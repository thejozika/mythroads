import { ConvexError } from 'convex/values'
import {
    ATTACK_LABELS,
    enemyForSpace,
    GUARD_LABELS,
    GUARD_STANCES,
    isMagicSpell,
    PHYSICAL_ATTACKS,
    strikeDamage,
    type CombatAttack,
    type GuardStance,
} from '../shared/combat.system'
import { equippedMagic } from '../shared/item.system'
import type { Doc, Id } from './_generated/dataModel'
import type { MutationCtx } from './_generated/server'
import { advanceTurn, roomPhase } from './gameHelpers'

const choose = <T>(options: readonly T[]) => options[Math.floor(Math.random() * options.length)]

const playerStats = (player: Doc<'players'>) => ({
    attack: player.attack,
    defense: player.defense ?? 2,
    magic: player.magic ?? 2,
    athletics: player.athletics ?? 2,
    agility: player.agility ?? 2,
})

const enemyStats = (combat: Doc<'combats'>) => ({
    attack: combat.enemyAttack,
    defense: combat.enemyDefense ?? 2,
    magic: combat.enemyMagic ?? 2,
    athletics: combat.enemyAthletics ?? 2,
    agility: combat.enemyAgility ?? 2,
})

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
    const guard = choose(GUARD_STANCES)
    const magic = isMagicSpell(attack)
    const mp = player.mp ?? player.maxMp ?? 5
    if (magic && mp < 2) throw new ConvexError('You need 2 MP to cast that spell.')
    const inventory = await ctx.db
        .query('playerItems')
        .withIndex('by_playerId', (query) => query.eq('playerId', player._id))
        .take(40)
    const loadout = equippedMagic(inventory)
    if (magic && attack !== loadout.spell)
        throw new ConvexError('Equip that battle spell before casting it.')
    const result = strikeDamage(
        attack,
        guard,
        playerStats(player),
        enemyStats(combat),
        combat.enemyElement,
    )
    const damage = Math.random() <= result.accuracy ? result.damage : 0
    const enemyHp = Math.max(0, combat.enemyHp - damage)
    if (magic) await ctx.db.patch(player._id, { mp: mp - 2 })
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
    const attack = choose([...PHYSICAL_ATTACKS, combat.enemyElement] as const)
    const inventory = await ctx.db
        .query('playerItems')
        .withIndex('by_playerId', (query) => query.eq('playerId', player._id))
        .take(40)
    const result = strikeDamage(
        attack,
        guard,
        enemyStats(combat),
        playerStats(player),
        undefined,
        equippedMagic(inventory).wardPower,
    )
    const damage = Math.random() <= result.accuracy ? result.damage : 0
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
        await ctx.db.patch(player._id, { hp: 1, gold: player.gold - loss })
        await advanceTurn(
            ctx,
            room,
            player._id,
            `${player.name} escaped ${combat.enemyName}, losing ${loss} gold.`,
        )
        return
    }
    await ctx.db.patch(player._id, { hp })
    await ctx.db.patch(room._id, {
        phase: 'combatAttack',
        message: `${player.name} weathered the counterattack. Choose another attack.`,
    })
}
