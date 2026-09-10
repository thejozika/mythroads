import Mythroads.Convex.TypeScript

namespace Mythroads.Game.World

open Mythroads.Convex.TypeScript

/-- The gameplay role attached to a board node. Rendering derives its visual identifier from this value. -/
inductive SpaceKind where
  | castle | combat | event | armoury | jeweller | weapons | items | magic
  deriving Repr, DecidableEq

/-- Converts a space kind to the stable lowercase value emitted into TypeScript. -/
def SpaceKind.label : SpaceKind → String
  | .castle => "castle" | .combat => "combat" | .event => "event"
  | .armoury => "armoury" | .jeweller => "jeweller" | .weapons => "weapons"
  | .items => "items" | .magic => "magic"

/-- An integer board-space coordinate. Emitters divide values by 100 for Three.js world units. -/
structure Point where
  x : Int
  z : Int
  deriving Repr, DecidableEq

/-- A landmark's offset from its associated playable node. Landmarks do not replace the node itself. -/
structure Landmark where
  offsetX : Int
  offsetZ : Int
  deriving Repr, DecidableEq

/-- A playable destination in the logical board graph. -/
structure Node where
  id : Nat
  label : String
  kind : SpaceKind
  point : Point
  landmark : Option Landmark := none
  deriving Repr, DecidableEq

/-- A directed graph edge. `bidirectional` adds the reverse edge; `bridge` is visual metadata. -/
structure Road where
  origin : Nat
  destination : Nat
  bidirectional : Bool := true
  bridge : Bool := false
  deriving Repr, DecidableEq

/-- The complete traversable board: playable nodes plus the roads connecting them. -/
structure BoardGraph where
  nodes : List Node
  roads : List Road
  deriving Repr, DecidableEq

/-- Non-playable world geometry positioned around and beneath the graph. -/
inductive Terrain where
  | lake (id : String) (point : Point) (radiusX radiusZ : Nat)
  | river (id : String) (width : Nat) (points : List Point)
  | hill (id : String) (point : Point) (radius height : Nat)
  deriving Repr, DecidableEq

private def n (id : Nat) (label : String) (kind : SpaceKind) (x z : Int) : Node :=
  { id, label, kind, point := { x, z } }

/-- Every playable space in Wildroot Crossing. Node IDs are persistent game-state references. -/
def nodes : List Node := [
  { id := 0, label := "Hearthkeep", kind := .castle, point := { x := -540, z := 320 },
    landmark := some { offsetX := 0, offsetZ := 90 } },
  n 1 "Mossling" .combat (-420) 320, n 2 "Armoury Junction" .armoury (-300) 320,
  n 3 "Lucky Well" .event (-300) 450, n 4 "Boar Wood" .combat (-170) 450,
  n 5 "Jeweller" .jeweller (-40) 450, n 6 "Wishing Tree" .event 90 450,
  n 7 "Bandit Pass" .combat 220 450, n 8 "Weapons" .weapons 350 450,
  n 9 "Moon Shrine" .event 480 340, n 10 "Slime Fen" .combat (-300) 180,
  n 11 "Item Shop" .items (-170) 180, n 12 "Odd Crossroad" .event (-40) 180,
  n 13 "Wolf Hollow" .combat 90 180, n 14 "Magic Shop" .magic 220 180,
  n 15 "Fallen Star" .event 350 180, n 16 "Goblin Gate" .combat (-300) 40,
  n 17 "Sunken Cache" .event (-170) 40, n 18 "Briar Knight" .combat (-40) 40,
  n 19 "Wayfarer" .items 90 40, n 20 "Old Ferry" .event 220 40,
  n 21 "Thorn Beast" .combat 350 40, n 22 "Cloud Altar" .event (-300) (-120),
  n 23 "Windy Bluff" .event (-150) (-120), n 24 "River Cache" .items 0 (-120),
  n 25 "Ash Orchard" .combat 150 (-120), n 26 "Pilgrim Stone" .event 300 (-120)
]

