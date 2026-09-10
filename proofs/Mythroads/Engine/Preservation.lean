import Mythroads.Engine.Invariant

/-!
# One invariant lemma per transition

`Mythroads.Engine.Invariant` proves the invariant for the two mutation primitives.
This module spends that work: every per-phase module function gets exactly one small
lemma, each of which unfolds the function, splits its branches, and hands each branch
to `ok_congr`, `ok_mapPlayer` or `ok_advanceTurn`.

The lemmas are separate on purpose. `ok_transition` in `Mythroads.Engine.Theorems`
consumes them one dispatch arm at a time, so an event added without its lemma leaves a
hole the compiler reports rather than a silently weaker theorem.
-/

namespace Mythroads.Engine

/-! ## Lobby -/

/-- Creating a room empties the hero list and parks the cursor at zero. -/
theorem ok_create {s s' : State} {actor : Mythroads.AuthId} {seed : Nat} {fx : List Effect}
    (h : Lobby.create s actor seed = .ok (s', fx)) : Ok s' := by
  simp only [Lobby.create, Except.ok.injEq, Prod.mk.injEq] at h
  obtain ⟨rfl, -⟩ := h
  exact ⟨by simp, by simp⟩

/-- Seating a hero appends one hero at full health and keeps the cursor in range. -/
theorem ok_joinAs {s s' : State} {actor : Mythroads.AuthId} {hero color : String}
    {fx : List Effect} (ok : Ok s) (h : Lobby.joinAs s actor hero color = .ok (s', fx)) : Ok s' := by
  simp only [Lobby.joinAs] at h
  split at h
  · simp only [Except.ok.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, -⟩ := h
    exact ok
  · split at h
    · split at h
      · exact absurd h (by simp)
      · split at h
        · exact absurd h (by simp)
        · simp only [Except.ok.injEq, Prod.mk.injEq] at h
          obtain ⟨rfl, -⟩ := h
          refine ok_mapPlayer ok ?_; exact fun _ hq => hq
    · split at h
      · exact absurd h (by simp)
      · split at h
        · exact absurd h (by simp)
        · simp only [Except.ok.injEq, Prod.mk.injEq] at h
          obtain ⟨rfl, -⟩ := h
          refine ⟨?_, ?_⟩
          · intro p hp
            simp only [List.mem_append, List.mem_cons, List.not_mem_nil, or_false] at hp
            cases hp with
            | inl seated => exact ok.heroes p seated
            | inr fresh => subst fresh; simp [Lobby.freshPlayer]
          · have := ok.turnInRange
            simp only [List.length_append, List.length_cons, List.length_nil]
            omega

/-- Joining preserves the invariant. -/
theorem ok_join {s s' : State} {actor : Mythroads.AuthId} {name color : String} {fx : List Effect}
    (ok : Ok s) (h : Lobby.join s actor name color = .ok (s', fx)) : Ok s' := by
  simp only [Lobby.join] at h
  split at h
  · exact absurd h (by simp)
  · exact ok_joinAs ok h

/-- Starting the adventure only moves the cursor to the first hero. -/
theorem ok_start {s s' : State} {fx : List Effect} (ok : Ok s)
    (h : Lobby.start s = .ok (s', fx)) : Ok s' := by
  simp only [Lobby.start] at h
  split at h
  · exact absurd h (by simp)
  · simp only [Except.ok.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, -⟩ := h
    exact ⟨ok.heroes, Nat.lt_of_lt_of_le Nat.zero_lt_one (Nat.le_max_left 1 _)⟩

/-! ## Movement -/

/-- Rolling dice only advances the generator, so the hero list is untouched. -/
theorem rollDice_players (dice : List Nat) (s : State) :
    (Movement.rollDice s dice).2.players = s.players := by
  induction dice generalizing s with
  | nil => rfl
  | cons sides rest ih => simp only [Movement.rollDice]; exact ih (s.draw sides).2

/-- Rolling dice does not move the turn cursor. -/
theorem rollDice_turn (dice : List Nat) (s : State) :
    (Movement.rollDice s dice).2.turn = s.turn := by
  induction dice generalizing s with
  | nil => rfl
  | cons sides rest ih => simp only [Movement.rollDice]; exact ih (s.draw sides).2

/-- Rolling preserves the invariant. -/
theorem ok_rollDice {s : State} (ok : Ok s) (dice : List Nat) : Ok (Movement.rollDice s dice).2 :=
  ok_congr ok (rollDice_players dice s) (rollDice_turn dice s)

/-- `movement.roll` only rewrites one hero's memory of where they came from. -/
theorem ok_roll {s s' : State} {p : PlayerState} {fx : List Effect} (ok : Ok s)
    (h : Movement.roll s p = .ok (s', fx)) : Ok s' := by
  simp only [Movement.roll, Except.ok.injEq, Prod.mk.injEq] at h
  obtain ⟨rfl, -⟩ := h
  refine ok_congr (ok_mapPlayer (ok_rollDice ok p.dice) ?_) rfl rfl
  exact fun _ hq => hq

/-- Planning a route only changes the phase. -/
theorem ok_select {s s' : State} {p : PlayerState} {moves : Nat} {sel : Option Selection}
    {d : NodeId} {fx : List Effect} (ok : Ok s)
    (h : Movement.select s p moves sel d = .ok (s', fx)) : Ok s' := by
  simp only [Movement.select] at h
  split at h
  · split at h
    · exact absurd h (by simp)
    · simp only [Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, -⟩ := h
      exact ok_congr ok rfl rfl
  · split at h
    · exact absurd h (by simp)
    · simp only [Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, -⟩ := h
      exact ok_congr ok rfl rfl

/-- Cancelling a route only changes the phase. -/
theorem ok_cancel {s s' : State} {moves : Nat} {fx : List Effect} (ok : Ok s)
    (h : Movement.cancel s moves = .ok (s', fx)) : Ok s' := by
  simp only [Movement.cancel, Except.ok.injEq, Prod.mk.injEq] at h
  obtain ⟨rfl, -⟩ := h
  exact ok_congr ok rfl rfl

/-! ## Landing -/
/-- Every landing either changes the phase, or heals a hero to full and passes the turn. -/
theorem ok_resolveOn {s s' : State} {p : PlayerState} {d : NodeId} {landed : Game.World.Node}
    {fx : List Effect} (ok : Ok s) (h : Landing.resolveOn s p d landed = .ok (s', fx)) :
    Ok s' := by
  simp only [Landing.resolveOn] at h
  split at h
  · simp only [Except.ok.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, -⟩ := h
    exact ok_congr ok rfl rfl
  · split at h
    · simp only [Landing.startCombat, Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, -⟩ := h
      exact ok_congr ok rfl rfl
    · simp only [Landing.startEvent, Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, -⟩ := h
      exact ok_congr ok rfl rfl
    · simp only [Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, -⟩ := h
      refine ok_advanceTurn (ok_mapPlayer ok ?_) _
      exact fun q _ => Nat.le_refl q.maxHp
    · simp only [Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, -⟩ := h
      exact ok_advanceTurn ok _

/-- Landing on a node preserves the invariant. -/
theorem ok_resolveLanding {s s' : State} {p : PlayerState} {d : NodeId} {fx : List Effect}
    (ok : Ok s) (h : Landing.resolveLanding s p d = .ok (s', fx)) : Ok s' := ok_resolveOn ok h

/-- Committing a route moves one hero and then resolves the space they stopped on. -/
theorem ok_stepMove {s s' : State} {p : PlayerState} {moves : Nat} {sel : Option Selection}
    {d : NodeId} {fx : List Effect} (ok : Ok s)
    (h : Movement.stepMove s p moves sel d = .ok (s', fx)) : Ok s' := by
  simp only [Movement.stepMove] at h
  split at h
  · exact absurd h (by simp)
  · split at h
    · exact absurd h (by simp)
    · split at h
      · exact absurd h (by simp)
      · rename_i landing
        simp only [Except.ok.injEq, Prod.mk.injEq] at h
        obtain ⟨rfl, -⟩ := h
        refine ok_resolveLanding (ok_mapPlayer ok ?_) landing
        exact fun _ hq => hq

/-! ## Battle -/
/-- Striking either logs an exchange, or fells the enemy and passes the turn. -/
theorem ok_attack {s s' : State} {p : PlayerState} {b : CombatState} {c : Strike}
    {fx : List Effect} (ok : Ok s) (h : Battle.attack s p b c = .ok (s', fx)) : Ok s' := by
  simp only [Battle.attack] at h
  split at h
  · exact absurd h (by simp)
  · split at h
    · simp only [Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, -⟩ := h
      exact ok_congr ok rfl rfl
    · split at h
      · simp only [Except.ok.injEq, Prod.mk.injEq] at h
        obtain ⟨rfl, -⟩ := h
        refine ok_advanceTurn (ok_withPhase (ok_mapPlayer (ok_congr ok ?_ ?_) ?_) _ _) _
        · rfl
        · rfl
        · exact fun _ hq => hq
      · simp only [Except.ok.injEq, Prod.mk.injEq] at h
        obtain ⟨rfl, -⟩ := h
        exact ok_congr ok rfl rfl

/-- Defeat restores the hero to full health before passing the turn. -/
theorem ok_defeat {s s' : State} {p : PlayerState} {b : CombatState} {fx : List Effect}
    (ok : Ok s) (h : Battle.defeat s p b = .ok (s', fx)) : Ok s' := by
  simp only [Battle.defeat, Except.ok.injEq, Prod.mk.injEq] at h
  obtain ⟨rfl, -⟩ := h
  refine ok_advanceTurn (ok_mapPlayer ok ?_) _
  exact fun q _ => Nat.le_refl q.maxHp

/-- Guarding either takes damage, which only lowers health, or falls and is restored. -/
theorem ok_guard {s s' : State} {p : PlayerState} {b : CombatState} {g : Game.Combat.Guard}
    {fx : List Effect} (ok : Ok s) (h : Battle.guard s p b g = .ok (s', fx)) : Ok s' := by
  simp only [Battle.guard] at h
  split at h
  · simp only [Except.ok.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, -⟩ := h
    exact ok_congr ok rfl rfl
  · split at h
    · refine ok_defeat (ok_withPhase (ok_congr ok ?_ ?_) _ _) h
      · rfl
      · rfl
    · simp only [Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, -⟩ := h
      refine ok_withPhase (ok_mapPlayer (ok_congr ok ?_ ?_) ?_) _ _
      · rfl
      · rfl
      · exact fun q hq => damaged_bounded q _ hq

/-! ## Encounter, shop and camera -/
/-- Encounter deltas are clamped into the health bound by construction. -/
theorem ok_resolveEncounter {s s' : State} {p : PlayerState} {e : EncounterState}
    {fx : List Effect} (ok : Ok s) (h : Encounters.resolve s p e = .ok (s', fx)) : Ok s' := by
  simp only [Encounters.resolve, Except.ok.injEq, Prod.mk.injEq] at h
  obtain ⟨rfl, -⟩ := h
  refine ok_advanceTurn (ok_withPhase (ok_mapPlayer ok ?_) _ _) _
  exact fun q _ => Nat.min_le_left q.maxHp _

/-- Buying spends gold and grows an inventory; health is untouched. -/
theorem ok_buy {s s' : State} {p : PlayerState} {k : Game.Inventory.ShopKind}
    {itemId : Mythroads.ItemId} {fx : List Effect} (ok : Ok s)
    (h : Shop.buy s p k itemId = .ok (s', fx)) : Ok s' := by
  simp only [Shop.buy] at h
  split at h
  · exact absurd h (by simp)
  · split at h
    · exact absurd h (by simp)
    · split at h
      · exact absurd h (by simp)
      · simp only [Except.ok.injEq, Prod.mk.injEq] at h
        obtain ⟨rfl, -⟩ := h
        refine ok_mapPlayer ok ?_; exact fun _ hq => hq

/-- Leaving a shop passes the turn. -/
theorem ok_leave {s s' : State} {p : PlayerState} {fx : List Effect} (ok : Ok s)
    (h : Shop.leave s p = .ok (s', fx)) : Ok s' := by
  simp only [Shop.leave, Except.ok.injEq, Prod.mk.injEq] at h
  obtain ⟨rfl, -⟩ := h
  exact ok_advanceTurn ok _

/-- Equipping only moves items between slots. -/
theorem ok_equip {s s' : State} {actor : Mythroads.AuthId} {p : PlayerState}
    {row : OwnedItemId} {slot : Game.Inventory.EquipmentSlot} {fx : List Effect} (ok : Ok s)
    (h : Shop.equip s actor p row slot = .ok (s', fx)) : Ok s' := by
  simp only [Shop.equip] at h
  split at h
  · exact absurd h (by simp)
  · exact absurd h (by simp)
  · simp only [Except.ok.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, -⟩ := h
    refine ok_mapPlayer ok ?_; exact fun _ hq => hq

/-- Toggling the camera touches only the ephemeral projection. -/
theorem ok_cameraToggle {s s' : State} {p : PlayerState} {fx : List Effect} (ok : Ok s)
    (h : CameraStep.toggle s p = .ok (s', fx)) : Ok s' := by
  simp only [CameraStep.toggle, Except.ok.injEq, Prod.mk.injEq] at h
  obtain ⟨rfl, -⟩ := h
  exact ok_congr ok rfl rfl

/-- Panning the camera touches only the ephemeral projection. -/
theorem ok_cameraMove {s s' : State} {d : Direction} {fx : List Effect} (ok : Ok s)
    (h : CameraStep.move s d = .ok (s', fx)) : Ok s' := by
  simp only [CameraStep.move] at h
  split at h
  · split at h
    · exact absurd h (by simp)
    · simp only [Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, -⟩ := h
      exact ok_congr ok rfl rfl
  · exact absurd h (by simp)

/-- Zooming the camera touches only the ephemeral projection. -/
theorem ok_cameraZoom {s s' : State} {d : Zoom} {fx : List Effect} (ok : Ok s)
    (h : CameraStep.zoom s d = .ok (s', fx)) : Ok s' := by
  simp only [CameraStep.zoom] at h
  split at h
  · split at h
    · exact absurd h (by simp)
    · simp only [Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, -⟩ := h
      exact ok_congr ok rfl rfl
  · exact absurd h (by simp)

end Mythroads.Engine
