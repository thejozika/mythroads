import Mythroads

/-! # `mythroads-emit`: the single code generator

Every checked-in `*.generated.ts` file is written by this one executable. It replaces the
twenty-nine `lean_exe` targets that used to print one file each to standard output: twenty-nine
root modules for Lake to elaborate and link, twenty-nine process spawns for the drift check, and a
twenty-nine entry duplicate of this table living in JavaScript, where a wrong relative path could
not be caught by anything.

The table below is the whole mapping. Paths are relative to the repository root and are exactly the
paths the previous executables wrote to, so every consumer — the adapter modules under `convex/`
and `shared/`, the vitest suites, and the architecture checker — keeps working unchanged.

Usage: `lake exe mythroads-emit <output-root>`. `scripts/lean/check-generated.mjs` points it at a
temporary staging directory, formats that tree with Biome, and compares it against the repository
tree; nothing here needs to know about Biome or about the repository layout.
-/

open Mythroads

/-- Every generated file: its path relative to the output root, and the module that fills it. -/
def outputs : List (System.FilePath × Convex.Module) :=
  [ ("convex/generated/game-api.generated.ts", Convex.module),
    ("convex/generated/schema.generated.ts", Convex.Schema.module Game.Schema.appSchema),
    ("convex/generated/inventory.generated.ts", Backend.Inventory.module),
    ("convex/generated/random.generated.ts", Backend.Random.module),
    ("convex/generated/aggregate/enums.generated.ts", Backend.Aggregate.Enums.module),
    ("convex/generated/aggregate/load.generated.ts", Backend.Aggregate.Load.module),
    ("convex/generated/aggregate/rows.generated.ts", Backend.Aggregate.Rows.module),
    ("convex/generated/aggregate/persist.generated.ts", Backend.Aggregate.Persist.module),
    ("convex/generated/aggregate/envelope.generated.ts", Backend.Aggregate.Envelope.module),
    ("convex/generated/aggregate/boundary.generated.ts", Backend.Aggregate.Boundary.module),
    ("convex/events/validators.generated.ts", Game.Events.module),
    ("convex/events/policy.generated.ts", Backend.Policy.module),
    ("convex/events/authority.generated.ts", Backend.Authority.module),
    ("convex/events/persistence.generated.ts", Backend.Persistence.module),
    ("convex/events/retention.generated.ts", Backend.Retention.module),
    ("convex/auth/authorization.generated.ts", Backend.Authorization.module),
    ("convex/rooms/queries.generated.ts", Backend.Room.Queries.module),
    ("shared/generated/board.generated.ts", Game.World.boardModule),
    ("shared/generated/world.generated.ts", Game.World.worldTypesModule),
    ("shared/generated/controller-input.generated.ts", Game.World.controllerInputModule),
    ("shared/generated/combat.generated.ts", Game.Combat.module),
    ("shared/generated/magic.generated.ts", Game.Magic.module),
    ("shared/generated/item.generated.ts", Game.Inventory.module),
    ("shared/generated/encounter.generated.ts", Game.Encounter.module) ]

/-- Writes every generated file under the output root given as the single argument. -/
def main : List String → IO UInt32
  | [root] => do
      for (relative, value) in outputs do
        let target := System.FilePath.mk root / relative
        if let some parent := target.parent then IO.FS.createDirAll parent
        IO.FS.writeFile target (Convex.Module.render value)
      IO.println s!"wrote {outputs.length} generated modules to {root}"
      return 0
  | _ => do
      IO.eprintln "usage: mythroads-emit <output-root>"
      return 1
