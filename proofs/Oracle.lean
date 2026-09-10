import Mythroads.Oracle.Scenario

/-!
# `mythroads-oracle`: what the Lean engine actually does

`lake exe mythroads-oracle <output-root>` writes `tests/engine/fixtures/engine-oracle.json`
below the given root: the scenarios and the seeded fuzz of
`Mythroads.Oracle.Scenario`, each with the result the *Lean* `step` produced.

`tests/engine/engine-parity.test.ts` replays exactly those envelopes through the
compiled TypeScript engine and compares. Nothing in the fixture is written by hand and
nothing in it is approximate: the scenarios carry whole outcomes and the fuzz carries a
digest of the canonical text of each one.

`scripts/lean/check-oracle.mjs` regenerates the fixture into a temporary directory and
fails if it differs from the one in the repository, so a rule change that would move
the goalposts cannot land with a stale oracle beside it.
-/

open Lean Mythroads.Engine Mythroads.Oracle

/--
How many fuzz envelopes the fixture carries. The number is bounded by the fixture's
size rather than by the compiler: the envelopes are stored verbatim because they are
the test's input, and they are what fills the file.
-/
def fuzzLength : Nat := 1750

/-- The seed the fuzz starts from. Park–Miller needs a non-zero state. -/
def fuzzSeed : Nat := 7

/-- The path of the fixture, relative to the output root. -/
def outputPath : System.FilePath := "tests/engine/fixtures/engine-oracle.json"

/-- One scenario, as it appears in the fixture. -/
def scenarioJson (s : Mythroads.Oracle.Scenario) : Json :=
  Json.mkObj [("name", Json.str s.name), ("start", state s.start),
    ("steps", Json.arr (runScenario s.start s.envelopes).toArray)]

/-- The whole fixture. -/
def fixture : Json :=
  let fuzz := runFuzz fuzzLength fuzzSeed blank []
  Json.mkObj
    [("scenarios", Json.arr (scenarios.map scenarioJson).toArray),
      ("fuzz", Json.mkObj
        [("seed", nat fuzzSeed),
          ("start", state blank),
          ("envelopes", Json.arr (fuzz.map (·.1)).toArray),
          ("digests", Json.arr (fuzz.map (fun p => Json.str p.2)).toArray)])]

/-- Write the fixture under the output root given as the single argument. -/
def main : List String → IO UInt32
  | [root] => do
      let target := System.FilePath.mk root / outputPath
      if let some parent := target.parent then IO.FS.createDirAll parent
      let text := canonical fixture
      IO.FS.writeFile target (text ++ "\n")
      IO.eprintln s!"wrote {text.length} bytes of oracle to {target}"
      return 0
  | _ => do
      IO.eprintln "usage: mythroads-oracle <output-root>"
      return 1
