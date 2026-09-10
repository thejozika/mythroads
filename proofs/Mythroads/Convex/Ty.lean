import Mythroads.Convex.TypeScript

namespace Mythroads.Convex

/-! # One value universe, two denotations

A Convex value shape has to be written twice in the emitted TypeScript: once as a runtime validator
(`v.object({ … })`) and once as a static type (`{ … }`). Before this module there were *three*
sources for that pair, and they could disagree:

* `Convex/Schema.lean`'s `Validator`, printed to a validator string only;
* `Convex/TypeScript.lean`'s `TsType`, printed to a type only;
* `Convex.ValueType`, a third small universe with a `custom (validator typeName : String)`
  constructor whose two halves were unrelated strings a human had to keep in step.

`Ty` is the single universe. `Ty.validator` folds it to a validator expression and `Ty.tsType`
folds the *same* value to a TypeScript type, so the two can no longer drift.

The fold is where the Convex-specific subtleties live:

* `.optional inner` inside an object becomes an **optional field**, `name?: T`, not
  `name: T | undefined`. Convex does not transport `undefined` as a value, so the old rendering
  described a shape the server cannot produce. Outside an object there is no optional-field syntax
  to use, so `T | undefined` remains.
* `.id table` becomes `Id<'table'>`, which is why `TsType.id` takes a `Table` rather than a string.
* `.int64` is `bigint` and `.number` is float64's `number`.
* `.external` is the deliberate escape hatch for a validator defined in another generated module
  (`gameEventValidator`), where the emitter must reference a binding rather than inline a shape. It
  keeps the validator and type names together in one constructor, which is the one property the old
  `ValueType.custom` had and the reason it is retained in this form.
-/

/-- A Convex value shape: the single source for both the runtime validator and the static type. -/
inductive Ty where
  /-- `v.any()`. Reserved for the legacy `gameEvents` migration arm. -/
  | any
  /-- `v.null()`. -/
  | null
  /-- `v.boolean()`. -/
  | boolean
  /-- `v.number()`, a float64. -/
  | number
  /-- `v.int64()`, a `bigint`. -/
  | int64
  /-- `v.string()`. -/
  | string
  /-- `v.id('table')`. -/
  | id (table : Table)
  /-- A string literal, `v.literal('value')`. -/
  | literalString (value : String)
  /-- A numeric literal, `v.literal(value)`. -/
  | literalNumber (value : Int)
  /-- `v.optional(inner)`; an optional field when it appears directly in an object. -/
  | optional (inner : Ty)
  /-- `v.array(inner)`. -/
  | array (inner : Ty)
  /-- `v.object({ … })`. -/
  | obj (fields : List (String × Ty))
  /-- `v.union(…)`. -/
  | union (members : List Ty)
  /-- A whole stored document: `schema.doc('table')` and `Doc<'table'>`. Distinct from `.obj` of the
  table's fields, which would omit the system fields Convex adds. -/
  | document (table : Table)
  /-- A validator exported by another generated module, with the type it infers. -/
  | external (validator typeName : String)
  deriving Repr

namespace Ty

-- Both folds below are structural but declared `partial` because they recurse under `List.map`;
-- Lean requires the result types to be inhabited for that, so the two neutral values are named.

/-- Witness that a TypeScript expression type is inhabited. -/
instance : Inhabited TypeScript.Expr := ⟨.null⟩

/-- Witness that a TypeScript type expression is inhabited. -/
instance : Inhabited TypeScript.TsType := ⟨.void⟩

/-- A union of string literals, the shape every enumerated field in the schema uses. -/
def literals (values : List String) : Ty := .union (values.map .literalString)

/-- The runtime validator expression for a value shape. -/
partial def validator : Ty → TypeScript.Expr
  | .any => .call (.property (.identifier "v") "any") []
  | .null => .call (.property (.identifier "v") "null") []
  | .boolean => .call (.property (.identifier "v") "boolean") []
  | .number => .call (.property (.identifier "v") "number") []
  | .int64 => .call (.property (.identifier "v") "int64") []
  | .string => .call (.property (.identifier "v") "string") []
  | .id table => .call (.property (.identifier "v") "id") [.string table.name]
  | .literalString value => .call (.property (.identifier "v") "literal") [.string value]
  | .literalNumber value =>
      .call (.property (.identifier "v") "literal")
        [if value < 0 then .prefix "-" (.number value.natAbs) else .number value.toNat]
  | .optional inner => .call (.property (.identifier "v") "optional") [validator inner]
  | .array inner => .call (.property (.identifier "v") "array") [validator inner]
  | .obj fields =>
      .call (.property (.identifier "v") "object")
        [.object (fields.map fun (name, type) => (name, validator type))]
  | .union members => .call (.property (.identifier "v") "union") (members.map validator)
  | .document table => .call (.property (.identifier "schema") "doc") [.string table.name]
  | .external name _ => .identifier name

/-- The static TypeScript type for a value shape. Object fields whose type is `.optional` become
optional properties, which is the only faithful rendering of a Convex optional. -/
partial def tsType : Ty → TypeScript.TsType
  | .any => .named "unknown"
  | .null => .named "null"
  | .boolean => .boolean
  | .number => .number
  | .int64 => .named "bigint"
  | .string => .string
  | .id table => .id table
  | .literalString value => .literalString value
  | .literalNumber value => .named (toString value)
  | .optional inner => .union [tsType inner, .named "undefined"]
  | .array inner => .array (tsType inner)
  | .obj fields =>
      .object (fields.map fun (name, type) =>
        match type with
        | .optional inner => (name, tsType inner, true)
        | _ => (name, tsType type, false))
  | .union members => .union (members.map tsType)
  | .document table => .doc table
  | .external _ typeName => .named typeName

end Ty
end Mythroads.Convex
