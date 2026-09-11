import Mythroads.Game.World

/-!
# Derived board-topology requirement

The authoritative graph validates itself. Cycle witnesses are enumerated from local roads, then
canonicalized and deduplicated; callers cannot supply a favorable certificate. Teleport pairs are
landing effects and therefore never participate in road traversal or local cycle discovery.
-/

namespace Mythroads.Game.World

/-- Find a node without inventing a fallback field. -/
def BoardGraph.node? (graph : BoardGraph) (id : Nat) : Option Node :=
  graph.nodes.find? fun node => node.id = id

/-- Whether an identifier names a field on the selected island. -/
def BoardGraph.nodeIsOn (graph : BoardGraph) (island : IslandId) (id : Nat) : Bool :=
  (graph.node? id).any fun node => node.island = island

/-- A road whose two endpoints both belong to the selected island. -/
def BoardGraph.isInternalRoad (graph : BoardGraph) (island : IslandId) (road : Road) : Bool :=
  graph.nodeIsOn island road.origin && graph.nodeIsOn island road.destination

/-- Every road is local to exactly one island; cross-island travel is a landing effect. -/
def BoardGraph.hasOnlyLocalRoads (graph : BoardGraph) : Bool :=
  graph.roads.all fun road =>
    match graph.node? road.origin, graph.node? road.destination with
    | some origin, some destination => origin.island = destination.island
    | _, _ => false

/-- Number of distinct local neighbours; duplicate roads and self-loops cannot inflate degree. -/
def BoardGraph.internalDegree (graph : BoardGraph) (island : IslandId) (id : Nat) : Nat :=
  ((graph.roads.filterMap fun road =>
    if !graph.isInternalRoad island road || road.origin = road.destination then none
    else if road.origin = id then some road.destination
    else if road.destination = id then some road.origin
    else none).eraseDups).length

/-- Number of teleport pairs incident to one field. -/
def BoardGraph.teleportDegree (graph : BoardGraph) (id : Nat) : Nat :=
  (graph.teleports.filter fun pair => pair.first = id || pair.second = id).length

/-- Every teleport field has exactly one teleport counterpart on a different island. -/
def BoardGraph.hasPairedTeleports (graph : BoardGraph) : Bool :=
  (graph.nodes.all fun node =>
    if node.kind = .teleport then graph.teleportDegree node.id = 1
    else graph.teleportDegree node.id = 0) &&
  (graph.teleports.all fun pair =>
    match graph.node? pair.first, graph.node? pair.second with
    | some first, some second =>
        first.kind = .teleport && second.kind = .teleport && first.island != second.island
    | _, _ => false)

/-- Teleport fields may be local leaves; every ordinary field needs two incident local roads. -/
def BoardGraph.hasMinimumInternalDegree (graph : BoardGraph) (island : IslandId) : Bool :=
  graph.nodes.all fun node =>
    if node.island != island then true
    else if node.kind = .teleport then 1 ≤ graph.internalDegree island node.id
    else 2 ≤ graph.internalDegree island node.id

/-- Legal outgoing road destinations, respecting one-way direction. World validity separately
proves that every road remains inside one island. -/
def BoardGraph.roadDestinations (graph : BoardGraph) (position : Nat) : List Nat :=
  graph.roads.filterMap fun road =>
    if road.origin = position then some road.destination
    else if road.bidirectional && road.destination = position then some road.origin
    else none

/-- Every consecutive pair in a path is a legal local movement step. -/
def BoardGraph.pathTraversableInside (graph : BoardGraph) (island : IslandId) : List Nat → Bool
  | [] | [_] => true
  | origin :: destination :: rest =>
      graph.nodeIsOn island origin && graph.nodeIsOn island destination &&
        (graph.roadDestinations origin).contains destination &&
        graph.pathTraversableInside island (destination :: rest)

/-- Total last-element helper used after checking that a cycle is nonempty. -/
def lastNode : List Nat → Nat
  | [] => 0
  | [node] => node
  | _ :: rest => lastNode rest

/-- Whether a path is a closed, directed, simple cycle entirely inside one island. -/
def BoardGraph.isSimpleIslandCycle (graph : BoardGraph) (island : IslandId)
    (cycle : List Nat) : Bool :=
  3 ≤ cycle.length && cycle.Nodup &&
    cycle.all (graph.nodeIsOn island) &&
    graph.pathTraversableInside island cycle &&
    match cycle with
    | [] => false
    | first :: _ => (graph.roadDestinations (lastNode cycle)).contains first

/-- Canonical identity of an undirected edge. -/
def undirectedEdge (origin destination : Nat) : Nat × Nat :=
  if origin ≤ destination then (origin, destination) else (destination, origin)

