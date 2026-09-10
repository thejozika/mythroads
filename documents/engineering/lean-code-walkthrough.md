# Reading Mythroads' Lean code

This document explains the Lean code that currently generates part of the Mythroads Convex
backend. It assumes no prior Lean experience.

The shortest useful mental model is:

> We describe endpoint shapes and security rules as Lean values, prove facts about those values,
> and run a Lean program that prints ordinary TypeScript for Convex.

Lean is therefore both the language in which we state the model and the program that generates the
backend artifact. Convex still executes TypeScript; it does not execute Lean inside a transaction.

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
                                                      ├─> proofs/Main.lean
proofs/Mythroads/Authz.lean  ── model and theorems ────┘          │
                                                                  │ lake exe
                                                                  ▼
                                         TypeScript printed to standard output
                                                                  │
                                      scripts/lean/check-generated.mjs
                                             │ format with Biome
                                             ▼
                                 convex/generated/game-api.generated.ts
                                             │
                         ┌───────────────────┴───────────────────┐
                         ▼                                       ▼
              query(...) in shops.ts                  mutation(...) in game.ts
                         │                                       │
                         └──────── ordinary Convex functions ────┘
```

The checked-in generated file is important: Vercel and Convex can build the application without
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

The `custom` case currently carries raw names such as `gameEventValidator` and `GameEvent`. That is
a pragmatic bridge to validators and types still authored in TypeScript. It is not yet a fully
Lean-owned event schema.

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

`gameApi` is simply the list consumed by the generator:

```lean
def gameApi : List Endpoint := [inventoryEndpoint, dispatchEndpoint]
```

Adding a value to this list is what asks the Lean executable to emit another endpoint definition.

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

The generated inventory handler obtains `identity.tokenIdentifier` from `ctx.auth`, loads the
player, compares the verified identity with `player.authId`, and only then executes the indexed
item query. The client supplies the requested player ID, but it never supplies the identity used
to authorize the read.

## 4. The generated Convex code

[`convex/generated/game-api.generated.ts`](../../convex/generated/game-api.generated.ts) is the
exact formatted output of the Lean executable. It contains full definition objects, including
arguments, return validators, context types, and handler bodies.

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

1. run `lake exe mythroads-codegen` inside `proofs/`;
2. capture the TypeScript printed by Lean;
3. format it through the repository's installed Biome version;
4. with `--write`, replace the generated artifact;
5. without `--write`, compare bytes and fail if the committed file is stale.

Use:

```bash
npm run proofs:generate  # deliberately refresh generated TypeScript
npm run proofs:check     # prove and verify that no generated drift exists
npm run check            # run the entire repository gate
```

Never edit `game-api.generated.ts` directly. The next generation would overwrite the edit, and the
drift check is specifically designed to reject that split source of truth.

## What Lean owns today—and what it does not

The boundary is intentionally visible:

| Lean-authored today | Still handwritten TypeScript today |
|---|---|
| Endpoint argument descriptions | The complete `GameEvent` union |
| Query versus mutation selection | Detailed movement, combat, shop, and room transitions |
| Inventory query orchestration | Event routing implementations |
| Dispatch orchestration order | Persistence helper implementations |
| Pure inventory authorization model | Hanko and Convex platform behavior |
| Inventory confidentiality theorems | The code generator's semantic-correctness proof |

This means it would be too strong to say “the complete game is implemented and proved in Lean.”
The accurate statement is:

> Lean currently authors the two public endpoint definition plans, generates their validators and
> handler orchestration, and proves the pure inventory-confidentiality policy. Handwritten
> TypeScript still implements the domain operations called by the generated dispatcher.

There is also one important gap inside the current DSL: `AuthRule` metadata and effect steps are
declared together, but the type system does not yet force an `inventoryOwner` rule to be paired
with `readOwnedInventory`. The concrete endpoint is proved to carry the guard and the generator
emits the check, but a future typed plan should make an invalid pairing impossible.

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
