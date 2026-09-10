import Mythroads.Convex.TypeScript
import Mythroads.Game.Events

namespace Mythroads.Backend.Authorization

open Mythroads.Convex.TypeScript
open Mythroads.Game.Events

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments

private def error (message : String) : Statement :=
  .throw (.new "ConvexError" [.string message])

def developmentBypassFunction : Function where
  isAsync := false
  name := "developmentAuthBypass"
  parameters := []
  returns := .boolean
  body := [.return (.binary (prop (prop (id "process") "env") "DEV_NO_AUTH") "==="
    (.string "true"))]

def requireAuthIdFunction : Function where
  name := "requireAuthId"
  parameters := [{ name := "ctx", type := .named "AuthContext" }]
  returns := .promise (.union [.string, .named "null"])
  body := [
    .constDecl "identity" (.await (method (prop (id "ctx") "auth") "getUserIdentity")),
    .ifThen (id "identity") [.return (prop (id "identity") "tokenIdentifier")],
    .ifThen (call (id "developmentAuthBypass")) [.return .null],
    error "Sign in to continue."
  ]

def requirePlayerOwnerFunction : Function where
  name := "requirePlayerOwner"
  parameters := [
    { name := "ctx", type := .named "AuthContext" },
    { name := "playerId", type := .id "players" }
  ]
  returns := .promise (.object [
    ("authId", .union [.string, .named "null"]), ("player", .named "Doc<'players'>")
  ])
  body := [
    .constDecl "authId" (.await (call (id "requireAuthId") [id "ctx"])),
    .constDecl "player" (.await (method (prop (id "ctx") "db") "get" [id "playerId"])),
    .ifThen (.prefix "!" (id "player")) [error "That hero does not exist."],
    .ifThen (.binary
      (.prefix "!" (call (id "developmentAuthBypass"))) "&&"
      (.binary (prop (id "player") "authId") "!==" (id "authId"))) [
      error "That hero belongs to another account."
    ],
    .return (.object [("authId", id "authId"), ("player", id "player")])
  ]

private def authorizeBody (spec : EventSpec) : List Statement := match spec.authority with
  | .account => [.return (id "authId")]
  | .roomHost => [
      .constDecl "room" (.await (method (prop (id "ctx") "db") "get"
        [prop (prop (id "event") "subjects") "roomId"])),
      .ifThen (.binary (.prefix "!" (id "room")) "||"
        (.binary (prop (id "room") "hostAuthId") "!==" (id "authId"))) [
        error "Only the host can start."
      ],
      .return (id "authId")
    ]
  | .playerOwner => [
      .expression (.await (call (id "requirePlayerOwner")
        [id "ctx", prop (prop (id "event") "subjects") "playerId"])),
      .return (id "authId")
    ]

def authorizeEventFunction : Function where
  name := "authorizeGameEvent"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "event", type := .named "GameEvent" }
  ]
  returns := .promise (.union [.string, .named "null"])
  body := [
    .constDecl "authId" (.await (call (id "requireAuthId") [id "ctx"])),
    .ifThen (call (id "developmentAuthBypass")) [.return (id "authId")],
    .switch (prop (id "event") "type") (specs.map fun spec =>
      (spec.type, authorizeBody spec)),
    error "This command has no authenticated actor."
  ]

def emitAuthorization : String :=
  emitFunction developmentBypassFunction ++ "\n" ++ emitFunction requireAuthIdFunction ++
  "\n" ++ emitFunction requirePlayerOwnerFunction ++ "\n" ++ emitFunction authorizeEventFunction

end Mythroads.Backend.Authorization
