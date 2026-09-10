import Mythroads.Compile.Expr

/-!
# Control flow

LCNF control flow is four constructs, and each has an obvious TypeScript counterpart:

| LCNF | TypeScript |
|---|---|
| `let` | a `const`, or nothing at all when the value is used at most once |
| `fun` / `jp` | a local arrow function; a join point is called, never fallen into |
| `cases` | `if` for `Bool`, `Nat` and `List`; a `switch` on `_` for tagged unions |
| `return` / `jmp` | `return` |

## Join points are local functions

A join point is the shared tail of several branches. Emitting it as a local `const`
keeps the branch structure of the Lean source visible instead of duplicating the tail
into every arm, and TypeScript's own control-flow analysis follows it without help.

## Where a terminator goes

A `switch` with no `default` clause is followed by a `throw`, because Biome reads a
`case` that ends in such a switch as falling through. A `switch` that does have a
`default` needs none, and Biome would reject one as unreachable. An `if`/`else` never
gets one, for the same reason. The `throw` is never reached: Lean has already proved
every one of these matches total.
-/

namespace Mythroads.Compile

open Lean Lean.Compiler.LCNF

/-- The typed parameter list of a function, and the identifiers its body may use. -/
def bindParams (params : Array (Param .pure)) : M (Array (String × String)) := do
  let mut out := #[]
  for p in params do
    let id ← bindFVar p.fvarId p.binderName
    let ty ← tsType p.type
    noteType p.fvarId ty
    out := out.push (id, ty)
  return out

/-- Rename a parameter to `_name` when the body never mentions it, which Biome requires. -/
def hideUnused (body : String) (typed : Array (String × String)) : Array (String × String) :=
  typed.map fun (id, ty) =>
    if occursAsIdent body id || id.startsWith "_" then (id, ty) else ("_" ++ id, ty)

/-- A readable name for a discriminant that has to be bound to a `const`. -/
def scrutineeName (expression : String) : String :=
  let head := (expression.splitOn "(").head!
  let tail := (head.splitOn ".").getLast!
  let cleaned := tail.foldl
    (fun acc c => if c.isAlphanum || c == '_' then acc ++ c.toString else acc) ""
  if cleaned.isEmpty || cleaned.front.isDigit then "scrutinee" else cleaned

mutual

/-- A lambda or join point, as a local arrow function. -/
partial def emitFunDecl (kind : String) (d : FunDecl .pure) (indent : String) : M String := do
  let name ← bindFVar d.fvarId d.binderName
  markConst name
  let typed ← bindParams d.params
  let result ← tsType (resultType d.type d.params.size)
  let outer := (← get).resultTy
  modify fun s => { s with resultTy := result }
  let body ← emitCode d.value (indent ++ "  ")
  modify fun s => { s with resultTy := outer }
  let typed := hideUnused body typed
  let params := String.intercalate ", " (typed.toList.map fun (id, ty) => s!"{id}: {ty}")
  return s!"{indent}// {kind}\n{indent}const {name} = ({params}): {result} => \{\n{body}\
    {indent}};\n"

/--
The body of one `cases` alternative. LCNF destructures every field of the matched
constructor; `binds` says how to read each one back off the discriminant, and a field
used at most once is read at its use site instead of being named.
-/
partial def emitAltBody (params : Array (Param .pure)) (binds : Array String)
    (code : Code .pure) (indent : String) : M String := do
  let mut names := #[]
  let mut named := #[]
  for i in [0:params.size] do
    let p := params[i]!
    let uses ← useCount p.fvarId
    noteType p.fvarId (← tsType p.type)
    if let some b := binds[i]? then
      if uses <= 1 then
        bindExpr p.fvarId b
        names := names.push b
        named := named.push false
        continue
    names := names.push (← bindFVar p.fvarId p.binderName)
    named := named.push true
  let body ← emitCode code indent
  let mut prelude := ""
  for i in [0:params.size] do
    if named[i]! then
      if let some b := binds[i]? then
        if occursAsIdent body names[i]! then
          markConst names[i]!
          prelude := prelude ++ s!"{indent}const {names[i]!} = {b};\n"
  return prelude ++ body

/-- A `switch` over the `_` tag of a discriminated union. -/
partial def emitSwitch (typeName : Name) (d : String) (alts : Array (Alt .pure))
    (indent : String) : M String := do
  let hasDefault := alts.any fun alt => match alt with | .default _ => true | _ => false
  let mut out := s!"{indent}switch ({d}._) \{\n"
  for alt in alts do
    match alt with
    | .alt cn ps code _ =>
        let binds := (← ctorFields cn).map fun f => s!"{d}.{f}"
        let body ← emitAltBody ps binds code (indent ++ "    ")
        out := out ++ s!"{indent}  case \"{ctorTag cn}\": \{\n{body}{indent}  }\n"
    | .default code =>
        let body ← emitCode code (indent ++ "    ")
        out := out ++ s!"{indent}  default: \{\n{body}{indent}  }\n"
  out := out ++ s!"{indent}}\n"
  -- A switch without a `default` gets a terminator: Biome reads a `case` that ends in one
  -- as falling through, and does not read the `throw` as dead code because it cannot see
  -- that Lean already proved the match total. With a `default` it can, so there is none.
  if hasDefault then return out
  return out ++ s!"{indent}throw new Error(\"non-exhaustive match on {typeName}\");\n"

