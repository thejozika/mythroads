import Mythroads.Convex.TypeScript

namespace Mythroads.Backend.Retention

open Mythroads.Convex.TypeScript

def retentionDays : Nat := 90
def retentionBatchSize : Nat := 100

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments

private def expiredQuery : Expr :=
  method
    (method
      (method (prop (id "ctx") "db") "query" [.string "gameEvents"])
      "withIndex" [.string "by_createdAt", .arrow ["query"]
        (method (id "query") "lt" [.string "createdAt", id "cutoff"])])
    "take" [.number retentionBatchSize]

def deleteExpiredFunction : Function where
  name := "deleteExpiredGameEventBatch"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "cutoff", type := .number }
  ]
  returns := .promise (.object [("deleted", .number), ("complete", .boolean)])
  body := [
    .constDecl "expired" (.await expiredQuery),
    .forOf "event" (id "expired") [
      .expression (.await (method (prop (id "ctx") "db") "delete" [prop (id "event") "_id"]))
    ],
    .return (.object [
      ("deleted", prop (id "expired") "length"),
      ("complete", .binary (prop (id "expired") "length") "<" (.number retentionBatchSize))
    ])
  ]

def emitRetention : String :=
  s!"export const GAME_EVENT_RETENTION_DAYS = {retentionDays}\n" ++
  s!"export const GAME_EVENT_RETENTION_BATCH_SIZE = {retentionBatchSize}\n\n" ++
  emitFunction deleteExpiredFunction

end Mythroads.Backend.Retention
