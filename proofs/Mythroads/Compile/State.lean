import Lean
import Lean.Compiler.LCNF
import Mythroads.Compile.Names

/-!
# The compiler's state

One `StateRefT` over `CoreM` carries everything the translation accumulates: the
work queues for declarations and types, the finished text of each, the local naming
context of the declaration being translated, and the list of primitives that were
reached without a shim.

Two details are worth reading twice.

**Occurrence counts drive readability.** LCNF is A-normal form: every subterm is its
own `let`. Emitting one `const` per `let` is faithful and unreadable, so each variable
is counted first and the ones used at most once are inlined at their use site. The
pure phase is side-effect free, so this only ever moves a computation later, never
earlier, and never changes a result.

**Names are chosen once per declaration.** `Ctx` is reset for each declaration, and
`freshIdent` guarantees that the identifiers inside one function never collide, which
is what lets join points and lambdas be emitted as ordinary local `const`s.
-/

namespace Mythroads.Compile

open Lean Lean.Compiler.LCNF

/-- The naming context of the declaration currently being translated. -/
structure Ctx where
  /-- Free variable to the TypeScript expression that stands for it. -/
  names : Std.HashMap FVarId String := {}
  /-- Identifiers already taken inside this declaration. -/
  used : Std.HashSet String := {}
  /-- Identifiers bound by a `const`, whose narrowing TypeScript keeps inside closures. -/
  consts : Std.HashSet String := {}
  /-- The TypeScript type of each bound variable, used to decide where a cast is needed. -/
  types : Std.HashMap FVarId String := {}
  deriving Inhabited

/-- Everything the translation accumulates. -/
structure St where
  /-- How often each free variable of the current declaration is used. -/
  counts : Std.HashMap FVarId Nat := {}
  /-- Declarations already translated. -/
  done : NameSet := {}
  /-- Declarations discovered but not yet translated. -/
  queue : Array Name := #[]
  /-- Inductives already translated. -/
  types : NameSet := {}
  /-- Inductives discovered but not yet translated. -/
  typeQueue : Array Name := #[]
  /-- Finished function text, in emission order. -/
  fns : Array String := #[]
  /-- Finished type text, in emission order. -/
  tys : Array String := #[]
  /--
  Identifiers no local may take. The compiler runs twice: the first pass discovers every
  top-level name it will emit, and the second forbids any local from shadowing one, so a
  local `const` can never capture a call to a function of the same name.
  -/
  reserved : Std.HashSet String := {}
  /-- The TypeScript result type of the declaration being translated. -/
  resultTy : String := ""
  /-- The declaration being translated, named in diagnostics. -/
  current : Name := Name.anonymous
  /-- Primitives reached with no shim, and where they were reached from. -/
  missing : Array (Name × Name) := #[]
  /-- TypeScript identifier to the Lean name that claimed it, for collision detection. -/
  claimed : Std.HashMap String Name := {}
  /-- Identifiers claimed by two different Lean names. -/
  collisions : Array (String × Name × Name) := #[]
  ctx : Ctx := {}
  deriving Inhabited

/-- The compiler monad: mutable translation state over Lean's `CoreM`. -/
abbrev M := StateRefT St CoreM

/-- An identifier that is free inside the declaration being translated. -/
def freshIdent (base : String) : M String := do
  let base := if base.isEmpty then "x" else base
  let mut candidate := base
  let mut i := 0
  while (← get).ctx.used.contains candidate || (← get).reserved.contains candidate do
    i := i + 1
    candidate := s!"{base}_{i}"
  modify fun s => { s with ctx := { s.ctx with used := s.ctx.used.insert candidate } }
  return candidate

/-- Give `fv` a fresh identifier derived from its Lean binder name. -/
def bindFVar (fv : FVarId) (binder : Name) : M String := do
  let id ← freshIdent (localIdent binder)
  modify fun s => { s with ctx := { s.ctx with names := s.ctx.names.insert fv id } }
  return id

/-- Remember the TypeScript type of a bound variable. -/
def noteType (fv : FVarId) (ty : String) : M Unit :=
  modify fun s => { s with ctx := { s.ctx with types := s.ctx.types.insert fv ty } }

/-- The TypeScript type of a bound variable, if one was recorded. -/
def fvarType (fv : FVarId) : M (Option String) := return (← get).ctx.types[fv]?

