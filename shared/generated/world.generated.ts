/** Generated from proofs/Mythroads/Game/World.lean. Do not edit by hand. */
import type { ShopKind } from '../item.system'

export type SpaceKind = 'castle' | 'combat' | 'event' | 'teleport' | ShopKind
export type IslandId = 'hearth' | 'ember' | 'tide'
export type WorldVisualId = `space.${SpaceKind}`
export type WorldNode = {
    id: number
    label: string
    kind: SpaceKind
    island: IslandId
    visualId: WorldVisualId
    x: number
    z: number
    landmark?: { visualId: 'landmark.castle'; offsetX: number; offsetZ: number }
}
export type WorldRoad = {
    id: string
    from: number
    to: number
    bidirectional: boolean
    via?: { x: number; z: number }[]
    bridge?: boolean
}
export type WorldTeleportPair = { first: number; second: number }
export type WorldIsland = { id: IslandId; label: string; boundary: { x: number; z: number }[] }
export type WorldTerrainFeature =
    | {
          id: string
          kind: 'hill'
          visualId: 'terrain.hill'
          x: number
          z: number
          radius: number
          height: number
      }
    | {
          id: string
          kind: 'lake'
          visualId: 'terrain.lake'
          x: number
          z: number
          radiusX: number
          radiusZ: number
      }
    | {
          id: string
          kind: 'river'
          visualId: 'terrain.river'
          width: number
          points: { x: number; z: number }[]
      }
export type LogicalGameWorld = {
    id: string
    label: string
    version: number
    islands: WorldIsland[]
    nodes: WorldNode[]
    roads: WorldRoad[]
    teleports: WorldTeleportPair[]
    terrain: WorldTerrainFeature[]
}
