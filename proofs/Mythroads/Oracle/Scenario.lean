import Mythroads.Oracle.Event

/-!
# What the oracle runs

Two kinds of input, for two kinds of confidence.

**Scenarios** are the walks through the game that `Mythroads.Engine.Examples` already
pins with `#guard`: a whole turn from an empty room, a battle round, a shop visit, the
camera, and the refusals each of them earns. They are stored with the full outcome of
every step, so a failure names the exact field that differs.

**The fuzz** is some seventeen hundred envelopes generated from a fixed seed against the running
room, so the events are mostly the ones the current phase accepts, with one in five
deliberately not. It is stored as digests rather than outcomes, so the fixture stays
small; the state is threaded on both sides, so a single divergence anywhere makes every
later digest disagree as well.
-/

namespace Mythroads.Oracle

open Lean (Json)
open Mythroads Mythroads.Engine

/-- Build an envelope. -/
def env (actor : String) (subject : Option Mythroads.PlayerId) (e : Event) (seed : Nat := 0) :
    Envelope :=
  { actor, subject, event := e, seed }

/-- A named walk through the game: where it starts and what is sent. -/
structure Scenario where
  name : String
  start : State
  envelopes : List Envelope

/-- Apply one envelope, keeping the old room when it is refused, as `Examples.run` does. -/
def advance (s : State) (e : Envelope) : State :=
  match step s e with
  | .ok (s', _) => s'
  | .error _ => s

/-- Every step of a scenario: the envelope and the outcome the Lean engine produced. -/
def runScenario (s : State) : List Envelope → List Json
  | [] => []
  | e :: rest =>
      Json.mkObj [("envelope", envelope e), ("outcome", outcome (step s e))]
        :: runScenario (advance s e) rest

/-- The hero on turn in the example room. -/
def hero : Mythroads.PlayerId := ayla

/-- A whole turn from an empty room, with the refusals the three gates produce. -/
def turnScenario : Scenario where
  name := "a full turn from an empty room"
  start := blank
  envelopes :=
    [env "host" none (.roomCreate 20260910),
      env "" none (.playerJoin "JSKM" "   " "grey"),
      env "host" none (.playerJoin "JSKM" "Ayla" "red"),
      env "bo" none (.playerJoin "JSKM" "Bo" "blue"),
      env "bo" none .gameStart,
      env "host" none .gameStart,
      env "stranger" (some hero) .movementRoll,
      env "host" (some hero) (.combatGuard .brace),
      env "host" (some hero) .movementRoll]
      ++ ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map fun d =>
            env "host" (some hero) (.movementSelect d))
      ++ [env "host" (some hero) (.movementSelect 40),
        env "host" (some hero) (.movementStep 9),
        env "host" (some hero) .encounterResolve]

/-- A battle round from the hand-built battle `Examples.facing` opens with. -/
def battleScenario : Scenario where
  name := "a battle round"
  start := facing
  envelopes :=
    [env "host" (some hero) (.combatAttack (.physical .chargeHigh)),
      env "host" (some hero) (.combatAttack (.physical .leap)),
      env "host" (some hero) (.combatGuard .brace),
      env "host" (some hero) (.combatAttack (.magic .emberBlast)),
      env "host" (some hero) (.combatGuard .ward),
      env "host" (some hero) (.combatAttack (.physical .stab)),
      env "host" (some hero) (.combatGuard .high)]

/-- A shop visit, including the two purchases the rules refuse. -/
def shopScenario : Scenario where
  name := "a shop visit"
  start := shopping
  envelopes :=
    [env "host" (some hero) (.shopBuy "moon_ring"),
      env "host" (some hero) (.shopBuy "iron_sword"),
      env "host" (some hero) (.shopBuy "oak_blade"),
      env "host" (some hero) (.inventoryEquip "JSKM-0-item-3" .weapon),
      env "host" (some hero) (.inventoryEquip "JSKM-0-item-9" .weapon),
      env "host" (some hero) .shopLeave]

/-- The shared camera, which changes nothing durable. -/
def cameraScenario : Scenario where
  name := "the shared camera"
  start := started
  envelopes :=
    [env "host" (some hero) (.cameraMove .left),
      env "host" (some hero) .cameraToggle,
      env "host" (some hero) (.cameraMove .left),
      env "host" (some hero) (.cameraMove .up),
      env "host" (some hero) (.cameraZoom .nearer),
      env "host" (some hero) (.cameraZoom .farther),
      env "host" (some hero) .cameraToggle]

/-- Every scenario the fixture carries. -/
def scenarios : List Scenario :=
  [turnScenario, battleScenario, shopScenario, cameraScenario]

/-- Pick from a list by a drawn number; the list is never empty in practice. -/
def pick (n : Nat) (xs : List α) (fallback : α) : α := (xs[n % xs.length]?).getD fallback

