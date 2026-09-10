import Mythroads.Backend.Router

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Game/Events.lean. Do not edit by hand. */\n" ++
  "import type { MutationCtx } from '../_generated/server'\n" ++
  "import { moveCamera, toggleCamera, zoomCamera } from '../camera'\n" ++
  "import { chooseAttack, chooseGuard } from '../combat'\n" ++
  "import { resolveEncounter } from '../encounters'\n" ++
  "import { cancelDestination, createRoom, joinRoom, movePlayer, rollMovement, selectDestination, startRoom } from '../rooms'\n" ++
  "import { buyItem, equipItem, leaveShop } from '../shops'\n" ++
  "import type { DispatchResult, GameEvent } from './validators'\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++ Mythroads.Backend.Router.emitRouter)
