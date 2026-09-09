import type { Doc } from '../_generated/dataModel'
import type { MutationCtx } from '../_generated/server'
import { resolveEventAuthority } from './authority.ts'
import { eventRoomId, GAME_EVENT_SCHEMA_VERSION, isPersistentGameEvent } from './policy.ts'
import type { DispatchResult, GameEvent } from './validators.ts'

type VersionedGameEvent = Extract<Doc<'gameEvents'>, { schemaVersion: number }>

export async function priorDispatchResult(
    ctx: MutationCtx,
    commandId: string | undefined,
    actorAuthId: string | null,
) {
    if (!commandId) return null
    const existing = await ctx.db
        .query('gameEvents')
        .withIndex('by_commandId', (query) => query.eq('commandId', commandId))
        .unique()
    if (!existing || !('result' in existing)) return null
    if (actorAuthId && existing.authority.actorAuthId !== actorAuthId) {
        throw new ConvexError('That command belongs to another account.')
    }
    return existing.result
}

export async function persistGameEvent(
    ctx: MutationCtx,
    event: GameEvent,
    result: DispatchResult,
    commandId?: string,
    actorAuthId: string | null = null,
) {
    if (!isPersistentGameEvent(event)) return
    const roomId = eventRoomId(event)
    const authority = resolveEventAuthority(event, result, actorAuthId)
    const record: Omit<VersionedGameEvent, '_id' | '_creationTime'> = {
        eventId: `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`,
        schemaVersion: GAME_EVENT_SCHEMA_VERSION,
        event,
        result,
        authority,
        createdAt: Date.now(),
        ...(commandId ? { commandId } : {}),
        ...(roomId ? { roomId } : {}),
        ...(authority.actorPlayerId ? { actorPlayerId: authority.actorPlayerId } : {}),
    }
    await ctx.db.insert('gameEvents', record)
}
import { ConvexError } from 'convex/values'
