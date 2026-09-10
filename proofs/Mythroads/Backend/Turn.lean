import Mythroads.Convex.Module
import Mythroads.Convex.Query

namespace Mythroads.Backend.Turn

open Mythroads.Convex
open Mythroads.Convex.TypeScript

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments

def roomPhaseFunction : Function where
  isAsync := false
  name := "roomPhase"
  parameters := [{ name := "room", type := .doc .rooms }]
  returns := .named "RoomPhase"
  body := [
    .ifThen (prop (id "room") "phase") [.return (prop (id "room") "phase")],
    .return (.conditional (.binary (prop (id "room") "remainingMoves") ">" (.number 0))
      (.string "moving") (.string "awaitingRoll"))
  ]

private def playersQuery : Expr :=
  Query.indexedRead .players .playersByRoom [prop (id "room") "_id"] (.take 4)

def advanceTurnFunction : Function where
  name := "advanceTurn"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "room", type := .doc .rooms },
    { name := "playerId", type := .id .players },
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

/-- Turn order and phase reset. -/
def module : Module where
  provenance := some "proofs/Mythroads/Game/Turn.lean"
  imports := [
    { source := "../_generated/dataModel", bindings := [{ name := "Doc", isType := true }, { name := "Id", isType := true }] },
    { source := "../_generated/server", bindings := [{ name := "MutationCtx", isType := true }] }
  ]
  items := [
    .raw "export type RoomPhase = NonNullable<Doc<'rooms'>['phase']>\n",
    .function roomPhaseFunction,
    .function advanceTurnFunction
  ]

end Mythroads.Backend.Turn
