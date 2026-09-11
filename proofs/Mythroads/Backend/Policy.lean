import Mythroads.Convex.Module
import Mythroads.Engine.Event

namespace Mythroads.Backend.Policy

open Mythroads.Convex
open Mythroads.Convex.TypeScript
open Mythroads.Engine

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name

def persistentFunction : Function where
  isAsync := false
  name := "isPersistentGameEvent"
  parameters := [{ name := "event", type := .named "GameEvent" }]
  returns := .boolean
  body := [
    .switch (prop (id "event") "type") (Event.alphabet.map fun event =>
      (event.name, [.return (.boolean event.durable)])),
    .return (.boolean false)
  ]

def roomIdFunction : Function where
  isAsync := false
  name := "eventRoomId"
  parameters := [{ name := "event", type := .named "GameEvent" }]
  returns := .union [.id .rooms, .named "undefined"]
  body := [
    .return (.conditional
      (.binary (.string "roomId") "in" (prop (id "event") "subjects"))
      (prop (prop (id "event") "subjects") "roomId") .undefined)
  ]

/-- Which events are durable, and which room each one belongs to. -/
def module : Module where
  provenance := some "proofs/Mythroads/Engine/Event.lean"
  imports := [
    { source := "../_generated/dataModel", bindings := [{ name := "Id", isType := true }] },
    { source := "./validators", bindings := [{ name := "GameEvent", isType := true }] }
  ]
  items := [
    .raw "export const GAME_EVENT_SCHEMA_VERSION = 1 as const\n",
    .function persistentFunction,
    .function roomIdFunction
  ]

end Mythroads.Backend.Policy
