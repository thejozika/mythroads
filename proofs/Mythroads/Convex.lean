import Mythroads.Convex.Module
import Mythroads.Convex.Query
import Mythroads.Convex.Ty

namespace Mythroads.Convex

/-! # The write-side game API

This module describes the two endpoints that make up `convex/generated/game-api.generated.ts` —
the public `game.dispatch` mutation and the internal `game.execute` transaction it forwards to —
and renders them.

Two things changed here when the value universe was unified. Argument types are `Ty` rather than
the old `ValueType`, whose `custom (validator typeName : String)` constructor let the runtime
validator and the static type be written independently; `Ty.external` keeps the pair in one
constructor. And the body is built from the TypeScript syntax tree instead of pasted together as
strings with hand-counted eight-space indentation, which is what `emitQueryStep` and
`emitMutationSteps` used to do.

Two visible consequences in the generated file, both deliberate:

* `commandId` is now typed `commandId?: string` rather than `commandId: string | undefined`.
  Convex does not transport `undefined` as a value, so the old annotation described a shape the
  server cannot produce; `Ty.tsType` renders an optional object field correctly.
* `if (priorResult) return priorResult` is now braced, because the statement tree has one `ifThen`
  form and every other generated conditional is braced too.

`Endpoint.auth` stays a separate `AuthRule` because `Mythroads/Authz.lean` proves the inventory
confidentiality theorems against it.
-/

/-- How an endpoint decides whether its caller is allowed to run it. -/
inductive AuthRule where
  /-- Only the account that owns the player named by this argument. -/
  | inventoryOwner (playerArgument : String)
  /-- The authority attached to the event being dispatched. -/
  | eventActor
  deriving Repr, DecidableEq

/-- One declared endpoint argument. -/
structure Field where
  /-- The argument name, used both in the validator object and in the destructuring binder. -/
  name : String
  /-- The argument's value shape. -/
  type : Ty
  deriving Repr

/-- The read plan of a query endpoint. -/
inductive QueryStep where
  /-- Authenticate, confirm the caller owns the player named by `playerArgument`, and return that
  hero's inventory. The table and index are not parameters: this step *is* the inventory read, and
  `Index.playerItemsByPlayerId` is the only index that can serve it. -/
  | readOwnedInventory (playerArgument : String) (limit : Nat)
  deriving Repr, DecidableEq

/-- One stage of the transactional event loop. -/
inductive MutationStep where
  /-- Resolve and check the event's authority, yielding the actor's auth id. -/
  | authorizeEvent
  /-- Return the recorded result if this command id has already been applied. -/
  | returnPriorCommand
  /-- Load the room, run the rules over the event, and write the effects they return. -/
  | routeEvent
  /-- Append the event and its result to the durable log. -/
  | persistEvent
  deriving Repr, DecidableEq

/-- Describes whether a generated endpoint reads, executes a transaction, or forwards to one. -/
inductive EndpointPlan where
  /-- A read-only query. -/
  | query (steps : List QueryStep)
  /-- A transaction. -/
  | mutation (steps : List MutationStep)
  /-- A mutation that only forwards to another one, named by a function reference path. -/
  | forwardMutation (functionReference : List String)
  deriving Repr, DecidableEq

/-- A generated Convex endpoint definition. -/
structure Endpoint where
  /-- The exported binding name a registrar wraps. -/
  exportName : String
  /-- The declared arguments. -/
  args : List Field
  /-- The declared return shape. -/
  returns : Ty
  /-- The authorization rule the endpoint enforces. -/
  auth : AuthRule
  /-- What the endpoint does. -/
  plan : EndpointPlan
  deriving Repr

/-- The owner-only inventory read. Not part of `gameApi`; it is the endpoint
`Mythroads/Authz.lean` reasons about. -/
def inventoryEndpoint : Endpoint where
  exportName := "inventoryQueryDefinition"
  args := [{ name := "playerId", type := .id .players }]
  returns := .array (.document .playerItems)
  auth := .inventoryOwner "playerId"
  plan := .query [.readOwnedInventory "playerId" 40]

/-- The dispatch result, shared by both write endpoints. -/
private def dispatchResult : Ty := .external "dispatchResultValidator" "DispatchResult"

/-- The only client-callable mutation. It delegates without writing state itself. -/
def dispatchEndpoint : Endpoint where
  exportName := "dispatchMutationDefinition"
  args := [
    { name := "commandId", type := .optional .string },
    { name := "event", type := .external "gameEventValidator" "GameEvent" }
  ]
  returns := dispatchResult
  auth := .eventActor
  plan := .forwardMutation ["internal", "game", "execute"]

/-- The internal transactional event loop: authorize, deduplicate, route, and persist. -/
def executeEndpoint : Endpoint where
  exportName := "executeMutationDefinition"
  args := dispatchEndpoint.args
  returns := dispatchResult
  auth := .eventActor
  plan := .mutation [.authorizeEvent, .returnPriorCommand, .routeEvent, .persistEvent]

