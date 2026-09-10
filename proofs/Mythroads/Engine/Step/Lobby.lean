import Mythroads.Engine.Event
import Mythroads.Game.Player

/-!
# Lobby transitions: create, join, start

This is the only module that grows `State.players`; every other module rewrites
heroes that already exist. That is why the invariant proof for joining is the one
place a list-append argument appears.

Two boundary details are modelled faithfully rather than idealised.

* **The room code is drawn from the room's own generator.** `room.create` takes four
  draws from the seeded Park–Miller state before anything else happens, which is why
  a freshly created room reports `rngCounter = 4`. The generated `createRoom` then
  redraws on a code collision; that retry needs a database read, so the pure rules
  model the first draw and leave collision handling to the interpreter.
* **Joining doubles as rejoining.** A player who already owns a hero gets that hero
  back unchanged, and a matching name with a matching colour reclaims an unowned
  hero even after the adventure has started. Only a genuinely new hero requires the
  lobby phase and a free seat.
-/

namespace Mythroads.Engine.Lobby

open Mythroads.Game

/-- The room-code alphabet: upper case without the shapes that read as digits. -/
def codeAlphabet : List Char :=
  "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".toList

/-- Draw `count` further code characters, threading the generator state. -/
def codeChars (state count : Nat) : List Char × Nat :=
  match count with
  | 0 => ([], state)
  | n + 1 =>
      let draw := Random.drawBounded state codeAlphabet.length
      let rest := codeChars draw.state n
      ((codeAlphabet[draw.value]?.getD 'A') :: rest.1, rest.2)

/-- A four-character join code and the generator state left behind. -/
def roomCode (state : Nat) : String × Nat :=
  let drawn := codeChars state 4
  (String.ofList drawn.1, drawn.2)

/-- The hero sheet every new player starts from, mirroring the generated `createPlayer`. -/
def freshPlayer (id : Mythroads.PlayerId) (owner : Mythroads.AuthId) (name color : String) :
    PlayerState :=
  { id, owner, name, color,
    position := Player.startingStats.position,
    previousPosition := none,
    gold := Player.startingStats.gold,
    hp := Player.startingStats.hp,
    maxHp := Player.startingStats.hp,
    attack := Player.startingStats.attack,
    defense := Player.startingStats.defense,
    magic := Player.startingStats.magic,
    athletics := Player.startingStats.athletics,
    agility := Player.startingStats.agility,
    dice := Player.startingStats.dice,
    items :=
      [{ rowId := id ++ "-item-1", itemId := "ember_grimoire", equippedSlot := some .offensiveMagic },
       { rowId := id ++ "-item-2", itemId := "aegis_script", equippedSlot := some .defensiveMagic }] }

/-- The trimmed, length-capped hero name the boundary stores. -/
def normalizeName (name : String) : String := String.ofList (name.trimAscii.toString.toList.take 16)

/-- `room.create`: seed the generator, draw a code, and open an empty lobby. -/
def create (s : State) (actor : Mythroads.AuthId) (seed : Nat) : Outcome :=
  let generated := roomCode (Random.normalizeSeed seed)
  .ok ({ s with
          code := generated.1, host := actor, players := [], turn := 0, round := 1,
          phase := .lobby, message := "Scan the code to join the adventure.",
          lastRoll := [], rng := generated.2, rngCounter := 4, camera := none },
       [.persistRoom, .appendLog "room.create"])

/-- A hero already owned by this account, which a repeated join simply returns. -/
def ownedBy (s : State) (actor : Mythroads.AuthId) : Option PlayerState :=
  if actor = "" then none else s.players.find? fun p => p.owner = actor

/-- A hero holding this name, compared case-insensitively as the boundary does. -/
def namedBy (s : State) (name : String) : Option PlayerState :=
  s.players.find? fun p => p.name.toLower = name.toLower

/--
Seat a hero under an already-normalized name: return the account's existing hero,
reclaim a matching unowned hero, or take a free seat in the lobby.
-/
def joinAs (s : State) (actor : Mythroads.AuthId) (hero color : String) : Outcome :=
  match ownedBy s actor with
  | some p => .ok (s, [.persistPlayer p.id])
  | none =>
    match namedBy s hero with
    | some p =>
        if p.owner ≠ "" && p.owner ≠ actor then .error .nameTaken
        else if p.color.toLower ≠ color.toLower then .error .colorMismatch
        else .ok (s.mapPlayer p.id (fun q => { q with owner := actor }),
                  [.persistPlayer p.id, .appendLog "player.join"])
    | none =>
        if s.phase ≠ Phase.lobby then .error .roomNotInLobby
        else if s.players.length ≥ maxPlayers then .error .roomFull
        else
          .ok ({ s with
                  players := s.players ++
                    [freshPlayer (s.code ++ "-" ++ toString s.players.length) actor hero color] },
               [.persistPlayer (s.code ++ "-" ++ toString s.players.length),
                .appendLog "player.join"])

/--
`player.join`: normalize the requested name, then seat it. The room `code` in the event
selects which room to load and is therefore not re-checked here.
-/
def join (s : State) (actor : Mythroads.AuthId) (name color : String) : Outcome :=
  if normalizeName name = "" then .error .nameRequired
  else joinAs s actor (normalizeName name) color

/--
`game.start`: at least one hero must be seated; the first to join acts first.

Starting a room that has already left the lobby is an accepted no-op rather than a
refusal, because the host's phone may resend the command; the event is still logged.
-/
def start (s : State) : Outcome :=
  if s.phase ≠ Phase.lobby then .ok (s, [.appendLog "game.start"])
  else match s.players[0]? with
    | none => .error .roomEmpty
    | some first =>
        .ok ({ s with turn := 0, phase := .awaitingRoll,
                      message := first.name ++ ", roll your movement dice." },
             [.persistRoom, .appendLog "game.start"])

end Mythroads.Engine.Lobby
