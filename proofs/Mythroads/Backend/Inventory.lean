import Mythroads.Convex.Module
import Mythroads.Convex.Query
import Mythroads.Convex.Ty
import Mythroads.Game.Inventory

namespace Mythroads.Backend.Inventory

open Mythroads.Convex
open Mythroads.Convex.TypeScript
open Mythroads.Game.Inventory

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments

def equipmentSlotType : TsType :=
  .union (allEquipmentSlots.map fun slot => .literalString slot.label)

private def inventoryQuery : Expr :=
  Query.indexedRead .playerItems .playerItemsByPlayerId [id "playerId"] (.take 40)

def inventoryQueryDefinition : EndpointDefinition where
  name := "inventoryQueryDefinition"
  arguments := [("playerId", (Ty.id .players).validator)]
  returns := (Ty.array (.document .playerItems)).validator
  handler := {
    parameters := [
      { name := "ctx", type := .named "QueryCtx" },
      { name := "{ playerId }", type := .obj [("playerId", .id .players)] }
    ]
    body := [
      .constDecl "identity" (.await (method (prop (id "ctx") "auth") "getUserIdentity")),
      .ifThen (.prefix "!" (id "identity")) [
        .throw (.new "ConvexError" [.string "Sign in to view an inventory."])
      ],
      .constDecl "player" (.await (method (prop (id "ctx") "db") "get" [id "playerId"])),
      .ifThen (.prefix "!" (id "player")) [
        .throw (.new "ConvexError" [.string "That hero does not exist."])
      ],
      .ifThen (.binary (.prefix "!" (prop (id "player") "authId")) "||"
        (.binary (prop (id "identity") "tokenIdentifier") "!==" (prop (id "player") "authId"))) [
        .throw (.new "ConvexError" [.string "That inventory belongs to another account."])
      ],
      .return inventoryQuery
    ]
  }

/-- The owner-only inventory read. Equipping is a rule now, and lives in the engine. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Inventory.lean"
  imports := [
    { source := "convex/values", bindings := [{ name := "ConvexError" }, { name := "v" }] },
    { source := "../_generated/dataModel", bindings := [{ name := "Id", isType := true }] },
    { source := "../_generated/server", bindings := [{ name := "QueryCtx", isType := true }] },
    { source := "../schema", «default» := "schema" }
  ]
  items := [.endpoint inventoryQueryDefinition]

end Mythroads.Backend.Inventory
