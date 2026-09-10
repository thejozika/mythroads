# Lean-authored Convex backend plan

## Executive conclusion

Mythroads can make Lean the source language for essentially all application-owned backend logic.
The recommended meaning of “the backend is written in Lean” is:

- schemas, validators, endpoint declarations, authorization policies, database programs, game
  transitions, and proofs are authored in Lean;
- a Lean compiler emits the complete application-specific TypeScript modules that Convex deploys;
- no game rule or authorization decision is independently handwritten in TypeScript;
- a small, generic target runtime and Convex's own generated files remain in TypeScript because the
  Convex platform executes JavaScript or TypeScript functions.

This is stronger than the current endpoint-template generator. It is a real compiler from a typed
Lean backend language to Convex TypeScript.

Literal execution of the entire Lean runtime inside Convex is technically approachable through
WebAssembly, but it is the wrong primary design. Convex can instantiate WebAssembly, yet database,
authentication, storage, scheduling, and function-call capabilities are exposed through an
asynchronous JavaScript context.[^1] A Wasm build would therefore still require JavaScript glue,
serialization, an async effect bridge, and the Lean runtime. Lean's supported compiler currently
emits C, and its documented FFI targets the C ABI; the FFI is explicitly described as unstable.[^2]
Community Lean-to-Wasm tooling also describes itself as experimental and documents runtime-reset
constraints.[^3]

The recommendation is therefore:

> Build a deep, typed Lean embedding of the Convex programming model and generate TypeScript. Use
> Wasm later only for measured, pure, computation-heavy functions where it has a concrete benefit.

## What “import Convex into Lean” can mean

Lean cannot import `convex` from npm and call `ctx.db.get` during a Convex transaction. Those APIs
exist only in Convex's JavaScript runtime. Instead, Mythroads can define Lean constructors that
have the same typed meaning:

```lean
-- Illustrative API shape, not the final syntax.
def inventory (playerId : Id .players) : Query (List PlayerItem) := do
  let identity ← Auth.requireIdentity
  let player ← Db.require .players playerId
  Auth.requireOwner identity player.authId
  Db.takeByIndex .playerItems .byPlayerId playerId 40
```

This is not a second implementation. The calls construct a typed backend program. That same
program is consumed by:

1. a pure Lean interpreter used in proofs;
2. a Lean TypeScript emitter used for production;
3. a trace interpreter used to generate cross-language test cases.

The distinction is important. A shallow generator that stores arbitrary TypeScript strings in
Lean is easy to build but proves little. A deep embedding represents tables, IDs, validators,
effects, expressions, and control flow as typed Lean data. Invalid programs—such as writing in a
query or using a `players` ID to read `rooms`—should fail to typecheck.

## Platform facts that shape the design

Convex has three main function kinds. Queries are reactive, cached, consistent reads; mutations
are atomic transactions; actions may call external services but do not have direct database
access.[^4] Convex requires deployed backend functions to be JavaScript or TypeScript and bundles
the modules under `convex/` with esbuild.[^5]

The installed Convex version in this repository is `1.45.0`. Its local type declarations are the
ground truth for the compiler target. They expose these capability families:

| Context | Capabilities available in Convex 1.45.0 |
|---|---|
| Query | database read, authentication, storage read, nested query, transaction metadata |
| Mutation | database read/write, authentication, storage read/write, scheduler, nested query/mutation, transaction metadata |
| Action | authentication, storage including blobs, scheduler, query/mutation/action calls, vector search, external `fetch` |
| HTTP action | action-like context plus `Request` and `Response` |

Convex itself already uses code generation for application-specific data-model and API types.[^6]
Generating Convex source from Lean is therefore compatible with the platform's workflow, provided
the resulting TypeScript is validated and deployed normally.

Several semantic constraints must be represented rather than treated as incidental details:

