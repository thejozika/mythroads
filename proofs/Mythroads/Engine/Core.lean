import Mythroads.Identity
import Mythroads.Game.World
import Mythroads.Game.Combat
import Mythroads.Game.Encounter
import Mythroads.Game.Inventory
import Mythroads.Game.Random
import Mythroads.Game.Turn

/-!
# Mythroads engine — core vocabulary

This module fixes the vocabulary the whole game definition speaks: identities, the
per-hero sheet, the phase automaton, the room aggregate `State`, the outbound
`Effect` list and the `Error` type.

Three design decisions are load-bearing and are the reason the proofs in
`Mythroads.Engine.Theorems` are short.

1. **The room is the aggregate.** One room is one transaction, one event log and one
   `State`. Heroes are a `List PlayerState` inside it, capped at `maxPlayers`, which
   is why `turn : Nat` can be *proved* to name a real hero.
2. **The phase carries its payload.** `Phase.moving` carries the roll total and the
   planned route, `Phase.combat` carries the whole battle. Cross-field consistency
   checks ("is there a combat row for this room?") become impossible states rather
   than runtime guards. The Convex `rooms.phase` column is the erasure of this
   inductive to a string; `Phase.name` is that erasure.
3. **Exactly two mutation primitives.** Every transition changes heroes through
   `State.mapPlayer` and passes the turn through `State.advanceTurn`, both defined in
   `Mythroads.Engine.Room`. Invariant preservation is therefore two lemmas plus a
   per-event side condition instead of one induction per event.

Nothing here performs a transition; `Mythroads.Engine.Step` is the only place a
`State` changes.
-/

namespace Mythroads.Engine

open Mythroads.Game

/-- A board node identifier; an index into `Game.World.nodes`. -/
abbrev NodeId := Nat

/-- The identifier of a `playerItems` row (one owned copy of a catalogue item). -/
abbrev OwnedItemId := Mythroads.ItemId

/-- One owned copy of a catalogue item, mirroring a `playerItems` row. -/
structure Owned where
  /-- The row identity, which `inventory.equip` names. -/
  rowId : OwnedItemId
  /-- The catalogue identity, which decides price, slots, spell and ward power. -/
  itemId : Mythroads.ItemId
  /-- The slot this copy currently occupies, if any. -/
  equippedSlot : Option Inventory.EquipmentSlot := none
  deriving Repr, DecidableEq, Inhabited

/-- Everything the rules know about one hero; persisted one-to-one with a `players` row. -/
structure PlayerState where
  /-- The `players` row identity. -/
  id : Mythroads.PlayerId
  /-- The account allowed to act for this hero. Empty means "claimed by nobody yet". -/
  owner : Mythroads.AuthId
  name : String
  color : String
  position : NodeId
  /-- The node stepped off last, used to bias route previews forward. -/
  previousPosition : Option NodeId
  gold : Nat
  hp : Nat
  maxHp : Nat
  attack : Nat
  defense : Nat
  magic : Nat
  athletics : Nat
  agility : Nat
  /-- The hero's movement dice, in roll order. -/
  dice : List Nat
  items : List Owned
  deriving Repr, DecidableEq, Inhabited

/-- A route being planned: the previewed endpoint and the nodes walked to reach it. -/
structure Selection where
  playerId : Mythroads.PlayerId
  destination : NodeId
  path : List NodeId
  deriving Repr, DecidableEq, Inhabited

/-- A neutral enemy, so battle records have a default. The catalogue always overwrites it. -/
instance : Inhabited Combat.Enemy where
  default :=
    { name := "", element := .fire, hp := 1, attack := 0, defense := 0, magic := 0,
      athletics := 0, agility := 0, reward := 0 }

/-- Encounter kinds default to the harmless one. -/
instance : Inhabited Encounter.Kind where default := .event

/-- A neutral encounter outcome, so encounter records have a default. -/
instance : Inhabited Encounter.Outcome where
  default :=
    { id := "", kind := .event, title := "", description := "", goldDelta := 0, hpDelta := 0,
      weight := 1 }

