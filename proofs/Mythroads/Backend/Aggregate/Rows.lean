import Mythroads.Backend.Aggregate.Support

namespace Mythroads.Backend.Aggregate.Rows

/-!
# Engine values as table columns

`Mythroads.Engine.State` and the Convex tables hold the same room, and this module is the
dictionary between them in the writing direction. It is deliberately only a dictionary: nothing
here decides anything, and every entry is one column paired with the engine expression that fills
it.

Four translations are not field-for-field and are worth stating, because each of them is a shape
the tables chose and the rules did not.

* **`rooms.phase` is narrower than `Phase`.** The column has no `lobby` and no `finished` value —
  `rooms.status` carries those — and it collapses the battle stage into `combatAttack` and
  `combatDefend`. `phaseColumn` and `statusColumn` are that split.
* **A zero penalty is stored as nothing.** `combats.enemyDefensePenalty` and its seven siblings are
  optional columns that only exist once a hex has landed, so `penaltyColumn` maps zero to
  `undefined` rather than writing a zero the old handlers never wrote.
* **An empty roll is stored as nothing.** `rooms.lastRoll` is absent before the first roll, so an
  empty list becomes `undefined` for the same reason.
* **A hero with no account is stored as nothing.** The engine spells "claimed by nobody" as the
  empty string, because `Option` in a hot field buys nothing; the column spells it `undefined`.

`Doc<'rooms'>['phase']` and friends are named rather than restated, so a schema change reaches this
file as a type error instead of a wrong string.
-/

open Mythroads.Convex Mythroads.Convex.TypeScript
open Mythroads.Backend.Aggregate

/-- `hero`, the engine `PlayerState` a `players` row is written from. -/
def hero : Expr := id "hero"

/-- `battle`, the engine `CombatState` a `combats` row is written from. -/
def battle : Expr := id "battle"

/-- `drawn`, the engine `EncounterState` an `encounters` row is written from. -/
def drawn : Expr := id "drawn"

/-- `phase`, the engine `Phase` the three `rooms` shape columns are written from. -/
def phase : Expr := id "phase"

/-- The empty string the engine uses for "no account", as an absent column. -/
def blankToAbsent (value : Expr) : Expr := .conditional (eq value (.string "")) .undefined value

/-- The `playerItems.equippedSlot` column for an engine `Option EquipmentSlot`. -/
def slotColumn : Function where
  isAsync := false
  name := "slotColumn"
  parameters := [{ name := "slot", type := .named "Option<Game_Inventory_EquipmentSlot>" }]
  returns := .named "SlotColumn"
  body := [.return (.conditional (isTag (id "slot") "none") .undefined
    (tagOf (unwrapped (id "slot"))))]

/-- An optional engine number as an optional column. -/
def numberColumn : Function where
  isAsync := false
  name := "numberColumn"
  parameters := [{ name := "value", type := .named "Option<number>" }]
  returns := .union [.number, .named "undefined"]
  body := [.return (.conditional (isTag (id "value") "none") .undefined (unwrapped (id "value")))]

/-- A per-battle penalty column, which stores nothing rather than a zero. -/
def penaltyColumn : Function where
  isAsync := false
  name := "penaltyColumn"
  parameters := [{ name := "value", type := .number }]
  returns := .union [.number, .named "undefined"]
  body := [.return (.conditional (eq (id "value") (.number 0)) .undefined (id "value"))]

/-- The `rooms.phase` column for a phase. -/
def phaseColumn : Function where
  isAsync := false
  name := "phaseColumn"
  parameters := [{ name := "phase", type := engineType "Phase" }]
  returns := .named "RoomPhaseColumn"
  body := [
    .ifThen (isTag phase "moving") [.return (.string "moving")],
    .ifThen (isTag phase "combat") [.return (.conditional
      (isTag (prop phase "stage") "defenderChoice")
      (.string "combatDefend") (.string "combatAttack"))],
    .ifThen (isTag phase "encounter") [.return (.string "revealingEncounter")],
    .ifThen (isTag phase "shop") [.return (.string "shopping")],
    .return (.string "awaitingRoll")]

/-- The `rooms.status` column for a phase. -/
def statusColumn : Function where
  isAsync := false
  name := "statusColumn"
  parameters := [{ name := "phase", type := engineType "Phase" }]
  returns := .named "RoomStatusColumn"
  body := [
    .ifThen (isTag phase "lobby") [.return (.string "lobby")],
    .ifThen (isTag phase "finished") [.return (.string "finished")],
    .return (.string "playing")]

/-- The `rooms.remainingMoves` column, which only a planned move is allowed to fill. -/
def movesColumn : Function where
  isAsync := false
  name := "movesColumn"
  parameters := [{ name := "phase", type := engineType "Phase" }]
  returns := .number
  body := [.return (.conditional (isTag phase "moving") (prop phase "moves") (.number 0))]

/-- The `combats.phase` column for a battle stage. -/
def stageColumn : Function where
  isAsync := false
  name := "stageColumn"
  parameters := [{ name := "stage", type := engineType "CombatStage" }]
  returns := .named "Doc<'combats'>['phase']"
  body := [
    .ifThen (isTag (id "stage") "resolved") [.return (.string "resolved")],
    .return (.conditional (isTag (id "stage") "defenderChoice")
      (.string "defend") (.string "attack"))]

