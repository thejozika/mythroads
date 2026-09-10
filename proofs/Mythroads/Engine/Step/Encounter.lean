import Mythroads.Engine.Event

/-!
# Encounter resolution

The wheel was already spun when the hero landed (see `Mythroads.Engine.Landing`), so
this transition is a pure application of an outcome the state already holds. That
split is deliberate: the animation the player watches and the numbers the rules apply
can never disagree, and acknowledging an encounter draws no randomness at all.

Both deltas are clamped, and the clamps differ. Gold floors at zero, so a toll can
never put a hero into debt. Health floors at **one** and ceils at `maxHp`, so a thorn
patch never kills — dying is something only a battle can do.

One guard is *not* modelled: the generated `resolveEncounter` also refuses within
2200 ms of the reveal, so the wheel finishes spinning before the deltas land. That is
a wall-clock check and has no place in a deterministic replayable rule; the boundary
keeps enforcing it.
-/

namespace Mythroads.Engine.Encounters

open Mythroads.Game

/-- Render a signed delta the way the banner does, with an explicit `+` for gains. -/
def signed (value : Int) : String := if 0 < value then "+" ++ toString value else toString value

/-- The parenthesised effect summary, omitted entirely when nothing changed. -/
def summary (outcome : Encounter.Outcome) : String :=
  let parts :=
    (if outcome.goldDelta = 0 then [] else [signed outcome.goldDelta ++ " gold"]) ++
    (if outcome.hpDelta = 0 then [] else [signed outcome.hpDelta ++ " health"])
  match parts with
  | [] => "."
  | first :: rest => " (" ++ rest.foldl (fun acc part => acc ++ ", " ++ part) first ++ ")."

/-- Health after an encounter delta: never above the maximum, never below one. -/
def survivedHp (p : PlayerState) (delta : Int) : Nat :=
  min p.maxHp (max 1 (applyDelta p.hp delta))

/-- `encounter.resolve`: apply the drawn deltas, mark the wheel spent, and pass the turn. -/
def resolve (s : State) (p : PlayerState) (drawn : EncounterState) : Outcome :=
  .ok ((s.mapPlayer p.id fun q =>
          { q with gold := applyDelta q.gold drawn.outcome.goldDelta,
                   hp := survivedHp q drawn.outcome.hpDelta }).withPhase
          (.encounter { drawn with resolved := true }) s.message
        |>.advanceTurn
          (p.name ++ ": " ++ drawn.outcome.title ++ summary drawn.outcome),
       [.persistPlayer p.id, .persistEncounter, .persistRoom, .appendLog "encounter.resolve"])

end Mythroads.Engine.Encounters
