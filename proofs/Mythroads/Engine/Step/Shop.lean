import Mythroads.Engine.Event

/-!
# Shopping and equipment

Buying keeps the turn: a hero may buy any number of items and only `shop.leave` ends
the visit, matching the generated handlers, which never touch the room banner on a
purchase. Affordability is checked *before* the hero is charged, so the truncated
subtraction in `PlayerState.spent` can never silently swallow a debt — `gold : Nat`
plus that check is the whole of "gold is never negative".

Equipping is the one gameplay write that is neither turn-gated nor phase-gated: the
generated `equipItem` only checks ownership, so a hero may re-equip at any moment,
including during someone else's turn. The slot transition itself is not restated here
— it reuses `Game.Inventory.equipInventory`, which already carries the proofs that the
requested item takes the slot and that whatever held that slot gives it up.
-/

namespace Mythroads.Engine.Shop

open Mythroads.Game

/-- `shop.buy`: the item must be stocked by this shop and affordable. -/
def buy (s : State) (p : PlayerState) (kind : Inventory.ShopKind) (itemId : Mythroads.ItemId) :
    Outcome :=
  match itemById itemId with
  | none => .error .unknownItem
  | some item =>
      if item.shop ≠ kind then .error .itemNotHere
      else if p.gold < item.price then .error .insufficientGold
      else
        .ok (s.mapPlayer p.id fun q =>
              { q.spent item.price with
                  items := q.items ++
                    [{ rowId := q.id ++ "-item-" ++ toString (q.items.length + 1), itemId }] },
             [.persistPlayer p.id, .appendLog "shop.buy"])

/-- `shop.leave`: the only exit from a shop, and it passes the turn. -/
def leave (s : State) (p : PlayerState) : Outcome :=
  .ok (s.advanceTurn (p.name ++ " finished shopping."),
       [.persistRoom, .appendLog "shop.leave"])

/-- View one owned copy as the inventory model `Game.Inventory` reasons about. -/
def asItem (owner : Mythroads.PlayerId) (o : Owned) : Inventory.Item :=
  { id := o.rowId, playerId := owner, equippedSlot := o.equippedSlot,
    supportedSlots := (itemById o.itemId).elim [] Inventory.ItemDefinition.slots }

/-- Copy the slot decisions back onto the owned rows, which keep the catalogue identity. -/
def rejoin (owned : List Owned) (items : List Inventory.Item) : List Owned :=
  List.zipWith (fun o i => { o with equippedSlot := i.equippedSlot }) owned items

/--
`inventory.equip`: move an owned copy into a slot, reusing the proved inventory
transition. The three inventory refusals collapse into two engine errors, because the
ownership refusal is already unreachable behind the authority gate.
-/
def equip (s : State) (actor : Mythroads.AuthId) (p : PlayerState) (rowId : OwnedItemId)
    (slot : Inventory.EquipmentSlot) : Outcome :=
  match Inventory.equipInventory actor p.owner p.id rowId slot (p.items.map (asItem p.id)) with
  | .error .notOwner => .error .unauthorized
  | .error _ => .error .cannotEquip
  | .ok items =>
      .ok (s.mapPlayer p.id fun q => { q with items := rejoin q.items items },
           [.persistPlayer p.id, .appendLog "inventory.equip"])

end Mythroads.Engine.Shop
