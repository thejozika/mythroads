import Mythroads.Compile.Names
import Mythroads.Compile.State
import Mythroads.Compile.Shims
import Mythroads.Compile.Types
import Mythroads.Compile.Expr
import Mythroads.Compile.Code
import Mythroads.Compile.Driver

/-!
# Lean to TypeScript

A compiler from Lean's monomorphised compiler IR (LCNF, `.mono` phase) to readable,
strictly typed TypeScript. It exists so that the rules Convex runs are not a
transcription of `Mythroads.Engine.step` but that definition itself.

Why the compiler IR rather than the kernel term: by the `.mono` phase Lean has already
erased proofs and types, specialised most higher-order code, turned pattern matching
into flat `cases`, and named every intermediate value. What is left is a first-order
functional language with join points — which is almost exactly TypeScript, minus
mutation. Nothing in this compiler has to think about dependent types, universes, or
well-founded recursion; Lean has already discharged all of that.

Read the modules in this order.

| Module | What it settles |
|---|---|
| `Compile.Names` | Lean names to readable TypeScript identifiers |
| `Compile.State` | the compiler monad, work queues, occurrence counting |
| `Compile.Shims` | where compilation stops: the primitive table and the runtime |
| `Compile.Types` | Lean types to TypeScript types, including erasure polarity |
| `Compile.Expr` | literals, constructors and calls — the wire format |
| `Compile.Code` | control flow: `let`, join points, `cases` |
| `Compile.Driver` | the reachable closure, module assembly, and the failure conditions |

The entry point is `proofs/Compile.lean`, the `mythroads-compile` executable, which
loads `Mythroads.Engine` with `Lean.importModules` and writes
`shared/generated/engine.generated.ts`.
-/
