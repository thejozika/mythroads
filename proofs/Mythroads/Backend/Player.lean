import Mythroads.Convex.TypeScript
import Mythroads.Game.Inventory
import Mythroads.Game.Player

namespace Mythroads.Backend.Player

open Mythroads.Convex.TypeScript
open Mythroads.Game

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments

private def playerDocument : Expr := .object [
  ("roomId", id "roomId"), ("authId", id "authId"),
  ("name", prop (id "data") "name"), ("color", prop (id "data") "color"),
  ("position", .number Player.startingStats.position),
  ("gold", .number Player.startingStats.gold), ("hp", .number Player.startingStats.hp),
  ("maxHp", .number Player.startingStats.hp),
  ("attack", .number Player.startingStats.attack),
  ("defense", .number Player.startingStats.defense),
  ("magic", .number Player.startingStats.magic),
  ("athletics", .number Player.startingStats.athletics),
  ("agility", .number Player.startingStats.agility),
  ("dice", .array (Player.startingStats.dice.map Expr.number)),
  ("joinedAt", id "createdAt")
]

private def starterItem (itemId slot : String) : Expr := .object [
  ("playerId", id "playerId"), ("itemId", .string itemId),
  ("equippedSlot", .string slot), ("purchasedAt", id "createdAt")
]

def createPlayerFunction : Function where
  name := "createPlayer"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "roomId", type := .id "rooms" },
    { name := "data", type := .object [("name", .string), ("color", .string)] },
    { name := "authId", type := .union [.string, .named "undefined"] }
  ]
  returns := .promise (.id "players")
  body := [
    .constDecl "createdAt" (call (prop (id "Date") "now")),
    .constDecl "playerId" (.await (method (prop (id "ctx") "db") "insert"
      [.string "players", playerDocument])),
    .expression (.await (method (prop (id "ctx") "db") "insert"
      [.string "playerItems", starterItem "ember_grimoire" "offensiveMagic"])),
    .expression (.await (method (prop (id "ctx") "db") "insert"
      [.string "playerItems", starterItem "aegis_script" "defensiveMagic"])),
    .return (id "playerId")
  ]

def emitPlayer : String := emitFunction createPlayerFunction

end Mythroads.Backend.Player
