import Mythroads.Convex.Module
import Mythroads.Game.Magic
import Mythroads.Identity

namespace Mythroads.Game.Inventory

open Mythroads.Convex
open Mythroads.Convex.TypeScript
open Mythroads.Game.Magic

inductive EquipmentSlot where
  | weapon
  | helmet
  | body
  | gloves
  | boots
  | cape
  | amulet
  | ringLeft
  | ringRight
  | offensiveMagic
  | defensiveMagic
  deriving Repr, DecidableEq

def EquipmentSlot.label : EquipmentSlot → String
  | .weapon => "weapon"
  | .helmet => "helmet"
  | .body => "body"
  | .gloves => "gloves"
  | .boots => "boots"
  | .cape => "cape"
  | .amulet => "amulet"
  | .ringLeft => "ringLeft"
  | .ringRight => "ringRight"
  | .offensiveMagic => "offensiveMagic"
  | .defensiveMagic => "defensiveMagic"

def allEquipmentSlots : List EquipmentSlot :=
  [.weapon, .helmet, .body, .gloves, .boots, .cape, .amulet, .ringLeft, .ringRight,
    .offensiveMagic, .defensiveMagic]

def EquipmentSlot.title : EquipmentSlot → String
  | .helmet => "Helmet" | .amulet => "Amulet" | .weapon => "Weapon"
  | .body => "Body" | .cape => "Cape / Pack" | .gloves => "Gloves" | .boots => "Boots"
  | .ringLeft => "Ring I" | .ringRight => "Ring II"
  | .offensiveMagic => "Battle Spell" | .defensiveMagic => "Magic Ward"

def EquipmentSlot.icon : EquipmentSlot → String
  | .helmet => "⸙" | .amulet => "✧" | .weapon => "⚔" | .body => "◈"
  | .cape => "◒" | .gloves => "◖" | .boots => "◡"
  | .ringLeft | .ringRight => "○" | .offensiveMagic => "✦"
  | .defensiveMagic => "⌾"

def displayedEquipmentSlots : List EquipmentSlot := [
  .helmet, .amulet, .weapon, .body, .cape, .gloves, .boots, .ringLeft, .ringRight,
  .offensiveMagic, .defensiveMagic
]

inductive ShopKind where
  | armoury | jeweller | weapons | items | magic
  deriving Repr, DecidableEq

/-- Every shop kind, in catalogue order. The boundary walks this to read the `rooms.shopKind`
column back into the engine's `ShopKind`. -/
def allShopKinds : List ShopKind := [.armoury, .jeweller, .weapons, .items, .magic]

def ShopKind.label : ShopKind → String
  | .armoury => "armoury" | .jeweller => "jeweller" | .weapons => "weapons"
  | .items => "items" | .magic => "magic"

structure ItemDefinition where
  id : String
  name : String
  icon : String
  price : Nat
  shop : ShopKind
  description : String
  slots : List EquipmentSlot
  spell : Option Element := none
  wardPowerHundredths : Option Nat := none
  deriving Repr, DecidableEq

