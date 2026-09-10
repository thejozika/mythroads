/** Generated from proofs/Mythroads/Backend/Inventory.lean. Do not edit by hand. */
import { ConvexError, v } from 'convex/values'
import { getItem } from '../../shared/item.system'
import type { Id } from '../_generated/dataModel'
import type { MutationCtx, QueryCtx } from '../_generated/server'
import { requirePlayerOwner } from '../auth/authorization'
import schema from '../schema'

export const inventoryQueryDefinition = {
    args: { playerId: v.id('players') },
    returns: v.array(schema.doc('playerItems')),
    handler: async (ctx: QueryCtx, { playerId }: { playerId: Id<'players'> }) => {
        const identity = await ctx.auth.getUserIdentity()
        if (!identity) throw new ConvexError('Sign in to view an inventory.')
        const player = await ctx.db.get(playerId)
        if (!player) throw new ConvexError('That hero does not exist.')
        if (!player.authId || identity.tokenIdentifier !== player.authId) {
            throw new ConvexError('That inventory belongs to another account.')
        }
        return await ctx.db
            .query('playerItems')
            .withIndex('by_playerId', (q) => q.eq('playerId', playerId))
            .take(40)
    },
}

export type EquipmentSlot =
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

export async function equipItem(
    ctx: MutationCtx,
    args: { playerId: Id<'players'>; playerItemId: Id<'playerItems'>; slot: EquipmentSlot },
): Promise<void> {
    const playerId = args.playerId
    const playerItemId = args.playerItemId
    const slot = args.slot
    await requirePlayerOwner(ctx, playerId)
    const owned = await ctx.db.get('playerItems', playerItemId)
    const item = owned ? getItem(owned.itemId) : null
    if (!owned || owned.playerId !== playerId || !item || !item.slots.includes(slot)) {
        throw new ConvexError('That item cannot be equipped there.')
    }
    const inventory = await ctx.db
        .query('playerItems')
        .withIndex('by_playerId', (query) => query.eq('playerId', playerId))
        .take(40)
    const occupied = inventory.find((candidate) => candidate.equippedSlot === slot)
    if (occupied) {
        await ctx.db.patch('playerItems', occupied._id, { equippedSlot: undefined })
    }
    await ctx.db.patch('playerItems', playerItemId, { equippedSlot: slot })
}
