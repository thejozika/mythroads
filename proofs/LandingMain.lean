import Mythroads.Backend.Landing

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Backend/Landing.lean. Do not edit by hand. */\n" ++
  "import { getNode, isShopKind } from '../../shared/board.system'\n" ++
  "import { encounterWeight, outcomesFor, pickEncounter } from '../../shared/encounter.system'\n" ++
  "import type { Doc, Id } from '../_generated/dataModel'\n" ++
  "import type { MutationCtx } from '../_generated/server'\n" ++
  "import { startCombat } from '../combat'\n" ++
  "import { advanceTurn } from '../gameHelpers'\n" ++
  "import { drawRoomRandom } from '../random/state'\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++ Mythroads.Backend.Landing.emitLanding)
