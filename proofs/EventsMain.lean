import Mythroads.Convex.Emit.Schema
import Mythroads.Game.Events

open Mythroads.Convex.Emit.Schema
open Mythroads.Game.Events

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Game/Events.lean. Do not edit by hand. */\n" ++
  "import { type Infer, v } from 'convex/values'\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++
    "export const gameEventValidator = " ++ emitValidator gameEvent ++ "\n\n" ++
    "export const dispatchResultValidator = " ++ emitValidator dispatchResult ++ "\n\n" ++
    "export type GameEvent = Infer<typeof gameEventValidator>\n" ++
    "export type DispatchResult = Infer<typeof dispatchResultValidator>\n")
