/** Generated from proofs/Mythroads/Backend/Inventory.lean. Do not edit by hand. */
import { ConvexError, v } from 'convex/values'
import type { Id } from '../_generated/dataModel'
import type { QueryCtx } from '../_generated/server'
import schema from '../schema'

export const inventoryQueryDefinition = {
    args: { playerId: v.id('players') },
    returns: v.array(schema.doc('playerItems')),
    handler: async (ctx: QueryCtx, { playerId }: { playerId: Id<'players'> }) => {
        const identity = await ctx.auth.getUserIdentity()
        if (!identity) {
            throw new ConvexError('Sign in to view an inventory.')
        }
        const player = await ctx.db.get(playerId)
        if (!player) {
            throw new ConvexError('That hero does not exist.')
        }
        if (!player.authId || identity.tokenIdentifier !== player.authId) {
            throw new ConvexError('That inventory belongs to another account.')
        }
        return await ctx.db
            .query('playerItems')
            .withIndex('by_playerId', (query) => query.eq('playerId', playerId))
            .take(40)
    },
}
