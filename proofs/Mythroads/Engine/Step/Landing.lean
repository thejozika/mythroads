import Mythroads.Engine.Event

/-!
# Landing: what the space a hero stopped on does

`resolveLanding` is the fork where the board's five space kinds become five phases.
It is deliberately *not* an event: no client can request it, it only ever runs as the
tail of a committed `movement.step`, which is why it takes the hero and destination as
arguments rather than re-reading them from the phase.

The encounter wheel is spun here, not when the encounter is acknowledged. That is what
makes `encounter.resolve` a pure application of an already-drawn outcome, and it is why
the drawn outcome and its wheel index are carried in `Phase.encounter`: the animation
the player watches and the deltas the rules apply come from the same draw.
-/

namespace Mythroads.Engine.Landing

open Mythroads.Game

/-- Pick the outcome the cursor lands on by walking the weighted list, as the wheel does. -/
def pickAt : List Encounter.Outcome → Nat → Option Encounter.Outcome
  | [], _ => none
  | outcome :: rest, cursor =>
      if cursor < outcome.weight then some outcome else pickAt rest (cursor - outcome.weight)

/-- The outcome a weighted roll selects, mirroring the generated `pickEncounter`. -/
def pickEncounter (kind : Encounter.Kind) (roll : Nat) : Encounter.Outcome :=
  let choices := Encounter.outcomesFor kind
  let cursor := min roll (Encounter.totalWeight kind - 1)
  (pickAt choices cursor).getD (choices.getLast?.getD default)

/-- Where the selected outcome sits in its wheel, which the client animates to. -/
def wheelIndexOf (kind : Encounter.Kind) (outcome : Encounter.Outcome) : Nat :=
  (Encounter.outcomesFor kind).findIdx fun candidate => candidate.id = outcome.id

/-- Open a battle against the enemy that guards this combat space. -/
def startCombat (s : State) (p : PlayerState) (spaceId : NodeId) : Outcome :=
  let enemy := enemyForSpace spaceId
  let battle : CombatState :=
    { playerId := p.id, spaceId, enemy, enemyHp := enemy.hp,
      message := "Choose how to attack the " ++ enemy.name ++ "." }
  .ok (s.withPhase (.combat battle .attackerChoice)
        (p.name ++ " faces a " ++ enemy.name ++ "!"),
       [.persistCombat battle .attackerChoice, .persistRoom, .appendLog "landing.combat"])

/-- Spin the event wheel, storing the drawn outcome for `encounter.resolve` to apply. -/
def startEvent (s : State) (p : PlayerState) (spaceId : NodeId) : Outcome :=
  let drawn := s.draw (Encounter.totalWeight .event)
  let outcome := pickEncounter .event drawn.1
  let revealed : EncounterState :=
    { playerId := p.id, spaceId, kind := .event, outcome,
      wheelIndex := wheelIndexOf .event outcome }
  .ok (drawn.2.withPhase (.encounter revealed) (p.name ++ " spins the event wheel!"),
       [.persistEncounter revealed, .persistRoom, .appendLog "landing.event"])

/--
Resolve the space a hero has just stopped on, given that space's node.

Shops and battles and events each open their own phase and keep the turn; the castle
heals to full and passes the turn; anything else simply passes the turn.
-/
def resolveOn (s : State) (p : PlayerState) (destination : NodeId) (landed : World.Node) :
    Outcome :=
  match shopKindOf landed.kind with
  | some kind =>
      .ok (s.withPhase (.shop kind) (p.name ++ " entered the " ++ landed.label ++ "."),
           [.persistRoom, .appendLog "landing.shop"])
  | none =>
      match landed.kind with
      | .combat => startCombat s p destination
      | .event => startEvent s p destination
      | .castle =>
          .ok ((s.mapPlayer p.id fun q => { q with hp := q.maxHp }).advanceTurn
                (p.name ++ " rested at Hearthkeep and recovered all health."),
               [.persistPlayer p.id, .persistRoom, .appendLog "landing.castle"])
      | _ =>
          .ok (s.advanceTurn (p.name ++ " completed the journey."),
               [.persistRoom, .appendLog "landing.done"])

/-- Resolve the space a hero has just stopped on. -/
def resolveLanding (s : State) (p : PlayerState) (destination : NodeId) : Outcome :=
  resolveOn s p destination (node destination)

end Mythroads.Engine.Landing
