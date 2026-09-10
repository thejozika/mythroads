/** Generated from proofs/Mythroads/*.lean. Do not edit by hand. */
import { v } from 'convex/values'
import { internal } from '../_generated/api'
import type { MutationCtx } from '../_generated/server'
import { authorizeGameEvent } from '../auth/authorization'
import { persistGameEvent, priorDispatchResult } from '../events/persistence'
import {
    type DispatchResult,
    dispatchResultValidator,
    type GameEvent,
    gameEventValidator,
} from '../events/validators'
import { applyGameEvent } from './aggregate/boundary.generated'

export const dispatchMutationDefinition = {
    args: { commandId: v.optional(v.string()), event: gameEventValidator },
    returns: dispatchResultValidator,
    handler: async (
        ctx: MutationCtx,
        { commandId, event }: { commandId?: string; event: GameEvent },
    ): Promise<DispatchResult> => {
        return await ctx.runMutation(internal.game.execute, { commandId, event })
    },
}

export const executeMutationDefinition = {
    args: { commandId: v.optional(v.string()), event: gameEventValidator },
    returns: dispatchResultValidator,
    handler: async (
        ctx: MutationCtx,
        { commandId, event }: { commandId?: string; event: GameEvent },
    ): Promise<DispatchResult> => {
        const actorAuthId = await authorizeGameEvent(ctx, event)
        const priorResult = await priorDispatchResult(ctx, commandId, actorAuthId)
        if (priorResult) {
            return priorResult
        }
        const result = await applyGameEvent(ctx, event, actorAuthId)
        await persistGameEvent(ctx, event, result, commandId, actorAuthId)
        return result
    },
}
