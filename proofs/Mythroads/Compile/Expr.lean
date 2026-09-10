import Mythroads.Compile.Types
import Mythroads.Compile.Shims

/-!
# Values: literals, constructors and calls

This module translates the right-hand side of an LCNF `let`. It never looks at control
flow; `Mythroads.Compile.Code` does that.

## The wire format

The shapes chosen here are the contract between the compiled engine and the Convex
adapter that stores its results, so they are deliberately boring JSON:

* a structure is a plain object, `{ code: "JSKM", host: "…", players: […] }`;
* a many-constructor inductive is a discriminated union tagged with `_`,
  `{ _: "combat", battle: {…}, stage: { _: "attackerChoice" } }`;
* a `List` is an array, `Nat` and `Int` are numbers, `String` is a string;
* `Option` is `{ _: "none" }` or `{ _: "some", val: … }` — *not* `undefined` — because
  a Convex document round-trips an absent field and a present `null` differently, and
  the engine's `Option` fields must survive that round trip unchanged.

## Calls

Arguments the callee erases (types and proofs) are dropped at every call site and from
every signature, so the emitted code speaks only in computationally relevant values.
An under-applied constant becomes an arrow function that supplies the rest; an
over-applied one is called and then applied again.
-/

namespace Mythroads.Compile

open Lean Lean.Compiler.LCNF

/-- Substitute `$0`, `$1`, … in a shim template. -/
def applyTemplate (t : String) (args : Array String) : String := Id.run do
  let mut out := ""
  let mut rest := t.toList
  repeat
    match rest with
    | [] => break
    | '$' :: d :: tl =>
        if d.isDigit then
          out := out ++ (args[d.toNat - '0'.toNat]!)
          rest := tl
        else
          out := out ++ "$"
          rest := d :: tl
    | c :: tl =>
        out := out ++ c.toString
        rest := tl
  return out

/-- A literal, as TypeScript. `Nat` literals beyond the exact-integer range are refused. -/
def litToTs : LitValue → M String
  | .nat n =>
      if n < 9007199254740992 then return toString n
      else do
        recordMissing (Name.mkSimple s!"literal-exceeds-2^53:{n}")
        return toString n
  | .str s => return "\"" ++ s.foldl (fun acc c =>
      acc ++ (if c == '"' then "\\\"" else if c == '\\' then "\\\\"
              else if c == '\n' then "\\n" else if c == '\t' then "\\t"
              else if c == '\r' then "\\r" else c.toString)) "" ++ "\""
  | .uint8 v => return toString v.toNat
  | .uint16 v => return toString v.toNat
  | .uint32 v => return toString v.toNat
  | .uint64 v => return toString v.toNat
  | .usize v => return toString v.toNat

/--
The signature of a callee as this compiler sees it: which parameters monomorphisation
erased, and the TypeScript type of each of the rest. `none` means the callee has no
compiled body at all, which is how a primitive is recognised.
-/
def calleeSignature (n : Name) : M (Option (Array Bool × Array String)) := do
  match (← getDeclAt? n .mono) with
  | some d =>
      let mut types := #[]
      for p in d.params do
        unless p.type.isErased do types := types.push (← tsType p.type)
      return some (d.params.map (fun p => p.type.isErased), types)
  | none => return none

/-- An argument: either a bound value or something monomorphisation erased. -/
def argToTs (a : Arg .pure) : M String := do
  match a with
  | .erased | .type .. => return "undefined"
  | .fvar fv => lookupFVar fv

/-- An argument, cast to the type the position expects when erasure lost it. -/
def argToTsAt (a : Arg .pure) (target : String) : M String := do
  let value ← argToTs a
  if mentionsTypeVariable target then return value
  match a with
  | .fvar fv =>
      match ← fvarType fv with
      | some source => return castTo value source target
      | none => return value
  | _ => return value

/-- Build a value of an inductive type from a constructor application. -/
def ctorToTs (ctorName : Name) (args : Array (Arg .pure)) : M String := do
  let .ctorInfo cv ← getConstInfo ctorName | return "undefined"
  requestType cv.induct
  let fieldArgs := args.extract cv.numParams args.size
  let fieldTypes ← ctorFieldTypes ctorName
  let mut values := #[]
  for i in [0:fieldArgs.size] do
    values := values.push (← argToTsAt fieldArgs[i]! ((fieldTypes[i]?).getD erasedName))
  match (← repOfM cv.induct) with
  | .bool => return if ctorName == ``Bool.true then "true" else "false"
  | .nat =>
      if ctorName == ``Nat.zero then return "0" else return s!"({values[0]!} + 1)"
  | .list =>
      if ctorName == ``List.nil then return "[]"
      else
        let tail := values[1]!
        -- Splice `cons a [b, c]` into `[a, b, c]` rather than `[a, ...[b, c]]`.
        if tail == "[]" then return s!"[{values[0]!}]"
        else if tail.front == '[' then return s!"[{values[0]!}, " ++ tail.drop 1
        else return s!"[{values[0]!}, ...{tail}]"
  | .str | .int =>
      recordMissing ctorName
      return "undefined"
  | .plain =>
      let fields ← ctorFields ctorName
      if fields.isEmpty then return "{}"
      return "{ " ++ String.intercalate ", "
        (fields.zipWith (fun f v => s!"{f}: {v}") values).toList ++ " }"
  | .tagged =>
      let fields ← ctorFields ctorName
      let parts := (fields.zipWith (fun f v => s!"{f}: {v}") values).toList
      return "{ _: \"" ++ ctorTag ctorName ++ "\"" ++
        (if parts.isEmpty then "" else ", " ++ String.intercalate ", " parts) ++ " }"