private def r (origin destination : Nat) (bidirectional := true) (bridge := false) : Road :=
  { origin, destination, bidirectional, bridge }

/-- The board's edges. A road with `bidirectional := false` may only be traversed origin-to-destination. -/
def roads : List Road := [
  r 0 1, r 1 2, r 2 3, r 3 4, r 4 5, r 5 6 true true, r 6 7, r 7 8, r 8 9,
  r 2 10, r 10 11, r 11 12, r 12 13 false true, r 13 14, r 14 15, r 15 9,
  r 10 16, r 16 17, r 17 18, r 18 19 true true, r 19 20, r 20 21, r 21 15,
  r 16 22, r 22 23, r 23 24, r 24 25 true true, r 25 26, r 26 21,
  r 4 11, r 6 13, r 8 15, r 12 18, r 14 20, r 17 23, r 20 25
]

/-- The authoritative graph value consumed by movement rules and TypeScript generation. -/
def boardGraph : BoardGraph where
  nodes := nodes
  roads := roads

/-- Decorative and collision-free terrain; terrain never decides legal movement. -/
def terrain : List Terrain := [
  .lake "heartmere" { x := 25, z := -200 } 105 42,
  .river "silverrun" 52 [
    { x := 20, z := 560 }, { x := 25, z := 420 }, { x := 15, z := 260 },
    { x := 25, z := 110 }, { x := 20, z := -20 }, { x := 25, z := -200 }
  ],
  .hill "greenwatch-hill" { x := -450, z := -30 } 90 52
]

/-- A legal outgoing movement option as seen from one node. -/
structure AvailableRoad where
  destination : Nat
  oneWay : Bool
  deriving Repr, DecidableEq

/-- Computes outgoing edges, including reverse edges only for bidirectional roads. -/
def BoardGraph.availableRoads (graph : BoardGraph) (position : Nat) : List AvailableRoad :=
  graph.roads.filterMap fun road =>
    if road.origin = position then
      some { destination := road.destination, oneWay := !road.bidirectional }
    else if road.bidirectional ∧ road.destination = position then
      some { destination := road.origin, oneWay := false }
    else none

/-- Decides whether the graph contains a legal edge between two node IDs. -/
def BoardGraph.canTraverse (graph : BoardGraph) (origin destination : Nat) : Bool :=
  (graph.availableRoads origin).any fun road => road.destination = destination

/-- Looks up movement options in the authoritative board graph. -/
def availableRoads (position : Nat) : List AvailableRoad := boardGraph.availableRoads position

/-- Checks a movement step against the authoritative board graph. -/
def canTraverse (origin destination : Nat) : Bool :=
  boardGraph.canTraverse origin destination

theorem oneWayBridgeAllowsForward : canTraverse 12 13 = true := by native_decide
theorem oneWayBridgeRejectsReverse : canTraverse 13 12 = false := by native_decide
theorem castleIsStart : (nodes.find? fun node => node.id = 0).map Node.kind = some .castle := by native_decide
theorem everyRoadEndpointExists : roads.all (fun road =>
    nodes.any (fun node => node.id = road.origin) ∧
    nodes.any (fun node => node.id = road.destination)) = true := by
  native_decide

private def coordinate (value : Int) : String := toString value ++ " / 100"
private def point (value : Point) : String :=
  "{ x: " ++ coordinate value.x ++ ", z: " ++ coordinate value.z ++ " }"

private def renderNode (value : Node) : String :=
  "    { id: " ++ toString value.id ++ ", label: " ++ quote value.label ++ ", kind: " ++
  quote value.kind.label ++ ", x: " ++ coordinate value.point.x ++ ", z: " ++
  coordinate value.point.z ++ (match value.landmark with
    | none => ""
    | some mark => ", landmark: { visualId: 'landmark.castle', offsetX: " ++
      coordinate mark.offsetX ++ ", offsetZ: " ++ coordinate mark.offsetZ ++ " }") ++ " },\n"

