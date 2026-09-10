import Mythroads.Convex.TypeScript

namespace Mythroads.Backend.Landing

open Mythroads.Convex.TypeScript

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments
private def concat (left right : Expr) : Expr := .binary left "+" right

def resolveLandingFunction : Function where
  name := "resolveLanding"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "room", type := .named "Doc<'rooms'>" },
    { name := "player", type := .named "Doc<'players'>" },
    { name := "destination", type := .number }
  ]
  returns := .promise .void
  body := [
    .constDecl "landed" (call (id "getNode") [id "destination"]),
    .ifThen (call (id "isShopKind") [prop (id "landed") "kind"]) [
      .expression (.await (method (prop (id "ctx") "db") "patch" [
        prop (id "room") "_id", .object [
          ("remainingMoves", .number 0), ("phase", .string "shopping"),
          ("shopKind", prop (id "landed") "kind"),
          ("message", concat
            (concat (prop (id "player") "name") (.string " entered the "))
            (concat (prop (id "landed") "label") (.string ".")))
        ]
      ])), .returnVoid
    ],
    .ifThen (.binary (prop (id "landed") "kind") "===" (.string "combat")) [
      .expression (.await (call (id "startCombat")
        [id "ctx", id "room", id "player", id "destination"])), .returnVoid
    ],
    .ifThen (.binary (prop (id "landed") "kind") "===" (.string "event")) [
      .expression (.await (call (id "startEvent") [
        id "ctx", prop (id "room") "_id", id "player", id "destination"
      ])), .returnVoid
    ],
    .ifThen (.binary (prop (id "landed") "kind") "===" (.string "castle")) [
      .expression (.await (method (prop (id "ctx") "db") "patch" [
        prop (id "player") "_id", .object [("hp", prop (id "player") "maxHp")]
      ])),
      .expression (.await (call (id "advanceTurn") [
        id "ctx", id "room", prop (id "player") "_id",
        concat (prop (id "player") "name")
          (.string " rested at Hearthkeep and recovered all health.")
      ])), .returnVoid
    ],
    .expression (.await (call (id "advanceTurn") [
      id "ctx", id "room", prop (id "player") "_id",
      concat (prop (id "player") "name") (.string " completed the journey.")
    ]))
  ]

def startEventFunction : Function where
  isExported := false
  name := "startEvent"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "roomId", type := .id "rooms" },
    { name := "player", type := .named "Doc<'players'>" },
    { name := "destination", type := .number }
  ]
  returns := .promise .void
  body := [
    .constDecl "roll" (.await (call (id "drawRoomRandom") [
      id "ctx", id "roomId", call (id "encounterWeight") [.string "event"]
    ])),
    .constDecl "outcome" (call (id "pickEncounter") [.string "event", id "roll"]),
    .constDecl "wheelIndex" (method (call (id "outcomesFor") [.string "event"]) "findIndex" [
      .arrow ["candidate"] (.binary (prop (id "candidate") "id") "===" (prop (id "outcome") "id"))
    ]),
    .constDecl "encounterId" (.await (method (prop (id "ctx") "db") "insert" [
      .string "encounters", .object [
        ("roomId", id "roomId"), ("playerId", prop (id "player") "_id"),
        ("spaceId", id "destination"), ("kind", .string "event"),
        ("outcomeId", prop (id "outcome") "id"), ("title", prop (id "outcome") "title"),
        ("description", prop (id "outcome") "description"),
        ("goldDelta", prop (id "outcome") "goldDelta"),
        ("hpDelta", prop (id "outcome") "hpDelta"), ("wheelIndex", id "wheelIndex"),
        ("status", .string "revealing"), ("createdAt", call (prop (id "Date") "now"))
      ]
    ])),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      id "roomId", .object [
        ("remainingMoves", .number 0), ("phase", .string "revealingEncounter"),
        ("activeEncounterId", id "encounterId"),
        ("message", concat (prop (id "player") "name") (.string " spins the event wheel!"))
      ]
    ]))
  ]

def emitLanding : String :=
  emitFunction resolveLandingFunction ++ "\n" ++ emitFunction startEventFunction

end Mythroads.Backend.Landing
