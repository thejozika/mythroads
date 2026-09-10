/** Generated from proofs/Mythroads/Game/Events.lean. Do not edit by hand. */
import type { Id } from '../_generated/dataModel'
import type { DispatchResult, GameEvent } from './validators'

export type EventAuthority = {
    mode: 'authenticated' | 'developmentBypass'
    actorPlayerId: Id<'players'> | undefined
    actorAuthId: string | undefined
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
        actorPlayerId: actorPlayerId,
        actorAuthId: actorAuthId ?? undefined,
    }
}
