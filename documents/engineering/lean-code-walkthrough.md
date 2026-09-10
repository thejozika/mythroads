# Reading Mythroads' Lean code

This document explains the Lean code that currently generates part of the Mythroads Convex
backend. It assumes no prior Lean experience.

The shortest useful mental model is:

> We describe endpoint shapes and security rules as Lean values, prove facts about those values,
> and run a Lean program that prints ordinary TypeScript for Convex.

Lean is therefore both the language in which we state the model and the program that generates the
backend artifact. Convex still executes TypeScript; it does not execute Lean inside a transaction.

## Current migration status

Lean now owns and generates these live backend surfaces:

- all eight Convex tables, fields, validators, and indexes;
- the complete 16-variant game command protocol and dispatch-result validator;
- the single public game mutation definition;
- the private inventory query and the `inventory.equip` mutation logic;
- the seeded Park–Miller random generator used by room codes, movement, encounters, and combat.
- event routing, authorization, authority attribution, persistence policy, persistence, and retention;
- player creation, shop transitions, turn advancement, encounter resolution, landing resolution,
  camera control, and room-random-state consumption.

The remaining large handwritten backend surfaces are room/movement transitions, combat, reactive
room queries, and the shared board/item/magic/encounter catalogues they consume. The migration is
therefore not yet the claimed end state of a fully Lean-authored backend.

## Why `Mythroads.Convex` is called a module

In Lean, every `.lean` file is a **module**. The module name follows its path below the source root:

| File | Lean module name |
|---|---|
| `proofs/Mythroads/Convex.lean` | `Mythroads.Convex` |
| `proofs/Mythroads/Authz.lean` | `Mythroads.Authz` |
| `proofs/Mythroads.lean` | `Mythroads` |

So this is not a choice between “a module” and “a file.” `Convex.lean` is the file, and
`Mythroads.Convex` is the name Lean uses when another file imports it.

We could put every declaration, proof, and generator in one file, but the separation gives each
file one job:

- [`Convex.lean`](../../proofs/Mythroads/Convex.lean) defines the small endpoint-description
  language and the two endpoint values.
- [`Authz.lean`](../../proofs/Mythroads/Authz.lean) gives authorization a pure meaning and proves
  properties about it.
- [`Main.lean`](../../proofs/Main.lean) translates the endpoint values into TypeScript text.
- [`Mythroads.lean`](../../proofs/Mythroads.lean) is the library's convenient public import.

This also lets Lean recompile and reuse modules independently. The name `Convex` means “our Lean
model of the Convex boundary”; it is not a separately deployed Convex service.

The generated TypeScript is also technically an ECMAScript module, but that is a separate use of
the word.

## The complete flow

```text
proofs/Mythroads/Convex.lean ── endpoint declarations ─┐
                                                      ├─> proofs/Emit.lean
proofs/Mythroads/Authz.lean  ── model and theorems ────┘          │
                                                                  │ lake exe
                                                                  │ mythroads-emit
                                                                  ▼
                                        every generated file, written to a
                                            staging directory in one run
                                                                  │
                                      scripts/lean/check-generated.mjs
                                             │ organize + format with Biome
                                             ▼
                                 convex/generated/game-api.generated.ts
                                             │
                         ┌───────────────────┴───────────────────┐
                         ▼                                       ▼
              query(...) in shops.ts                  mutation(...) in game.ts
                         │                                       │
                         └──────── ordinary Convex functions ────┘
```

The checked-in generated files are important: Vercel and Convex can build the application without
installing Lean. CI separately rebuilds it with Lean and rejects the commit if the result differs.

## A small Lean syntax primer

These are the constructs used in the current code:

