import Mythroads.Game.World

namespace Mythroads.Game.World

open Mythroads.Convex Mythroads.Convex.TypeScript

private def coordinate (value : Int) : String := toString value ++ " / 100"
private def point (value : Point) : String :=
  "{ x: " ++ coordinate value.x ++ ", z: " ++ coordinate value.z ++ " }"

private def renderNode (value : Node) : String :=
  "    { id: " ++ toString value.id ++ ", label: " ++ quote value.label ++ ", kind: " ++
  quote value.kind.label ++ ", x: " ++ coordinate value.point.x ++ ", z: " ++
  coordinate value.point.z ++ ", island: " ++ quote value.island.label ++ (match value.landmark with
    | none => ""
    | some mark => ", landmark: { visualId: 'landmark.castle', offsetX: " ++
      coordinate mark.offsetX ++ ", offsetZ: " ++ coordinate mark.offsetZ ++ " }") ++ " },\n"

private def renderRoad (value : Road) : String :=
  "    road(" ++ toString value.origin ++ ", " ++ toString value.destination ++
  (if value.bidirectional ∧ !value.bridge then ""
   else ", { bidirectional: " ++ (if value.bidirectional then "true" else "false") ++
     (if value.bridge then ", bridge: true" else "") ++ " }") ++ "),\n"

private def renderTeleport (value : TeleportPair) : String :=
  "    { first: " ++ toString value.first ++ ", second: " ++ toString value.second ++ " },\n"

private def renderIsland (value : Island) : String :=
  "    { id: " ++ quote value.id.label ++ ", label: " ++ quote value.label ++
  ", boundary: [" ++ join ", " (value.boundary.map point) ++ "] },\n"

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

private def boardDataBody : String :=
  "export const WORLD_NODES: Omit<WorldNode, 'visualId'>[] = [\n" ++
  join "" (boardGraph.nodes.map renderNode) ++ "]\n" ++
  "const road = (from: number, to: number, options: Partial<WorldRoad> = {}): WorldRoad => ({ id: `${from}-${to}`, from, to, bidirectional: true, ...options })\n" ++
  "export const WORLD_ROADS: WorldRoad[] = [\n" ++ join "" (boardGraph.roads.map renderRoad) ++
  "]\nexport const WORLD_TELEPORTS: WorldTeleportPair[] = [\n" ++
  join "" (boardGraph.teleports.map renderTeleport) ++
  "]\nexport const WORLD_ISLANDS: WorldIsland[] = [\n" ++
  join "" (boardGraph.islands.map renderIsland) ++ "]\n" ++
  "export const WORLD_TERRAIN: WorldTerrainFeature[] = [\n" ++
  join "" (terrain.map renderTerrain) ++ "]\n"

private def boardBody : String :=
  "export type { SpaceKind, WorldNode as BoardNode } from '../world.type'\n" ++
  "const node = (definition: Omit<WorldNode, 'visualId'>): WorldNode => ({ ...definition, visualId: `space.${definition.kind}` })\n" ++
  "export const WORLD: LogicalGameWorld = { id: 'mythroads-archipelago', label: 'Mythroads Archipelago', version: 7, islands: WORLD_ISLANDS, nodes: WORLD_NODES.map(node), roads: WORLD_ROADS, teleports: WORLD_TELEPORTS, terrain: WORLD_TERRAIN }\n" ++
  "export const BOARD = WORLD.nodes\n" ++
  "export const isShopKind = (kind: SpaceKind): kind is ShopKind => ['armoury', 'jeweller', 'weapons', 'items', 'magic'].includes(kind)\n" ++
  "export const getNode = (id: number) => BOARD.find((node) => node.id === id) ?? BOARD[0]\n" ++
  "export type AvailableRoad = { destination: number; oneWay: boolean; roadId: string }\n" ++
  "export const availableRoads = (position: number): AvailableRoad[] => WORLD.roads.flatMap((road) => { if (road.from === position) return [{ destination: road.to, oneWay: !road.bidirectional, roadId: road.id }]; if (road.bidirectional && road.to === position) return [{ destination: road.from, oneWay: false, roadId: road.id }]; return [] })\n" ++
  "export const canTraverse = (from: number, to: number) => availableRoads(from).some((road) => road.destination === to)\n" ++
  "export const teleportTarget = (position: number) => { const pair = WORLD.teleports.find(({ first, second }) => first === position || second === position); if (!pair) return undefined; return pair.first === position ? pair.second : pair.first }\n" ++
  "export const availableSteps = (position: number, previousPosition?: number) => { const destinations = availableRoads(position).map((road) => road.destination); const forward = destinations.filter((id) => id !== previousPosition); return forward.length > 0 ? forward : destinations }\n" ++
  "export function previewRouteStep(origin: number, path: number[], destination: number, totalSteps: number) { const current = path.at(-1) ?? origin; const previous = path.length > 1 ? path.at(-2) : path.length === 1 ? origin : undefined; if (destination === previous && canTraverse(current, destination)) return path.slice(0, -1); if (path.length >= totalSteps || !canTraverse(current, destination)) return null; return [...path, destination] }\n" ++
  "export type ReachableRoute = { destination: number; path: number[] }\n" ++
  "export function reachableRoutes(position: number, previousPosition: number | undefined, steps: number) { if (steps <= 0) return []; type RouteState = { current: number; previous?: number; path: number[] }; let routes = new Map<string, RouteState>([[`${position}:${previousPosition ?? 'none'}`, { current: position, previous: previousPosition, path: [] }]]); for (let step = 0; step < steps; step += 1) { const nextRoutes = new Map<string, RouteState>(); for (const route of routes.values()) { for (const destination of availableSteps(route.current, route.previous)) { const key = `${destination}:${route.current}`; if (!nextRoutes.has(key)) nextRoutes.set(key, { current: destination, previous: route.current, path: [...route.path, destination] }) } } routes = nextRoutes } const destinations = new Map<number, number[]>(); for (const route of routes.values()) if (!destinations.has(route.current)) destinations.set(route.current, route.path); return [...destinations].map(([destination, path]) => ({ destination, path })) }\n"

