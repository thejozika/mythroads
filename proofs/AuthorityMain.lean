import Mythroads.Backend.Authority

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Game/Events.lean. Do not edit by hand. */\n" ++
  "import type { Id } from '../_generated/dataModel'\n" ++
  "import type { DispatchResult, GameEvent } from './validators'\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++ Mythroads.Backend.Authority.emitAuthority)
