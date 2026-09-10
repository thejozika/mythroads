import Mythroads.Oracle.Encode

/-!
# The oracle's encoders, part two: what goes in and what comes out

`Mythroads.Oracle.Encode` covers the room; this module covers the envelope that acts on
it and the outcome that comes back. The split is only about file length — the two are
one table, written in the same style, and both must agree with the shapes
`Mythroads.Compile.Expr` emits.

The digest at the end is the reason the fixture stays small. Two thousand fuzzed steps
carry two thousand whole rooms, which is megabytes of JSON; storing a hash of the
canonical text of each keeps the comparison exact while keeping the file under a
hundred kilobytes. It is FNV-1a over the code points of the canonical text, which is
easy to reproduce in TypeScript character for character, with the text length appended
so that a truncation cannot pass.
-/

namespace Mythroads.Oracle

open Lean (Json)
open Mythroads Mythroads.Engine

/-- `Mythroads.Engine.Direction`. -/
def direction : Direction → Json
  | .up => tag "up" | .down => tag "down" | .left => tag "left" | .right => tag "right"

/-- `Mythroads.Engine.Zoom`. -/
def zoom : Zoom → Json
  | .nearer => tag "nearer" | .farther => tag "farther"

/-- `Mythroads.Engine.Event`. -/
def event : Event → Json
  | .roomCreate seed => tag "roomCreate" [("seed", nat seed)]
  | .playerJoin code name color =>
      tag "playerJoin" [("code", Json.str code), ("name", Json.str name),
        ("color", Json.str color)]
  | .gameStart => tag "gameStart"
  | .movementRoll => tag "movementRoll"
  | .movementSelect destination => tag "movementSelect" [("destination", nat destination)]
  | .movementCancel => tag "movementCancel"
  | .movementStep destination => tag "movementStep" [("destination", nat destination)]
  | .combatAttack s => tag "combatAttack" [("strike", strike s)]
  | .combatGuard g => tag "combatGuard" [("guard", guard g)]
  | .encounterResolve => tag "encounterResolve"
  | .shopBuy itemId => tag "shopBuy" [("itemId", Json.str itemId)]
  | .inventoryEquip row s =>
      tag "inventoryEquip" [("playerItemId", Json.str row), ("slot", slot s)]
  | .shopLeave => tag "shopLeave"
  | .cameraToggle => tag "cameraToggle"
  | .cameraMove d => tag "cameraMove" [("direction", direction d)]
  | .cameraZoom d => tag "cameraZoom" [("delta", zoom d)]

/-- `Mythroads.Engine.Envelope`. -/
def envelope (e : Envelope) : Json :=
  Json.mkObj [("actor", Json.str e.actor), ("subject", option Json.str e.subject),
    ("event", event e.event), ("seed", nat e.seed)]

/-- `Mythroads.Engine.Effect`. -/
def effect : Effect → Json
  | .persistPlayer id => tag "persistPlayer" [("id", Json.str id)]
  | .persistRoom => tag "persistRoom"
  | .persistCombat => tag "persistCombat"
  | .persistEncounter => tag "persistEncounter"
  | .persistSelection => tag "persistSelection"
  | .clearSelection => tag "clearSelection"
  | .persistCamera => tag "persistCamera"
  | .appendLog name => tag "appendLog" [("name", Json.str name)]
  | .notify message => tag "notify" [("message", Json.str message)]

/-- `Mythroads.Engine.Error`. -/
def error : Error → Json
  | .unauthorized => tag "unauthorized" | .notYourTurn => tag "notYourTurn"
  | .wrongPhase => tag "wrongPhase" | .unknownPlayer => tag "unknownPlayer"
  | .illegalMove => tag "illegalMove" | .insufficientGold => tag "insufficientGold"
  | .roomFull => tag "roomFull" | .roomEmpty => tag "roomEmpty"
  | .nameRequired => tag "nameRequired" | .nameTaken => tag "nameTaken"
  | .colorMismatch => tag "colorMismatch" | .roomNotInLobby => tag "roomNotInLobby"
  | .unknownItem => tag "unknownItem" | .itemNotHere => tag "itemNotHere"
  | .cannotEquip => tag "cannotEquip" | .techniqueNotEquipped => tag "techniqueNotEquipped"
  | .cameraNotFree => tag "cameraNotFree"

/--
`Mythroads.Engine.Outcome`, which is `Except Error (State × List Effect)`.

Both constructors of `Except` name their payload `a`, and `Prod` names its two `fst`
and `snd`, because those are the binder names Lean gives them and the compiler emits
field names exactly as Lean wrote them.
-/
def outcome : Outcome → Json
  | .error e => tag "error" [("a", error e)]
  | .ok (s, effects) =>
      tag "ok" [("a", Json.mkObj [("fst", state s), ("snd", list effect effects)])]

/-- The canonical text of a JSON value: compact, with object keys in sorted order. -/
def canonical (j : Json) : String := j.compress

/--
FNV-1a over the code points of a string, as a 32-bit number, with the length appended.

The compiled engine's own outputs are hashed the same way in TypeScript, so a fixture
entry pins the exact text of an outcome without storing it.
-/
def digest (text : String) : String :=
  let hash := text.foldl (fun h c => ((h ^^^ c.toNat) * 16777619) % 4294967296) 2166136261
  s!"{hash}-{text.length}"

end Mythroads.Oracle
