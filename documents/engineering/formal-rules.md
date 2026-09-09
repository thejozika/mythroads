# Lean-to-Convex game architecture

## Decision

Mythroads authors its stable, deterministic game model and Convex endpoint manifest in Lean. A
Lean executable compiles those declarations into TypeScript endpoint definitions under
`convex/generated/`. Thin, stable files at Convex's public module paths register the generated
query and mutation definitions.

This is a source-generation architecture, not a second implementation of the rules. Endpoint
arguments, validators, authorization policies, transaction steps, and pure transition functions
move into Lean as they stabilize. Generated TypeScript is committed for Vercel/Convex deployment
and is rejected by CI whenever it differs from the current Lean output.

The approach deliberately does not run the Lean runtime inside each Convex transaction. Lean's
official compiler emits C and native artifacts.[^1] Convex functions execute TypeScript or
JavaScript in a V8-based default runtime; that runtime can instantiate WebAssembly, but database
access remains available through the asynchronous Convex function context.[^2] Bridging Lean's
runtime, memory model, and async database effects through Wasm would enlarge the trusted boundary
without removing the need for a JavaScript adapter.

## Required properties

The pipeline must satisfy all of the following:

1. Lean is the authored source for deterministic rules and public endpoint declarations.
2. Lean declares whether an endpoint becomes a Convex query or mutation.
3. Lean declares argument and return validators because runtime validation is a security boundary,
   not merely TypeScript metadata.[^3]
4. Lean declares authorization and database-operation plans; generated code must not accept an
   identity asserted by the client.
5. Proofs describe the same declarations consumed by the generator.
6. Convex remains responsible for atomic transactions, indexed persistence, verified Hanko
   identity, and server-controlled randomness.
7. CI checks proofs, audits axioms, regenerates code, and rejects drift.
8. Browser and Three.js code never execute a competing rules implementation.

## Alternatives evaluated

| Approach | Result | Reason |
|---|---|---|
| Handwrite TypeScript and restate it in Lean | Rejected | The proof and production program can diverge silently. |
| Emit isolated predicates from Lean | Rejected | It leaves endpoint validators, auth ordering, and database effects handwritten. |
| Compile the full Lean runtime to Wasm | Deferred experiment | Convex supports Wasm, but Lean's supported backend is C and current Lean-to-Wasm projects are experimental.[^2][^4] Async `ctx.db` calls still require an effect bridge. |
| Write a new Lean-to-JavaScript compiler backend | Rejected for the game | This turns a toy RPG into a compiler research project. Lean permits alternative backends in principle, but semantic preservation becomes a major proof project itself.[^5] |
| Lean endpoint/effect DSL → generated Convex TypeScript | Selected | It keeps authoring and proofs in Lean while producing ordinary, inspectable Convex modules. |

## Architecture

```text
proofs/Mythroads/
  Convex.lean       endpoint types, validators, auth policies, transaction plans
  Authz.lean        authorization semantics and theorems
  Movement.lean     eventual movement transition and graph proofs
  Combat.lean       eventual combat transition and bounds
        │
        │ lake builds and executes proofs/Main.lean
        ▼
convex/generated/
  game-api.generated.ts
        │
        ├── inventoryQueryDefinition ── query(...) in convex/shops.ts
        └── dispatchMutationDefinition ─ mutation(...) in convex/game.ts
```

Convex discovers public functions through files under `convex/` and generates client function
references from those exports.[^6] Consequently the public compatibility files remain at their
existing paths:

```ts
export const inventory = query(inventoryQueryDefinition)
export const dispatch = mutation(dispatchMutationDefinition)
```

These lines are runtime adapters, not alternate rules. They select the Convex function builder and
preserve the existing API paths `shops:inventory` and `game:dispatch`. Everything inside each
definition—validators and handler orchestration—is generated from Lean.

## Lean endpoint DSL

`Mythroads.Convex.Endpoint` declares:

- `exportName`: generated TypeScript binding;
- `args`: named fields with Convex-compatible value types;
- `returnsValidator`: runtime return contract;
- `auth`: authorization rule evaluated before private data is returned;
- `plan`: query or mutation effect program.

