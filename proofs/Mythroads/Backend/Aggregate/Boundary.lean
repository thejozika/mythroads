import Mythroads.Backend.Aggregate.Support

namespace Mythroads.Backend.Aggregate.Boundary

/-!
# The transaction: load, step, save

`applyGameEvent` is the whole write side of the backend. It loads the room the event addresses,
hands the rules an envelope, and interprets what they return. Nothing in it is game-specific: there
is no event it knows more about than which room to fetch and which answer to send back.

## The two policies the rules deliberately omit

`Mythroads.Engine` is a pure function of a room and an envelope. Two behaviours the deployed
backend has always had cannot be written that way, and both are emitted here as explicit steps
rather than smuggled into the rules.

* **The encounter reveal delay.** A drawn encounter may not be acknowledged for 2200 ms, so the
  wheel finishes spinning before the numbers land. That reads a wall clock and a stored timestamp;
  a replayable transition may consult neither, and a rule that did would make the same log produce
  different rooms. `Mythroads.Engine.Step.Encounter` records the omission; this is where it is
  enforced, with the sentence the old handler used.
* **The room-code collision retry.** `Mythroads.Engine.Step.Lobby` draws one four-character code
  from the seeded generator. Whether that code is already in the `rooms` table is a database
  question, so the retry lives here — and it redraws with the engine's own `Lobby.roomCode`, four
  characters and four counter ticks at a time, so the room's generator stays in the state the rules
  would have left it in. The retry is bounded at `codeAttempts` redraws: with a healthy generator
  the alphabet offers over a million codes and a second collision is already improbable, so hitting
  the bound means the generator is degenerate, and refusing is better than spinning until Convex
  kills the mutation.

## Numbers from the client

The `room.create` seed is the one client number this module reads itself. It goes through
`Envelope.wireNat` before the rules see it — the same `Math.trunc(Math.abs(seed))` the pre-engine
boundary applied — and a non-finite seed counts as no seed, so the clock supplies one. Together
with `Lobby.create`'s `normalizeSeed`, that restores the old contract exactly: the stored generator
state is `trunc(|seed|) % (modulus − 1) + 1`.

## Refusals

Every refusal comes from one table, `Mythroads.Engine.Error.message`, keyed on the error and the
event. The policies above are the only sentences written here, because they are the only
refusals the rules never see.

## The development bypass

With `DEV_NO_AUTH=true` the boundary has no verified identity to hand over. Rather than refuse
every gate, it substitutes the identity the gate is about to compare against — the room's host for
a host-only event, the addressed hero's stored owner for an owner-only one. Account-level events
(`room.create`, `player.join`) get the anonymous actor, the empty string, which the rules treat as
owning nothing: a room created this way has no `hostAuthId`, and every anonymous joiner under a new
name is seated as a fresh hero with no `authId`, exactly as the pre-engine handler did with an
absent identity. Fabricating a shared owner here would collapse every joiner onto the first hero.
-/

open Mythroads.Convex Mythroads.Convex.TypeScript
open Mythroads.Backend.Aggregate

/-- `event`, the wire event being applied. -/
def event : Expr := id "event"

/-- `event.subjects`. -/
def subjects : Expr := prop event "subjects"

/-- Is this the named wire event? -/
def isEvent (name : String) : Expr := eq (prop event "type") (.string name)

/-- How long the encounter wheel spins before its outcome may be acknowledged. -/
def revealDelay : Nat := 2200

