import Lean

/-! # `mythroads-docs`: the documentation exporter

`scripts/lean/build-definition-reader.mjs` renders an HTML reader of the Lean sources. It used to
recover declarations with regular expressions, which meant it guessed at kinds, could not see a
signature, and had no idea which module documentation belonged where. This executable replaces the
guessing with the elaborator's own answer: it imports the compiled `Mythroads` modules, walks the
environment, and prints one JSON document describing every authored declaration.

Per module it reports the source file, the modules it imports (the reader turns that graph into a
reading order), every `/-! -/` prose block with the line it starts on, and every declaration the
author actually wrote: name, kind, docstring, pretty-printed signature, line range, the exact
source slice, and — for theorems — the axioms the proof depends on.

Compiler-generated declarations are excluded four ways: `findDeclarationRanges?` returns `none` for
anything without a position in a source file, `isBoring` reimplements the blacklist doc-gen4
inherits from Mathlib, constructors and field projections are dropped because the structure's own
source already shows them, and an undocumented `instance` is a `deriving` product rather than
something a person wrote.

One limitation is worth knowing, because the reader works around it. The environment `importModules`
assembles here has no notation delaborators, so `ppExpr` prints `Eq (step s env) …` rather than
`step s env = …`. Signatures of definitions are unaffected and read well (`State → Envelope →
Outcome`); propositions do not, which is why the reader shows a theorem's *source* statement as
written and keeps the elaborated type beside the proof, where seeing the implicit binders is
actually useful.

Usage: `lake exe mythroads-docs <source-root> <root-module>…`. The root modules are imported and
every module below the `Mythroads` namespace in their import closure is documented, in the order
Lean loaded them — which is a topological order, and therefore already a defensible reading order.
Output goes to standard output as one JSON object.
-/

open Lean Meta

namespace Mythroads.Docs

/-- One `/-! -/` prose block, with the line it starts on so the reader can interleave it. -/
structure Prose where
  /-- The 1-based line the block opens on. -/
  startLine : Nat
  /-- The block's markdown text, without the delimiters. -/
  text : String
  deriving ToJson, FromJson

/-- One exported declaration: everything the reader needs to render it. -/
structure Decl where
  /-- The fully qualified name, exactly as Lean knows it. -/
  name : String
  /-- `def`, `structure`, `inductive`, `theorem`, `instance`, `abbrev`, `opaque`. -/
  kind : String
  /-- The `/-- -/` docstring, when the author wrote one. -/
  doc : Option String := none
  /-- The 1-based first line of the declaration, including its docstring. -/
  startLine : Nat
  /-- The 1-based last line of the declaration. -/
  endLine : Nat
  /-- The declaration's type, pretty-printed the way an editor hover shows it. -/
  signature : String
  /-- The exact source text of the declaration, sliced out of the `.lean` file. -/
  source : String
  /-- For a theorem, the axioms its proof term depends on. Empty for everything else. -/
  axioms : Array String := #[]
  deriving ToJson, FromJson

/-- One module: where it lives, what it imports, its prose, and its declarations. -/
structure Module where
  /-- The Lean module name, such as `Mythroads.Engine.Step`. -/
  name : String
  /-- The source path, relative to the repository root. -/
  file : String
  /-- The modules this one imports, for the reader's reading order. -/
  imports : Array String := #[]
  /-- Number of lines in the source file. -/
  lines : Nat := 0
  /-- The `/-! -/` blocks, in source order. -/
  prose : Array Prose := #[]
  /-- The authored declarations, in source order. -/
  decls : Array Decl := #[]
  deriving ToJson, FromJson

/-- The whole export: the toolchain it was produced with and one entry per module. -/
structure Export where
  /-- The Lean version string, so the reader can state what elaborated it. -/
  toolchain : String
  /-- Every requested module, in the order they were requested. -/
  modules : Array Module
  deriving ToJson, FromJson

/-- Whether a name is an instance name.

`instanceExtension` is empty in an environment assembled by `importModules`, so the naming
convention is the reliable signal here: Lean names every anonymous instance `inst…`, and the
helpers a `deriving` clause generates below one (`instReprState.repr`) carry that component too. -/
private def isInstanceName (name : Name) : Bool :=
  name.components.any fun part => part.toString.startsWith "inst"

/-- Which declaration keyword produced this constant. -/
private def kindOf (env : Environment) (name : Name) : String :=
  match env.find? name with
  | some (.inductInfo _) => if isStructure env name then "structure" else "inductive"
  | some (.thmInfo _) => "theorem"
  | some (.axiomInfo _) => "axiom"
  | some (.opaqueInfo _) => "opaque"
  | some (.ctorInfo _) => "constructor"
  | some (.defnInfo info) =>
      if (instanceExtension.getState env).instanceNames.contains name || isInstanceName name then
        "instance"
      else if (projectionFnInfoExt.find? env name).isSome then "projection"
      else if info.hints matches .abbrev then "abbrev"
      else "def"
  | _ => "other"

