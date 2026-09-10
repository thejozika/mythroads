import Mythroads.Backend.Room.Queries

def header : String :=
  "/** Generated from proofs/Mythroads/Backend/Room/Queries.lean. Do not edit by hand. */\n" ++
  "import { v } from 'convex/values'\n" ++
  "import type { Doc, Id } from '../_generated/dataModel'\n" ++
  "import type { QueryCtx } from '../_generated/server'\n" ++
  "import { developmentAuthBypass, requireAuthId, requirePlayerOwner } from '../auth/authorization'\n" ++
  "import schema from '../schema'\n\n"

def main : IO Unit :=
  IO.print (header ++ Mythroads.Backend.Room.Queries.emitQueries)
