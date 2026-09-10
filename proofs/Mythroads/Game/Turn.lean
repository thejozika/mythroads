namespace Mythroads.Game.Turn

def nextIndex (current playerCount : Nat) : Nat := (current + 1) % playerCount

def nextRound (round current playerCount : Nat) : Nat :=
  if current + 1 = playerCount then round + 1 else round

theorem nextIndexIsValid (current playerCount : Nat) (positive : 0 < playerCount) :
    nextIndex current playerCount < playerCount := by
  exact Nat.mod_lt _ positive

theorem roundNeverDecreases (round current playerCount : Nat) :
    round ≤ nextRound round current playerCount := by
  simp only [nextRound]; split <;> omega

end Mythroads.Game.Turn
