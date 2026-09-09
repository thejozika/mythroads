# Code architecture

The taxonomy makes a file's allowed responsibilities visible in its name. It is deliberately more
specific around Three.js because scene code otherwise tends to accumulate data loading, gameplay,
animation, networking, and rendering in one opaque component.

## Hard limits

| Scope | Limit | Response |
|---|---:|---|
| Production source | 300 lines | Split at a responsibility boundary |
| Test source | 450 lines | Split fixtures or behaviors |
| Stylesheet | 500 lines | Split by screen or feature |
| Direct files in a code folder | 12 | Introduce a named feature subfolder |

These limits are enforced by `npm run check:architecture`. Generated Convex code is excluded.
Line limits are intentionally strict while the project is young; exceptions tend to become permanent.

## General frontend taxonomy

| Suffix | Owns | Must not own |
|---|---|---|
| `*.type.ts` | Shared types and validators | Runtime behavior |
| `*.util.ts` | Small pure helpers | React, Convex, browser state |
| `*.system.ts` | Deterministic gameplay rules and state transitions | React, Three.js, Convex calls, randomness not supplied as input |
| `*.hook.ts` | One reusable `useX` behavior | Page composition or backend definitions |
| `*.component.tsx` | Presentational DOM UI | Convex calls or route/storage orchestration |
| `*.context.tsx` | A provider and its consumer hook | Feature UI |
| `*.container.tsx` | Convex subscriptions, mutations, routing, storage, screen orchestration | Low-level geometry or materials |
| `*.generated.ts` | Lean-emitted endpoint definitions and stable rule artifacts | Hand-authored behavior |

Runtime dependencies flow upward: types/utilities/systems → hooks/resources → renderable UI →
containers. Type-only imports may cross tiers because they produce no runtime coupling.

## Three.js taxonomy

| Suffix | Owns | Example |
|---|---|---|
| `*.geometry.ts` | Procedural vertices, curves, paths, spatial calculations | Road spline generation |
| `*.material.ts` | Materials, shaders, uniforms, visual constants | Combat-space shader |
| `*.asset.ts` | Typed GLTF, texture, font, and audio loading/preloading | Character model catalogue |
| `*.animation.ts` | Reusable frame updates and transition math | Pawn hop along an edge |
| `*.object.tsx` | A reusable object placed in a 3D world | Pawn, tree, embedded field |
| `*.effect.tsx` | Particles, environmental effects, post-processing | Combat landing burst |
| `*.scene.tsx` | Canvas, camera, lights, controls, and high-level world composition | Main board scene |

Three.js files never call Convex. Scene and object files never access DOM storage or route state.
They receive plain state and callbacks. `*.system.ts` must remain Three.js-independent so rules can
be verified on the backend and replayed in tests.

Do not create every possible suffix preemptively. Introduce a file when a real responsibility exists.
For a tiny object, keep local geometry and material declarations inside its `*.object.tsx`; extract
them only when reused or independently complex.

## Feature folders

The target shape is:

```text
src/
  app/                 routing and application composition
  game/
    board/             board systems and 3D board presentation
    combat/            combat systems and combat presentation
    controller/        private phone controls
    events/            event systems and presentation
  lib/                 narrow cross-feature integrations
shared/                deterministic rules also imported by Convex
convex/                authoritative commands, queries, and persistence
proofs/Mythroads/      Lean endpoint manifests, deterministic models, and theorems
```

When a folder approaches 12 files, split by concept (`board/terrain`, `board/pawns`) rather than by
generic file type (`components`, `utils`). Keep tests adjacent to the file they verify.

## Enforcement layers

1. `.claude/settings.json` runs an advisory post-edit hook for immediate AI feedback.
2. Biome handles syntax-aware linting, imports, accessibility, and formatting.
3. `check-architecture.mjs` handles repository-specific structural rules.
4. `.githooks/pre-commit` runs fast architecture and lint checks when enabled.
5. GitHub Actions runs the complete `npm run check` gate.

The post-edit hook reports problems without discarding an edit. The pre-commit and CI gates block
violations. This keeps iteration fast while preventing structural debt from entering shared history.
