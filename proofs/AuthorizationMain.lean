import Mythroads.Backend.Authorization

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Game/Events.lean. Do not edit by hand. */\n" ++
  "import { ConvexError } from 'convex/values'\n" ++
  "import type { Doc, Id } from '../_generated/dataModel'\n" ++
  "import type { MutationCtx, QueryCtx } from '../_generated/server'\n" ++
  "import type { GameEvent } from '../events/validators'\n\n" ++
  "declare const process: { env: Record<string, string | undefined> }\n" ++
  "type AuthContext = Pick<MutationCtx | QueryCtx, 'auth' | 'db'>\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++ Mythroads.Backend.Authorization.emitAuthorization)
