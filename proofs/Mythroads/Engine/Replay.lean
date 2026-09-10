import Mythroads.Engine.Step

/-!
# Replay

The durable event log is the source of truth; `State` is a cache of `replay`. Rejected
envelopes are never appended, so folding a log is total: `applyLogged` keeps the state
unchanged when an envelope is refused.

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
