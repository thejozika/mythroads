import Mythroads.Convex.TypeScript

namespace Mythroads.Backend.Room.Queries

open Mythroads.Convex.TypeScript

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments
private def vcall (name : String) (arguments : List Expr := []) : Expr :=
  call (prop (id "v") name) arguments

private def byIndex (table index key : String) (value : Expr) (terminal : String)
    (terminalArguments : List Expr := []) : Expr :=
  method
    (method
      (method (prop (id "ctx") "db") "query" [.string table])
      "withIndex" [.string index, .arrow ["lookup"]
        (method (id "lookup") "eq" [.string key, value])])
    terminal terminalArguments

def roomViewFunction : Function where
  isExported := false
  isAsync := false
  name := "roomView"
  parameters := [{ name := "room", type := .named "Doc<'rooms'>" }]
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
  parameters := [{ name := "player", type := .named "Doc<'players'>" }]
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
  parameters := [{ name := "player", type := .named "Doc<'players'>" }]
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
    { name := "room", type := .named "Doc<'rooms'>" }
  ]
  returns := .promise (.named "ActiveState")
  body := [
    .constDecl "encounter" (.conditional (prop (id "room") "activeEncounterId")
      (.await (method (prop (id "ctx") "db") "get" [prop (id "room") "activeEncounterId"])) .null),
    .constDecl "combat" (.conditional (prop (id "room") "activeCombatId")
      (.await (method (prop (id "ctx") "db") "get" [prop (id "room") "activeCombatId"])) .null),
    .constDecl "selection" (.await (byIndex "roomSelections" "by_roomId" "roomId"
      (prop (id "room") "_id") "first")),
    .constDecl "camera" (.await (byIndex "roomCameras" "by_roomId" "roomId"
      (prop (id "room") "_id") "unique")),
    .return (.object [
      ("encounter", id "encounter"), ("combat", id "combat"),
      ("selection", id "selection"), ("camera", id "camera")
    ])
  ]

private def findRoom : Expr := .await (byIndex "rooms" "by_code" "code"
  (method (id "code") "toUpperCase") "unique")

private def activeFields : List (String × Expr) := [
  ("encounter", prop (id "active") "encounter"),
  ("combat", prop (id "active") "combat"),
  ("selection", prop (id "active") "selection"),
  ("camera", prop (id "active") "camera")
]

private def activeValidatorFields : List (String × Expr) := [
  ("encounter", vcall "union" [vcall "null", call (prop (id "schema") "doc") [.string "encounters"]]),
  ("combat", vcall "union" [vcall "null", call (prop (id "schema") "doc") [.string "combats"]]),
  ("selection", vcall "union" [vcall "null", call (prop (id "schema") "doc") [.string "roomSelections"]]),
  ("camera", vcall "union" [vcall "null", call (prop (id "schema") "doc") [.string "roomCameras"]])
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
      { name := "{ code }", type := .object [("code", .string)] }
    ]
    body := [
      .constDecl "room" findRoom,
      .ifThen (.prefix "!" (id "room")) [.return .null],
      .constDecl "players" (.await (byIndex "players" "by_room" "roomId"
        (prop (id "room") "_id") "take" [.number 4])),
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
  arguments := [("code", vcall "string"), ("playerId", vcall "id" [.string "players"])]
  returns := vcall "union" [vcall "null", vcall "object" [.object (
    [("room", id "roomViewValidator"),
     ("players", vcall "array" [id "playerViewValidator"])] ++ activeValidatorFields)]]
  handler := {
    parameters := [
      { name := "ctx", type := .named "QueryCtx" },
      { name := "{ code, playerId }", type := .object [("code", .string), ("playerId", .id "players")] }
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
  returns := vcall "union" [vcall "null", vcall "id" [.string "players"]]
  handler := {
    parameters := [
      { name := "ctx", type := .named "QueryCtx" },
      { name := "{ code }", type := .object [("code", .string)] }
    ]
    body := [
      .constDecl "authId" (.await (call (id "requireAuthId") [id "ctx"])),
      .ifThen (.prefix "!" (id "authId")) [.return .null],
      .constDecl "room" findRoom,
      .ifThen (.prefix "!" (id "room")) [.return .null],
      .constDecl "player" (.await (method
        (method
          (method (prop (id "ctx") "db") "query" [.string "players"])
          "withIndex" [.string "by_room_and_authId", .arrow ["lookup"]
            (method (method (id "lookup") "eq" [.string "roomId", prop (id "room") "_id"])
              "eq" [.string "authId", id "authId"])])
        "unique")),
      .return (.binary (.optionalProperty (id "player") "_id") "??" .null)
    ]
  }

def emitQueries : String :=
  "type PublicPlayer = { _id: Id<'players'>; name: string; color: string; position: number; previousPosition?: number; joinedAt: number }\n" ++
  "type ActiveState = { encounter: Doc<'encounters'> | null; combat: Doc<'combats'> | null; selection: Doc<'roomSelections'> | null; camera: Doc<'roomCameras'> | null }\n\n" ++
  "const roomViewValidator = schema.doc('rooms').omit('hostAuthId', 'rngState', 'rngCounter')\n" ++
  "const playerViewValidator = schema.doc('players').omit('authId')\n" ++
  "const publicPlayerValidator = v.object({ _id: v.id('players'), name: v.string(), color: v.string(), position: v.number(), previousPosition: v.optional(v.number()), joinedAt: v.number() })\n\n" ++
  emitFunction roomViewFunction ++ "\n" ++ emitFunction playerViewFunction ++ "\n" ++
  emitFunction publicPlayerFunction ++ "\n" ++ emitFunction activeStateFunction ++ "\n" ++
  emitEndpointDefinition displayDefinition ++ "\n" ++
  emitEndpointDefinition controllerDefinition ++ "\n" ++
  emitEndpointDefinition myPlayerDefinition

end Mythroads.Backend.Room.Queries
