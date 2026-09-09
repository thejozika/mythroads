import { v } from 'convex/values'
import { mutation } from './_generated/server'
import { authorizeGameEvent } from './auth/authorization'
import { persistGameEvent, priorDispatchResult } from './events/persistence.ts'
import { routeGameEvent } from './events/router.ts'
import { dispatchResultValidator, gameEventValidator } from './events/validators.ts'

export const dispatch = mutation({
    args: { commandId: v.optional(v.string()), event: gameEventValidator },
    returns: dispatchResultValidator,
    handler: async (ctx, { commandId, event }) => {
        const actorAuthId = await authorizeGameEvent(ctx, event)
        const priorResult = await priorDispatchResult(ctx, commandId, actorAuthId)
        if (priorResult) return priorResult
        const result = await routeGameEvent(ctx, event, actorAuthId)
        await persistGameEvent(ctx, event, result, commandId, actorAuthId)
        return result
    },
})
