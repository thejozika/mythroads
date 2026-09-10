import Mythroads.Convex.Module
import Mythroads.Convex.Query
import Mythroads.Convex.Ty

namespace Mythroads.Backend.Room.Queries

open Mythroads.Convex
open Mythroads.Convex.TypeScript

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments
private def vcall (name : String) (arguments : List Expr := []) : Expr :=
  call (prop (id "v") name) arguments

/-- Every read in this module goes through an index, with the lambda binder spelled `lookup`. -/
private def byIndex (table : Table) (index : Index table) (value : Expr)
    (terminal : Query.Terminal) : Expr :=
  Query.indexedRead table index [value] terminal "lookup"

def roomViewFunction : Function where
  isExported := false
  isAsync := false
  name := "roomView"
  parameters := [{ name := "room", type := .doc .rooms }]
  returns := .named "Omit<Doc<'rooms'>, 'hostAuthId' | 'rngState' | 'rngCounter'>"
  body := [
    .constObjectRest ["hostAuthId", "rngCounter", "rngState"] "view" (id "room"),
    .voidValue (id "hostAuthId"),
    .voidValue (id "rngCounter"),
    .voidValue (id "rngState"),
    .return (id "view")
  ]

def playerViewFunction : Function where
  isExported := false
  isAsync := false
  name := "playerView"
  parameters := [{ name := "player", type := .doc .players }]
  returns := .named "Omit<Doc<'players'>, 'authId'>"
  body := [
    .constObjectRest ["authId"] "view" (id "player"),
    .voidValue (id "authId"),
    .return (id "view")
  ]

def publicPlayerFunction : Function where
  isExported := false
  isAsync := false
  name := "publicPlayer"
  parameters := [{ name := "player", type := .doc .players }]
  returns := .named "PublicPlayer"
  body := [.return (.object [
    ("_id", prop (id "player") "_id"), ("name", prop (id "player") "name"),
    ("color", prop (id "player") "color"), ("position", prop (id "player") "position"),
    ("previousPosition", prop (id "player") "previousPosition"),
    ("joinedAt", prop (id "player") "joinedAt")
  ])]

def activeStateFunction : Function where
  isExported := false
  name := "activeState"
  parameters := [
    { name := "ctx", type := .named "QueryCtx" },
    { name := "room", type := .doc .rooms }
  ]
  returns := .promise (.named "ActiveState")
  body := [
    .constDecl "encounter" (.conditional (prop (id "room") "activeEncounterId")
      (.await (method (prop (id "ctx") "db") "get" [prop (id "room") "activeEncounterId"])) .null),
    .constDecl "combat" (.conditional (prop (id "room") "activeCombatId")
      (.await (method (prop (id "ctx") "db") "get" [prop (id "room") "activeCombatId"])) .null),
    .constDecl "selection" ((byIndex .roomSelections .roomSelectionsByRoomId
      (prop (id "room") "_id") .first)),
    .constDecl "camera" ((byIndex .roomCameras .roomCamerasByRoomId
      (prop (id "room") "_id") .unique)),
    .return (.object [
      ("encounter", id "encounter"), ("combat", id "combat"),
      ("selection", id "selection"), ("camera", id "camera")
    ])
  ]

private def findRoom : Expr := (byIndex .rooms .roomsByCode
  (method (id "code") "toUpperCase") .unique)

private def activeFields : List (String × Expr) := [
  ("encounter", prop (id "active") "encounter"),
  ("combat", prop (id "active") "combat"),
  ("selection", prop (id "active") "selection"),
  ("camera", prop (id "active") "camera")
]

private def activeValidatorFields : List (String × Expr) := [
  ("encounter", vcall "union" [vcall "null", (Ty.document .encounters).validator]),
  ("combat", vcall "union" [vcall "null", (Ty.document .combats).validator]),
  ("selection", vcall "union" [vcall "null", (Ty.document .roomSelections).validator]),
  ("camera", vcall "union" [vcall "null", (Ty.document .roomCameras).validator])
]