/-- A `cases`, dispatched on how the scrutinised type is represented. -/
partial def emitCases (c : Cases .pure) (indent : String) : M String := do
  let .mk typeName _ discr alts := c
  requestType typeName
  -- The discriminant is bound to a `const` unless it already is one: TypeScript keeps a
  -- narrowing inside a closure only for a `const`, and the arms of a `cases` routinely
  -- build closures over the very field they matched on.
  let raw ← lookupFVar discr
  let mut binding := ""
  let mut d := raw
  unless ← isConstIdent raw do
    d ← bindFVar discr (Name.mkSimple (scrutineeName raw))
    markConst d
    binding := s!"{indent}const {d} = {raw};\n"
  let inner := indent ++ "  "
  let arm (name : Name) (binds : Array String) : M (Option String) := do
    for alt in alts do
      if let .alt cn ps code _ := alt then
        if cn == name then return some (← emitAltBody ps binds code inner)
    return none
  let fallback : M (Option String) := do
    for alt in alts do
      if let .default code := alt then return some (← emitCode code inner)
    return none
  let fill (chosen : Option String) : M String := do
    match chosen, ← fallback with
    | some body, _ => return body
    | none, some body => return body
    | none, none => return s!"{inner}throw new Error(\"unmatched alternative\");\n"
  let ifThenElse (test : String) (whenTrue whenFalse : Option String) : M String := do
    return s!"{indent}if ({test}) \{\n{← fill whenTrue}{indent}} else \{\n{← fill whenFalse}\
      {indent}}\n"
  let body ← match ← repOfM typeName with
    | .bool => ifThenElse d (← arm ``Bool.true #[]) (← arm ``Bool.false #[])
    | .nat =>
        ifThenElse s!"{d} === 0" (← arm ``Nat.zero #[]) (← arm ``Nat.succ #[s!"({d} - 1)"])
    | .list =>
        ifThenElse s!"{d}.length === 0" (← arm ``List.nil #[])
          (← arm ``List.cons #[s!"{d}[0]", s!"{d}.slice(1)"])
    | .plain =>
        match alts[0]? with
        | some (Alt.alt cn ps code _) =>
            emitAltBody ps ((← ctorFields cn).map fun f => s!"{d}.{f}") code indent
        | some (Alt.default code) => emitCode code indent
        | none => pure s!"{indent}throw new Error(\"empty cases\");\n"
    | _ => emitSwitch typeName d alts indent
  -- The `const` lives inside this branch only, so the discriminant goes back to being the
  -- expression it was: a sibling branch of the enclosing `cases` cannot see this binding.
  unless binding.isEmpty do bindExpr discr raw
  return binding ++ body

/-- One block of LCNF code. -/
partial def emitCode (code : Code .pure) (indent : String) : M String := do
  match code with
  | .let decl k =>
      let raw ← letValueToTs decl.value
      let declared ← tsType decl.type
      -- LCNF knows the type of the binding even where the callee's own signature lost it
      -- to erasure. This is the one place the knowledge is put back.
      let value := match ← letValueType decl.value with
        | some actual => castTo raw actual declared
        | none => raw
      noteType decl.fvarId declared
      if (← useCount decl.fvarId) <= 1 then
        -- Dead or used exactly once: inline it, which only ever delays a pure computation.
        bindExpr decl.fvarId value
        emitCode k indent
      else
        let name ← bindFVar decl.fvarId decl.binderName
        markConst name
        let rest ← emitCode k indent
        -- Every binding is given the type LCNF recorded for it. Without one, a constructor
        -- object would widen its `_` tag to `string` and stop being a member of its own
        -- union. The exception is the empty list, which Lean shares across every element
        -- type at once, so it is typed `never[]`, which fits all of them.
        let annotation ←
          if value == "[]" then pure ": never[]"
          else do
            let ty ← tsType decl.type
            pure (if occursAsIdent ty erasedName then "" else s!": {ty}")
        return s!"{indent}const {name}{annotation} = {value};\n" ++ rest
  | .fun decl k _ => return (← emitFunDecl "lambda" decl indent) ++ (← emitCode k indent)
  | .jp decl k => return (← emitFunDecl "join point" decl indent) ++ (← emitCode k indent)
  | .jmp fv args =>
      let f ← lookupFVar fv
      let values ← args.mapM argToTs
      return s!"{indent}return {f}({String.intercalate ", " values.toList});\n"
  | .cases c => emitCases c indent
  | .return fv =>
      let value ← lookupFVar fv
      let expected := (← get).resultTy
      let value := match ← fvarType fv with
        | some source => castTo value source expected
        | none => value
      return s!"{indent}return {value};\n"
  | .unreach _ =>
      return s!"{indent}throw new Error(\"unreachable state in the compiled engine\");\n"

end

end Mythroads.Compile