- Queries and mutations must be deterministic. Convex can retry them.[^1]
- A mutation commits all writes together or none of them.[^7]
- Actions are not transactions and are not automatically retryable after external side effects.[^8]
- Efficient multi-document reads must use declared indexes and finite result operations.[^9]
- Runtime argument and return validators are security boundaries, not just TypeScript types.[^10]
- Documents, calls, transactions, execution time, and deployed code have platform limits.[^11]

## Implemented Mythroads backend surface

Status, so this section is read as a record rather than a proposal: phases 0 to 5 below are done
(phase 5 except the noninterference proofs), phase 6 is partly done, and phase 7 has not been
needed. The game exists once, as `Mythroads.Engine.step`, and Convex runs it compiled from Lean;
see `documents/engineering/lean-code-walkthrough.md`.

The current repository is small enough to migrate incrementally:

| Area | Current state |
|---|---|
| Convex tables | 8 Lean-declared tables emitted into `convex/generated/schema.generated.ts` |
| Durable event variants | 16 Lean-declared variants with generated validators, policy, auth, and routing |
| Public write entry point | `game:dispatch`, registered from a Lean-generated definition |
| Public reads | Three room/controller queries plus private inventory, all Lean-generated |
| Runtime capabilities used | authentication, indexed database reads, inserts, patches, replaces, deletes, time, randomness |
| Capabilities not currently needed | actions, HTTP actions, storage, scheduler, search, vector search, crons |

This means the first production compiler does not need to clone the entire Convex SDK. It should
model the full capability families but implement operations only when the game needs them. Trying
to reproduce every current and future Convex method before migrating the game would increase
maintenance cost and delay the proof benefits.

The migration now generates every application-owned Convex handler and every stable shared
rule/catalogue, from one executable (`mythroads-emit`) whose `outputs` table pairs each repository
path with the module that fills it. Value shapes, table names and index keys are closed Lean types
rather than strings: `Convex.Ty` folds one value to both a validator and a TypeScript type, and
`Convex.Index` is indexed by its `Convex.Table`, so an indexed read cannot name a foreign index or
reorder its keys.

The remaining compiler limitations are:

- `AuthRule` and endpoint effects are parallel metadata rather than one type-safe program;
- the mutation emitter recognises one fixed list of named steps;
- emitter correctness is covered by drift checks, integration tests and — for the compiled engine —
  a parity oracle, but not by a formal semantics.

The stable TypeScript files in `convex/` and `shared/` are compatibility adapters only. A blocking
quality test rejects handwritten handler bodies, database access in adapters, or replacement shared
rules. Hanko configuration, Convex's `_generated/` bindings, React, and Three.js remain TypeScript
because they are platform and presentation boundaries rather than application-owned game logic.

## Target architecture

```text
                         LEAN-AUTHORED SOURCE

  Schema + indexes       Endpoints + effects        Game transitions
  Event/value types      Auth policies              Invariants + proofs
          │                       │                         │
          └───────────────────────┴─────────────────────────┘
                                  │
                     typed BackendProgram values
                                  │
              ┌───────────────────┼───────────────────┐
              ▼                   ▼                   ▼
      reference interpreter   TypeScript emitter   trace interpreter
              │                   │                   │
              ▼                   ▼                   ▼
        theorem statements    convex/generated/    parity vectors
                                  │
                    thin stable Convex path exports
                                  │
                                  ▼
                       Convex JavaScript runtime
```

### Lean source taxonomy

What was proposed here was a file-by-file plan. What exists is close to it in spirit and different
in shape, because the game turned out to want one definition rather than a domain per file:

```text
proofs/
  Emit.lean            the single code generator: path -> module
  Compile.lean         the Lean-to-TypeScript compiler executable
  DocExport.lean       the documentation exporter behind lean-definitions.html
  Axioms.lean          the axiom audit
  Mythroads/
    Engine.lean        the root, with the reading order
    Engine/            Core, Room, Combat, Event, Step, Step/*, Replay, Invariant,
                       Preservation, Theorems, Examples
    Convex/            Ty, Table, Query, Schema, Ast, TypeScript, Doc, Module
    Backend/           one module per generated Convex file
    Compile/           Names, State, Shims, Types, Expr, Code, Driver
    Game/              board, combat, magic, inventory, events, random, turn order
    Authz.lean, Identity.lean
```

