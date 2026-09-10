import { ConvexError } from 'convex/values'
import {
    ATTACK_LABELS,
    enemyForSpace,
    GUARD_LABELS,
    GUARD_STANCES,
    isMagicTechnique,
    PHYSICAL_ATTACKS,
    strikeDamage,
    type CombatAttack,
    type GuardStance,
} from '../shared/combat.system'
import { equippedMagic } from '../shared/item.system'
import { MAGIC_LOADOUTS, MAGIC_TECHNIQUES, type DebuffStat } from '../shared/magic.system'
import type { Doc, Id } from './_generated/dataModel'
import type { MutationCtx } from './_generated/server'
import { advanceTurn, roomPhase } from './gameHelpers'
import { chanceHits } from './generated/random.generated'
import { drawRoomRandom } from './random/state'

const playerStats = (player: Doc<'players'>, combat?: Doc<'combats'>) => ({
    attack: player.attack,
    defense: Math.max(0, (player.defense ?? 2) - (combat?.playerDefensePenalty ?? 0)),
    magic: Math.max(0, (player.magic ?? 2) - (combat?.playerMagicPenalty ?? 0)),
    athletics: Math.max(0, (player.athletics ?? 2) - (combat?.playerAthleticsPenalty ?? 0)),
    agility: Math.max(0, (player.agility ?? 2) - (combat?.playerAgilityPenalty ?? 0)),
})

const enemyStats = (combat: Doc<'combats'>) => ({
    attack: combat.enemyAttack,
    defense: Math.max(0, (combat.enemyDefense ?? 2) - (combat.enemyDefensePenalty ?? 0)),
    magic: Math.max(0, (combat.enemyMagic ?? 2) - (combat.enemyMagicPenalty ?? 0)),
    athletics: Math.max(0, (combat.enemyAthletics ?? 2) - (combat.enemyAthleticsPenalty ?? 0)),
    agility: Math.max(0, (combat.enemyAgility ?? 2) - (combat.enemyAgilityPenalty ?? 0)),
})

function debuffPatch(
    combat: Doc<'combats'>,
    target: 'enemy' | 'player',
    stat: DebuffStat,
    amount: number,
) {
    const current = (key: keyof Doc<'combats'>) => Number(combat[key] ?? 0)
    if (target === 'enemy') {
        if (stat === 'defense')
            return { enemyDefensePenalty: Math.max(current('enemyDefensePenalty'), amount) }
        if (stat === 'magic')
            return { enemyMagicPenalty: Math.max(current('enemyMagicPenalty'), amount) }
        if (stat === 'athletics')
            return { enemyAthleticsPenalty: Math.max(current('enemyAthleticsPenalty'), amount) }
        return { enemyAgilityPenalty: Math.max(current('enemyAgilityPenalty'), amount) }
    }
    if (stat === 'defense')
        return { playerDefensePenalty: Math.max(current('playerDefensePenalty'), amount) }
    if (stat === 'magic')
        return { playerMagicPenalty: Math.max(current('playerMagicPenalty'), amount) }
    if (stat === 'athletics')
        return { playerAthleticsPenalty: Math.max(current('playerAthleticsPenalty'), amount) }
    return { playerAgilityPenalty: Math.max(current('playerAgilityPenalty'), amount) }
}

export async function startCombat(
    ctx: MutationCtx,
    room: Doc<'rooms'>,
    player: Doc<'players'>,
    spaceId: number,
) {
    const enemy = enemyForSpace(spaceId)
    const combatId = await ctx.db.insert('combats', {
        roomId: room._id,
        playerId: player._id,
        spaceId,
        enemyName: enemy.name,
        enemyElement: enemy.element,
        enemyHp: enemy.hp,
        enemyMaxHp: enemy.hp,
        enemyAttack: enemy.attack,
        enemyDefense: enemy.defense,
        enemyMagic: enemy.magic,
        enemyAthletics: enemy.athletics,
        enemyAgility: enemy.agility,
        reward: enemy.reward,
        round: 1,
        phase: 'attack',
        message: `Choose how to attack the ${enemy.name}.`,
        createdAt: Date.now(),
    })
    await ctx.db.patch(room._id, {
        remainingMoves: 0,
        phase: 'combatAttack',
        activeCombatId: combatId,
        message: `${player.name} faces a ${enemy.name}!`,
    })
}

async function activeCombat(
    ctx: MutationCtx,
    roomId: Id<'rooms'>,
    playerId: Id<'players'>,
    expected: 'combatAttack' | 'combatDefend',
) {
    const [room, player] = await Promise.all([ctx.db.get(roomId), ctx.db.get(playerId)])
    const combat = room?.activeCombatId ? await ctx.db.get(room.activeCombatId) : null
    if (
        !room ||
        !player ||
        !combat ||
        room.activePlayerId !== playerId ||
        combat.playerId !== playerId ||
        roomPhase(room) !== expected
    )
        throw new ConvexError('That combat choice is not available.')
    return { room, player, combat }
}

