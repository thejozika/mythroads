import Mythroads.Convex.Module
import Mythroads.Game.Events

namespace Mythroads.Backend.Router

open Mythroads.Convex
open Mythroads.Convex.TypeScript
open Mythroads.Game.Events

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (name : String) (arguments : List Expr) : Expr := .call (id name) arguments
private def subject (name : String) : Expr := prop (prop (id "event") "subjects") name
private def data (name : String) : Expr := prop (prop (id "event") "data") name
private def awaited (name : String) (arguments : List Expr) : Expr := .await (call name arguments)

private def roomPlayerObject (extra : List (String × Expr) := []) : Expr := .object
  ([("roomId", subject "roomId"), ("playerId", subject "playerId")] ++ extra)

def routeBody : Route → List Statement
  | .createRoom => [.return (.object [
      ("kind", .string "room.created"),
      ("code", awaited "createRoom" [id "ctx",
        .binary (id "actorAuthId") "??" .undefined, data "seed"])
    ])]
  | .joinRoom => [.return (.object [
      ("kind", .string "player.joined"),
      ("playerId", awaited "joinRoom" [id "ctx", subject "code", prop (id "event") "data",
        .binary (id "actorAuthId") "??" .undefined])
    ])]
  | .startRoom => [.expression (awaited "startRoom" [id "ctx", subject "roomId"]), .break]
  | .rollMovement => [.expression (awaited "rollMovement"
      [id "ctx", prop (id "event") "subjects"]), .break]
  | .selectDestination => [.expression (awaited "selectDestination"
      [id "ctx", roomPlayerObject [("destination", data "destination")]]), .break]
  | .cancelDestination => [.expression (awaited "cancelDestination"
      [id "ctx", prop (id "event") "subjects"]), .break]
  | .movePlayer => [.expression (awaited "movePlayer"
      [id "ctx", roomPlayerObject [("destination", data "destination")]]), .break]
  | .chooseAttack => [.expression (awaited "chooseAttack"
      [id "ctx", prop (id "event") "subjects", data "attack"]), .break]
  | .chooseGuard => [.expression (awaited "chooseGuard"
      [id "ctx", prop (id "event") "subjects", data "guard"]), .break]
  | .resolveEncounter => [.expression (awaited "resolveEncounter"
      [id "ctx", prop (id "event") "subjects"]), .break]
  | .buyItem => [.expression (awaited "buyItem"
      [id "ctx", roomPlayerObject [("itemId", data "itemId")]]), .break]
  | .equipItem => [.expression (awaited "equipItem" [id "ctx", .object [
      ("playerId", subject "playerId"), ("playerItemId", subject "playerItemId"),
      ("slot", data "slot")
    ]]), .break]
  | .leaveShop => [.expression (awaited "leaveShop"
      [id "ctx", prop (id "event") "subjects"]), .break]
  | .toggleCamera => [.expression (awaited "toggleCamera"
      [id "ctx", prop (id "event") "subjects"]), .break]
  | .moveCamera => [.expression (awaited "moveCamera"
      [id "ctx", prop (id "event") "subjects", data "direction"]), .break]
  | .zoomCamera => [.expression (awaited "zoomCamera"
      [id "ctx", prop (id "event") "subjects", data "delta"]), .break]

def routeFunction : Function where
  name := "routeGameEvent"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "event", type := .named "GameEvent" },
    { name := "actorAuthId", type := .union [.string, .named "null"] }
  ]
  returns := .promise (.named "DispatchResult")
  body := [
    .switch (prop (id "event") "type") (specs.map fun spec => (spec.type, routeBody spec.route)),
    .return (.object [("kind", .string "accepted")])
  ]

/-- The exhaustive dispatch from a `GameEvent` to its transaction. -/
def module : Module where
  provenance := some "proofs/Mythroads/Game/Events.lean"
  imports := [
    { source := "../_generated/server", bindings := [{ name := "MutationCtx", isType := true }] },
    { source := "../camera", bindings := [{ name := "moveCamera" }, { name := "toggleCamera" }, { name := "zoomCamera" }] },
    { source := "../combat", bindings := [{ name := "chooseAttack" }, { name := "chooseGuard" }] },
    { source := "../encounters", bindings := [{ name := "resolveEncounter" }] },
    { source := "../rooms", bindings := [{ name := "cancelDestination" }, { name := "createRoom" }, { name := "joinRoom" }, { name := "movePlayer" }, { name := "rollMovement" }, { name := "selectDestination" }, { name := "startRoom" }] },
    { source := "../shops", bindings := [{ name := "buyItem" }, { name := "equipItem" }, { name := "leaveShop" }] },
    { source := "./validators", bindings := [{ name := "DispatchResult", isType := true }, { name := "GameEvent", isType := true }] }
  ]
  items := [
    .function routeFunction
  ]

end Mythroads.Backend.Router
