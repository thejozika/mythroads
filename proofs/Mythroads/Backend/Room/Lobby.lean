import Mythroads.Convex.TypeScript

namespace Mythroads.Backend.Room.Lobby

open Mythroads.Convex.TypeScript

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments
private def reject (message : String) : Statement :=
  .throw (.new "ConvexError" [.string message])

private def uniqueBy (table index field : String) (value : Expr) : Expr :=
  .await (method
    (method
      (method (prop (id "ctx") "db") "query" [.string table])
      "withIndex" [.string index, .arrow ["query"]
        (method (id "query") "eq" [.string field, value])])
    "unique")

private def playersByRoom (roomId : Expr) : Expr :=
  .await (method
    (method
      (method (prop (id "ctx") "db") "query" [.string "players"])
      "withIndex" [.string "by_room", .arrow ["query"]
        (method (id "query") "eq" [.string "roomId", roomId])])
    "take" [.number 4])

def roomCodeFunction : Function where
  isExported := false
  isAsync := false
  name := "roomCode"
  parameters := [{ name := "state", type := .number }]
  returns := .object [("code", .string), ("state", .number)]
  body := [
    .constDecl "alphabet" (.string "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"),
    .letDecl "rngState" (id "state"),
    .letDecl "code" (.string ""),
    .forOf "unused" (.array [.number 0, .number 1, .number 2, .number 3]) [
      .expression (.prefix "void " (id "unused")),
      .constDecl "draw" (call (id "drawBounded") [
        id "rngState", prop (id "alphabet") "length"
      ]),
      .assign (id "rngState") (prop (id "draw") "state"),
      .assign (id "code") (.binary (id "code") "+" (.binary
        (method (id "alphabet") "at" [prop (id "draw") "value"]) "??"
        (.index (id "alphabet") (.number 0))))
    ],
    .return (.object [("code", id "code"), ("state", id "rngState")])
  ]

def createRoomFunction : Function where
  name := "createRoom"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "hostAuthId", type := .union [.string, .named "undefined"] },
    { name := "seed", type := .union [.number, .named "undefined"] }
  ]
  returns := .promise .string
  body := [
    .letDecl "rngState" (call (id "normalizeSeed") [
      .binary (id "seed") "??" (call (prop (id "Date") "now"))
    ]),
    .letDecl "generated" (call (id "roomCode") [id "rngState"]),
    .letDecl "code" (prop (id "generated") "code"),
    .assign (id "rngState") (prop (id "generated") "state"),
    .letDecl "rngCounter" (.number 4),
    .whileDo (uniqueBy "rooms" "by_code" "code" (id "code")) [
      .assign (id "generated") (call (id "roomCode") [id "rngState"]),
      .assign (id "code") (prop (id "generated") "code"),
      .assign (id "rngState") (prop (id "generated") "state"),
      .assign (id "rngCounter") (.binary (id "rngCounter") "+" (.number 4))
    ],
    .expression (.await (method (prop (id "ctx") "db") "insert" [
      .string "rooms", .object [
        ("code", id "code"), ("hostAuthId", id "hostAuthId"),
        ("status", .string "lobby"), ("remainingMoves", .number 0),
        ("message", .string "Scan the code to join the adventure."),
        ("round", .number 1), ("phase", .string "awaitingRoll"),
        ("rngState", id "rngState"), ("rngCounter", id "rngCounter")
      ]
    ])),
    .return (id "code")
  ]

def joinRoomFunction : Function where
  name := "joinRoom"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "code", type := .string },
    { name := "data", type := .object [("name", .string), ("color", .string)] },
    { name := "authId", type := .union [.string, .named "undefined"] }
  ]
  returns := .promise (.id "players")
  body := [
    .constDecl "normalizedName" (method
      (method (prop (id "data") "name") "trim") "slice" [.number 0, .number 16]),
    .ifThen (.prefix "!" (id "normalizedName")) [reject "Choose a hero name."],
    .constDecl "room" (uniqueBy "rooms" "by_code" "code"
      (method (id "code") "toUpperCase")),
    .ifThen (.prefix "!" (id "room")) [reject "That room does not exist."],
    .constDecl "players" (playersByRoom (prop (id "room") "_id")),
    .constDecl "ownedPlayer" (.conditional (id "authId")
      (method (id "players") "find" [.arrow ["player"]
        (.binary (prop (id "player") "authId") "===" (id "authId"))]) .undefined),
    .ifThen (id "ownedPlayer") [.return (prop (id "ownedPlayer") "_id")],
    .constDecl "namedPlayer" (method (id "players") "find" [.arrow ["player"]
      (.binary (method (prop (id "player") "name") "toLocaleLowerCase") "==="
        (method (id "normalizedName") "toLocaleLowerCase"))]),
    .ifThen (id "namedPlayer") [
      .ifThen (.binary (prop (id "namedPlayer") "authId") "&&"
        (.binary (prop (id "namedPlayer") "authId") "!==" (id "authId"))) [
        reject "That hero name belongs to another account."
      ],
      .ifThen (.binary
        (method (prop (id "namedPlayer") "color") "toLocaleLowerCase") "!=="
        (method (prop (id "data") "color") "toLocaleLowerCase")) [
        reject "That hero exists. Select their original color to rejoin."
      ],
      .ifThen (.binary (id "authId") "&&" (.prefix "!" (prop (id "namedPlayer") "authId"))) [
        .expression (.await (method (prop (id "ctx") "db") "patch" [
          prop (id "namedPlayer") "_id", .object [("authId", id "authId")]
        ]))
      ],
      .return (prop (id "namedPlayer") "_id")
    ],
    .ifThen (.binary (prop (id "room") "status") "!==" (.string "lobby")) [
      reject "That adventure has started. Rejoin with your existing name and color."
    ],
    .ifThen (.binary (prop (id "players") "length") ">=" (.number 4)) [
      reject "That room is full."
    ],
    .return (.await (call (id "createPlayer") [
      id "ctx", prop (id "room") "_id", .object [
        ("name", id "normalizedName"), ("color", prop (id "data") "color")
      ], id "authId"
    ]))
  ]

def startRoomFunction : Function where
  name := "startRoom"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "roomId", type := .id "rooms" }
  ]
  returns := .promise (.union [.void, .named "null"])
  body := [
    .constDecl "room" (.await (method (prop (id "ctx") "db") "get" [id "roomId"])),
    .ifThen (.binary (.prefix "!" (id "room")) "||"
      (.binary (prop (id "room") "status") "!==" (.string "lobby"))) [.return .null],
    .constDecl "players" (playersByRoom (id "roomId")),
    .ifThen (.prefix "!" (prop (id "players") "length")) [
      reject "At least one hero must join."
    ],
    .constDecl "ordered" (method (id "players") "sort" [.arrow ["a", "b"]
      (.binary (prop (id "a") "joinedAt") "-" (prop (id "b") "joinedAt"))]),
    .constDecl "first" (.index (id "ordered") (.number 0)),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      id "roomId", .object [
        ("status", .string "playing"), ("activePlayerId", prop (id "first") "_id"),
        ("phase", .string "awaitingRoll"),
        ("message", .binary (prop (id "first") "name") "+" (.string ", roll your movement dice."))
      ]
    ]))
  ]

def emitLobby : String :=
  emitFunction roomCodeFunction ++ "\n" ++ emitFunction createRoomFunction ++ "\n" ++
  emitFunction joinRoomFunction ++ "\n" ++ emitFunction startRoomFunction

end Mythroads.Backend.Room.Lobby
