import Mythroads.Backend.Aggregate.Support

namespace Mythroads.Backend.Aggregate.Persist

/-!
# Carrying out the effects of one transition

`Mythroads.Engine.step` writes nothing. It returns a new `State` and a list of `Effect`s, and this
module emits the interpreter for that list: a `switch` with one arm per constructor, run in the
order the rules produced them.

The order is load-bearing in exactly one way. A battle or an encounter row is always written
*before* the room row that points at it, because inserting the row is what produces the identifier
`rooms.activeCombatId` needs. That is why `Mythroads.Engine.Step.Landing.startCombat` lists
`persistCombat` ahead of `persistRoom`, and why nothing here has to re-derive it.

Two more decisions live here rather than in the rules.

* **A hero the rules invented gets their row here.** `Lobby.joinAs` appends a `PlayerState` whose
  id is a placeholder, because a pure function cannot mint a Convex identifier. `persistHero` sees
  an id that was not in the state it loaded, inserts the row and its starting inventory, and
  reports the real identifier back so `player.join` can answer with it.
* **Bought items are inserted, equipped ones are patched.** The same rule applies to the item rows:
  an `Owned` whose row id the loaded state did not contain is a purchase, and one whose slot moved
  is an equip.

`createdAt` is never patched. The encounter reveal delay is measured against it, so rewriting it on
every save would make the wheel spin forever.
-/

open Mythroads.Convex Mythroads.Convex.TypeScript
open Mythroads.Backend.Aggregate

/-- `after`, the state the transition produced. -/
def after : Expr := id "after"

/-- `hero`, the engine hero a row is written from. -/
def hero : Expr := id "hero"

/-- `effect`, the request being interpreted. -/
def effect : Expr := id "effect"

/-- `roomId`, the aggregate every write belongs to. -/
def roomId : Expr := id "roomId"

/-- The empty string the engine uses for "no account", as an absent column. -/
def blankToAbsent (value : Expr) : Expr := .conditional (eq value (.string "")) .undefined value

/-- Insert a hero the rules have just invented, together with their starting inventory. -/
def insertHero : Function where
  isExported := false
  name := "insertHero"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "roomId", type := .id .rooms },
    { name := "hero", type := engineType "PlayerState" }]
  returns := .promise (.id .players)
  body := [
    .constDecl "createdAt" now,
    .constDecl "playerId" (Query.insert .players (.object [
      ("roomId", roomId),
      ("...", call (id "heroColumns") [hero]),
      ("joinedAt", id "createdAt")])),
    .forOf "owned" (prop hero "items") [
      .expression (Query.insert .playerItems (.object [
        ("playerId", id "playerId"),
        ("itemId", prop (id "owned") "itemId"),
        ("equippedSlot", call (id "slotColumn") [prop (id "owned") "equippedSlot"]),
        ("purchasedAt", id "createdAt")]))],
    .return (id "playerId")]

