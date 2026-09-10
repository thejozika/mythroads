import Mythroads.Convex
import Mythroads.Identity

namespace Mythroads.Authz

structure Player where
  id : PlayerId
  owner : AuthId
  deriving Repr, DecidableEq

structure InventoryItem where
  id : String
  playerId : PlayerId
  deriving Repr, DecidableEq

def mayReadInventory (actor owner : AuthId) : Bool :=
  decide (actor = owner)

def endpointAllowsInventoryRead
    (endpoint : Convex.Endpoint) (actor owner : AuthId) : Bool :=
  match endpoint.auth with
  | .inventoryOwner _ => mayReadInventory actor owner
  | .eventActor => false

def readInventory (actor : AuthId) (player : Player)
    (items : List InventoryItem) : Option (List InventoryItem) :=
  if actor = player.owner then
    some (items.filter fun item => item.playerId = player.id)
  else
    none

theorem mayReadInventory_iff (actor owner : AuthId) :
    mayReadInventory actor owner = true ↔ actor = owner := by
  simp [mayReadInventory]

theorem otherPlayerCannotReadInventory (actor owner : AuthId) (different : actor ≠ owner) :
    endpointAllowsInventoryRead Convex.inventoryEndpoint actor owner = false := by
  simp [endpointAllowsInventoryRead, Convex.inventoryEndpoint, mayReadInventory, different]

theorem successfulInventoryReadIdentifiesOwner (actor owner : AuthId)
    (allowed : endpointAllowsInventoryRead Convex.inventoryEndpoint actor owner = true) :
    actor = owner := by
  exact (mayReadInventory_iff actor owner).mp allowed

theorem inventoryEndpointHasOwnerGuard :
    Convex.inventoryEndpoint.auth = .inventoryOwner "playerId" := by
  rfl

theorem otherPlayerGetsNoInventory (actor : AuthId) (player : Player)
    (items : List InventoryItem) (different : actor ≠ player.owner) :
    readInventory actor player items = none := by
  simp [readInventory, different]

theorem returnedInventoryContainsOnlyOwnedItems (actor : AuthId) (player : Player)
    (items visible : List InventoryItem)
    (read : readInventory actor player items = some visible)
    (item : InventoryItem) (member : item ∈ visible) : item.playerId = player.id := by
  simp only [readInventory] at read
  split at read
  · cases read
    exact of_decide_eq_true (List.mem_filter.mp member).2
  · contradiction

theorem otherInventoriesAreNoninterfering (actor : AuthId) (player : Player)
    (before after : List InventoryItem)
    (sameOwnedItems :
      before.filter (fun item => item.playerId = player.id) =
      after.filter (fun item => item.playerId = player.id)) :
    readInventory actor player before = readInventory actor player after := by
  simp [readInventory, sameOwnedItems]

end Mythroads.Authz
