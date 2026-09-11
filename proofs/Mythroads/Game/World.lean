import Mythroads.Convex.Module

namespace Mythroads.Game.World

open Mythroads.Convex
open Mythroads.Convex.TypeScript

/-- The gameplay role attached to a board node. Rendering derives its visual identifier from this value. -/
inductive SpaceKind where
  | castle | combat | event | armoury | jeweller | weapons | items | magic | teleport
  deriving Repr, DecidableEq

/-- Converts a space kind to the stable lowercase value emitted into TypeScript. -/
def SpaceKind.label : SpaceKind → String
  | .castle => "castle" | .combat => "combat" | .event => "event"
  | .armoury => "armoury" | .jeweller => "jeweller" | .weapons => "weapons"
  | .items => "items" | .magic => "magic"
  | .teleport => "teleport"

/-- Stable identity of one disconnected landmass. Teleport landings connect the islands. -/
inductive IslandId where | hearth | ember | tide deriving Repr, DecidableEq

def IslandId.label : IslandId → String
  | .hearth => "hearth" | .ember => "ember" | .tide => "tide"

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
  island : IslandId := .hearth
  deriving Repr, DecidableEq

/-- A directed local graph edge. `bidirectional` adds the reverse edge; `bridge` is visual metadata. -/
structure Road where
  origin : Nat
  destination : Nat
  bidirectional : Bool := true
  bridge : Bool := false
  deriving Repr, DecidableEq

/-- A landing-triggered, bidirectional pairing between teleport fields on different islands. -/
structure TeleportPair where
  first : Nat
  second : Nat
  deriving Repr, DecidableEq

/-- The visible shoreline of one independently rendered map. -/
structure Island where
  id : IslandId
  label : String
  boundary : List Point
  deriving Repr, DecidableEq

/-- The complete traversable board: playable nodes plus the roads connecting them. -/
structure BoardGraph where
  nodes : List Node
  roads : List Road
  teleports : List TeleportPair
  islands : List Island
  deriving Repr, DecidableEq

/-- Non-playable world geometry positioned around and beneath the graph. -/
inductive Terrain where
  | lake (id : String) (point : Point) (radiusX radiusZ : Nat)
  | river (id : String) (width : Nat) (points : List Point)
  | hill (id : String) (point : Point) (radius height : Nat)
  deriving Repr, DecidableEq

private def n (id : Nat) (label : String) (kind : SpaceKind) (x z : Int)
    (island : IslandId := .hearth) : Node :=
  { id, label, kind, point := { x, z }, island }

/-- Three disconnected shorelines. Landing on paired teleport fields moves between them. -/
def islands : List Island := [
  { id := .hearth, label := "Hearthwild", boundary := [
      { x := -650, z := -270 }, { x := -310, z := -305 }, { x := 80, z := -285 },
      { x := 370, z := -300 }, { x := 620, z := -220 }, { x := 650, z := 110 },
      { x := 610, z := 380 }, { x := 410, z := 550 }, { x := 20, z := 575 },
      { x := -320, z := 555 }, { x := -620, z := 465 }, { x := -680, z := 120 }] },
  { id := .ember, label := "Embercrag", boundary := [
      { x := -1510, z := -760 }, { x := -1360, z := -950 }, { x := -1050, z := -990 },
      { x := -790, z := -850 }, { x := -760, z := -560 }, { x := -930, z := -390 },
      { x := -1240, z := -370 }, { x := -1490, z := -500 }] },
  { id := .tide, label := "Tideglass", boundary := [
      { x := 760, z := -590 }, { x := 900, z := -870 }, { x := 1190, z := -1010 },
      { x := 1480, z := -860 }, { x := 1530, z := -570 }, { x := 1330, z := -390 },
      { x := 1010, z := -370 }, { x := 790, z := -450 }] }
]

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
  n 25 "Ash Orchard" .combat 150 (-120), n 26 "Pilgrim Stone" .event 300 (-120),
  n 27 "Ember Gate" .teleport (-420) (-170), n 28 "Tide Gate" .teleport 420 (-170),
  n 30 "Hearth Gate" .teleport (-980) (-520) .ember,
  n 31 "Cinder Market" .items (-1160) (-500) .ember,
  n 32 "Ash Drake" .combat (-1340) (-570) .ember,
  n 33 "Forge Shrine" .event (-1390) (-760) .ember,
  n 34 "Crag Armoury" .armoury (-1210) (-880) .ember,
  n 35 "Magma Maw" .combat (-960) (-820) .ember,
  n 36 "Tide Gate" .teleport (-880) (-650) .ember,
  n 37 "Ember Jeweller" .jeweller (-1130) (-690) .ember,
  n 50 "Hearth Gate" .teleport 980 (-520) .tide,
  n 51 "Coral Cache" .event 1160 (-480) .tide,
  n 52 "Reef Stalker" .combat 1360 (-560) .tide,
  n 53 "Pearl Jeweller" .jeweller 1420 (-750) .tide,
  n 54 "Sunken Library" .magic 1240 (-900) .tide,
  n 55 "Storm Crab" .combat 990 (-850) .tide,
  n 56 "Ember Gate" .teleport 860 (-660) .tide,
  n 57 "Drift Shop" .items 1150 (-700) .tide
]