/-- Consecutive edge identities before adding the closing edge. -/
def pathEdges : List Nat → List (Nat × Nat)
  | [] | [_] => []
  | origin :: destination :: rest =>
      undirectedEdge origin destination :: pathEdges (destination :: rest)

/-- Every edge in a closed cycle, including the closing edge. -/
def cycleEdges : List Nat → List (Nat × Nat)
  | [] => []
  | first :: rest =>
      pathEdges (first :: rest) ++ [undirectedEdge (lastNode (first :: rest)) first]

/-- Rotation or reversal of the same undirected edge set is not a new cycle. -/
def sameCycle (left right : List Nat) : Bool :=
  let leftEdges := cycleEdges left
  let rightEdges := cycleEdges right
  leftEdges.length = rightEdges.length && leftEdges.all rightEdges.contains

/-- Add a cycle only when its edge set has not already been discovered. -/
def addDistinctCycle (cycles : List (List Nat)) (candidate : List Nat) : List (List Nat) :=
  if cycles.any (sameCycle candidate) then cycles else cycles ++ [candidate]

/-- Explore simple paths until they close onto `start`, stopping after five distinct witnesses. -/
def BoardGraph.cyclesFrom (graph : BoardGraph) (island : IslandId) (start : Nat) :
    Nat → Nat → List Nat → List (List Nat) → List (List Nat)
  | 0, _, _, found => found
  | fuel + 1, current, path, found =>
      (graph.roadDestinations current).foldl (fun cycles destination =>
        if 5 ≤ cycles.length then cycles
        else if !graph.nodeIsOn island destination then cycles
        else if destination = start then
          if 3 ≤ path.length then addDistinctCycle cycles path else cycles
        else if path.contains destination then cycles
        else graph.cyclesFrom island start fuel destination (path ++ [destination]) cycles) found

/-- Derive up to five distinct simple local cycles, enough to witness the requirement. -/
def BoardGraph.deriveIslandCycles (graph : BoardGraph) (island : IslandId) : List (List Nat) :=
  let ids := (graph.nodes.filter fun node => node.island = island).map Node.id
  ids.foldl (fun cycles start =>
    if 5 ≤ cycles.length then cycles
    else graph.cyclesFrom island start ids.length start [start] cycles) []

/-- Pairwise cycle identity check retained as an independent guard around deduplication. -/
def pairwiseDistinctCycles : List (List Nat) → Bool
  | [] => true
  | cycle :: rest => rest.all (fun candidate => !sameCycle cycle candidate) &&
      pairwiseDistinctCycles rest

/-- The complete executable contract for one island. -/
def BoardGraph.isIslandValid (graph : BoardGraph) (island : IslandId) : Bool :=
  let cycles := graph.deriveIslandCycles island
  graph.hasMinimumInternalDegree island &&
    5 ≤ cycles.length && pairwiseDistinctCycles cycles &&
    cycles.all (graph.isSimpleIslandCycle island)

/-- The complete executable contract for the authored game world. -/
def BoardGraph.isWorldValid (graph : BoardGraph) : Bool :=
  graph.hasOnlyLocalRoads && graph.hasPairedTeleports &&
    graph.islands.all fun island => graph.isIslandValid island.id

/-- An island has five distinct, traversable simple cycle witnesses and valid field degrees. -/
def BoardGraph.SatisfiesIslandRequirement (graph : BoardGraph) (island : IslandId) : Prop :=
  graph.hasMinimumInternalDegree island = true ∧
    ∃ cycles : List (List Nat), 5 ≤ cycles.length ∧
      pairwiseDistinctCycles cycles = true ∧
      ∀ cycle ∈ cycles, graph.isSimpleIslandCycle island cycle = true

/-- World requirements independent of how the cycle witnesses are found. -/
def BoardGraph.SatisfiesWorldRequirement (graph : BoardGraph) : Prop :=
  graph.hasOnlyLocalRoads = true ∧ graph.hasPairedTeleports = true ∧
    ∀ island ∈ graph.islands, graph.SatisfiesIslandRequirement island.id

/-- Acceptance supplies independently checked witnesses for each island. -/
theorem BoardGraph.isWorldValid_sound {graph : BoardGraph} (valid : graph.isWorldValid = true) :
    graph.SatisfiesWorldRequirement := by
  simp only [isWorldValid, Bool.and_eq_true, List.all_eq_true] at valid
  refine ⟨valid.1.1, valid.1.2, ?_⟩
  intro island member
  have checked := valid.2 island member
  simp only [isIslandValid, Bool.and_eq_true, decide_eq_true_eq, List.all_eq_true] at checked
  exact ⟨checked.1.1.1, graph.deriveIslandCycles island.id,
    checked.1.1.2, checked.1.2, checked.2⟩

-- Permanent build gate: changing the authoritative graph may invalidate compilation.
#guard boardGraph.isWorldValid

end Mythroads.Game.World
