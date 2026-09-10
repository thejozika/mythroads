import Mythroads.Engine.Core
import Mythroads.Engine.Room
import Mythroads.Engine.Combat
import Mythroads.Engine.Event
import Mythroads.Engine.Step
import Mythroads.Engine.Step.Camera
import Mythroads.Engine.Step.Combat
import Mythroads.Engine.Step.Encounter
import Mythroads.Engine.Step.Landing
import Mythroads.Engine.Step.Lobby
import Mythroads.Engine.Step.Movement
import Mythroads.Engine.Step.Shop
import Mythroads.Engine.Replay
import Mythroads.Engine.Invariant
import Mythroads.Engine.Preservation
import Mythroads.Engine.Theorems
import Mythroads.Engine.Examples

/-!
# The Mythroads engine

One definition of the game, in Lean. Importing this module brings in the whole of it.

The engine is a pure, deterministic, event-sourced state machine over a single
aggregate — the room. There is exactly one entry point, `Mythroads.Engine.step`, and
everything else in this directory either supplies its vocabulary, supplies one arm of
its dispatch, or proves something about it.

Read the modules in this order.

| Module | What it settles |
|---|---|
| `Engine.Core` | ids, the hero sheet, the phase automaton, the room aggregate, effects and errors |
| `Engine.Room` | total board lookup and the only two mutation primitives |
| `Engine.Combat` | the damage formula and the battle statistics, in exact fixed point |
| `Engine.Event` | the event alphabet and the three gates: `authorized`, `onTurn`, `permitted` |
| `Engine.Step.*` | one module per phase family: lobby, movement, landing, battle, encounter, shop, camera |
| `Engine.Step` | `transition`, the flat `(phase, event)` table, and `step`, the three gates in front of it |
| `Engine.Replay` | the durable log is the truth; `State` is its cache |
| `Engine.Invariant` | the `Ok` invariant and the two primitive lemmas that make it cheap |
| `Engine.Preservation` | one invariant lemma per transition |
| `Engine.Theorems` | determinism, the gate theorems, phase safety, and `ok_step` / `ok_replay` |
| `Engine.Examples` | compile-time `#guard`s walking a full turn, a battle round and a shop visit |

## Where the rules come from

The semantics reproduce the behaviour of the currently generated Convex backend — the
handlers under `convex/generated/**` and the shared rules under `shared/generated/**` —
so this definition can replace them without a behavioural diff. Catalogue data is not
restated: the board graph, matchup tables, magic techniques, item catalogue, encounter
wheel, Park–Miller generator and turn order are imported from `Mythroads.Game.*`, which
already generates the TypeScript those handlers call.

Four behaviours of the generated code are deliberately *not* modelled, because they are
not rules. Room-code collision retries and Convex row identifiers need database reads;
the 2200 ms cooling-off before an encounter may be acknowledged is a wall clock; and
message text, while reproduced, is display state rather than a game outcome. Each is
noted in the module that would otherwise carry it.
-/
