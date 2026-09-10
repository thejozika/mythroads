import Mythroads.Convex.Schema
import Mythroads.Game.Inventory

namespace Mythroads.Game.Events

open Mythroads.Convex.Schema

private def empty : Validator := object []
private def roomPlayer : Validator := object [
  ("roomId", .id "rooms"), ("playerId", .id "players")
]

private def event (type : String) (subjects data : Validator) : Validator := object [
  ("type", .literalString type), ("subjects", subjects), ("data", data)
]

def gameEvent : Validator := .union [
  event "room.create" empty (object [("seed", optional .number)]),
  event "player.join" (object [("code", .string)])
    (object [("name", .string), ("color", .string)]),
  event "game.start" (object [("roomId", .id "rooms")]) empty,
  event "movement.roll" roomPlayer empty,
  event "movement.select" roomPlayer (object [("destination", .number)]),
  event "movement.cancel" roomPlayer empty,
  event "movement.step" roomPlayer (object [("destination", .number)]),
  event "combat.attack" roomPlayer (object [("attack", literals [
    "stab", "chargeHigh", "chargeSide", "leap", "emberBlast", "scorchArmor",
    "tideNeedle", "undertow", "galeBlade", "windShear", "stoneCrash", "calcify"
  ])]),
  event "combat.guard" roomPlayer (object [("guard", literals [
    "high", "side", "brace", "ward"
  ])]),
  event "encounter.resolve" (object [
    ("roomId", .id "rooms"), ("playerId", .id "players"),
    ("encounterId", .id "encounters")
  ]) empty,
  event "shop.buy" roomPlayer (object [("itemId", .string)]),
  event "inventory.equip" (object [
    ("playerId", .id "players"), ("playerItemId", .id "playerItems")
  ]) (object [("slot", literals
    (Inventory.allEquipmentSlots.map Inventory.EquipmentSlot.label))]),
  event "shop.leave" roomPlayer empty,
  event "camera.toggle" roomPlayer empty,
  event "camera.move" roomPlayer (object [("direction", literals [
    "up", "down", "left", "right"
  ])]),
  event "camera.zoom" roomPlayer (object [("delta", .union [
    .literalNumber (-1), .literalNumber 1
  ])])
]

def dispatchResult : Validator := .union [
  object [("kind", .literalString "accepted")],
  object [("kind", .literalString "room.created"), ("code", .string)],
  object [("kind", .literalString "player.joined"), ("playerId", .id "players")]
]

end Mythroads.Game.Events
