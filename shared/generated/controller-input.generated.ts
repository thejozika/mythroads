/** Generated from proofs/Mythroads/Game/World.lean. Do not edit by hand. */
import { availableRoads, getNode } from '../board.system.ts'

export type CardinalDirection = 'up' | 'down' | 'left' | 'right'
export function directionForStep(originId: number, destinationId: number): CardinalDirection {
    const origin = getNode(originId)
    const destination = getNode(destinationId)
    const deltaX = destination.x - origin.x
    const deltaZ = destination.z - origin.z
    if (Math.abs(deltaX) > Math.abs(deltaZ)) return deltaX > 0 ? 'right' : 'left'
    return deltaZ > 0 ? 'down' : 'up'
}
export function directionalRoads(position: number) {
    const result: Partial<Record<CardinalDirection, number>> = {}
    for (const { destination } of availableRoads(position))
        result[directionForStep(position, destination)] = destination
    return result
}
export function directionalTargets(originId: number, destinations: number[]) {
    const origin = getNode(originId)
    const result: Partial<Record<CardinalDirection, number>> = {}
    const distance: Partial<Record<CardinalDirection, number>> = {}
    for (const destinationId of destinations) {
        if (destinationId === originId) continue
        const destination = getNode(destinationId)
        const direction = directionForStep(originId, destinationId)
        const squared = (destination.x - origin.x) ** 2 + (destination.z - origin.z) ** 2
        if (distance[direction] === undefined || squared < (distance[direction] ?? Infinity)) {
            result[direction] = destinationId
            distance[direction] = squared
        }
    }
    return result
}
