import Mythroads.Convex.TypeScript

namespace Mythroads.Backend.Shop

open Mythroads.Convex.TypeScript

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments
private def reject (message : String) : Statement :=
  .throw (.new "ConvexError" [.string message])

private def shopArgs : TsType := .object [
  ("roomId", .id "rooms"), ("playerId", .id "players"), ("itemId", .string)
]

def buyItemFunction : Function where
  name := "buyItem"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "args", type := shopArgs }
  ]
  returns := .promise .void
  body := [
    .constDecl "roomId" (prop (id "args") "roomId"),
    .constDecl "playerId" (prop (id "args") "playerId"),
    .constDecl "itemId" (prop (id "args") "itemId"),
    .constDecl "room" (.await (method (prop (id "ctx") "db") "get" [id "roomId"])),
    .constDecl "player" (.await (method (prop (id "ctx") "db") "get" [id "playerId"])),
    .constDecl "item" (call (id "getItem") [id "itemId"]),
    .ifThen (.binary
      (.binary
        (.binary
          (.binary (.prefix "!" (id "room")) "||" (.prefix "!" (id "player"))) "||"
          (.prefix "!" (id "item"))) "||"
        (.binary (prop (id "room") "activePlayerId") "!==" (id "playerId"))) "||"
      (.binary
        (.binary (call (id "roomPhase") [id "room"]) "!==" (.string "shopping")) "||"
        (.binary (prop (id "room") "shopKind") "!==" (prop (id "item") "shop")))) [
      reject "That item is not available here."
    ],
    .ifThen (.binary (prop (id "player") "gold") "<" (prop (id "item") "price")) [
      reject "You need more gold."
    ],
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      id "playerId", .object [("gold", .binary (prop (id "player") "gold") "-"
        (prop (id "item") "price"))]
    ])),
    .expression (.await (method (prop (id "ctx") "db") "insert" [
      .string "playerItems", .object [
        ("playerId", id "playerId"), ("itemId", id "itemId"),
        ("purchasedAt", call (prop (id "Date") "now"))
      ]
    ]))
  ]

def leaveShopFunction : Function where
  name := "leaveShop"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "subjects", type := .object [
        ("roomId", .id "rooms"), ("playerId", .id "players")
      ] }
  ]
  returns := .promise .void
  body := [
    .constDecl "roomId" (prop (id "subjects") "roomId"),
    .constDecl "playerId" (prop (id "subjects") "playerId"),
    .constDecl "room" (.await (method (prop (id "ctx") "db") "get" [id "roomId"])),
    .constDecl "player" (.await (method (prop (id "ctx") "db") "get" [id "playerId"])),
    .ifThen (.binary
      (.binary
        (.binary (.prefix "!" (id "room")) "||" (.prefix "!" (id "player"))) "||"
        (.binary (prop (id "room") "activePlayerId") "!==" (id "playerId"))) "||"
      (.binary (call (id "roomPhase") [id "room"]) "!==" (.string "shopping"))) [
      reject "You are not shopping now."
    ],
    .expression (.await (call (id "advanceTurn") [
      id "ctx", id "room", id "playerId",
      .binary (prop (id "player") "name") "+" (.string " finished shopping.")
    ]))
  ]

def emitShop : String := emitFunction buyItemFunction ++ "\n" ++ emitFunction leaveShopFunction

end Mythroads.Backend.Shop