| Lean | Meaning |
|---|---|
| `namespace Mythroads.Convex` | Put following names under a common prefix. |
| `inductive X where` | Define a choice between named cases, similar to a TypeScript discriminated union. |
| `structure X where` | Define a record with named fields, similar to a TypeScript interface. |
| `def name : Type := value` | Define a value or function. |
| `abbrev AuthId := String` | Give an existing type a more descriptive alias. |
| `List X` | A list whose members all have type `X`. |
| `Option X` | Either `some value` or `none`. |
| `.id "players"` | Constructor shorthand when Lean already knows the expected inductive type. |
| `fun item => ...` | An anonymous function, like `(item) => ...` in TypeScript. |
| `match x with` | Exhaustively select behavior for every constructor of `x`. |
| `theorem name (...) : claim := by` | State a proposition and begin its proof. |
| `rfl` | Prove equality by reducing both sides; they are definitionally the same. |
| `simp [...]` | Simplify using definitions and known rewrite rules. |

Unlike a TypeScript unit test, a Lean theorem is checked for every value admitted by its types. A
theorem quantified over `actor owner : AuthId` is not checking two example strings; it proves the
claim for all strings.

## 1. The endpoint language in `Convex.lean`

[`proofs/Mythroads/Convex.lean`](../../proofs/Mythroads/Convex.lean) does not directly query a
database. It defines a tiny data language—often called a domain-specific language, or DSL—that can
describe the supported endpoints.

### `ValueType`

```lean
inductive ValueType where
  | string
  | id (table : String)
  | optional (inner : ValueType)
  | custom (validator typeName : String)
```

A `ValueType` is syntax stored as data. For example:

```lean
.id "players"
```

means “generate a Convex `players` document ID,” while:

```lean
.optional .string
```

means “generate an optional string.” `Main.lean` later interprets these values twice: once as a
Convex runtime validator and once as a TypeScript type.

The `custom` case carries references such as `gameEventValidator` and `GameEvent`. Those validators
are now generated by a separate Lean schema module; `custom` is the link between the endpoint and
event generators rather than a handwritten TypeScript escape hatch.

### Records and policies

`Field` groups an argument name with its value type:

```lean
structure Field where
  name : String
  type : ValueType
```

`AuthRule` names the authorization policy attached to an endpoint:

```lean
inductive AuthRule where
  | inventoryOwner (playerArgument : String)
  | eventActor
```

And the step types describe the currently supported database orchestration:

- `QueryStep.readOwnedInventory` means an authenticated, indexed, bounded inventory read.
- `MutationStep.authorizeEvent` authenticates the event actor.
- `returnPriorCommand` makes repeated command IDs idempotent.
- `routeEvent` calculates and applies the event-specific behavior.
- `persistEvent` records the event and its result.

`EndpointPlan` makes the top-level distinction between a query and a mutation. Finally, `Endpoint`
collects the generated export name, arguments, result validator, authorization rule, and plan.

### The two concrete endpoint values

`inventoryEndpoint` says that the generated query:

- accepts a `playerId` validated as `v.id('players')`;
- returns an array of complete `playerItems` documents;
- is governed by the inventory-owner rule;
- reads at most 40 items using the `by_playerId` index.

`dispatchEndpoint` says that the generated mutation:

- accepts an optional idempotency key and a game event;
- returns a value checked by `dispatchResultValidator`;
- authorizes the event actor;
- performs authorize → deduplicate → route → persist in that order.

`gameApi` is simply the list consumed by the top-level API generator:

```lean
def gameApi : List Endpoint := [dispatchEndpoint]
```

Inventory has its own generator because putting its query in the dispatcher module created a
runtime import cycle through `shops.ts`. The policy value remains available to the authorization
proofs, while its executable query and equipment mutation are emitted together.

## 2. The security model in `Authz.lean`

[`proofs/Mythroads/Authz.lean`](../../proofs/Mythroads/Authz.lean) deliberately removes Convex,
Hanko, promises, and database mechanics. That leaves a small mathematical policy that Lean can
reason about.

```lean
def mayReadInventory (actor owner : AuthId) : Bool :=
  decide (actor = owner)
```

An inventory is readable exactly when the authenticated actor ID equals its stored owner ID.
`decide` converts the proposition `actor = owner` into a computable Boolean.

`readInventory` models the whole observable read:

