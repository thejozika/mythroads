import Mythroads.Convex.Module
import Mythroads.Convex.Query
import Mythroads.Engine

namespace Mythroads.Backend.Aggregate

/-!
# Shared vocabulary for the aggregate boundary

The five modules beside this one emit `convex/generated/aggregate/**`, the interpreter that
turns one wire event into one `Mythroads.Engine.step` and writes what it returns. They all
speak the same three dialects, so those live here rather than three times over.

* **TypeScript shorthand** — `id`, `prop`, `call`, `eq`: the `Expr` constructors are precise but
  verbose, and an emitter reads better when a member access looks like one.
* **The compiled engine's value shapes** — a Lean inductive becomes `{ _: "tag", … }` and an
  `Option` becomes `{ _: "none" }` or `{ _: "some", val }`. `ctor`, `wrapped` and `absent` build
  those, and `isTag` reads one back, so no emitter spells the representation contract out.
* **The imports** — every generated file in this directory imports from the same handful of
  modules, and `engineImport` and friends keep those specifiers in one place, since a relative
  path is exactly the kind of thing nothing else can check.

Nothing here decides anything about the game. It is the punctuation of five emitters.
-/

open Mythroads.Convex Mythroads.Convex.TypeScript

/-! ## TypeScript shorthand -/

/-- A bare identifier. -/
def id (name : String) : Expr := .identifier name

/-- Member access, `target.name`. -/
def prop (target : Expr) (name : String) : Expr := .property target name

/-- A call of an arbitrary callee. -/
def call (callee : Expr) (arguments : List Expr := []) : Expr := .call callee arguments

/-- A method call, `target.name(arguments…)`. -/
def method (target : Expr) (name : String) (arguments : List Expr := []) : Expr :=
  .call (.property target name) arguments

/-- Strict equality. -/
def eq (left right : Expr) : Expr := .binary left "===" right

/-- Strict inequality. -/
def ne (left right : Expr) : Expr := .binary left "!==" right

/-- Nullish coalescing, which is how an absent Convex column supplies its default. -/
def orElse (value fallback : Expr) : Expr := .binary value "??" fallback

/-- Logical negation. -/
def not' (value : Expr) : Expr := .prefix "!" value

/-- `throw new ConvexError(message)`, the single refusal shape of the whole boundary. -/
def refuse (message : String) : Statement := .throw (.new "ConvexError" [.string message])

/-- `Date.now()`. Only row timestamps read the clock; no rule ever does. -/
def now : Expr := call (prop (id "Date") "now")

/-- `ctx`. -/
def ctx : Expr := id "ctx"

/-- `ctx.db`. -/
def db : Expr := prop ctx "db"

/-! ## The compiled engine's value shapes -/

/-- A compiled Lean constructor: `{ _: "tag", field: … }`. -/
def ctor (tag : String) (fields : List (String × Expr) := []) : Expr :=
  .object (("_", .string tag) :: fields)

/-- The constructor tag of a compiled inductive value. -/
def tagOf (value : Expr) : Expr := prop value "_"

/-- Is this compiled value the named constructor? -/
def isTag (value : Expr) (tag : String) : Expr := eq (tagOf value) (.string tag)

/-- `{ _: "some", val }`. -/
def wrapped (value : Expr) : Expr := ctor "some" [("val", value)]

/-- `{ _: "none" }`. -/
def absent : Expr := ctor "none"

/-- The payload of a compiled `Option` that is known to be `some`. -/
def unwrapped (value : Expr) : Expr := prop value "val"

/-- An engine type, referenced by the name the compiler gave it. -/
def engineType (name : String) : TsType := .named name

/-! ## Imports

Every module in this directory reaches the same five places. Naming the specifiers once means a
wrong relative path is a Lean edit rather than a silent runtime failure.
-/

/-- Named bindings from the compiled engine. -/
def engineImport (bindings : List Binding) : Import :=
  { source := "../../../shared/engine.system", bindings }

/-- Named bindings from the generated Convex data model. -/
def dataModelImport (bindings : List Binding) : Import :=
  { source := "../../_generated/dataModel", bindings }

/-- The mutation context type. -/
def serverImport : Import :=
  { source := "../../_generated/server", bindings := [{ name := "MutationCtx", isType := true }] }

/-- The wire event union. -/
def validatorsImport (bindings : List Binding) : Import :=
  { source := "../../events/validators", bindings }

/-- `ConvexError`, which every refusal at this boundary raises. -/
def convexErrorImport : Import :=
  { source := "convex/values", bindings := [{ name := "ConvexError" }] }

/-- A type-only binding. -/
def typeBinding (name : String) : Binding := { name, isType := true }

/-- A value binding. -/
def valueBinding (name : String) : Binding := { name }

end Mythroads.Backend.Aggregate