The proof modules are not a separate directory: each one sits beside the definitions it is about
(`Engine/Theorems.lean`, `Engine/Preservation.lean`, `Authz.lean`), which is what keeps a statement
and the value it quantifies over in the same file.

### Generated output taxonomy

The layout that actually shipped keeps the paths the handwritten files already had, so no consumer
had to move:

```text
convex/generated/     schema, game API, the owner-only inventory read, Park-Miller
convex/generated/aggregate/
                      the load-step-save boundary: enums, load, rows, persist,
                      envelope, boundary
convex/events/        validators, policy, authority, persistence, retention
convex/auth/          authorization
convex/rooms/         public room queries
shared/generated/     board, world, controller input, combat, magic, items, encounters,
                      and engine.generated.ts — the compiled Lean engine
```

Convex requires conventional module paths such as `convex/schema.ts` and uses file paths to name
API functions. Those files remain tiny registrations or re-exports:

```ts
// convex/schema.ts
export { default } from './generated/model/schema.generated'

// convex/game.ts
export { dispatch } from './generated/functions/game.generated'
```

Even these compatibility files can be emitted by Lean, but keeping a few stable, mechanically
checked adapters makes migrations easier and preserves client API paths.

`convex/_generated/` remains owned by the Convex CLI and is never generated or edited by Lean.

## The Lean Convex language

### Exact value universe

The current `ValueType.custom` escape hatch should be replaced with a closed representation of
Convex values:

```text
null, boolean, string, float64, int64, bytes, commit timestamp
table-indexed ID, optional field, array, object, record, literal, union
```

Convex does not accept `undefined` as a transported value, although optional object fields may be
absent.[^12] The Lean representation must distinguish `Option α` in an object field from a nullable
value transported as `null`. IDs should be indexed by a finite Lean table name type, not `String`.

Every value type should have:

- a Lean carrier type;
- a generated Convex validator;
- a generated TypeScript type;
- an encoder/decoder model;
- size or boundedness obligations where a program could exceed Convex limits.

### Schema as the source of table and index types

The Lean schema should define each table once. From it, Lean should derive:

- `convex/generated/model/schema.generated.ts`;
- the finite `Table` type;
- each table's row type and table-indexed `Id`;
- legal index names and their ordered fields;
- document validators including system fields;
- insert, patch, and return types.

An indexed query should be unrepresentable unless its index exists in the schema. The key type
should be derived from the index fields, preventing a generator from swapping index order or using
the wrong field.

### Capabilities indexed by function kind

The backend program type should carry its function kind:

```lean
inductive FunctionKind where
  | query | mutation | action

-- Illustrative only.
inductive Op : FunctionKind → Type → Type where
  | authIdentity : Op kind (Option Identity)
  | dbGet        : TableRef row → Id table → Op kind (Option row)
  | dbInsert     : Insertable table → Row table → Op .mutation (Id table)
  | fetch        : HttpRequest → Op .action HttpResponse
```

The real constructors need capability evidence so that:

- queries cannot write, schedule, or fetch;
- mutations cannot fetch from the external network;
- actions cannot directly read or write `ctx.db`;
- public and internal function references retain their argument and return types.

This mirrors the actual Convex context split.[^4] The safety property is then enforced by Lean's
typechecker before any theorem is written.

### Typed effects, not named templates

The program language needs general sequencing and bindings:

```text
pure value
bind operation result into the remaining program
let expression
if / match over typed sums
reject with a declared domain error
```

Core database operations should initially cover:

