import Mythroads.Engine.Step

/-!
# Replay

`replay` is the meaning of a log: the room a sequence of accepted envelopes produces.
Rejected envelopes are never appended, so folding a log is total: `applyLogged` keeps the
state unchanged when an envelope is refused.

What the deployed backend stores is the *state* — the `rooms` row and its satellites,
which `loadState` reads and `saveState` writes — and the `gameEvents` log beside it is an
audit trail rather than the source the state is rebuilt from. Two things keep it from
being a complete transcript today: the `room.create` seed is normalised into the room's
generator state and not written to the log, and the room-code collision retry advances
that generator outside any logged envelope. The theorems below are about the log as a
mathematical object, and they are what a snapshot-and-tail persistence model would rest
on if it is ever adopted.

`replay_append` is the theorem that makes **snapshots sound**. A stored snapshot taken
at version *n* plus the tail of the log equals a full replay from the beginning, so a
snapshot table can be added later without weakening any claim made here. `replay_snoc`
is its one-event corollary: appending an event advances the cached state by exactly one
`step`, which is what the Convex mutation does inside a single transaction.
-/

namespace Mythroads.Engine

/-- Fold one durable envelope into the state, bumping the version it has folded in. -/
def applyLogged (s : State) (env : Envelope) : State :=
  match step s env with
  | .ok (s', _) => { s' with version := s.version + 1 }
  | .error _ => s

/-- Rebuild a room from an initial state and its durable log. -/
def replay (s : State) (log : List Envelope) : State := log.foldl applyLogged s

/-- Replaying nothing changes nothing. -/
theorem replay_nil (s : State) : replay s [] = s := rfl

/-- Replaying a concatenation is replaying the parts; this is what makes snapshots sound. -/
theorem replay_append (s : State) (a b : List Envelope) :
    replay s (a ++ b) = replay (replay s a) b := by
  simp [replay, List.foldl_append]

/-- Appending one event advances the cached state by exactly one `step`. -/
theorem replay_snoc (s : State) (log : List Envelope) (env : Envelope) :
    replay s (log ++ [env]) = applyLogged (replay s log) env := by
  simp [replay]

end Mythroads.Engine
