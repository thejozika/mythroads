import Mythroads.Engine.Replay

/-!
# The room invariant, and the lemmas that make it cheap

`Ok` is the safety property every reachable room satisfies: no hero is over-healed, and
the turn cursor names a real hero whenever the room has any. Two more safety properties
are *free* and therefore absent from `Ok`: gold is a `Nat`, so it cannot go negative,
and hero identity is preserved because every rewrite goes through `State.mapPlayer`.

The proof strategy is the point of this file. Everything a transition can do to the
room is one of three shapes:

* it changes nothing about the hero list or cursor (`ok_congr`);
* it rewrites one hero (`ok_mapPlayer`, plus a one-line side condition on that rewrite);
* it passes the turn (`ok_advanceTurn`).

So each per-phase module needs exactly one small lemma, and the dispatcher proof in
`Mythroads.Engine.Theorems` is a mechanical `split` with one arm per transition. Adding
an event whose lemma is missing does not silently weaken the theorem — it fails to
compile.
-/

namespace Mythroads.Engine

/--
The room safety invariant. Gold non-negativity is free, because `gold : Nat`.

`turnInRange` is stated against `max 1` rather than the bare length so that it also
pins the cursor of an *empty* lobby to zero. Without that, a room could sit at turn
three with nobody seated and the first hero to join would arrive out of range; with
it, seating a hero is a one-line `omega`.
-/
structure Ok (s : State) : Prop where
  /-- No hero is ever over-healed. -/
  heroes : ∀ p ∈ s.players, p.hp ≤ p.maxHp
  /-- The turn cursor names a real hero, and rests at zero while the room is empty. -/
  turnInRange : s.turn < max 1 s.players.length

/-- A non-empty hero list has positive length. -/
theorem length_pos_of_ne_nil {α : Type} {l : List α} (h : l ≠ []) : 0 < l.length := by
  cases l with
  | nil => exact absurd rfl h
  | cons _ _ => exact Nat.succ_pos _

/-- Anything that leaves the hero list and the cursor alone preserves the invariant. -/
theorem ok_congr {s s' : State} (ok : Ok s) (players : s'.players = s.players)
    (turn : s'.turn = s.turn) : Ok s' := by
  refine ⟨?_, ?_⟩
  · rw [players]; exact ok.heroes
  · rw [players, turn]; exact ok.turnInRange

/-- The invariant only reads the hero list and the cursor. -/
theorem ok_of {s : State} (heroes : ∀ p ∈ s.players, p.hp ≤ p.maxHp)
    (turn : s.turn < max 1 s.players.length) : Ok s := ⟨heroes, turn⟩

/-- Rewriting one hero leaves the list length alone, which is why the cursor stays valid. -/
theorem mapPlayer_length (s : State) (pid : Mythroads.PlayerId) (f : PlayerState → PlayerState) :
    (s.mapPlayer pid f).players.length = s.players.length := by
  simp [State.mapPlayer]

/-- **Primitive lemma 1.** A per-hero rewrite preserves `Ok` if it preserves the hero bound. -/
theorem ok_mapPlayer {s : State} {pid : Mythroads.PlayerId} {f : PlayerState → PlayerState}
    (ok : Ok s) (hf : ∀ p, p.hp ≤ p.maxHp → (f p).hp ≤ (f p).maxHp) :
    Ok (s.mapPlayer pid f) := by
  refine ⟨?_, ?_⟩
  · intro p hp
    simp only [State.mapPlayer, List.mem_map] at hp
    obtain ⟨q, hq, rfl⟩ := hp
    by_cases hid : q.id = pid
    · simpa [hid] using hf q (ok.heroes q hq)
    · simpa [hid] using ok.heroes q hq
  · rw [mapPlayer_length]
    exact ok.turnInRange

/-- **Primitive lemma 2.** Passing the turn preserves `Ok`; the modulus keeps the cursor in range. -/
theorem ok_advanceTurn {s : State} (ok : Ok s) (message : String) :
    Ok (s.advanceTurn message) := by
  unfold State.advanceTurn
  split
  · rename_i h
    refine ⟨ok.heroes, ?_⟩
    have := Game.Turn.nextIndexIsValid s.turn s.players.length h
    simp only []
    omega
  · exact ok

/-- Changing the phase and banner preserves `Ok`. -/
theorem ok_withPhase {s : State} (ok : Ok s) (phase : Phase) (message : String) :
    Ok (s.withPhase phase message) := ok_congr ok rfl rfl

/-- Taking a draw from the room generator preserves `Ok`. -/
theorem ok_draw {s : State} (ok : Ok s) (bound : Nat) : Ok (s.draw bound).2 :=
  ok_congr ok rfl rfl

/-! ## Side conditions for the per-hero rewrites the rules perform -/

/-- Damage only lowers health, so the bound survives. -/
theorem damaged_bounded (p : PlayerState) (n : Nat) (h : p.hp ≤ p.maxHp) :
    (p.damaged n).hp ≤ (p.damaged n).maxHp :=
  Nat.le_trans (Nat.sub_le _ _) h

/-- Spending gold does not touch health. -/
theorem spent_bounded (p : PlayerState) (n : Nat) (h : p.hp ≤ p.maxHp) :
    (p.spent n).hp ≤ (p.spent n).maxHp := h

/-- Healing to full lands exactly on the bound. -/
theorem restored_bounded (p : PlayerState) : ({ p with hp := p.maxHp } : PlayerState).hp ≤
    ({ p with hp := p.maxHp } : PlayerState).maxHp := Nat.le_refl _


end Mythroads.Engine
