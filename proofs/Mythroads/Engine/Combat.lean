import Mythroads.Engine.Room
import Mythroads.Game.Magic

/-!
# Battle arithmetic

The damage formula is the single most rule-bearing computation in Mythroads, and
until now it existed only as a TypeScript string inside `Game/Combat.lean`. This
module is its Lean definition, exact to the last rounding step.

**Fixed point, not floating point.** The generated `strikeDamage` multiplies four
fractions (`power`, `0.35`/`0.55`/`0.25` stat coefficients, the matchup multiplier,
the ward factor) and rounds once at the end. Every one of those fractions has a
terminating decimal expansion in hundredths, so the whole computation is exact in
integers scaled by 100: an *inner* term in hundredths, multiplied by a percentage
matchup and a percentage ward factor, gives a value in millionths that is rounded
once. `roundMillionths` is `Math.round` — floor of the value plus a half —
and the final `max 1` makes negative inner terms harmless, which is why the result
is a `Nat`.

**Accuracy is exact too.** `0.75 + delta * 0.04` clamped to `[0.5, 0.98]` is
`7500 + 400 * delta` clamped to `[5000, 9800]` basis points, and the hit test is
`hitRoll < accuracy` against a draw from `10000`. Nothing here is approximate.
-/

namespace Mythroads.Engine

open Mythroads.Game

/-- Magic techniques default to the first catalogue entry, so lookups can be total. -/
instance : Inhabited Magic.Technique where
  default :=
    { id := "emberBlast", label := "Ember Blast", element := .fire, delivery := .arcane,
      powerHundredths := 135, description := "" }

/-- The eight battle techniques, as a type rather than a string, so matches stay exhaustive. -/
inductive Technique where
  | emberBlast | scorchArmor | tideNeedle | undertow
  | galeBlade | windShear | stoneCrash | calcify
  deriving Repr, DecidableEq, Inhabited

/-- The catalogue identifier of a technique; identical to the wire value. -/
def Technique.id : Technique → String
  | .emberBlast => "emberBlast" | .scorchArmor => "scorchArmor"
  | .tideNeedle => "tideNeedle" | .undertow => "undertow"
  | .galeBlade => "galeBlade" | .windShear => "windShear"
  | .stoneCrash => "stoneCrash" | .calcify => "calcify"

/-- Every technique, in catalogue order. -/
def techniques : List Technique :=
  [.emberBlast, .scorchArmor, .tideNeedle, .undertow, .galeBlade, .windShear, .stoneCrash,
    .calcify]

/-- The catalogue entry for a technique, read from `Game.Magic` rather than restated. -/
def Technique.spec (t : Technique) : Magic.Technique :=
  (Magic.techniques.find? fun candidate => candidate.id = t.id).getD default

-- Every technique name resolves in the shared catalogue; no entry is silently defaulted.
#guard techniques.map (fun t => t.spec.id) = techniques.map Technique.id

/-- The two techniques an element's grimoire grants, mirroring `MAGIC_LOADOUTS`. -/
def loadoutFor : Magic.Element → Technique × Technique
  | .fire => (.emberBlast, .scorchArmor)
  | .water => (.tideNeedle, .undertow)
  | .wind => (.galeBlade, .windShear)
  | .earth => (.stoneCrash, .calcify)

-- The Lean loadouts agree with the catalogue pairs generated into magic.system.ts.
#guard Magic.elements.all fun e =>
  ((loadoutFor e).1.id, (loadoutFor e).2.id) = Magic.loadout e

/-- A combat choice: one of the four physical attacks, or one equipped technique. -/
inductive Strike where
  /-- A weapon attack, checked against the guard stance. -/
  | physical (attack : Combat.PhysicalAttack)
  /-- A spell from the equipped grimoire. -/
  | magic (technique : Technique)
  deriving Repr, DecidableEq, Inhabited

/-- The wire value of a combat choice, matching the `combat.attack` event literals. -/
def Strike.label : Strike → String
  | .physical a => a.label
  | .magic t => t.id

/-- The display name of a combat choice, matching the generated `ATTACK_LABELS`. -/
def Strike.title : Strike → String
  | .physical a => a.title
  | .magic t => t.spec.label

/-- Every combat choice the `combat.attack` validator accepts, in validator order. -/
def strikes : List Strike :=
  Combat.physicalAttacks.map Strike.physical ++ techniques.map Strike.magic

-- The strike alphabet is exactly the twelve literals in the combat.attack event data.
#guard strikes.map Strike.label =
  ["stab", "chargeHigh", "chargeSide", "leap", "emberBlast", "scorchArmor", "tideNeedle",
    "undertow", "galeBlade", "windShear", "stoneCrash", "calcify"]

/-- The five battle statistics a combatant brings into an exchange. -/
structure BattleStats where
  attack : Nat
  defense : Nat
  magic : Nat
  athletics : Nat
  agility : Nat
  deriving Repr, DecidableEq, Inhabited

/-- The hero's statistics inside a battle, after that battle's debuffs. -/
def playerStats (p : PlayerState) (c : CombatState) : BattleStats where
  attack := p.attack
  defense := p.defense - c.playerDefensePenalty
  magic := p.magic - c.playerMagicPenalty
  athletics := p.athletics - c.playerAthleticsPenalty
  agility := p.agility - c.playerAgilityPenalty

/-- The enemy's statistics inside a battle, after that battle's debuffs. -/
def enemyStats (c : CombatState) : BattleStats where
  attack := c.enemy.attack
  defense := c.enemy.defense - c.enemyDefensePenalty
  magic := c.enemy.magic - c.enemyMagicPenalty
  athletics := c.enemy.athletics - c.enemyAthleticsPenalty
  agility := c.enemy.agility - c.enemyAgilityPenalty