| Family | Lean operations |
|---|---|
| Read | `get`, indexed `unique`, indexed `first`, indexed `take`, bounded pagination |
| Write | `insert`, `patch`, `replace`, `delete` |
| Auth | optional identity, required identity, owner/host assertions |
| Runtime | current transaction time, deterministic random sample, `ConvexError` |
| Calls | typed internal query/mutation reference, with nested transaction limits |

Full-table `collect` and arbitrary `.filter()` should not exist in the initial DSL. They can be
added only with an explicit bounded-use type or reviewed escape hatch. This turns the project's
performance rules into compiler constraints.

### Pure semantics

Every effect constructor needs a reference meaning over an abstract state:

```text
World = tables + authenticated identity + clock/random transcript
run : BackendProgram kind result → World → Result error (result × World × Trace)
```

Queries return the same world. Mutations may change tables atomically. Actions produce an external
effect trace and interact with database state only through modeled function calls.

The reference interpreter is what makes whole-program theorems possible. It also supports small,
deterministic examples without running Convex.

### TypeScript target

`Main.lean` should stop concatenating large raw strings. It should emit a small TypeScript abstract
syntax tree containing only the constructs required by the backend language: imports, constants,
object literals, calls, `await`, bindings, branches, switches, returns, and throws. A deterministic
pretty-printer then serializes that tree.

This does not prove TypeScript semantics. It does drastically narrow the emitter, prevents syntax
injection through names, and makes structural tests possible. A later proof can relate the Lean
reference interpreter to a formal semantics of this restricted target subset without formalizing
all of JavaScript.

## Convex API coverage strategy

“Most Convex functions” should be treated as an ordered compatibility roadmap:

| Tier | Capability | Decision |
|---|---|---|
| 1 | values, validators, schema, standard indexes | Build first |
| 1 | public/internal query and mutation registration | Build first |
| 1 | auth identity and indexed database read/write | Build first |
| 1 | errors, deterministic time/random inputs | Build first |
| 2 | nested query/mutation calls and transaction budgets | Add after current game migration |
| 2 | scheduler `runAfter`, `runAt`, `cancel` | Add when durable timers appear |
| 2 | storage URLs, metadata, upload, delete | Add when assets become user-generated |
| 3 | action and HTTP-action registration, `fetch` ports | Add for concrete integrations |
| 3 | recurring crons | Generate when maintenance jobs exist |
| 3 | full-text and vector search | Add only for a product requirement |
| 4 | arbitrary npm/component APIs | Typed foreign-port wrappers, never a universal escape hatch |

Scheduled calls made from mutations are atomic with the mutation; scheduled calls made from
actions are not.[^13] That difference must appear in the reference semantics. Similarly, storage
capabilities vary by context: mutations can create upload URLs and delete files, while actions can
also read and store blobs.[^14]

Each supported capability must include four pieces in the same change:

1. Lean operation and types;
2. reference semantics;
3. TypeScript emitter case;
4. generated Convex integration test.

The Convex npm version should be pinned exactly once this compiler mirrors its API. CI should check
that the installed version equals a `TargetVersion` declared in Lean. A Convex upgrade then becomes
an explicit compiler-target upgrade rather than an accidental semver change.

## Randomness, time, and replay

Convex makes `Math.random()` deterministic within retryable functions by treating its seed as an
implicit input, and freezes `Date.now()` for a function invocation.[^1] Lean proofs still should not
pretend these values are constants.

The backend language should model an oracle transcript:

```text
OracleInput = currentTime | randomUnit | randomIndex upperBound
OracleOutput = timestamp | bounded sample
```

Production TypeScript obtains the value from Convex. The generated dispatcher records every
sample used to resolve a durable event. Replay supplies the recorded transcript instead of drawing
again. Lean can then prove properties for every valid transcript—for example, damage and loot
bounds—without claiming that the random generator is fair.

The current event ID assembled from time plus randomness should eventually be replaced by a
Convex document ID or a modeled unique-command mechanism. Identity and idempotency should not rely
on probabilistic string collision assumptions.

