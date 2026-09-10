import { ConvexError } from 'convex/values'
import { enemyForSpace, type BattleStats } from '../../../shared/combat.system'
import type { DebuffStat } from '../../../shared/magic.system'
import type { Doc, Id } from '../../_generated/dataModel'
import type { MutationCtx } from '../../_generated/server'
import { roomPhase } from '../../gameHelpers'

type CombatControl = { room: Doc<'rooms'>; player: Doc<'players'>; combat: Doc<'combats'> }

export function playerStats(
    player: Doc<'players'>,
    combat: Doc<'combats'> | undefined,
): BattleStats {
    return {
        attack: player.attack,
        defense: Math.max(0, (player.defense ?? 2) - (combat?.playerDefensePenalty ?? 0)),
        magic: Math.max(0, (player.magic ?? 2) - (combat?.playerMagicPenalty ?? 0)),
        athletics: Math.max(0, (player.athletics ?? 2) - (combat?.playerAthleticsPenalty ?? 0)),
        agility: Math.max(0, (player.agility ?? 2) - (combat?.playerAgilityPenalty ?? 0)),
    }
}

export function enemyStats(combat: Doc<'combats'>): BattleStats {
    return {
        attack: combat.enemyAttack,
        defense: Math.max(0, (combat.enemyDefense ?? 2) - (combat.enemyDefensePenalty ?? 0)),
        magic: Math.max(0, (combat.enemyMagic ?? 2) - (combat.enemyMagicPenalty ?? 0)),
        athletics: Math.max(0, (combat.enemyAthletics ?? 2) - (combat.enemyAthleticsPenalty ?? 0)),
        agility: Math.max(0, (combat.enemyAgility ?? 2) - (combat.enemyAgilityPenalty ?? 0)),
    }
}

export function debuffPatch(
    combat: Doc<'combats'>,
    target: 'enemy' | 'player',
    stat: DebuffStat,
    amount: number,
):
    | { enemyDefensePenalty: number }
    | { enemyMagicPenalty: number }
    | { enemyAthleticsPenalty: number }
    | { enemyAgilityPenalty: number }
    | { playerDefensePenalty: number }
    | { playerMagicPenalty: number }
    | { playerAthleticsPenalty: number }
    | { playerAgilityPenalty: number } {
    if (target === 'enemy') {
        if (stat === 'defense') {
            return { enemyDefensePenalty: Math.max(combat.enemyDefensePenalty ?? 0, amount) }
        }
        if (stat === 'magic') {
            return { enemyMagicPenalty: Math.max(combat.enemyMagicPenalty ?? 0, amount) }
        }
        if (stat === 'athletics') {
            return { enemyAthleticsPenalty: Math.max(combat.enemyAthleticsPenalty ?? 0, amount) }
        }
        return { enemyAgilityPenalty: Math.max(combat.enemyAgilityPenalty ?? 0, amount) }
    }
    if (stat === 'defense') {
        return { playerDefensePenalty: Math.max(combat.playerDefensePenalty ?? 0, amount) }
    }
    if (stat === 'magic') {
        return { playerMagicPenalty: Math.max(combat.playerMagicPenalty ?? 0, amount) }
    }
    if (stat === 'athletics') {
        return { playerAthleticsPenalty: Math.max(combat.playerAthleticsPenalty ?? 0, amount) }
    }
    return { playerAgilityPenalty: Math.max(combat.playerAgilityPenalty ?? 0, amount) }
}

export async function startCombat(
    ctx: MutationCtx,
    room: Doc<'rooms'>,
    player: Doc<'players'>,
    spaceId: number,
): Promise<void> {
    const enemy = enemyForSpace(spaceId)
    const combatId = await ctx.db.insert('combats', {
        roomId: room._id,
        playerId: player._id,
        spaceId: spaceId,
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
        message: 'Choose how to attack the ' + (enemy.name + '.'),
        createdAt: Date.now(),
    })
    await ctx.db.patch(room._id, {
        remainingMoves: 0,
        phase: 'combatAttack',
        activeCombatId: combatId,
        message: player.name + ' faces a ' + (enemy.name + '!'),
    })
}

export async function activeCombat(
    ctx: MutationCtx,
    roomId: Id<'rooms'>,
    playerId: Id<'players'>,
    expected: 'combatAttack' | 'combatDefend',
): Promise<CombatControl> {
    const room = await ctx.db.get(roomId)
    const player = await ctx.db.get(playerId)
    const combat = room && room.activeCombatId ? await ctx.db.get(room.activeCombatId) : null
    if (
        !room ||
        !player ||
        !combat ||
        room.activePlayerId !== playerId ||
        combat.playerId !== playerId ||
        roomPhase(room) !== expected
    ) {
        throw new ConvexError('That combat choice is not available.')
    }
    return { room: room, player: player, combat: combat }
}
