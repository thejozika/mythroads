import Mythroads.Convex.Schema
import Mythroads.Game.Inventory

namespace Mythroads.Game.Schema

/-! # The document shape of every table

This is the single source of the Convex data model. Each table's document is one `Ty`, from which
`Ty.validator` derives the emitted `v.object({ … })` and `Ty.tsType` derives the matching
TypeScript type; the table's identity and its indexes come from `Convex/Table.lean`.

`document` is a total function over `Table`, so a new table cannot be added to the enumeration
without a document here, and a removed table cannot leave a stale definition behind.

The `gameEvents` document is a union of a legacy untyped row and the typed envelope. The legacy arm
is a migration bridge for rows written before the envelope existed; dropping it is a breaking data
change, not a refactor, so it stays until those rows are gone.
-/

open Mythroads.Convex
open Mythroads.Convex.Ty (literals)

/-- The equipment slots an owned item may occupy, taken from the item catalogue. -/
private def equipmentSlot : Ty :=
  literals (Inventory.allEquipmentSlots.map Inventory.EquipmentSlot.label)

/-- The authority recorded alongside a durable game event. -/
private def authority : Ty := .obj [
  ("mode", literals ["prototypePlayerId", "authenticated", "developmentBypass"]),
  ("actorPlayerId", .optional (.id .players)), ("actorAuthId", .optional .string)
]

/-- The document shape of every table. -/
def document : Table → Ty
  | .rooms => .obj [
      ("code", .string), ("hostAuthId", .optional .string),
      ("status", literals ["lobby", "playing", "finished"]),
      ("activePlayerId", .optional (.id .players)), ("remainingMoves", .number),
      ("lastRoll", .optional (.array .number)), ("message", .string), ("round", .number),
      ("phase", .optional (literals ["awaitingRoll", "moving", "revealingEncounter", "shopping",
        "combatAttack", "combatDefend"])),
      ("activeEncounterId", .optional (.id .encounters)),
      ("activeCombatId", .optional (.id .combats)),
      ("shopKind", .optional (literals ["armoury", "jeweller", "weapons", "items", "magic"])),
      ("rngState", .optional .number), ("rngCounter", .optional .number)
    ]
  | .players => .obj [
      ("roomId", .id .rooms), ("authId", .optional .string), ("name", .string),
      ("color", .string), ("position", .number), ("previousPosition", .optional .number),
      ("gold", .number), ("hp", .number), ("maxHp", .number), ("attack", .number),
      ("defense", .optional .number), ("magic", .optional .number),
      ("athletics", .optional .number), ("agility", .optional .number),
      ("dice", .array .number), ("joinedAt", .number)
    ]
  | .encounters => .obj [
      ("roomId", .id .rooms), ("playerId", .id .players), ("spaceId", .number),
      ("kind", literals ["combat", "event"]), ("outcomeId", .string), ("title", .string),
      ("description", .string), ("goldDelta", .number), ("hpDelta", .number),
      ("wheelIndex", .number), ("status", literals ["revealing", "resolved"]),
      ("createdAt", .number)
    ]
  | .combats => .obj [
      ("roomId", .id .rooms), ("playerId", .id .players), ("spaceId", .number),
      ("enemyName", .string), ("enemyElement", literals ["fire", "water", "wind", "earth"]),
      ("enemyHp", .number), ("enemyMaxHp", .number), ("enemyAttack", .number),
      ("enemyDefense", .optional .number), ("enemyMagic", .optional .number),
      ("enemyAthletics", .optional .number), ("enemyAgility", .optional .number),
      ("enemyDefensePenalty", .optional .number), ("enemyMagicPenalty", .optional .number),
      ("enemyAthleticsPenalty", .optional .number), ("enemyAgilityPenalty", .optional .number),
      ("playerDefensePenalty", .optional .number), ("playerMagicPenalty", .optional .number),
      ("playerAthleticsPenalty", .optional .number), ("playerAgilityPenalty", .optional .number),
      ("reward", .number), ("round", .number),
      ("phase", literals ["attack", "defend", "resolved"]),
      ("lastAttack", .optional .string), ("lastGuard", .optional .string),
      ("lastDamage", .optional .number), ("message", .string), ("createdAt", .number)
    ]
  | .roomSelections => .obj [
      ("roomId", .id .rooms), ("playerId", .id .players), ("destination", .number),
      ("path", .optional (.array .number)), ("updatedAt", .number)
    ]
  | .playerItems => .obj [
      ("playerId", .id .players), ("itemId", .string),
      ("equippedSlot", .optional equipmentSlot), ("purchasedAt", .number)
    ]
  | .gameEvents => .union [
      .obj [("type", .string), ("subjects", .any), ("data", .any), ("createdAt", .number)],
      .obj [
        ("eventId", .string), ("commandId", .optional .string),
        ("schemaVersion", .literalNumber 1), ("roomId", .optional (.id .rooms)),
        ("actorPlayerId", .optional (.id .players)), ("authority", authority),
        ("event", .external "gameEventValidator" "GameEvent"),
        ("result", .external "dispatchResultValidator" "DispatchResult"), ("createdAt", .number)
      ]
    ]
  | .roomCameras => .obj [
      ("roomId", .id .rooms), ("mode", literals ["follow", "free"]),
      ("targetX", .number), ("targetZ", .number), ("distance", .number),
      ("updatedAt", .number)
    ]

/-- The application schema handed to the emitter. -/
def appSchema : Convex.Schema.AppSchema where
  targetConvexVersion := "1.45.0"
  document := document

end Mythroads.Game.Schema