## External services and Hanko

Hanko authentication remains a trusted platform boundary. Lean can prove:

```text
if Convex supplies identity A and a player is owned by B and A ≠ B,
then the backend program does not reveal or mutate B's private inventory.
```

Lean cannot prove that Hanko signed a token correctly or that Convex validated it correctly. The
generated code must always obtain identity from `ctx.auth.getUserIdentity()`, never from a client
argument.[^15]

Actions and HTTP actions should use typed foreign ports:

```text
HankoAdmin.lookupUser : Email → Action (Result HankoError PublicUser)
```

The Lean program owns authorization, request construction, response validation, retry policy, and
workflow decisions. A generated or narrowly handwritten adapter performs `fetch`. External API
responses are untrusted inputs that must pass generated validators before entering the model.

## Proof portfolio

The compiler should prioritize properties that matter to the game and to backend safety:

| Property | Technique |
|---|---|
| Queries cannot write | impossible by `BackendProgram .query` operation types |
| Actions cannot access the database directly | impossible by action capability types |
| Only one public mutation alters game state | theorem over the generated endpoint manifest |
| Every durable event is authenticated | exhaustive theorem over the `GameEvent` sum type |
| Other-player inventory confidentiality | observational noninterference theorem |
| Other-player inventory cannot be equipped or sold | transition-preservation theorem |
| Equipment slots remain unique | invariant preserved by all inventory transitions |
| Movement respects directed roads and roll budget | transition legality theorem |
| Combat preserves numeric bounds | bounded-stat and damage theorem |
| Game phases admit only legal events | state-machine progress/preservation theorem |
| Replay is deterministic | reference interpreter theorem over stored oracle transcript |
| Generated endpoints have validators | theorem over every public/internal function declaration |
| Every indexed query uses an existing index | enforced by schema-indexed types |

Lean's kernel validates theorem terms, but proof trust still depends on the statements matching the
intended policy and on auditing imported axioms.[^16] CI should keep axiom auditing and reject
`sorry` in the entire proof dependency graph.

## Trust boundary

Even after migration, the end-to-end system relies on:

- the Lean kernel and declared axioms;
- the correctness of the Lean reference semantics;
- the restricted TypeScript emitter and printer;
- TypeScript/esbuild and the Convex bundler;
- the Convex runtime, database, and authentication integration;
- Hanko's token issuance;
- any external service called by an action.

The goal is not to claim these systems are formally verified. The goal is to remove application
business logic and authorization duplication from that boundary. Production assurance combines
Lean theorems, generated-code drift checks, TypeScript typechecking, `convex-test`, and tests against
a real local or preview backend. Convex documents that `convex-test` does not reproduce all runtime
limits and semantics, so it cannot be the final integration layer.[^17]

## Implementation plan

### Phase 0 — compiler contract and vertical-slice choice (done)

Estimated effort: 1–2 focused days.

- Record “no handwritten backend business logic” as the target contract.
- Pin the Convex compiler target to installed version `1.45.0`.
- Define generated-file ownership and stable adapter exceptions.
- Select `inventory.equip` as the first vertical slice: it needs authentication, two document IDs,
  indexed reads, conditional failure, patches, and a meaningful ownership/slot proof.
- Preserve current production behavior with parity fixtures before replacing it.

Exit criterion: one written compiler contract and fixtures describing current equip behavior,
including hostile callers.

### Phase 1 — values, schema, and validators (done)

Estimated effort: 3–5 focused days.

- Replace raw validator/type strings with the closed `Convex.Value` universe.
- Define all eight current tables and indexes in Lean.
- Generate schema, document validators, `GameEvent`, and `DispatchResult` validators/types.
- Remove `v.any()` from the durable event schema and migrate or explicitly retain legacy rows.
- Generate stable TypeScript identifiers only from validated Lean names.

Exit criterion: generated schema and validators are byte-stable, `tsc` passes, and Convex validates
the existing database shape.

