import Lean.Elab.Command
import Lean.Util.CollectAxioms
import Mythroads

/-! # Axiom audit

A Lean proof is only as trustworthy as the axioms it leans on. Three are the standard classical
foundation and are accepted here: `propext`, `Quot.sound`, and `Classical.choice`. Everything else
is a hole: `sorryAx` means an unfinished proof that still typechecks, and `Lean.ofReduceBool` /
`Lean.trustCompiler` mean a `native_decide` proof whose evidence is a compiled program's answer
rather than a kernel reduction.

This file enumerates *every* theorem reachable from the `Mythroads` import root, collects the
axioms each one depends on the same way `#print axioms` does, and fails elaboration if any theorem
depends on something outside the allowed set. Running it as `lake env lean proofs/Axioms.lean`
therefore exits non-zero on a regression, which is what `npm run proofs:axioms` does.

`nativeDecideAllowlist` is **empty**, and the intent is to keep it that way: every concrete-data
fact in this repository (board reachability, catalogue non-emptiness, matchup coverage, encounter
weights) is proved by `decide`, which the kernel checks, rather than by `native_decide`, which it
trusts. Adding a name here is a deliberate decision to trust the compiler for that one theorem and
should come with a comment saying why kernel reduction is not viable.
-/

open Lean

namespace Mythroads.Axioms

/-- The classical foundation every proof here is allowed to assume. -/
def allowed : List Name := [``propext, ``Quot.sound, ``Classical.choice]

/-- Whether an axiom was minted by `native_decide`. Lean 4.33 generates a fresh axiom per such
proof, named after the theorem, rather than reusing `Lean.ofReduceBool`; both spellings are
recognised so the allowlist keeps working across toolchain versions. -/
def isNativeDecide (axiomName : Name) : Bool :=
  axiomName == ``Lean.ofReduceBool || axiomName == ``Lean.trustCompiler ||
    (axiomName.toString.splitOn "native_decide").length > 1

/-- Theorems permitted to depend on the `native_decide` axioms. Empty by design; see the module
documentation before adding to it. -/
def nativeDecideAllowlist : List Name := []

/-- Whether a theorem may depend on the given axiom. -/
def permits (theoremName axiomName : Name) : Bool :=
  allowed.contains axiomName ||
    (isNativeDecide axiomName && nativeDecideAllowlist.contains theoremName)

/-- Whether a declaration is one of this project's theorems, as opposed to an imported one or an
elaborator-generated helper. -/
def audited (env : Environment) (name : Name) : Bool :=
  (`Mythroads).isPrefixOf name && !name.isInternalDetail &&
    (match env.find? name with
      | some (ConstantInfo.thmInfo _) => true
      | _ => false)

end Mythroads.Axioms

-- A doc comment may not precede `open`, so the note lives here: this command is the audit itself.
-- It fails elaboration -- and therefore the process -- if any audited theorem depends on an axiom
-- outside the allowed set.
open Mythroads.Axioms in
run_cmd Elab.Command.liftCoreM do
  let env ← getEnv
  let names := env.constants.fold (init := #[]) fun acc name _ =>
    if audited env name then acc.push name else acc
  let mut failures : Array (Name × Name) := #[]
  for name in names do
    for axiomName in ← collectAxioms name do
      unless permits name axiomName do
        failures := failures.push (name, axiomName)
  if failures.isEmpty then
    logInfo s!"Axiom audit: {names.size} theorems depend only on {allowed}."
  else
    throwError "Axiom audit failed:{indentD (.joinSep
      (failures.toList.map fun (name, axiomName) => m!"{name} depends on {axiomName}") "\n")}"
