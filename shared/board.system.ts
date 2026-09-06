export type SpaceKind = 'start' | 'combat' | 'event'

export type BoardNode = {
    id: number
    label: string
    kind: SpaceKind
    x: number
    z: number
    neighbors: number[]
}

export const BOARD: BoardNode[] = [
    { id: 0, label: 'Camp', kind: 'start', x: -4.5, z: 0, neighbors: [1, 11] },
    { id: 1, label: 'Mossling', kind: 'combat', x: -3.5, z: 1.8, neighbors: [0, 2] },
    { id: 2, label: 'Lucky Well', kind: 'event', x: -1.7, z: 2.4, neighbors: [1, 3, 10] },
    { id: 3, label: 'Boar', kind: 'combat', x: 0, z: 2.8, neighbors: [2, 4] },
    { id: 4, label: 'Wishing Tree', kind: 'event', x: 1.8, z: 2.2, neighbors: [3, 5, 8] },
    { id: 5, label: 'Bandit', kind: 'combat', x: 3.7, z: 1.6, neighbors: [4, 6] },
    { id: 6, label: 'Moon Shrine', kind: 'event', x: 4.5, z: 0, neighbors: [5, 7] },
    { id: 7, label: 'Slime', kind: 'combat', x: 3.6, z: -1.8, neighbors: [6, 8] },
    { id: 8, label: 'Odd Merchant', kind: 'event', x: 1.7, z: -2.3, neighbors: [7, 9, 4] },
    { id: 9, label: 'Wolf', kind: 'combat', x: 0, z: -2.8, neighbors: [8, 10] },
    { id: 10, label: 'Fallen Star', kind: 'event', x: -1.8, z: -2.3, neighbors: [9, 11, 2] },
    { id: 11, label: 'Goblin', kind: 'combat', x: -3.7, z: -1.6, neighbors: [10, 0] },
]

export const SPACE_COLORS: Record<SpaceKind, string> = {
    start: '#f7cf67',
    combat: '#ee5d62',
    event: '#8d7cf6',
}

export const getNode = (id: number) => BOARD.find((node) => node.id === id) ?? BOARD[0]

export const availableSteps = (position: number, previousPosition?: number) => {
    const neighbors = getNode(position).neighbors
    const forward = neighbors.filter((id) => id !== previousPosition)
    return forward.length > 0 ? forward : neighbors
}