/-- The room this event acts on: named directly, found by code, or reached through a hero. -/
def roomIdForEvent : Function where
  isExported := false
  name := "roomIdForEvent"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "event", type := .named "GameEvent" }]
  returns := .promise (.id .rooms)
  body := [
    .ifThen (isEvent "player.join") [
      .constDecl "room" (Query.indexedRead .rooms .roomsByCode
        [method (prop subjects "code") "toUpperCase"] .unique),
      .ifThen (not' (id "room")) [refuse "That room does not exist."],
      .return (prop (id "room") "_id")],
    .ifThen (isEvent "inventory.equip") [
      .constDecl "player" (Query.getIn .players (prop subjects "playerId")),
      .ifThen (not' (id "player")) [refuse "That hero does not exist."],
      .return (prop (id "player") "roomId")],
    .ifThen (.binary (.string "roomId") "in" subjects) [.return (prop subjects "roomId")],
    refuse "That room does not exist."]

/-- The verified actor, or the identity the gate is about to check when auth is bypassed. -/
def actorFor : Function where
  isExported := false
  isAsync := false
  name := "actorFor"
  parameters := [
    { name := "event", type := .named "GameEvent" },
    { name := "actorAuthId", type := .union [.string, .named "null"] },
    { name := "before", type := engineType "State" }]
  returns := .string
  body := [
    .ifThen (id "actorAuthId") [.return (id "actorAuthId")],
    .constDecl "authority" (call (id "Event_authority")
      [call (id "eventFrom") [event, .number 0]]),
    .ifThen (isTag (id "authority") "roomHost") [.return (prop (id "before") "host")],
    .ifThen (isTag (id "authority") "playerOwner") [
      .constDecl "subject" (call (id "subjectOf") [event]),
      .constDecl "hero" (.conditional (isTag (id "subject") "some")
        (method (prop (id "before") "players") "find"
          [.arrow ["candidate"] (eq (prop (id "candidate") "id") (unwrapped (id "subject")))])
        .undefined),
      .return (.conditional (id "hero") (prop (id "hero") "owner") (.string ""))],
    .return (.string "")]

/-- Boundary policy: the encounter wheel must have finished spinning. -/
def requireRipeEncounter : Function where
  isExported := false
  name := "requireRipeEncounter"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "event", type := .named "GameEvent" }]
  returns := .promise .void
  body := [
    .ifThen (ne (prop event "type") (.string "encounter.resolve")) [.returnVoid],
    .constDecl "encounter" (Query.getIn .encounters (prop subjects "encounterId")),
    .ifThen (.binary
        (.binary
          (.binary (not' (id "encounter")) "||"
            (ne (prop (id "encounter") "roomId") (prop subjects "roomId"))) "||"
          (ne (prop (id "encounter") "playerId") (prop subjects "playerId"))) "||"
        (.binary (ne (prop (id "encounter") "status") (.string "revealing")) "||"
          (.binary (.binary now "-" (prop (id "encounter") "createdAt")) "<"
            (.number revealDelay))))
      [refuse "This encounter cannot be resolved now."]]

/-- How many redraws the collision retry allows before refusing. -/
def codeAttempts : Nat := 32

/-- Durable snapshots bound replay cost without making them part of the public game surface. -/
def snapshotInterval : Nat := 20

/-- Store the complete compiled Lean state after every twentieth durable transition. -/
def writeSnapshot : Function where
  isExported := false
  name := "writeSnapshot"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "roomId", type := .id .rooms },
    { name := "state", type := engineType "State" },
    { name := "durable", type := .boolean }]
  returns := .promise .void
  body := [
    .ifThen (not' (id "durable")) [.returnVoid],
    .expression (Query.patchIn .rooms (id "roomId")
      (.object [("eventVersion", prop (id "state") "version")])),
    .ifThen (ne (.binary (prop (id "state") "version") "%" (.number snapshotInterval))
      (.number 0)) [.returnVoid],
    .constDecl "canonical" (.await (call (id "loadState") [ctx, id "roomId"])),
    .expression (Query.insert .gameSnapshots (.object [
      ("roomId", id "roomId"), ("version", prop (id "canonical") "version"),
      ("stateJson", call (prop (id "JSON") "stringify") [id "canonical"]),
      ("createdAt", now)]))]

/-- Boundary policy: keep redrawing until the room code is free, up to `codeAttempts` times. -/
def freeRoomCode : Function where
  isExported := false
  name := "freeRoomCode"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "after", type := engineType "State" }]
  returns := .promise (.obj [("code", .string), ("rngState", .number), ("rngCounter", .number)])
  body := [
    .letDecl "code" (prop (id "after") "code"),
    .letDecl "rngState" (prop (id "after") "rng"),
    .letDecl "rngCounter" (prop (id "after") "rngCounter"),
    .letDecl "attempts" (.number 0),
    .whileDo (Query.indexedRead .rooms .roomsByCode [id "code"] .unique) [
      .ifThen (.binary (id "attempts") ">=" (.number codeAttempts))
        [refuse "Could not allocate a room code."],
      .assign (id "attempts") (.binary (id "attempts") "+" (.number 1)),
      .constDecl "drawn" (call (id "Lobby_roomCode") [id "rngState"]),
      .assign (id "code") (prop (id "drawn") "fst"),
      .assign (id "rngState") (prop (id "drawn") "snd"),
      .assign (id "rngCounter") (.binary (id "rngCounter") "+" (.number 4))],
    .return (.shorthand ["code", "rngState", "rngCounter"])]

/-- Refuse with the sentence this error shows for this event. -/
def refuseOutcome : Statement :=
  .throw (.new "ConvexError" [call (id "Error_message")
    [prop (id "outcome") "a", prop (id "envelope") "event"]])

