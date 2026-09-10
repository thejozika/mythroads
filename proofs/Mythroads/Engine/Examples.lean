import Mythroads.Engine.Theorems

/-!
# Executable examples

Theorems say what is true of *every* room; these `#guard`s say what happens in *this*
one. They run at compile time, so a rule change that silently alters an outcome breaks
the build rather than the game.

The first scenario is a whole turn played end to end from an empty room: create, two
heroes join, the host starts, the first hero rolls, plans a nine-node route, commits
it, lands on an event space, and acknowledges the encounter — at which point the turn
has passed to the second hero. Every number below (the join code, the dice faces, the
drawn encounter) is fixed by the seed given to `room.create`, which is the point: the
generator is part of the state, so the whole turn is reproducible.

Two further scenarios start from a hand-built phase, because reaching a battle or a
shop by rolling would make the example depend on a lucky seed rather than on the rules
under test.
-/

namespace Mythroads.Engine

open Mythroads.Game

/-- A room before anything has happened: the state `room.create` is applied to. -/
def blank : State :=
  { code := "", host := "", players := [], turn := 0, round := 0, phase := .lobby,
    message := "", lastRoll := [], rng := 1, rngCounter := 0, camera := none, version := 0 }

/-- Apply one envelope, keeping the old room if it is refused. -/
def run (s : State) (env : Envelope) : State :=
  match step s env with
  | .ok (s', _) => s'
  | .error _ => s

/-- The error a refused envelope produces, if it is refused. -/
def refusal (s : State) (env : Envelope) : Option Error :=
  match step s env with
  | .ok _ => none
  | .error e => some e

/-- Build an envelope; only `room.create` reads the seed, so the examples pass zero. -/
def envelope (actor : String) (subject : Option String) (event : Event) : Envelope :=
  { actor, subject, event, seed := 0 }

/-! ## A full turn, from an empty room -/

/-- The room, created by the host with a fixed seed. -/
def created : State := run blank (envelope "host" none (.roomCreate 20260910))

-- The join code is drawn from the seeded generator, and costs exactly four draws.
#guard created.code = "JSKM"
#guard created.rngCounter = 4
#guard created.phase = Phase.lobby

/-- Two heroes have joined. -/
def seated : State :=
  run (run created (envelope "host" none (.playerJoin created.code "Ayla" "red")))
    (envelope "bo" none (.playerJoin created.code "Bo" "blue"))

-- Each hero is owned by the account that seated them, in join order.
#guard seated.players.map (fun p => (p.name, p.owner)) = [("Ayla", "host"), ("Bo", "bo")]
#guard seated.players.length = 2

-- A hero starts with ten gold, ten health, and a grimoire and ward already equipped.
#guard seated.players.map (fun p => (p.gold, p.hp, p.maxHp, p.position)) = [(10, 10, 10, 0),
  (10, 10, 10, 0)]
#guard (seated.players[0]!.items.map fun o => (o.itemId, o.equippedSlot)) =
  [("ember_grimoire", some Inventory.EquipmentSlot.offensiveMagic),
    ("aegis_script", some Inventory.EquipmentSlot.defensiveMagic)]

/-! ## The anonymous actor of the development bypass -/

/-- Two heroes seated by the anonymous actor, as two controllers on one laptop would. -/
def anonymousPair : State :=
  run (run created (envelope Lobby.anonymous none (.playerJoin created.code "Ayla" "red")))
    (envelope Lobby.anonymous none (.playerJoin created.code "Bo" "blue"))

-- Each anonymous joiner gets a fresh, unowned hero rather than the first one seated.
#guard anonymousPair.players.map (fun p => (p.name, p.owner)) = [("Ayla", ""), ("Bo", "")]

-- Rejoining anonymously by name and colour returns that hero instead of seating a third.
#guard (run anonymousPair
  (envelope Lobby.anonymous none (.playerJoin created.code "ayla" "RED"))).players.length = 2

-- A signed-in account may claim an unowned hero by name and colour.
#guard (run anonymousPair (envelope "host" none (.playerJoin created.code "Ayla" "red"))).players.map
  (fun p => (p.name, p.owner)) = [("Ayla", "host"), ("Bo", "")]

