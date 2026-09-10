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

def equipItemFunction : Function where
  name := "equipItem"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "args", type := .obj [
        ("playerId", .id .players),
        ("playerItemId", .id .playerItems),
        ("slot", .named "EquipmentSlot")
      ] }
  ]
  returns := .promise .void
  body := [
    .constDecl "playerId" (prop (id "args") "playerId"),
    .constDecl "playerItemId" (prop (id "args") "playerItemId"),
    .constDecl "slot" (prop (id "args") "slot"),
    .expression (.await (call (id "requirePlayerOwner") [id "ctx", id "playerId"])),
    .constDecl "owned" (Query.getIn .playerItems (id "playerItemId")),
    .constDecl "item" (.conditional (id "owned")
      (call (id "getItem") [prop (id "owned") "itemId"]) .null),
    .ifThen
      (.binary
        (.binary
          (.binary (.prefix "!" (id "owned")) "||"
            (.binary (prop (id "owned") "playerId") "!==" (id "playerId")))
          "||" (.prefix "!" (id "item")))
        "||" (.prefix "!" (call (prop (prop (id "item") "slots") "includes") [id "slot"])))
      [.throw (.new "ConvexError" [.string "That item cannot be equipped there."])],
    .constDecl "inventory" inventoryQuery,
    .constDecl "occupied"
      (call (prop (id "inventory") "find")
        [.arrow ["candidate"]
          (.binary (prop (id "candidate") "equippedSlot") "===" (id "slot"))]),
    .ifThen (id "occupied") [
      .expression (Query.patchIn .playerItems (prop (id "occupied") "_id")
        (.object [("equippedSlot", .undefined)]))
    ],
    .expression (Query.patchIn .playerItems (id "playerItemId")
      (.object [("equippedSlot", id "slot")]))
  ]

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

/-- The owner-only inventory read and the equip transaction. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Inventory.lean"
  imports := [
    { source := "convex/values", bindings := [{ name := "ConvexError" }, { name := "v" }] },
    { source := "../../shared/item.system", bindings := [{ name := "getItem" }] },
    { source := "../_generated/dataModel", bindings := [{ name := "Id", isType := true }] },
    { source := "../_generated/server", bindings := [{ name := "MutationCtx", isType := true }, { name := "QueryCtx", isType := true }] },
    { source := "../auth/authorization", bindings := [{ name := "requirePlayerOwner" }] },
    { source := "../schema", «default» := "schema" }
  ]
  items := [
    .endpoint inventoryQueryDefinition,
    .typeAlias "EquipmentSlot" equipmentSlotType,
    .function equipItemFunction
  ]

end Mythroads.Backend.Inventory