/-- All generated registrations that form the write-side game API. -/
def gameApi : List Endpoint := [dispatchEndpoint, executeEndpoint]

open TypeScript

/-- Reads the caller's own inventory, after proving the caller owns the hero. -/
private def queryStepBody : QueryStep → List Statement
  | .readOwnedInventory playerArgument limit =>
    let identity := Expr.identifier "identity"
    let player := Expr.identifier "player"
    [ .constDecl "identity"
        (.await (.call (.property (.property (.identifier "ctx") "auth") "getUserIdentity") [])),
      .ifThen (.prefix "!" identity)
        [.throw (.new "ConvexError" [.string "Sign in to view an inventory."])],
      .constDecl "player" (Query.get (.identifier playerArgument)),
      .ifThen (.prefix "!" player)
        [.throw (.new "ConvexError" [.string "That hero does not exist."])],
      .ifThen (.binary (.prefix "!" (.property player "authId")) "||"
        (.binary (.property identity "tokenIdentifier") "!==" (.property player "authId")))
        [.throw (.new "ConvexError" [.string "That inventory belongs to another account."])],
      .return (Query.indexedRead .playerItems .playerItemsByPlayerId
        [.identifier playerArgument] (.take limit) "q") ]

/-- One stage of the transactional event loop, as statements. -/
private def mutationStepBody : MutationStep → List Statement
  | .authorizeEvent =>
      [.constDecl "actorAuthId" (.await (.call (.identifier "authorizeGameEvent")
        [.identifier "ctx", .identifier "event"]))]
  | .returnPriorCommand =>
      [.constDecl "priorResult" (.await (.call (.identifier "priorDispatchResult")
        [.identifier "ctx", .identifier "commandId", .identifier "actorAuthId"])),
       .ifThen (.identifier "priorResult") [.return (.identifier "priorResult")]]
  | .routeEvent =>
      [.constDecl "result" (.await (.call (.identifier "applyGameEvent")
        [.identifier "ctx", .identifier "event", .identifier "actorAuthId"]))]
  | .persistEvent =>
      [.expression (.await (.call (.identifier "persistGameEvent")
        [.identifier "ctx", .identifier "event", .identifier "result", .identifier "commandId",
          .identifier "actorAuthId"])),
       .return (.identifier "result")]

/-- The context type an endpoint's handler receives. -/
private def contextType : EndpointPlan → TsType
  | .query _ => .named "QueryCtx"
  | .mutation _ | .forwardMutation _ => .named "MutationCtx"

/-- A dotted function reference such as `internal.game.execute`. -/
private def referenceExpr : List String → Expr
  | [] => .identifier "internal"
  | head :: rest => rest.foldl (fun acc segment => .property acc segment) (.identifier head)

/-- The handler body for a plan. -/
private def planBody (endpoint : Endpoint) : List Statement :=
  match endpoint.plan with
  | .query steps => steps.flatMap queryStepBody
  | .mutation steps => steps.flatMap mutationStepBody
  | .forwardMutation reference =>
      [.return (.await (.call (.property (.identifier "ctx") "runMutation")
        [referenceExpr reference, .shorthand (endpoint.args.map (·.name))]))]

/-- Renders one endpoint as an exported `{ args, returns, handler }` record. -/
def endpointDefinition (endpoint : Endpoint) : EndpointDefinition where
  name := endpoint.exportName
  arguments := endpoint.args.map fun field => (field.name, field.type.validator)
  returns := endpoint.returns.validator
  handler := {
    parameters := [
      { name := "ctx", type := contextType endpoint.plan },
      { name := "{ " ++ TypeScript.join ", " (endpoint.args.map (·.name)) ++ " }",
        type := (Ty.obj (endpoint.args.map fun field => (field.name, field.type))).tsType }
    ]
    returns := match endpoint.plan with
      | .query _ => none
      | .mutation _ | .forwardMutation _ => some (.promise endpoint.returns.tsType)
    body := planBody endpoint
  }

/-- The write-side game API module: the public `dispatch` mutation and the internal `execute`
transaction it forwards to. -/
def module : Module where
  provenance := some "proofs/Mythroads/*.lean"
  imports := [
    { source := "convex/values", bindings := [{ name := "v" }] },
    { source := "../_generated/api", bindings := [{ name := "internal" }] },
    { source := "../_generated/server", bindings := [{ name := "MutationCtx", isType := true }] },
    { source := "../auth/authorization", bindings := [{ name := "authorizeGameEvent" }] },
    { source := "../events/persistence", bindings := [
      { name := "persistGameEvent" }, { name := "priorDispatchResult" }] },
    { source := "./aggregate/boundary.generated", bindings := [{ name := "applyGameEvent" }] },
    { source := "../events/validators", bindings := [
      { name := "dispatchResultValidator" }, { name := "gameEventValidator" },
      { name := "DispatchResult", isType := true }, { name := "GameEvent", isType := true }] }
  ]
  items := gameApi.map fun endpoint => .endpoint (endpointDefinition endpoint)

end Mythroads.Convex
