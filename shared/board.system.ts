import type { ShopKind } from './item.system'
import type { LogicalGameWorld, SpaceKind, WorldNode, WorldRoad } from './world.type'

export type { SpaceKind, WorldNode as BoardNode } from './world.type'

const node = (definition: Omit<WorldNode, 'visualId'>): WorldNode => ({
    ...definition,
    visualId: `space.${definition.kind}`,
})

const WORLD_NODES: Omit<WorldNode, 'visualId'>[] = [
    {
        id: 0,
        label: 'Hearthkeep',
        kind: 'castle',
        x: -5.4,
        z: 3.2,
        landmark: { visualId: 'landmark.castle', offsetX: 0, offsetZ: 0.9 },
    },
    { id: 1, label: 'Mossling', kind: 'combat', x: -4.2, z: 3.2 },
    { id: 2, label: 'Armoury Junction', kind: 'armoury', x: -3, z: 3.2 },
    { id: 3, label: 'Lucky Well', kind: 'event', x: -3, z: 4.5 },
    { id: 4, label: 'Boar Wood', kind: 'combat', x: -1.7, z: 4.5 },
    { id: 5, label: 'Jeweller', kind: 'jeweller', x: -0.4, z: 4.5 },
    { id: 6, label: 'Wishing Tree', kind: 'event', x: 0.9, z: 4.5 },
    { id: 7, label: 'Bandit Pass', kind: 'combat', x: 2.2, z: 4.5 },
    { id: 8, label: 'Weapons', kind: 'weapons', x: 3.5, z: 4.5 },
    { id: 9, label: 'Moon Shrine', kind: 'event', x: 4.8, z: 3.4 },
    { id: 10, label: 'Slime Fen', kind: 'combat', x: -3, z: 1.8 },
    { id: 11, label: 'Item Shop', kind: 'items', x: -1.7, z: 1.8 },
    { id: 12, label: 'Odd Crossroad', kind: 'event', x: -0.4, z: 1.8 },
    { id: 13, label: 'Wolf Hollow', kind: 'combat', x: 0.9, z: 1.8 },
    { id: 14, label: 'Magic Shop', kind: 'magic', x: 2.2, z: 1.8 },
    { id: 15, label: 'Fallen Star', kind: 'event', x: 3.5, z: 1.8 },
    { id: 16, label: 'Goblin Gate', kind: 'combat', x: -3, z: 0.4 },
    { id: 17, label: 'Sunken Cache', kind: 'event', x: -1.7, z: 0.4 },
    { id: 18, label: 'Briar Knight', kind: 'combat', x: -0.4, z: 0.4 },
    { id: 19, label: 'Wayfarer', kind: 'items', x: 0.9, z: 0.4 },
    { id: 20, label: 'Old Ferry', kind: 'event', x: 2.2, z: 0.4 },
    { id: 21, label: 'Thorn Beast', kind: 'combat', x: 3.5, z: 0.4 },
    { id: 22, label: 'Cloud Altar', kind: 'event', x: -3, z: -1.2 },
    { id: 23, label: 'Windy Bluff', kind: 'event', x: -1.5, z: -1.2 },
    { id: 24, label: 'River Cache', kind: 'items', x: 0, z: -1.2 },
    { id: 25, label: 'Ash Orchard', kind: 'combat', x: 1.5, z: -1.2 },
    { id: 26, label: 'Pilgrim Stone', kind: 'event', x: 3, z: -1.2 },
]

const road = (from: number, to: number, options: Partial<WorldRoad> = {}): WorldRoad => ({
    id: `${from}-${to}`,
    from,
    to,
    bidirectional: true,
    ...options,
})

const WORLD_ROADS: WorldRoad[] = [
    road(0, 1),
    road(1, 2),
    road(2, 3),
    road(3, 4),
    road(4, 5),
    road(5, 6, { bridge: true }),
    road(6, 7),
    road(7, 8),
    road(8, 9),
    road(2, 10),
    road(10, 11),
    road(11, 12),
    road(12, 13, { bidirectional: false, bridge: true }),
    road(13, 14),
    road(14, 15),
    road(15, 9),
    road(10, 16),
    road(16, 17),
    road(17, 18),
    road(18, 19, { bridge: true }),
    road(19, 20),
    road(20, 21),
    road(21, 15),
    road(16, 22),
    road(22, 23),
    road(23, 24),
    road(24, 25, { bridge: true }),
    road(25, 26),
    road(26, 21),
    road(4, 11),
    road(6, 13),
    road(8, 15),
    road(12, 18),
    road(14, 20),
    road(17, 23),
    road(20, 25),
]

export const WORLD: LogicalGameWorld = {
    id: 'wildroot-crossing',
    label: 'Wildroot Crossing',
    version: 5,
    nodes: WORLD_NODES.map(node),
    roads: WORLD_ROADS,
    terrain: [
        {
            id: 'heartmere',
            kind: 'lake',
            visualId: 'terrain.lake',
            x: 0.25,
            z: -2,
            radiusX: 1.05,
            radiusZ: 0.42,
        },
        {
            id: 'silverrun',
            kind: 'river',
            visualId: 'terrain.river',
            width: 0.52,
            points: [
                { x: 0.2, z: 5.6 },
                { x: 0.25, z: 4.2 },
                { x: 0.15, z: 2.6 },
                { x: 0.25, z: 1.1 },
                { x: 0.2, z: -0.2 },
                { x: 0.25, z: -2 },
            ],
        },
        {
            id: 'greenwatch-hill',
            kind: 'hill',
            visualId: 'terrain.hill',
            x: -4.5,
            z: -0.3,
            radius: 0.9,
            height: 0.52,
        },
    ],
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
                if (!nextRoutes.has(key)) {
                    nextRoutes.set(key, {
                        current: destination,
                        previous: route.current,
                        path: [...route.path, destination],
                    })
                }
            }
        }
        routes = nextRoutes
    }
    const destinations = new Map<number, number[]>()
    for (const route of routes.values())
        if (!destinations.has(route.current)) destinations.set(route.current, route.path)
    return [...destinations].map(([destination, path]) => ({ destination, path }))
}