The initial effect algebra contains an indexed, owner-checked inventory read and the four ordered
steps of the single game mutation:

```text
authorize event
→ return a prior idempotent command result when present
→ route the event
→ persist the event and result
```

This order is authored in `dispatchEndpoint`. Changing it changes generated production code. The
effect vocabulary must remain narrow: every constructor has explicit Lean semantics, a generator
case, and tests against the Convex adapter. Unsupported plans fail generation instead of silently
falling back to handwritten behavior.

## Inventory confidentiality proof

The client sends a `playerId` only to identify the requested record. It never sends an authoritative
account identifier. Generated query code performs these steps:

1. obtain the verified caller from `ctx.auth.getUserIdentity()`;
2. load the requested player document by Convex ID;
3. read the owner identity stored on that document;
4. compare the verified token identifier with the stored owner;
5. only after equality, read `playerItems` through `by_playerId` with a finite bound.

Lean defines authorization as equality between the authenticated actor and stored inventory owner.
It proves:

- unequal accounts evaluate to denial for `inventoryEndpoint`;
- every successful inventory read identifies the actor as the owner;
- the endpoint manifest actually carries the `inventoryOwner "playerId"` guard.

This proves the universal pure policy over all strings, rather than testing selected accounts. It
does not alone prove that Hanko, Convex, or the generator is bug-free. The production claim is
therefore supported by three independent layers:

| Layer | Evidence |
|---|---|
| Lean model | Kernel-checked theorems with no `sorry` |
| Generated artifact | Byte-for-byte regeneration check and axiom audit in CI |
| Convex boundary | `convex-test` calls the real public query as owner, stranger, and anonymous user |

The stronger future theorem is noninterference: changing another player's inventory must not alter
the authorized player's observable inventory response. That requires modeling finite maps of
players and items in Lean, then proving the indexed read is scoped to the authenticated owner.

## Mapping Lean effects to Convex

Lean should model transactions as a small free effect language rather than pretending its pure
functions can directly invoke `ctx.db`. Representative constructors are:

```text
requireIdentity
get table id
getUnique table index key
take table index key limit
insert table value
patch table id patch
delete table id
freshRandom suppliedValue
reject domainError
return value
```

Each effect needs four definitions:

1. a Lean constructor used by game programs;
2. a pure reference interpreter over an abstract database state;
3. a TypeScript emitter targeting the matching Convex `ctx` operation;
4. adapter tests exercising the generated endpoint through `convex-test`.

Database reads that behave like a `WHERE` clause must compile to declared indexes, never full-table
filters. Convex mutations are atomic and deterministic, which matches a pure state-transition
semantics well.[^7] External network calls must remain actions and cannot be introduced into the
deterministic transaction language.

## Randomness and time

Proofs should never depend on an unmodeled random generator or wall clock. Convex obtains random
samples or timestamps at the trusted boundary and passes them into a Lean-authored transition as
explicit inputs. Lean then proves properties for every possible allowed input—for example, reward
bounds for every wheel index—not that the random source is fair.

For replayability, the durable game event stores those inputs. Replaying a sequence then invokes the
same generated transition with identical values.

## Types and numeric semantics

Convex values are JSON-like and have explicit size and nesting limits.[^8] The Lean DSL should map
only types with an exact Convex representation:

| Lean model | Convex validator | Notes |
|---|---|---|
| `String` | `v.string()` | UTF-8 size remains a runtime constraint |
| bounded `Nat` encoded as number | `v.number()` | generator emits range guards where required |
| signed exact integer | `v.int64()` | generated TypeScript uses `bigint` |
| `Bool` | `v.boolean()` | direct |
| `Option α` | `v.optional(...)` | absence is distinct from `null` |
| `Id table` phantom type | `v.id(table)` | table name is part of the type |
| sum type | `v.union(...)` | discriminated objects for events |

Game arithmetic should avoid unconstrained JavaScript floating point. HP, gold, stats, movement,
damage, and inventory counts become bounded integers in Lean. The generated boundary checks those
bounds before constructing the Lean-modeled input.

## Migration sequence

### Phase 1 — endpoint compiler vertical slice

