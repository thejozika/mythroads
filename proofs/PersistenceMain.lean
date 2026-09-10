import Mythroads.Backend.Persistence

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Game/Events.lean. Do not edit by hand. */\n" ++
  "import { ConvexError } from 'convex/values'\n" ++
  "import type { MutationCtx } from '../_generated/server'\n" ++
  "import { resolveEventAuthority } from './authority'\n" ++
  "import { eventRoomId, isPersistentGameEvent } from './policy'\n" ++
  "import type { DispatchResult, GameEvent } from './validators'\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++ Mythroads.Backend.Persistence.emitPersistence)
