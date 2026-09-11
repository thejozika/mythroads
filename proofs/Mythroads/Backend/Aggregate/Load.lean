import Mythroads.Backend.Aggregate.Support

namespace Mythroads.Backend.Aggregate.Load

/-!
# Reading the room back into the engine

`loadState` is the other half of the dictionary in `Mythroads.Backend.Aggregate.Rows`: eight rows
in, one `Mythroads.Engine.State` out. It is the only place the boundary reads game state, and it
reads the whole room at once, because the rules are a function of the room and of nothing smaller.

Three reconstructions deserve their own sentence.

* **The phase is inferred from three columns.** `rooms.status` decides `lobby` and `finished`,
  `rooms.phase` decides the rest, and the payload comes from the row the room points at. A phase
  column with no matching row — a `combatAttack` with no `combats` row — falls back to
  `awaitingRoll`, which is exactly what the old handlers did when their guard failed: the event is
  then refused by the phase gate rather than acting on half a battle.
* **A resolved encounter is not a live one.** `encounters.status` is checked here, so acknowledging
  the same wheel twice meets an `awaitingRoll` phase and the refusal the players already knew.
* **The camera is stored in world units and reasoned about in hundredths.** `Game.World.Point` is
  an integer type, so panning is exact; the column is a float because the browser wants one.

Row identifiers *are* the engine's identifiers. A hero the rules invent during a transition has no
row yet and carries a placeholder id instead; `Mythroads.Backend.Aggregate.Persist` is where that
placeholder becomes a real one.
-/

open Mythroads.Convex Mythroads.Convex.TypeScript
open Mythroads.Backend.Aggregate

/-- `row`, the document a converter reads. -/
def row : Expr := id "row"

/-- The stat columns that were added after launch and therefore default rather than exist. -/
def defaulted (target : Expr) (name : String) (fallback : Nat) : String × Expr :=
  (name, orElse (prop target name) (.number fallback))

/-- An optional column as an engine `Option`. -/
def optional (target : Expr) (name : String) : Expr :=
  .conditional (eq (prop target name) .undefined) absent (wrapped (prop target name))

/-- An optional column as an engine `Option`, read through a converter. -/
def optionalVia (target : Expr) (name converter : String) : Expr :=
  .conditional (eq (prop target name) .undefined) absent
    (wrapped (call (id converter) [prop target name]))

/-- One owned item row as the engine's `Owned`. -/
def ownedFrom : Function where
  isExported := false
  isAsync := false
  name := "ownedFrom"
  parameters := [{ name := "row", type := .doc .playerItems }]
  returns := engineType "Owned"
  body := [.return (.object [
    ("rowId", prop row "_id"),
    ("itemId", prop row "itemId"),
    ("equippedSlot", optionalVia row "equippedSlot" "equipmentSlotOf")])]

/-- One hero row and their inventory as the engine's `PlayerState`. -/
def heroFrom : Function where
  isExported := false
  isAsync := false
  name := "heroFrom"
  parameters := [
    { name := "row", type := .doc .players },
    { name := "items", type := .array (.doc .playerItems) }]
  returns := engineType "PlayerState"
  body := [.return (.object [
    ("id", prop row "_id"),
    ("owner", orElse (prop row "authId") (.string "")),
    ("name", prop row "name"),
    ("color", prop row "color"),
    ("position", prop row "position"),
    ("previousPosition", optional row "previousPosition"),
    ("gold", prop row "gold"),
    ("hp", prop row "hp"),
    ("maxHp", prop row "maxHp"),
    ("attack", prop row "attack"),
    defaulted row "defense" 2,
    defaulted row "magic" 2,
    defaulted row "athletics" 2,
    defaulted row "agility" 2,
    ("dice", prop row "dice"),
    ("items", method (id "items") "map" [id "ownedFrom"])])]

/-- One battle row as the engine's `CombatState`. -/
def battleFrom : Function where
  isExported := false
  isAsync := false
  name := "battleFrom"
  parameters := [{ name := "row", type := .doc .combats }]
  returns := engineType "CombatState"
  body := [.return (.object [
    ("playerId", prop row "playerId"),
    ("spaceId", prop row "spaceId"),
    ("enemy", .object [
      ("name", prop row "enemyName"),
      ("element", call (id "elementOf") [prop row "enemyElement"]),
      ("hp", prop row "enemyMaxHp"),
      ("attack", prop row "enemyAttack"),
      defaulted row "enemyDefense" 2 |>.snd |> fun value => ("defense", value),
      defaulted row "enemyMagic" 2 |>.snd |> fun value => ("magic", value),
      defaulted row "enemyAthletics" 2 |>.snd |> fun value => ("athletics", value),
      defaulted row "enemyAgility" 2 |>.snd |> fun value => ("agility", value),
      ("reward", prop row "reward")]),
    ("enemyHp", prop row "enemyHp"),
    defaulted row "enemyDefensePenalty" 0,
    defaulted row "enemyMagicPenalty" 0,
    defaulted row "enemyAthleticsPenalty" 0,
    defaulted row "enemyAgilityPenalty" 0,
    defaulted row "playerDefensePenalty" 0,
    defaulted row "playerMagicPenalty" 0,
    defaulted row "playerAthleticsPenalty" 0,
    defaulted row "playerAgilityPenalty" 0,
    ("round", prop row "round"),
    ("lastAttack", optional row "lastAttack"),
    ("lastGuard", optionalVia row "lastGuard" "guardOf"),
    ("lastDamage", optional row "lastDamage"),
    ("message", prop row "message")])]

