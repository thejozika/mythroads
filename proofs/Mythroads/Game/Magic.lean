import Mythroads.Convex.Module

namespace Mythroads.Game.Magic

open Mythroads.Convex
open Mythroads.Convex.TypeScript

inductive Element where
  | fire | water | wind | earth
  deriving Repr, DecidableEq

def Element.label : Element → String
  | .fire => "fire"
  | .water => "water"
  | .wind => "wind"
  | .earth => "earth"

def elements : List Element := [.fire, .water, .wind, .earth]

inductive Impact where
  | wucht | stich | hieb
  deriving Repr, DecidableEq

def Impact.label : Impact → String
  | .wucht => "wucht"
  | .stich => "stich"
  | .hieb => "hieb"

inductive DebuffStat where
  | defense | magic | athletics | agility
  deriving Repr, DecidableEq

def DebuffStat.label : DebuffStat → String
  | .defense => "defense"
  | .magic => "magic"
  | .athletics => "athletics"
  | .agility => "agility"

inductive Delivery where
  | arcane | impact (kind : Impact) | debuff
  deriving Repr, DecidableEq

def Delivery.label : Delivery → String
  | .arcane => "arcane"
  | .impact kind => kind.label
  | .debuff => "debuff"

structure Debuff where
  stat : DebuffStat
  amount : Nat
  deriving Repr, DecidableEq

structure Technique where
  id : String
  label : String
  element : Element
  delivery : Delivery
  powerHundredths : Nat
  debuff : Option Debuff := none
  description : String
  deriving Repr, DecidableEq

def techniques : List Technique := [
  { id := "emberBlast", label := "Ember Blast", element := .fire, delivery := .arcane,
    powerHundredths := 135,
    description := "Pure magic damage. Arcane Ward is its direct counter." },
  { id := "scorchArmor", label := "Scorch Armor", element := .fire, delivery := .debuff,
    powerHundredths := 0, debuff := some { stat := .defense, amount := 1 },
    description := "Lower enemy Defense for this battle." },
  { id := "tideNeedle", label := "Tide Needle", element := .water,
    delivery := .impact .stich, powerHundredths := 125,
    description := "Magic-powered Stich damage checked against physical guarding." },
  { id := "undertow", label := "Undertow", element := .water, delivery := .debuff,
    powerHundredths := 0, debuff := some { stat := .agility, amount := 1 },
    description := "Lower enemy Agility for this battle." },
  { id := "galeBlade", label := "Gale Blade", element := .wind,
    delivery := .impact .hieb, powerHundredths := 120,
    description := "Magic-powered Hieb damage checked against physical guarding." },
  { id := "windShear", label := "Wind Shear", element := .wind, delivery := .debuff,
    powerHundredths := 0, debuff := some { stat := .athletics, amount := 1 },
    description := "Lower enemy Athletics for this battle." },
  { id := "stoneCrash", label := "Stone Crash", element := .earth,
    delivery := .impact .wucht, powerHundredths := 130,
    description := "Magic-powered Wucht damage checked against physical guarding." },
  { id := "calcify", label := "Calcify", element := .earth, delivery := .debuff,
    powerHundredths := 0, debuff := some { stat := .magic, amount := 1 },
    description := "Lower enemy Magic for this battle." }
]

def loadout : Element → String × String
  | .fire => ("emberBlast", "scorchArmor")
  | .water => ("tideNeedle", "undertow")
  | .wind => ("galeBlade", "windShear")
  | .earth => ("stoneCrash", "calcify")

def strongAgainst : Element → Element
  | .fire => .earth
  | .water => .fire
  | .wind => .water
  | .earth => .wind

def weakAgainst : Element → Element
  | .fire => .water
  | .water => .wind
  | .wind => .earth
  | .earth => .fire

theorem strongAndWeakDiffer (element : Element) :
    strongAgainst element ≠ weakAgainst element := by cases element <;> decide

theorem loadoutsContainTwoTechniques (element : Element) :
    [(loadout element).1, (loadout element).2].length = 2 := by simp

private def renderPower (value : Nat) : String :=
  if value % 100 = 0 then toString (value / 100)
  else toString value ++ " / 100"

private def renderDebuff : Option Debuff → String
  | none => ""
  | some value =>
      ", debuff: { stat: " ++ quote value.stat.label ++ ", amount: " ++
      toString value.amount ++ " }"

private def renderTechnique (value : Technique) : String :=
  "    " ++ value.id ++ ": { id: " ++ quote value.id ++ ", label: " ++ quote value.label ++
  ", element: " ++ quote value.element.label ++ ", delivery: " ++ quote value.delivery.label ++
  ", power: " ++ renderPower value.powerHundredths ++ renderDebuff value.debuff ++
  ", description: " ++ quote value.description ++ " },\n"

private def renderLoadout (element : Element) : String :=
  let pair := loadout element
  "    " ++ element.label ++ ": [" ++ quote pair.1 ++ ", " ++ quote pair.2 ++ "],\n"

private def renderEdge (element : Element) : String :=
  "    " ++ element.label ++ ": { strong: " ++ quote (strongAgainst element).label ++
  ", weak: " ++ quote (weakAgainst element).label ++ " },\n"

/-- The body of `shared/generated/magic.generated.ts`, assembled from the catalogue above. -/
private def body : String :=
  "export const ELEMENTS = [" ++ join ", " (elements.map fun value => quote value.label) ++
  "] as const\nexport type Element = (typeof ELEMENTS)[number]\n" ++
  "export type ImpactType = 'wucht' | 'stich' | 'hieb'\n" ++
  "export type DebuffStat = 'defense' | 'magic' | 'athletics' | 'agility'\n\n" ++
  "export const MAGIC_TECHNIQUE_IDS = [" ++
  join ", " (techniques.map fun value => quote value.id) ++ "] as const\n" ++
  "export type MagicTechniqueId = (typeof MAGIC_TECHNIQUE_IDS)[number]\n" ++
  "export type MagicTechnique = { id: MagicTechniqueId; label: string; element: Element; delivery: 'arcane' | ImpactType | 'debuff'; power: number; debuff?: { stat: DebuffStat; amount: number }; description: string }\n\n" ++
  "export const MAGIC_TECHNIQUES: Record<MagicTechniqueId, MagicTechnique> = {\n" ++
  join "" (techniques.map renderTechnique) ++ "}\n\n" ++
  "export const MAGIC_LOADOUTS: Record<Element, readonly [MagicTechniqueId, MagicTechniqueId]> = {\n" ++
  join "" (elements.map renderLoadout) ++ "}\n\n" ++
  "const ELEMENT_EDGE: Record<Element, { strong: Element; weak: Element }> = {\n" ++
  join "" (elements.map renderEdge) ++ "}\n\n" ++
  "export function elementMatchup(element: Element, target?: Element) {\n" ++
  "    if (!target) return 'neutral' as const\n" ++
  "    if (ELEMENT_EDGE[element].strong === target) return 'strong' as const\n" ++
  "    if (ELEMENT_EDGE[element].weak === target) return 'weak' as const\n" ++
  "    return 'neutral' as const\n}\n"

/-- The magic-technique catalogue and the element matchup table. -/
def module : Module where
  provenance := some "proofs/Mythroads/Game/Magic.lean"
  items := [.raw body]

end Mythroads.Game.Magic