### Phase 2 — typed effect language (done, as a structural TypeScript AST)

Estimated effort: 4–7 focused days.

- Introduce capability-indexed query, mutation, and action programs.
- Implement auth, bounded indexed reads, write operations, errors, time, and random sampling.
- Implement the pure abstract-database interpreter.
- Implement a restricted TypeScript AST and printer.
- Express and generate `inventory.equip` entirely from Lean.
- Prove owner-only mutation and unique-slot preservation.

Exit criterion: the old handwritten `equipItem` is deleted; owner, stranger, invalid item, invalid
slot, and occupied-slot cases pass against generated Convex code.

### Phase 3 — event dispatcher and authorization (done)

Estimated effort: 3–5 focused days.

- Move the full event sum type and event-to-authority relation into Lean.
- Generate the exhaustive router rather than a handwritten TypeScript switch.
- Encode authorize → deduplicate → interpret → persist as one typed mutation program.
- Generate only one public state-changing mutation.
- Make development auth bypass a compile/profile choice that production generation cannot enable.
- Prove every non-lobby event has an authenticated owner or host policy.

Exit criterion: `convex/events/router.ts`, handwritten validators, and handwritten authorization
branching contain no domain logic.

### Phase 4 — migrate the game domains (done)

Estimated effort: 7–12 focused days.

Move one domain at a time in this order:

1. room creation/join/start;
2. movement roll/select/cancel/commit;
3. landings and encounters;
4. shops and equipment;
5. combat attack/guard/resolution.

For each domain, add the pure transition, invariant theorem, effectful persistence program,
generated TypeScript parity fixtures, and hostile-case integration tests in the same change.

Camera state should be removed from the durable game program if it remains ephemeral. It should
not consume proof or persistence complexity intended for authoritative game state.

Exit criterion: the handwritten files under `convex/` contain registration, configuration, or
generic foreign adapters only—no game decisions.

### Phase 5 — generated reads and information-flow boundaries (done, except the noninterference proofs)

Estimated effort: 2–4 focused days.

- Generate public display queries from an explicit public projection of game state.
- Generate controller queries from an authenticated private projection.
- Prove public display output cannot contain private inventory or controller-only choices.
- Prove other-player changes are noninterfering for private controller observations.
- Add bounded query budgets to every collection operation.

Exit criterion: all public and private read surfaces are generated and tested as anonymous, owner,
other player, and host identities.

### Phase 6 — hardening and compiler assurance (partly done)

- Done: random and scenario test vectors generated from the Lean `step` (`mythroads-oracle`) and
  executed against the compiled engine in `tests/engine`; the axiom audit; whole-tree drift checks
  that also reject generated files with no Lean producer.
- Open: source maps from generated TypeScript back to Lean declarations; a compiler-version
  manifest that fails on Convex target-version drift; `lean4checker` or another independent proof
  check in CI; structural theorems about the emitted module manifest.

Exit criterion: generated drift, missing validators, unsupported operations, unbounded reads, API
version skew, and public-mutation proliferation all fail CI.

### Phase 7 — advanced Convex capabilities on demand (not started; nothing needs one yet)

Estimated effort: feature-dependent.

Add scheduler, storage, actions, HTTP actions, search, or components only when Mythroads needs them.
Each capability receives types, semantics, emission, and integration tests. External npm packages
are exposed through narrow typed ports rather than arbitrary embedded TypeScript.

## Decision gates, as they were answered

1. **Is Lean authoring pleasant enough to justify migration?** Yes. The cost that mattered was not
   proving things; it was string-typed emitters, and closing the value, table and index universes
   removed it.
2. **Do generated diffs and error messages remain understandable?** Yes, once Biome — not Lean —
   became the arbiter of final style, so a Lean change shows up as a semantic diff.
3. **Does parity hold for a stateful, random workflow?** Randomness became a field of the state and
   a Park–Miller step, so replay is exact by construction rather than by agreement.