/-- One encounter row as the engine's `EncounterState`.

The outcome's `weight` is not a column: it decides which outcome the wheel draws and is spent by
the time the row exists, so nothing that reads this value can observe the zero. -/
def drawnFrom : Function where
  isExported := false
  isAsync := false
  name := "drawnFrom"
  parameters := [{ name := "row", type := .doc .encounters }]
  returns := engineType "EncounterState"
  body := [
    .constDeclTyped "kind" (engineType "Game_Encounter_Kind")
      (.conditional (eq (prop row "kind") (.string "combat")) (ctor "combat") (ctor "event")),
    .return (.object [
      ("playerId", prop row "playerId"),
      ("spaceId", prop row "spaceId"),
      ("kind", id "kind"),
      ("outcome", .object [
        ("id", prop row "outcomeId"),
        ("kind", id "kind"),
        ("title", prop row "title"),
        ("description", prop row "description"),
        ("goldDelta", prop row "goldDelta"),
        ("hpDelta", prop row "hpDelta"),
        ("weight", .number 0)]),
      ("wheelIndex", prop row "wheelIndex"),
      ("resolved", eq (prop row "status") (.string "resolved"))])]

/-- One planned-route row as the engine's `Selection`. -/
def routeFrom : Function where
  isExported := false
  isAsync := false
  name := "routeFrom"
  parameters := [{ name := "row", type := .doc .roomSelections }]
  returns := engineType "Selection"
  body := [.return (.object [
    ("playerId", prop row "playerId"),
    ("destination", prop row "destination"),
    ("path", orElse (prop row "path") (.array []))])]

/-- One camera row as the engine's `Camera`, in hundredths of a world unit. -/
def cameraFrom : Function where
  isExported := false
  isAsync := false
  name := "cameraFrom"
  parameters := [{ name := "row", type := .doc .roomCameras }]
  returns := engineType "Camera"
  body := [.return (.object [
    ("free", eq (prop row "mode") (.string "free")),
    ("targetX", method (id "Math") "round" [.binary (prop row "targetX") "*" (.number 100)]),
    ("targetZ", method (id "Math") "round" [.binary (prop row "targetZ") "*" (.number 100)]),
    ("distance", prop row "distance")])]

/-- `room`, the room row every phase reconstruction reads. -/
def roomRow : Expr := id "room"

/-- The stored phase name, falling back the way the old `roomPhase` helper did. -/
def namedPhase : Statement :=
  .constDecl "named" (orElse (prop roomRow "phase")
    (.conditional (.binary (prop roomRow "remainingMoves") ">" (.number 0))
      (.string "moving") (.string "awaitingRoll")))

/-- Is the stored phase this one, and is the row it needs present? -/
private def phaseIs (name : String) (extra : Option Expr := none) : Expr :=
  match extra with
  | none => eq (id "named") (.string name)
  | some guard => .binary (eq (id "named") (.string name)) "&&" guard

/-- The engine `Phase` these four rows describe. -/
def phaseFrom : Function where
  isExported := false
  isAsync := false
  name := "phaseFrom"
  parameters := [
    { name := "room", type := .doc .rooms },
    { name := "combat", type := .union [.doc .combats, .named "null"] },
    { name := "encounter", type := .union [.doc .encounters, .named "null"] },
    { name := "selection", type := .union [.doc .roomSelections, .named "null"] }]
  returns := engineType "Phase"
  body := [
    .ifThen (eq (prop roomRow "status") (.string "lobby")) [.return (ctor "lobby")],
    .ifThen (eq (prop roomRow "status") (.string "finished"))
      [.return (ctor "finished" [("winner", orElse (prop roomRow "activePlayerId") (.string ""))])],
    namedPhase,
    .ifThen (phaseIs "moving") [.return (ctor "moving" [
      ("moves", prop roomRow "remainingMoves"),
      ("selection", .conditional (id "selection")
        (wrapped (call (id "routeFrom") [id "selection"])) absent)])],
    .ifThen (phaseIs "combatAttack" (some (id "combat"))) [.return (ctor "combat" [
      ("battle", call (id "battleFrom") [id "combat"]), ("stage", ctor "attackerChoice")])],
    .ifThen (phaseIs "combatDefend" (some (id "combat"))) [.return (ctor "combat" [
      ("battle", call (id "battleFrom") [id "combat"]), ("stage", ctor "defenderChoice")])],
    .ifThen (phaseIs "revealingEncounter" (some (.binary (id "encounter") "&&"
        (eq (prop (id "encounter") "status") (.string "revealing")))))
      [.return (ctor "encounter" [("drawn", call (id "drawnFrom") [id "encounter"])])],
    .ifThen (phaseIs "shopping" (some (prop roomRow "shopKind")))
      [.return (ctor "shop" [("kind", call (id "shopKindOf") [prop roomRow "shopKind"])])],
    .return (ctor "awaitingRoll")]

