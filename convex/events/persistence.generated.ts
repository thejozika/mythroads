/** Generated from proofs/Mythroads/Game/Events.lean. Do not edit by hand. */
import { ConvexError } from 'convex/values'
import type { MutationCtx } from '../_generated/server'
import { resolveEventAuthority } from './authority'
import { eventRoomId, isPersistentGameEvent } from './policy'
import type { DispatchResult, GameEvent } from './validators'

export async function priorDispatchResult(
    ctx: MutationCtx,
    commandId: string | undefined,
    actorAuthId: string | null,
): Promise<DispatchResult | null> {
    if (!commandId) {
        return null
    }
    const existing = await ctx.db
        .query('gameEvents')
        .withIndex('by_commandId', (query) => query.eq('commandId', commandId))
        .unique()
    if (!existing || !('result' in existing)) {
        return null
    }
    if (actorAuthId && existing.authority.actorAuthId !== actorAuthId) {
        throw new ConvexError('That command belongs to another account.')
    }
    return existing.result
}

export async function persistGameEvent(
    ctx: MutationCtx,
    event: GameEvent,
    result: DispatchResult,
    commandId: string | undefined,
    actorAuthId: string | null,
): Promise<void> {
    if (!isPersistentGameEvent(event)) {
        return
    }
    const createdAt = Date.now()
    const roomId = eventRoomId(event)
    const authority = resolveEventAuthority(event, result, actorAuthId)
    const record = {
        eventId:
            commandId ??
            createdAt.toString(36) + ':' + event.type + (':' + JSON.stringify(event.subjects)),
        schemaVersion: 1 as const,
        event: event,
        result: result,
        authority: authority,
        createdAt: createdAt,
        commandId: commandId,
        roomId: roomId,
        actorPlayerId: authority.actorPlayerId,
    }
    await ctx.db.insert('gameEvents', record)
}