def displayDefinition : EndpointDefinition where
  name := "displayByCodeDefinition"
  arguments := [("code", vcall "string")]
  returns := vcall "union" [vcall "null", vcall "object" [.object (
    [("room", id "roomViewValidator"),
     ("players", vcall "array" [id "publicPlayerValidator"]),
     ("canStart", vcall "boolean")] ++ activeValidatorFields)]]
  handler := {
    parameters := [
      { name := "ctx", type := .named "QueryCtx" },
      { name := "{ code }", type := .obj [("code", .string)] }
    ]
    body := [
      .constDecl "room" findRoom,
      .ifThen (.prefix "!" (id "room")) [.return .null],
      .constDecl "players" ((byIndex .players .playersByRoom
        (prop (id "room") "_id") (.take 4))),
      .constDecl "identity" (.await (method (prop (id "ctx") "auth") "getUserIdentity")),
      .constDecl "active" (.await (call (id "activeState") [id "ctx", id "room"])),
      .return (.object ([
        ("room", call (id "roomView") [id "room"]),
        ("players", method
          (method (id "players") "sort" [.arrow ["a", "b"]
            (.binary (prop (id "a") "joinedAt") "-" (prop (id "b") "joinedAt"))])
          "map" [id "publicPlayer"]),
        ("canStart", .binary (call (id "developmentAuthBypass")) "||"
          (call (id "Boolean") [.binary (id "identity") "&&"
            (.binary (prop (id "room") "hostAuthId") "==="
              (prop (id "identity") "tokenIdentifier"))]))
      ] ++ activeFields))
    ]
  }

def controllerDefinition : EndpointDefinition where
  name := "controllerByCodeDefinition"
  arguments := [("code", vcall "string"), ("playerId", (Ty.id .players).validator)]
  returns := vcall "union" [vcall "null", vcall "object" [.object (
    [("room", id "roomViewValidator"),
     ("players", vcall "array" [id "playerViewValidator"])] ++ activeValidatorFields)]]
  handler := {
    parameters := [
      { name := "ctx", type := .named "QueryCtx" },
      { name := "{ code, playerId }", type := .obj [("code", .string), ("playerId", .id .players)] }
    ]
    body := [
      .constDecl "room" findRoom,
      .ifThen (.prefix "!" (id "room")) [.return .null],
      .constDecl "ownership" (.await (call (id "requirePlayerOwner") [id "ctx", id "playerId"])),
      .constDecl "player" (prop (id "ownership") "player"),
      .ifThen (.binary (prop (id "player") "roomId") "!==" (prop (id "room") "_id")) [.return .null],
      .constDecl "active" (.await (call (id "activeState") [id "ctx", id "room"])),
      .return (.object ([
        ("room", call (id "roomView") [id "room"]),
        ("players", .array [call (id "playerView") [id "player"]])
      ] ++ activeFields))
    ]
  }

def myPlayerDefinition : EndpointDefinition where
  name := "myPlayerByCodeDefinition"
  arguments := [("code", vcall "string")]
  returns := vcall "union" [vcall "null", (Ty.id .players).validator]
  handler := {
    parameters := [
      { name := "ctx", type := .named "QueryCtx" },
      { name := "{ code }", type := .obj [("code", .string)] }
    ]
    body := [
      .constDecl "authId" (.await (call (id "requireAuthId") [id "ctx"])),
      .ifThen (.prefix "!" (id "authId")) [.return .null],
      .constDecl "room" findRoom,
      .ifThen (.prefix "!" (id "room")) [.return .null],
      .constDecl "player" (Query.indexedRead .players .playersByRoomAndAuthId
        [prop (id "room") "_id", id "authId"] .unique "lookup"),
      .return (.binary (.optionalProperty (id "player") "_id") "??" .null)
    ]
  }

/-- The read-side projections and the three public room queries. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Room/Queries.lean"
  imports := [
    { source := "convex/values", bindings := [{ name := "v" }] },
    { source := "../_generated/dataModel", bindings := [{ name := "Doc", isType := true }, { name := "Id", isType := true }] },
    { source := "../_generated/server", bindings := [{ name := "QueryCtx", isType := true }] },
    { source := "../auth/authorization", bindings := [{ name := "developmentAuthBypass" }, { name := "requireAuthId" }, { name := "requirePlayerOwner" }] },
    { source := "../schema", «default» := "schema" }
  ]
  items := [
    .raw ("type PublicPlayer = { _id: Id<'players'>; name: string; color: string; position: number; previousPosition?: number; joinedAt: number }\n" ++
      "type ActiveState = { encounter: Doc<'encounters'> | null; combat: Doc<'combats'> | null; selection: Doc<'roomSelections'> | null; camera: Doc<'roomCameras'> | null }\n"),
    .raw ("const roomViewValidator = schema.doc('rooms').omit('hostAuthId', 'rngState', 'rngCounter')\n" ++
      "const playerViewValidator = schema.doc('players').omit('authId')\n" ++
      "const publicPlayerValidator = v.object({ _id: v.id('players'), name: v.string(), color: v.string(), position: v.number(), previousPosition: v.optional(v.number()), joinedAt: v.number() })\n"),
    .function roomViewFunction,
    .function playerViewFunction,
    .function publicPlayerFunction,
    .function activeStateFunction,
    .endpoint displayDefinition,
    .endpoint controllerDefinition,
    .endpoint myPlayerDefinition
  ]

end Mythroads.Backend.Room.Queries
