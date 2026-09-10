import Mythroads.Convex.TypeScript

namespace Mythroads.Backend.Turn

open Mythroads.Convex.TypeScript

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments

def roomPhaseFunction : Function where
  isAsync := false
  name := "roomPhase"
  parameters := [{ name := "room", type := .named "Doc<'rooms'>" }]
  returns := .named "RoomPhase"
  body := [
    .ifThen (prop (id "room") "phase") [.return (prop (id "room") "phase")],
    .return (.conditional (.binary (prop (id "room") "remainingMoves") ">" (.number 0))
      (.string "moving") (.string "awaitingRoll"))
  ]

private def playersQuery : Expr :=
  .await (method
    (method
      (method (prop (id "ctx") "db") "query" [.string "players"])
      "withIndex" [.string "by_room", .arrow ["query"]
        (method (id "query") "eq" [.string "roomId", prop (id "room") "_id"])])
    "take" [.number 4])

def advanceTurnFunction : Function where
  name := "advanceTurn"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "room", type := .named "Doc<'rooms'>" },
    { name := "playerId", type := .id "players" },
    { name := "message", type := .string }
  ]
  returns := .promise .void
  body := [
    .constDecl "unsortedPlayers" playersQuery,
    .constDecl "players" (method (id "unsortedPlayers") "sort" [
      .arrow ["a", "b"] (.binary (prop (id "a") "joinedAt") "-"
        (prop (id "b") "joinedAt"))
    ]),
    .constDecl "currentIndex" (method (id "players") "findIndex" [
      .arrow ["candidate"] (.binary (prop (id "candidate") "_id") "===" (id "playerId"))
    ]),
    .constDecl "next" (.index (id "players")
      (.binary (.binary (id "currentIndex") "+" (.number 1)) "%"
        (prop (id "players") "length"))),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      prop (id "room") "_id", .object [
        ("remainingMoves", .number 0), ("activePlayerId", prop (id "next") "_id"),
        ("round", .conditional
          (.binary (id "currentIndex") "==="
            (.binary (prop (id "players") "length") "-" (.number 1)))
          (.binary (prop (id "room") "round") "+" (.number 1)) (prop (id "room") "round")),
        ("phase", .string "awaitingRoll"), ("activeEncounterId", .undefined),
        ("activeCombatId", .undefined), ("shopKind", .undefined), ("message", id "message")
      ]
    ]))
  ]

def emitTurn : String :=
  "export type RoomPhase = NonNullable<Doc<'rooms'>['phase']>\n\n" ++
  emitFunction roomPhaseFunction ++ "\n" ++ emitFunction advanceTurnFunction

end Mythroads.Backend.Turn