/-- Insert the items a hero has bought and patch the slots that moved. -/
def syncItems : Function where
  isExported := false
  name := "syncItems"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "playerId", type := .id .players },
    { name := "previous", type := engineType "PlayerState" },
    { name := "hero", type := engineType "PlayerState" }]
  returns := .promise .void
  body := [
    .forOf "item" (prop hero "items") [
      .constDecl "existing" (method (prop (id "previous") "items") "find"
        [.arrow ["candidate"] (eq (prop (id "candidate") "rowId") (prop (id "item") "rowId"))]),
      .ifElse (not' (id "existing"))
        [.expression (Query.insert .playerItems (.object [
          ("playerId", id "playerId"),
          ("itemId", prop (id "item") "itemId"),
          ("equippedSlot", call (id "slotColumn") [prop (id "item") "equippedSlot"]),
          ("purchasedAt", now)]))]
        [.ifThen (ne (call (id "slotColumn") [prop (id "existing") "equippedSlot"])
            (call (id "slotColumn") [prop (id "item") "equippedSlot"]))
          [.expression (Query.patchIn .playerItems
            (.cast (prop (id "item") "rowId") (.id .playerItems))
            (.object [("equippedSlot", call (id "slotColumn") [prop (id "item") "equippedSlot"])]))]]]]

/-- Write one hero: insert them if the rules invented them, patch them otherwise. -/
def persistHero : Function where
  isExported := false
  name := "persistHero"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "roomId", type := .id .rooms },
    { name := "before", type := engineType "State" },
    { name := "after", type := engineType "State" },
    { name := "id", type := .string }]
  returns := .promise (.id .players)
  body := [
    .constDecl "hero" (method (prop after "players") "find"
      [.arrow ["candidate"] (eq (prop (id "candidate") "id") (id "id"))]),
    .ifThen (not' hero) [refuse "That hero does not exist."],
    .constDecl "previous" (method (prop (id "before") "players") "find"
      [.arrow ["candidate"] (eq (prop (id "candidate") "id") (id "id"))]),
    .ifThen (not' (id "previous"))
      [.return (.await (call (id "insertHero") [ctx, roomId, hero]))],
    .constDecl "playerId" (.cast (prop hero "id") (.id .players)),
    .expression (Query.patchIn .players (id "playerId") (call (id "heroColumns") [hero])),
    .expression (.await (call (id "syncItems") [ctx, id "playerId", id "previous", hero])),
    .return (id "playerId")]

/-- The one planned-route row a room may hold. -/
def selectionRow : Expr :=
  Query.indexedRead .roomSelections .roomSelectionsByRoomId [roomId] .first

/-- Write the planned route, replacing whatever was planned before. -/
def upsertSelection : Function where
  isExported := false
  name := "upsertSelection"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "roomId", type := .id .rooms },
    { name := "selection", type := engineType "Selection" }]
  returns := .promise .void
  body := [
    .constDecl "existing" selectionRow,
    .constDecl "value" (.object [
      ("roomId", roomId),
      ("playerId", .cast (prop (id "selection") "playerId") (.id .players)),
      ("destination", prop (id "selection") "destination"),
      ("path", prop (id "selection") "path"),
      ("updatedAt", now)]),
    .ifThen (id "existing") [
      .expression (Query.replace (prop (id "existing") "_id") (id "value")),
      .returnVoid],
    .expression (Query.insert .roomSelections (id "value"))]

/-- Drop the planned route. -/
def dropSelection : Function where
  isExported := false
  name := "dropSelection"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "roomId", type := .id .rooms }]
  returns := .promise .void
  body := [
    .constDecl "existing" selectionRow,
    .ifThen (id "existing") [.expression (Query.remove (prop (id "existing") "_id"))]]

/-- Write the shared camera, in world units. -/
def upsertCamera : Function where
  isExported := false
  name := "upsertCamera"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "roomId", type := .id .rooms },
    { name := "camera", type := engineType "Camera" }]
  returns := .promise .void
  body := [
    .constDecl "existing" (Query.indexedRead .roomCameras .roomCamerasByRoomId [roomId] .first),
    .constDecl "value" (.object [
      ("mode", .conditional (prop (id "camera") "free")
        (.asConst (.string "free")) (.asConst (.string "follow"))),
      ("targetX", .binary (prop (id "camera") "targetX") "/" (.number 100)),
      ("targetZ", .binary (prop (id "camera") "targetZ") "/" (.number 100)),
      ("distance", prop (id "camera") "distance"),
      ("updatedAt", now)]),
    .ifThen (id "existing") [
      .expression (Query.patch (prop (id "existing") "_id") (id "value")),
      .returnVoid],
    .expression (Query.insert .roomCameras (.object [("roomId", roomId), ("...", id "value")]))]

/-- Upsert one side row from a shared column block, keeping the `createdAt` an existing row has. -/
private def upsertRow (table : Table) (identifier : String) (columns : Expr) : List Statement :=
  [.constDecl "columns" columns,
   .ifElse (id identifier)
     [.expression (Query.patch (id identifier) (id "columns"))]
     [.assign (id identifier) (Query.insert table
       (.object [("...", id "columns"), ("createdAt", now)]))]]

