/** Generated from proofs/Mythroads/Backend/Combat/Attack.lean. Do not edit by hand. */
import { ConvexError } from 'convex/values'
import {
    ATTACK_LABELS,
    type CombatAttack,
    GUARD_LABELS,
    GUARD_STANCES,
    isMagicTechnique,
    strikeDamage,
} from '../../../shared/combat.system'
import { equippedMagic } from '../../../shared/item.system'
import { MAGIC_TECHNIQUES } from '../../../shared/magic.system'
import type { Id } from '../../_generated/dataModel'
import type { MutationCtx } from '../../_generated/server'
import { advanceTurn } from '../../gameHelpers'
import { drawRoomRandom } from '../../random/state'
import { chanceHits } from '../random.generated'
import { activeCombat, debuffPatch, enemyStats, playerStats } from './state.generated'

export async function chooseAttack(
    ctx: MutationCtx,
    subjects: { roomId: Id<'rooms'>; playerId: Id<'players'> },
    attack: CombatAttack,
): Promise<void> {
    const control = await activeCombat(ctx, subjects.roomId, subjects.playerId, 'combatAttack')
    const room = control.room
    const player = control.player
    const combat = control.combat
    const guard = GUARD_STANCES[await drawRoomRandom(ctx, room._id, GUARD_STANCES.length)]
    const magic = isMagicTechnique(attack)
    const inventory = await ctx.db
        .query('playerItems')
        .withIndex('by_playerId', (query) => query.eq('playerId', player._id))
        .take(40)
    const loadout = equippedMagic(inventory)
    if (magic && !loadout.actions.includes(attack)) {
        throw new ConvexError('Equip the grimoire containing that technique first.')
    }
    const technique = magic ? MAGIC_TECHNIQUES[attack] : undefined
    if (technique && technique.delivery === 'debuff') {
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
                ? GUARD_LABELS[guard] + ' nullified ' + (ATTACK_LABELS[attack] + '.')
                : ATTACK_LABELS[attack] + " lowered the enemy's " + (technique.debuff?.stat + '.'),
        })
        await ctx.db.patch(room._id, {
            phase: 'combatDefend',
            message: combat.enemyName + ' prepares a counterattack. Choose a guard.',
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
    const hitRoll = await drawRoomRandom(ctx, room._id, 10000)
    const damage = chanceHits(Math.round(result.accuracy * 10000), 10000, hitRoll)
        ? result.damage
        : 0
    const enemyHp = Math.max(0, combat.enemyHp - damage)
    await ctx.db.patch(combat._id, {
        enemyHp: enemyHp,
        lastAttack: attack,
        lastGuard: guard,
        lastDamage: damage,
        message: damage
            ? ATTACK_LABELS[attack] +
              ' met ' +
              (GUARD_LABELS[guard] + ': ') +
              (result.matchup + ', ') +
              (damage + ' damage.')
            : ATTACK_LABELS[attack] + ' missed!',
    })
    if (enemyHp === 0) {
        await ctx.db.patch(combat._id, { phase: 'resolved' })
        await ctx.db.patch(player._id, { gold: player.gold + combat.reward })
        await advanceTurn(
            ctx,
            room,
            player._id,
            player.name +
                ' defeated ' +
                (combat.enemyName + ' and won ') +
                (combat.reward + ' gold.'),
        )
        return
    }
    await ctx.db.patch(combat._id, { phase: 'defend' })
    await ctx.db.patch(room._id, {
        phase: 'combatDefend',
        message: combat.enemyName + ' prepares a counterattack. Choose a guard.',
    })
}
