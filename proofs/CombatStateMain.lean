import Mythroads.Backend.Combat.State

open Mythroads.Backend.Combat.State

def header : String :=
  "import { ConvexError } from 'convex/values'\n" ++
  "import { enemyForSpace, type BattleStats } from '../../../shared/combat.system'\n" ++
  "import type { DebuffStat } from '../../../shared/magic.system'\n" ++
  "import type { Doc, Id } from '../../_generated/dataModel'\n" ++
  "import type { MutationCtx } from '../../_generated/server'\n" ++
  "import { roomPhase } from '../../gameHelpers'\n\n"

def main : IO Unit := IO.print (header ++ emitState)
