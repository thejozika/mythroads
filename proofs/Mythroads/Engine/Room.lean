import Mythroads.Engine.Core

/-!
# The room aggregate: reading it, and the only two ways to change it

`Mythroads.Engine.Core` declares the shapes. This module supplies the *operations*, and
there are deliberately very few of them.

Board lookup is made **total** here. `Game.World` stores the graph as a list, and the
generated `getNode` falls back to the first node for an unknown id; `node` does the
same, so no rule ever carries a partial lookup or an `Option` it must handle twice.

Everything else is the two mutation primitives. `State.mapPlayer` is the only way a
hero changes and `State.advanceTurn` is the only way the turn moves, so the invariant
proofs are two lemmas and a per-event side condition rather than one induction per
event. `withPhase` and `draw` are conveniences over record update, not further ways to
mutate: neither touches the hero list or the cursor, which is exactly why their
invariant lemmas are `rfl`.
-/

namespace Mythroads.Engine

open Mythroads.Game

/-! ## Board access

`Game.World` is the authoritative graph. These wrappers make node lookup *total*, exactly
as the generated `getNode` does by falling back to the first node.
-/

/-- The node with this id, falling back to the castle, mirroring the generated `getNode`. -/
def node (id : NodeId) : World.Node :=
  (World.nodes.find? fun candidate => candidate.id = id).getD
    { id := 0, label := "Hearthkeep", kind := .castle, point := { x := -540, z := 320 } }

/-- The gameplay kind of a node. Total by construction. -/
def kindOf (id : NodeId) : World.SpaceKind := (node id).kind

/-- The shop a node houses, if it houses one, mirroring the generated `isShopKind`. -/
def shopKindOf : World.SpaceKind → Option Inventory.ShopKind
  | .armoury => some .armoury
  | .jeweller => some .jeweller
  | .weapons => some .weapons
  | .items => some .items
  | .magic => some .magic
  | _ => none

/-! ## The only state-mutation primitives -/

namespace State

/-- Look up a hero by row id. -/
def player? (s : State) (pid : Mythroads.PlayerId) : Option PlayerState :=
  s.players.find? fun p => p.id = pid

/-- The hero whose turn it is, if the room has any heroes. -/
def active? (s : State) : Option PlayerState := s.players[s.turn]?

/--
**Primitive 1.** Rewrite exactly one hero. The list shape — and therefore the validity
of `turn` — is preserved by construction, which is what `ok_mapPlayer` exploits.
-/
def mapPlayer (s : State) (pid : Mythroads.PlayerId) (f : PlayerState → PlayerState) : State :=
  { s with players := s.players.map fun p => if p.id = pid then f p else p }

/--
**Primitive 2.** Pass the turn: advance the cursor with wraparound, bump the round on
wraparound, clear the per-turn payloads and ask the next hero for a roll. This is the
Lean form of the generated `advanceTurn`.
-/
def advanceTurn (s : State) (message : String) : State :=
  if 0 < s.players.length then
    { s with
      turn := Game.Turn.nextIndex s.turn s.players.length,
      round := Game.Turn.nextRound s.round s.turn s.players.length,
      phase := .awaitingRoll,
      lastRoll := [],
      message }
  else s

/-- Change the phase and banner only. A convenience wrapper, not a third primitive. -/
def withPhase (s : State) (phase : Phase) (message : String) : State :=
  { s with phase, message }

/-- Take one bounded draw from the room generator, advancing it and the audit counter. -/
def draw (s : State) (bound : Nat) : Nat × State :=
  let d := Game.Random.drawBounded s.rng bound
  (d.value, { s with rng := d.state, rngCounter := s.rngCounter + 1 })

end State

/-- Damage, clamped at zero. HP can only fall here, so the `hp ≤ maxHp` bound survives. -/
def PlayerState.damaged (p : PlayerState) (amount : Nat) : PlayerState :=
  { p with hp := p.hp - amount }

/-- Healing, clamped at `maxHp`. -/
def PlayerState.healed (p : PlayerState) (amount : Nat) : PlayerState :=
  { p with hp := min p.maxHp (p.hp + amount) }

/-- Spending, clamped at zero; callers check affordability first to raise the right error. -/
def PlayerState.spent (p : PlayerState) (amount : Nat) : PlayerState :=
  { p with gold := p.gold - amount }

/-- Apply a signed delta to a `Nat` resource, clamping at zero, as `Math.max(0, …)` does. -/
def applyDelta (value : Nat) (delta : Int) : Nat :=
  ((value : Int) + delta).toNat


end Mythroads.Engine
