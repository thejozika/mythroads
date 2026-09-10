import Mythroads.Compile

/-!
# `mythroads-compile`: the engine, as TypeScript

`lake exe mythroads-compile <output-root>` writes `shared/generated/engine.generated.ts`
below the given root. It is the second half of the code generator: `mythroads-emit`
prints the Convex boundary from Lean *values*, while this executable compiles Lean
*functions* — `Mythroads.Engine.step` and everything it reaches.

The environment is loaded with `Lean.importModules` rather than being the executable's
own, because the compiler must read the persisted LCNF of the engine's declarations out
of their `.olean` files; that is also why the engine modules do not need to know that
this compiler exists.

`scripts/lean/check-generated.mjs` runs this into a staging directory beside
`mythroads-emit`, formats the whole tree with Biome, and compares it against the
repository, so a stale compiled engine fails `npm run check` exactly like a stale
generated Convex module.
-/

open Lean Mythroads.Compile

/--
Everything the Convex adapter and the parity harness need to reach.

Beyond `step` itself the boundary needs four classifiers, the refusal table, and
`Lobby.roomCode`. That last one is there for the collision retry: when a drawn code is
already taken the boundary must draw the next one *from the same generator the rules
use*, so it calls the engine's own function rather than restating Park-Miller.
-/
def roots : List Name :=
  [`Mythroads.Engine.step,
    `Mythroads.Engine.Event.name,
    `Mythroads.Engine.Event.authority,
    `Mythroads.Engine.Event.durable,
    `Mythroads.Engine.Phase.name,
    `Mythroads.Engine.Error.message,
    `Mythroads.Engine.Lobby.roomCode]

/-- The path of the compiled engine, relative to the output root. -/
def outputPath : System.FilePath := "shared/generated/engine.generated.ts"

/-- Compile the engine and write it, or report why the output cannot be trusted. -/
def main : List String → IO UInt32
  | [root] => do
      initSearchPath (← findSysroot)
      let env ← importModules #[{ module := `Mythroads.Engine }] {} (trustLevel := 1024)
      let ctx : Core.Context := { fileName := "<mythroads-compile>", fileMap := default }
      -- Two passes: the first only to learn every top-level name, the second to emit code
      -- in which no local identifier shadows one of them.
      let ((_, discovery), _) ← ((compileEngine roots).run {}).toIO ctx { env }
      let ((body, st), _) ←
        ((compileEngine roots).run { reserved := claimedIdents discovery }).toIO ctx { env }
      match failures st with
      | some problem =>
          IO.eprintln s!"mythroads-compile refused to write the engine:\n{problem}"
          return 1
      | none =>
          let target := System.FilePath.mk root / outputPath
          if let some parent := target.parent then IO.FS.createDirAll parent
          IO.FS.writeFile target body
          IO.eprintln s!"compiled {st.fns.size} functions and {st.tys.size} types into {target}"
          return 0
  | _ => do
      IO.eprintln "usage: mythroads-compile <output-root>"
      return 1
