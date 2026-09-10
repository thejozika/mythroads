import Mythroads.Convex.TypeScript
import Mythroads.Game.Inventory

namespace Mythroads.Backend.Inventory

open Mythroads.Convex.TypeScript
open Mythroads.Game.Inventory

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments
private def vcall (name : String) (arguments : List Expr := []) : Expr :=
  call (prop (id "v") name) arguments

def equipmentSlotType : TsType :=
  .union (allEquipmentSlots.map fun slot => .literalString slot.label)

private def inventoryQuery : Expr :=
  call
    (prop
      (call
        (prop
          (call (prop (prop (id "ctx") "db") "query") [.string "playerItems"])
          "withIndex")
        [.string "by_playerId",
          .arrow ["query"]
            (call (prop (id "query") "eq") [.string "playerId", id "playerId"])])
      "take")
    [.number 40]

def equipItemFunction : Function where
  name := "equipItem"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "args", type := .object [
        ("playerId", .id "players"),
        ("playerItemId", .id "playerItems"),
        ("slot", .named "EquipmentSlot")
      ] }
  ]
  returns := .promise .void
  body := [
    .constDecl "playerId" (prop (id "args") "playerId"),
    .constDecl "playerItemId" (prop (id "args") "playerItemId"),
    .constDecl "slot" (prop (id "args") "slot"),
    .expression (.await (call (id "requirePlayerOwner") [id "ctx", id "playerId"])),
    .constDecl "owned" (.await (call (prop (prop (id "ctx") "db") "get")
      [.string "playerItems", id "playerItemId"])),
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
    .constDecl "inventory" (.await inventoryQuery),
    .constDecl "occupied"
      (call (prop (id "inventory") "find")
        [.arrow ["candidate"]
          (.binary (prop (id "candidate") "equippedSlot") "===" (id "slot"))]),
    .ifThen (id "occupied") [
      .expression (.await (call (prop (prop (id "ctx") "db") "patch")
        [.string "playerItems", prop (id "occupied") "_id",
          .object [("equippedSlot", .undefined)]]))
    ],
    .expression (.await (call (prop (prop (id "ctx") "db") "patch")
      [.string "playerItems", id "playerItemId", .object [("equippedSlot", id "slot")]]))
  ]

def inventoryQueryDefinition : EndpointDefinition where
  name := "inventoryQueryDefinition"
  arguments := [("playerId", vcall "id" [.string "players"])]
  returns := vcall "array" [call (prop (id "schema") "doc") [.string "playerItems"]]
  handler := {
    parameters := [
      { name := "ctx", type := .named "QueryCtx" },
      { name := "{ playerId }", type := .object [("playerId", .id "players")] }
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
      .return (.await inventoryQuery)
    ]
  }

def emitInventoryBackend : String :=
  emitEndpointDefinition inventoryQueryDefinition ++ "\n" ++
  emitTypeAlias "EquipmentSlot" equipmentSlotType ++ "\n" ++
  emitFunction equipItemFunction

end Mythroads.Backend.Inventory
