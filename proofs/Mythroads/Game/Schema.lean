import Mythroads.Convex.Schema
import Mythroads.Game.Inventory

namespace Mythroads.Game.Schema

open Mythroads.Convex.Schema

private def equipmentSlot : Validator :=
  literals (Inventory.allEquipmentSlots.map Inventory.EquipmentSlot.label)

private def room : Table where
  name := "rooms"
  document := object [
    ("code", .string), ("hostAuthId", optional .string),
    ("status", literals ["lobby", "playing", "finished"]),
    ("activePlayerId", optional (.id "players")), ("remainingMoves", .number),
    ("lastRoll", optional (.array .number)), ("message", .string), ("round", .number),
    ("phase", optional (literals ["awaitingRoll", "moving", "revealingEncounter", "shopping",
      "combatAttack", "combatDefend"])),
    ("activeEncounterId", optional (.id "encounters")),
    ("activeCombatId", optional (.id "combats")),
    ("shopKind", optional (literals ["armoury", "jeweller", "weapons", "items", "magic"])),
    ("rngState", optional .number), ("rngCounter", optional .number)
  ]
  indexes := [index "by_code" ["code"]]

private def player : Table where
  name := "players"
  document := object [
    ("roomId", .id "rooms"), ("authId", optional .string), ("name", .string),
    ("color", .string), ("position", .number), ("previousPosition", optional .number),
    ("gold", .number), ("hp", .number), ("maxHp", .number), ("attack", .number),
    ("defense", optional .number), ("magic", optional .number),
    ("athletics", optional .number), ("agility", optional .number),
    ("dice", .array .number), ("joinedAt", .number)
  ]
  indexes := [index "by_room" ["roomId"], index "by_room_and_authId" ["roomId", "authId"]]

private def encounter : Table where
  name := "encounters"
  document := object [
    ("roomId", .id "rooms"), ("playerId", .id "players"), ("spaceId", .number),
    ("kind", literals ["combat", "event"]), ("outcomeId", .string), ("title", .string),
    ("description", .string), ("goldDelta", .number), ("hpDelta", .number),
    ("wheelIndex", .number), ("status", literals ["revealing", "resolved"]),
    ("createdAt", .number)
  ]
  indexes := [index "by_roomId" ["roomId"]]

private def combat : Table where
  name := "combats"
  document := object [
    ("roomId", .id "rooms"), ("playerId", .id "players"), ("spaceId", .number),
    ("enemyName", .string), ("enemyElement", literals ["fire", "water", "wind", "earth"]),
    ("enemyHp", .number), ("enemyMaxHp", .number), ("enemyAttack", .number),
    ("enemyDefense", optional .number), ("enemyMagic", optional .number),
    ("enemyAthletics", optional .number), ("enemyAgility", optional .number),
    ("enemyDefensePenalty", optional .number), ("enemyMagicPenalty", optional .number),
    ("enemyAthleticsPenalty", optional .number), ("enemyAgilityPenalty", optional .number),
    ("playerDefensePenalty", optional .number), ("playerMagicPenalty", optional .number),
    ("playerAthleticsPenalty", optional .number), ("playerAgilityPenalty", optional .number),
    ("reward", .number), ("round", .number),
    ("phase", literals ["attack", "defend", "resolved"]),
    ("lastAttack", optional .string), ("lastGuard", optional .string),
    ("lastDamage", optional .number), ("message", .string), ("createdAt", .number)
  ]
  indexes := [index "by_roomId" ["roomId"]]

private def roomSelection : Table where
  name := "roomSelections"
  document := object [
    ("roomId", .id "rooms"), ("playerId", .id "players"), ("destination", .number),
    ("path", optional (.array .number)), ("updatedAt", .number)
  ]
  indexes := [index "by_roomId" ["roomId"]]

private def playerItem : Table where
  name := "playerItems"
  document := object [
    ("playerId", .id "players"), ("itemId", .string),
    ("equippedSlot", optional equipmentSlot), ("purchasedAt", .number)
  ]
  indexes := [index "by_playerId" ["playerId"]]

private def authority : Validator := object [
  ("mode", literals ["prototypePlayerId", "authenticated", "developmentBypass"]),
  ("actorPlayerId", optional (.id "players")), ("actorAuthId", optional .string)
]

private def gameEvent : Table where
  name := "gameEvents"
  document := .union [
    object [("type", .string), ("subjects", .any), ("data", .any), ("createdAt", .number)],
    object [
      ("eventId", .string), ("commandId", optional .string),
      ("schemaVersion", .literalNumber 1), ("roomId", optional (.id "rooms")),
      ("actorPlayerId", optional (.id "players")), ("authority", authority),
      ("event", .external "gameEventValidator"),
      ("result", .external "dispatchResultValidator"), ("createdAt", .number)
    ]
  ]
  indexes := [index "by_createdAt" ["createdAt"], index "by_commandId" ["commandId"],
    index "by_roomId_and_createdAt" ["roomId", "createdAt"]]

private def roomCamera : Table where
  name := "roomCameras"
  document := object [
    ("roomId", .id "rooms"), ("mode", literals ["follow", "free"]),
    ("targetX", .number), ("targetZ", .number), ("distance", .number),
    ("updatedAt", .number)
  ]
  indexes := [index "by_roomId" ["roomId"]]

def appSchema : AppSchema where
  targetConvexVersion := "1.45.0"
  tables := [room, player, encounter, combat, roomSelection, playerItem, gameEvent, roomCamera]

end Mythroads.Game.Schema
