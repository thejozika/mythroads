import type { ShopKind } from './item.system'
import type { LogicalGameWorld, SpaceKind, WorldNode, WorldRoad } from './world.type'

export type { SpaceKind, WorldNode as BoardNode } from './world.type'

const node = (definition: Omit<WorldNode, 'visualId'>): WorldNode => ({
    ...definition,
    visualId: `space.${definition.kind}`,
})

const WORLD_NODES: Omit<WorldNode, 'visualId'>[] = [
    { id: 0, label: 'Camp', kind: 'start', x: -5.8, z: 0 },
    { id: 1, label: 'Mossling', kind: 'combat', x: -5.6, z: 1.25 },
    { id: 2, label: 'Armoury', kind: 'armoury', x: -5, z: 2.45 },
    { id: 3, label: 'Lucky Well', kind: 'event', x: -4.1, z: 3.45 },
    { id: 4, label: 'Boar Wood', kind: 'combat', x: -2.9, z: 4.15 },
    { id: 5, label: 'Jeweller', kind: 'jeweller', x: -1.5, z: 4.55 },
    { id: 6, label: 'Wishing Tree', kind: 'event', x: 0, z: 4.7 },
    { id: 7, label: 'Bandit Pass', kind: 'combat', x: 1.5, z: 4.5 },
    { id: 8, label: 'Weapons', kind: 'weapons', x: 2.9, z: 4 },
    { id: 9, label: 'Moon Shrine', kind: 'event', x: 4, z: 3.2 },
    { id: 10, label: 'Slime Fen', kind: 'combat', x: 4.9, z: 2.2 },
    { id: 11, label: 'Item Shop', kind: 'items', x: 5.5, z: 1.1 },
    { id: 12, label: 'Odd Crossroad', kind: 'event', x: 5.8, z: -0.2 },
    { id: 13, label: 'Wolf Hollow', kind: 'combat', x: 5.5, z: -1.5 },
    { id: 14, label: 'Magic Shop', kind: 'magic', x: 4.8, z: -2.6 },
    { id: 15, label: 'Fallen Star', kind: 'event', x: 3.8, z: -3.5 },
    { id: 16, label: 'Goblin Gate', kind: 'combat', x: 2.6, z: -4.2 },
    { id: 17, label: 'Sunken Cache', kind: 'event', x: 1.2, z: -4.6 },
    { id: 18, label: 'Briar Knight', kind: 'combat', x: -0.3, z: -4.7 },
    { id: 19, label: 'Wayfarer', kind: 'items', x: -1.8, z: -4.4 },
    { id: 20, label: 'Old Ferry', kind: 'event', x: -3.1, z: -3.9 },
    { id: 21, label: 'Thorn Beast', kind: 'combat', x: -4.3, z: -3 },
    { id: 22, label: 'Cloud Altar', kind: 'event', x: -5.1, z: -2 },
    { id: 23, label: 'Windy Bluff', kind: 'event', x: -5.6, z: -1 },
]

const ringRoads: WorldRoad[] = WORLD_NODES.map((current, index) => ({
    id: `ring-${current.id}`,
    from: current.id,
    to: WORLD_NODES[(index + 1) % WORLD_NODES.length].id,
    bidirectional: true,
}))

const SHORTCUTS: WorldRoad[] = [
    {
        id: 'armoury-bluff',
        from: 2,
        to: 23,
        bidirectional: true,
        via: [{ x: -4.55, z: 0.65 }],
    },
    {
        id: 'slime-magic-current',
        from: 10,
        to: 14,
        bidirectional: false,
        via: [
            { x: 4.1, z: -0.1 },
            { x: 4.15, z: -1.45 },
        ],
    },
    {
        id: 'goblin-ferry-run',
        from: 16,
        to: 20,
        bidirectional: false,
        via: [
            { x: 0.55, z: -3.45 },
            { x: -1.45, z: -3.35 },
        ],
    },
]

export const WORLD: LogicalGameWorld = {
    id: 'wildroot-crossing',
    label: 'Wildroot Crossing',
    version: 3,
    nodes: WORLD_NODES.map(node),
    roads: [...ringRoads, ...SHORTCUTS],
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