/-- Which half of a battle round is owed. Mirrors `combats.phase`. -/
inductive CombatStage where
  /-- The hero owes an attack choice. -/
  | attackerChoice
  /-- The hero owes a guard choice against the enemy's reply. -/
  | defenderChoice
  /-- The battle is over; no further choice is accepted. -/
  | resolved
  deriving Repr, DecidableEq, Inhabited

/-- The live battle, mirroring a `combats` row. Stat penalties are per-battle debuffs. -/
structure CombatState where
  playerId : Mythroads.PlayerId
  spaceId : NodeId
  /-- The catalogue enemy, chosen by `enemyForSpace`. -/
  enemy : Combat.Enemy
  enemyHp : Nat
  enemyDefensePenalty : Nat := 0
  enemyMagicPenalty : Nat := 0
  enemyAthleticsPenalty : Nat := 0
  enemyAgilityPenalty : Nat := 0
  playerDefensePenalty : Nat := 0
  playerMagicPenalty : Nat := 0
  playerAthleticsPenalty : Nat := 0
  playerAgilityPenalty : Nat := 0
  round : Nat := 1
  /-- Display echo of the last resolved exchange. -/
  lastAttack : Option String := none
  lastGuard : Option Combat.Guard := none
  lastDamage : Option Nat := none
  message : String := ""
  deriving Repr, DecidableEq, Inhabited

/-- A revealed encounter awaiting acknowledgement, mirroring an `encounters` row. -/
structure EncounterState where
  playerId : Mythroads.PlayerId
  spaceId : NodeId
  kind : Encounter.Kind
  /-- The drawn outcome; its deltas are applied on `encounter.resolve`. -/
  outcome : Encounter.Outcome
  /-- Index of the outcome inside `outcomesFor kind`, which drives the wheel animation. -/
  wheelIndex : Nat
  resolved : Bool := false
  deriving Repr, DecidableEq, Inhabited

/-- The shared display camera, mirroring a `roomCameras` row. Never part of game history. -/
structure Camera where
  /-- `true` is free mode; `false` follows the active hero. -/
  free : Bool
  /-- Target coordinates in hundredths of a world unit, matching `Game.World.Point`. -/
  targetX : Int
  targetZ : Int
  distance : Nat
  deriving Repr, DecidableEq, Inhabited

/--
The room's phase automaton. `Mythroads.Engine.permitted` says which events each
constructor accepts, so reading these two declarations together *is* the
turn-structure specification.

`moving` deliberately covers both halves of Dokapon-style movement — planning a
route and committing it — because the Convex `rooms.phase` column does: planning
writes a `roomSelections` row while the phase stays `moving`, and `movement.step`
commits the whole planned route at once. `moves` is the roll total and never
shrinks during planning; the movement left to plan is `moves - selection.path.length`.
-/
inductive Phase where
  /-- Before `game.start`: heroes may join. -/
  | lobby
  /-- The active hero owes a dice roll. -/
  | awaitingRoll
  /-- A roll of `moves` was made; `selection` is the route planned so far. -/
  | moving (moves : Nat) (selection : Option Selection)
  /-- A battle is in progress. -/
  | combat (battle : CombatState) (stage : CombatStage)
  /-- An encounter wheel has been spun and awaits acknowledgement. -/
  | encounter (drawn : EncounterState)
  /-- The active hero is standing in a shop of this kind. -/
  | shop (kind : Inventory.ShopKind)
  /-- The room is over. -/
  | finished (winner : Mythroads.PlayerId)
  deriving Repr, DecidableEq, Inhabited

/--
The string the Convex `rooms.phase` column stores for a phase.

The column is narrower than this inductive: it has no `lobby` or `finished` value,
because the row splits those across `rooms.status`, and it collapses the battle stage
into `combatAttack` / `combatDefend`. This function is that erasure.
-/
def Phase.name : Phase → String
  | .lobby => "lobby"
  | .awaitingRoll => "awaitingRoll"
  | .moving _ _ => "moving"
  | .combat _ .defenderChoice => "combatDefend"
  | .combat _ _ => "combatAttack"
  | .encounter _ => "revealingEncounter"
  | .shop _ => "shopping"
  | .finished _ => "finished"

