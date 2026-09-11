# World and Lean pipeline verification

This audit records the evidence for the board redesign and Lean-authored backend goal. Passing
automated checks establishes the properties they exercise; visual quality still requires viewing
the rendered board.

| Requirement | Evidence | Status |
| --- | --- | --- |
| Branching board instead of one ring | `Game/World.lean` declares local roads and three islands; `gameplay.test.mjs` checks branching and bridge-only crossings | Automated checks pass |
| Landmarks adjacent to playable fields | Castle node declares a landmark offset; `BoardSpace.object.tsx` renders the castle in that offset group | Implemented; rendered review outstanding |
| Five distinct simple cycles on every island | `World/Requirement.lean` derives witnesses and independently checks simplicity, direction, uniqueness and island membership; its imported `#guard` rejects invalid worlds | Build gate passes |
| Degree and teleport requirements | Distinct neighbours determine degree; teleport endpoints pair across islands; regression cases remove roads and pairings | Build gate and negative cases pass |
| Teleports trigger on landing | `Engine/Step/Landing.lean` updates position once and advances the turn; `tests/convex/teleport.test.ts` drives the public mutation | Test passes |
| Lean-authored deterministic transition | `Engine/Step.lean` owns the transition; `Compile.lean` emits the shared engine; parity fixtures compare engine behavior | Generation and parity checks pass |
| Convex consumes generated backend code | `Emit.lean` owns output paths; public modules register generated definitions; architecture tests enforce the boundary | Checks pass |
| Inventory owner-only policy | `Authz.lean` proves denial for a different actor, item ownership, and noninterference of other inventories | Axiom audit passes |
| Production inventory access enforcement | `Backend/Inventory.lean` emits verified-identity checks followed by an indexed owner-scoped read; `authorization.test.ts` exercises owner, stranger, anonymous and foreign-item cases | Tests pass |

## Proof boundary

The topology soundness theorem derives existential cycle witnesses from an accepted check. The
concrete board is checked with `#guard`; this is an executable compilation assertion, not a named
kernel proof of that specific board. The search stops after five distinct witnesses and therefore
does not report the total number of cycles.

Inventory policy theorems describe the Lean authorization model. The emitted query separately
implements the ownership check and indexed database read. Current tests connect these layers,
but there is no proved interpreter/compiler correspondence for the entire asynchronous Convex
query, nor a proof of Convex or Hanko itself. Do not describe this as end-to-end formally verified
infrastructure.

## Remaining verification

- Live Chrome DevTools capture after real elapsed worker time confirms the bundled font renders:
  field symbols and the pawn name are visible. Earlier virtual-time screenshots were premature.
  The text worker is functioning; no worker workaround is required. Console errors instead show
  Hanko rejecting the localhost demo origin, which should be investigated separately from text.
- Noto Sans and its SIL license are bundled in `public/fonts/` and selected by the shared 3D
  text component. A new headless capture still lacks text, so external font availability alone
  does not explain the remaining problem. Inspect worker execution and text synchronization;
  do not treat the bundled asset as proof that labels render. The full check passes with it.
- A subsequent capture after adding local text Suspense boundaries renders the main island,
  branching rectangular fields, river bridges, hill, pawn, teleport gates and adjacent castle.
  The prior blank scene was caused by font loading suspending the scene. The new boundary keeps
  geometry and camera updates visible while labels load. Text labels remain absent in the
  headless capture and need follow-up; outer-island framing is not yet visually reviewed.
- Browser review attempted with isolated headless Chrome at `/display/demo`, using both default
  graphics and SwiftShader. Both captures show the HUD and background but no board. Chrome logs
  report display-link initialization errors. This does not yet distinguish an environment issue
  from an application loading/rendering defect. Inspect scene suspension and font loading next;
  do not mark visual review complete from these captures.
- Review the rendered three-island board for grid-like readability, landmark placement, and
  controller navigation; automated graph checks alone do not establish the visual result.
- Keep the query/model correspondence limitation explicit when explaining inventory proofs.

The last complete `npm run check` passed with 26 quality tests, 85 Vitest tests, code-generation
parity, documentation freshness, the axiom audit, lint, formatting and a production build.
