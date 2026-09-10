import Mythroads.Engine.Preservation

/-!
# What is proved about the engine

Five families of theorem, all about the single `step` function.

* **Determinism** — `step` is a function, so equal inputs give equal outputs. The real
  content is in its *type*: it mentions no `IO`, no clock and no ambient generator, so
  there is nowhere for a hidden input to enter.
* **Authorization, turn and phase gates** — a successful `step` implies each of the
  three gates held. These are one-liners precisely because `step` is three `if`s in
  front of `transition`, and they are universally quantified over every state and every
  actor, which no test suite can be.
* **Phase safety** — statements about the finite `permitted` table alone, with no state
  involved: an attack is only ever accepted while the battle owes an attacker choice,
  a purchase only inside a shop, and so on.
* **Invariant preservation** — `Ok` survives `step` and therefore survives `replay`.
* **Camera events are ambient and ephemeral** — accepted in every phase, appended to no
  log, and unable to change the hero list at all.
-/

namespace Mythroads.Engine

/-! ## Determinism -/

/-- `step` is deterministic: the same room and envelope always give the same outcome. -/
theorem step_deterministic (s : State) (env : Envelope) {a b : Outcome}
    (first : step s env = a) (second : step s env = b) : a = b := by
  rw [← first, ← second]

/-! ## The three gates -/

/-- An actor without the required authority is always rejected, in every phase. -/
theorem unauthorized_rejected {s : State} {env : Envelope} (h : authorized s env = false) :
    step s env = .error .unauthorized := by
  simp [step, h]

/-- A hero acting out of turn is always rejected. -/
theorem offTurn_rejected {s : State} {env : Envelope} (auth : authorized s env = true)
    (h : onTurn s env = false) : step s env = .error .notYourTurn := by
  simp [step, auth, h]

/-- An event the phase does not accept is always rejected. -/
theorem unpermitted_rejected {s : State} {env : Envelope} (auth : authorized s env = true)
    (turn : onTurn s env = true) (h : permitted s.phase env.event = false) :
    step s env = .error .wrongPhase := by
  simp [step, auth, turn, h]