- Generate the private inventory query definition.
- Generate the single dispatch mutation definition and its ordered orchestration.
- Preserve public Convex function paths with two registration adapters.
- Prove inventory owner-only access.
- Test owner, stranger, and anonymous calls through `convex-test`.

### Phase 2 — event and validator ownership

- Move the `GameEvent` sum type into Lean.
- Generate `gameEventValidator`, `DispatchResult`, and their TypeScript types.
- Generate the event router exhaustively from a Lean list of event declarations.
- Prove every state-changing event has an authenticated actor policy.
- Delete the handwritten validator union and router switch after parity tests pass.

### Phase 3 — pure transition kernels

- Move movement legality and route preview into Lean.
- Generate the shared browser/Convex transition functions.
- Prove a committed route consumes the full roll and only traverses declared directed roads.
- Move equipment transitions and prove slot uniqueness and ownership preservation.
- Move combat resolution and prove HP/damage bounds and turn-phase legality.

### Phase 4 — abstract transaction interpreter

- Replace named transaction steps with a typed effect program.
- Define a pure Lean database interpreter and state invariants.
- Generate Convex `ctx.db` programs from the same effect tree.
- Prove preservation of ownership, room membership, nonnegative resources, and event ordering.

### Phase 5 — compiler assurance

- Add snapshot tests for every generated module.
- Generate cross-language test vectors in Lean and execute them in TypeScript.
- Prove the emitter preserves the semantics of the restricted expression/transaction IR where
  practical.
- Consider Wasm only for large pure computations after measuring bundle size and cold execution.

## Developer workflow

```bash
# Edit proofs/Mythroads/*.lean
npm run proofs:generate
npm run proofs:check
npm run test:convex
npm run check
```

`proofs:generate` builds Lean and formats the emitted TypeScript. `proofs:check` independently runs
the compiler and fails if the committed artifact is stale. GitHub uses the official Lean action to
build the nested Lake project and audit its axioms.[^9]

Generated modules are reviewable artifacts but are never edited directly. The header names the
Lean source. A production change should show the Lean declaration/proof change alongside its
generated TypeScript diff.

## Limits of the proof claim

The theorem does not prove TLS, Hanko's implementation, Convex's platform, V8, or the Lean kernel.
It also does not yet prove the TypeScript emitter semantics. Those components form the trusted
computing base. The architecture reduces that base over time by keeping adapters small, generating
validators and orchestration, running negative integration tests, auditing axioms, and eventually
proving the restricted emitter.

Saying “the inventory is proven private” is justified only as the composed claim:

- Lean proves the endpoint policy denies every unequal authenticated identity;
- generated code derives actor identity from Convex auth and owner identity from stored data;
- integration tests prove public callers cannot bypass that generated sequence.

## Sources

[^1]: Lean project, [Elaboration and Compilation](https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/). Lean modules compile through an official C backend into native artifacts.
[^2]: Convex, [Runtimes](https://docs.convex.dev/functions/runtimes). The default V8-based runtime supports WebAssembly in functions.
[^3]: Convex, [Argument and Return Value Validation](https://docs.convex.dev/functions/validation). Validators enforce runtime API contracts and reject undeclared fields.
[^4]: T-Brick, [lean2wasm](https://github.com/T-Brick/lean2wasm). The project describes itself as experimental, requires Emscripten, and documents runtime-reset constraints.
[^5]: Leonardo de Moura and Sebastian Ullrich, [The Lean 4 Theorem Prover and Programming Language](https://lean-lang.org/papers/lean4.pdf). The compiler IR is extensible to alternative backends; the maintained generator emits C.
[^6]: Convex, [Generated Code](https://docs.convex.dev/generated-api/). Convex derives typed client API references from backend functions.
[^7]: Convex, [Mutations](https://docs.convex.dev/functions/mutation-functions). Mutations execute deterministically and transactionally.
[^8]: Convex, [Data Types](https://docs.convex.dev/database/types). Convex documents use a constrained JSON-like value model.
[^9]: Lean project, [lean-action](https://github.com/leanprover/lean-action). The official action builds Lake projects and can audit axioms.
