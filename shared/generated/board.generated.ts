/** Generated from proofs/Mythroads/Game/World.lean. Do not edit by hand. */
import type { ShopKind } from '../item.system'
import type { LogicalGameWorld, SpaceKind, WorldNode } from '../world.type'
import {
    WORLD_ISLANDS,
    WORLD_NODES,
    WORLD_ROADS,
    WORLD_TELEPORTS,
    WORLD_TERRAIN,
} from './board-data.generated.ts'

export type { SpaceKind, WorldNode as BoardNode } from '../world.type'

const node = (definition: Omit<WorldNode, 'visualId'>): WorldNode => ({
    ...definition,
    visualId: `space.${definition.kind}`,
})
export const WORLD: LogicalGameWorld = {
    id: 'mythroads-archipelago',
    label: 'Mythroads Archipelago',
    version: 7,
    islands: WORLD_ISLANDS,
    nodes: WORLD_NODES.map(node),
    roads: WORLD_ROADS,
    teleports: WORLD_TELEPORTS,
    terrain: WORLD_TERRAIN,
}
export const BOARD = WORLD.nodes
export const isShopKind = (kind: SpaceKind): kind is ShopKind =>
    ['armoury', 'jeweller', 'weapons', 'items', 'magic'].includes(kind)
export const getNode = (id: number) => BOARD.find((node) => node.id === id) ?? BOARD[0]
export type AvailableRoad = { destination: number; oneWay: boolean; roadId: string }
export const availableRoads = (position: number): AvailableRoad[] =>
    WORLD.roads.flatMap((road) => {
        if (road.from === position)
            return [{ destination: road.to, oneWay: !road.bidirectional, roadId: road.id }]
        if (road.bidirectional && road.to === position)
            return [{ destination: road.from, oneWay: false, roadId: road.id }]
        return []
    })
export const canTraverse = (from: number, to: number) =>
    availableRoads(from).some((road) => road.destination === to)
export const teleportTarget = (position: number) => {
    const pair = WORLD.teleports.find(
        ({ first, second }) => first === position || second === position,
    )
    if (!pair) return undefined
    return pair.first === position ? pair.second : pair.first
}
export const availableSteps = (position: number, previousPosition?: number) => {
    const destinations = availableRoads(position).map((road) => road.destination)
    const forward = destinations.filter((id) => id !== previousPosition)
    return forward.length > 0 ? forward : destinations
}
export function previewRouteStep(
    origin: number,
    path: number[],
    destination: number,
    totalSteps: number,
) {
    const current = path.at(-1) ?? origin
    const previous = path.length > 1 ? path.at(-2) : path.length === 1 ? origin : undefined
    if (destination === previous && canTraverse(current, destination)) return path.slice(0, -1)
    if (path.length >= totalSteps || !canTraverse(current, destination)) return null
    return [...path, destination]
}
export type ReachableRoute = { destination: number; path: number[] }
export function reachableRoutes(
    position: number,
    previousPosition: number | undefined,
    steps: number,
) {
    if (steps <= 0) return []
    type RouteState = { current: number; previous?: number; path: number[] }
    let routes = new Map<string, RouteState>([
        [
            `${position}:${previousPosition ?? 'none'}`,
            { current: position, previous: previousPosition, path: [] },
        ],
    ])
    for (let step = 0; step < steps; step += 1) {
        const nextRoutes = new Map<string, RouteState>()
        for (const route of routes.values()) {
            for (const destination of availableSteps(route.current, route.previous)) {
                const key = `${destination}:${route.current}`
                if (!nextRoutes.has(key))
                    nextRoutes.set(key, {
                        current: destination,
                        previous: route.current,
                        path: [...route.path, destination],
                    })
            }
        }
        routes = nextRoutes
    }
    const destinations = new Map<number, number[]>()
    for (const route of routes.values())
        if (!destinations.has(route.current)) destinations.set(route.current, route.path)
    return [...destinations].map(([destination, path]) => ({ destination, path }))
}