-- Names and colours are trimmed and capped at sixteen characters before they are stored.
#guard (run created (envelope "host" none
  (.playerJoin created.code "  Ayla  " "  #4bd3c2-with-a-long-tail  "))).players.map
    (fun p => (p.name, p.color)) = [("Ayla", "#4bd3c2-with-a-l")]

/-- The adventure has started; the first hero to join acts first. -/
def started : State := run seated (envelope "host" none .gameStart)

#guard started.phase = Phase.awaitingRoll
#guard started.message = "Ayla, roll your movement dice."

/-- The identifier of the hero whose turn it is. -/
def ayla : String := started.players[0]!.id

/-- Ayla has rolled her two dice. -/
def rolled : State := run started (envelope "host" (some ayla) .movementRoll)

-- Both dice are drawn from the room generator, so the roll is part of the replayable log.
#guard rolled.lastRoll = [4, 5]
#guard rolled.message = "Ayla rolled 9. Press Y to choose a destination."
#guard rolled.phase = Phase.moving 9 none

/-- A nine-node route has been planned along the southern road. -/
def planned : State :=
  ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]).foldl
    (fun s d => run s (envelope "host" (some ayla) (.movementSelect d))) rolled

-- The route consumes the whole roll and ends at Moon Shrine.
#guard planned.phase =
  Phase.moving 9 (some { playerId := ayla, destination := 9, path := [1, 2, 3, 4, 5, 6, 7, 8, 9] })
#guard planned.message = "Route ends at Moon Shrine. Press A to travel."

/-- The route has been committed and the landed space resolved. -/
def travelled : State := run planned (envelope "host" (some ayla) (.movementStep 9))

-- Moon Shrine is an event space, so the wheel is spun as part of the landing.
#guard travelled.phase.name = "revealingEncounter"
#guard travelled.message = "Ayla spins the event wheel!"
#guard (match travelled.phase with
  | .encounter drawn => (drawn.outcome.id, drawn.outcome.goldDelta, drawn.wheelIndex)
  | _ => ("", 0, 0)) = ("bridge_toll", -2, 2)

/-- The encounter has been acknowledged and the turn has passed. -/
def acknowledged : State := run travelled (envelope "host" (some ayla) .encounterResolve)

-- The toll is paid, the banner names it, and Bo is now on turn in the same round.
#guard acknowledged.players.map (fun p => (p.name, p.gold, p.hp, p.position)) =
  [("Ayla", 8, 10, 9), ("Bo", 10, 10, 0)]
#guard acknowledged.message = "Ayla: Bridge Toll (-2 gold)."
#guard acknowledged.turn = 1
#guard acknowledged.round = 1
#guard acknowledged.phase = Phase.awaitingRoll

/-! ## The three gates refuse -/

-- A stranger cannot act for a hero they do not own.
#guard refusal started (envelope "stranger" (some ayla) .movementRoll) = some .unauthorized

-- Only the host may start the adventure.
#guard refusal seated (envelope "bo" none .gameStart) = some .unauthorized

-- A hero cannot act out of turn.
#guard refusal started (envelope "bo" (some (started.players[1]!.id)) .movementRoll) =
  some .notYourTurn

-- A hero who owes a roll cannot skip to guarding.
#guard refusal started (envelope "host" (some ayla) (.combatGuard .brace)) = some .wrongPhase

/-! ## Route planning refunds and refuses -/

-- Selecting the node the route came from retracts a step instead of extending it.
#guard Movement.previewRouteStep 0 [1, 2] 1 9 = some [1]

-- A hop that is not a declared road is refused.
#guard Movement.previewRouteStep 0 [1] 9 9 = none

-- A full route refuses to grow.
#guard Movement.previewRouteStep 0 [1, 2] 3 2 = none

-- The one-way bridge from Odd Crossroad may not be walked backwards.
#guard World.canTraverse 12 13 = true
#guard World.canTraverse 13 12 = false

/-! ## A battle round -/

/-- Ayla, facing the enemy that guards Mossling. -/
def opening : CombatState :=
  { playerId := ayla, spaceId := 1, enemy := enemyForSpace 1, enemyHp := (enemyForSpace 1).hp }

#guard ((enemyForSpace 1).name, (enemyForSpace 1).hp, (enemyForSpace 1).reward) =
  ("Fen Slime", 11, 6)

