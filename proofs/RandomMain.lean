import Mythroads.Backend.Random

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/Game/Random.lean. Do not edit by hand. */\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++ Mythroads.Backend.Random.emitRandomBackend)
