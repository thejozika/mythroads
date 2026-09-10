import Mythroads.Backend.Retention

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Backend/Retention.lean. Do not edit by hand. */\n" ++
  "import type { MutationCtx } from '../_generated/server'\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++ Mythroads.Backend.Retention.emitRetention)