private def typesBody : String :=
  "export type SpaceKind = 'castle' | 'combat' | 'event' | 'teleport' | ShopKind\n" ++
  "export type IslandId = 'hearth' | 'ember' | 'tide'\n" ++
  "export type WorldVisualId = `space.${SpaceKind}`\n" ++
  "export type WorldNode = { id: number; label: string; kind: SpaceKind; island: IslandId; visualId: WorldVisualId; x: number; z: number; landmark?: { visualId: 'landmark.castle'; offsetX: number; offsetZ: number } }\n" ++
  "export type WorldRoad = { id: string; from: number; to: number; bidirectional: boolean; via?: { x: number; z: number }[]; bridge?: boolean }\n" ++
  "export type WorldTeleportPair = { first: number; second: number }\n" ++
  "export type WorldIsland = { id: IslandId; label: string; boundary: { x: number; z: number }[] }\n" ++
  "export type WorldTerrainFeature = { id: string; kind: 'hill'; visualId: 'terrain.hill'; x: number; z: number; radius: number; height: number } | { id: string; kind: 'lake'; visualId: 'terrain.lake'; x: number; z: number; radiusX: number; radiusZ: number } | { id: string; kind: 'river'; visualId: 'terrain.river'; width: number; points: { x: number; z: number }[] }\n" ++
  "export type LogicalGameWorld = { id: string; label: string; version: number; islands: WorldIsland[]; nodes: WorldNode[]; roads: WorldRoad[]; teleports: WorldTeleportPair[]; terrain: WorldTerrainFeature[] }\n"

private def controllerInputBody : String :=
  "export type CardinalDirection = 'up' | 'down' | 'left' | 'right'\n" ++
  "export function directionForStep(originId: number, destinationId: number): CardinalDirection { const origin = getNode(originId); const destination = getNode(destinationId); const deltaX = destination.x - origin.x; const deltaZ = destination.z - origin.z; if (Math.abs(deltaX) > Math.abs(deltaZ)) return deltaX > 0 ? 'right' : 'left'; return deltaZ > 0 ? 'down' : 'up' }\n" ++
  "export function directionalRoads(position: number) { const result: Partial<Record<CardinalDirection, number>> = {}; for (const { destination } of availableRoads(position)) result[directionForStep(position, destination)] = destination; return result }\n" ++
  "export function directionalTargets(originId: number, destinations: number[]) { const origin = getNode(originId); const result: Partial<Record<CardinalDirection, number>> = {}; const distance: Partial<Record<CardinalDirection, number>> = {}; for (const destinationId of destinations) { if (destinationId === originId) continue; const destination = getNode(destinationId); const direction = directionForStep(originId, destinationId); const squared = (destination.x - origin.x) ** 2 + (destination.z - origin.z) ** 2; if (distance[direction] === undefined || squared < (distance[direction] ?? Infinity)) { result[direction] = destinationId; distance[direction] = squared } } return result }\n"

def boardModule : Module where
  provenance := some "proofs/Mythroads/Game/World.lean"
  imports := [
    { source := "./board-data.generated.ts", bindings := [
      { name := "WORLD_ISLANDS" }, { name := "WORLD_NODES" }, { name := "WORLD_ROADS" },
      { name := "WORLD_TELEPORTS" }, { name := "WORLD_TERRAIN" }] },
    { source := "../item.system", bindings := [{ name := "ShopKind", isType := true }] },
    { source := "../world.type", bindings := [
      { name := "LogicalGameWorld", isType := true }, { name := "SpaceKind", isType := true },
      { name := "WorldNode", isType := true }] }]
  items := [.raw boardBody]

def boardDataModule : Module where
  provenance := some "proofs/Mythroads/Game/World.lean"
  imports := [{ source := "../world.type", bindings := [
    { name := "WorldIsland", isType := true }, { name := "WorldNode", isType := true },
    { name := "WorldRoad", isType := true }, { name := "WorldTeleportPair", isType := true },
    { name := "WorldTerrainFeature", isType := true }] }]
  items := [.raw boardDataBody]

def worldTypesModule : Module where
  provenance := some "proofs/Mythroads/Game/World.lean"
  imports := [{ source := "../item.system", bindings := [{ name := "ShopKind", isType := true }] }]
  items := [.raw typesBody]

def controllerInputModule : Module where
  provenance := some "proofs/Mythroads/Game/World.lean"
  imports := [{ source := "../board.system.ts", bindings := [
    { name := "availableRoads" }, { name := "getNode" }] }]
  items := [.raw controllerInputBody]

end Mythroads.Game.World
