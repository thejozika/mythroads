import Mythroads.Engine.Step.Camera
import Mythroads.Engine.Step.Combat
import Mythroads.Engine.Step.Encounter
import Mythroads.Engine.Step.Lobby
import Mythroads.Engine.Step.Movement
import Mythroads.Engine.Step.Shop

/-!
# `step` — the whole game, in one function

`step` is the only entry point into the rules. It is three total gates followed by a
dispatch:

1. **authority** — does the verified actor hold the privilege this event demands?
2. **turn** — is it this hero's turn at all?
3. **phase** — does the current phase accept this event?

Only then does `transition` run, and it may still refuse with a domain error such as
`insufficientGold`. Writing the gates as three separate `if`s is what makes the
security theorems in `Mythroads.Engine.Theorems` one-liners: a successful `step`
*syntactically* implies each gate held, for every state and every actor, rather than
for the cases a test happens to cover.

`transition` is one flat match on `(phase, event)`. Every arm hands the phase payload
to a per-phase module, which therefore never re-checks authority, never re-reads the
turn, and never inspects `Phase` again — its preconditions arrive as arguments.
Reading this match top to bottom is the specification of what the game can do next.
-/

namespace Mythroads.Engine

/-- Run a transition for the hero whose turn it is, or refuse if the room is empty. -/
def withActive (s : State) (f : PlayerState → Outcome) : Outcome :=
  match s.active? with
  | none => .error .unknownPlayer
  | some p => f p

/-- Run a transition for the hero the envelope names, or refuse if there is no such hero. -/
def withSubject (s : State) (subject : Option Mythroads.PlayerId) (f : PlayerState → Outcome) :
    Outcome :=
  match subject with
  | none => .error .unknownPlayer
  | some pid => match s.player? pid with
    | none => .error .unknownPlayer
    | some p => f p

/--
The phase-indexed dispatch table: every legal `(phase, event)` pair and what it does.

The three phase-free families come first — equipping, the camera, and joining — because
they are accepted in every phase. Everything below them is the turn structure proper:
roll, plan, commit, resolve the landed space, and pass the turn.
-/
def transition (s : State) (env : Envelope) : Outcome :=
  match s.phase, env.event with
  | _, .inventoryEquip row slot =>
      withSubject s env.subject fun p => Shop.equip s env.actor p row slot
  | _, .cameraToggle => withActive s (CameraStep.toggle s)
  | _, .cameraMove direction => CameraStep.move s direction
  | _, .cameraZoom delta => CameraStep.zoom s delta
  | _, .playerJoin _ name color => Lobby.join s env.actor name color
  | .lobby, .roomCreate seed => Lobby.create s env.actor seed
  | .lobby, .gameStart => Lobby.start s
  | .awaitingRoll, .movementRoll => withActive s (Movement.roll s)
  | .moving moves selection, .movementSelect destination =>
      withActive s fun p => Movement.select s p moves selection destination
  | .moving moves _, .movementCancel => Movement.cancel s moves
  | .moving moves selection, .movementStep destination =>
      withActive s fun p => Movement.stepMove s p moves selection destination
  | .combat battle .attackerChoice, .combatAttack choice =>
      withActive s fun p => Battle.attack s p battle choice
  | .combat battle .defenderChoice, .combatGuard stance =>
      withActive s fun p => Battle.guard s p battle stance
  | .encounter drawn, .encounterResolve => withActive s fun p => Encounters.resolve s p drawn
  | .shop kind, .shopBuy itemId => withActive s fun p => Shop.buy s p kind itemId
  | .shop _, .shopLeave => withActive s (Shop.leave s)
  | _, _ => .error .wrongPhase

/-- The single deterministic transition function of Mythroads. -/
def step (s : State) (env : Envelope) : Outcome :=
  if !authorized s env then .error .unauthorized
  else if !onTurn s env then .error .notYourTurn
  else if !permitted s.phase env.event then .error .wrongPhase
  else transition s env

end Mythroads.Engine
