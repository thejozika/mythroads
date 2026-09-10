import Mythroads.Convex.Module
import Mythroads.Convex.Ty

namespace Mythroads.Convex.Schema

/-! # The Convex schema module

The schema is now a function of three things that live elsewhere: the closed `Table` enumeration,
the `Index` family indexed by it, and one `Ty` per table describing its document. This module only
turns those into `convex/generated/schema.generated.ts`.

`AppSchema` therefore carries no table list of its own — `Table.all` is the list, and adding a
constructor to `Table` makes every total function over it fail to compile until the new table has a
document, its indexes, and its place in the emitted schema. It carries the Convex version the
validators were written against, because a schema is only meaningful against a server contract.
-/

open Mythroads.Convex

/-- The whole application schema: the document of every table, plus the Convex version it targets. -/
structure AppSchema where
  /-- The Convex server version these validators were written against. -/
  targetConvexVersion : String
  /-- The document shape of each table. Total over `Table`, so no table can be left undescribed. -/
  document : Table → Ty

/-- `defineTable(document).index('name', ['field', …])…` for one table. -/
def tableExpr (schema : AppSchema) (table : Table) : TypeScript.Expr :=
  table.indexes.foldl
    (fun acc index =>
      .call (.property acc "index")
        [.string index.name, .array (index.fields.map .string)])
    (.call (.identifier "defineTable") [(schema.document table).validator])

/-- The `defineSchema({ … })` call, one table per line. -/
def emitAppSchema (schema : AppSchema) : String :=
  "export const appSchema = defineSchema({\n" ++
  TypeScript.join ",\n" (Table.all.map fun table =>
    "    " ++ TypeScript.quote table.name ++ ": " ++
      TypeScript.emitExpr (tableExpr schema table)) ++
  "\n})\n"

/-- The generated Convex schema module. -/
def module (schema : AppSchema) : Module where
  provenance := some ("proofs/Mythroads/Game/Schema.lean for Convex " ++
    schema.targetConvexVersion)
  imports := [
    { source := "convex/server", bindings := [
      { name := "defineSchema" }, { name := "defineTable" }] },
    { source := "convex/values", bindings := [{ name := "v" }] },
    { source := "../events/validators", bindings := [
      { name := "dispatchResultValidator" }, { name := "gameEventValidator" }] }
  ]
  items := [.raw (emitAppSchema schema), .raw "export default appSchema\n"]

end Mythroads.Convex.Schema