private def renderRoad (value : Road) : String :=
  "    road(" ++ toString value.origin ++ ", " ++ toString value.destination ++
  (if value.bidirectional ∧ !value.bridge then ""
   else ", { bidirectional: " ++ (if value.bidirectional then "true" else "false") ++
     (if value.bridge then ", bridge: true" else "") ++ " }") ++ "),\n"

private def renderTerrain : Terrain → String
  | .lake id center radiusX radiusZ =>
      "    { id: " ++ quote id ++ ", kind: 'lake', visualId: 'terrain.lake', x: " ++
      coordinate center.x ++ ", z: " ++ coordinate center.z ++ ", radiusX: " ++
      coordinate radiusX ++ ", radiusZ: " ++ coordinate radiusZ ++ " },\n"
  | .river id width points =>
      "    { id: " ++ quote id ++ ", kind: 'river', visualId: 'terrain.river', width: " ++
      coordinate width ++ ", points: [" ++ join ", " (points.map point) ++ "] },\n"
  | .hill id center radius height =>
      "    { id: " ++ quote id ++ ", kind: 'hill', visualId: 'terrain.hill', x: " ++
      coordinate center.x ++ ", z: " ++ coordinate center.z ++ ", radius: " ++
      coordinate radius ++ ", height: " ++ coordinate height ++ " },\n"

def emitTypeScript : String :=
  "/** Generated from proofs/Mythroads/Game/World.lean. Do not edit by hand. */\n" ++
  "import type { ShopKind } from '../item.system'\nimport type { LogicalGameWorld, SpaceKind, WorldNode, WorldRoad } from '../world.type'\n\n" ++
  "export type { SpaceKind, WorldNode as BoardNode } from '../world.type'\n" ++
  "const node = (definition: Omit<WorldNode, 'visualId'>): WorldNode => ({ ...definition, visualId: `space.${definition.kind}` })\n" ++
  "const WORLD_NODES: Omit<WorldNode, 'visualId'>[] = [\n" ++
  join "" (boardGraph.nodes.map renderNode) ++ "]\n" ++
  "const road = (from: number, to: number, options: Partial<WorldRoad> = {}): WorldRoad => ({ id: `${from}-${to}`, from, to, bidirectional: true, ...options })\n" ++
  "const WORLD_ROADS: WorldRoad[] = [\n" ++
  join "" (boardGraph.roads.map renderRoad) ++ "]\n" ++
  "export const WORLD: LogicalGameWorld = { id: 'wildroot-crossing', label: 'Wildroot Crossing', version: 5, nodes: WORLD_NODES.map(node), roads: WORLD_ROADS, terrain: [\n" ++
  join "" (terrain.map renderTerrain) ++ "] }\n" ++
  "export const BOARD = WORLD.nodes\n" ++
  "export const isShopKind = (kind: SpaceKind): kind is ShopKind => ['armoury', 'jeweller', 'weapons', 'items', 'magic'].includes(kind)\n" ++
  "export const getNode = (id: number) => BOARD.find((node) => node.id === id) ?? BOARD[0]\n" ++
  "export type AvailableRoad = { destination: number; oneWay: boolean; roadId: string }\n" ++
  "export const availableRoads = (position: number): AvailableRoad[] => WORLD.roads.flatMap((road) => { if (road.from === position) return [{ destination: road.to, oneWay: !road.bidirectional, roadId: road.id }]; if (road.bidirectional && road.to === position) return [{ destination: road.from, oneWay: false, roadId: road.id }]; return [] })\n" ++
  "export const canTraverse = (from: number, to: number) => availableRoads(from).some((road) => road.destination === to)\n" ++
  "export const availableSteps = (position: number, previousPosition?: number) => { const destinations = availableRoads(position).map((road) => road.destination); const forward = destinations.filter((id) => id !== previousPosition); return forward.length > 0 ? forward : destinations }\n" ++
  "export function previewRouteStep(origin: number, path: number[], destination: number, totalSteps: number) { const current = path.at(-1) ?? origin; const previous = path.length > 1 ? path.at(-2) : path.length === 1 ? origin : undefined; if (destination === previous && canTraverse(current, destination)) return path.slice(0, -1); if (path.length >= totalSteps || !canTraverse(current, destination)) return null; return [...path, destination] }\n" ++
  "export type ReachableRoute = { destination: number; path: number[] }\n" ++
  "export function reachableRoutes(position: number, previousPosition: number | undefined, steps: number) { if (steps <= 0) return []; type RouteState = { current: number; previous?: number; path: number[] }; let routes = new Map<string, RouteState>([[`${position}:${previousPosition ?? 'none'}`, { current: position, previous: previousPosition, path: [] }]]); for (let step = 0; step < steps; step += 1) { const nextRoutes = new Map<string, RouteState>(); for (const route of routes.values()) { for (const destination of availableSteps(route.current, route.previous)) { const key = `${destination}:${route.current}`; if (!nextRoutes.has(key)) nextRoutes.set(key, { current: destination, previous: route.current, path: [...route.path, destination] }) } } routes = nextRoutes } const destinations = new Map<number, number[]>(); for (const route of routes.values()) if (!destinations.has(route.current)) destinations.set(route.current, route.path); return [...destinations].map(([destination, path]) => ({ destination, path })) }\n"

