import Mythroads.Backend.Inventory

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Backend/Inventory.lean. Do not edit by hand. */\n" ++
  "import { ConvexError, v } from 'convex/values'\n" ++
  "import { getItem } from '../../shared/item.system'\n" ++
  "import type { Id } from '../_generated/dataModel'\n" ++
  "import type { MutationCtx, QueryCtx } from '../_generated/server'\n" ++
  "import { requirePlayerOwner } from '../auth/authorization'\n" ++
  "import schema from '../schema'\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++ Mythroads.Backend.Inventory.emitInventoryBackend)
