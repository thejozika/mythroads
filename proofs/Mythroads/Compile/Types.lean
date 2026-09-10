import Mythroads.Compile.State

/-!
# Lean types as TypeScript types

Every emitted function carries a full signature, taken from the type LCNF itself
records for the monomorphised declaration. That is what makes the output typecheck
under the repository's `strict` TypeScript configuration instead of drifting into
implicit `any`.

## The four shapes

| Lean | TypeScript |
|---|---|
| `Nat`, `Int`, `UInt32`, `Char` | `number` |
| `String` | `string`, `Bool` → `boolean` |
| `List α`, `Array α` | `α[]` |
| a structure (one constructor) | `{ field: T; … }` |
| an inductive (many constructors) | `{ _: "ctor"; field: T } \| …` |

Polymorphic inductives keep their parameters: `Option<A>`, `Except<A, B>`,
`Prod<A, B>`. The engine's result type is therefore
`Except<Error, Prod<State, Effect[]>>`, which reads exactly like the Lean `Outcome`.

## Erasure is `unknown`, and casts are explicit

Monomorphisation erases the type arguments of the handful of generic helpers that
survive specialisation (`List.get?Internal._redArg` and friends), leaving LCNF's
`lcAny`. Those become `unknown`: every concrete value may be passed *in*, and nothing
may be done with such a value *out* without saying what it is. `Mythroads.Compile.Expr`
therefore emits an explicit `as` cast at exactly the points where an erased value flows
back into typed code — an argument, a constructor field, a `return`. Each cast is
justified by the Lean type that LCNF erased, and there is no `any` anywhere.
-/

namespace Mythroads.Compile

open Lean Lean.Compiler.LCNF

/-- How a Lean type is represented at runtime, which decides how it is built and matched. -/
inductive Rep where
  /-- `Bool`, a JavaScript boolean. -/
  | bool
  /-- `Nat`, a non-negative `number`. -/
  | nat
  /-- `Int`, a `number`. -/
  | int
  /-- `String`. -/
  | str
  /-- `List α`, a JavaScript array. -/
  | list
  /-- A many-constructor inductive: `{ _: "ctor", … }`. -/
  | tagged
  /-- A one-constructor inductive: a plain object of its fields. -/
  | plain
  deriving BEq, Inhabited

/-- The representation of a type constructor, before the single-constructor refinement. -/
def repOf (typeName : Name) : Rep :=
  match typeName with
  | ``Bool => .bool
  | ``Nat => .nat
  | ``Int => .int
  | ``String => .str
  | ``List => .list
  | _ => .tagged

/-- The constructors of an inductive, or `[]` for anything else. -/
def indCtors (typeName : Name) : CoreM (List Name) := do
  let .inductInfo iv ← getConstInfo typeName | return []
  return iv.ctors

/-- The representation of a type, refined to `.plain` for single-constructor inductives. -/
def repOfM (typeName : Name) : CoreM Rep := do
  match repOf typeName with
  | .tagged => return if (← indCtors typeName).length == 1 then .plain else .tagged
  | r => return r

/-- The field names of a constructor, taken from its binder names after the type parameters. -/
def ctorFields (ctorName : Name) : CoreM (Array String) := do
  let .ctorInfo cv ← getConstInfo ctorName | return #[]
  let rec go (e : Expr) (i : Nat) (acc : Array String) : Array String :=
    match e with
    | .forallE bn _ body _ =>
        if i < cv.numParams then go body (i + 1) acc
        else
          let nm := bn.eraseMacroScopes.toString
          let usable := nm.length > 0 && nm.front.isAlpha && nm.all fun c => c.isAlphanum || c == '_'
          go body (i + 1) (acc.push (if usable then nm else s!"f{acc.size}"))
    | _ => acc
  return go cv.type 0 #[]

/-- The name standing for type parameter `i` while a constructor type is being walked. -/
def tyVarSentinel (i : Nat) : Name := Name.mkNum `_mythroadsTyVar i

/-- The TypeScript name of type parameter `i`: `A`, `B`, `C`, … -/
def tyVarName (i : Nat) : String :=
  let letters := "ABCDEFGH"
  match letters.toList[i]? with
  | some c => c.toString
  | none => s!"T{i}"

/-- A dependent field's type mentions an earlier field; it is erased rather than modelled. -/
def dependentSentinel : Name := `_mythroadsDependent

/--
The TypeScript type standing for one monomorphisation erased: `unknown`, the type that
accepts every value and promises nothing. `List.get?Internal._redArg` becomes
`(xs: unknown[], index: number) => Option<unknown>`, which is exactly what is known about
it, and `Mythroads.Compile.Expr` writes an explicit cast wherever such a value is handed
back to code that does know its type. This is why `any` — which would silently disable
checking in both directions — is never needed.
-/
def erasedName : String := "unknown"

mutual

/-- The TypeScript type of a Lean type expression, in the given polarity. -/
partial def tsType (e : Expr) : M String := do
  match e.headBeta with
  | .const n _ => tsTypeOf n #[]
  | .app .. =>
      let e := e.headBeta
      match e.getAppFn with
      | .const n _ => tsTypeOf n e.getAppArgs
      | _ => return erasedName
  | .forallE .. => tsArrow e.headBeta #[]
  | _ => return erasedName

