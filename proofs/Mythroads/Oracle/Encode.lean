import Lean.Data.Json
import Mythroads.Engine

/-!
# The oracle's encoders

The parity harness compares the compiled TypeScript engine against the Lean engine by
running the same envelopes through both and comparing the JSON. This module is the Lean
half of that: one total function per type, writing exactly the shape
`Mythroads.Compile.Expr` emits.

These encoders are the only hand-written correspondence in the whole pipeline, and they
are deliberately dumb — a field name and a recursive call, nothing else. They cannot
drift silently, because a mismatch between what is written here and what the compiler
emits is precisely what `tests/engine/engine-parity.test.ts` fails on.

`Lean.Json` is used rather than string concatenation because `Json.mkObj` keys an
ordered map: `Json.compress` therefore prints object keys in sorted order, which is the
canonical form the test compares against.
-/

namespace Mythroads.Oracle

open Lean (Json)
open Mythroads Mythroads.Engine

/-- A constructor of a many-constructor inductive: `{ "_": "name", … }`. -/
def tag (name : String) (fields : List (String × Json) := []) : Json :=
  Json.mkObj (("_", Json.str name) :: fields)

/-- A `Nat`, which the compiled engine represents as a `number`. -/
def nat (n : Nat) : Json := Json.num (Lean.JsonNumber.fromNat n)

/-- An `Int`, which the compiled engine also represents as a `number`. -/
def int (i : Int) : Json := Json.num (Lean.JsonNumber.fromInt i)

/-- A `List`, which the compiled engine represents as an array. -/
def list (f : α → Json) (xs : List α) : Json := Json.arr (xs.map f).toArray

/-- An `Option`, which is tagged like any other inductive rather than becoming `null`. -/
def option (f : α → Json) : Option α → Json
  | none => tag "none"
  | some a => tag "some" [("val", f a)]

/-- `Mythroads.Game.Inventory.EquipmentSlot`. -/
def slot : Game.Inventory.EquipmentSlot → Json
  | .weapon => tag "weapon" | .helmet => tag "helmet" | .body => tag "body"
  | .gloves => tag "gloves" | .boots => tag "boots" | .cape => tag "cape"
  | .amulet => tag "amulet" | .ringLeft => tag "ringLeft" | .ringRight => tag "ringRight"
  | .offensiveMagic => tag "offensiveMagic" | .defensiveMagic => tag "defensiveMagic"

/-- `Mythroads.Game.Inventory.ShopKind`. -/
def shopKind : Game.Inventory.ShopKind → Json
  | .armoury => tag "armoury" | .jeweller => tag "jeweller" | .weapons => tag "weapons"
  | .items => tag "items" | .magic => tag "magic"

/-- `Mythroads.Game.Magic.Element`. -/
def element : Game.Magic.Element → Json
  | .fire => tag "fire" | .water => tag "water" | .wind => tag "wind" | .earth => tag "earth"

/-- `Mythroads.Game.Combat.Guard`. -/
def guard : Game.Combat.Guard → Json
  | .high => tag "high" | .side => tag "side" | .brace => tag "brace" | .ward => tag "ward"

/-- `Mythroads.Game.Combat.PhysicalAttack`. -/
def physical : Game.Combat.PhysicalAttack → Json
  | .stab => tag "stab" | .chargeHigh => tag "chargeHigh"
  | .chargeSide => tag "chargeSide" | .leap => tag "leap"

/-- `Mythroads.Engine.Technique`. -/
def technique : Technique → Json
  | .emberBlast => tag "emberBlast" | .scorchArmor => tag "scorchArmor"
  | .tideNeedle => tag "tideNeedle" | .undertow => tag "undertow"
  | .galeBlade => tag "galeBlade" | .windShear => tag "windShear"
  | .stoneCrash => tag "stoneCrash" | .calcify => tag "calcify"

/-- `Mythroads.Engine.Strike`. -/
def strike : Strike → Json
  | .physical a => tag "physical" [("attack", physical a)]
  | .magic t => tag "magic" [("technique", technique t)]

/-- `Mythroads.Engine.Owned`. -/
def owned (o : Owned) : Json :=
  Json.mkObj [("rowId", Json.str o.rowId), ("itemId", Json.str o.itemId),
    ("equippedSlot", option slot o.equippedSlot)]

/-- `Mythroads.Engine.PlayerState`. -/
def player (p : PlayerState) : Json :=
  Json.mkObj [("id", Json.str p.id), ("owner", Json.str p.owner), ("name", Json.str p.name),
    ("color", Json.str p.color), ("position", nat p.position),
    ("previousPosition", option nat p.previousPosition), ("gold", nat p.gold),
    ("hp", nat p.hp), ("maxHp", nat p.maxHp), ("attack", nat p.attack),
    ("defense", nat p.defense), ("magic", nat p.magic), ("athletics", nat p.athletics),
    ("agility", nat p.agility), ("dice", list nat p.dice), ("items", list owned p.items)]

