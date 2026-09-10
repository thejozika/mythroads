import Mythroads.Backend.Turn

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Game/Turn.lean. Do not edit by hand. */\n" ++
  "import type { Doc, Id } from '../_generated/dataModel'\n" ++
  "import type { MutationCtx } from '../_generated/server'\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++ Mythroads.Backend.Turn.emitTurn)
