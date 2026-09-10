import Mythroads.Backend.Aggregate.Boundary
import Mythroads.Backend.Aggregate.Enums
import Mythroads.Backend.Aggregate.Envelope
import Mythroads.Backend.Aggregate.Load
import Mythroads.Backend.Aggregate.Persist
import Mythroads.Backend.Aggregate.Rows
import Mythroads.Backend.Aggregate.Support

/-!
# The aggregate boundary

Six modules that emit `convex/generated/aggregate/**`: the interpreter standing between the wire
and `Mythroads.Engine.step`. Together they replace the fourteen per-event handler modules this
directory used to hold, and they contain no rule at all.

| Module | What it emits |
|---|---|
| `Aggregate.Support` | shorthand for the other five: expressions, the compiled value shapes, the imports |
| `Aggregate.Enums` | `enums.generated.ts` — a closed column string read back as an engine constructor |
| `Aggregate.Load` | `load.generated.ts` — eight rows in, one `State` out |
| `Aggregate.Rows` | `rows.generated.ts` — one `State` out, columns in |
| `Aggregate.Persist` | `persist.generated.ts` — the `Effect` list, carried out in order |
| `Aggregate.Envelope` | `envelope.generated.ts` — the wire event as an `Envelope` |
| `Aggregate.Boundary` | `boundary.generated.ts` — load, step, save, and the two policies the rules omit |

Read `Aggregate.Boundary` first. Its module documentation states the whole contract, including the
two behaviours the rules deliberately leave to it and why neither of them could be a rule.
-/