/-- `Mythroads.Engine.Selection`. -/
def selection (s : Selection) : Json :=
  Json.mkObj [("playerId", Json.str s.playerId), ("destination", nat s.destination),
    ("path", list nat s.path)]

/-- `Mythroads.Game.Combat.Enemy`. -/
def enemy (e : Game.Combat.Enemy) : Json :=
  Json.mkObj [("name", Json.str e.name), ("element", element e.element), ("hp", nat e.hp),
    ("attack", nat e.attack), ("defense", nat e.defense), ("magic", nat e.magic),
    ("athletics", nat e.athletics), ("agility", nat e.agility), ("reward", nat e.reward)]

/-- `Mythroads.Engine.CombatStage`. -/
def stage : CombatStage → Json
  | .attackerChoice => tag "attackerChoice"
  | .defenderChoice => tag "defenderChoice"
  | .resolved => tag "resolved"

/-- `Mythroads.Engine.CombatState`. -/
def combat (c : CombatState) : Json :=
  Json.mkObj [("playerId", Json.str c.playerId), ("spaceId", nat c.spaceId),
    ("enemy", enemy c.enemy), ("enemyHp", nat c.enemyHp),
    ("enemyDefensePenalty", nat c.enemyDefensePenalty),
    ("enemyMagicPenalty", nat c.enemyMagicPenalty),
    ("enemyAthleticsPenalty", nat c.enemyAthleticsPenalty),
    ("enemyAgilityPenalty", nat c.enemyAgilityPenalty),
    ("playerDefensePenalty", nat c.playerDefensePenalty),
    ("playerMagicPenalty", nat c.playerMagicPenalty),
    ("playerAthleticsPenalty", nat c.playerAthleticsPenalty),
    ("playerAgilityPenalty", nat c.playerAgilityPenalty), ("round", nat c.round),
    ("lastAttack", option Json.str c.lastAttack), ("lastGuard", option guard c.lastGuard),
    ("lastDamage", option nat c.lastDamage), ("message", Json.str c.message)]

/-- `Mythroads.Game.Encounter.Kind`. -/
def encounterKind : Game.Encounter.Kind → Json
  | .combat => tag "combat" | .event => tag "event"

/-- `Mythroads.Game.Encounter.Outcome`. -/
def encounterOutcome (o : Game.Encounter.Outcome) : Json :=
  Json.mkObj [("id", Json.str o.id), ("kind", encounterKind o.kind),
    ("title", Json.str o.title), ("description", Json.str o.description),
    ("goldDelta", int o.goldDelta), ("hpDelta", int o.hpDelta), ("weight", nat o.weight)]

/-- `Mythroads.Engine.EncounterState`. -/
def encounter (e : EncounterState) : Json :=
  Json.mkObj [("playerId", Json.str e.playerId), ("spaceId", nat e.spaceId),
    ("kind", encounterKind e.kind), ("outcome", encounterOutcome e.outcome),
    ("wheelIndex", nat e.wheelIndex), ("resolved", Json.bool e.resolved)]

/-- `Mythroads.Engine.Camera`. -/
def camera (c : Camera) : Json :=
  Json.mkObj [("free", Json.bool c.free), ("targetX", int c.targetX),
    ("targetZ", int c.targetZ), ("distance", nat c.distance)]

/-- `Mythroads.Engine.Phase`. -/
def phase : Phase → Json
  | .lobby => tag "lobby"
  | .awaitingRoll => tag "awaitingRoll"
  | .moving moves sel => tag "moving" [("moves", nat moves), ("selection", option selection sel)]
  | .combat battle st => tag "combat" [("battle", combat battle), ("stage", stage st)]
  | .encounter drawn => tag "encounter" [("drawn", encounter drawn)]
  | .shop kind => tag "shop" [("kind", shopKind kind)]
  | .finished winner => tag "finished" [("winner", Json.str winner)]

/-- `Mythroads.Engine.State`. -/
def state (s : State) : Json :=
  Json.mkObj [("code", Json.str s.code), ("host", Json.str s.host),
    ("players", list player s.players), ("turn", nat s.turn), ("round", nat s.round),
    ("phase", phase s.phase), ("message", Json.str s.message),
    ("lastRoll", list nat s.lastRoll), ("rng", nat s.rng), ("rngCounter", nat s.rngCounter),
    ("camera", option camera s.camera), ("version", nat s.version)]

end Mythroads.Oracle
