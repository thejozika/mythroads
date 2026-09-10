import Mythroads.Backend.Random

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Game/Random.lean. Do not edit by hand. */\n" ++
  "import type { Id } from '../_generated/dataModel'\n" ++
  "import type { MutationCtx } from '../_generated/server'\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++ Mythroads.Backend.Random.emitRandomBackend)
