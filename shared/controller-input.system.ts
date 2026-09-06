import { availableSteps, getNode } from './board.system'

export type CardinalDirection = 'up' | 'down' | 'left' | 'right'

export function directionForStep(originId: number, destinationId: number): CardinalDirection {
    const origin = getNode(originId)
    const destination = getNode(destinationId)
    const deltaX = destination.x - origin.x
    const deltaZ = destination.z - origin.z

    if (Math.abs(deltaX) > Math.abs(deltaZ)) return deltaX > 0 ? 'right' : 'left'
    return deltaZ > 0 ? 'down' : 'up'
}

export function directionalSteps(position: number, previousPosition?: number) {
    const result: Partial<Record<CardinalDirection, number>> = {}
    for (const destination of availableSteps(position, previousPosition)) {
        result[directionForStep(position, destination)] = destination
    }
    return result
}