/--
An expression whose type mentions `unknown` cannot be used where a concrete type is
expected, which is the whole point of not writing `any`. This is the cast that says what
the value is, justified by the Lean type that monomorphisation erased. It also goes the
other way for a function argument, which is contravariant in its own parameters.
-/
def castTo (expression source target : String) : String :=
  if source == target then expression
  else if occursAsIdent source "unknown" && !occursAsIdent target "unknown" then
    s!"({expression} as {target})"
  else if occursAsIdent target "unknown" && (source.splitOn "=>").length > 1 then
    -- A function is contravariant in its arguments, so a concrete one does not fit a
    -- position that expects an erased one either; the cast has to go this way too.
    s!"({expression} as {target})"
  else expression

/-- Record that `id` was introduced by a `const`, so its narrowing survives a closure. -/
def markConst (id : String) : M Unit :=
  modify fun s => { s with ctx := { s.ctx with consts := s.ctx.consts.insert id } }

/-- Was `expression` introduced by a `const` in this declaration? -/
def isConstIdent (expression : String) : M Bool :=
  return (← get).ctx.consts.contains expression

/-- Record `fv` as an alias for an already-built expression instead of a `const`. -/
def bindExpr (fv : FVarId) (e : String) : M Unit :=
  modify fun s => { s with ctx := { s.ctx with names := s.ctx.names.insert fv e } }

/-- How often `fv` is used in the declaration being translated. -/
def useCount (fv : FVarId) : M Nat := return ((← get).counts.getD fv 0)

/-- The TypeScript expression standing for `fv`. -/
def lookupFVar (fv : FVarId) : M String := do
  match (← get).ctx.names[fv]? with
  | some s => return s
  | none => return s!"undefined /* unbound {fv.name} */"

/--
Claim a TypeScript identifier for a Lean name, recording any collision.

`kind` separates the type namespace from the value namespace, because TypeScript keeps
them apart: a `type State` and a `function State` can coexist, two functions cannot.
-/
def claimIdent (kind : String) (n : Name) : M String := do
  let id := tsIdent n
  let key := kind ++ ":" ++ id
  match (← get).claimed[key]? with
  | some other =>
      unless other == n do
        modify fun s => { s with collisions := s.collisions.push (id, other, n) }
  | none => modify fun s => { s with claimed := s.claimed.insert key n }
  return id

/-- Schedule a declaration for translation. -/
def requestDecl (n : Name) : M Unit := do
  unless (← get).done.contains n || (← get).queue.contains n do
    modify fun s => { s with queue := s.queue.push n }

/-- Schedule an inductive for translation. -/
def requestType (n : Name) : M Unit := do
  unless (← get).types.contains n || (← get).typeQueue.contains n do
    modify fun s => { s with typeQueue := s.typeQueue.push n }

/-- Record a primitive that has no shim. The driver turns this into a build failure. -/
def recordMissing (n : Name) : M Unit := do
  let entry := (n, (← get).current)
  modify fun s => { s with missing := if s.missing.any (·.1 == n) then s.missing else s.missing.push entry }

/-! ## Occurrence counting -/

/-- Count one more use of `fv`. -/
def bumpFV (m : Std.HashMap FVarId Nat) (fv : FVarId) : Std.HashMap FVarId Nat :=
  m.insert fv ((m.getD fv 0) + 1)

/-- Count the free variables an argument list mentions. -/
def countArgs (m : Std.HashMap FVarId Nat) (as : Array (Arg .pure)) : Std.HashMap FVarId Nat :=
  as.foldl (fun m a => match a with | .fvar fv => bumpFV m fv | _ => m) m

/-- Count the free variables one `let` right-hand side mentions. -/
def countLetValue (m : Std.HashMap FVarId Nat) (v : LetValue .pure) : Std.HashMap FVarId Nat :=
  match v with
  | .proj _ _ fv _ => bumpFV m fv
  | .const _ _ as _ => countArgs m as
  | .fvar fv as => countArgs (bumpFV m fv) as
  | _ => m

mutual

/-- Count every use of every free variable in a block of LCNF code. -/
partial def countCode (m : Std.HashMap FVarId Nat) (c : Code .pure) : Std.HashMap FVarId Nat :=
  match c with
  | .let d k => countCode (countLetValue m d.value) k
  | .fun d k _ | .jp d k => countCode (countFun m d) k
  | .jmp fv as => countArgs (bumpFV m fv) as
  | .cases c =>
      let .mk _ _ discr alts := c
      alts.foldl (fun m alt => match alt with
        | .alt _ _ code _ => countCode m code
        | .default code => countCode m code) (bumpFV m discr)
  | .return fv => bumpFV m fv
  | _ => m

/-- Count every use inside a lambda or join point. -/
partial def countFun (m : Std.HashMap FVarId Nat) (d : FunDecl .pure) : Std.HashMap FVarId Nat :=
  countCode m d.value

end

end Mythroads.Compile
