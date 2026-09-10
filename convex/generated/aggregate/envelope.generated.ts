/** Generated from proofs/Mythroads/Backend/Aggregate/Envelope.lean. Do not edit by hand. */
import { ConvexError } from 'convex/values'
import type { Envelope, Event, Option } from '../../../shared/engine.system'
import type { GameEvent } from '../../events/validators'
import { directionOf, equipmentSlotOf, guardOf, strikeOf } from './enums.generated'

export function wireNat(value: number): number | undefined {
    if (!Number.isFinite(value)) {
        return undefined
    }
    return Math.trunc(Math.abs(value))
}

export function destinationOf(value: number): number {
    const node = wireNat(value)
    if (node === undefined) {
        throw new ConvexError('That destination cannot be selected.')
    }
    return node
}

export function eventFrom(event: GameEvent, seed: number): Event {
    switch (event.type) {
        case 'room.create': {
            return { _: 'roomCreate', seed: seed }
        }
        case 'player.join': {
            return {
                _: 'playerJoin',
                code: event.subjects.code,
                name: event.data.name,
                color: event.data.color,
            }
        }
        case 'game.start': {
            return { _: 'gameStart' }
        }
        case 'movement.roll': {
            return { _: 'movementRoll' }
        }
        case 'movement.select': {
            return { _: 'movementSelect', destination: destinationOf(event.data.destination) }
        }
        case 'movement.cancel': {
            return { _: 'movementCancel' }
        }
        case 'movement.step': {
            return { _: 'movementStep', destination: destinationOf(event.data.destination) }
        }
        case 'combat.attack': {
            return { _: 'combatAttack', strike: strikeOf(event.data.attack) }
        }
        case 'combat.guard': {
            return { _: 'combatGuard', guard: guardOf(event.data.guard) }
        }
        case 'encounter.resolve': {
            return { _: 'encounterResolve' }
        }
        case 'shop.buy': {
            return { _: 'shopBuy', itemId: event.data.itemId }
        }
        case 'inventory.equip': {
            return {
                _: 'inventoryEquip',
                playerItemId: event.subjects.playerItemId,
                slot: equipmentSlotOf(event.data.slot),
            }
        }
        case 'shop.leave': {
            return { _: 'shopLeave' }
        }
        case 'camera.toggle': {
            return { _: 'cameraToggle' }
        }
        case 'camera.move': {
            return { _: 'cameraMove', direction: directionOf(event.data.direction) }
        }
        case 'camera.zoom': {
            return {
                _: 'cameraZoom',
                delta: event.data.delta < 0 ? { _: 'nearer' } : { _: 'farther' },
            }
        }
    }
    throw new ConvexError('This action is not available right now.')
}

export function subjectOf(event: GameEvent): Option<string> {
    return 'playerId' in event.subjects
        ? { _: 'some', val: event.subjects.playerId }
        : { _: 'none' }
}

export function envelopeFrom(event: GameEvent, actor: string, seed: number): Envelope {
    return { actor: actor, subject: subjectOf(event), event: eventFrom(event, seed), seed: seed }
}
