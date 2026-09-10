import Mythroads.Backend.Room.Lobby
import Mythroads.Convex.Module
import Mythroads.Convex.Query

namespace Mythroads.Backend.Room.Movement

open Mythroads.Convex
open Mythroads.Convex.TypeScript

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments
private def reject (message : String) : Statement :=
  .throw (.new "ConvexError" [.string message])

private def roomPlayerType (destination := false) : TsType := .obj
  ([("roomId", .id .rooms), ("playerId", .id .players)] ++
    if destination then [("destination", .number)] else [])

private def selectionByRoom (roomId : Expr) : Expr :=
  Query.indexedRead .roomSelections .roomSelectionsByRoomId [roomId] .first

def clearSelectionFunction : Function where
  isExported := false
  name := "clearSelection"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "roomId", type := .id .rooms }
  ]
  returns := .promise .void
  body := [
    .constDecl "selection" (selectionByRoom (id "roomId")),
    .ifThen (id "selection") [
      .expression (.await (method (prop (id "ctx") "db") "delete"
        [prop (id "selection") "_id"]))
    ]
  ]

def rollMovementFunction : Function where
  name := "rollMovement"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "subjects", type := roomPlayerType }
  ]
  returns := .promise .void
  body := [
    .constDecl "roomId" (prop (id "subjects") "roomId"),
    .constDecl "playerId" (prop (id "subjects") "playerId"),
    .constDecl "room" (.await (method (prop (id "ctx") "db") "get" [id "roomId"])),
    .constDecl "player" (.await (method (prop (id "ctx") "db") "get" [id "playerId"])),
    .ifThen (.binary
      (.binary
        (.binary
          (.binary (.prefix "!" (id "room")) "||" (.prefix "!" (id "player"))) "||"
          (.binary (prop (id "room") "activePlayerId") "!==" (id "playerId"))) "||"
        (.binary (prop (id "room") "remainingMoves") "!==" (.number 0))) "||"
      (.binary (call (id "roomPhase") [id "room"]) "!==" (.string "awaitingRoll"))) [
      reject "You cannot roll now."
    ],
    .letDecl "rngState" (.binary (prop (id "room") "rngState") "??"
      (call (id "normalizeSeed") [prop (id "room") "_creationTime"])),
    .constDeclTyped "results" (.array .number) (.array []),
    .forOf "sides" (prop (id "player") "dice") [
      .constDecl "draw" (call (id "drawBounded") [id "rngState", id "sides"]),
      .assign (id "rngState") (prop (id "draw") "state"),
      .expression (method (id "results") "push" [
        .binary (prop (id "draw") "value") "+" (.number 1)
      ])
    ],
    .constDecl "total" (method (id "results") "reduce" [
      .arrow ["sum", "value"] (.binary (id "sum") "+" (id "value")), .number 0
    ]),
    .expression (.await (call (id "clearSelection") [id "ctx", id "roomId"])),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      id "playerId", .object [("previousPosition", .undefined)]
    ])),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      id "roomId", .object [
        ("lastRoll", id "results"), ("remainingMoves", id "total"),
        ("phase", .string "moving"), ("rngState", id "rngState"),
        ("rngCounter", .binary
          (.binary (prop (id "room") "rngCounter") "??" (.number 0)) "+"
          (prop (id "results") "length")),
        ("message", .binary
          (.binary
            (.binary (prop (id "player") "name") "+" (.string " rolled ")) "+" (id "total")) "+"
          (.string ". Press Y to choose a destination."))
      ]
    ]))
  ]

def selectDestinationFunction : Function where
  name := "selectDestination"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "args", type := roomPlayerType true }
  ]
  returns := .promise .void
  body := [
    .constDecl "roomId" (prop (id "args") "roomId"),
    .constDecl "playerId" (prop (id "args") "playerId"),
    .constDecl "destination" (prop (id "args") "destination"),
    .constDecl "room" (.await (method (prop (id "ctx") "db") "get" [id "roomId"])),
    .constDecl "player" (.await (method (prop (id "ctx") "db") "get" [id "playerId"])),
    .ifThen (.binary
      (.binary
        (.binary (.prefix "!" (id "room")) "||" (.prefix "!" (id "player"))) "||"
        (.binary (prop (id "room") "activePlayerId") "!==" (id "playerId"))) "||"
      (.binary (call (id "roomPhase") [id "room"]) "!==" (.string "moving"))) [
      reject "That destination cannot be selected."
    ],
    .constDecl "current" (selectionByRoom (id "roomId")),
    .constDecl "currentPath" (.conditional (id "current")
      (.binary (prop (id "current") "path") "??" (.array [])) (.array [])),
    .ifThen (.binary (.prefix "!" (id "current")) "&&"
      (.binary (id "destination") "!==" (prop (id "player") "position"))) [
      reject "Start route planning from the hero."
    ],
    .constDecl "path" (.conditional (id "current")
      (call (id "previewRouteStep") [
        prop (id "player") "position", id "currentPath", id "destination",
        prop (id "room") "remainingMoves"
      ]) (.array [])),
    .ifThen (.prefix "!" (id "path")) [reject "That road cannot be used from here."],
    .constDecl "previewDestination" (.binary
      (method (id "path") "at" [.prefix "-" (.number 1)]) "??"
      (prop (id "player") "position")),
    .constDecl "remaining" (.binary (prop (id "room") "remainingMoves") "-"
      (prop (id "path") "length")),
    .constDecl "value" (.object [
      ("roomId", id "roomId"), ("playerId", id "playerId"),
      ("destination", id "previewDestination"), ("path", id "path"),
      ("updatedAt", call (prop (id "Date") "now"))
    ]),
    .ifElse (id "current") [
      .expression (.await (method (prop (id "ctx") "db") "replace" [
        prop (id "current") "_id", id "value"
      ]))
    ] [
      .expression (Query.insert .roomSelections (id "value"))
    ],
    .constDecl "nodeLabel" (prop (call (id "getNode") [id "previewDestination"]) "label"),
    .constDecl "message" (.conditional (id "remaining")
      (.binary
        (.binary
          (.binary (.string "Planning through ") "+" (id "nodeLabel")) "+" (.string ". ")) "+"
        (.binary (id "remaining") "+" (.string " movement left.")))
      (.binary (.binary (.string "Route ends at ") "+" (id "nodeLabel")) "+"
        (.string ". Press A to travel."))),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      id "roomId", .object [("message", id "message")]
    ]))
  ]

