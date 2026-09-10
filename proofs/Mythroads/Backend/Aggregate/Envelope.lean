import Mythroads.Backend.Aggregate.Support
import Mythroads.Game.Events

namespace Mythroads.Backend.Aggregate.Envelope

/-!
# From the wire to the alphabet

`convex/events/validators.generated.ts` describes what a phone may send; `Mythroads.Engine.Event`
describes what the rules accept. They are the same sixteen events, but they are shaped differently
on purpose: the wire splits every event into `subjects` and `data`, because `subjects` is what the
authorization layer reads and `data` is what the client chose, while the engine constructor takes
its payload as arguments and takes the *actor* from the envelope rather than the body.

`envelopeFrom` is that translation, and it is the only place where a value a client sent becomes a
value the rules see. Two fields never come from the body:

* `actor` is derived server-side from `ctx.auth`;
* `subject` is the hero the event addresses, which the three gates compare against the stored owner
  and the turn cursor.

The table below is keyed on the wire type, and the `#guard` under it holds that key set to
`Game.Events.specs` — so an event added to the protocol without a translation stops the build.

## Numbers are coerced at this edge

The compiled engine represents every `Nat` as a JavaScript `number` and its arithmetic assumes a
non-negative integer: `natMod` is `%`, and a Park–Miller state that is negative, fractional or `NaN`
never recovers. A `v.number()` validator admits all three, so every client number that becomes a
`Nat` passes through `wireNat` first — `Math.trunc(Math.abs(x))`, and `undefined` for a non-finite
value — and each caller decides what an absent value means: `room.create` falls back to the clock,
`movement.select` and `movement.step` refuse with the sentence an unselectable destination already
has. `camera.zoom`'s `delta` needs no coercion because its validator is a literal union.
-/

open Mythroads.Convex Mythroads.Convex.TypeScript
open Mythroads.Backend.Aggregate

/-- `event`, the wire event being translated. -/
def event : Expr := id "event"

/-- `event.subjects`. -/
def subjects : Expr := prop event "subjects"

/-- `event.data`. -/
def payload : Expr := prop event "data"

/-- One wire event and the engine constructor it denotes. -/
structure Wire where
  /-- The wire `type` literal. -/
  type : String
  /-- The engine constructor tag. -/
  tag : String
  /-- The constructor's fields, read out of the wire event. -/
  fields : List (String × Expr) := []

/-- The sixteen translations, in validator order. -/
def wires : List Wire :=
  [{ type := "room.create", tag := "roomCreate", fields := [("seed", id "seed")] },
    { type := "player.join", tag := "playerJoin", fields :=
      [("code", prop subjects "code"), ("name", prop payload "name"),
        ("color", prop payload "color")] },
    { type := "game.start", tag := "gameStart" },
    { type := "movement.roll", tag := "movementRoll" },
    { type := "movement.select", tag := "movementSelect", fields :=
      [("destination", call (id "destinationOf") [prop payload "destination"])] },
    { type := "movement.cancel", tag := "movementCancel" },
    { type := "movement.step", tag := "movementStep", fields :=
      [("destination", call (id "destinationOf") [prop payload "destination"])] },
    { type := "combat.attack", tag := "combatAttack", fields :=
      [("strike", call (id "strikeOf") [prop payload "attack"])] },
    { type := "combat.guard", tag := "combatGuard", fields :=
      [("guard", call (id "guardOf") [prop payload "guard"])] },
    { type := "encounter.resolve", tag := "encounterResolve" },
    { type := "shop.buy", tag := "shopBuy", fields := [("itemId", prop payload "itemId")] },
    { type := "inventory.equip", tag := "inventoryEquip", fields :=
      [("playerItemId", prop subjects "playerItemId"),
        ("slot", call (id "equipmentSlotOf") [prop payload "slot"])] },
    { type := "shop.leave", tag := "shopLeave" },
    { type := "camera.toggle", tag := "cameraToggle" },
    { type := "camera.move", tag := "cameraMove", fields :=
      [("direction", call (id "directionOf") [prop payload "direction"])] },
    { type := "camera.zoom", tag := "cameraZoom", fields :=
      [("delta", .conditional (.binary (prop payload "delta") "<" (.number 0))
        (ctor "nearer") (ctor "farther"))] }]

-- The wire keys are exactly the validator manifest's event types, in order.
#guard wires.map Wire.type = Game.Events.specs.map Game.Events.EventSpec.type

-- And the manifest is itself the engine alphabet, so this table covers every constructor.
#guard wires.map Wire.type = Engine.Event.alphabet.map Engine.Event.name

/--
Boundary policy: the `Nat` a client number denotes, or `undefined` when it denotes none.
Sign and fraction are discarded rather than refused because the pre-engine boundary did the
same (`Math.trunc(Math.abs(seed))`), and a non-finite value has no integer to offer.
-/
def wireNat : Function where
  isAsync := false
  name := "wireNat"
  parameters := [{ name := "value", type := .number }]
  returns := .union [.number, .named "undefined"]
  body := [
    .ifThen (not' (call (prop (id "Number") "isFinite") [id "value"])) [.return .undefined],
    .return (call (prop (id "Math") "trunc") [call (prop (id "Math") "abs") [id "value"]])]

/-- Boundary policy: a route destination must be a `Nat`; anything else is unselectable. -/
def destinationOf : Function where
  isAsync := false
  name := "destinationOf"
  parameters := [{ name := "value", type := .number }]
  returns := .number
  body := [
    .constDecl "node" (call (id "wireNat") [id "value"]),
    .ifThen (eq (id "node") .undefined) [refuse "That destination cannot be selected."],
    .return (id "node")]

/-- The engine event one wire event asks for. -/
def eventFrom : Function where
  isAsync := false
  name := "eventFrom"
  parameters := [
    { name := "event", type := .named "GameEvent" },
    { name := "seed", type := .number }]
  returns := engineType "Event"
  body :=
    [.switch (prop event "type")
      (wires.map fun wire => (wire.type, [Statement.return (ctor wire.tag wire.fields)]))] ++
    [refuse "This action is not available right now."]

/-- The hero this event acts upon, when the wire event names one. -/
def subjectOf : Function where
  isAsync := false
  name := "subjectOf"
  parameters := [{ name := "event", type := .named "GameEvent" }]
  returns := .named "Option<string>"
  body := [.return (.conditional (.binary (.string "playerId") "in" subjects)
    (wrapped (prop subjects "playerId")) absent)]

/-- The envelope the rules receive: verified actor, subject hero, payload, server seed. -/
def envelopeFrom : Function where
  isAsync := false
  name := "envelopeFrom"
  parameters := [
    { name := "event", type := .named "GameEvent" },
    { name := "actor", type := .string },
    { name := "seed", type := .number }]
  returns := engineType "Envelope"
  body := [.return (.object [
    ("actor", id "actor"),
    ("subject", call (id "subjectOf") [event]),
    ("event", call (id "eventFrom") [event, id "seed"]),
    ("seed", id "seed")])]

/-- The generated wire-to-alphabet translation. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Aggregate/Envelope.lean"
  imports := [
    convexErrorImport,
    engineImport [typeBinding "Envelope", typeBinding "Event", typeBinding "Option"],
    validatorsImport [typeBinding "GameEvent"],
    { source := "./enums.generated", bindings := [valueBinding "directionOf",
      valueBinding "equipmentSlotOf", valueBinding "guardOf", valueBinding "strikeOf"] }
  ]
  items := [.function wireNat, .function destinationOf, .function eventFrom, .function subjectOf,
    .function envelopeFrom]

end Mythroads.Backend.Aggregate.Envelope
