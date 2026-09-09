import type { Id } from '../_generated/dataModel'
import type { DispatchResult, GameEvent } from './validators.ts'

export type EventAuthority = {
    mode: 'authenticated' | 'developmentBypass'
    actorPlayerId?: Id<'players'>
    actorAuthId?: string
}

export function resolveEventAuthority(
    event: GameEvent,
    result: DispatchResult,
    actorAuthId: string | null,
): EventAuthority {
    const actorPlayerId =
        'playerId' in event.subjects
            ? event.subjects.playerId
            : result.kind === 'player.joined'
              ? result.playerId
              : undefined
    return {
        mode: actorAuthId ? 'authenticated' : 'developmentBypass',
        ...(actorPlayerId ? { actorPlayerId } : {}),
        ...(actorAuthId ? { actorAuthId } : {}),
    }
}
