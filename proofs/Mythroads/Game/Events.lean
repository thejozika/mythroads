import Mythroads.Convex.Module
import Mythroads.Convex.Ty
import Mythroads.Game.Inventory

namespace Mythroads.Game.Events

open Mythroads.Convex
open Mythroads.Convex.Ty (literals)

private def empty : Ty := Ty.obj []
private def roomPlayer : Ty := Ty.obj [
  ("roomId", .id .rooms), ("playerId", .id .players)
]
private def event (type : String) (subjects data : Ty) : Ty := Ty.obj [
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
  subjects : Ty
  data : Ty
  authority : Authority
  route : Route
  persistent : Bool := true
  deriving Repr

private def spec (type : String) (subjects data : Ty) (authority : Authority)
    (route : Route) (persistent := true) : EventSpec :=
  { type, subjects, data, authority, route, persistent }

def specs : List EventSpec := [
  spec "room.create" empty (Ty.obj [("seed", .optional .number)]) .account .createRoom,
  spec "player.join" (Ty.obj [("code", .string)])
    (Ty.obj [("name", .string), ("color", .string)]) .account .joinRoom,
  spec "game.start" (Ty.obj [("roomId", .id .rooms)]) empty .roomHost .startRoom,
  spec "movement.roll" roomPlayer empty .playerOwner .rollMovement,
  spec "movement.select" roomPlayer (Ty.obj [("destination", .number)])
    .playerOwner .selectDestination,
  spec "movement.cancel" roomPlayer empty .playerOwner .cancelDestination,
  spec "movement.step" roomPlayer (Ty.obj [("destination", .number)])
    .playerOwner .movePlayer,
  spec "combat.attack" roomPlayer (Ty.obj [("attack", literals [
    "stab", "chargeHigh", "chargeSide", "leap", "emberBlast", "scorchArmor",
    "tideNeedle", "undertow", "galeBlade", "windShear", "stoneCrash", "calcify"
  ])]) .playerOwner .chooseAttack,
  spec "combat.guard" roomPlayer (Ty.obj [("guard", literals [
    "high", "side", "brace", "ward"
  ])]) .playerOwner .chooseGuard,
  spec "encounter.resolve" (Ty.obj [
    ("roomId", .id .rooms), ("playerId", .id .players),
    ("encounterId", .id .encounters)
  ]) empty .playerOwner .resolveEncounter,
  spec "shop.buy" roomPlayer (Ty.obj [("itemId", .string)]) .playerOwner .buyItem,
  spec "inventory.equip" (Ty.obj [
    ("playerId", .id .players), ("playerItemId", .id .playerItems)
  ]) (Ty.obj [("slot", literals
    (Inventory.allEquipmentSlots.map Inventory.EquipmentSlot.label))])
    .playerOwner .equipItem,
  spec "shop.leave" roomPlayer empty .playerOwner .leaveShop,
  spec "camera.toggle" roomPlayer empty .playerOwner .toggleCamera false,
  spec "camera.move" roomPlayer (Ty.obj [("direction", literals [
    "up", "down", "left", "right"
  ])]) .playerOwner .moveCamera false,
  spec "camera.zoom" roomPlayer (Ty.obj [("delta", .union [
    .literalNumber (-1), .literalNumber 1
  ])]) .playerOwner .zoomCamera false
]

def EventSpec.validator (value : EventSpec) : Ty :=
  event value.type value.subjects value.data

def gameEvent : Ty := .union (specs.map EventSpec.validator)

def dispatchResult : Ty := .union [
  Ty.obj [("kind", .literalString "accepted")],
  Ty.obj [("kind", .literalString "room.created"), ("code", .string)],
  Ty.obj [("kind", .literalString "player.joined"), ("playerId", .id .players)]
]

theorem exactlyCameraEventsAreEphemeral :
    (specs.filter fun value => !value.persistent).map EventSpec.type =
      ["camera.toggle", "camera.move", "camera.zoom"] := by
  decide

/-- The single source of the event sum: one `v.union` arm per `EventSpec`, plus the dispatch
result, with the TypeScript types inferred from the validators rather than restated. -/
def module : Module where
  provenance := some "proofs/Mythroads/Game/Events.lean"
  imports := [{ source := "convex/values", bindings := [
    { name := "Infer", isType := true }, { name := "v" }] }]
  items := [
    .raw ("export const gameEventValidator = " ++ TypeScript.emitExpr gameEvent.validator ++ "\n"),
    .raw ("export const dispatchResultValidator = " ++
      TypeScript.emitExpr dispatchResult.validator ++ "\n"),
    .raw ("export type GameEvent = Infer<typeof gameEventValidator>\n" ++
      "export type DispatchResult = Infer<typeof dispatchResultValidator>\n")
  ]

end Mythroads.Game.Events
