import Mythroads.Backend.Combat.Attack

open Mythroads.Backend.Combat.Attack

def header : String :=
  "import { ConvexError } from 'convex/values'\n" ++
  "import { ATTACK_LABELS, GUARD_LABELS, GUARD_STANCES, isMagicTechnique, strikeDamage, type CombatAttack } from '../../../shared/combat.system'\n" ++
  "import { equippedMagic } from '../../../shared/item.system'\n" ++
  "import { MAGIC_TECHNIQUES } from '../../../shared/magic.system'\n" ++
  "import type { Id } from '../../_generated/dataModel'\n" ++
  "import type { MutationCtx } from '../../_generated/server'\n" ++
  "import { advanceTurn } from '../../gameHelpers'\n" ++
  "import { chanceHits } from '../random.generated'\n" ++
  "import { drawRoomRandom } from '../../random/state'\n" ++
  "import { activeCombat, debuffPatch, enemyStats, playerStats } from './state.generated'\n\n"

def main : IO Unit := IO.print (header ++ emitAttack)
