import type { ShopKind } from './item.system'

export type SpaceKind = 'start' | 'combat' | 'event' | ShopKind
export type WorldVisualId = `space.${SpaceKind}`

export type WorldNode = {
    id: number
    label: string
    kind: SpaceKind
    visualId: WorldVisualId
    x: number
    z: number
    neighbors: number[]
}

export type LogicalGameWorld = {
    id: string
    label: string
    version: number
    nodes: WorldNode[]
}
