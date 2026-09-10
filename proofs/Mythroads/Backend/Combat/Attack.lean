import Mythroads.Backend.Combat.State

namespace Mythroads.Backend.Combat.Attack

open Mythroads.Convex.TypeScript
open Mythroads.Backend.Combat.State

private def concat (left right : Expr) : Expr := .binary left "+" right
private def label (catalog value : String) : Expr := .index (id catalog) (id value)

private def inventoryQuery : Expr :=
  .await (method
    (method
      (method (prop (id "ctx") "db") "query" [.string "playerItems"])
      "withIndex" [.string "by_playerId", .arrow ["query"]
        (method (id "query") "eq" [.string "playerId", prop (id "player") "_id"])])
    "take" [.number 40])

private def debuffMessage : Expr := .conditional (id "blocked")
  (concat (concat (label "GUARD_LABELS" "guard") (.string " nullified "))
    (concat (label "ATTACK_LABELS" "attack") (.string ".")))
  (concat (concat (label "ATTACK_LABELS" "attack") (.string " lowered the enemy's "))
    (concat (.optionalProperty (prop (id "technique") "debuff") "stat") (.string ".")))

private def strikeMessage : Expr := .conditional (id "damage")
  (concat
    (concat
      (concat
        (concat (label "ATTACK_LABELS" "attack") (.string " met "))
        (concat (label "GUARD_LABELS" "guard") (.string ": ")))
      (concat (prop (id "result") "matchup") (.string ", ")))
    (concat (id "damage") (.string " damage.")))
  (concat (label "ATTACK_LABELS" "attack") (.string " missed!"))

def chooseAttackFunction : Function where
  name := "chooseAttack"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "subjects", type := .object [
        ("roomId", .id "rooms"), ("playerId", .id "players")
      ] },
    { name := "attack", type := .named "CombatAttack" }
  ]
  returns := .promise .void
  body := [
    .constDecl "control" (.await (call (id "activeCombat") [
      id "ctx", prop (id "subjects") "roomId", prop (id "subjects") "playerId",
      .string "combatAttack"
    ])),
    .constDecl "room" (prop (id "control") "room"),
    .constDecl "player" (prop (id "control") "player"),
    .constDecl "combat" (prop (id "control") "combat"),
    .constDecl "guard" (.index (id "GUARD_STANCES") (.await (call (id "drawRoomRandom") [
      id "ctx", prop (id "room") "_id", prop (id "GUARD_STANCES") "length"
    ]))),
    .constDecl "magic" (call (id "isMagicTechnique") [id "attack"]),
    .constDecl "inventory" inventoryQuery,
    .constDecl "loadout" (call (id "equippedMagic") [id "inventory"]),
    .ifThen (.binary (id "magic") "&&"
      (.prefix "!" (method (prop (id "loadout") "actions") "includes" [id "attack"]))) [
      reject "Equip the grimoire containing that technique first."
    ],
    .constDecl "technique" (.conditional (id "magic")
      (.index (id "MAGIC_TECHNIQUES") (id "attack")) .undefined),
    .ifThen (.binary (id "technique") "&&"
      (.binary (prop (id "technique") "delivery") "===" (.string "debuff"))) [
      .constDecl "blocked" (.binary (id "guard") "===" (.string "ward")),
      .ifThen (.binary (.prefix "!" (id "blocked")) "&&" (prop (id "technique") "debuff")) [
        .expression (.await (method (prop (id "ctx") "db") "patch" [
          prop (id "combat") "_id", call (id "debuffPatch") [
            id "combat", .string "enemy", prop (prop (id "technique") "debuff") "stat",
            prop (prop (id "technique") "debuff") "amount"
          ]
        ]))
      ],
      .expression (.await (method (prop (id "ctx") "db") "patch" [
        prop (id "combat") "_id", .object [
          ("phase", .string "defend"), ("lastAttack", id "attack"),
          ("lastGuard", id "guard"), ("lastDamage", .number 0),
          ("message", debuffMessage)
        ]
      ])),
      .expression (.await (method (prop (id "ctx") "db") "patch" [
        prop (id "room") "_id", .object [
          ("phase", .string "combatDefend"),
          ("message", concat (prop (id "combat") "enemyName")
            (.string " prepares a counterattack. Choose a guard."))
        ]
      ])), .returnVoid
    ],
    .constDecl "result" (call (id "strikeDamage") [
      id "attack", id "guard", call (id "playerStats") [id "player", id "combat"],
      call (id "enemyStats") [id "combat"], prop (id "combat") "enemyElement"
    ]),
    .constDecl "hitRoll" (.await (call (id "drawRoomRandom") [
      id "ctx", prop (id "room") "_id", .number 10000
    ])),
    .constDecl "damage" (.conditional (call (id "chanceHits") [
      call (prop (id "Math") "round") [
        .binary (prop (id "result") "accuracy") "*" (.number 10000)
      ], .number 10000, id "hitRoll"
    ]) (prop (id "result") "damage") (.number 0)),
    .constDecl "enemyHp" (call (prop (id "Math") "max") [
      .number 0, .binary (prop (id "combat") "enemyHp") "-" (id "damage")
    ]),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      prop (id "combat") "_id", .object [
        ("enemyHp", id "enemyHp"), ("lastAttack", id "attack"),
        ("lastGuard", id "guard"), ("lastDamage", id "damage"),
        ("message", strikeMessage)
      ]
    ])),
    .ifThen (.binary (id "enemyHp") "===" (.number 0)) [
      .expression (.await (method (prop (id "ctx") "db") "patch" [
        prop (id "combat") "_id", .object [("phase", .string "resolved")]
      ])),
      .expression (.await (method (prop (id "ctx") "db") "patch" [
        prop (id "player") "_id", .object [("gold", .binary
          (prop (id "player") "gold") "+" (prop (id "combat") "reward"))]
      ])),
      .expression (.await (call (id "advanceTurn") [
        id "ctx", id "room", prop (id "player") "_id",
        concat
          (concat
            (concat (prop (id "player") "name") (.string " defeated "))
            (concat (prop (id "combat") "enemyName") (.string " and won ")))
          (concat (prop (id "combat") "reward") (.string " gold."))
      ])), .returnVoid
    ],
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      prop (id "combat") "_id", .object [("phase", .string "defend")]
    ])),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      prop (id "room") "_id", .object [
        ("phase", .string "combatDefend"),
        ("message", concat (prop (id "combat") "enemyName")
          (.string " prepares a counterattack. Choose a guard."))
      ]
    ]))
  ]

def emitAttack : String := emitFunction chooseAttackFunction

end Mythroads.Backend.Combat.Attack
