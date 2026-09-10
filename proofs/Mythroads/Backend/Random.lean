import Mythroads.Convex.TypeScript
import Mythroads.Game.Random

namespace Mythroads.Backend.Random

open Mythroads.Convex.TypeScript
open Mythroads.Game.Random

private def id (name : String) : Expr := .identifier name
private def prop (target : Expr) (name : String) : Expr := .property target name
private def call (target : Expr) (arguments : List Expr) : Expr := .call target arguments

def normalizeSeedFunction : Function where
  isAsync := false
  name := "normalizeSeed"
  parameters := [{ name := "seed", type := .number }]
  returns := .number
  body := [
    .constDecl "whole" (call (prop (id "Math") "trunc") [
      call (prop (id "Math") "abs") [id "seed"]
    ]),
    .return (.binary
      (.binary (id "whole") "%" (.number (modulus - 1))) "+" (.number 1))
  ]

def nextRandomFunction : Function where
  isAsync := false
  name := "nextRandom"
  parameters := [{ name := "state", type := .number }]
  returns := .number
  body := [
    .return (.binary
      (.binary (id "state") "*" (.number multiplier)) "%" (.number modulus))
  ]

def drawBoundedFunction : Function where
  isAsync := false
  name := "drawBounded"
  parameters := [
    { name := "state", type := .number }, { name := "bound", type := .number }
  ]
  returns := .object [("value", .number), ("state", .number)]
  body := [
    .ifThen (.binary (id "bound") "<=" (.number 0)) [
      .throw (.new "RangeError" [.string "Random bounds must be positive."])
    ],
    .constDecl "next" (.call (id "nextRandom") [id "state"]),
    .return (.object [
      ("value", .binary (id "next") "%" (id "bound")), ("state", id "next")
    ])
  ]

def chanceHitsFunction : Function where
  isAsync := false
  name := "chanceHits"
  parameters := [
    { name := "favorable", type := .number }, { name := "possible", type := .number },
    { name := "roll", type := .number }
  ]
  returns := .boolean
  body := [
    .ifThen (.binary
      (.binary
        (.binary
          (.binary (id "possible") "<=" (.number 0)) "||"
          (.binary (id "favorable") "<" (.number 0))) "||"
        (.binary (id "favorable") ">" (id "possible"))) "||"
      (.binary
        (.binary (id "roll") "<" (.number 0)) "||"
        (.binary (id "roll") ">=" (id "possible")))) [
      .throw (.new "RangeError" [.string "Chance bounds must be non-negative and possible must be positive."])
    ],
    .return (.binary (id "roll") "<" (id "favorable"))
  ]
def emitRandomBackend : String :=
  emitFunction normalizeSeedFunction ++ "\n" ++ emitFunction nextRandomFunction ++ "\n" ++
  emitFunction drawBoundedFunction ++ "\n" ++ emitFunction chanceHitsFunction

end Mythroads.Backend.Random
