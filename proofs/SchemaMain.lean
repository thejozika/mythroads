import Mythroads.Convex.Emit.Schema
import Mythroads.Game.Schema

def main : IO Unit :=
  IO.print (Mythroads.Convex.Emit.Schema.emitAppSchema Mythroads.Game.Schema.appSchema)
