import Mythroads.Engine.Event

/-!
# Battle transitions

One battle round is two envelopes. The hero picks a strike (`combat.attack`) against a
guard the *room generator* chooses for the enemy; then the hero picks a stance
(`combat.guard`) against a strike the generator chooses for the enemy. `CombatStage`
records which half is owed, so the phase alone decides which event is accepted and no
handler has to re-check whose turn within the battle it is.

Two shapes of exchange share the pipeline. A **damaging** strike draws a guard (or an
attack), evaluates `strikeDamage`, draws a hit roll from `10000` and subtracts. A
**debuff** strike draws no hit roll at all: it either lands, deepening a per-battle stat
penalty, or is nullified outright by an arcane ward. Every penalty is a `max` against
the penalty already standing, so debuffs never stack past their own strength.

Defeat is not elimination. The hero wakes at Hearthkeep at full health, three gold
lighter at most, and the turn passes.
-/

namespace Mythroads.Engine.Battle

open Mythroads.Game

/-- Deepen one per-battle stat penalty, never weakening a penalty already standing. -/
def debuffEnemy (c : CombatState) (stat : Magic.DebuffStat) (amount : Nat) : CombatState :=
  match stat with
  | .defense => { c with enemyDefensePenalty := max c.enemyDefensePenalty amount }
  | .magic => { c with enemyMagicPenalty := max c.enemyMagicPenalty amount }
  | .athletics => { c with enemyAthleticsPenalty := max c.enemyAthleticsPenalty amount }
  | .agility => { c with enemyAgilityPenalty := max c.enemyAgilityPenalty amount }

/-- The same, applied to the hero's side of the battle. -/
def debuffPlayer (c : CombatState) (stat : Magic.DebuffStat) (amount : Nat) : CombatState :=
  match stat with
  | .defense => { c with playerDefensePenalty := max c.playerDefensePenalty amount }
  | .magic => { c with playerMagicPenalty := max c.playerMagicPenalty amount }
  | .athletics => { c with playerAthleticsPenalty := max c.playerAthleticsPenalty amount }
  | .agility => { c with playerAgilityPenalty := max c.playerAgilityPenalty amount }

/-- The debuff a strike carries, if it is a hex rather than a blow. -/
def debuffOf : Strike → Option Magic.Debuff
  | .physical _ => none
  | .magic t => match t.spec.delivery with
    | .debuff => t.spec.debuff
    | _ => none

/-- Record the exchange the client replays in the battle log. -/
def echo (c : CombatState) (s : Strike) (g : Combat.Guard) (damage : Nat) (message : String) :
    CombatState :=
  { c with lastAttack := some s.label, lastGuard := some g, lastDamage := some damage, message }

