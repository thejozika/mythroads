import type { Doc } from '../_generated/dataModel'
import type { MutationCtx } from '../_generated/server'
import { resolveEventAuthority } from './authority.ts'
import { eventRoomId, GAME_EVENT_SCHEMA_VERSION, isPersistentGameEvent } from './policy.ts'
import type { DispatchResult, GameEvent } from './validators.ts'

type VersionedGameEvent = Extract<Doc<'gameEvents'>, { schemaVersion: number }>

export async function priorDispatchResult(ctx: MutationCtx, commandId?: string) {
    if (!commandId) return null
    const existing = await ctx.db
        .query('gameEvents')
        .withIndex('by_commandId', (query) => query.eq('commandId', commandId))
        .unique()
    return existing && 'result' in existing ? existing.result : null
}

export async function persistGameEvent(
    ctx: MutationCtx,
    event: GameEvent,
    result: DispatchResult,
    commandId?: string,
) {
    if (!isPersistentGameEvent(event)) return
    const roomId = eventRoomId(event)
    const authority = resolveEventAuthority(event, result)
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
