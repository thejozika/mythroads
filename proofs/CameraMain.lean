import Mythroads.Backend.Camera

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Backend/Camera.lean. Do not edit by hand. */\n" ++
  "import { ConvexError } from 'convex/values'\n" ++
  "import { getNode } from '../../shared/board.system'\n" ++
  "import type { Doc, Id } from '../_generated/dataModel'\n" ++
  "import type { MutationCtx } from '../_generated/server'\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++ Mythroads.Backend.Camera.emitCamera)
