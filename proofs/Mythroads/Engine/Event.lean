import Mythroads.Engine.Combat
import Mythroads.Game.Events

/-!
# The event alphabet

One inductive lists every transition a client may request. Four total functions
classify each constructor:

* `Event.name` — the wire type, identical to the string in `Game.Events.specs`;
* `Event.authority` — the privilege the sender must hold;
* `Event.durable` — whether the event is appended to the durable `gameEvents` log;
* `permitted` — the phases that accept it.

Because all four are total functions on the inductive, adding a constructor without
classifying it is a *compile error* rather than a runtime hole. That is the single
biggest gain over today's `specs : List EventSpec` manifest, which can silently omit
a case; the `#guard` at the bottom of this file pins the two together so the manifest
can eventually be derived from the inductive instead of maintained beside it.

Three gates guard `step`, and they are separate on purpose: `authorized` (does the
verified actor hold the privilege?), `onTurn` (is it this hero's turn?) and
`permitted` (does the phase accept the event?). Keeping them apart is what makes the
security theorems in `Mythroads.Engine.Theorems` one-liners.
-/

namespace Mythroads.Engine

open Mythroads.Game

/-- The four directions the shared free camera can pan. -/
inductive Direction where
  | up | down | left | right
  deriving Repr, DecidableEq, Inhabited

/-- The wire value of a pan direction. -/
def Direction.label : Direction → String
  | .up => "up" | .down => "down" | .left => "left" | .right => "right"

/-- A single zoom notch. The wire carries `-1` (nearer) or `1` (farther). -/
inductive Zoom where
  /-- Pull the camera in one unit. -/
  | nearer
  /-- Push the camera out one unit. -/
  | farther
  deriving Repr, DecidableEq, Inhabited

/-- The signed delta applied to the camera distance. -/
def Zoom.delta : Zoom → Int
  | .nearer => -1
  | .farther => 1

/-- Every requestable transition, one constructor per wire event type. -/
inductive Event where
  /-- Create a room; the seed enters the room generator here and nowhere else. -/
  | roomCreate (seed : Nat)
  /-- Join or rejoin the room identified by `code` under a hero name and colour. -/
  | playerJoin (code : String) (name : String) (color : String)
  /-- The host starts the adventure. -/
  | gameStart
  /-- The active hero rolls their movement dice. -/
  | movementRoll
  /-- Extend or retract the previewed route by one node. -/
  | movementSelect (destination : NodeId)
  /-- Discard the previewed route and start planning again. -/
  | movementCancel
  /-- Commit the planned route and resolve the landed space. -/
  | movementStep (destination : NodeId)
  /-- Choose how to strike in the attacker half of a battle round. -/
  | combatAttack (strike : Strike)
  /-- Choose a stance against the enemy's reply. -/
  | combatGuard (guard : Combat.Guard)
  /-- Acknowledge a revealed encounter and apply its deltas. -/
  | encounterResolve
  /-- Buy one catalogue item from the shop the hero is standing in. -/
  | shopBuy (itemId : Mythroads.ItemId)
  /-- Move an owned item into an equipment slot. -/
  | inventoryEquip (playerItemId : OwnedItemId) (slot : Inventory.EquipmentSlot)
  /-- Leave the shop and pass the turn. -/
  | shopLeave
  /-- Switch the shared camera between follow and free mode. -/
  | cameraToggle
  /-- Pan the free camera. -/
  | cameraMove (direction : Direction)
  /-- Zoom the free camera by one notch. -/
  | cameraZoom (delta : Zoom)
  deriving Repr, DecidableEq, Inhabited

/-- The envelope actually dispatched: verified actor, subject hero, payload, server seed. -/
structure Envelope where
  /-- Derived server-side from the auth token; never read from the client body. -/
  actor : Mythroads.AuthId
  /-- The hero this event acts upon, when the event names one. -/
  subject : Option Mythroads.PlayerId
  event : Event
  /-- Entropy supplied by the trusted boundary and stored in the log, so replay is faithful. -/
  seed : Nat
  deriving Repr, DecidableEq, Inhabited

namespace Event

/-- The wire type, identical to the `type` field of the matching `Game.Events` spec. -/
def name : Event → String
  | .roomCreate _ => "room.create"
  | .playerJoin _ _ _ => "player.join"
  | .gameStart => "game.start"
  | .movementRoll => "movement.roll"
  | .movementSelect _ => "movement.select"
  | .movementCancel => "movement.cancel"
  | .movementStep _ => "movement.step"
  | .combatAttack _ => "combat.attack"
  | .combatGuard _ => "combat.guard"
  | .encounterResolve => "encounter.resolve"
  | .shopBuy _ => "shop.buy"
  | .inventoryEquip _ _ => "inventory.equip"
  | .shopLeave => "shop.leave"
  | .cameraToggle => "camera.toggle"
  | .cameraMove _ => "camera.move"
  | .cameraZoom _ => "camera.zoom"

/-- Who may send this event, matching `Game.Events.Authority`. -/
def authority : Event → Events.Authority
  | .roomCreate _ | .playerJoin _ _ _ => .account
  | .gameStart => .roomHost
  | .movementRoll | .movementSelect _ | .movementCancel | .movementStep _
  | .combatAttack _ | .combatGuard _ | .encounterResolve
  | .shopBuy _ | .inventoryEquip _ _ | .shopLeave
  | .cameraToggle | .cameraMove _ | .cameraZoom _ => .playerOwner

/-- Whether the event is appended to the durable log. The three camera commands are not. -/
def durable : Event → Bool
  | .cameraToggle | .cameraMove _ | .cameraZoom _ => false
  | _ => true

/--
One representative of every constructor, in `Game.Events.specs` order.

This list is what lets the validator manifest be *derived* from the inductive: the
`#guard` below shows the two agree today, and a new constructor that is not added
here fails that check immediately.
-/
def alphabet : List Event :=
  [.roomCreate 0, .playerJoin "" "" "", .gameStart, .movementRoll, .movementSelect 0,
    .movementCancel, .movementStep 0, .combatAttack (.physical .stab), .combatGuard .high,
    .encounterResolve, .shopBuy "", .inventoryEquip "" .weapon, .shopLeave, .cameraToggle,
    .cameraMove .up, .cameraZoom .farther]

end Event

-- The engine's event names are exactly the validator manifest's event types, in order.
#guard Event.alphabet.map Event.name = Events.specs.map Events.EventSpec.type

-- Durability agrees with the manifest's persistence flag for every event.
#guard Event.alphabet.map Event.durable = Events.specs.map Events.EventSpec.persistent

-- Authority agrees with the manifest for every event.
#guard Event.alphabet.map Event.authority = Events.specs.map Events.EventSpec.authority

-- Exactly the three camera events are ephemeral, decided rather than compiler-trusted.
#guard (Event.alphabet.filter fun e => !e.durable).map Event.name =
  ["camera.toggle", "camera.move", "camera.zoom"]

/--
Does the sender hold the privilege the event demands?

`account` only requires a verified identity, `roomHost` compares against the stored
host, and `playerOwner` compares against the hero's stored owner. The client never
supplies any of these three values; the actor arrives from `ctx.auth`.
-/
def authorized (s : State) (env : Envelope) : Bool :=
  match env.event.authority with
  | .account => env.actor ≠ ""
  | .roomHost => s.host = env.actor
  | .playerOwner =>
      match env.subject with
      | none => false
      | some pid =>
          match s.player? pid with
          | none => false
          | some p => p.owner = env.actor

/--
The phase gate: the one table saying which events each phase accepts. Read top to
bottom it is the game's turn-structure specification.

Two entries are deliberately phase-free. `inventory.equip` is accepted in every
phase because equipping is an inventory operation the boundary only owner-checks,
and the camera commands are accepted everywhere because the shared view must keep
working while a battle or a shop is open.
-/
def permitted (phase : Phase) (e : Event) : Bool :=
  match phase, e with
  | _, .inventoryEquip _ _ => true
  | _, .cameraToggle | _, .cameraMove _ | _, .cameraZoom _ => true
  | _, .playerJoin _ _ _ => true
  | .lobby, .roomCreate _ | .lobby, .gameStart => true
  | .awaitingRoll, .movementRoll => true
  | .moving _ _, .movementSelect _ => true
  | .moving _ _, .movementCancel => true
  | .moving _ _, .movementStep _ => true
  | .combat _ .attackerChoice, .combatAttack _ => true
  | .combat _ .defenderChoice, .combatGuard _ => true
  | .encounter _, .encounterResolve => true
  | .shop _, .shopBuy _ | .shop _, .shopLeave => true
  | _, _ => false

/--
Only the hero whose turn it is may send in-play events.

Lobby events are exempt because there is no turn yet, and `inventory.equip` is
exempt because the generated `equipItem` performs no active-player check. Camera
commands are *not* exempt: the generated `requireCameraControl` demands the active
player, so the shared view is driven by whoever is playing.
-/
def onTurn (s : State) (env : Envelope) : Bool :=
  match env.event with
  | .roomCreate _ | .playerJoin _ _ _ | .gameStart | .inventoryEquip _ _ => true
  | _ =>
      match env.subject, s.active? with
      | some pid, some p => p.id = pid
      | _, _ => false

end Mythroads.Engine
