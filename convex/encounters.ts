import { ConvexError } from 'convex/values'
import type { Id } from './_generated/dataModel'
import type { MutationCtx } from './_generated/server'
import { advanceTurn, roomPhase } from './gameHelpers'

export async function resolveEncounter(
    ctx: MutationCtx,
    {
        roomId,
        playerId,
        encounterId,
    }: {
        roomId: Id<'rooms'>
        playerId: Id<'players'>
        encounterId: Id<'encounters'>
    },
) {
    const [room, player, encounter] = await Promise.all([
        ctx.db.get(roomId),
        ctx.db.get(playerId),
        ctx.db.get(encounterId),
    ])
    if (
        !room ||
        !player ||
        !encounter ||
        room.activePlayerId !== playerId ||
        room.activeEncounterId !== encounterId ||
        encounter.playerId !== playerId ||
        encounter.status !== 'revealing' ||
        roomPhase(room) !== 'revealingEncounter' ||
        Date.now() - encounter.createdAt < 2200
    ) {
        throw new ConvexError('This encounter cannot be resolved now.')
    }
    const gold = Math.max(0, player.gold + encounter.goldDelta)
    const hp = Math.min(player.maxHp, Math.max(1, player.hp + encounter.hpDelta))
    await ctx.db.patch(playerId, { gold, hp })
    await ctx.db.patch(encounterId, { status: 'resolved' })
    const effects = [
        encounter.goldDelta
            ? `${encounter.goldDelta > 0 ? '+' : ''}${encounter.goldDelta} gold`
            : '',
        encounter.hpDelta ? `${encounter.hpDelta > 0 ? '+' : ''}${encounter.hpDelta} health` : '',
    ].filter(Boolean)
    await advanceTurn(
        ctx,
        room,
        playerId,
        `${player.name}: ${encounter.title}${effects.length ? ` (${effects.join(', ')})` : ''}.`,
    )
}
