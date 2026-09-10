import Mythroads.Convex.Module
import Mythroads.Game.Magic

namespace Mythroads.Game.Combat

open Mythroads.Convex
open Mythroads.Convex.TypeScript
open Mythroads.Game.Magic

inductive PhysicalAttack where | stab | chargeHigh | chargeSide | leap deriving Repr, DecidableEq
inductive Guard where | high | side | brace | ward deriving Repr, DecidableEq
inductive Matchup where | weak | neutral | strong deriving Repr, DecidableEq

def PhysicalAttack.label : PhysicalAttack → String
  | .stab => "stab" | .chargeHigh => "chargeHigh" | .chargeSide => "chargeSide" | .leap => "leap"
def PhysicalAttack.title : PhysicalAttack → String
  | .stab => "Quick stab" | .chargeHigh => "High charge"
  | .chargeSide => "Side rush" | .leap => "Leaping strike"
def Guard.label : Guard → String | .high => "high" | .side => "side" | .brace => "brace" | .ward => "ward"
def Guard.title : Guard → String
  | .high => "High guard" | .side => "Side guard" | .brace => "Brace" | .ward => "Arcane ward"
def Matchup.label : Matchup → String | .weak => "weak" | .neutral => "neutral" | .strong => "strong"

def physicalAttacks : List PhysicalAttack := [.stab, .chargeHigh, .chargeSide, .leap]
def guards : List Guard := [.high, .side, .brace, .ward]
def matchups : List Matchup := [.weak, .neutral, .strong]

def physicalMatchup : PhysicalAttack → Guard → Matchup
  | .stab, .high | .stab, .side | .stab, .brace => .neutral
  | .stab, .ward => .strong
  | .chargeHigh, .high => .weak | .chargeHigh, .side => .strong
  | .chargeHigh, .brace => .neutral | .chargeHigh, .ward => .strong
  | .chargeSide, .high => .neutral | .chargeSide, .side => .weak
  | .chargeSide, .brace | .chargeSide, .ward => .strong
  | .leap, .high => .strong | .leap, .side => .neutral
  | .leap, .brace => .weak | .leap, .ward => .strong

def impactMatchup : Impact → Guard → Matchup
  | .wucht, .high => .neutral | .wucht, .side => .strong
  | .wucht, .brace => .weak | .wucht, .ward => .strong
  | .stich, .high => .strong | .stich, .side => .weak
  | .stich, .brace => .neutral | .stich, .ward => .strong
  | .hieb, .high => .weak | .hieb, .side => .neutral
  | .hieb, .brace | .hieb, .ward => .strong

def physicalPower : PhysicalAttack → Nat
  | .stab => 115 | .chargeHigh | .chargeSide | .leap => 145

def matchupMultiplier : Matchup → Nat | .weak => 55 | .neutral => 100 | .strong => 165

def committedCharges : List PhysicalAttack := [.chargeHigh, .chargeSide, .leap]

theorem everyChargeHasWeakNeutralStrong : committedCharges.all (fun attack =>
    guards.any (physicalMatchup attack · = .weak) ∧
    guards.any (physicalMatchup attack · = .neutral) ∧
    guards.any (physicalMatchup attack · = .strong)) = true := by decide

theorem wardIsExposedToPhysicalAttacks :
    physicalAttacks.all (fun attack => physicalMatchup attack .ward = .strong) = true := by
  decide

structure Enemy where
  name : String
  element : Element
  hp : Nat
  attack : Nat
  defense : Nat
  magic : Nat
  athletics : Nat
  agility : Nat
  reward : Nat
  deriving Repr, DecidableEq

def enemies : List Enemy := [
  { name := "Mossback Boar", element := .earth, hp := 14, attack := 3, defense := 3,
    magic := 1, athletics := 4, agility := 1, reward := 7 },
  { name := "Fen Slime", element := .water, hp := 11, attack := 2, defense := 2,
    magic := 3, athletics := 1, agility := 2, reward := 6 },
  { name := "Ember Imp", element := .fire, hp := 12, attack := 3, defense := 2,
    magic := 4, athletics := 2, agility := 4, reward := 8 },
  { name := "Gale Wolf", element := .wind, hp := 15, attack := 4, defense := 2,
    magic := 2, athletics := 4, agility := 5, reward := 9 }
]

theorem enemyCatalogNonempty : enemies ≠ [] := by decide
theorem enemiesHavePositiveHealth : enemies.all (fun enemy => 0 < enemy.hp) = true := by decide

private def record (values : List (String × String)) : String :=
  "{ " ++ join ", " (values.map fun (key, value) => key ++ ": " ++ value) ++ " }"

private def renderPhysicalRow (attack : PhysicalAttack) : String :=
  "    " ++ attack.label ++ ": " ++ record (guards.map fun guard =>
    (guard.label, quote (physicalMatchup attack guard).label)) ++ ",\n"

private def renderImpactRow (impact : Impact) : String :=
  "    " ++ impact.label ++ ": " ++ record (guards.map fun guard =>
    (guard.label, quote (impactMatchup impact guard).label)) ++ ",\n"

