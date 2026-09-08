import type { Id } from '../_generated/dataModel'
import type { GameEvent } from './validators.ts'

export const GAME_EVENT_SCHEMA_VERSION = 1 as const

export function isPersistentGameEvent(event: GameEvent) {
    return !event.type.startsWith('camera.')
}

export function eventRoomId(event: GameEvent): Id<'rooms'> | undefined {
    return 'roomId' in event.subjects ? event.subjects.roomId : undefined
}