export async function chooseAttack(
    ctx: MutationCtx,
    subjects: { roomId: Id<'rooms'>; playerId: Id<'players'> },
    attack: CombatAttack,
) {
    const { room, player, combat } = await activeCombat(
        ctx,
        subjects.roomId,
        subjects.playerId,
        'combatAttack',
    )
    const guard = GUARD_STANCES[await drawRoomRandom(ctx, room._id, GUARD_STANCES.length)]
    const magic = isMagicTechnique(attack)
    const inventory = await ctx.db
        .query('playerItems')
        .withIndex('by_playerId', (query) => query.eq('playerId', player._id))
        .take(40)
    const loadout = equippedMagic(inventory)
    if (magic && !loadout.actions.includes(attack))
        throw new ConvexError('Equip the grimoire containing that technique first.')
    const technique = magic ? MAGIC_TECHNIQUES[attack] : undefined
    if (technique?.delivery === 'debuff') {
        const blocked = guard === 'ward'
        if (!blocked && technique.debuff) {
            await ctx.db.patch(
                combat._id,
                debuffPatch(combat, 'enemy', technique.debuff.stat, technique.debuff.amount),
            )
        }
        await ctx.db.patch(combat._id, {
            phase: 'defend',
            lastAttack: attack,
            lastGuard: guard,
            lastDamage: 0,
            message: blocked
                ? `${GUARD_LABELS[guard]} nullified ${ATTACK_LABELS[attack]}.`
                : `${ATTACK_LABELS[attack]} lowered the enemy's ${technique.debuff?.stat}.`,
        })
        await ctx.db.patch(room._id, {
            phase: 'combatDefend',
            message: `${combat.enemyName} prepares a counterattack. Choose a guard.`,
        })
        return
    }
    const result = strikeDamage(
        attack,
        guard,
        playerStats(player, combat),
        enemyStats(combat),
        combat.enemyElement,
    )
    const hitRoll = await drawRoomRandom(ctx, room._id, 10_000)
    const damage = chanceHits(Math.round(result.accuracy * 10_000), 10_000, hitRoll)
        ? result.damage
        : 0
    const enemyHp = Math.max(0, combat.enemyHp - damage)
    await ctx.db.patch(combat._id, {
        enemyHp,
        lastAttack: attack,
        lastGuard: guard,
        lastDamage: damage,
        message: damage
            ? `${ATTACK_LABELS[attack]} met ${GUARD_LABELS[guard]}: ${result.matchup}, ${damage} damage.`
            : `${ATTACK_LABELS[attack]} missed!`,
    })
    if (enemyHp === 0) {
        await ctx.db.patch(combat._id, { phase: 'resolved' })
        await ctx.db.patch(player._id, { gold: player.gold + combat.reward })
        await advanceTurn(
            ctx,
            room,
            player._id,
            `${player.name} defeated ${combat.enemyName} and won ${combat.reward} gold.`,
        )
        return
    }
    await ctx.db.patch(combat._id, { phase: 'defend' })
    await ctx.db.patch(room._id, {
        phase: 'combatDefend',
        message: `${combat.enemyName} prepares a counterattack. Choose a guard.`,
    })
}

export async function chooseGuard(
    ctx: MutationCtx,
    subjects: { roomId: Id<'rooms'>; playerId: Id<'players'> },
    guard: GuardStance,
) {
    const { room, player, combat } = await activeCombat(
        ctx,
        subjects.roomId,
        subjects.playerId,
        'combatDefend',
    )
    const attacks = [...PHYSICAL_ATTACKS, ...MAGIC_LOADOUTS[combat.enemyElement]] as const
    const attack = attacks[await drawRoomRandom(ctx, room._id, attacks.length)]
    const inventory = await ctx.db
        .query('playerItems')
        .withIndex('by_playerId', (query) => query.eq('playerId', player._id))
        .take(40)
    const technique = isMagicTechnique(attack) ? MAGIC_TECHNIQUES[attack] : undefined
    if (technique?.delivery === 'debuff') {
        const blocked = guard === 'ward'
        if (!blocked && technique.debuff) {
            await ctx.db.patch(
                combat._id,
                debuffPatch(combat, 'player', technique.debuff.stat, technique.debuff.amount),
            )
        }
        await ctx.db.patch(combat._id, {
            round: combat.round + 1,
            phase: 'attack',
            lastAttack: attack,
            lastGuard: guard,
            lastDamage: 0,
            message: blocked
                ? `${player.name}'s ${GUARD_LABELS[guard]} nullified ${ATTACK_LABELS[attack]}.`
                : `${combat.enemyName}'s ${ATTACK_LABELS[attack]} lowered ${player.name}'s ${technique.debuff?.stat}.`,
        })
        await ctx.db.patch(room._id, {
            phase: 'combatAttack',
            message: blocked
                ? `${player.name} resisted the hex. Choose another attack.`
                : `${player.name} was weakened. Choose another attack.`,
        })
        return
    }
    const result = strikeDamage(
        attack,
        guard,
        enemyStats(combat),
        playerStats(player, combat),
        undefined,
        equippedMagic(inventory).wardPower,
    )
    const hitRoll = await drawRoomRandom(ctx, room._id, 10_000)
    const damage = chanceHits(Math.round(result.accuracy * 10_000), 10_000, hitRoll)
        ? result.damage
        : 0
    const hp = Math.max(0, player.hp - damage)
    await ctx.db.patch(combat._id, {
        round: combat.round + 1,
        phase: hp === 0 ? 'resolved' : 'attack',
        lastAttack: attack,
        lastGuard: guard,
        lastDamage: damage,
        message: damage
            ? `${combat.enemyName}'s ${ATTACK_LABELS[attack]} met ${GUARD_LABELS[guard]}: ${result.matchup}, ${damage} damage.`
            : `${combat.enemyName}'s ${ATTACK_LABELS[attack]} missed!`,
    })
    if (hp === 0) {
        const loss = Math.min(3, player.gold)
        await ctx.db.patch(player._id, {
            hp: player.maxHp,
            gold: player.gold - loss,
            position: 0,
            previousPosition: undefined,
        })
        await advanceTurn(
            ctx,
            room,
            player._id,
            `${player.name} fell to ${combat.enemyName} and awoke at Hearthkeep, losing ${loss} gold.`,
        )
        return
    }
    await ctx.db.patch(player._id, { hp })
    await ctx.db.patch(room._id, {
        phase: 'combatAttack',
        message: `${player.name} weathered the counterattack. Choose another attack.`,
    })
}
