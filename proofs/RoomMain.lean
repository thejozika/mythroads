import Mythroads.Backend.Room.Lobby
import Mythroads.Backend.Room.Movement

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Backend/Room/*.lean. Do not edit by hand. */\n" ++
  "import { ConvexError } from 'convex/values'\n" ++
  "import { canTraverse, getNode, previewRouteStep } from '../../shared/board.system'\n" ++
  "import type { Id } from '../_generated/dataModel'\n" ++
  "import type { MutationCtx } from '../_generated/server'\n" ++
  "import { roomPhase } from '../gameHelpers'\n" ++
  "import { drawBounded, normalizeSeed } from './random.generated'\n" ++
  "import { resolveLanding } from '../landings'\n" ++
  "import { createPlayer } from '../players'\n\n"

def main : IO Unit := IO.print (generatedHeader ++
  Mythroads.Backend.Room.Lobby.emitLobby ++ "\n" ++
  Mythroads.Backend.Room.Movement.emitMovement)