/-- The room aggregate: the entire authoritative game and the unit of transactional consistency. -/
structure State where
  /-- The join code; four characters drawn from the room's own generator. -/
  code : String
  /-- The account that created the room and the only one allowed to start it. -/
  host : Mythroads.AuthId
  /-- Heroes in join order. `advanceTurn` walks this list. -/
  players : List PlayerState
  /-- Index into `players` of the hero whose turn it is. -/
  turn : Nat
  round : Nat
  phase : Phase
  /-- The human-readable banner mirrored into `rooms.message`. -/
  message : String
  /-- The dice faces produced by the most recent `movement.roll`. -/
  lastRoll : List Nat
  /-- Park–Miller generator state. Randomness is *in* the state, never sampled ambiently. -/
  rng : Nat
  /-- How many draws the room has taken; an audit counter mirrored into `rooms.rngCounter`. -/
  rngCounter : Nat
  /-- The ephemeral shared camera. Camera events never touch the durable log. -/
  camera : Option Camera
  /-- Durable events already folded into this state. -/
  version : Nat
  deriving Repr, DecidableEq, Inhabited

/-- A request the Convex interpreter must carry out after the pure transition succeeded. -/
inductive Effect where
  /-- Patch one `players` row from the new state. -/
  | persistPlayer (id : Mythroads.PlayerId)
  /-- Patch the `rooms` row from the new state. -/
  | persistRoom
  /-- Upsert the `combats` row backing `Phase.combat`. -/
  | persistCombat
  /-- Upsert the `encounters` row backing `Phase.encounter`. -/
  | persistEncounter
  /-- Upsert the `roomSelections` row backing a planned route. -/
  | persistSelection
  /-- Delete the `roomSelections` row. -/
  | clearSelection
  /-- Upsert the ephemeral `roomCameras` projection. -/
  | persistCamera
  /-- Append one durable `gameEvents` row under this wire name. -/
  | appendLog (name : String)
  /-- Send an ephemeral message that is never appended to the log. -/
  | notify (message : String)
  deriving Repr, DecidableEq

/-- Every way a transition can be refused. Each maps to one `ConvexError` at the boundary. -/
inductive Error where
  /-- The actor does not hold the authority the event demands. -/
  | unauthorized
  /-- It is not this hero's turn. -/
  | notYourTurn
  /-- The current phase does not accept this event. -/
  | wrongPhase
  /-- The named hero is not in this room. -/
  | unknownPlayer
  /-- The requested route or step is not on the board. -/
  | illegalMove
  /-- The hero cannot afford the purchase. -/
  | insufficientGold
  /-- The room already holds `maxPlayers` heroes. -/
  | roomFull
  /-- `game.start` needs at least one hero. -/
  | roomEmpty
  /-- A hero name was blank after trimming. -/
  | nameRequired
  /-- That hero name belongs to another account. -/
  | nameTaken
  /-- A rejoin supplied the wrong colour for an existing hero. -/
  | colorMismatch
  /-- The room has started and the name is new. -/
  | roomNotInLobby
  /-- No catalogue item carries that identifier. -/
  | unknownItem
  /-- The item is not sold by the shop the hero is standing in. -/
  | itemNotHere
  /-- The item does not support the requested slot, or is not owned. -/
  | cannotEquip
  /-- The technique is not on the equipped grimoire. -/
  | techniqueNotEquipped
  /-- Camera panning and zooming require free mode. -/
  | cameraNotFree
  deriving Repr, DecidableEq

/-- The shared result shape of every transition: a new state plus the effects to interpret. -/
abbrev Outcome := Except Error (State × List Effect)

/-- The maximum number of heroes in one room, matching the `take(4)` bound at the boundary. -/
def maxPlayers : Nat := 4

end Mythroads.Engine