/-- A successful transition proves the actor held the authority the event demands. -/
theorem step_ok_authorized {s s' : State} {env : Envelope} {fx : List Effect}
    (h : step s env = .ok (s', fx)) : authorized s env = true := by
  by_cases ha : authorized s env
  · exact ha
  · simp [step, ha] at h

/-- A successful in-play transition proves it was the sender's hero's turn; lobby events and
`inventory.equip` are exempt from the turn gate and pass it trivially. -/
theorem step_ok_onTurn {s s' : State} {env : Envelope} {fx : List Effect}
    (h : step s env = .ok (s', fx)) : onTurn s env = true := by
  by_cases ht : onTurn s env
  · exact ht
  · by_cases ha : authorized s env <;> simp [step, ha, ht] at h

/-- A successful transition proves the current phase accepts the event. -/
theorem step_ok_permitted {s s' : State} {env : Envelope} {fx : List Effect}
    (h : step s env = .ok (s', fx)) : permitted s.phase env.event = true := by
  by_cases hp : permitted s.phase env.event
  · exact hp
  · by_cases ha : authorized s env <;> by_cases ht : onTurn s env <;>
      simp [step, ha, ht, hp] at h

/-! ## Phase safety

These are facts about the `permitted` table only. `Phase` carries `Nat` payloads and is
therefore not a finite type, so `decide` does not apply to the whole table; `cases` on
the phase is the tactic that scales.
-/

/-- `combat.attack` is accepted only while the battle owes an attacker choice. -/
theorem attack_only_in_attackerChoice (ph : Phase) (choice : Strike)
    (h : permitted ph (.combatAttack choice) = true) :
    ∃ battle, ph = .combat battle .attackerChoice := by
  cases ph with
  | combat battle stage =>
      cases stage with
      | attackerChoice => exact ⟨battle, rfl⟩
      | defenderChoice => simp [permitted] at h
      | resolved => simp [permitted] at h
  | _ => simp [permitted] at h

/-- `combat.guard` is accepted only while the battle owes a defender choice. -/
theorem guard_only_in_defenderChoice (ph : Phase) (stance : Game.Combat.Guard)
    (h : permitted ph (.combatGuard stance) = true) :
    ∃ battle, ph = .combat battle .defenderChoice := by
  cases ph with
  | combat battle stage =>
      cases stage with
      | attackerChoice => simp [permitted] at h
      | defenderChoice => exact ⟨battle, rfl⟩
      | resolved => simp [permitted] at h
  | _ => simp [permitted] at h

/-- A resolved battle accepts no further combat input; only the turn can move on. -/
theorem resolved_battle_is_closed (battle : CombatState) (choice : Strike)
    (stance : Game.Combat.Guard) :
    permitted (.combat battle .resolved) (.combatAttack choice) = false ∧
      permitted (.combat battle .resolved) (.combatGuard stance) = false :=
  ⟨rfl, rfl⟩

/-- `movement.roll` is accepted only when the active hero owes a roll. -/
theorem roll_only_when_awaiting (ph : Phase) (h : permitted ph .movementRoll = true) :
    ph = .awaitingRoll := by
  cases ph <;> first | rfl | simp [permitted] at h

/-- `shop.buy` is accepted only while standing in a shop. -/
theorem buy_only_in_shop (ph : Phase) (itemId : Mythroads.ItemId)
    (h : permitted ph (.shopBuy itemId) = true) : ∃ kind, ph = .shop kind := by
  cases ph with
  | shop kind => exact ⟨kind, rfl⟩
  | _ => simp [permitted] at h

/-- Outside the lobby `game.start` changes nothing: a resent start is an idempotent no-op. -/
theorem start_outside_lobby_is_noop {s : State} (h : s.phase ≠ Phase.lobby) :
    Lobby.start s = .ok (s, [.appendLog "game.start"]) := by
  simp [Lobby.start, h]

/-- Camera commands are accepted in every phase and are never durable. -/
theorem camera_is_ambient_and_ephemeral (ph : Phase) (direction : Direction) (delta : Zoom) :
    permitted ph .cameraToggle = true ∧ permitted ph (.cameraMove direction) = true ∧
      permitted ph (.cameraZoom delta) = true ∧ Event.durable .cameraToggle = false ∧
      Event.durable (.cameraMove direction) = false ∧
      Event.durable (.cameraZoom delta) = false := by
  cases ph <;> exact ⟨rfl, rfl, rfl, rfl, rfl, rfl⟩

/-- Equipping is accepted in every phase, because the boundary only owner-checks it. -/
theorem equip_is_ambient (ph : Phase) (row : OwnedItemId) (slot : Game.Inventory.EquipmentSlot) :
    permitted ph (.inventoryEquip row slot) = true := by
  cases ph <;> rfl

/-! ## Invariant preservation -/

/-- Running a transition for the active hero preserves whatever that transition preserves. -/
theorem ok_withActive {s s' : State} {f : PlayerState → Outcome} {fx : List Effect}
    (hf : ∀ p s'' fx', f p = .ok (s'', fx') → Ok s'')
    (h : withActive s f = .ok (s', fx)) : Ok s' := by
  unfold withActive at h
  split at h
  · exact absurd h (by simp)
  · exact hf _ _ _ h

/-- The same, for a transition addressed to the hero the envelope names. -/
theorem ok_withSubject {s s' : State} {subject : Option Mythroads.PlayerId}
    {f : PlayerState → Outcome} {fx : List Effect}
    (hf : ∀ p s'' fx', f p = .ok (s'', fx') → Ok s'')
    (h : withSubject s subject f = .ok (s', fx)) : Ok s' := by
  unfold withSubject at h
  split at h
  · exact absurd h (by simp)
  · split at h
    · exact absurd h (by simp)
    · exact hf _ _ _ h

/--
**The dispatcher theorem.** Every accepted transition preserves the room invariant.

The proof is one `split` with one arm per dispatch case, each discharged by the matching
lemma in `Mythroads.Engine.Preservation`. An event added to `transition` without its
lemma leaves an arm this proof cannot close.
-/
theorem ok_transition {s s' : State} {env : Envelope} {fx : List Effect}
    (ok : Ok s) (h : transition s env = .ok (s', fx)) : Ok s' := by
  unfold transition at h
  split at h
  case _ => exact ok_withSubject (fun _ _ _ hh => ok_equip ok hh) h
  case _ => exact ok_withActive (fun _ _ _ hh => ok_cameraToggle ok hh) h
  case _ => exact ok_cameraMove ok h
  case _ => exact ok_cameraZoom ok h
  case _ => exact ok_join ok h
  case _ => exact ok_start ok h
  case _ => exact ok_create h
  case _ => exact ok_withActive (fun _ _ _ hh => ok_roll ok hh) h
  case _ => exact ok_withActive (fun _ _ _ hh => ok_select ok hh) h
  case _ => exact ok_cancel ok h
  case _ => exact ok_withActive (fun _ _ _ hh => ok_stepMove ok hh) h
  case _ => exact ok_withActive (fun _ _ _ hh => ok_attack ok hh) h
  case _ => exact ok_withActive (fun _ _ _ hh => ok_guard ok hh) h
  case _ => exact ok_withActive (fun _ _ _ hh => ok_resolveEncounter ok hh) h
  case _ => exact ok_withActive (fun _ _ _ hh => ok_buy ok hh) h
  case _ => exact ok_withActive (fun _ _ _ hh => ok_leave ok hh) h
  case _ => exact absurd h (by simp)

/-- `step` preserves the invariant, because it only ever ends in `transition`. -/
theorem ok_step {s s' : State} {env : Envelope} {fx : List Effect}
    (ok : Ok s) (h : step s env = .ok (s', fx)) : Ok s' := by
  unfold step at h
  split at h
  · exact absurd h (by simp)
  · split at h
    · exact absurd h (by simp)
    · split at h
      · exact absurd h (by simp)
      · exact ok_transition ok h

/-- Folding one durable envelope preserves the invariant, whether it is accepted or not. -/
theorem ok_applyLogged {s : State} (ok : Ok s) (env : Envelope) : Ok (applyLogged s env) := by
  unfold applyLogged
  split
  · rename_i s'' fx hstep
    exact ok_congr (ok_step ok hstep) rfl rfl rfl
  · exact ok

/-- Replaying a durable log from a safe room lands in a safe room. -/
theorem ok_replay (log : List Envelope) : ∀ {s : State}, Ok s → Ok (replay s log) := by
  induction log with
  | nil => intro s ok; exact ok
  | cons env rest ih =>
      intro s ok
      exact ih (ok_applyLogged ok env)

end Mythroads.Engine
