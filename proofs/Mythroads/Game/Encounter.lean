import Mythroads.Convex.Module

namespace Mythroads.Game.Encounter

open Mythroads.Convex
open Mythroads.Convex.TypeScript

inductive Kind where | combat | event deriving Repr, DecidableEq

def Kind.label : Kind → String | .combat => "combat" | .event => "event"

structure Outcome where
  id : String
  kind : Kind
  title : String
  description : String
  goldDelta : Int
  hpDelta : Int
  weight : Nat
  deriving Repr, DecidableEq

def outcomes : List Outcome := [
  { id := "slime_scout", kind := .combat, title := "Slime Scout",
    description := "A quick victory leaves a few coins behind.", goldDelta := 2, hpDelta := 0, weight := 28 },
  { id := "goblin_duel", kind := .combat, title := "Goblin Duel",
    description := "You win, but not without a scratch.", goldDelta := 4, hpDelta := -1, weight := 25 },
  { id := "wild_boar", kind := .combat, title := "Wild Boar",
    description := "A brutal charge and a valuable trophy.", goldDelta := 6, hpDelta := -2, weight := 20 },
  { id := "alpha_wolf", kind := .combat, title := "Alpha Wolf",
    description := "A dangerous foe guards a rich cache.", goldDelta := 9, hpDelta := -3, weight := 12 },
  { id := "monster_fled", kind := .combat, title := "Monster Fled",
    description := "It saw you and chose another road.", goldDelta := 0, hpDelta := 0, weight := 15 },
  { id := "coin_spring", kind := .event, title := "Coin Spring",
    description := "Bright coins bubble out of the ground.", goldDelta := 5, hpDelta := 0, weight := 25 },
  { id := "forest_blessing", kind := .event, title := "Forest Blessing",
    description := "The old trees restore your strength.", goldDelta := 0, hpDelta := 3, weight := 20 },
  { id := "bridge_toll", kind := .event, title := "Bridge Toll",
    description := "A tiny official demands a tiny fee.", goldDelta := -2, hpDelta := 0, weight := 18 },
  { id := "falling_star", kind := .event, title := "Falling Star",
    description := "You find a warm shard worth a fortune.", goldDelta := 8, hpDelta := 0, weight := 12 },
  { id := "thorn_patch", kind := .event, title := "Thorn Patch",
    description := "The shortcut was not actually shorter.", goldDelta := 0, hpDelta := -2, weight := 25 }
]

def outcomesFor (kind : Kind) : List Outcome := outcomes.filter fun value => value.kind = kind
def totalWeight (kind : Kind) : Nat := (outcomesFor kind).foldl (fun sum value => sum + value.weight) 0

theorem combatWeightPositive : 0 < totalWeight .combat := by decide
theorem eventWeightPositive : 0 < totalWeight .event := by decide
theorem allWeightsPositive : outcomes.all (fun value => 0 < value.weight) = true := by decide

private def renderOutcome (value : Outcome) : String :=
  "    { id: " ++ quote value.id ++ ", kind: " ++ quote value.kind.label ++
  ", title: " ++ quote value.title ++ ", description: " ++ quote value.description ++
  ", goldDelta: " ++ toString value.goldDelta ++ ", hpDelta: " ++ toString value.hpDelta ++
  ", weight: " ++ toString value.weight ++ " },\n"

/-- The body of `shared/generated/encounter.generated.ts`, assembled from the catalogue above. -/
private def body : String :=
  "export type EncounterKind = 'combat' | 'event'\n" ++
  "export type EncounterOutcome = { id: string; kind: EncounterKind; title: string; description: string; goldDelta: number; hpDelta: number; weight: number }\n\n" ++
  "export const ENCOUNTERS: EncounterOutcome[] = [\n" ++
  join "" (outcomes.map renderOutcome) ++ "]\n\n" ++
  "export function outcomesFor(kind: EncounterKind) { return ENCOUNTERS.filter((outcome) => outcome.kind === kind) }\n" ++
  "export function encounterWeight(kind: EncounterKind) { return outcomesFor(kind).reduce((sum, outcome) => sum + outcome.weight, 0) }\n" ++
  "export function pickEncounter(kind: EncounterKind, roll: number) {\n" ++
  "    const choices = outcomesFor(kind)\n" ++
  "    let cursor = Math.min(Math.max(Math.trunc(roll), 0), encounterWeight(kind) - 1)\n" ++
  "    for (const outcome of choices) { cursor -= outcome.weight; if (cursor < 0) return outcome }\n" ++
  "    return choices[choices.length - 1]\n}\n"

/-- The encounter-wheel catalogue shared by the browser and Convex. -/
def module : Module where
  provenance := some "proofs/Mythroads/Game/Encounter.lean"
  items := [.raw body]

end Mythroads.Game.Encounter
