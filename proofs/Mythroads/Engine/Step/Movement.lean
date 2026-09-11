import Mythroads.Engine.Step.Landing

/-!
# Movement: roll, plan a route, commit it

Dokapon-style movement is not "walk one node per input". The hero rolls, then *plans*
a whole route node by node, then commits it in one go. All three live in the single
`Phase.moving` constructor, matching the Convex `rooms.phase = 'moving'` column:

* `moves` is the roll total and never shrinks while planning;
* `selection` is the route planned so far, mirroring the `roomSelections` row;
* the movement still to plan is `moves - selection.path.length`.

`previewRouteStep` is the interesting rule and is reproduced exactly, including its
**refund**: selecting the node you came from retracts the last step instead of
extending the route, so a misclick costs nothing. `movement.step` then accepts the
route only if it is exactly `moves` long and every hop is a declared road, so a
committed route always consumes the full roll.
-/

namespace Mythroads.Engine.Movement

open Mythroads.Game

/-- Roll one hero's dice in order, threading the room generator and adding one per face. -/
def rollDice (s : State) : List Nat → List Nat × State
  | [] => ([], s)
  | sides :: rest =>
      let drawn := s.draw sides
      let tail := rollDice drawn.2 rest
      ((drawn.1 + 1) :: tail.1, tail.2)

/-- The node a partially planned route currently stands on. -/
def routeHead (origin : NodeId) (path : List NodeId) : NodeId := path.getLast?.getD origin

/-- The node the route arrived from, which is the one a refund step retracts to. -/
def routeTail (origin : NodeId) (path : List NodeId) : Option NodeId :=
  if 1 < path.length then path[path.length - 2]?
  else if path.length = 1 then some origin
  else none

/--
Extend, retract, or refuse one planning step, exactly as the generated
`previewRouteStep` does. Retracting wins over extending, a full route refuses to grow,
and a hop that is not a declared road is refused outright.
-/
def previewRouteStep (origin : NodeId) (path : List NodeId) (destination : NodeId)
    (totalSteps : Nat) : Option (List NodeId) :=
  let current := routeHead origin path
  if routeTail origin path = some destination ∧ World.canTraverse current destination then
    some path.dropLast
  else if totalSteps ≤ path.length ∨ !World.canTraverse current destination then none
  else some (path ++ [destination])

/-- Is every hop of a planned route a declared road out of the previous node? -/
def routeValid (origin : NodeId) : List NodeId → Bool
  | [] => true
  | step :: rest => World.canTraverse origin step && routeValid step rest

/-- `movement.roll`: roll every die, owe exactly that many steps, and drop any old route. -/
def roll (s : State) (p : PlayerState) : Outcome :=
  let rolled := rollDice s p.dice
  let total := rolled.1.foldl (· + ·) 0
  .ok ({ (rolled.2.mapPlayer p.id fun q => { q with previousPosition := none }) with
          lastRoll := rolled.1, phase := .moving total none,
          message := p.name ++ " rolled " ++ toString total ++
            ". Press Y to choose a destination." },
       [.clearSelection, .persistPlayer p.id, .persistRoom, .appendLog "movement.roll"])

/-- The banner shown after a planning step, naming the node and the movement left. -/
def planningMessage (destination remaining : Nat) : String :=
  if remaining = 0 then "Route ends at " ++ (node destination).label ++ ". Press A to travel."
  else "Planning through " ++ (node destination).label ++ ". " ++
    toString remaining ++ " movement left."

/--
`movement.select`: start a route at the hero, or extend/retract it by one node.

The first selection must name the hero's own node and produces the empty route, which
is what the client uses to open the planning cursor.
-/
def select (s : State) (p : PlayerState) (moves : Nat) (selection : Option Selection)
    (destination : NodeId) : Outcome :=
  match selection with
  | none =>
      if destination ≠ p.position then .error .routeNotStarted
      else
        let opened : Selection := { playerId := p.id, destination := p.position, path := [] }
        .ok (s.withPhase (.moving moves (some opened)) (planningMessage p.position moves),
             [.persistSelection opened, .persistRoom, .appendLog "movement.select"])
  | some current =>
      match previewRouteStep p.position current.path destination moves with
      | none => .error .roadUnavailable
      | some path =>
          let previewed := routeHead p.position path
          let planned : Selection := { playerId := p.id, destination := previewed, path }
          .ok (s.withPhase (.moving moves (some planned))
                (planningMessage previewed (moves - path.length)),
               [.persistSelection planned, .persistRoom, .appendLog "movement.select"])

/-- `movement.cancel`: throw the planned route away and keep the roll. -/
def cancel (s : State) (moves : Nat) : Outcome :=
  .ok (s.withPhase (.moving moves none) "Press Y to choose a destination.",
       [.clearSelection, .persistRoom, .appendLog "movement.cancel"])

/--
`movement.step`: commit the planned route.

Three conditions must hold together, and they prevent a client from inventing movement steps:
the route must end where the event says, it must be exactly as long as the roll, and
every hop must be a declared road. Only then does the hero move and the landed space
resolve.
-/
def stepMove (s : State) (p : PlayerState) (moves : Nat) (selection : Option Selection)
    (destination : NodeId) : Outcome :=
  if moves = 0 then .error .noMovementLeft
  else match selection with
  | none => .error .routeUnavailable
  | some current =>
      if current.destination ≠ destination ∨ current.path.length ≠ moves
          ∨ !routeValid p.position current.path then
        .error .routeUnavailable
      else
        match Landing.resolveLanding (s.mapPlayer p.id fun q =>
            { q with position := destination,
                     previousPosition := some ((current.path.dropLast).getLast?.getD p.position) })
            p destination with
        | .error e => .error e
        | .ok (s', fx) =>
            .ok (s', [.clearSelection, .persistPlayer p.id, .appendLog "movement.step"] ++ fx)

end Mythroads.Engine.Movement