def cancelDestinationFunction : Function where
  name := "cancelDestination"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "subjects", type := roomPlayerType }
  ]
  returns := .promise .void
  body := [
    .constDecl "roomId" (prop (id "subjects") "roomId"),
    .constDecl "playerId" (prop (id "subjects") "playerId"),
    .constDecl "room" (.await (method (prop (id "ctx") "db") "get" [id "roomId"])),
    .ifThen (.binary
      (.binary (.prefix "!" (id "room")) "||"
        (.binary (prop (id "room") "activePlayerId") "!==" (id "playerId"))) "||"
      (.binary (call (id "roomPhase") [id "room"]) "!==" (.string "moving"))) [
      reject "There is no movement selection to cancel."
    ],
    .expression (.await (call (id "clearSelection") [id "ctx", id "roomId"])),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      id "roomId", .object [("message", .string "Press Y to choose a destination.")]
    ]))
  ]

def movePlayerFunction : Function where
  name := "movePlayer"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "args", type := roomPlayerType true }
  ]
  returns := .promise .void
  body := [
    .constDecl "roomId" (prop (id "args") "roomId"),
    .constDecl "playerId" (prop (id "args") "playerId"),
    .constDecl "destination" (prop (id "args") "destination"),
    .constDecl "room" (.await (method (prop (id "ctx") "db") "get" [id "roomId"])),
    .constDecl "player" (.await (method (prop (id "ctx") "db") "get" [id "playerId"])),
    .ifThen (.binary
      (.binary
        (.binary
          (.binary (.prefix "!" (id "room")) "||" (.prefix "!" (id "player"))) "||"
          (.binary (prop (id "room") "activePlayerId") "!==" (id "playerId"))) "||"
        (.binary (prop (id "room") "remainingMoves") "<=" (.number 0))) "||"
      (.binary (call (id "roomPhase") [id "room"]) "!==" (.string "moving"))) [
      reject "You cannot move now."
    ],
    .constDecl "selection" (selectionByRoom (id "roomId")),
    .constDecl "path" (.conditional (id "selection")
      (.binary (prop (id "selection") "path") "??" (.array [])) (.array [])),
    .constDecl "validRoute" (method (id "path") "reduce" [
      .arrow ["valid", "step", "index"] (.binary (id "valid") "&&"
        (call (id "canTraverse") [
          .conditional (id "index")
            (.index (id "path") (.binary (id "index") "-" (.number 1)))
            (prop (id "player") "position"),
          id "step"
        ])), .boolean true
    ]),
    .ifThen (.binary
      (.binary
        (.binary (.prefix "!" (id "selection")) "||"
          (.binary (prop (id "selection") "destination") "!==" (id "destination"))) "||"
        (.binary (prop (id "path") "length") "!==" (prop (id "room") "remainingMoves"))) "||"
      (.prefix "!" (id "validRoute"))) [reject "That route is not available."],
    .expression (.await (call (id "clearSelection") [id "ctx", id "roomId"])),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      id "playerId", .object [
        ("previousPosition", .binary (method (id "path") "at" [.prefix "-" (.number 2)]) "??"
          (prop (id "player") "position")),
        ("position", id "destination")
      ]
    ])),
    .expression (.await (call (id "resolveLanding") [
      id "ctx", id "room", id "player", id "destination"
    ]))
  ]

/-- The movement half of `convex/generated/room.generated.ts`. -/
def items : List Item := [
  .function clearSelectionFunction,
  .function rollMovementFunction,
  .function selectDestinationFunction,
  .function cancelDestinationFunction,
  .function movePlayerFunction
]

/-- The room module is the one generated file assembled from two Lean emitters, so it is declared
here rather than in either half: the lobby transactions followed by the movement transactions. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Room/*.lean"
  imports := [
    { source := "convex/values", bindings := [{ name := "ConvexError" }] },
    { source := "../../shared/board.system", bindings := [
      { name := "canTraverse" }, { name := "getNode" }, { name := "previewRouteStep" }] },
    { source := "../_generated/dataModel", bindings := [{ name := "Id", isType := true }] },
    { source := "../_generated/server", bindings := [{ name := "MutationCtx", isType := true }] },
    { source := "../gameHelpers", bindings := [{ name := "roomPhase" }] },
    { source := "../landings", bindings := [{ name := "resolveLanding" }] },
    { source := "../players", bindings := [{ name := "createPlayer" }] },
    { source := "./random.generated", bindings := [
      { name := "drawBounded" }, { name := "normalizeSeed" }] }
  ]
  items := Lobby.items ++ items

end Mythroads.Backend.Room.Movement
