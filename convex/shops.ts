import { ConvexError } from 'convex/values'
import { getItem } from '../shared/item.system'
import type { Id } from './_generated/dataModel'
import { type MutationCtx, query } from './_generated/server'
import { inventoryQueryDefinition } from './generated/inventory.generated'
import { advanceTurn, roomPhase } from './gameHelpers'

export const inventory = query(inventoryQueryDefinition)
export { equipItem } from './generated/inventory.generated'

export async function buyItem(
    ctx: MutationCtx,
    {
        roomId,
        playerId,
        itemId,
    }: {
        roomId: Id<'rooms'>
        playerId: Id<'players'>
        itemId: string
    },
) {
    const [room, player] = await Promise.all([ctx.db.get(roomId), ctx.db.get(playerId)])
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
    if (player.gold < item.price) throw new ConvexError('You need more gold.')
    await ctx.db.patch(playerId, { gold: player.gold - item.price })
    await ctx.db.insert('playerItems', { playerId, itemId, purchasedAt: Date.now() })
}

export async function leaveShop(
    ctx: MutationCtx,
    { roomId, playerId }: { roomId: Id<'rooms'>; playerId: Id<'players'> },
) {
    const room = await ctx.db.get(roomId)
    const player = await ctx.db.get(playerId)
    if (!room || !player || room.activePlayerId !== playerId || roomPhase(room) !== 'shopping') {
        throw new ConvexError('You are not shopping now.')
    }
    await advanceTurn(ctx, room, playerId, `${player.name} finished shopping.`)
}
