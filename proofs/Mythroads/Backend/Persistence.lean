import Mythroads.Convex.Module
import Mythroads.Convex.Query

namespace Mythroads.Backend.Persistence

open Mythroads.Convex
open Mythroads.Convex.TypeScript

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments

private def eventByCommandId : Expr :=
  Query.indexedRead .gameEvents .gameEventsByCommandId [id "commandId"] .unique

def priorResultFunction : Function where
  name := "priorDispatchResult"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "commandId", type := .union [.string, .named "undefined"] },
    { name := "actorAuthId", type := .union [.string, .named "null"] }
  ]
  returns := .promise (.union [.named "DispatchResult", .named "null"])
  body := [
    .ifThen (.prefix "!" (id "commandId")) [.return .null],
    .constDecl "existing" eventByCommandId,
    .ifThen (.binary (.prefix "!" (id "existing")) "||"
      (.prefix "!" (.binary (.string "result") "in" (id "existing")))) [.return .null],
    .ifThen (.binary (id "actorAuthId") "&&"
      (.binary (prop (prop (id "existing") "authority") "actorAuthId") "!=="
        (id "actorAuthId"))) [
      .throw (.new "ConvexError" [.string "That command belongs to another account."])
    ],
    .return (prop (id "existing") "result")
  ]

private def eventId : Expr := .binary (id "commandId") "??"
  (.binary
    (.binary
      (.binary (call (prop (id "createdAt") "toString") [.number 36]) "+" (.string ":")) "+"
      (prop (id "event") "type")) "+"
    (.binary (.string ":") "+" (call (prop (id "JSON") "stringify")
      [prop (id "event") "subjects"])))

def persistFunction : Function where
  name := "persistGameEvent"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "event", type := .named "GameEvent" },
    { name := "result", type := .named "DispatchResult" },
    { name := "commandId", type := .union [.string, .named "undefined"] },
    { name := "actorAuthId", type := .union [.string, .named "null"] }
  ]
  returns := .promise .void
  body := [
    .ifThen (.prefix "!" (call (id "isPersistentGameEvent") [id "event"])) [.returnVoid],
    .constDecl "createdAt" (call (prop (id "Date") "now")),
    .constDecl "roomId" (call (id "eventRoomId") [id "event"]),
    .constDecl "authority" (call (id "resolveEventAuthority")
      [id "event", id "result", id "actorAuthId"]),
    .constDecl "record" (.object [
      ("eventId", eventId), ("schemaVersion", .asConst (.number 1)),
      ("event", id "event"), ("result", id "result"), ("authority", id "authority"),
      ("createdAt", id "createdAt"), ("commandId", id "commandId"),
      ("roomId", id "roomId"), ("actorPlayerId", prop (id "authority") "actorPlayerId")
    ]),
    .expression (Query.insert .gameEvents (id "record"))
  ]

/-- Command deduplication and the durable game-event log. -/
def module : Module where
  provenance := some "proofs/Mythroads/Game/Events.lean"
  imports := [
    { source := "convex/values", bindings := [{ name := "ConvexError" }] },
    { source := "../_generated/server", bindings := [{ name := "MutationCtx", isType := true }] },
    { source := "./authority", bindings := [{ name := "resolveEventAuthority" }] },
    { source := "./policy", bindings := [{ name := "eventRoomId" }, { name := "isPersistentGameEvent" }] },
    { source := "./validators", bindings := [{ name := "DispatchResult", isType := true }, { name := "GameEvent", isType := true }] }
  ]
  items := [
    .function priorResultFunction,
    .function persistFunction
  ]

end Mythroads.Backend.Persistence
