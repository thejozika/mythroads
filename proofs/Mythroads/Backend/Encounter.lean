import Mythroads.Convex.Module

namespace Mythroads.Backend.Encounter

open Mythroads.Convex
open Mythroads.Convex.TypeScript

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr := []) : Expr := .call target arguments
private def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  call (prop target name) arguments
private def reject (message : String) : Statement :=
  .throw (.new "ConvexError" [.string message])

private def subjectsType : TsType := .obj [
  ("roomId", .id .rooms), ("playerId", .id .players),
  ("encounterId", .id .encounters)
]

private def effectText (field suffix : String) : Expr :=
  .conditional (prop (id "encounter") field)
    (.binary
      (.binary (.conditional
        (.binary (prop (id "encounter") field) ">" (.number 0)) (.string "+") (.string "")) "+"
        (prop (id "encounter") field)) "+" (.string suffix))
    (.string "")

def resolveEncounterFunction : Function where
  name := "resolveEncounter"
  parameters := [
    { name := "ctx", type := .named "MutationCtx" },
    { name := "subjects", type := subjectsType }
  ]
  returns := .promise .void
  body := [
    .constDecl "roomId" (prop (id "subjects") "roomId"),
    .constDecl "playerId" (prop (id "subjects") "playerId"),
    .constDecl "encounterId" (prop (id "subjects") "encounterId"),
    .constDecl "room" (.await (method (prop (id "ctx") "db") "get" [id "roomId"])),
    .constDecl "player" (.await (method (prop (id "ctx") "db") "get" [id "playerId"])),
    .constDecl "encounter" (.await (method (prop (id "ctx") "db") "get" [id "encounterId"])),
    .ifThen (.binary
      (.binary
        (.binary
          (.binary
            (.binary
              (.binary
                (.binary
                  (.binary (.prefix "!" (id "room")) "||" (.prefix "!" (id "player"))) "||"
                  (.prefix "!" (id "encounter"))) "||"
                (.binary (prop (id "room") "activePlayerId") "!==" (id "playerId"))) "||"
              (.binary (prop (id "room") "activeEncounterId") "!==" (id "encounterId"))) "||"
            (.binary (prop (id "encounter") "playerId") "!==" (id "playerId"))) "||"
          (.binary (prop (id "encounter") "status") "!==" (.string "revealing"))) "||"
        (.binary (call (id "roomPhase") [id "room"]) "!==" (.string "revealingEncounter"))) "||"
      (.binary
        (.binary (call (prop (id "Date") "now")) "-" (prop (id "encounter") "createdAt"))
        "<" (.number 2200))) [
      reject "This encounter cannot be resolved now."
    ],
    .constDecl "gold" (call (prop (id "Math") "max") [
      .number 0, .binary (prop (id "player") "gold") "+" (prop (id "encounter") "goldDelta")
    ]),
    .constDecl "hp" (call (prop (id "Math") "min") [
      prop (id "player") "maxHp", call (prop (id "Math") "max") [
        .number 1, .binary (prop (id "player") "hp") "+" (prop (id "encounter") "hpDelta")
      ]
    ]),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      id "playerId", .object [("gold", id "gold"), ("hp", id "hp")]
    ])),
    .expression (.await (method (prop (id "ctx") "db") "patch" [
      id "encounterId", .object [("status", .string "resolved")]
    ])),
    .constDecl "effects" (method (.array [
      effectText "goldDelta" " gold", effectText "hpDelta" " health"
    ]) "filter" [.arrow ["value"] (id "value")]),
    .constDecl "message" (.binary
      (.binary
        (.binary (prop (id "player") "name") "+" (.string ": ")) "+"
        (prop (id "encounter") "title")) "+"
      (.conditional (prop (id "effects") "length")
        (.binary
          (.binary (.string " (") "+" (method (id "effects") "join" [.string ", "])) "+"
          (.string ")."))
        (.string "."))),
    .expression (.await (call (id "advanceTurn") [
      id "ctx", id "room", id "playerId", id "message"
    ]))
  ]

/-- The `encounter.resolve` transaction as one generated Convex module. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Encounter.lean"
  imports := [
    { source := "convex/values", bindings := [{ name := "ConvexError" }] },
    { source := "../_generated/dataModel", bindings := [{ name := "Id", isType := true }] },
    { source := "../_generated/server", bindings := [{ name := "MutationCtx", isType := true }] },
    { source := "../gameHelpers", bindings := [{ name := "advanceTurn" }, { name := "roomPhase" }] }
  ]
  items := [
    .function resolveEncounterFunction
  ]

end Mythroads.Backend.Encounter
