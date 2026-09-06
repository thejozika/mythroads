import type { ShopKind } from './item.system'
import type { LogicalGameWorld, SpaceKind, WorldNode } from './world.type'

export type { SpaceKind, WorldNode as BoardNode } from './world.type'

const node = (definition: Omit<WorldNode, 'visualId'>): WorldNode => ({
    ...definition,
    visualId: `space.${definition.kind}`,
})

const WORLD_NODES: Omit<WorldNode, 'visualId'>[] = [
    { id: 0, label: 'Camp', kind: 'start', x: -6.4, z: 0, neighbors: [1, 19] },
    { id: 1, label: 'Mossling', kind: 'combat', x: -6, z: 1.6, neighbors: [0, 2] },
    { id: 2, label: 'Armoury', kind: 'armoury', x: -5.1, z: 3, neighbors: [1, 3, 18] },
    { id: 3, label: 'Lucky Well', kind: 'event', x: -3.8, z: 4.1, neighbors: [2, 4] },
    { id: 4, label: 'Boar Wood', kind: 'combat', x: -2, z: 4.7, neighbors: [3, 5, 16] },
    { id: 5, label: 'Jeweller', kind: 'jeweller', x: 0, z: 4.9, neighbors: [4, 6] },
    { id: 6, label: 'Wishing Tree', kind: 'event', x: 2, z: 4.6, neighbors: [5, 7, 14] },
    { id: 7, label: 'Bandit Pass', kind: 'combat', x: 3.9, z: 4, neighbors: [6, 8] },
    { id: 8, label: 'Weapons', kind: 'weapons', x: 5.3, z: 2.9, neighbors: [7, 9, 12] },
    { id: 9, label: 'Moon Shrine', kind: 'event', x: 6.2, z: 1.5, neighbors: [8, 10] },
    { id: 10, label: 'Slime Fen', kind: 'combat', x: 6.5, z: 0, neighbors: [9, 11] },
    { id: 11, label: 'Item Shop', kind: 'items', x: 6, z: -1.7, neighbors: [10, 12] },
    { id: 12, label: 'Odd Crossroad', kind: 'event', x: 5, z: -3.2, neighbors: [11, 13, 8] },
    { id: 13, label: 'Wolf Hollow', kind: 'combat', x: 3.5, z: -4.2, neighbors: [12, 14] },
    { id: 14, label: 'Magic Shop', kind: 'magic', x: 1.7, z: -4.8, neighbors: [13, 15, 6] },
    { id: 15, label: 'Fallen Star', kind: 'event', x: -0.4, z: -4.9, neighbors: [14, 16] },
    { id: 16, label: 'Goblin Gate', kind: 'combat', x: -2.5, z: -4.6, neighbors: [15, 17, 4] },
    { id: 17, label: 'Old Ferry', kind: 'event', x: -4.2, z: -3.8, neighbors: [16, 18] },
    { id: 18, label: 'Thorn Beast', kind: 'combat', x: -5.5, z: -2.7, neighbors: [17, 19, 2] },
    { id: 19, label: 'Windy Bluff', kind: 'event', x: -6.2, z: -1.3, neighbors: [18, 0] },
]

export const WORLD: LogicalGameWorld = {
    id: 'wildroot-crossing',
    label: 'Wildroot Crossing',
    version: 1,
    nodes: WORLD_NODES.map(node),
}

export const BOARD = WORLD.nodes

export const isShopKind = (kind: SpaceKind): kind is ShopKind =>
    ['armoury', 'jeweller', 'weapons', 'items', 'magic'].includes(kind)

export const getNode = (id: number) => BOARD.find((node) => node.id === id) ?? BOARD[0]

export const availableSteps = (position: number, previousPosition?: number) => {
    const neighbors = getNode(position).neighbors
    const forward = neighbors.filter((id) => id !== previousPosition)
    return forward.length > 0 ? forward : neighbors
}