def itemDefinitions : List ItemDefinition := [
  { id := "oak_blade", name := "Oak Blade", icon := "⚔", price := 5, shop := .weapons,
    description := "A dependable first weapon.", slots := [.weapon] },
  { id := "iron_sword", name := "Iron Sword", icon := "†", price := 12, shop := .weapons,
    description := "Heavy, honest steel.", slots := [.weapon] },
  { id := "trail_helm", name := "Trail Helm", icon := "⸙", price := 7, shop := .armoury,
    description := "Keeps branches and blows away.", slots := [.helmet] },
  { id := "padded_coat", name := "Padded Coat", icon := "◈", price := 8, shop := .armoury,
    description := "Light protection for long roads.", slots := [.body] },
  { id := "grip_gloves", name := "Grip Gloves", icon := "◖", price := 5, shop := .armoury,
    description := "Never drop the important thing.", slots := [.gloves] },
  { id := "swift_boots", name := "Swift Boots", icon := "◡", price := 6, shop := .armoury,
    description := "Made for muddy shortcuts.", slots := [.boots] },
  { id := "ranger_cape", name := "Ranger Cape", icon := "◒", price := 9, shop := .armoury,
    description := "A cape with a secret travel pack.", slots := [.cape] },
  { id := "amber_amulet", name := "Amber Amulet", icon := "✧", price := 9, shop := .jeweller,
    description := "Warm luck trapped in amber.", slots := [.amulet] },
  { id := "copper_ring", name := "Copper Ring", icon := "○", price := 6, shop := .jeweller,
    description := "Simple magic, carefully set.", slots := [.ringLeft, .ringRight] },
  { id := "moon_ring", name := "Moon Ring", icon := "◉", price := 13, shop := .jeweller,
    description := "Glints when danger is close.", slots := [.ringLeft, .ringRight] },
  { id := "red_potion", name := "Red Potion", icon := "♥", price := 4, shop := .items,
    description := "A future-use healing item.", slots := [] },
  { id := "smoke_bomb", name := "Smoke Bomb", icon := "◌", price := 5, shop := .items,
    description := "A future-use escape item.", slots := [] },
  { id := "spark_wand", name := "Spark Wand", icon := "⁂", price := 11, shop := .magic,
    description := "Crackles with beginner magic.", slots := [.weapon] },
  { id := "ward_charm", name := "Ward Charm", icon := "❈", price := 10, shop := .magic,
    description := "A charm against wild curses.", slots := [.amulet] },
  { id := "ember_grimoire", name := "Ember Grimoire", icon := "♨", price := 8, shop := .magic,
    description := "Grants Ember Blast and Scorch Armor.", slots := [.offensiveMagic], spell := some .fire },
  { id := "tide_grimoire", name := "Tide Grimoire", icon := "≋", price := 10, shop := .magic,
    description := "Grants Tide Needle and Undertow.", slots := [.offensiveMagic], spell := some .water },
  { id := "gale_grimoire", name := "Gale Grimoire", icon := "〰", price := 10, shop := .magic,
    description := "Grants Gale Blade and Wind Shear.", slots := [.offensiveMagic], spell := some .wind },
  { id := "stone_grimoire", name := "Stone Grimoire", icon := "◆", price := 11, shop := .magic,
    description := "Grants Stone Crash and Calcify.", slots := [.offensiveMagic], spell := some .earth },
  { id := "aegis_script", name := "Aegis Script", icon := "⌾", price := 9, shop := .magic,
    description := "Strengthens Arcane Ward against battle magic.", slots := [.defensiveMagic],
    wardPowerHundredths := some 35 }
]

theorem everyItemHasNonemptyIdentity :
    itemDefinitions.all (fun item => !item.id.isEmpty ∧ !item.name.isEmpty) = true := by decide

private def renderSlots (slots : List EquipmentSlot) : String :=
  "[" ++ join ", " (slots.map fun slot => quote slot.label) ++ "]"

private def renderItem (item : ItemDefinition) : String :=
  "    { id: " ++ quote item.id ++ ", name: " ++ quote item.name ++ ", icon: " ++
  quote item.icon ++ ", price: " ++ toString item.price ++ ", shop: " ++ quote item.shop.label ++
  ", description: " ++ quote item.description ++ ", slots: " ++ renderSlots item.slots ++
  (match item.spell with | none => "" | some value => ", spell: " ++ quote value.label) ++
  (match item.wardPowerHundredths with
    | none => ""
    | some value => ", wardPower: " ++ toString value ++ " / 100") ++ " },\n"

