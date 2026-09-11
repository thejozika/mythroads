namespace Mythroads.Game.Random

def modulus : Nat := 2147483647
def multiplier : Nat := 48271

/-- Turns every external seed into a non-zero Park–Miller state. -/
def normalizeSeed (seed : Nat) : Nat := seed % (modulus - 1) + 1

/-- One deterministic transition of the game's random state. -/
def nextState (state : Nat) : Nat := (state * multiplier) % modulus

structure Draw where
  value : Nat
  state : Nat
  deriving Repr, DecidableEq

/-- Draws uniformly from the PRNG state modulo `bound`; callers must use a positive bound. -/
def drawBounded (state bound : Nat) : Draw :=
  let next := nextState state
  { value := next % bound, state := next }

structure Chance where
  favorable : Nat
  possible : Nat
  valid : 0 < possible ∧ favorable ≤ possible

def hits (chance : Chance) (roll : Nat) : Bool := roll < chance.favorable

theorem normalizedSeed_positive (seed : Nat) : 0 < normalizeSeed seed := by
  simp [normalizeSeed]

theorem normalizedSeed_lt_modulus (seed : Nat) : normalizeSeed seed < modulus := by
  unfold normalizeSeed modulus
  omega

theorem nextState_lt_modulus (state : Nat) : nextState state < modulus := by
  exact Nat.mod_lt _ (by decide)

/-- The Park–Miller multiplier is invertible modulo the Mersenne modulus. -/
theorem multiplier_coprime_modulus : Nat.Coprime modulus multiplier := by decide

/-- A valid non-zero Park–Miller state can never transition to zero. -/
theorem nextState_positive (state : Nat) (positive : 0 < state) (small : state < modulus) :
    0 < nextState state := by
  have notDvd : ¬ modulus ∣ state := Nat.not_dvd_of_pos_of_lt positive small
  have modNonzero : (state * multiplier) % modulus ≠ 0 := by
    intro zero
    exact notDvd (multiplier_coprime_modulus.dvd_of_dvd_mul_right
      (Nat.dvd_of_mod_eq_zero zero))
  unfold nextState
  omega

theorem drawBounded_lt (state bound : Nat) (positive : 0 < bound) :
    (drawBounded state bound).value < bound := by
  exact Nat.mod_lt _ positive

theorem drawBounded_is_deterministic (state bound : Nat) :
    drawBounded state bound = drawBounded state bound := by
  rfl

theorem hit_iff_roll_is_favorable (chance : Chance) (roll : Nat) :
    hits chance roll = true ↔ roll < chance.favorable := by
  simp [hits]

/-- A uniform traversal of every bucket hits exactly the declared numerator many times. -/
theorem exact_favorable_bucket_count (chance : Chance) :
    ((List.range chance.possible).filter fun roll => hits chance roll).length =
      chance.favorable := by
  have split : chance.possible = chance.favorable + (chance.possible - chance.favorable) := by
    exact (Nat.add_sub_of_le chance.valid.2).symm
  rw [split, List.range_add, List.filter_append]
  have keep :
      (List.range chance.favorable).filter (fun roll => hits chance roll) =
        List.range chance.favorable := by
    apply List.filter_eq_self.mpr
    intro roll member
    simp only [List.mem_range] at member
    simp [hits, member]
  have discard :
      ((List.range (chance.possible - chance.favorable)).map
        (chance.favorable + ·)).filter (fun roll => hits chance roll) = [] := by
    apply List.filter_eq_nil_iff.mpr
    intro roll member
    simp only [List.mem_map, List.mem_range] at member
    obtain ⟨offset, _, rfl⟩ := member
    simp [hits]
  rw [keep, discard]
  simp

theorem impossible_chance_never_hits (possible : Nat) (positive : 0 < possible) (roll : Nat) :
    hits { favorable := 0, possible, valid := ⟨positive, Nat.zero_le possible⟩ } roll = false := by
  simp [hits]

theorem certain_chance_hits_every_valid_roll (possible roll : Nat)
    (positive : 0 < possible) (validRoll : roll < possible) :
    hits { favorable := possible, possible, valid := ⟨positive, Nat.le_refl possible⟩ } roll = true := by
  simp [hits, validRoll]

end Mythroads.Game.Random
