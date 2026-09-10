namespace Mythroads.Convex

inductive ValueType where
  | string
  | id (table : String)
  | optional (inner : ValueType)
  | custom (validator typeName : String)
  deriving Repr, DecidableEq

structure Field where
  name : String
  type : ValueType
  deriving Repr, DecidableEq

inductive AuthRule where
  | inventoryOwner (playerArgument : String)
  | eventActor
  deriving Repr, DecidableEq

inductive QueryStep where
  | readOwnedInventory (playerArgument table index : String) (limit : Nat)
  deriving Repr, DecidableEq

inductive MutationStep where
  | authorizeEvent
  | returnPriorCommand
  | routeEvent
  | persistEvent
  deriving Repr, DecidableEq

/-- Describes whether a generated endpoint reads, executes a transaction, or forwards to one. -/
inductive EndpointPlan where
  | query (steps : List QueryStep)
  | mutation (steps : List MutationStep)
  | forwardMutation (functionReference : String)
  deriving Repr, DecidableEq

structure Endpoint where
  exportName : String
  args : List Field
  returnsValidator : String
  auth : AuthRule
  plan : EndpointPlan
  deriving Repr, DecidableEq

def inventoryEndpoint : Endpoint where
  exportName := "inventoryQueryDefinition"
  args := [{ name := "playerId", type := .id "players" }]
  returnsValidator := "v.array(schema.doc('playerItems'))"
  auth := .inventoryOwner "playerId"
  plan := .query [.readOwnedInventory "playerId" "playerItems" "by_playerId" 40]

/-- The only client-callable mutation. It delegates without writing state itself. -/
def dispatchEndpoint : Endpoint where
  exportName := "dispatchMutationDefinition"
  args := [
    { name := "commandId", type := .optional .string },
    { name := "event", type := .custom "gameEventValidator" "GameEvent" }
  ]
  returnsValidator := "dispatchResultValidator"
  auth := .eventActor
  plan := .forwardMutation "internal.game.execute"

/-- The internal transactional event loop: authorize, deduplicate, route, and persist. -/
def executeEndpoint : Endpoint where
  exportName := "executeMutationDefinition"
  args := dispatchEndpoint.args
  returnsValidator := "dispatchResultValidator"
  auth := .eventActor
  plan := .mutation [.authorizeEvent, .returnPriorCommand, .routeEvent, .persistEvent]

/-- All generated registrations that form the write-side game API. -/
def gameApi : List Endpoint := [dispatchEndpoint, executeEndpoint]

end Mythroads.Convex
