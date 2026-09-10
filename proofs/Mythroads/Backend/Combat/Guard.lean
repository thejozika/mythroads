import Mythroads.Backend.Combat.State

namespace Mythroads.Backend.Combat.Guard

open Mythroads.Convex.TypeScript
open Mythroads.Backend.Combat.State

private def concat (left right : Expr) : Expr := .binary left "+" right
private def label (catalog value : String) : Expr := .index (id catalog) (id value)

private def inventoryQuery : Expr :=
  .await (method
    (method
      (method (prop (id "ctx") "db") "query" [.string "playerItems"])
      "withIndex" [.string "by_playerId", .arrow ["query"]
        (method (id "query") "eq" [.string "playerId", prop (id "player") "_id"])] )
    "take" [.number 40])

private def blockedCombatMessage : Expr :=
  concat
    (concat
      (concat (prop (id "player") "name") (.string "'s "))
      (concat (label "GUARD_LABELS" "guard") (.string " nullified ")))
    (concat (label "ATTACK_LABELS" "attack") (.string "."))

private def debuffedCombatMessage : Expr :=
  concat
    (concat
      (concat
        (concat (prop (id "combat") "enemyName") (.string "'s "))
        (concat (label "ATTACK_LABELS" "attack") (.string " lowered ")))
      (concat (prop (id "player") "name") (.string "'s ")))
    (concat (.optionalProperty (prop (id "technique") "debuff") "stat") (.string "."))

private def strikeMessage : Expr := .conditional (id "damage")
  (concat
    (concat
      (concat
        (concat
          (concat (prop (id "combat") "enemyName") (.string "'s "))
          (concat (label "ATTACK_LABELS" "attack") (.string " met ")))
        (concat (label "GUARD_LABELS" "guard") (.string ": ")))
      (concat (prop (id "result") "matchup") (.string ", ")))
    (concat (id "damage") (.string " damage.")))
  (concat
    (concat (prop (id "combat") "enemyName") (.string "'s "))
    (concat (label "ATTACK_LABELS" "attack") (.string " missed!")))

def chooseGuardFunction : Function where
  name := "chooseGuard"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "subjects", type := .object [
        ("roomId", .id "rooms"), ("playerId", .id "players")
      ] },
    { name := "guard", type := .named "GuardStance" }
  ]
  returns := .promise .void
  body := [
    .constDecl "control" (.await (call (id "activeCombat") [
      id "ctx", prop (id "subjects") "roomId", prop (id "subjects") "playerId",
      .string "combatDefend"
    ])),
    .constDecl "room" (prop (id "control") "room"),
    .constDecl "player" (prop (id "control") "player"),
    .constDecl "combat" (prop (id "control") "combat"),
    .constDecl "attacks" (.asConst (.array [
      .spread (id "PHYSICAL_ATTACKS"),
      .spread (.index (id "MAGIC_LOADOUTS") (prop (id "combat") "enemyElement"))
    ])),
    .constDecl "attack" (.index (id "attacks") (.await (call (id "drawRoomRandom") [
      id "ctx", prop (id "room") "_id", prop (id "attacks") "length"
    ]))),
    .constDecl "inventory" inventoryQuery,
    .constDecl "technique" (.conditional (call (id "isMagicTechnique") [id "attack"])
      (.index (id "MAGIC_TECHNIQUES") (id "attack")) .undefined),
    .ifThen (.binary (id "technique") "&&"
      (.binary (prop (id "technique") "delivery") "===" (.string "debuff"))) [
      .constDecl "blocked" (.binary (id "guard") "===" (.string "ward")),
      .ifThen (.binary (.prefix "!" (id "blocked")) "&&" (prop (id "technique") "debuff")) [
        .expression (.await (method (prop (id "ctx") "db") "patch" [
          prop (id "combat") "_id", call (id "debuffPatch") [
            id "combat", .string "player", prop (prop (id "technique") "debuff") "stat",
            prop (prop (id "technique") "debuff") "amount"
          ]
        ]))
      ],
      .expression (.await (method (prop (id "ctx") "db") "patch" [
        prop (id "combat") "_id", .object [
          ("round", .binary (prop (id "combat") "round") "+" (.number 1)),
          ("phase", .string "attack"), ("lastAttack", id "attack"),
          ("lastGuard", id "guard"), ("lastDamage", .number 0),
          ("message", .conditional (id "blocked") blockedCombatMessage debuffedCombatMessage)
        ]
      ])),
      .expression (.await (method (prop (id "ctx") "db") "patch" [
        prop (id "room") "_id", .object [
          ("phase", .string "combatAttack"),
          ("message", .conditional (id "blocked")
            (concat (prop (id "player") "name")
              (.string " resisted the hex. Choose another attack."))
            (concat (prop (id "player") "name")
              (.string " was weakened. Choose another attack.")))
        ]
      ])), .returnVoid
    ],
    .constDecl "result" (call (id "strikeDamage") [
      id "attack", id "guard", call (id "enemyStats") [id "combat"],
      call (id "playerStats") [id "player", id "combat"], .undefined,
      prop (call (id "equippedMagic") [id "inventory"]) "wardPower"
    ]),
    .constDecl "hitRoll" (.await (call (id "drawRoomRandom") [
      id "ctx", prop (id "room") "_id", .number 10000
    ])),
    .constDecl "damage" (.conditional (call (id "chanceHits") [
      call (prop (id "Math") "round") [
        .binary (prop (id "result") "accuracy") "*" (.number 10000)
      ], .number 10000, id "hitRoll"
    ]) (prop (id "result") "damage") (.number 0)),
    .constDecl "hp" (call (prop (id "Math") "max") [
      .number 0, .binary (prop (id "player") "hp") "-" (id "damage")
    ]),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      prop (id "combat") "_id", .object [
        ("round", .binary (prop (id "combat") "round") "+" (.number 1)),
        ("phase", .conditional (.binary (id "hp") "===" (.number 0))
          (.string "resolved") (.string "attack")),
        ("lastAttack", id "attack"), ("lastGuard", id "guard"),
        ("lastDamage", id "damage"), ("message", strikeMessage)
      ]
    ])),
    .ifThen (.binary (id "hp") "===" (.number 0)) [
      .constDecl "loss" (call (prop (id "Math") "min") [
        .number 3, prop (id "player") "gold"
      ]),
      .expression (.await (method (prop (id "ctx") "db") "patch" [
        prop (id "player") "_id", .object [
          ("hp", prop (id "player") "maxHp"),
          ("gold", .binary (prop (id "player") "gold") "-" (id "loss")),
          ("position", .number 0), ("previousPosition", .undefined)
        ]
      ])),
      .expression (.await (call (id "advanceTurn") [
        id "ctx", id "room", prop (id "player") "_id",
        concat
          (concat
            (concat
              (concat (prop (id "player") "name") (.string " fell to "))
              (concat (prop (id "combat") "enemyName")
                (.string " and awoke at Hearthkeep, losing ")))
            (id "loss"))
          (.string " gold.")
      ])), .returnVoid
    ],
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      prop (id "player") "_id", .object [("hp", id "hp")]
    ])),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      prop (id "room") "_id", .object [
        ("phase", .string "combatAttack"),
        ("message", concat (prop (id "player") "name")
          (.string " weathered the counterattack. Choose another attack."))
      ]
    ]))
  ]

def emitGuard : String := emitFunction chooseGuardFunction

end Mythroads.Backend.Combat.Guard
