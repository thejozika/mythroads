import Mythroads.Game.World.Requirement

/-!
# Topology regression cases

These checks remove real roads and teleport pairs from the authored world. Acceptance must fail
for broken degree or pairing requirements, and repeated cycle rotations must count only once.
-/

namespace Mythroads.Game.World

/-- Recreate Embercrag's original single ring by removing its two new chords. -/
def singleRingWorld : BoardGraph :=
  { boardGraph with roads := boardGraph.roads.filter fun road =>
      !((road.origin = 32 || road.origin = 34) && road.destination = 37) }

/-- Remove the castle's second connection, leaving an ordinary field at degree one. -/
def leafCastleWorld : BoardGraph :=
  { boardGraph with roads := boardGraph.roads.filter fun road =>
      !(road.origin = 0 && road.destination = 3) }

/-- Remove one pairing while retaining its teleport fields. -/
def unpairedWorld : BoardGraph := { boardGraph with teleports := boardGraph.teleports.drop 1 }

#guard !singleRingWorld.isWorldValid
#guard (singleRingWorld.deriveIslandCycles .ember).length = 1
#guard !leafCastleWorld.isWorldValid
#guard !unpairedWorld.isWorldValid
#guard sameCycle [1, 2, 3] [2, 3, 1]
#guard sameCycle [1, 2, 3] [3, 2, 1]
#guard !pairwiseDistinctCycles [[1, 2, 3], [3, 2, 1]]
#guard !boardGraph.canTraverse 27 30
#guard boardGraph.teleportTarget? 27 = some 30
#guard boardGraph.teleportTarget? 30 = some 27

end Mythroads.Game.World