/-- Element advantage, mirroring the generated `elementMatchup`; no target means neutral. -/
def elementMatchup (element : Magic.Element) : Option Magic.Element → Combat.Matchup
  | none => .neutral
  | some target =>
      if Magic.strongAgainst element = target then .strong
      else if Magic.weakAgainst element = target then .weak
      else .neutral

/-- The matchup a strike faces: element advantage for spells, guard tables otherwise. -/
def matchupOf (s : Strike) (guard : Combat.Guard) (target : Option Magic.Element) :
    Combat.Matchup :=
  match s with
  | .physical a => Combat.physicalMatchup a guard
  | .magic t =>
      match t.spec.delivery with
      | .arcane => elementMatchup t.spec.element target
      | .impact kind => Combat.impactMatchup kind guard
      | .debuff => Combat.physicalMatchup .stab guard

/-- Whether a strike bypasses physical guarding, which decides resistance, brace and ward. -/
def Strike.isArcane (s : Strike) : Bool :=
  match s with
  | .physical _ => false
  | .magic t => t.spec.delivery = .arcane

/-- The attack power of a strike, in hundredths. -/
def Strike.powerHundredths : Strike → Nat
  | .physical a => Combat.physicalPower a
  | .magic t => t.spec.powerHundredths

/-- `Math.round` on a value expressed in millionths: floor of the value plus a half. -/
def roundMillionths (value : Nat) : Nat := (2 * value + 1000000) / 2000000

/-- The outcome of one exchange: the matchup shown, the hit chance, and the damage on a hit. -/
structure StrikeResult where
  /-- The matchup label echoed into the battle log. -/
  matchup : Combat.Matchup
  /-- Hit chance in basis points; the exchange lands when a draw from `10000` is below it. -/
  accuracy : Nat
  /-- Damage dealt when the exchange lands. Never zero: a landed hit always hurts. -/
  damage : Nat
  deriving Repr, DecidableEq

/--
The damage formula, exactly as the generated `strikeDamage` computes it.

The inner term is `attackValue * power + techniquePower - resistance - brace`, held
in hundredths: spells use magic against magic resistance, weapons use attack against
defense and add an athletics bonus unless the attack is the light `stab`, and a
`brace` stance subtracts a quarter of the defender's athletics. That term is then
scaled by the matchup percentage and, for arcane spells met by an arcane ward, by the
ward's power, and rounded once. A landed exchange always deals at least one damage.
-/
def strikeDamage (s : Strike) (guard : Combat.Guard) (attacker defender : BattleStats)
    (target : Option Magic.Element) (wardPowerHundredths : Nat) : StrikeResult :=
  let arcane := s.isArcane
  let matchup := matchupOf s guard target
  let attackValue := match s with | .physical _ => attacker.attack | .magic _ => attacker.magic
  let techniquePower : Nat :=
    match s with
    | .physical .stab => 0
    | .physical _ => attacker.athletics * 35
    | .magic _ => 0
  let resistance : Nat :=
    if arcane then defender.magic * 55 else defender.defense * 55
  let brace : Nat :=
    if !arcane && guard = Combat.Guard.brace then defender.athletics * 25 else 0
  let ward : Nat := if arcane && guard = Combat.Guard.ward then wardPowerHundredths else 100
  let gross := attackValue * s.powerHundredths + techniquePower
  let penalty := resistance + brace
  let accuracy : Nat :=
    if arcane then 10000
    else max 5000 (min 9800 (7500 + 400 * attacker.agility - 400 * defender.agility))
  { matchup, accuracy,
    damage :=
      if gross ≤ penalty then 1
      else max 1 (roundMillionths ((gross - penalty) * Combat.matchupMultiplier matchup * ward)) }

/-- The enemy guarding a combat node, mirroring the generated `enemyForSpace`. -/
def enemyForSpace (spaceId : NodeId) : Combat.Enemy :=
  Combat.enemies[spaceId % Combat.enemies.length]?.getD default

/-- The catalogue item a hero owns in a slot, if any. -/
def equippedItem (p : PlayerState) (slot : Inventory.EquipmentSlot) : Option Owned :=
  p.items.find? fun owned => owned.equippedSlot = some slot

/-- A catalogue entry by identifier, mirroring the generated `getItem`. -/
def itemById (id : Mythroads.ItemId) : Option Inventory.ItemDefinition :=
  Inventory.itemDefinitions.find? fun item => item.id = id

/-- The element of the equipped grimoire, defaulting to fire exactly as `equippedMagic` does. -/
def equippedSpell (p : PlayerState) : Magic.Element :=
  match equippedItem p .offensiveMagic with
  | none => .fire
  | some owned => match itemById owned.itemId with
    | none => .fire
    | some item => item.spell.getD .fire

/-- The techniques the equipped grimoire grants. -/
def equippedActions (p : PlayerState) : Technique × Technique := loadoutFor (equippedSpell p)

/-- Ward strength in hundredths, defaulting to the Aegis Script's `0.35`. -/
def equippedWardPower (p : PlayerState) : Nat :=
  match equippedItem p .defensiveMagic with
  | none => 35
  | some owned => match itemById owned.itemId with
    | none => 35
    | some item => item.wardPowerHundredths.getD 35

/-- A hero may only cast the two techniques on the grimoire they have equipped. -/
def canCast (p : PlayerState) : Strike → Bool
  | .physical _ => true
  | .magic t => t = (equippedActions p).1 || t = (equippedActions p).2

end Mythroads.Engine
