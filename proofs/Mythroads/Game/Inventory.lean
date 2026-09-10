namespace Mythroads.Game.Inventory

abbrev AuthId := String
abbrev PlayerId := String
abbrev ItemId := String

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

end Mythroads.Game.Inventory
