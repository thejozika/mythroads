import Mythroads.Convex.Module
import Mythroads.Convex.Query

namespace Mythroads.Backend.Retention

open Mythroads.Convex
open Mythroads.Convex.TypeScript

def retentionDays : Nat := 90
def retentionBatchSize : Nat := 100

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments

private def expiredQuery : Expr :=
  Query.indexedRead .gameEvents .gameEventsByCreatedAt [id "cutoff"]
    (.take retentionBatchSize) (bound := .lt)

def deleteExpiredFunction : Function where
  name := "deleteExpiredGameEventBatch"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "cutoff", type := .number }
  ]
  returns := .promise (.obj [("deleted", .number), ("complete", .boolean)])
  body := [
    .constDecl "expired" expiredQuery,
    .forOf "event" (id "expired") [
      .expression (Query.remove (prop (id "event") "_id"))
    ],
    .return (.object [
      ("deleted", prop (id "expired") "length"),
      ("complete", .binary (prop (id "expired") "length") "<" (.number retentionBatchSize))
    ])
  ]

/-- The bounded batch delete that trims the game-event log. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Retention.lean"
  imports := [
    { source := "../_generated/server", bindings := [{ name := "MutationCtx", isType := true }] }
  ]
  items := [
    .raw (s!"export const GAME_EVENT_RETENTION_DAYS = {retentionDays}\n" ++
      s!"export const GAME_EVENT_RETENTION_BATCH_SIZE = {retentionBatchSize}\n"),
    .function deleteExpiredFunction
  ]

end Mythroads.Backend.Retention
