import Mythroads.Convex.TypeScript

namespace Mythroads.Convex

/-! # Generated modules as data

A generated TypeScript file used to be assembled by whichever `*Main.lean` executable happened to
own it: a hand-written `generatedHeader : String` holding the provenance comment and a literal
block of `import` lines, concatenated with whatever the emitter produced. Thirty such blobs meant
thirty places where an identifier referenced by an emitter (`.identifier "advanceTurn"`) had to be
matched by hand against an import line, and where a duplicate or misordered import was invisible
until Biome or `tsc` complained.

`Module` makes the whole file data. `Import` is a record, so imports from the same module
specifier merge, duplicate bindings collapse, and the list is ordered by a total order rather than
by editing history. `Item` is the body: either a syntax tree this repository can already print
(`Function`, type alias, endpoint definition) or a `raw` block for the catalogue emitters that
still assemble their own text.

Layout contract, chosen to reproduce the bytes the hand-written headers produced:

* the provenance comment, when present, is the first line;
* import lines follow immediately, with no blank line after the comment;
* a single blank line separates the import block from the body, and only when there are imports;
* body items are newline-terminated and separated by one blank line.

Import *order* is not load-bearing: `scripts/lean/check-generated.mjs` runs Biome's
`organizeImports` assist over the emitted tree before comparing, so Biome is the arbiter of import
order exactly as it is the arbiter of line width. The ordering here only has to be deterministic.
-/

/-- One name imported from a module, and whether it is a type-only binding. -/
structure Binding where
  /-- The imported identifier, optionally including an `as` clause. -/
  name : String
  /-- Whether the binding is types-only (`import type` or an inline `type` specifier). -/
  isType : Bool := false
  deriving Repr, DecidableEq, Inhabited

/-- A single `import` statement. A `default` binding and named `bindings` are mutually exclusive in
practice; the only default import in this codebase is `schema`. -/
structure Import where
  /-- The module specifier, exactly as it appears between the quotes. -/
  source : String
  /-- The default binding, for `import name from '…'`. -/
  «default» : Option String := none
  /-- The named bindings, for `import { … } from '…'`. -/
  bindings : List Binding := []
  deriving Repr, DecidableEq, Inhabited

/-- A top-level declaration in a generated module. -/
inductive Item where
  /-- Pre-rendered TypeScript, newline-terminated. The escape hatch used by the catalogue emitters
  under `Mythroads/Game/`, which still build their data tables as text. -/
  | raw (source : String)
  /-- A function declaration built from the TypeScript syntax tree. -/
  | function (value : TypeScript.Function)
  /-- An exported type alias. -/
  | typeAlias (name : String) (type : TypeScript.TsType)
  /-- A Convex `{ args, returns, handler }` record for a registrar to wrap. -/
  | endpoint (value : TypeScript.EndpointDefinition)

/-- A complete generated TypeScript file. -/
structure Module where
  /-- The Lean source this file is generated from, rendered into the provenance comment. Every
  generated file should have one; `none` exists only so a module can opt out deliberately. -/
  provenance : Option String := none
  /-- The module's imports, merged and ordered by `Module.render`. -/
  imports : List Import := []
  /-- The module body. -/
  items : List Item := []

namespace Import

/-- Renders one named binding, `name` or `type Name`. -/
private def bindingText (binding : Binding) : String :=
  if binding.isType then "type " ++ binding.name else binding.name

/-- Renders one `import` statement, newline-terminated. A binding list that is entirely type-only
becomes an `import type { … }` statement; a mixed list uses inline `type` specifiers. -/
def render (value : Import) : String :=
  let tail := " from " ++ TypeScript.quote value.source ++ "\n"
  match value.default, value.bindings with
  | some name, [] => "import " ++ name ++ tail
  | some name, bindings =>
      "import " ++ name ++ ", { " ++
        TypeScript.join ", " (bindings.map bindingText) ++ " }" ++ tail
  | none, [] => "import " ++ TypeScript.quote value.source ++ "\n"
  | none, bindings =>
      if bindings.all (·.isType) then
        "import type { " ++ TypeScript.join ", " (bindings.map (·.name)) ++ " }" ++ tail
      else
        "import { " ++ TypeScript.join ", " (bindings.map bindingText) ++ " }" ++ tail

end Import

namespace Module

/-- Case-insensitive-then-case-sensitive ordering, so `Element` and `elementMatchup` sort next to
each other the way Biome's import assist groups them. -/
private def nameLe (left right : String) : Bool :=
  let lowerLeft := left.toLower
  let lowerRight := right.toLower
  if lowerLeft == lowerRight then left ≤ right else lowerLeft < lowerRight

/-- Merges the bindings of two imports of the same module, dropping duplicates. A name imported
both as a value and as a type keeps the value form, which is the wider of the two. -/
private def mergeBindings (left right : List Binding) : List Binding :=
  let combined := left ++ right
  combined.foldl (init := []) fun acc binding =>
    if acc.any (·.name == binding.name) then
      acc.map fun existing =>
        if existing.name == binding.name then
          { existing with isType := existing.isType && binding.isType }
        else existing
    else acc ++ [binding]

/-- Collapses imports that share a module specifier, preserving first-mention order. -/
private def mergeImports (values : List Import) : List Import :=
  values.foldl (init := []) fun acc value =>
    if acc.any (·.source == value.source) then
      acc.map fun existing =>
        if existing.source == value.source then
          { existing with
            «default» := existing.default.or value.default
            bindings := mergeBindings existing.bindings value.bindings }
        else existing
    else acc ++ [value]

/-- Merges, deduplicates, and orders a module's imports: package specifiers first, then relative
ones, each group ordered by specifier, with the bindings of each statement ordered by name. -/
def normalizeImports (values : List Import) : List Import :=
  let merged := (mergeImports values).map fun value =>
    { value with bindings := value.bindings.mergeSort fun a b => nameLe a.name b.name }
  let relative := fun (value : Import) => value.source.startsWith "."
  let packages := merged.filter (fun value => !relative value)
  let locals := merged.filter relative
  (packages.mergeSort fun a b => nameLe a.source b.source) ++
    (locals.mergeSort fun a b => nameLe a.source b.source)

/-- Renders one body item, newline-terminated. -/
def renderItem : Item → String
  | .raw source => source
  | .function value => TypeScript.emitFunction value
  | .typeAlias name type => TypeScript.emitTypeAlias name type
  | .endpoint value => TypeScript.emitEndpointDefinition value

/-- Renders a complete generated TypeScript file. -/
def render (value : Module) : String :=
  let header := match value.provenance with
    | none => ""
    | some source => "/** Generated from " ++ source ++ ". Do not edit by hand. */\n"
  let imports := normalizeImports value.imports
  let importBlock := String.join (imports.map Import.render)
  let separator := if imports.isEmpty then "" else "\n"
  header ++ importBlock ++ separator ++
    TypeScript.join "\n" (value.items.map renderItem)

end Module
end Mythroads.Convex