/-- Suffixes Lean appends when it derives a helper from a declaration the author wrote. -/
private def autoSuffixes : List String :=
  [".sizeOf_spec", ".injEq", ".eq_def", ".ctorIdx", ".ctorElim", ".ctorElimType", ".elim",
    ".below", ".ibelow", ".brecOn", ".binductionOn", ".ofNat", ".toCtorIdx", ".noConfusionType",
    ".noConfusion", ".casesOn", ".recOn", ".rec", ".induct", ".fun_cases", ".mutual_induct",
    ".eq_1", ".eq_2", ".eq_3", ".eq_4", ".eq_5", ".eq_6", ".eq_7", ".eq_8", ".eq_9"]

/-- The blacklist doc-gen4 and Mathlib share, reimplemented without the Mathlib dependency. -/
private def isBoring (name : Name) : MetaM Bool := do
  let env ← getEnv
  if name.isInternalDetail || isAuxRecursor env name || isNoConfusion env name then return true
  if isRecCore env name || (← Meta.isMatcher name) then return true
  let text := name.toString
  if (text.splitOn ".proof_").length > 1 || (text.splitOn ".match_").length > 1 then return true
  return autoSuffixes.any fun suffix => text.endsWith suffix

/-- The modules a source file imports, read off its `import` lines. -/
private def importsOf (lines : List String) : Array String :=
  lines.foldl (init := #[]) fun acc line =>
    if line.startsWith "import " then acc.push (line.drop 7).trimAscii.toString else acc

/-- The path of a module's source file below `root`. -/
private def sourceOf (root : System.FilePath) (m : Name) : System.FilePath :=
  m.components.foldl (init := root) (fun path part => path / part.toString) |>.addExtension "lean"

/-- Pretty-print a type as an editor hover would, with names shortened against `ns`. -/
private def ppSignature (ns : Name) (type : Expr) : MetaM String :=
  withTheReader Core.Context (fun context => { context with currNamespace := ns }) do
    return (← ppExpr type).pretty 78

/-- Collect every authored declaration of `mods`, grouped by module and ordered by line. -/
def collect (root : System.FilePath) (mods : Array Name) : MetaM (Array Module) := do
  let env ← getEnv
  let wanted : Std.HashSet Name := mods.foldl (·.insert ·) {}
  let mut byModule : Std.HashMap Name (Array Decl) := {}
  for (name, info) in env.constants.toList do
    let some index := env.getModuleIdxFor? name | continue
    let modName := env.header.moduleNames[index.toNat]!
    unless wanted.contains modName do continue
    if ← isBoring name then continue
    let kind := kindOf env name
    if kind == "constructor" || kind == "projection" then continue
    let doc ← findDocString? env name
    -- An undocumented instance is a `deriving` product; every hand-written one carries a docstring.
    if kind == "instance" && doc.isNone then continue
    let some range ← findDeclarationRanges? name | continue
    let axioms ← if kind == "theorem" then
        pure ((← collectAxioms name).map (·.toString))
      else pure #[]
    let decl : Decl := {
      name := name.toString
      kind
      doc
      startLine := range.range.pos.line
      endLine := range.range.endPos.line
      signature := ← ppSignature name.getPrefix info.type
      source := ""
      axioms }
    byModule := byModule.insert modName ((byModule.getD modName #[]).push decl)
  mods.mapM fun m => do
    let file := sourceOf root m
    let text ← IO.FS.readFile file
    let lines := text.splitOn "\n"
    let slice (a b : Nat) : String :=
      String.intercalate "\n" ((lines.drop (a - 1)).take (b - a + 1)) |>.trimAsciiEnd.toString
    let ordered := (byModule.getD m #[]).qsort fun x y =>
      x.startLine < y.startLine || (x.startLine == y.startLine && x.name < y.name)
    return {
      name := m.toString
      file := file.toString
      imports := importsOf lines
      lines := lines.length
      prose := (getModuleDoc? env m |>.getD #[]).map fun block =>
        { startLine := block.declarationRange.pos.line, text := block.doc }
      decls := ordered.map fun d => { d with source := slice d.startLine d.endLine } }

end Mythroads.Docs

open Mythroads.Docs in
/-- Imports the root modules and prints the documentation of their `Mythroads` closure. -/
def main (args : List String) : IO UInt32 := do
  let (root, names) := match args with
    | root :: rest => (root, rest)
    | [] => (".", [])
  if names.isEmpty then
    IO.eprintln "usage: mythroads-docs <source-root> <root-module>…"
    return 1
  initSearchPath (← findSysroot)
  let roots := (names.map (·.toName)).toArray
  let env ← importModules (roots.map ({ module := · })) {} (trustLevel := 1024)
  -- Lean loads modules in a topological order of the import graph, so this is a reading order.
  let mods := env.header.moduleNames.filter fun m => (`Mythroads).isPrefixOf m
  let context : Core.Context := { fileName := "<mythroads-docs>", fileMap := default }
  let (modules, _) ← ((collect root mods).run' {} {}).toIO context { env }
  IO.println (toJson { toolchain := Lean.versionString, modules : Export }).compress
  return 0