/-- The body of `shared/generated/item.generated.ts`, assembled from the catalogue above. -/
private def body : String :=
  "export type ShopKind = 'armoury' | 'jeweller' | 'weapons' | 'items' | 'magic'\n" ++
  "export type EquipmentSlot = " ++
  join " | " (allEquipmentSlots.map fun slot => quote slot.label) ++ "\n" ++
  "export type ItemDefinition = { id: string; name: string; icon: string; price: number; shop: ShopKind; description: string; slots: EquipmentSlot[]; spell?: Element; wardPower?: number }\n\n" ++
  "export const EQUIPMENT_SLOTS: { id: EquipmentSlot; label: string; icon: string }[] = [\n" ++
  join "" (displayedEquipmentSlots.map fun slot => "    { id: " ++ quote slot.label ++
    ", label: " ++ quote slot.title ++ ", icon: " ++ quote slot.icon ++ " },\n") ++ "]\n\n" ++
  "export const ITEMS: ItemDefinition[] = [\n" ++ join "" (itemDefinitions.map renderItem) ++ "]\n\n" ++
  "export const getItem = (id: string) => ITEMS.find((item) => item.id === id)\n" ++
  "export const itemsForShop = (shop: ShopKind) => ITEMS.filter((item) => item.shop === shop)\n\n" ++
  "export function equippedMagic(items: { itemId: string; equippedSlot?: EquipmentSlot }[]) {\n" ++
  "    const offensive = items.find((item) => item.equippedSlot === 'offensiveMagic')\n" ++
  "    const defensive = items.find((item) => item.equippedSlot === 'defensiveMagic')\n" ++
  "    const spell = getItem(offensive?.itemId ?? 'ember_grimoire')?.spell ?? 'fire'\n" ++
  "    return { spell, actions: MAGIC_LOADOUTS[spell], wardPower: getItem(defensive?.itemId ?? 'aegis_script')?.wardPower ?? 0.35 }\n}\n"

structure Item where
  id : ItemId
  playerId : PlayerId
  supportedSlots : List EquipmentSlot
  equippedSlot : Option EquipmentSlot
  deriving Repr, DecidableEq

inductive EquipError where
  | notOwner
  | missingItem
  | incompatibleSlot
  deriving Repr, DecidableEq

def equipOne (requestedItem : ItemId) (slot : EquipmentSlot) (item : Item) : Item :=
  if item.id = requestedItem then
    { item with equippedSlot := some slot }
  else if item.equippedSlot = some slot then
    { item with equippedSlot := none }
  else
    item

def equipInventory (actor owner : AuthId) (playerId : PlayerId) (requestedItem : ItemId)
    (slot : EquipmentSlot) (items : List Item) : Except EquipError (List Item) :=
  if actor ≠ owner then
    .error .notOwner
  else
    match items.find? fun item => item.id = requestedItem ∧ item.playerId = playerId with
    | none => .error .missingItem
    | some item =>
        if slot ∈ item.supportedSlots then
          .ok (items.map (equipOne requestedItem slot))
        else
          .error .incompatibleSlot

theorem otherPlayerCannotEquip (actor owner : AuthId) (playerId : PlayerId)
    (requestedItem : ItemId) (slot : EquipmentSlot) (items : List Item)
    (different : actor ≠ owner) :
    equipInventory actor owner playerId requestedItem slot items = .error .notOwner := by
  simp [equipInventory, different]

theorem equipPreservesItemOwner (requestedItem : ItemId) (slot : EquipmentSlot) (item : Item) :
    (equipOne requestedItem slot item).playerId = item.playerId := by
  unfold equipOne
  split
  · rfl
  · split <;> rfl

theorem selectedItemUsesRequestedSlot (requestedItem : ItemId) (slot : EquipmentSlot) (item : Item)
    (selected : item.id = requestedItem) :
    (equipOne requestedItem slot item).equippedSlot = some slot := by
  simp [equipOne, selected]

theorem otherItemsReleaseRequestedSlot (requestedItem : ItemId) (slot : EquipmentSlot)
    (item : Item) (other : item.id ≠ requestedItem) :
    (equipOne requestedItem slot item).equippedSlot ≠ some slot := by
  unfold equipOne
  rw [if_neg other]
  split
  · simp
  · assumption

/-- The item catalogue, equipment slots, and the equipped-magic projection. -/
def module : Mythroads.Convex.Module where
  provenance := some "proofs/Mythroads/Game/Inventory.lean"
  imports := [{ source := "../magic.system.ts", bindings := [
    { name := "MAGIC_LOADOUTS" }, { name := "Element", isType := true }] }]
  items := [.raw body]

end Mythroads.Game.Inventory
