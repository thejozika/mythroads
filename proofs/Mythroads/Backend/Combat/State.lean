import Mythroads.Convex.Module

namespace Mythroads.Backend.Combat.State

open Mythroads.Convex
open Mythroads.Convex.TypeScript

def id (name : String) : Expr := .identifier name
def prop (target : Expr) (name : String) : Expr := .property target name
def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments
def maxZero (value : Expr) : Expr := call (prop (id "Math") "max") [.number 0, value]
def coalesce (value : Expr) (fallback : Nat) : Expr := .binary value "??" (.number fallback)
def reject (message : String) : Statement := .throw (.new "ConvexError" [.string message])

private def adjusted (source : Expr) (base penalty : String) : Expr :=
  maxZero (.binary (coalesce (prop source base) 2) "-" (coalesce (prop source penalty) 0))

def playerStatsFunction : Function where
  isAsync := false
  name := "playerStats"
  parameters := [
    { name := "player", type := .doc .players },
    { name := "combat", type := .union [.doc .combats, .named "undefined"] }
  ]
  returns := .named "BattleStats"
  body := [.return (.object [
    ("attack", prop (id "player") "attack"),
    ("defense", maxZero (.binary (coalesce (prop (id "player") "defense") 2) "-"
      (coalesce (.optionalProperty (id "combat") "playerDefensePenalty") 0))),
    ("magic", maxZero (.binary (coalesce (prop (id "player") "magic") 2) "-"
      (coalesce (.optionalProperty (id "combat") "playerMagicPenalty") 0))),
    ("athletics", maxZero (.binary (coalesce (prop (id "player") "athletics") 2) "-"
      (coalesce (.optionalProperty (id "combat") "playerAthleticsPenalty") 0))),
    ("agility", maxZero (.binary (coalesce (prop (id "player") "agility") 2) "-"
      (coalesce (.optionalProperty (id "combat") "playerAgilityPenalty") 0)))
  ])]

def enemyStatsFunction : Function where
  isAsync := false
  name := "enemyStats"
  parameters := [{ name := "combat", type := .doc .combats }]
  returns := .named "BattleStats"
  body := [.return (.object [
    ("attack", prop (id "combat") "enemyAttack"),
    ("defense", adjusted (id "combat") "enemyDefense" "enemyDefensePenalty"),
    ("magic", adjusted (id "combat") "enemyMagic" "enemyMagicPenalty"),
    ("athletics", adjusted (id "combat") "enemyAthletics" "enemyAthleticsPenalty"),
    ("agility", adjusted (id "combat") "enemyAgility" "enemyAgilityPenalty")
  ])]

private def penaltyObject (field : String) : Expr := .object [
  (field, call (prop (id "Math") "max") [
    coalesce (prop (id "combat") field) 0, id "amount"
  ])
]

def debuffPatchFunction : Function where
  isAsync := false
  name := "debuffPatch"
  parameters := [
    { name := "combat", type := .doc .combats },
    { name := "target", type := .union [.literalString "enemy", .literalString "player"] },
    { name := "stat", type := .named "DebuffStat" }, { name := "amount", type := .number }
  ]
  returns := .union [
    .obj [("enemyDefensePenalty", .number)], .obj [("enemyMagicPenalty", .number)],
    .obj [("enemyAthleticsPenalty", .number)], .obj [("enemyAgilityPenalty", .number)],
    .obj [("playerDefensePenalty", .number)], .obj [("playerMagicPenalty", .number)],
    .obj [("playerAthleticsPenalty", .number)], .obj [("playerAgilityPenalty", .number)]
  ]
  body := [
    .ifThen (.binary (id "target") "===" (.string "enemy")) [
      .ifThen (.binary (id "stat") "===" (.string "defense")) [
        .return (penaltyObject "enemyDefensePenalty")
      ],
      .ifThen (.binary (id "stat") "===" (.string "magic")) [
        .return (penaltyObject "enemyMagicPenalty")
      ],
      .ifThen (.binary (id "stat") "===" (.string "athletics")) [
        .return (penaltyObject "enemyAthleticsPenalty")
      ],
      .return (penaltyObject "enemyAgilityPenalty")
    ],
    .ifThen (.binary (id "stat") "===" (.string "defense")) [
      .return (penaltyObject "playerDefensePenalty")
    ],
    .ifThen (.binary (id "stat") "===" (.string "magic")) [
      .return (penaltyObject "playerMagicPenalty")
    ],
    .ifThen (.binary (id "stat") "===" (.string "athletics")) [
      .return (penaltyObject "playerAthleticsPenalty")
    ],
    .return (penaltyObject "playerAgilityPenalty")
  ]

