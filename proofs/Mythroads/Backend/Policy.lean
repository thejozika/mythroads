import Mythroads.Convex.TypeScript
import Mythroads.Game.Events

namespace Mythroads.Backend.Policy

open Mythroads.Convex.TypeScript
open Mythroads.Game.Events

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name

def persistentFunction : Function where
  isAsync := false
  name := "isPersistentGameEvent"
  parameters := [{ name := "event", type := .named "GameEvent" }]
  returns := .boolean
  body := [
    .switch (prop (id "event") "type") (specs.map fun spec =>
      (spec.type, [.return (.boolean spec.persistent)])),
    .return (.boolean false)
  ]

def roomIdFunction : Function where
  isAsync := false
  name := "eventRoomId"
  parameters := [{ name := "event", type := .named "GameEvent" }]
  returns := .union [.id "rooms", .named "undefined"]
  body := [
    .return (.conditional
      (.binary (.string "roomId") "in" (prop (id "event") "subjects"))
      (prop (prop (id "event") "subjects") "roomId") .undefined)
  ]

def emitPolicy : String :=
  "export const GAME_EVENT_SCHEMA_VERSION = 1 as const\n\n" ++
  emitFunction persistentFunction ++ "\n" ++ emitFunction roomIdFunction

end Mythroads.Backend.Policy
