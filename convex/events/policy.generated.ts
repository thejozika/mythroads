/** Generated from proofs/Mythroads/Engine/Event.lean. Do not edit by hand. */
import type { Id } from '../_generated/dataModel'
import type { GameEvent } from './validators'

export const GAME_EVENT_SCHEMA_VERSION = 1 as const

export function isPersistentGameEvent(event: GameEvent): boolean {
    switch (event.type) {
        case 'room.create': {
            return true
        }
        case 'player.join': {
            return true
        }
        case 'game.start': {
            return true
        }
        case 'movement.roll': {
            return true
        }
        case 'movement.select': {
            return true
        }
        case 'movement.cancel': {
            return true
        }
        case 'movement.step': {
            return true
        }
        case 'combat.attack': {
            return true
        }
        case 'combat.guard': {
            return true
        }
        case 'encounter.resolve': {
            return true
        }
        case 'shop.buy': {
            return true
        }
        case 'inventory.equip': {
            return true
        }
        case 'shop.leave': {
            return true
        }
        case 'camera.toggle': {
            return false
        }
        case 'camera.move': {
            return false
        }
        case 'camera.zoom': {
            return false
        }
    }
    return false
}

export function eventRoomId(event: GameEvent): Id<'rooms'> | undefined {
    return 'roomId' in event.subjects ? event.subjects.roomId : undefined
}