/-- Four draws from the Park–Miller stream, which is the engine's own generator. -/
def draws (r : Nat) : Nat × Nat × Nat × Nat :=
  let a := Game.Random.nextState r
  let b := Game.Random.nextState a
  let c := Game.Random.nextState b
  (a, b, c, Game.Random.nextState c)

/-- An envelope with no regard for the phase: this is where the refusals come from. -/
def wildEnvelope (r : Nat) : Envelope :=
  let (a, b, c, d) := draws r
  let actor := pick (a % 6) ["host", "bo", "carol", "dave", "", "mallory"] ""
  let subject := if b % 7 == 0 then none else
    some (pick (b % 4) ["JSKM-0", "JSKM-1", "JSKM-2", "ghost"] "JSKM-0")
  let e : Event := pick (c % 16)
    [.roomCreate (d % 1000), .playerJoin "JSKM" (pick (d % 4) ["Ayla", "Bo", "Cyd", ""] "X") "red",
      .gameStart, .movementRoll, .movementSelect (d % 40), .movementCancel,
      .movementStep (d % 40), .combatAttack (.physical (pick (d % 4)
        [.stab, .chargeHigh, .chargeSide, .leap] .stab)),
      .combatGuard (pick (d % 4) [.high, .side, .brace, .ward] .high), .encounterResolve,
      .shopBuy (pick (d % 4) ["oak_blade", "moon_ring", "iron_sword", "elixir"] "oak_blade"),
      .inventoryEquip "JSKM-0-item-1" .offensiveMagic, .shopLeave, .cameraToggle,
      .cameraMove (pick (d % 4) [.up, .down, .left, .right] .up),
      .cameraZoom (pick (d % 2) [.nearer, .farther] .nearer)] .cameraToggle
  env actor subject e d

/-- The nodes reachable in one step from `origin`, which is what route planning accepts. -/
def neighbours (origin : NodeId) : List NodeId :=
  (List.range Game.World.nodes.length).filter fun n => Game.World.canTraverse origin n

/-- An envelope the current phase is likely to accept, sent by the hero on turn. -/
def phaseEnvelope (s : State) (r : Nat) : Envelope :=
  let (_, _, _, d) := draws r
  let active := s.active?
  let actor := match active with | some p => p.owner | none => "host"
  let subject := match active with | some p => some p.id | none => none
  let e : Event :=
    match s.phase with
    | .lobby =>
        if s.players.length < 2 || d % 3 != 0 then
          .playerJoin s.code (pick (d % 4) ["Ayla", "Bo", "Cyd", "Dag"] "X")
            (pick (d % 3) ["red", "blue", "green"] "red")
        else .gameStart
    | .awaitingRoll => .movementRoll
    | .moving moves sel =>
        -- Route planning opens on the hero's own node and then only accepts a neighbour of
        -- the route's head; a fuzz that fed it arbitrary node numbers would never leave
        -- this phase. The route is committed once it is as long as the roll.
        let position := match active with | some p => p.position | none => 0
        if d % 11 == 0 then .movementCancel
        else match sel with
          | none => .movementSelect position
          | some plan =>
              if plan.path.length >= moves then .movementStep plan.destination
              else .movementSelect (pick (d % 7) (neighbours plan.destination) position)
    | .combat _ .attackerChoice =>
        if d % 3 == 0 then .combatAttack (.magic (pick (d % 8)
          [.emberBlast, .scorchArmor, .tideNeedle, .undertow, .galeBlade, .windShear,
            .stoneCrash, .calcify] .emberBlast))
        else .combatAttack (.physical (pick (d % 4)
          [.stab, .chargeHigh, .chargeSide, .leap] .stab))
    | .combat _ _ => .combatGuard (pick (d % 4) [.high, .side, .brace, .ward] .high)
    | .encounter _ => .encounterResolve
    | .shop _ =>
        if d % 2 == 0 then .shopBuy (pick (d % 3) ["oak_blade", "trail_helm", "moon_ring"] "oak_blade")
        else .shopLeave
    | .finished _ => .cameraToggle
  let actor := if s.phase matches .lobby then pick (d % 3) ["host", "bo", "carol"] "host" else actor
  env actor subject e d

/-- The next fuzz envelope: mostly legal, one in five deliberately not. -/
def fuzzEnvelope (s : State) (r : Nat) : Envelope :=
  if s.code.isEmpty then env "host" none (.roomCreate (r % 100000)) r
  else if r % 5 == 0 then wildEnvelope r
  else phaseEnvelope s r

/-- Run the fuzz, collecting the envelope sent and the digest of the outcome. -/
def runFuzz : Nat → Nat → State → List (Json × String) → List (Json × String)
  | 0, _, _, acc => acc.reverse
  | n + 1, r, s, acc =>
      let e := fuzzEnvelope s r
      let o := step s e
      runFuzz n (Game.Random.nextState r) (advance s e)
        ((envelope e, digest (canonical (outcome o))) :: acc)

end Mythroads.Oracle
