import Mythroads.Backend.Aggregate.Support

namespace Mythroads.Backend.Aggregate.Enums

/-!
# Reading a column back into an engine constructor

A Convex column stores a closed set of strings; the engine stores the matching constructor. Going
from the constructor to the column is free — the compiled representation *is* `{ _: "armoury" }`,
so `.  _` is already the column value. Coming back is the direction that needs code, because
TypeScript will not narrow `'armoury' | 'jeweller' | …` into a union of singleton objects on its
own.

Every function below is therefore the same shape and none of them is written out by hand: the tag
lists come from the catalogues themselves — `Game.Inventory.allEquipmentSlots`,
`Game.Inventory.allShopKinds`, `Game.Magic.elements`, `Game.Combat.guards`,
`Engine.directions` and `Engine.strikes` — so a constructor added to the game cannot be missed
here. The first tag of each list is the fallback and is emitted as the final `return`, which is
what keeps the function total against a column value that predates the catalogue.
-/

open Mythroads.Convex Mythroads.Convex.TypeScript
open Mythroads.Backend.Aggregate

/-- The label-to-constructor reader for one closed column. -/
structure Reader where
  /-- The exported function name. -/
  name : String
  /-- The compiled engine type it returns. -/
  type : String
  /-- The parameter name, which reads better as `label` for a slot and `direction` for a pan. -/
  parameter : String
  /-- Every wire label paired with the constructor expression it denotes, fallback first. -/
  cases : List (String × Expr)
  /-- A sentence naming what this reader is for. -/
  doc : String

/-- Emits one reader: a chain of label comparisons ending in the fallback constructor. -/
def readerFunction (reader : Reader) : Function :=
  let fallback := (reader.cases.head?.map Prod.snd).getD (ctor "unknown")
  { isAsync := false
    name := reader.name
    parameters := [{ name := reader.parameter, type := .string }]
    returns := engineType reader.type
    body :=
      (reader.cases.drop 1).map (fun (label, value) =>
        Statement.ifThen (eq (id reader.parameter) (.string label)) [.return value]) ++
      [.return fallback] }

/-- Equipment slots, read back from `playerItems.equippedSlot`. -/
def equipmentSlot : Reader where
  name := "equipmentSlotOf"
  type := "Game_Inventory_EquipmentSlot"
  parameter := "label"
  cases := Game.Inventory.allEquipmentSlots.map fun slot => (slot.label, ctor slot.label)
  doc := "The equipment slot a `playerItems.equippedSlot` column names."

/-- Shop kinds, read back from `rooms.shopKind`. -/
def shopKind : Reader where
  name := "shopKindOf"
  type := "Game_Inventory_ShopKind"
  parameter := "label"
  cases := Game.Inventory.allShopKinds.map fun kind => (kind.label, ctor kind.label)
  doc := "The shop a `rooms.shopKind` column names."

/-- Elements, read back from `combats.enemyElement`. -/
def element : Reader where
  name := "elementOf"
  type := "Game_Magic_Element"
  parameter := "label"
  cases := Game.Magic.elements.map fun value => (value.label, ctor value.label)
  doc := "The element a `combats.enemyElement` column names."

/-- Guard stances, read back from `combats.lastGuard` and from the wire. -/
def guard : Reader where
  name := "guardOf"
  type := "Game_Combat_Guard"
  parameter := "label"
  cases := Game.Combat.guards.map fun value => (value.label, ctor value.label)
  doc := "The stance a `combats.lastGuard` column, or a `combat.guard` event, names."

/-- Pan directions, read back from the wire. -/
def direction : Reader where
  name := "directionOf"
  type := "Direction"
  parameter := "direction"
  cases := Engine.directions.map fun value => (value.label, ctor value.label)
  doc := "The pan direction a `camera.move` event names."

/-- The constructor expression for one combat choice. -/
def strikeExpr : Engine.Strike → Expr
  | .physical attack => ctor "physical" [("attack", ctor attack.label)]
  | .magic technique => ctor "magic" [("technique", ctor technique.id)]

/-- Combat choices, read back from the twelve `combat.attack` literals. -/
def strike : Reader where
  name := "strikeOf"
  type := "Strike"
  parameter := "attack"
  cases := Engine.strikes.map fun value => (value.label, strikeExpr value)
  doc := "The combat choice a `combat.attack` event names."

/-- Every reader, in the order they appear in the generated file. -/
def readers : List Reader := [equipmentSlot, shopKind, element, guard, direction, strike]

-- The readers cover every label the catalogues define; nothing falls through silently.
#guard readers.map (fun reader => reader.cases.length) = [11, 5, 4, 4, 4, 12]

/-- The generated column-to-constructor readers. -/
def module : Module where
  provenance := some "proofs/Mythroads/Backend/Aggregate/Enums.lean"
  imports := [
    engineImport (readers.map fun reader => typeBinding reader.type)
  ]
  items := readers.map fun reader => .function (readerFunction reader)

end Mythroads.Backend.Aggregate.Enums
