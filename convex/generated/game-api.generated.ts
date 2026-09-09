/** Generated from proofs/Mythroads/*.lean. Do not edit by hand. */
import { ConvexError, v } from 'convex/values'
import type { Id } from '../_generated/dataModel'
import type { MutationCtx, QueryCtx } from '../_generated/server'
import { authorizeGameEvent } from '../auth/authorization'
import { persistGameEvent, priorDispatchResult } from '../events/persistence'
import { routeGameEvent } from '../events/router'
import { dispatchResultValidator, gameEventValidator } from '../events/validators'
import type { GameEvent } from '../events/validators'
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

export const dispatchMutationDefinition = {
    args: { commandId: v.optional(v.string()), event: gameEventValidator },
    returns: dispatchResultValidator,
    handler: async (
        ctx: MutationCtx,
        { commandId, event }: { commandId: string | undefined; event: GameEvent },
    ) => {
        const actorAuthId = await authorizeGameEvent(ctx, event)
        const priorResult = await priorDispatchResult(ctx, commandId, actorAuthId)
        if (priorResult) return priorResult
        const result = await routeGameEvent(ctx, event, actorAuthId)
        await persistGameEvent(ctx, event, result, commandId, actorAuthId)
        return result
    },
}