/--
Apply `arity` arguments to something, eta-expanding when too few were supplied and
re-applying the result when too many were.
-/
def applyArgs (values : Array String) (arity : Nat) (build : Array String → String) :
    String :=
  if values.size == arity then build values
  else if values.size < arity then
    let extra := (List.range (arity - values.size)).map fun i => s!"a{i}"
    s!"(({String.intercalate ", " extra}) => {build (values ++ extra.toArray)})"
  else
    let head := build (values.extract 0 arity)
    s!"{head}({String.intercalate ", " (values.extract arity values.size).toList})"

/--
One piece of a template literal. Nested appends are flattened, so a chain of them reads
as one string with holes rather than as a tower of nested templates.
-/
def templatePiece (value : String) : String :=
  if value.length >= 2 && value.front == '`' && value.back == '`' then
    (value.drop 1).dropEnd 1 |>.toString
  else if value.length >= 2 && value.front == '"' && value.back == '"' then
    -- A string literal becomes literal text. The escapes `litToTs` writes are all legal
    -- inside a template too; only the backtick and a `${` opening have to be added.
    ((value.drop 1).dropEnd 1).toString.foldl (fun acc c =>
      if c == '`' then acc ++ "\\`" else if c == '$' then acc ++ "\\$" else acc ++ c.toString) ""
  else "${" ++ value ++ "}"

/-- `String.append`, as a template literal, which is what Biome insists on. -/
def appendTemplate (values : Array String) : String :=
  "`" ++ templatePiece (values[0]!) ++ templatePiece (values[1]!) ++ "`"

/-- A call to a named constant: a shim, a constructor, or another compiled declaration. -/
def constToTs (declName : Name) (args : Array (Arg .pure)) : M String := do
  let signature ← calleeSignature declName
  let mask := signature.map (·.1)
  let mut values := #[]
  for i in [0:args.size] do
    let isErased := match mask with
      | some m => (m[i]?).getD false
      | none => match args[i]! with | .type .. => true | _ => false
    unless isErased do
      let target := match signature with
        | some (_, types) => (types[values.size]?).getD erasedName
        | none => erasedName
      values := values.push (← argToTsAt args[i]! target)
  if declName == ``String.append then
    return applyArgs values 2 appendTemplate
  if let some shim := shimTable[declName]? then
    return applyArgs values shim.arity (fun vs => applyTemplate shim.tmpl vs)
  -- Lambda-lifted declarations have no kernel constant at all, so ask the environment.
  if let some (.ctorInfo _) := (← getEnv).find? declName then
    return ← ctorToTs declName args
  match mask with
  | none =>
      -- An `@[extern]` primitive with no shim: recorded, and the build will fail.
      recordMissing declName
      return s!"{tsIdent declName}({String.intercalate ", " values.toList})"
  | some m =>
      requestDecl declName
      let fn ← claimIdent "value" declName
      let arity := (m.filter (· == false)).size
      -- A constant mentioned with no arguments at all is the function itself.
      if values.isEmpty && arity > 0 then return fn
      return applyArgs values arity fun vs => s!"{fn}({String.intercalate ", " vs.toList})"

/--
The TypeScript type of a `let` right-hand side as the emitted expression actually has
it, which is not always the type Lean recorded: a saturated call to a declaration whose
own signature was erased returns `unknown` where Lean knows better.
-/
def letValueType (v : LetValue .pure) : M (Option String) := do
  match v with
  | .const declName _ args _ =>
      if (shimTable[declName]?).isSome then return none
      match (← getDeclAt? declName .mono) with
      | some d =>
          let supplied := (args.size == d.params.size)
          if supplied then return some (← tsType (resultType d.type d.params.size)) else return none
      | none => return none
  | _ => return none

/-- The right-hand side of one LCNF `let`. -/
def letValueToTs (v : LetValue .pure) : M String := do
  match v with
  | .lit l => litToTs l
  | .erased => return "undefined"
  | .proj typeName idx struct _ =>
      requestType typeName
      let s ← lookupFVar struct
      match ← indCtors typeName with
      | [c] =>
          let fields ← ctorFields c
          match fields[idx]? with
          | some f => return s!"{s}.{f}"
          | none => return s!"{s}.f{idx}"
      | _ => return s!"{s}.f{idx}"
  | .const declName _ args _ => constToTs declName args
  | .fvar fv args =>
      let f ← lookupFVar fv
      if args.isEmpty then return f
      let values ← args.mapM argToTs
      return s!"{f}({String.intercalate ", " values.toList})"
  | _ =>
      recordMissing `impure.LetValue
      return "undefined"

end Mythroads.Compile
