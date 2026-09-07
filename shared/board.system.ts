import type { ShopKind } from './item.system'
import type { LogicalGameWorld, SpaceKind, WorldNode, WorldRoad } from './world.type'

export type { SpaceKind, WorldNode as BoardNode } from './world.type'

const node = (definition: Omit<WorldNode, 'visualId'>): WorldNode => ({
    ...definition,
    visualId: `space.${definition.kind}`,
})

const WORLD_NODES: Omit<WorldNode, 'visualId'>[] = [
    { id: 0, label: 'Camp', kind: 'start', x: -7.4, z: 0 },
    { id: 1, label: 'Mossling', kind: 'combat', x: -7.1, z: 1.7 },
    { id: 2, label: 'Armoury', kind: 'armoury', x: -6.3, z: 3.3 },
    { id: 3, label: 'Lucky Well', kind: 'event', x: -5.1, z: 4.6 },
    { id: 4, label: 'Boar Wood', kind: 'combat', x: -3.6, z: 5.5 },
    { id: 5, label: 'Jeweller', kind: 'jeweller', x: -1.8, z: 6.1 },
    { id: 6, label: 'Wishing Tree', kind: 'event', x: 0, z: 6.3 },
    { id: 7, label: 'Bandit Pass', kind: 'combat', x: 1.9, z: 6.1 },
    { id: 8, label: 'Weapons', kind: 'weapons', x: 3.7, z: 5.5 },
    { id: 9, label: 'Moon Shrine', kind: 'event', x: 5.2, z: 4.5 },
    { id: 10, label: 'Slime Fen', kind: 'combat', x: 6.4, z: 3.2 },
    { id: 11, label: 'Item Shop', kind: 'items', x: 7.1, z: 1.6 },
    { id: 12, label: 'Odd Crossroad', kind: 'event', x: 7.4, z: 0 },
    { id: 13, label: 'Wolf Hollow', kind: 'combat', x: 7, z: -1.8 },
    { id: 14, label: 'Magic Shop', kind: 'magic', x: 6.2, z: -3.4 },
    { id: 15, label: 'Fallen Star', kind: 'event', x: 5, z: -4.7 },
    { id: 16, label: 'Goblin Gate', kind: 'combat', x: 3.4, z: -5.6 },
    { id: 17, label: 'Sunken Cache', kind: 'event', x: 1.7, z: -6.1 },
    { id: 18, label: 'Briar Knight', kind: 'combat', x: 0, z: -6.3 },
    { id: 19, label: 'Wayfarer', kind: 'items', x: -1.8, z: -6.1 },
    { id: 20, label: 'Old Ferry', kind: 'event', x: -3.6, z: -5.5 },
    { id: 21, label: 'Thorn Beast', kind: 'combat', x: -5.2, z: -4.5 },
    { id: 22, label: 'Cloud Altar', kind: 'event', x: -6.4, z: -3.1 },
    { id: 23, label: 'Windy Bluff', kind: 'event', x: -7.1, z: -1.6 },
]

const ringRoads: WorldRoad[] = WORLD_NODES.map((current, index) => ({
    id: `ring-${current.id}`,
    from: current.id,
    to: WORLD_NODES[(index + 1) % WORLD_NODES.length].id,
    bidirectional: true,
}))

const SHORTCUTS: WorldRoad[] = [
    { id: 'ferry-armoury', from: 2, to: 20, bidirectional: true },
    { id: 'boar-current', from: 4, to: 18, bidirectional: false },
    { id: 'bandit-magic', from: 7, to: 14, bidirectional: true },
    { id: 'slime-wish', from: 10, to: 6, bidirectional: false },
    { id: 'crossroad-cache', from: 12, to: 17, bidirectional: true },
    { id: 'star-weapons', from: 15, to: 8, bidirectional: false },
]

export const WORLD: LogicalGameWorld = {
    id: 'wildroot-crossing',
    label: 'Wildroot Crossing',
    version: 2,
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
