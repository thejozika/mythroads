import Mythroads.Convex.Module

namespace Mythroads.Backend.Authority

open Mythroads.Convex
open Mythroads.Convex.TypeScript

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name

def authorityType : TsType := .obj [
  ("mode", .union [.literalString "authenticated", .literalString "developmentBypass"]),
  ("actorPlayerId", .union [.id .players, .named "undefined"]),
  ("actorAuthId", .union [.string, .named "undefined"])
]

def resolveAuthorityFunction : Function where
  isAsync := false
  name := "resolveEventAuthority"
  parameters := [
    { name := "event", type := .named "GameEvent" },
    { name := "result", type := .named "DispatchResult" },
    { name := "actorAuthId", type := .union [.string, .named "null"] }
  ]
  returns := .named "EventAuthority"
  body := [
    .constDecl "actorPlayerId" (.conditional
      (.binary (.string "playerId") "in" (prop (id "event") "subjects"))
      (prop (prop (id "event") "subjects") "playerId")
      (.conditional
        (.binary (prop (id "result") "kind") "===" (.string "player.joined"))
        (prop (id "result") "playerId") .undefined)),
    .return (.object [
      ("mode", .conditional (id "actorAuthId")
        (.string "authenticated") (.string "developmentBypass")),
      ("actorPlayerId", id "actorPlayerId"),
      ("actorAuthId", .binary (id "actorAuthId") "??" .undefined)
    ])
  ]

/-- The runtime projection of an event onto the authority recorded with it. -/
def module : Module where
  provenance := some "proofs/Mythroads/Game/Events.lean"
  imports := [
    { source := "../_generated/dataModel", bindings := [{ name := "Id", isType := true }] },
    { source := "./validators", bindings := [{ name := "DispatchResult", isType := true }, { name := "GameEvent", isType := true }] }
  ]
  items := [
    .typeAlias "EventAuthority" authorityType,
    .function resolveAuthorityFunction
  ]

end Mythroads.Backend.Authority