def emitTypes : String :=
  "/** Generated from proofs/Mythroads/Game/World.lean. Do not edit by hand. */\n" ++
  "import type { ShopKind } from '../item.system'\n\n" ++
  "export type SpaceKind = 'castle' | 'combat' | 'event' | ShopKind\n" ++
  "export type WorldVisualId = `space.${SpaceKind}`\n" ++
  "export type WorldNode = { id: number; label: string; kind: SpaceKind; visualId: WorldVisualId; x: number; z: number; landmark?: { visualId: 'landmark.castle'; offsetX: number; offsetZ: number } }\n" ++
  "export type WorldRoad = { id: string; from: number; to: number; bidirectional: boolean; via?: { x: number; z: number }[]; bridge?: boolean }\n" ++
  "export type WorldTerrainFeature = { id: string; kind: 'hill'; visualId: 'terrain.hill'; x: number; z: number; radius: number; height: number } | { id: string; kind: 'lake'; visualId: 'terrain.lake'; x: number; z: number; radiusX: number; radiusZ: number } | { id: string; kind: 'river'; visualId: 'terrain.river'; width: number; points: { x: number; z: number }[] }\n" ++
  "export type LogicalGameWorld = { id: string; label: string; version: number; nodes: WorldNode[]; roads: WorldRoad[]; terrain: WorldTerrainFeature[] }\n"

def emitControllerInput : String :=
  "/** Generated from proofs/Mythroads/Game/World.lean. Do not edit by hand. */\n" ++
  "import { availableRoads, getNode } from '../board.system.ts'\n\n" ++
  "export type CardinalDirection = 'up' | 'down' | 'left' | 'right'\n" ++
  "export function directionForStep(originId: number, destinationId: number): CardinalDirection { const origin = getNode(originId); const destination = getNode(destinationId); const deltaX = destination.x - origin.x; const deltaZ = destination.z - origin.z; if (Math.abs(deltaX) > Math.abs(deltaZ)) return deltaX > 0 ? 'right' : 'left'; return deltaZ > 0 ? 'down' : 'up' }\n" ++
  "export function directionalRoads(position: number) { const result: Partial<Record<CardinalDirection, number>> = {}; for (const { destination } of availableRoads(position)) result[directionForStep(position, destination)] = destination; return result }\n" ++
  "export function directionalTargets(originId: number, destinations: number[]) { const origin = getNode(originId); const result: Partial<Record<CardinalDirection, number>> = {}; const distance: Partial<Record<CardinalDirection, number>> = {}; for (const destinationId of destinations) { if (destinationId === originId) continue; const destination = getNode(destinationId); const direction = directionForStep(originId, destinationId); const squared = (destination.x - origin.x) ** 2 + (destination.z - origin.z) ** 2; if (distance[direction] === undefined || squared < (distance[direction] ?? Infinity)) { result[direction] = destinationId; distance[direction] = squared } } return result }\n"

end Mythroads.Game.World