/-- Every `players` column a hero owns, in schema order. -/
def heroColumnValues : List (String × Expr) :=
  [("authId", blankToAbsent (prop hero "owner")),
    ("name", prop hero "name"),
    ("color", prop hero "color"),
    ("position", prop hero "position"),
    ("previousPosition", call (id "numberColumn") [prop hero "previousPosition"]),
    ("gold", prop hero "gold"),
    ("hp", prop hero "hp"),
    ("maxHp", prop hero "maxHp"),
    ("attack", prop hero "attack"),
    ("defense", prop hero "defense"),
    ("magic", prop hero "magic"),
    ("athletics", prop hero "athletics"),
    ("agility", prop hero "agility"),
    ("dice", prop hero "dice")]

/-- Every `players` column a hero owns, ready to patch or insert. -/
def heroColumns : Function where
  isAsync := false
  name := "heroColumns"
  parameters := [{ name := "hero", type := engineType "PlayerState" }]
  returns := .inferred
  body := [.return (.object heroColumnValues)]

/-- One per-battle penalty column. -/
private def penalty (name : String) : String × Expr :=
  (name, call (id "penaltyColumn") [prop battle name])

/-- Every `combats` column a battle owns, apart from `createdAt`, which the row keeps. -/
def combatColumns : Function where
  isAsync := false
  name := "combatColumns"
  parameters := [
    { name := "roomId", type := .id .rooms },
    { name := "battle", type := engineType "CombatState" },
    { name := "stage", type := engineType "CombatStage" }]
  returns := .inferred
  body := [.return (.object [
    ("roomId", id "roomId"),
    ("playerId", .cast (prop battle "playerId") (.id .players)),
    ("spaceId", prop battle "spaceId"),
    ("enemyName", prop (prop battle "enemy") "name"),
    ("enemyElement", tagOf (prop (prop battle "enemy") "element")),
    ("enemyHp", prop battle "enemyHp"),
    ("enemyMaxHp", prop (prop battle "enemy") "hp"),
    ("enemyAttack", prop (prop battle "enemy") "attack"),
    ("enemyDefense", prop (prop battle "enemy") "defense"),
    ("enemyMagic", prop (prop battle "enemy") "magic"),
    ("enemyAthletics", prop (prop battle "enemy") "athletics"),
    ("enemyAgility", prop (prop battle "enemy") "agility"),
    penalty "enemyDefensePenalty",
    penalty "enemyMagicPenalty",
    penalty "enemyAthleticsPenalty",
    penalty "enemyAgilityPenalty",
    penalty "playerDefensePenalty",
    penalty "playerMagicPenalty",
    penalty "playerAthleticsPenalty",
    penalty "playerAgilityPenalty",
    ("reward", prop (prop battle "enemy") "reward"),
    ("round", prop battle "round"),
    ("phase", call (id "stageColumn") [id "stage"]),
    ("lastAttack", .conditional (isTag (prop battle "lastAttack") "none") .undefined
      (unwrapped (prop battle "lastAttack"))),
    ("lastGuard", .conditional (isTag (prop battle "lastGuard") "none") .undefined
      (tagOf (unwrapped (prop battle "lastGuard")))),
    ("lastDamage", call (id "numberColumn") [prop battle "lastDamage"]),
    ("message", prop battle "message")])]

/-- Every `encounters` column a drawn encounter owns, apart from `createdAt`. -/
def encounterColumns : Function where
  isAsync := false
  name := "encounterColumns"
  parameters := [
    { name := "roomId", type := .id .rooms },
    { name := "drawn", type := engineType "EncounterState" }]
  returns := .inferred
  body := [.return (.object [
    ("roomId", id "roomId"),
    ("playerId", .cast (prop drawn "playerId") (.id .players)),
    ("spaceId", prop drawn "spaceId"),
    ("kind", tagOf (prop drawn "kind")),
    ("outcomeId", prop (prop drawn "outcome") "id"),
    ("title", prop (prop drawn "outcome") "title"),
    ("description", prop (prop drawn "outcome") "description"),
    ("goldDelta", prop (prop drawn "outcome") "goldDelta"),
    ("hpDelta", prop (prop drawn "outcome") "hpDelta"),
    ("wheelIndex", prop drawn "wheelIndex"),
    ("status", .conditional (prop drawn "resolved")
      (.asConst (.string "resolved")) (.asConst (.string "revealing")))])]

/-- The generated engine-to-column dictionary. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Aggregate/Rows.lean"
  imports := [
    engineImport [typeBinding "CombatStage", typeBinding "CombatState",
      typeBinding "EncounterState", typeBinding "Game_Inventory_EquipmentSlot",
      typeBinding "Option", typeBinding "Phase", typeBinding "PlayerState"],
    dataModelImport [typeBinding "Doc", typeBinding "Id"]
  ]
  items := [
    .typeAlias "RoomPhaseColumn" (.named "NonNullable<Doc<'rooms'>['phase']>"),
    .typeAlias "RoomStatusColumn" (.named "Doc<'rooms'>['status']"),
    .typeAlias "SlotColumn" (.named "Doc<'playerItems'>['equippedSlot']"),
    .function slotColumn,
    .function numberColumn,
    .function penaltyColumn,
    .function phaseColumn,
    .function statusColumn,
    .function movesColumn,
    .function stageColumn,
    .function heroColumns,
    .function combatColumns,
    .function encounterColumns
  ]

end Mythroads.Backend.Aggregate.Rows
