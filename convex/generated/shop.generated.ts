/** Generated from proofs/Mythroads/Backend/Shop.lean. Do not edit by hand. */
import { ConvexError } from 'convex/values'
import { getItem } from '../../shared/item.system'
import type { Id } from '../_generated/dataModel'
import type { MutationCtx } from '../_generated/server'
import { advanceTurn, roomPhase } from '../gameHelpers'

export async function buyItem(
    ctx: MutationCtx,
    args: { roomId: Id<'rooms'>; playerId: Id<'players'>; itemId: string },
): Promise<void> {
    const roomId = args.roomId
    const playerId = args.playerId
    const itemId = args.itemId
    const room = await ctx.db.get(roomId)
    const player = await ctx.db.get(playerId)
    const item = getItem(itemId)
    if (
        !room ||
        !player ||
        !item ||
        room.activePlayerId !== playerId ||
        roomPhase(room) !== 'shopping' ||
        room.shopKind !== item.shop
    ) {
        throw new ConvexError('That item is not available here.')
    }
    if (player.gold < item.price) {
        throw new ConvexError('You need more gold.')
    }
    await ctx.db.patch(playerId, { gold: player.gold - item.price })
    await ctx.db.insert('playerItems', {
        playerId: playerId,
        itemId: itemId,
        purchasedAt: Date.now(),
    })
}

export async function leaveShop(
    ctx: MutationCtx,
    subjects: { roomId: Id<'rooms'>; playerId: Id<'players'> },
): Promise<void> {
    const roomId = subjects.roomId
    const playerId = subjects.playerId
    const room = await ctx.db.get(roomId)
    const player = await ctx.db.get(playerId)
    if (!room || !player || room.activePlayerId !== playerId || roomPhase(room) !== 'shopping') {
        throw new ConvexError('You are not shopping now.')
    }
    await advanceTurn(ctx, room, playerId, player.name + ' finished shopping.')
}
