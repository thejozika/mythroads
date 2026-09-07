import { ConvexError, v } from 'convex/values'
import { getItem } from '../shared/item.system'
import type { Id } from './_generated/dataModel'
import { type MutationCtx, query } from './_generated/server'
import { advanceTurn, roomPhase } from './gameHelpers'
import schema from './schema'

export const inventory = query({
    args: { playerId: v.id('players') },
    returns: v.array(schema.doc('playerItems')),
    handler: async (ctx, { playerId }) =>
        await ctx.db
            .query('playerItems')
            .withIndex('by_playerId', (q) => q.eq('playerId', playerId))
            .take(40),
})

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

export async function equipItem(
    ctx: MutationCtx,
    {
        playerId,
        playerItemId,
        slot,
    }: {
        playerId: Id<'players'>
        playerItemId: Id<'playerItems'>
        slot:
            | 'weapon'
            | 'helmet'
            | 'body'
            | 'gloves'
            | 'boots'
            | 'cape'
            | 'amulet'
            | 'ringLeft'
            | 'ringRight'
            | 'offensiveMagic'
            | 'defensiveMagic'
    },
) {
    const owned = await ctx.db.get(playerItemId)
    const item = owned && getItem(owned.itemId)
    if (!owned || owned.playerId !== playerId || !item?.slots.includes(slot)) {
        throw new ConvexError('That item cannot be equipped there.')
    }
    const inventory = await ctx.db
        .query('playerItems')
        .withIndex('by_playerId', (q) => q.eq('playerId', playerId))
        .take(40)
    const occupied = inventory.find((candidate) => candidate.equippedSlot === slot)
    if (occupied) await ctx.db.patch(occupied._id, { equippedSlot: undefined })
    await ctx.db.patch(playerItemId, { equippedSlot: slot })
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
