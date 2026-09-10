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

inductive Authority where
  | account | roomHost | playerOwner
  deriving Repr, DecidableEq

inductive Route where
  | createRoom | joinRoom | startRoom
  | rollMovement | selectDestination | cancelDestination | movePlayer
  | chooseAttack | chooseGuard | resolveEncounter
  | buyItem | equipItem | leaveShop
  | toggleCamera | moveCamera | zoomCamera
  deriving Repr, DecidableEq

structure EventSpec where
  type : String
  subjects : Validator
  data : Validator
  authority : Authority
  route : Route
  persistent : Bool := true
  deriving Repr

private def spec (type : String) (subjects data : Validator) (authority : Authority)
    (route : Route) (persistent := true) : EventSpec :=
  { type, subjects, data, authority, route, persistent }

def specs : List EventSpec := [
  spec "room.create" empty (object [("seed", optional .number)]) .account .createRoom,
  spec "player.join" (object [("code", .string)])
    (object [("name", .string), ("color", .string)]) .account .joinRoom,
  spec "game.start" (object [("roomId", .id "rooms")]) empty .roomHost .startRoom,
  spec "movement.roll" roomPlayer empty .playerOwner .rollMovement,
  spec "movement.select" roomPlayer (object [("destination", .number)])
    .playerOwner .selectDestination,
  spec "movement.cancel" roomPlayer empty .playerOwner .cancelDestination,
  spec "movement.step" roomPlayer (object [("destination", .number)])
    .playerOwner .movePlayer,
  spec "combat.attack" roomPlayer (object [("attack", literals [
    "stab", "chargeHigh", "chargeSide", "leap", "emberBlast", "scorchArmor",
    "tideNeedle", "undertow", "galeBlade", "windShear", "stoneCrash", "calcify"
  ])]) .playerOwner .chooseAttack,
  spec "combat.guard" roomPlayer (object [("guard", literals [
    "high", "side", "brace", "ward"
  ])]) .playerOwner .chooseGuard,
  spec "encounter.resolve" (object [
    ("roomId", .id "rooms"), ("playerId", .id "players"),
    ("encounterId", .id "encounters")
  ]) empty .playerOwner .resolveEncounter,
  spec "shop.buy" roomPlayer (object [("itemId", .string)]) .playerOwner .buyItem,
  spec "inventory.equip" (object [
    ("playerId", .id "players"), ("playerItemId", .id "playerItems")
  ]) (object [("slot", literals
    (Inventory.allEquipmentSlots.map Inventory.EquipmentSlot.label))])
    .playerOwner .equipItem,
  spec "shop.leave" roomPlayer empty .playerOwner .leaveShop,
  spec "camera.toggle" roomPlayer empty .playerOwner .toggleCamera false,
  spec "camera.move" roomPlayer (object [("direction", literals [
    "up", "down", "left", "right"
  ])]) .playerOwner .moveCamera false,
  spec "camera.zoom" roomPlayer (object [("delta", .union [
    .literalNumber (-1), .literalNumber 1
  ])]) .playerOwner .zoomCamera false
]

def EventSpec.validator (value : EventSpec) : Validator :=
  event value.type value.subjects value.data

def gameEvent : Validator := .union (specs.map EventSpec.validator)

def dispatchResult : Validator := .union [
  object [("kind", .literalString "accepted")],
  object [("kind", .literalString "room.created"), ("code", .string)],
  object [("kind", .literalString "player.joined"), ("playerId", .id "players")]
]

theorem exactlyCameraEventsAreEphemeral :
    (specs.filter fun value => !value.persistent).map EventSpec.type =
      ["camera.toggle", "camera.move", "camera.zoom"] := by
  native_decide

end Mythroads.Game.Events