/-- Read one room, its heroes, their inventories and the four side rows into a `State`. -/
def loadState : Function where
  name := "loadState"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "roomId", type := .id .rooms }]
  returns := .promise (engineType "State")
  body := [
    .constDecl "room" (Query.getIn .rooms (id "roomId")),
    .ifThen (not' roomRow) [refuse "That room does not exist."],
    .constDecl "rows" (Query.indexedRead .players .playersByRoom [id "roomId"] (.take 4)),
    .constDecl "ordered" (method (id "rows") "sort"
      [.arrow ["a", "b"] (.binary (prop (id "a") "joinedAt") "-" (prop (id "b") "joinedAt"))]),
    .constDeclTyped "players" (.array (engineType "PlayerState")) (.array []),
    .forOf "row" (id "ordered") [
      .constDecl "items"
        (Query.indexedRead .playerItems .playerItemsByPlayerId [prop row "_id"] (.take 40)),
      .expression (method (id "players") "push" [call (id "heroFrom") [row, id "items"]])],
    .constDecl "combat" (.conditional (prop roomRow "activeCombatId")
      (Query.get (prop roomRow "activeCombatId")) .null),
    .constDecl "encounter" (.conditional (prop roomRow "activeEncounterId")
      (Query.get (prop roomRow "activeEncounterId")) .null),
    .constDecl "selection"
      (Query.indexedRead .roomSelections .roomSelectionsByRoomId [id "roomId"] .first),
    .constDecl "camera"
      (Query.indexedRead .roomCameras .roomCamerasByRoomId [id "roomId"] .first),
    .constDecl "turn" (method (id "ordered") "findIndex"
      [.arrow ["candidate"] (eq (prop (id "candidate") "_id") (prop roomRow "activePlayerId"))]),
    .return (.object [
      ("code", prop roomRow "code"),
      ("host", orElse (prop roomRow "hostAuthId") (.string "")),
      ("players", id "players"),
      ("turn", .conditional (.binary (id "turn") "<" (.number 0)) (.number 0) (id "turn")),
      ("round", prop roomRow "round"),
      ("phase", call (id "phaseFrom")
        [roomRow, id "combat", id "encounter", id "selection"]),
      ("message", prop roomRow "message"),
      ("lastRoll", orElse (prop roomRow "lastRoll") (.array [])),
      ("rng", orElse (prop roomRow "rngState")
        (call (id "normalizeSeed") [prop roomRow "_creationTime"])),
      ("rngCounter", orElse (prop roomRow "rngCounter") (.number 0)),
      ("camera", .conditional (id "camera") (wrapped (call (id "cameraFrom") [id "camera"]))
        absent),
      ("version", orElse (prop (id "room") "eventVersion") (.number 0))])]

/-- The room `room.create` starts from: no code, no host, no heroes, nothing drawn.

Every field of it is overwritten by `Mythroads.Engine.Lobby.create`, which is why the boundary can
hand the rules a value rather than a special case. -/
def emptyState : Function where
  isAsync := false
  name := "emptyState"
  parameters := []
  returns := engineType "State"
  body := [.return (.object [
    ("code", .string ""),
    ("host", .string ""),
    ("players", .array []),
    ("turn", .number 0),
    ("round", .number 1),
    ("phase", ctor "lobby"),
    ("message", .string ""),
    ("lastRoll", .array []),
    ("rng", .number 1),
    ("rngCounter", .number 0),
    ("camera", absent),
    ("version", .number 0)])]

/-- The generated room reader. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Aggregate/Load.lean"
  imports := [
    convexErrorImport,
    engineImport [typeBinding "Camera", typeBinding "CombatState", typeBinding "EncounterState",
      typeBinding "Game_Encounter_Kind", typeBinding "Owned", typeBinding "Phase",
      typeBinding "PlayerState", typeBinding "Selection", typeBinding "State"],
    dataModelImport [typeBinding "Doc", typeBinding "Id"],
    serverImport,
    { source := "../random.generated", bindings := [valueBinding "normalizeSeed"] },
    { source := "./enums.generated", bindings := [valueBinding "elementOf",
      valueBinding "equipmentSlotOf", valueBinding "guardOf", valueBinding "shopKindOf"] }
  ]
  items := [
    .function ownedFrom,
    .function heroFrom,
    .function battleFrom,
    .function drawnFrom,
    .function routeFrom,
    .function cameraFrom,
    .function phaseFrom,
    .function loadState,
    .function emptyState
  ]

end Mythroads.Backend.Aggregate.Load
