namespace Mythroads.Game.Player

structure StartingStats where
  position : Nat
  gold : Nat
  hp : Nat
  attack : Nat
  defense : Nat
  magic : Nat
  athletics : Nat
  agility : Nat
  dice : List Nat
  deriving Repr, DecidableEq

def startingStats : StartingStats where
  position := 0
  gold := 10
  hp := 10
  attack := 2
  defense := 2
  magic := 2
  athletics := 2
  agility := 2
  dice := [4, 6]

theorem startingHealthPositive : 0 < startingStats.hp := by decide
theorem startingDiceAreUsable : startingStats.dice.all (0 < ·) = true := by decide

end Mythroads.Game.Player