/-- The battle, waiting for Ayla's attack. -/
def facing : State := { started with phase := .combat opening .attackerChoice }

/-- Ayla has thrown a high charge; the enemy's ward was drawn against it. -/
def struck : State := run facing (envelope "host" (some ayla) (.combatAttack (.physical .chargeHigh)))

-- The generator picked `ward`, the blow missed its accuracy roll, and a guard is now owed.
#guard (match struck.phase with
  | .combat b stage => (b.enemyHp, b.lastGuard, b.lastDamage, b.message, stage)
  | _ => (0, none, none, "", CombatStage.resolved)) =
  (11, some Combat.Guard.ward, some 0, "High charge missed!", CombatStage.defenderChoice)
#guard struck.message = "Fen Slime prepares a counterattack. Choose a guard."

/-- Ayla has braced against the reply. -/
def braced : State := run struck (envelope "host" (some ayla) (.combatGuard .brace))

-- Tide Needle is a Stich impact, so bracing meets it neutrally for two damage.
#guard braced.players.map (fun p => (p.name, p.hp)) = [("Ayla", 8), ("Bo", 10)]
#guard (match braced.phase with
  | .combat b stage => (b.round, b.lastAttack, b.lastDamage, stage)
  | _ => (0, none, none, CombatStage.resolved)) =
  (2, some "tideNeedle", some 2, CombatStage.attackerChoice)

-- The damage formula, checked directly against the numbers the generated code produces.
#guard strikeDamage (.physical .chargeHigh)
  .brace { attack := 2, defense := 2, magic := 2, athletics := 2, agility := 2 }
  { attack := 2, defense := 2, magic := 3, athletics := 1, agility := 2 }
  (some .water) 35 = { matchup := .neutral, accuracy := 7500, damage := 2 }

-- An arcane blast into an arcane ward, at an element disadvantage, is blunted to one.
#guard strikeDamage (.magic .emberBlast)
  .ward { attack := 2, defense := 2, magic := 2, athletics := 2, agility := 2 }
  { attack := 2, defense := 2, magic := 3, athletics := 1, agility := 2 }
  (some .water) 35 = { matchup := .weak, accuracy := 10000, damage := 1 }

/-! ## A shop visit -/

/-- Ayla, standing in the weapon shop. -/
def shopping : State := { started with phase := .shop .weapons }

/-- An oak blade has been bought and equipped, and the visit is over. -/
def outfitted : State :=
  run (run (run shopping (envelope "host" (some ayla) (.shopBuy "oak_blade")))
        (envelope "host" (some ayla) (.inventoryEquip "JSKM-0-item-3" .weapon)))
    (envelope "host" (some ayla) .shopLeave)

-- Five gold spent, the blade in the weapon slot, and the turn passed to Bo.
#guard outfitted.players[0]!.gold = 5
#guard (outfitted.players[0]!.items.map fun o => (o.itemId, o.equippedSlot)) =
  [("ember_grimoire", some Inventory.EquipmentSlot.offensiveMagic),
    ("aegis_script", some Inventory.EquipmentSlot.defensiveMagic),
    ("oak_blade", some Inventory.EquipmentSlot.weapon)]
#guard outfitted.message = "Ayla finished shopping."
#guard outfitted.turn = 1

-- A jeweller's ring is not stocked by the weapon shop.
#guard refusal shopping (envelope "host" (some ayla) (.shopBuy "moon_ring")) = some .itemNotHere

-- Nothing in the catalogue costs more than a hero can eventually afford, but not yet.
#guard refusal shopping (envelope "host" (some ayla) (.shopBuy "iron_sword")) =
  some .insufficientGold

/-! ## Camera commands change nothing durable -/

/-- The free camera, switched on and panned left. -/
def panned : State :=
  run (run started (envelope "host" (some ayla) .cameraToggle))
    (envelope "host" (some ayla) (.cameraMove .left))

-- Panning moves the shared target and leaves every hero exactly as they were.
#guard panned.camera = some { free := true, targetX := -630, targetZ := 320, distance := 8 }
#guard panned.players = started.players
#guard panned.phase = started.phase

-- Panning before the camera exists is refused, because there is no free camera yet.
#guard refusal started (envelope "host" (some ayla) (.cameraMove .left)) = some .cameraNotFree

end Mythroads.Engine
