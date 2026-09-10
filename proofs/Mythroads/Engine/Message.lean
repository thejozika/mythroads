import Mythroads.Engine.Event

/-!
# Refusals, in the words the players read

`step` refuses with an `Error`, which is a closed enumeration of *why*. The sentence a
player sees is not part of that reasoning, but it is part of the contract: the phones
show it, and the golden-master suite pins it verbatim.

The table below is that contract, and it is keyed on **both** the error and the event,
because the same refusal reads differently depending on what was asked. `wrongPhase` on
`movement.roll` is "You cannot roll now."; the same refusal on `shop.leave` is "You are
not shopping now."; on a camera command it is "Only the active player can control the
camera." One error, three sentences, and each of them is the sentence the boundary
produced before the engine ran the rules.

`unauthorized` never reaches this table in practice — the Convex boundary refuses an
unowned hero, a missing hero and an unauthenticated caller before `step` is called, with
messages of its own — but it is answered here anyway so the table is total.

The compiler emits this function into `shared/generated/engine.generated.ts` alongside
`step`, so the interpreter turns an `Error` into a `ConvexError` without a second table.
-/

namespace Mythroads.Engine

/-- Is this a camera command? Camera refusals share one sentence. -/
def Event.isCamera : Event → Bool
  | .cameraToggle | .cameraMove _ | .cameraZoom _ => true
  | _ => false

/--
The sentence shown when this event is refused for this reason.

Read it as one table: the rows that matter are the ones a phone can actually provoke,
and every other pairing falls through to a generic sentence rather than an empty string.
-/
def Error.message : Error → Event → String
  | .cameraNotFree, _ => "Free camera is not active."
  | .techniqueNotEquipped, _ => "Equip the grimoire containing that technique first."
  | .insufficientGold, _ => "You need more gold."
  | .unknownItem, _ | .itemNotHere, _ => "That item is not available here."
  | .cannotEquip, _ => "That item cannot be equipped there."
  | .roomFull, _ => "That room is full."
  | .roomEmpty, _ => "At least one hero must join."
  | .nameRequired, _ => "Choose a hero name."
  | .nameTaken, _ => "That hero name belongs to another account."
  | .colorMismatch, _ => "That hero exists. Select their original color to rejoin."
  | .roomNotInLobby, _ =>
      "That adventure has started. Rejoin with your existing name and color."
  | .routeNotStarted, _ => "Start route planning from the hero."
  | .roadUnavailable, _ => "That road cannot be used from here."
  | .routeUnavailable, _ => "That route is not available."
  | .noMovementLeft, _ => "You cannot move now."
  | .unauthorized, _ => "You are not allowed to do that."
  | _, e =>
      if e.isCamera then "Only the active player can control the camera."
      else match e with
        | .movementRoll => "You cannot roll now."
        | .movementSelect _ => "That destination cannot be selected."
        | .movementCancel => "There is no movement selection to cancel."
        | .movementStep _ => "You cannot move now."
        | .combatAttack _ | .combatGuard _ => "That combat choice is not available."
        | .encounterResolve => "This encounter cannot be resolved now."
        | .shopBuy _ => "That item is not available here."
        | .shopLeave => "You are not shopping now."
        | .inventoryEquip _ _ => "That item cannot be equipped there."
        | _ => "This action is not available right now."

-- The refusals the golden-master suite pins, decided rather than trusted.
#guard Error.message .wrongPhase .movementRoll = "You cannot roll now."
#guard Error.message .notYourTurn (.movementSelect 0) = "That destination cannot be selected."
#guard Error.message .wrongPhase .movementCancel = "There is no movement selection to cancel."
#guard Error.message .wrongPhase (.movementStep 0) = "You cannot move now."
#guard Error.message .wrongPhase .shopLeave = "You are not shopping now."
#guard Error.message .wrongPhase .encounterResolve = "This encounter cannot be resolved now."
#guard Error.message .notYourTurn .cameraToggle =
  "Only the active player can control the camera."
#guard Error.message .wrongPhase (.shopBuy "") = "That item is not available here."

end Mythroads.Engine