## Immediate next change

The load–step–save boundary is in place: `convex/generated/aggregate/boundary.generated.ts` loads
the room aggregate, calls the compiled `step`, and `saveState` performs the effects; the per-domain
handlers are gone. What remains, in order of value:

1. compile the browser combat preview from the engine so the number a player previews is the
   number the server writes (today `shared/generated/combat.generated.ts` rounds in floats);
2. add a snapshot table, which `replay_append` already proves sound;
3. derive `isPersistentGameEvent` from `Engine.Event.durable` instead of holding them equal with a
   `#guard`, and schedule or delete the retention batch;
4. bound every stored `Nat` below 2^53 in Lean, closing the one representation assumption the
   compiler makes. The invariant `Ok` now carries the two bounds the boundary relies on
   (`players.length ≤ maxPlayers`, `rng < modulus`), and every client number that becomes a `Nat`
   is coerced by `Envelope.wireNat` at the trust edge; what remains is the general statement for
   gold, hit points and counters;
5. decide whether the `gameEvents` log should become a full transcript. Today the room row is the
   truth and the log is an audit trail: the `room.create` seed is normalised into the generator
   state rather than logged, and the room-code collision retry advances the generator outside any
   envelope. Persisting the effective seed and the redraw count would make `replay` executable over
   the stored log;
6. prove `0 < rng` as part of `Ok`, which needs primality of 2^31 − 1 (or a decision procedure the
   axiom audit accepts); today the boundary guarantees it by normalising every seed to `1 ≤ state`.

## Sources

[^1]: Convex, [Runtimes](https://docs.convex.dev/functions/runtimes), accessed September 10, 2026.
[^2]: Lean, [Foreign Function Interface](https://lean-lang.org/doc/reference/latest/Run-Time-Code/Foreign-Function-Interface/) and [Elaboration and Compilation](https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/), accessed September 10, 2026.
[^3]: T-Brick, [Lean2Wasm](https://github.com/T-Brick/lean2wasm), accessed September 10, 2026.
[^4]: Convex, [Functions](https://docs.convex.dev/functions/overview) and [Generated server API](https://docs.convex.dev/generated-api/server), accessed September 10, 2026.
[^5]: Convex, [Bundling](https://docs.convex.dev/functions/bundling), accessed September 10, 2026.
[^6]: Convex, [Generated Code](https://docs.convex.dev/generated-api/), accessed September 10, 2026.
[^7]: Convex, [Mutations](https://docs.convex.dev/functions/mutation-functions), accessed September 10, 2026.
[^8]: Convex, [Actions](https://docs.convex.dev/functions/actions), accessed September 10, 2026.
[^9]: Convex, [Reading Data](https://docs.convex.dev/database/reading-data/), accessed September 10, 2026.
[^10]: Convex, [Argument and Return Value Validation](https://docs.convex.dev/functions/validation), accessed September 10, 2026.
[^11]: Convex, [Limits](https://docs.convex.dev/production/state/limits), accessed September 10, 2026.
[^12]: Convex, [Data Types](https://docs.convex.dev/database/types), accessed September 10, 2026.
[^13]: Convex, [Scheduled Functions](https://docs.convex.dev/scheduling/scheduled-functions), accessed September 10, 2026.
[^14]: Convex, [Uploading and Storing Files](https://docs.convex.dev/file-storage/upload-files) and [StorageActionWriter](https://docs.convex.dev/api/interfaces/server.StorageActionWriter), accessed September 10, 2026.
[^15]: Convex, [Auth interface](https://docs.convex.dev/api/interfaces/server.Auth), accessed September 10, 2026.
[^16]: Lean, [Validating a Lean Proof](https://lean-lang.org/doc/reference/latest/ValidatingProofs/), accessed September 10, 2026.
[^17]: Convex, [convex-test](https://docs.convex.dev/testing/convex-test), accessed September 10, 2026.
