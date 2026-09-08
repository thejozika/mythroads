import type { Id } from '../_generated/dataModel'
import type { DispatchResult, GameEvent } from './validators.ts'

export type EventAuthority = {
    mode: 'prototypePlayerId'
    actorPlayerId?: Id<'players'>
}

export function resolveEventAuthority(event: GameEvent, result: DispatchResult): EventAuthority {
    const actorPlayerId =
        'playerId' in event.subjects
            ? event.subjects.playerId
            : result.kind === 'player.joined'
              ? result.playerId
              : undefined
    return {
        mode: 'prototypePlayerId',
        ...(actorPlayerId ? { actorPlayerId } : {}),
    }
}
