import Mythroads.Convex.TypeScript
import Mythroads.Game.Inventory

namespace Mythroads.Backend.Inventory

open Mythroads.Convex.TypeScript
open Mythroads.Game.Inventory

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr) : Expr := .call target arguments

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

def emitInventoryBackend : String :=
  "export const inventoryQueryDefinition = {\n" ++
  "    args: { playerId: v.id('players') },\n" ++
  "    returns: v.array(schema.doc('playerItems')),\n" ++
  "    handler: async (ctx: QueryCtx, { playerId }: { playerId: Id<'players'> }) => {\n" ++
  "        const identity = await ctx.auth.getUserIdentity()\n" ++
  "        if (!identity) throw new ConvexError('Sign in to view an inventory.')\n" ++
  "        const player = await ctx.db.get(playerId)\n" ++
  "        if (!player) throw new ConvexError('That hero does not exist.')\n" ++
  "        if (!player.authId || identity.tokenIdentifier !== player.authId) {\n" ++
  "            throw new ConvexError('That inventory belongs to another account.')\n" ++
  "        }\n" ++
  "        return await ctx.db.query('playerItems')\n" ++
  "            .withIndex('by_playerId', (q) => q.eq('playerId', playerId))\n" ++
  "            .take(40)\n" ++
  "    },\n" ++
  "}\n\n" ++ emitTypeAlias "EquipmentSlot" equipmentSlotType ++ "\n" ++
  emitFunction equipItemFunction

end Mythroads.Backend.Inventory