```lean
def readInventory (actor : AuthId) (player : Player)
    (items : List InventoryItem) : Option (List InventoryItem) :=
  if actor = player.owner then
    some (items.filter fun item => item.playerId = player.id)
  else
    none
```

There are two independent protections here:

1. a caller whose identity differs from `player.owner` receives `none`;
2. an allowed caller receives only items whose `playerId` matches the requested player.

### What each theorem says

| Theorem | Plain-English claim |
|---|---|
| `mayReadInventory_iff` | Authorization returns true exactly when actor and owner are equal. |
| `otherPlayerCannotReadInventory` | A different actor is denied by the inventory endpoint policy. |
| `successfulInventoryReadIdentifiesOwner` | If that policy allows the call, the actor must be the owner. |
| `inventoryEndpointHasOwnerGuard` | The concrete endpoint declaration really carries the owner guard. |
| `otherPlayerGetsNoInventory` | The pure read returns no inventory to a different account. |
| `returnedInventoryContainsOnlyOwnedItems` | Every returned item belongs to the requested player. |
| `otherInventoriesAreNoninterfering` | Changes to other players' items cannot change this player's result. |

For example, `otherPlayerGetsNoInventory` receives a proof named `different` whose type is
`actor ≠ player.owner`. `simp [readInventory, different]` unfolds the function, uses that fact to
choose the false branch, and closes the result `= none`.

There are no `sorry` or `admit` escape hatches in these proofs. Lean's kernel checks them during
the build.

### Seeded randomness and frequency proofs

[`Random.lean`](../../proofs/Mythroads/Game/Random.lean) defines a Park–Miller state transition as
ordinary arithmetic over natural numbers. A draw returns both a bounded value and the next state,
so game randomness is explicit state that can be replayed rather than an invisible call to
`Math.random()`.

Its theorems establish that normalized seeds are valid, generator states remain below the modulus,
bounded draws remain below their requested bound, zero-probability events never hit, and certain
events hit every valid roll. `exact_favorable_bucket_count` proves the frequency interpretation:
across the complete uniform bucket space of a chance `favorable / possible`, exactly `favorable`
buckets hit. This proves the selection rule; it does not claim that a short pseudorandom run must
match that ratio exactly.

The generated state and counter are stored on the room and omitted from both public display and
private controller projections. Combat accuracy uses 10,000 integer buckets, while weighted events
draw directly from the sum of their integer weights.

## 3. The TypeScript generator in `Main.lean`

[`proofs/Main.lean`](../../proofs/Main.lean) is an executable Lean program. Its `main` function
prints TypeScript:

```lean
def main : IO Unit :=
  IO.print (generatedHeader ++ join "\n" (gameApi.map emitEndpoint))
```

The supporting functions are small interpreters:

- `emitValidator` maps `.id "players"` to `v.id('players')`.
- `emitType` maps the same value to `Id<'players'>`.
- `emitArgs` and `emitArgType` build argument declarations.
- `emitQueryStep` translates a supported query step into Convex handler code.
- `emitMutationSteps` translates the supported ordered mutation plan.
- `emitEndpoint` selects `QueryCtx` or `MutationCtx` and assembles the definition.

Pattern matching matters here. Lean checks that every `ValueType`, `QueryStep`, and endpoint-plan
case is handled. The mutation emitter currently accepts exactly one sequence and emits an explicit
error for any other sequence. That makes an unfinished extension fail visibly.

The dedicated generated inventory handler obtains `identity.tokenIdentifier` from `ctx.auth`, loads the
player, compares the verified identity with `player.authId`, and only then executes the indexed
item query. The client supplies the requested player ID, but it never supplies the identity used
to authorize the read.

## 4. The generated Convex code

Files under `convex/generated/` and `convex/events/validators.generated.ts` are exact formatted
outputs of the Lean executables. They contain the schema, protocol validators, pure random
functions, and full endpoint definition objects.

Two small handwritten files register those objects with Convex:

```ts
// convex/shops.ts
export const inventory = query(inventoryQueryDefinition)

// convex/game.ts
export const dispatch = mutation(dispatchMutationDefinition)
```