/-- `room.create`: the one event with no room to load and one row to insert. The client seed is
coerced by `wireNat`; an absent or non-finite one is replaced by the clock. -/
def createRoom : Function where
  isExported := false
  name := "createRoom"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "event", type := .named "GameEvent" },
    { name := "actorAuthId", type := .union [.string, .named "null"] }]
  returns := .promise (.named "DispatchResult")
  body := [
    .constDecl "before" (call (id "emptyState")),
    .constDecl "requested" (.conditional
      (.binary (isEvent "room.create") "&&" (ne (prop (prop event "data") "seed") .undefined))
      (call (id "wireNat") [prop (prop event "data") "seed"]) .undefined),
    .constDecl "seed" (orElse (id "requested") now),
    .constDecl "envelope" (call (id "envelopeFrom")
      [event, call (id "actorFor") [event, id "actorAuthId", id "before"], id "seed"]),
    .constDecl "outcome" (call (id "step") [id "before", id "envelope"]),
    .ifThen (isTag (id "outcome") "error") [refuseOutcome],
    .constDecl "after" (prop (prop (id "outcome") "a") "fst"),
    .constDecl "free" (.await (call (id "freeRoomCode") [ctx, id "after"])),
    .expression (.await (call (id "insertRoom") [ctx, id "after", prop (id "free") "code",
      prop (id "free") "rngState", prop (id "free") "rngCounter"])),
    .return (.object [("kind", .string "room.created"), ("code", prop (id "free") "code")])]

/-- Run one wire event through the engine: load the room, step, save the effects. -/
def applyGameEvent : Function where
  name := "applyGameEvent"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "event", type := .named "GameEvent" },
    { name := "actorAuthId", type := .union [.string, .named "null"] }]
  returns := .promise (.named "DispatchResult")
  body := [
    .ifThen (isEvent "room.create")
      [.return (.await (call (id "createRoom") [ctx, event, id "actorAuthId"]))],
    .expression (.await (call (id "requireRipeEncounter") [ctx, event])),
    .constDecl "roomId" (.await (call (id "roomIdForEvent") [ctx, event])),
    .constDecl "before" (.await (call (id "loadState") [ctx, id "roomId"])),
    .constDecl "envelope" (call (id "envelopeFrom")
      [event, call (id "actorFor") [event, id "actorAuthId", id "before"], .number 0]),
    .constDecl "outcome" (call (id "step") [id "before", id "envelope"]),
    .ifThen (isTag (id "outcome") "error") [refuseOutcome],
    .constDecl "durable" (call (id "isPersistentGameEvent") [event]),
    .constDecl "transitioned" (prop (prop (id "outcome") "a") "fst"),
    .constDecl "after" (.conditional (id "durable") (.object [
      ("...", id "transitioned"),
      ("version", .binary (prop (id "before") "version") "+" (.number 1))])
      (id "transitioned")),
    .constDecl "saved" (.await (call (id "saveState") [ctx, id "roomId", id "before",
      id "after", prop (prop (id "outcome") "a") "snd"])),
    .expression (.await (call (id "writeSnapshot")
      [ctx, id "roomId", id "after", id "durable"])),
    .ifThen (isEvent "player.join") [
      .ifThen (not' (prop (id "saved") "playerId")) [refuse "Choose a hero name."],
      .return (.object [("kind", .string "player.joined"),
        ("playerId", prop (id "saved") "playerId")])],
    .return (.object [("kind", .string "accepted")])]

/-- The generated load-step-save transaction. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Aggregate/Boundary.lean"
  imports := [
    convexErrorImport,
    engineImport [valueBinding "Error_message", valueBinding "Event_authority",
      valueBinding "Lobby_roomCode", typeBinding "State", valueBinding "step"],
    dataModelImport [typeBinding "Id"],
    serverImport,
    validatorsImport [typeBinding "DispatchResult", typeBinding "GameEvent"],
    { source := "./envelope.generated", bindings := [valueBinding "envelopeFrom",
      valueBinding "eventFrom", valueBinding "subjectOf", valueBinding "wireNat"] },
    { source := "./persist.generated", bindings := [valueBinding "insertRoom",
      valueBinding "saveState"] },
    { source := "./load.generated", bindings := [valueBinding "emptyState",
      valueBinding "loadState"] },
    { source := "../../events/policy", bindings := [valueBinding "isPersistentGameEvent"] }
  ]
  items := [
    .function roomIdForEvent,
    .function actorFor,
    .function requireRipeEncounter,
    .function writeSnapshot,
    .function freeRoomCode,
    .function createRoom,
    .function applyGameEvent
  ]

end Mythroads.Backend.Aggregate.Boundary
