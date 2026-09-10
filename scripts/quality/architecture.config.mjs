export const architectureConfig = {
    sourceRoots: ['src', 'convex', 'shared'],
    ignoredDirectories: new Set(['_generated', 'node_modules', 'dist']),
    maximumFilesPerDirectory: 12,
    maximumLines: {
        source: 300,
        test: 450,
        stylesheet: 500,
    },
    sourceExtensions: new Set(['.ts', '.tsx', '.js', '.jsx', '.css']),
    entryPointExceptions: new Set(['src/main.tsx']),
    /**
     * The one file exempt from the line limit, and why.
     *
     * `shared/generated/engine.generated.ts` is the whole Lean game engine compiled to
     * TypeScript by `lake exe mythroads-compile`: several thousand lines, none of them written
     * or maintained by a person. The limit exists so that a file stays readable to whoever has
     * to change it, and nobody changes this one — the engine is changed in
     * `proofs/Mythroads/Engine/**` and recompiled. Splitting it would mean cutting a strongly
     * connected call graph across modules for no benefit. Every other check still applies to
     * it: Biome's lint and format rules, `tsc --strict`, and the parity suite in
     * `tests/engine/` that runs it against the Lean engine itself.
     */
    lineLimitExceptions: new Set(['shared/generated/engine.generated.ts']),
}

export const frontendTiers = [
    { suffix: '.generated.ts', rank: 0, purpose: 'Lean-emitted rules and endpoint definitions' },
    { suffix: '.type.ts', rank: 0, purpose: 'types and validators without runtime behavior' },
    { suffix: '.util.ts', rank: 0, purpose: 'pure framework-independent logic' },
    {
        suffix: '.system.ts',
        rank: 0,
        purpose: 'deterministic gameplay rules shared by clients and backend',
    },
    { suffix: '.geometry.ts', rank: 0, purpose: 'procedural geometry and spatial data' },
    { suffix: '.material.ts', rank: 1, purpose: 'materials, shaders, and visual parameters' },
    { suffix: '.asset.ts', rank: 1, purpose: 'typed model, texture, and audio loading' },
    { suffix: '.animation.ts', rank: 1, purpose: 'frame animation and transition logic' },
    { suffix: '.hook.ts', rank: 1, purpose: 'reusable React state and effects' },
    { suffix: '.component.tsx', rank: 2, purpose: 'presentational DOM UI' },
    { suffix: '.object.tsx', rank: 2, purpose: 'reusable renderable 3D world object' },
    { suffix: '.effect.tsx', rank: 2, purpose: 'particles, lighting, and post-processing effects' },
    { suffix: '.scene.tsx', rank: 2, purpose: 'Canvas, camera, lights, and scene composition' },
    { suffix: '.context.tsx', rank: 2, purpose: 'React provider and consumer hook' },
    { suffix: '.container.tsx', rank: 3, purpose: 'routing, Convex, storage, and orchestration' },
]
