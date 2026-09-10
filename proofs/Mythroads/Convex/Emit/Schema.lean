import Mythroads.Convex.Schema
import Mythroads.Convex.TypeScript

namespace Mythroads.Convex.Emit.Schema

open Mythroads.Convex.Schema

partial def emitValidator : Validator → String
  | .any => "v.any()"
  | .null => "v.null()"
  | .boolean => "v.boolean()"
  | .number => "v.number()"
  | .int64 => "v.int64()"
  | .string => "v.string()"
  | .id table => s!"v.id({TypeScript.quote table})"
  | .literalString value => s!"v.literal({TypeScript.quote value})"
  | .literalNumber value => s!"v.literal({value})"
  | .optional inner => s!"v.optional({emitValidator inner})"
  | .array inner => s!"v.array({emitValidator inner})"
  | .object fields =>
      "v.object({" ++ TypeScript.join ", "
        (fields.map fun (name, validator) => s!"{name}: {emitValidator validator}") ++ "})"
  | .union members =>
      "v.union(" ++ TypeScript.join ", " (members.map emitValidator) ++ ")"
  | .external name => name

def emitIndex (value : Index) : String :=
  ".index(" ++ TypeScript.quote value.name ++ ", [" ++
  TypeScript.join ", " (value.fields.map TypeScript.quote) ++ "])"

def emitTable (table : Table) : String :=
  TypeScript.quote table.name ++ ": defineTable(" ++ emitValidator table.document ++ ")" ++
  TypeScript.join "" (table.indexes.map emitIndex)

def emitAppSchema (schema : AppSchema) : String :=
  "/** Generated from proofs/Mythroads/Game/Schema.lean for Convex " ++
  schema.targetConvexVersion ++ ". Do not edit by hand. */\n" ++
  "import { defineSchema, defineTable } from 'convex/server'\n" ++
  "import { v } from 'convex/values'\n" ++
  "import { dispatchResultValidator, gameEventValidator } from '../events/validators'\n\n" ++
  "export const appSchema = defineSchema({\n" ++
  TypeScript.join ",\n" (schema.tables.map fun table => "    " ++ emitTable table) ++
  "\n})\n\nexport default appSchema\n"

end Mythroads.Convex.Emit.Schema