private def renderEnemy (enemy : Enemy) : String :=
  "    " ++ record [
    ("name", quote enemy.name), ("element", quote enemy.element.label), ("hp", toString enemy.hp),
    ("attack", toString enemy.attack), ("defense", toString enemy.defense),
    ("magic", toString enemy.magic), ("athletics", toString enemy.athletics),
    ("agility", toString enemy.agility), ("reward", toString enemy.reward)
  ] ++ ",\n"

/-- The body of `shared/generated/combat.generated.ts`, assembled from the catalogue above. -/
private def body : String :=
  "export const PHYSICAL_ATTACKS = [" ++ join ", " (physicalAttacks.map fun value => quote value.label) ++ "] as const\n" ++
  "export const GUARD_STANCES = [" ++ join ", " (guards.map fun value => quote value.label) ++ "] as const\n" ++
  "export type PhysicalAttack = (typeof PHYSICAL_ATTACKS)[number]\nexport type GuardStance = (typeof GUARD_STANCES)[number]\n" ++
  "export type CombatAttack = PhysicalAttack | MagicTechniqueId\nexport type Matchup = 'weak' | 'neutral' | 'strong'\n" ++
  "export type BattleStats = { attack: number; defense: number; magic: number; athletics: number; agility: number }\n\n" ++
  "export const ATTACK_LABELS: Record<CombatAttack, string> = {\n" ++
  join "" (physicalAttacks.map fun value => "    " ++ value.label ++ ": " ++ quote value.title ++ ",\n") ++
  join "" (techniques.map fun value => "    " ++ value.id ++ ": " ++ quote value.label ++ ",\n") ++ "}\n" ++
  "export const GUARD_LABELS: Record<GuardStance, string> = {\n" ++
  join "" (guards.map fun value => "    " ++ value.label ++ ": " ++ quote value.title ++ ",\n") ++ "}\n" ++
  "const PHYSICAL_MATCHUPS: Record<PhysicalAttack, Record<GuardStance, Matchup>> = {\n" ++
  join "" (physicalAttacks.map renderPhysicalRow) ++ "}\n" ++
  "const MULTIPLIER: Record<Matchup, number> = { weak: 0.55, neutral: 1, strong: 1.65 }\n" ++
  "const POWER: Record<PhysicalAttack, number> = { " ++ join ", " (physicalAttacks.map fun value =>
    value.label ++ ": " ++ toString (physicalPower value) ++ " / 100") ++ " }\n" ++
  "export const isMagicTechnique = (attack: CombatAttack): attack is MagicTechniqueId => attack in MAGIC_TECHNIQUES\n" ++
  "export function physicalMatchup(attack: PhysicalAttack, guard: GuardStance) { return PHYSICAL_MATCHUPS[attack][guard] }\n" ++
  "const IMPACT_MATCHUPS: Record<ImpactType, Record<GuardStance, Matchup>> = {\n" ++
  join "" ([Impact.wucht, .stich, .hieb].map renderImpactRow) ++ "}\n" ++
  "export function strikeDamage(attack: CombatAttack, guard: GuardStance, attacker: BattleStats, defender: BattleStats, targetElement?: Element, wardPower = 0.35) { const technique = isMagicTechnique(attack) ? MAGIC_TECHNIQUES[attack] : undefined; const arcane = technique?.delivery === 'arcane'; const impact = technique && ['wucht', 'stich', 'hieb'].includes(technique.delivery) ? (technique.delivery as ImpactType) : undefined; const matchup = arcane ? elementMatchup(technique.element, targetElement) : impact ? IMPACT_MATCHUPS[impact][guard] : physicalMatchup(attack as PhysicalAttack, guard); const physical = !arcane; const techniquePower = technique ? 0 : attack === 'stab' ? 0 : attacker.athletics * 0.35; const attackValue = technique ? attacker.magic : attacker.attack; const resistance = arcane ? defender.magic * 0.55 : defender.defense * 0.55; const brace = physical && guard === 'brace' ? defender.athletics * 0.25 : 0; const ward = arcane && guard === 'ward' ? wardPower : 1; const accuracy = arcane ? 1 : Math.max(0.5, Math.min(0.98, 0.75 + (attacker.agility - defender.agility) * 0.04)); const power = technique?.power ?? POWER[attack as PhysicalAttack]; return { matchup, accuracy, damage: Math.max(1, Math.round((attackValue * power + techniquePower - resistance - brace) * MULTIPLIER[matchup] * ward)) } }\n" ++
  "const ENEMIES = [\n" ++ join "" (enemies.map renderEnemy) ++ "] as const\n" ++
  "export function enemyForSpace(spaceId: number) { return ENEMIES[spaceId % ENEMIES.length] }\n"

/-- The physical attack, guard, and enemy catalogues plus the damage formula. -/
def module : Module where
  provenance := some "proofs/Mythroads/Game/Combat.lean"
  imports := [{ source := "../magic.system.ts", bindings := [
    { name := "elementMatchup" }, { name := "MAGIC_TECHNIQUES" },
    { name := "Element", isType := true }, { name := "ImpactType", isType := true },
    { name := "MagicTechniqueId", isType := true }] }]
  items := [.raw body]

end Mythroads.Game.Combat