/-- The battle-log line for a landed or missed blow. -/
def blowMessage (prefix' : String) (s : Strike) (g : Combat.Guard) (result : StrikeResult)
    (damage : Nat) : String :=
  if damage = 0 then prefix' ++ s.title ++ " missed!"
  else prefix' ++ s.title ++ " met " ++ g.title ++ ": " ++ result.matchup.label ++ ", " ++
    toString damage ++ " damage."

/-- The enemy's guard for this exchange, drawn from the room generator. -/
def drawGuard (s : State) : Combat.Guard × State :=
  let drawn := s.draw Combat.guards.length
  ((Combat.guards[drawn.1]?.getD .high), drawn.2)

/-- The strikes an enemy of this element can choose from: four blows plus its grimoire. -/
def enemyStrikes (element : Magic.Element) : List Strike :=
  Combat.physicalAttacks.map Strike.physical ++
    [Strike.magic (loadoutFor element).1, Strike.magic (loadoutFor element).2]

/-- The enemy's strike for this exchange, drawn from the room generator. -/
def drawStrike (s : State) (element : Magic.Element) : Strike × State :=
  let options := enemyStrikes element
  let drawn := s.draw options.length
  ((options[drawn.1]?.getD (.physical .stab)), drawn.2)

/-- Roll the hit check: an exchange lands when a draw from `10000` is under the accuracy. -/
def drawHit (s : State) (result : StrikeResult) : Nat × State :=
  let drawn := s.draw 10000
  (if drawn.1 < result.accuracy then result.damage else 0, drawn.2)

/--
`combat.attack`: the hero strikes, and then owes a guard unless the enemy fell.

A hex is resolved without a hit roll; a blow subtracts its damage and, if that empties
the enemy, pays the bounty and passes the turn.
-/
def attack (s : State) (p : PlayerState) (battle : CombatState) (choice : Strike) : Outcome :=
  if !canCast p choice then .error .techniqueNotEquipped
  else
    let drawn := drawGuard s
    let guard := drawn.1
    match debuffOf choice with
    | some hex =>
        let blocked := guard = Combat.Guard.ward
        let hexed := if blocked then battle else debuffEnemy battle hex.stat hex.amount
        let logged := echo hexed choice guard 0
          (if blocked then guard.title ++ " nullified " ++ choice.title ++ "."
           else choice.title ++ " lowered the enemy's " ++ hex.stat.label ++ ".")
        .ok (drawn.2.withPhase (.combat logged .defenderChoice)
              (battle.enemy.name ++ " prepares a counterattack. Choose a guard."),
             [.persistCombat, .persistRoom, .appendLog "combat.attack"])
    | none =>
        let result := strikeDamage choice guard (playerStats p battle) (enemyStats battle)
          (some battle.enemy.element) 35
        let hit := drawHit drawn.2 result
        let damage := hit.1
        let enemyHp := battle.enemyHp - damage
        let logged := echo { battle with enemyHp } choice guard damage
          (blowMessage "" choice guard result damage)
        if enemyHp = 0 then
          .ok (((hit.2.mapPlayer p.id fun q => { q with gold := q.gold + battle.enemy.reward })
                 |>.withPhase (.combat logged .resolved) "").advanceTurn
                (p.name ++ " defeated " ++ battle.enemy.name ++ " and won " ++
                  toString battle.enemy.reward ++ " gold."),
               [.persistCombat, .persistPlayer p.id, .persistRoom, .appendLog "combat.attack"])
        else
          .ok (hit.2.withPhase (.combat logged .defenderChoice)
                (battle.enemy.name ++ " prepares a counterattack. Choose a guard."),
               [.persistCombat, .persistRoom, .appendLog "combat.attack"])

/-- Defeat: full health, up to three gold lost, back to Hearthkeep, and the turn passes. -/
def defeat (s : State) (p : PlayerState) (battle : CombatState) : Outcome :=
  let loss := min 3 p.gold
  .ok ((s.mapPlayer p.id fun q =>
          { q with hp := q.maxHp, gold := q.gold - loss, position := 0,
                   previousPosition := none }).advanceTurn
        (p.name ++ " fell to " ++ battle.enemy.name ++ " and awoke at Hearthkeep, losing " ++
          toString loss ++ " gold."),
       [.persistCombat, .persistPlayer p.id, .persistRoom, .appendLog "combat.guard"])

/--
`combat.guard`: the enemy replies and the hero either survives into the next round or
falls. The hero's equipped ward decides how much an arcane blow is blunted.
-/
def guard (s : State) (p : PlayerState) (battle : CombatState) (stance : Combat.Guard) :
    Outcome :=
  let drawn := drawStrike s battle.enemy.element
  let choice := drawn.1
  match debuffOf choice with
  | some hex =>
      let blocked := stance = Combat.Guard.ward
      let hexed := if blocked then battle else debuffPlayer battle hex.stat hex.amount
      let logged := echo { hexed with round := battle.round + 1 } choice stance 0
        (if blocked then p.name ++ "'s " ++ stance.title ++ " nullified " ++ choice.title ++ "."
         else battle.enemy.name ++ "'s " ++ choice.title ++ " lowered " ++ p.name ++ "'s " ++
           hex.stat.label ++ ".")
      .ok (drawn.2.withPhase (.combat logged .attackerChoice)
            (if blocked then p.name ++ " resisted the hex. Choose another attack."
             else p.name ++ " was weakened. Choose another attack."),
           [.persistCombat, .persistRoom, .appendLog "combat.guard"])
  | none =>
      let result := strikeDamage choice stance (enemyStats battle) (playerStats p battle) none
        (equippedWardPower p)
      let hit := drawHit drawn.2 result
      let damage := hit.1
      let hp := p.hp - damage
      let logged := echo { battle with round := battle.round + 1 } choice stance damage
        (blowMessage (battle.enemy.name ++ "'s ") choice stance result damage)
      if hp = 0 then
        defeat (hit.2.withPhase (.combat logged .resolved) "") p battle
      else
        .ok ((hit.2.mapPlayer p.id fun q => q.damaged damage).withPhase
              (.combat logged .attackerChoice)
              (p.name ++ " weathered the counterattack. Choose another attack."),
             [.persistCombat, .persistPlayer p.id, .persistRoom, .appendLog "combat.guard"])

end Mythroads.Engine.Battle