def startCombatFunction : Function where
  name := "startCombat"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "room", type := .doc .rooms },
    { name := "player", type := .doc .players },
    { name := "spaceId", type := .number }
  ]
  returns := .promise .void
  body := [
    .constDecl "enemy" (call (id "enemyForSpace") [id "spaceId"]),
    .constDecl "combatId" (.await (method (prop (id "ctx") "db") "insert" [
      .string "combats", .object [
        ("roomId", prop (id "room") "_id"), ("playerId", prop (id "player") "_id"),
        ("spaceId", id "spaceId"), ("enemyName", prop (id "enemy") "name"),
        ("enemyElement", prop (id "enemy") "element"), ("enemyHp", prop (id "enemy") "hp"),
        ("enemyMaxHp", prop (id "enemy") "hp"),
        ("enemyAttack", prop (id "enemy") "attack"),
        ("enemyDefense", prop (id "enemy") "defense"),
        ("enemyMagic", prop (id "enemy") "magic"),
        ("enemyAthletics", prop (id "enemy") "athletics"),
        ("enemyAgility", prop (id "enemy") "agility"),
        ("reward", prop (id "enemy") "reward"), ("round", .number 1),
        ("phase", .string "attack"),
        ("message", .binary (.string "Choose how to attack the ") "+"
          (.binary (prop (id "enemy") "name") "+" (.string "."))),
        ("createdAt", call (prop (id "Date") "now"))
      ]
    ])),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      prop (id "room") "_id", .object [
        ("remainingMoves", .number 0), ("phase", .string "combatAttack"),
        ("activeCombatId", id "combatId"),
        ("message", .binary
          (.binary (prop (id "player") "name") "+" (.string " faces a ")) "+"
          (.binary (prop (id "enemy") "name") "+" (.string "!")))
      ]
    ]))
  ]

def activeCombatFunction : Function where
  name := "activeCombat"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" }, { name := "roomId", type := .id .rooms },
    { name := "playerId", type := .id .players },
    { name := "expected", type := .union [
        .literalString "combatAttack", .literalString "combatDefend"
      ] }
  ]
  returns := .promise (.named "CombatControl")
  body := [
    .constDecl "room" (.await (method (prop (id "ctx") "db") "get" [id "roomId"])),
    .constDecl "player" (.await (method (prop (id "ctx") "db") "get" [id "playerId"])),
    .constDecl "combat" (.conditional
      (.binary (id "room") "&&" (prop (id "room") "activeCombatId"))
      (.await (method (prop (id "ctx") "db") "get" [prop (id "room") "activeCombatId"])) .null),
    .ifThen (.binary
      (.binary
        (.binary
          (.binary
            (.binary (.prefix "!" (id "room")) "||" (.prefix "!" (id "player"))) "||"
            (.prefix "!" (id "combat"))) "||"
          (.binary (prop (id "room") "activePlayerId") "!==" (id "playerId"))) "||"
        (.binary (prop (id "combat") "playerId") "!==" (id "playerId"))) "||"
      (.binary (call (id "roomPhase") [id "room"]) "!==" (id "expected"))) [
      reject "That combat choice is not available."
    ],
    .return (.object [("room", id "room"), ("player", id "player"), ("combat", id "combat")])
  ]

/-- Combat stat projection, debuff bookkeeping, and combat lifecycle. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Combat/State.lean"
  imports := [
    { source := "convex/values", bindings := [{ name := "ConvexError" }] },
    { source := "../../../shared/combat.system", bindings := [{ name := "enemyForSpace" }, { name := "BattleStats", isType := true }] },
    { source := "../../../shared/magic.system", bindings := [{ name := "DebuffStat", isType := true }] },
    { source := "../../_generated/dataModel", bindings := [{ name := "Doc", isType := true }, { name := "Id", isType := true }] },
    { source := "../../_generated/server", bindings := [{ name := "MutationCtx", isType := true }] },
    { source := "../../gameHelpers", bindings := [{ name := "roomPhase" }] }
  ]
  items := [
    .raw "type CombatControl = { room: Doc<'rooms'>; player: Doc<'players'>; combat: Doc<'combats'> }\n",
    .function playerStatsFunction,
    .function enemyStatsFunction,
    .function debuffPatchFunction,
    .function startCombatFunction,
    .function activeCombatFunction
  ]

end Mythroads.Backend.Combat.State
