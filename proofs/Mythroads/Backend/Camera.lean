import Mythroads.Convex.TypeScript

namespace Mythroads.Backend.Camera

open Mythroads.Convex.TypeScript

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments
private def reject (message : String) : Statement :=
  .throw (.new "ConvexError" [.string message])

private def subjectsType : TsType := .object [
  ("roomId", .id "rooms"), ("playerId", .id "players")
]
private def delta : Expr := .binary (.number 9) "/" (.number 10)

private def cameraQuery : Expr :=
  .await (method
    (method
      (method (prop (id "ctx") "db") "query" [.string "roomCameras"])
      "withIndex" [.string "by_roomId", .arrow ["query"]
        (method (id "query") "eq" [.string "roomId", id "roomId"])])
    "unique")

def cameraForRoomFunction : Function where
  isExported := false
  name := "cameraForRoom"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "roomId", type := .id "rooms" }
  ]
  returns := .promise (.union [.named "Doc<'roomCameras'>", .named "null"])
  body := [.return cameraQuery]

def requireCameraFunction : Function where
  isExported := false
  name := "requireCameraControl"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "subjects", type := subjectsType }
  ]
  returns := .promise (.object [
    ("room", .named "Doc<'rooms'>"), ("player", .named "Doc<'players'>"),
    ("camera", .union [.named "Doc<'roomCameras'>", .named "null"])
  ])
  body := [
    .constDecl "room" (.await (method (prop (id "ctx") "db") "get"
      [prop (id "subjects") "roomId"])),
    .constDecl "player" (.await (method (prop (id "ctx") "db") "get"
      [prop (id "subjects") "playerId"])),
    .ifThen (.binary
      (.binary
        (.binary (.prefix "!" (id "room")) "||" (.prefix "!" (id "player"))) "||"
        (.binary (prop (id "player") "roomId") "!==" (prop (id "room") "_id"))) "||"
      (.binary (prop (id "room") "activePlayerId") "!==" (prop (id "player") "_id"))) [
      reject "Only the active player can control the camera."
    ],
    .constDecl "camera" (.await (call (id "cameraForRoom")
      [id "ctx", prop (id "room") "_id"])),
    .return (.object [("room", id "room"), ("player", id "player"), ("camera", id "camera")])
  ]

def toggleCameraFunction : Function where
  name := "toggleCamera"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "subjects", type := subjectsType }
  ]
  returns := .promise .void
  body := [
    .constDecl "control" (.await (call (id "requireCameraControl") [id "ctx", id "subjects"])),
    .constDecl "node" (call (id "getNode") [prop (prop (id "control") "player") "position"]),
    .ifThen (prop (id "control") "camera") [
      .expression (.await (method (prop (id "ctx") "db") "patch" [
        prop (prop (id "control") "camera") "_id", .object [
          ("mode", .conditional
            (.binary (prop (prop (id "control") "camera") "mode") "===" (.string "free"))
            (.string "follow") (.string "free")),
          ("targetX", prop (id "node") "x"), ("targetZ", prop (id "node") "z"),
          ("updatedAt", call (prop (id "Date") "now"))
        ]
      ])), .returnVoid
    ],
    .expression (.await (method (prop (id "ctx") "db") "insert" [
      .string "roomCameras", .object [
        ("roomId", prop (prop (id "control") "room") "_id"), ("mode", .string "free"),
        ("targetX", prop (id "node") "x"), ("targetZ", prop (id "node") "z"),
        ("distance", .number 8), ("updatedAt", call (prop (id "Date") "now"))
      ]
    ]))
  ]

private def directionDelta (negative positive : String) : Expr :=
  .conditional (.binary (id "direction") "===" (.string negative)) (.prefix "-" delta)
    (.conditional (.binary (id "direction") "===" (.string positive)) delta (.number 0))

def moveCameraFunction : Function where
  name := "moveCamera"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "subjects", type := subjectsType },
    { name := "direction", type := .union [
        .literalString "up", .literalString "down", .literalString "left", .literalString "right"
      ] }
  ]
  returns := .promise .void
  body := [
    .constDecl "control" (.await (call (id "requireCameraControl") [id "ctx", id "subjects"])),
    .constDecl "camera" (prop (id "control") "camera"),
    .ifThen (.binary (.prefix "!" (id "camera")) "||"
      (.binary (prop (id "camera") "mode") "!==" (.string "free"))) [
      reject "Free camera is not active."
    ],
    .constDecl "targetX" (.binary (prop (id "camera") "targetX") "+"
      (directionDelta "left" "right")),
    .constDecl "targetZ" (.binary (prop (id "camera") "targetZ") "+"
      (directionDelta "up" "down")),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      prop (id "camera") "_id", .object [
        ("targetX", call (prop (id "Math") "max") [.prefix "-" (.number 7),
          call (prop (id "Math") "min") [.number 7, id "targetX"]]),
        ("targetZ", call (prop (id "Math") "max") [.prefix "-" (.binary (.number 55) "/" (.number 10)),
          call (prop (id "Math") "min") [.binary (.number 55) "/" (.number 10), id "targetZ"]]),
        ("updatedAt", call (prop (id "Date") "now"))
      ]
    ]))
  ]

def zoomCameraFunction : Function where
  name := "zoomCamera"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "subjects", type := subjectsType },
    { name := "delta", type := .union [.named "-1", .named "1"] }
  ]
  returns := .promise .void
  body := [
    .constDecl "control" (.await (call (id "requireCameraControl") [id "ctx", id "subjects"])),
    .constDecl "camera" (prop (id "control") "camera"),
    .ifThen (.binary (.prefix "!" (id "camera")) "||"
      (.binary (prop (id "camera") "mode") "!==" (.string "free"))) [
      reject "Free camera is not active."
    ],
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      prop (id "camera") "_id", .object [
        ("distance", call (prop (id "Math") "max") [.number 5,
          call (prop (id "Math") "min") [.number 15,
            .binary (prop (id "camera") "distance") "+" (id "delta")]]),
        ("updatedAt", call (prop (id "Date") "now"))
      ]
    ]))
  ]

def emitCamera : String :=
  emitFunction cameraForRoomFunction ++ "\n" ++ emitFunction requireCameraFunction ++ "\n" ++
  emitFunction toggleCameraFunction ++ "\n" ++ emitFunction moveCameraFunction ++ "\n" ++
  emitFunction zoomCameraFunction

end Mythroads.Backend.Camera