/-- Every `rooms` column the room row carries, written from the state the transition produced. -/
def roomColumns : Expr :=
  .object [
    ("code", prop after "code"),
    ("hostAuthId", blankToAbsent (prop after "host")),
    ("status", call (id "statusColumn") [prop after "phase"]),
    ("activePlayerId", .conditional
      (.binary (isTag (prop after "phase") "lobby") "||" (not' (id "active")))
      .undefined (.cast (prop (id "active") "id") (.id .players))),
    ("remainingMoves", call (id "movesColumn") [prop after "phase"]),
    ("lastRoll", .conditional (eq (prop (prop after "lastRoll") "length") (.number 0))
      .undefined (prop after "lastRoll")),
    ("message", prop after "message"),
    ("round", prop after "round"),
    ("phase", call (id "phaseColumn") [prop after "phase"]),
    ("activeEncounterId", .conditional (isTag (prop after "phase") "encounter")
      (id "encounterId") .undefined),
    ("activeCombatId", .conditional (isTag (prop after "phase") "combat")
      (id "combatId") .undefined),
    ("shopKind", .conditional (isTag (prop after "phase") "shop")
      (tagOf (prop (prop after "phase") "kind")) .undefined),
    ("rngState", prop after "rng"),
    ("rngCounter", prop after "rngCounter"),
    ("eventVersion", prop after "version")]

/-- One arm of the effect interpreter. -/
private def arm (tag : String) (body : List Statement) : String × List Statement :=
  (tag, body ++ [.break])

/-- Interpret the effects of one accepted transition against the tables. -/
def saveState : Function where
  name := "saveState"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "roomId", type := .id .rooms },
    { name := "before", type := engineType "State" },
    { name := "after", type := engineType "State" },
    { name := "effects", type := .array (engineType "Effect") }]
  returns := .promise (.named "SaveReport")
  body := [
    .constDecl "room" (Query.getIn .rooms roomId),
    .ifThen (not' (id "room")) [refuse "That room does not exist."],
    .letDecl "combatId" (prop (id "room") "activeCombatId"),
    .letDecl "encounterId" (prop (id "room") "activeEncounterId"),
    .constDeclTyped "report" (.named "SaveReport") (.object [("playerId", .null)]),
    .forOf "effect" (id "effects") [
      .switch (tagOf effect) [
        arm "persistPlayer" [.assign (prop (id "report") "playerId")
          (.await (call (id "persistHero")
            [ctx, roomId, id "before", after, prop effect "id"]))],
        arm "persistCombat" (upsertRow .combats "combatId"
          (call (id "combatColumns") [roomId, prop effect "battle", prop effect "stage"])),
        arm "persistEncounter" (upsertRow .encounters "encounterId"
          (call (id "encounterColumns") [roomId, prop effect "drawn"])),
        arm "persistSelection" [.expression (.await (call (id "upsertSelection")
          [ctx, roomId, prop effect "selection"]))],
        arm "clearSelection" [.expression (.await (call (id "dropSelection") [ctx, roomId]))],
        arm "persistCamera" [.expression (.await (call (id "upsertCamera")
          [ctx, roomId, prop effect "camera"]))],
        arm "persistRoom" [
          .constDecl "active" (.index (prop after "players") (prop after "turn")),
          .expression (Query.patchIn .rooms roomId roomColumns)],
        arm "appendLog" [],
        arm "notify" []]],
    .return (id "report")]

/-- Insert the `rooms` row a freshly created lobby starts from.

`room.create` is the one event with no room to load, so it is the one write that inserts rather
than patches; the code and generator state come from the collision policy in
`Mythroads.Backend.Aggregate.Boundary`, not from the state directly. -/
def insertRoom : Function where
  name := "insertRoom"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "after", type := engineType "State" },
    { name := "code", type := .string },
    { name := "rngState", type := .number },
    { name := "rngCounter", type := .number }]
  returns := .promise .void
  body := [
    .expression (Query.insert .rooms (.object [
      ("code", id "code"),
      ("hostAuthId", blankToAbsent (prop after "host")),
      ("status", .asConst (.string "lobby")),
      ("remainingMoves", .number 0),
      ("message", prop after "message"),
      ("round", prop after "round"),
      ("phase", .asConst (.string "awaitingRoll")),
      ("rngState", id "rngState"),
      ("rngCounter", id "rngCounter"),
      ("eventVersion", prop after "version")]))]

/-- The generated effect interpreter. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Aggregate/Persist.lean"
  imports := [
    convexErrorImport,
    engineImport [typeBinding "Camera", typeBinding "Effect", typeBinding "PlayerState",
      typeBinding "Selection", typeBinding "State"],
    dataModelImport [typeBinding "Id"],
    serverImport,
    { source := "./rows.generated", bindings := [valueBinding "combatColumns",
      valueBinding "encounterColumns", valueBinding "heroColumns", valueBinding "movesColumn",
      valueBinding "phaseColumn", valueBinding "slotColumn", valueBinding "statusColumn"] }
  ]
  items := [
    .typeAlias "SaveReport" (.obj [("playerId", .union [.id .players, .named "null"])]),
    .function insertHero,
    .function syncItems,
    .function persistHero,
    .function upsertSelection,
    .function dropSelection,
    .function upsertCamera,
    .function saveState,
    .function insertRoom
  ]

end Mythroads.Backend.Aggregate.Persist
