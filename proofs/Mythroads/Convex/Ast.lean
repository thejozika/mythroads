import Mythroads.Convex.Doc
import Mythroads.Convex.Table

namespace Mythroads.Convex.TypeScript

/-! # The generated TypeScript syntax tree

The target-language syntax tree every emitter under `Mythroads/Backend/` builds. It is separated
from its printer (`Mythroads/Convex/TypeScript.lean`) only so that neither file outgrows the
repository's three-hundred-line limit; both live in the `Mythroads.Convex.TypeScript` namespace and
importing the printer brings the tree with it.

Two design points worth stating here. `TsType.id` and `TsType.doc` take a `Table` rather than a
string, so a generated `Id<'players'>` cannot name a table that is not in the schema. And
`TsType.object` carries a per-field `Bool` marking an optional property: `name?: T` is not the same
type as `name: T | undefined`, and Convex can only produce the former.
-/

/-- A TypeScript type expression. -/
inductive TsType where
  /-- No annotation at all: TypeScript infers the result. The column builders want this, because
  their result is a wide object literal nobody should have to restate as a type. -/
  | inferred
  /-- The `void` type. -/
  | void
  /-- The `boolean` type. -/
  | boolean
  /-- The `number` type (Convex float64). -/
  | number
  /-- The `string` type. -/
  | string
  /-- A single-quoted string literal type. -/
  | literalString (value : String)
  /-- A named type referenced verbatim, for types this tree cannot yet describe. -/
  | named (name : String)
  /-- `Id<'table'>` from the Convex data model. -/
  | id (table : Table)
  /-- `Doc<'table'>`, a whole stored document including `_id` and `_creationTime`. -/
  | doc (table : Table)
  /-- `Omit<T, 'a' | 'b'>`, used by the read projections that strip private fields. -/
  | omit (inner : TsType) (fields : List String)
  /-- An object type. The `Bool` marks an optional field, rendered `name?: T`. -/
  | object (fields : List (String × TsType × Bool))
  /-- An array type, rendered `T[]`. -/
  | array (inner : TsType)
  /-- A union, rendered `A | B`. -/
  | union (members : List TsType)
  /-- `Promise<T>`. -/
  | promise (inner : TsType)
  deriving Repr

/-- A named, typed parameter of a generated function or arrow. -/
structure Parameter where
  /-- The binder text; may be a destructuring pattern such as `{ playerId }`. -/
  name : String
  /-- The parameter's declared type. -/
  type : TsType
  deriving Repr

/-- A TypeScript expression represented as typed Lean data before code generation. -/
inductive Expr where
  /-- A bare identifier. -/
  | identifier (name : String)
  /-- A boolean literal. -/
  | boolean (value : Bool)
  /-- A single-quoted string literal. -/
  | string (value : String)
  /-- A non-negative numeric literal. -/
  | number (value : Nat)
  /-- The `null` literal. -/
  | null
  /-- The `undefined` literal. -/
  | undefined
  /-- Member access, `target.name`. -/
  | property (target : Expr) (name : String)
  /-- Optional member access, `target?.name`. -/
  | optionalProperty (target : Expr) (name : String)
  /-- Computed member access, `target[index]`. -/
  | index (target index : Expr)
  /-- A call, `callee(arguments…)`. -/
  | call (callee : Expr) (arguments : List Expr)
  /-- A constructor call, `new Constructor(arguments…)`. -/
  | new (constructor : String) (arguments : List Expr)
  /-- `await value`. -/
  | await (value : Expr)
  /-- A parenthesised prefix operator application. -/
  | prefix (operator : String) (value : Expr)
  /-- A parenthesised binary operator application. -/
  | binary (left : Expr) (operator : String) (right : Expr)
  /-- A parenthesised conditional expression. -/
  | conditional (condition whenTrue whenFalse : Expr)
  /-- An expression-bodied arrow function. -/
  | arrow (parameters : List String) (body : Expr)
  /-- An object literal. A field named `...` is rendered as a spread of its value, which is how
  a generated row is assembled from a shared column block plus the one column that row owns. -/
  | object (fields : List (String × Expr))
  /-- A shorthand object literal, `{ a, b }`, where each property takes the value of the
  identically named binding. -/
  | shorthand (names : List String)
  /-- An array literal. -/
  | array (values : List Expr)
  /-- A spread element, `...value`. -/
  | spread (value : Expr)
  /-- `value as const`. -/
  | asConst (value : Expr)
  /-- `value as T`. The engine speaks in plain strings, so a row identifier crossing back into
  Convex has to be re-branded; this is the only place that happens. -/
  | cast (value : Expr) (type : TsType)
  deriving Repr

/-- A state-changing or control-flow statement in a generated TypeScript function body. -/
inductive Statement where
  /-- `const name = value`. -/
  | constDecl (name : String) (value : Expr)
  /-- `const name: T = value`. -/
  | constDeclTyped (name : String) (type : TsType) (value : Expr)
  /-- `let name = value`. -/
  | letDecl (name : String) (value : Expr)
  /-- `const { omitted…, ...rest } = source`, used to strip private document fields. -/
  | constObjectRest (omitted : List String) (rest : String) (source : Expr)
  /-- `target = value`. -/
  | assign (target value : Expr)
  /-- An expression statement. -/
  | expression (value : Expr)
  /-- `void value`, for deliberately discarded promises. -/
  | voidValue (value : Expr)
  /-- `if (condition) { … }`. -/
  | ifThen (condition : Expr) (body : List Statement)
  /-- `if (condition) { … } else { … }`. -/
  | ifElse (condition : Expr) (whenTrue whenFalse : List Statement)
  /-- `throw error`. -/
  | throw (error : Expr)
  /-- `return value`. -/
  | return (value : Expr)
  /-- A bare `return`. -/
  | returnVoid
  /-- `break`. -/
  | break
  /-- A `switch` over string-literal cases, each in its own block. -/
  | switch (value : Expr) (cases : List (String × List Statement))
  /-- `for (const binding of values) { … }`. -/
  | forOf (binding : String) (values : Expr) (body : List Statement)
  /-- `while (condition) { … }`. -/
  | whileDo (condition : Expr) (body : List Statement)
  deriving Repr

/-- A complete generated TypeScript function: visibility, parameters, result type, and body. -/
structure Function where
  /-- Whether the declaration carries `export`. -/
  isExported : Bool := true
  /-- Whether the declaration carries `async`. -/
  isAsync : Bool := true
  /-- The function name. -/
  name : String
  /-- The declared parameters. -/
  parameters : List Parameter
  /-- The declared result type. -/
  returns : TsType
  /-- The statements of the body. -/
  body : List Statement
  deriving Repr


end Mythroads.Convex.TypeScript
