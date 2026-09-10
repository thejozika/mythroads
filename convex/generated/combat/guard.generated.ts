/** Generated from proofs/Mythroads/Backend/Combat/Guard.lean. Do not edit by hand. */
import {
    ATTACK_LABELS,
    GUARD_LABELS,
    type GuardStance,
    isMagicTechnique,
    PHYSICAL_ATTACKS,
    strikeDamage,
} from '../../../shared/combat.system'
import { equippedMagic } from '../../../shared/item.system'
import { MAGIC_LOADOUTS, MAGIC_TECHNIQUES } from '../../../shared/magic.system'
import type { Id } from '../../_generated/dataModel'
import type { MutationCtx } from '../../_generated/server'
import { advanceTurn } from '../../gameHelpers'
import { drawRoomRandom } from '../../random/state'
import { chanceHits } from '../random.generated'
import { activeCombat, debuffPatch, enemyStats, playerStats } from './state.generated'

export async function chooseGuard(
    ctx: MutationCtx,
    subjects: { roomId: Id<'rooms'>; playerId: Id<'players'> },
    guard: GuardStance,
): Promise<void> {
    const control = await activeCombat(ctx, subjects.roomId, subjects.playerId, 'combatDefend')
    const room = control.room
    const player = control.player
    const combat = control.combat
    const attacks = [...PHYSICAL_ATTACKS, ...MAGIC_LOADOUTS[combat.enemyElement]] as const
    const attack = attacks[await drawRoomRandom(ctx, room._id, attacks.length)]
    const inventory = await ctx.db
        .query('playerItems')
        .withIndex('by_playerId', (query) => query.eq('playerId', player._id))
        .take(40)
    const technique = isMagicTechnique(attack) ? MAGIC_TECHNIQUES[attack] : undefined
    if (technique && technique.delivery === 'debuff') {
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
                ? player.name +
                  "'s " +
                  (GUARD_LABELS[guard] + ' nullified ') +
                  (ATTACK_LABELS[attack] + '.')
                : combat.enemyName +
                  "'s " +
                  (ATTACK_LABELS[attack] + ' lowered ') +
                  (player.name + "'s ") +
                  (technique.debuff?.stat + '.'),
        })
        await ctx.db.patch(room._id, {
            phase: 'combatAttack',
            message: blocked
                ? player.name + ' resisted the hex. Choose another attack.'
                : player.name + ' was weakened. Choose another attack.',
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
    const hitRoll = await drawRoomRandom(ctx, room._id, 10000)
    const damage = chanceHits(Math.round(result.accuracy * 10000), 10000, hitRoll)
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
            ? combat.enemyName +
              "'s " +
              (ATTACK_LABELS[attack] + ' met ') +
              (GUARD_LABELS[guard] + ': ') +
              (result.matchup + ', ') +
              (damage + ' damage.')
            : combat.enemyName + "'s " + (ATTACK_LABELS[attack] + ' missed!'),
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
            player.name +
                ' fell to ' +
                (combat.enemyName + ' and awoke at Hearthkeep, losing ') +
                loss +
                ' gold.',
        )
        return
    }
    await ctx.db.patch(player._id, { hp: hp })
    await ctx.db.patch(room._id, {
        phase: 'combatAttack',
        message: player.name + ' weathered the counterattack. Choose another attack.',
    })
}
