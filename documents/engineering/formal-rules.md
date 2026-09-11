# Lean-to-Convex game architecture

## Decision

Mythroads authors its game model and Convex endpoint manifest in Lean. Lean executables compile
those declarations into TypeScript under `convex/generated/` and `shared/generated/`. Thin, stable
files at Convex's public module paths register the generated query and mutation definitions.

The game itself is now a single Lean definition — `Mythroads.Engine.step`, one pure function from
a room and an envelope to either a refusal or a new room plus the writes it owes — with its
invariant and gate theorems beside it. `documents/engineering/lean-code-walkthrough.md` is the
narrative account of that definition and of the path it takes to Convex.

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
  Engine/           the one game definition: State, Event, Effect, Error, step, and its theorems
  Convex/           value universe, tables and indexes, TypeScript AST, layout, module assembly
  Backend/          complete Convex transaction/query programs, written in that embedding
  Compile/          a Lean-to-TypeScript compiler over the compiler's monomorphised LCNF
  Game/             world, combat, magic, inventory, events, and proofs
        │
        │ lake exe mythroads-emit  (proofs/Emit.lean)
        │ lake exe mythroads-compile (proofs/Compile.lean)
        ▼
convex/generated/ and shared/generated/
  complete application backend and shared deterministic rules
        │
        ├── query/mutation definitions ─ Convex registration adapters
        └── shared rule artifacts ──── stable `*.system.ts` re-exports
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

## The Lean Convex embedding

`Mythroads.Convex.Ty` is the single value universe: `Ty.validator` folds a value to a runtime
validator and `Ty.tsType` folds the *same* value to a TypeScript type, so the two cannot disagree.
`Mythroads.Convex.Table` closes the table enumeration and indexes `Index` by its table, so an
indexed read cannot name an index belonging to another table or put its keys in the wrong order.
The earlier `ValueType.custom (validator typeName : String)` escape hatch, whose two halves were
unrelated strings, is gone; `Ty.external` keeps the pair in one constructor.

`Mythroads.Convex.Endpoint` declares:

- `exportName`: generated TypeScript binding;
- `args`: named fields with Convex-compatible value types;
- `returnsValidator`: runtime return contract;
- `auth`: authorization rule evaluated before private data is returned;
- `plan`: query or mutation effect program.

The endpoint manifest contains an indexed, owner-checked inventory read and the four ordered steps
of the single public game mutation:

```text
authorize event
→ return a prior idempotent command result when present
→ route the event
→ persist the event and result
```

This order is authored in `dispatchEndpoint`. The production backend has since expanded through a
structural TypeScript AST: room, movement, combat, encounter, shop, inventory, camera, turn,
authorization, persistence, and public room queries are Lean values emitted as TypeScript.
Unsupported syntax fails Lean compilation instead of falling back to handwritten handlers.

Every generated file is written by one executable, `mythroads-emit`, whose `outputs` table pairs
each repository path with the `Convex.Module` that fills it. The twenty-nine per-file executables
that preceded it are gone, along with the duplicate path table that used to live in JavaScript.

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

Randomness is a field of the room state (a Park–Miller generator advanced by `State.draw`), so a
stored room replays its own future exactly. The `room.create` seed itself is coerced at the boundary
and normalised into that generator state; it is not stored in the `gameEvents` log, which is an audit
trail beside the authoritative room row rather than the source the room is rebuilt from.

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

Phases 1 to 4 are done. Phase 4 was overtaken rather than executed as written: instead of a free
effect language interpreted twice, the game became one Lean function returning a list of `Effect`
requests, and Convex runs that function compiled from Lean. Phase 5 is partly done.

### Phase 1 — endpoint compiler vertical slice (done)

- Generate the private inventory query definition.
- Generate the single dispatch mutation definition and its ordered orchestration.
- Preserve public Convex function paths with two registration adapters.
- Prove inventory owner-only access.
- Test owner, stranger, and anonymous calls through `convex-test`.

### Phase 2 — event and validator ownership (done)

- Move the `GameEvent` sum type into Lean.
- Generate `gameEventValidator`, `DispatchResult`, and their TypeScript types.
- Generate the event router exhaustively from a Lean list of event declarations.
- Prove every state-changing event has an authenticated actor policy.
- Delete the handwritten validator union and router switch after parity tests pass.

### Phase 3 — pure transition kernels (done)

- Move movement legality and route preview into Lean.
- Generate the shared browser/Convex transition functions.
- Prove a committed route consumes the full roll and only traverses declared directed roads.
- Move equipment transitions and prove slot uniqueness and ownership preservation.
- Move combat resolution and prove HP/damage bounds and turn-phase legality.

### Phase 4 — one transition function and an effect list (done, in a different shape)

- `Mythroads.Engine.step` is the whole transition: three gates, then a `(phase, event)` dispatch.
- `Effect` is what it returns instead of performing; the room invariant `Ok` is preserved by every
  accepted transition, and therefore by `replay`.
- `replay_append` makes snapshots sound before a snapshot table exists.
- Convex runs `step` itself: `convex/generated/aggregate/boundary.generated.ts` loads the room
  aggregate into a `State`, calls the compiled `step`, raises `Error.message` as a `ConvexError` on
  refusal, and `saveState` performs the returned effects. The Lean sources are
  `proofs/Mythroads/Backend/Aggregate/**`; the fourteen per-domain handler modules are deleted.
- Two behaviours stay boundary policies rather than rules because they need a wall clock or a
  database read: the 2200 ms encounter reveal delay and the room-code collision retry.

### Phase 5 — compiler assurance (partly done)

- Done: byte-for-byte drift checking of the whole generated tree, an axiom audit that rejects
  `sorry` and `native_decide`, and compile-time `#guard`s pinning the engine's event alphabet to
  the wire manifest.
- Done: `Mythroads.Compile`, a compiler from Lean's monomorphised LCNF to TypeScript, so
  `shared/generated/engine.generated.ts` is the Lean definition rather than a transcription of it;
  `mythroads-oracle` runs the Lean `step` over scenarios and fuzzed envelopes and `tests/engine`
  compares the compiled engine against that fixture on every check.
- Not started: proving the emitter preserves the semantics of the TypeScript AST, and a Lean-side
  bound showing every stored `Nat` stays below 2^53 (the compiler represents `Nat` as `number`).
- Done: browser combat preview delegates to compiled fixed-point damage; event durability is emitted
  from `Engine.Event.durable`; indexed private snapshots are written every 20 durable transitions;
  and `Ok` proves the PRNG state stays positive.
- Known follow-ups: `saveState` patches every hero column on each `persistPlayer`; the retention
  batch is unscheduled.
- Wasm remains out of scope until a measured, pure, computation-heavy function justifies it.

## Developer workflow

```bash
# Edit proofs/Mythroads/**/*.lean
npm run proofs:generate   # rewrite the generated TypeScript from Lean
npm run proofs:check      # rebuild it independently and reject drift
npm run proofs:axioms     # reject sorry and native_decide in the proof graph
npm run docs:lean         # rewrite documents/engineering/lean-definitions.html
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