These adapters remain because Convex uses file-based API paths. Keeping the exports in
[`convex/shops.ts`](../../convex/shops.ts) and [`convex/game.ts`](../../convex/game.ts) preserves the
existing public references `api.shops.inventory` and `api.game.dispatch`.

They do not reimplement the handlers. The handler definitions supplied to `query(...)` and
`mutation(...)` came from Lean.

## 5. Generation and drift checking

[`scripts/lean/check-generated.mjs`](../../scripts/lean/check-generated.mjs) connects the Lean and
Node toolchains:

1. build and run `lake exe mythroads-emit <staging>` inside `proofs/`, which writes every
   generated file named by `outputs` in [`proofs/Emit.lean`](../../proofs/Emit.lean);
2. canonicalize the staging tree with the repository's installed Biome version — the
   `organizeImports` assist first, then the formatter — so Biome, not Lean, is the arbiter of
   import order and layout;
3. with `--write`, copy the staging tree over the repository;
4. without `--write`, compare the two trees byte for byte and fail on any file that is stale or
   missing, or on any committed `*.generated.ts` that no longer has a Lean source.

Use:

```bash
npm run proofs:generate  # deliberately refresh generated TypeScript
npm run proofs:check     # prove and verify that no generated drift exists
npm run proofs:axioms    # verify no theorem depends on sorry or on a native_decide axiom
npm run check            # run the entire repository gate
```

Never edit `game-api.generated.ts` directly. The next generation would overwrite the edit, and the
drift check is specifically designed to reject that split source of truth.

## What Lean owns today—and what it does not

The boundary is intentionally visible:

| Lean-authored today | Still handwritten TypeScript today |
|---|---|
| All eight tables, indexes, and document validators | Tiny Convex registration/re-export modules |
| The complete `GameEvent` union, policy, authorization, router, and persistence | Hanko provider configuration |
| Room, movement, combat, encounter, shop, inventory, camera, and turn operations | React, browser input, and Three.js rendering |
| Board graph, controller directions, items, magic, enemy, and encounter catalogs | Convex's own `_generated/` client/server bindings |
| Seeded random transition and exact bucket-count theorem | A proof that the TypeScript emitter preserves Lean semantics |
| Ownership, equipment, road direction, combat-table, catalog, and schema theorems | Convex, Hanko, V8, and Lean's kernel as trusted infrastructure |

The accurate statement is now:

> Lean is the source of truth for all current application-owned backend behavior and stable shared
> game rules. Convex executes generated TypeScript, while small handwritten adapters preserve its
> file-based API paths. The whole game is not “proved correct”: only the named invariants are proved,
> and emitter/platform correctness remains in the trusted computing base.

The remaining architectural gap is compiler assurance. The current restricted TypeScript AST is
structural and exhaustive, but some identifiers and module imports are still strings, and its
semantic preservation has not been proved. Convex integration tests, TypeScript compilation, and
byte-for-byte drift checks currently guard that boundary. A future typed effect layer and reference
interpreter can shrink it further without changing the generated public API.

The broader design is documented in [`formal-rules.md`](formal-rules.md). The researched path from
this initial slice to an almost entirely Lean-authored backend is in
[`lean-full-backend-plan.md`](lean-full-backend-plan.md).

## How to extend it safely

For a new kind of rule or endpoint, the durable workflow is:

1. Add the smallest necessary constructor to the Lean DSL.
2. Define its pure semantics in Lean.
3. State and prove the invariant that matters.
4. Add the corresponding exhaustive emitter case.
5. Add adapter tests that call the generated Convex function as multiple identities.
6. Regenerate the TypeScript and review the diff.
7. Run the complete repository check.

For example, moving equipment changes into Lean should not begin by embedding arbitrary
TypeScript strings. It should introduce typed operations such as “load owned item,” “clear slot,”
and “equip item,” then prove that a successful transition cannot equip another player's item and
cannot leave two items in one slot.

That pattern is the real payoff: the Lean value used in a theorem is also consumed by the program
that generates the deployed endpoint, reducing the chance that a proof describes one policy while
production runs another.
