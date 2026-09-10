# Dicebound engineering guide

Dicebound is a Three.js board-RPG with a Convex-authoritative multiplayer state. Read the
authoritative design notes in `documents/` before changing rules. `sources/` is reference material,
not specification.

## Required checks

- `npm run check:architecture` — file size, folder density, taxonomy, dependency direction, and
  development-fragment checks.
- `npm run lint` / `npm run lint:fix` — Biome correctness and style checks.
- `npm run format` / `npm run format:check` — deterministic formatting.
- `npm run proofs:check` — compile Lean proofs and reject stale generated Convex code.
- `npm run proofs:axioms` — reject any theorem that depends on `sorry` or on a `native_decide`
  axiom instead of a kernel-checked proof. The allowlist in `proofs/Axioms.lean` is empty and stays
  empty; prove concrete facts with `decide` or `#guard`.
- `npm run docs:lean:check` — reject a stale `lean-definitions.html`. The page is generated from the
  Lean environment by `lake exe mythroads-docs`; run `npm run docs:lean` after changing `proofs/`.
- `npm run check` — the complete blocking gate, including the production build.

Do not weaken a check merely to land a change. Split or correct the code. Generated files under
`convex/_generated/` are never edited manually.

## Structure and limits

- Production source files are limited to 300 lines; tests to 450; stylesheets to 500.
- A code directory may contain at most 12 direct files. Create a meaningful feature subdirectory
  when it grows beyond that point.
- Organize by game feature first (`game/board`, `game/combat`, `game/controller`), then by technical
  role. Do not create global dumping grounds such as `helpers/` or `misc/`.
- Use the filename taxonomy documented in `documents/engineering/code-architecture.md`. A suffix is
  a contract, not decoration.
- The game rules live once, in `proofs/Mythroads/Engine/**`: `State`, `Event`, `Effect`, `Error`
  and the single transition `step`, with its invariant and gate theorems beside it. Endpoint
  manifests and the Convex value/table universe live in `proofs/Mythroads/Convex/**`. Provisional
  deterministic rules remain in `*.system.ts` and must run identically in the browser and Convex.
  Rendering never decides game outcomes.
- Every `*.generated.ts` file comes from Lean: the Convex boundary from the single emitter
  `mythroads-emit` (`proofs/Emit.lean`), whose `outputs` table owns the repository paths, and the
  shared engine from `mythroads-compile` (`proofs/Compile.lean`). Do not add a third generator and
  do not restate the path table in JavaScript. Generated files are never edited by hand, and public
  Convex modules may only register their generated query or mutation definitions.
- `shared/generated/engine.generated.ts` is the compiled engine itself, several thousand lines of
  machine-written TypeScript. It is the one file exempt from the 300-line limit, named explicitly
  in `scripts/quality/architecture.config.mjs`: nobody maintains it, and cutting a compiled call
  graph into modules would buy nothing. Every other check still applies to it, and
  `tests/engine/engine-parity.test.ts` runs it against the Lean engine step for step.
- `tests/engine/fixtures/` holds the parity oracle, which is machine-written data and is excluded
  from Biome in `biome.json` because formatting a fixture nobody reads would only double its size.
  `npm run proofs:oracle` regenerates it; `npm run proofs:check` fails when it is stale.
- Every Lean file opens with a `/-! … -/` module doc explaining its design, and every declaration
  carries a `/-- … -/`. That prose is what the generated reader renders, so it is documentation of
  record rather than a comment.
- Only `*.container.tsx` may query Convex, access storage, or orchestrate routes. Three.js scenes and
  objects receive serializable state through props.

## Working style

- Keep the main screen public-information-only; private choices and stats belong on controllers.
- Prefer primitive/procedural assets while mechanics are unsettled. Imported assets need a typed
  `*.asset.ts` boundary.
- Comments explain constraints and non-obvious decisions, not what a line already says.
- Do not leave debug logging, untracked TODO/FIXME markers, or placeholder production values.

<!-- convex-ai-start -->

This project uses [Convex](https://convex.dev) as its backend.

When working on Convex code, **always read
`convex/_generated/ai/guidelines.md` first** for important guidelines on
how to correctly use Convex APIs and patterns. The file contains rules that
override what you may have learned about Convex from training data.

Convex agent skills for common tasks can be installed by running
`npx convex ai-files install`.

<!-- convex-ai-end -->