/--
A function type, emitted uncurried: LCNF closures take all their arguments at once, and
so do the eta-wrappers this compiler builds for partial applications.
-/
partial def tsArrow (e : Expr) (acc : Array String) : M String := do
  match e with
  | .forallE _ d b _ =>
      if (← isTypeLike d) then tsArrow b acc
      else tsArrow b (acc.push (← tsType d))
  | _ =>
      let result ← tsType e
      if acc.isEmpty then return result
      let params := (acc.toList.zipIdx.map fun (ty, i) => s!"a{i}: {ty}")
      return s!"(({String.intercalate ", " params}) => {result})"

/-- The TypeScript type of a type constructor applied to arguments. -/
partial def tsTypeOf (n : Name) (args : Array Expr) : M String := do
  if let .num p i := n then
    if p == `_mythroadsTyVar then return tyVarName i
  match n with
  | ``Nat | ``Int | ``UInt8 | ``UInt16 | ``UInt32 | ``UInt64 | ``USize | ``Char | ``Fin =>
      return "number"
  | ``String => return "string"
  | ``Bool | ``Decidable => return "boolean"
  | ``List | ``Array =>
      match args[0]? with
      | some a => return s!"{← tsType a}[]"
      | none => return s!"{erasedName}[]"
  | _ =>
      match (← getEnv).find? n with
      | some (.inductInfo iv) =>
          requestType n
          let id := tsIdent n
          if iv.numParams == 0 then return id
          let mut parts := #[]
          for i in [0:iv.numParams] do
            match args[i]? with
            | some a => parts := parts.push (← tsType a)
            | none => parts := parts.push erasedName
          return s!"{id}<{String.intercalate ", " parts.toList}>"
      | some (.defnInfo dv) =>
          -- `abbrev NodeId := Nat` and friends: unfold the synonym rather than name it.
          tsType (dv.value.beta args)
      | _ => return erasedName

/-- Is this expression a type or a type former, rather than a value? -/
partial def isTypeLike (e : Expr) : M Bool := do
  match e with
  | .sort _ => return true
  | .forallE _ _ b _ => isTypeLike b
  | _ => return false

end

/--
Walk the type of a constructor, collecting the TypeScript type of each field. The
inductive's own parameters are replaced by symbolic type variables, a field whose type
is a proposition is a proof and is emitted as `undefined`, and a later field that
mentions an earlier one is erased rather than modelled.
-/
partial def ctorFieldTypesGo (numParams : Nat) (e : Expr) (i : Nat) (acc : Array String) :
    M (Array String) := do
  match e with
  | .forallE _ d body _ =>
      if i < numParams then
        ctorFieldTypesGo numParams (body.instantiate1 (mkConst (tyVarSentinel i))) (i + 1) acc
      else
        -- The sentinels are not real constants, so type inference can fail here; a field
        -- whose proof-ness cannot be decided is compiled as a value rather than erased.
        let isProof ← try (Meta.isProp d).run' catch _ => pure false
        let ty ← if isProof then pure "undefined" else tsType d
        ctorFieldTypesGo numParams (body.instantiate1 (mkConst dependentSentinel)) (i + 1)
          (acc.push ty)
  | _ => return acc

/-- The declared types of a constructor's fields, with type parameters left symbolic. -/
def ctorFieldTypes (ctorName : Name) : M (Array String) := do
  let .ctorInfo cv ← getConstInfo ctorName | return #[]
  ctorFieldTypesGo cv.numParams cv.type 0 #[]

/-- Drop `n` argument types from an LCNF arrow type, leaving the result type. -/
partial def resultType (t : Expr) (n : Nat) : Expr :=
  match n, t with
  | 0, _ => t
  | n + 1, .forallE _ _ b _ => resultType b n
  | _, _ => t

/-- Does this rendered type still mention one of the symbolic type parameters? -/
def mentionsTypeVariable (ty : String) : Bool :=
  (List.range 8).any fun i => occursAsIdent ty (tyVarName i)

/-- Emit the TypeScript type of one inductive, unless it has a primitive representation. -/
def emitType (n : Name) : M Unit := do
  if (← get).types.contains n then return
  modify fun s => { s with types := s.types.insert n }
  match repOf n with
  | .bool | .nat | .int | .str | .list => return
  | _ =>
    let .inductInfo iv ← getConstInfo n | return
    if iv.ctors.isEmpty then return
    let id ← claimIdent "type" n
    let single := iv.ctors.length == 1
    let mut variants := #[]
    for c in iv.ctors do
      let names ← ctorFields c
      let types ← ctorFieldTypes c
      let mut parts := if single then #[] else #[s!"_: \"{ctorTag c}\""]
      for i in [0:names.size] do
        parts := parts.push s!"{names[i]!}: {(types[i]?).getD erasedName}"
      variants := variants.push <|
        if parts.isEmpty then "Record<string, never>"
        else "{ " ++ String.intercalate "; " parts.toList ++ " }"
    -- A parameter no constructor mentions — `String.Pos` is indexed by its string — keeps
    -- its position, because call sites are positional, but is named `_A` so that Biome does
    -- not read it as an unused declaration.
    let variantText := String.intercalate " " variants.toList
    let names := (List.range iv.numParams).map fun i =>
      if occursAsIdent variantText (tyVarName i) then tyVarName i else "_" ++ tyVarName i
    let params := if iv.numParams == 0 then "" else "<" ++ String.intercalate ", " names ++ ">"
    let txt := s!"/** Lean `{n}`. */\nexport type {id}{params} =\n  " ++
      String.intercalate "\n  | " variants.toList ++ ";\n"
    modify fun s => { s with tys := s.tys.push txt }

end Mythroads.Compile