private def r (origin destination : Nat) (bidirectional := true) (bridge := false) : Road :=
  { origin, destination, bidirectional, bridge }

/-- The board's edges. A road with `bidirectional := false` may only be traversed origin-to-destination. -/
def roads : List Road := [
  r 0 1, r 0 3, r 1 2, r 2 3, r 3 4, r 4 5, r 5 6 true true, r 6 7, r 7 8, r 8 9,
  r 2 10, r 10 11, r 11 12, r 12 13 false true, r 13 14, r 14 15, r 15 9,
  r 10 16, r 16 17, r 17 18, r 18 19 true true, r 19 20, r 20 21, r 21 15,
  r 16 22, r 22 23, r 23 24, r 24 25 true true, r 25 26, r 26 21,
  r 4 11, r 6 13, r 8 15, r 12 18, r 14 20, r 17 23, r 20 25,
  r 23 27, r 25 28,
  r 30 31, r 31 32, r 32 33, r 33 34, r 34 35, r 35 36, r 36 37, r 37 31,
  r 32 37, r 34 37,
  r 50 51, r 51 52, r 52 53, r 53 54, r 54 55, r 55 56, r 56 57, r 57 51,
  r 52 57, r 54 57
]

/-- Teleport destinations are landing effects, never graph edges or movement steps. -/
def teleports : List TeleportPair := [
  { first := 27, second := 30 },
  { first := 28, second := 50 },
  { first := 36, second := 56 }
]

/-- The authoritative graph value consumed by movement rules and TypeScript generation. -/
def boardGraph : BoardGraph where
  nodes := nodes
  roads := roads
  teleports := teleports
  islands := islands

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

/-- The paired arrival field for a teleport landing, if this node is a declared endpoint. -/
def BoardGraph.teleportTarget? (graph : BoardGraph) (id : Nat) : Option Nat :=
  graph.teleports.findSome? fun pair =>
    if pair.first = id then some pair.second
    else if pair.second = id then some pair.first
    else none

/-- Looks up movement options in the authoritative board graph. -/
def availableRoads (position : Nat) : List AvailableRoad := boardGraph.availableRoads position

/-- Checks a movement step against the authoritative board graph. -/
def canTraverse (origin destination : Nat) : Bool :=
  boardGraph.canTraverse origin destination

theorem oneWayBridgeAllowsForward : canTraverse 12 13 = true := by decide
theorem oneWayBridgeRejectsReverse : canTraverse 13 12 = false := by decide
theorem castleIsStart : (nodes.find? fun node => node.id = 0).map Node.kind = some .castle := by decide
theorem everyRoadEndpointExists : roads.all (fun road =>
    nodes.any (fun node => node.id = road.origin) ∧
    nodes.any (fun node => node.id = road.destination)) = true := by
  decide

theorem teleportPairsConnectEveryIslandPair :
    boardGraph.teleportTarget? 27 = some 30 ∧
    boardGraph.teleportTarget? 28 = some 50 ∧
    boardGraph.teleportTarget? 36 = some 56 := by decide
end Mythroads.Game.World
