namespace Mythroads.Convex

/-! # The table and index universe

Table names and index names used to be bare `String` literals: one hundred and twenty-two spellings
of eight table names across twenty-two Lean files, and eight index names across twelve. Nothing
checked that a `withIndex('by_room', …)` string named an index that exists, that the index belonged
to the table being queried, or that the `q.eq(…)` field matched the index's first key.

`Table` is a closed enumeration and `Index` is indexed *by* the table it belongs to, so
`Index.playerItemsByPlayerId : Index .playerItems` cannot be handed to a query over `.rooms`: that
is a type error, not a runtime surprise. `Index.fields` then drives the emitted `q.eq(…)` chain, so
an indexed read cannot name a key the index does not have or put its keys in the wrong order.

This module deliberately carries only *identity*: the names, the key fields, and which indexes each
table has. The document shape of each table lives in `Mythroads/Game/Schema.lean` as
`Table.document`, because that is the file the generated schema names as its provenance.
-/

/-- Every table in the Convex schema. -/
inductive Table where
  /-- One game room, identified by its four-character join code. -/
  | rooms
  /-- One hero in a room. -/
  | players
  /-- A revealed encounter-wheel outcome awaiting resolution. -/
  | encounters
  /-- An in-progress battle. -/
  | combats
  /-- The destination a hero has previewed but not yet committed to. -/
  | roomSelections
  /-- One item owned by a hero, with its equipped slot. -/
  | playerItems
  /-- The durable game-event log. -/
  | gameEvents
  /-- Ephemeral spectator camera state for a room. -/
  | roomCameras
  deriving Repr, DecidableEq, Inhabited

namespace Table

/-- The table's name as it appears in the Convex schema and in every `ctx.db` call. -/
def name : Table → String
  | .rooms => "rooms"
  | .players => "players"
  | .encounters => "encounters"
  | .combats => "combats"
  | .roomSelections => "roomSelections"
  | .playerItems => "playerItems"
  | .gameEvents => "gameEvents"
  | .roomCameras => "roomCameras"

/-- Every table, in the order the generated `defineSchema` call lists them. -/
def all : List Table :=
  [.rooms, .players, .encounters, .combats, .roomSelections, .playerItems, .gameEvents,
    .roomCameras]

end Table

/-- The indexes declared on each table. The family is indexed by `Table`, so an index value can
only ever be used against the table that declares it. -/
inductive Index : Table → Type where
  /-- Room lookup by join code. -/
  | roomsByCode : Index .rooms
  /-- All heroes in a room. -/
  | playersByRoom : Index .players
  /-- One hero in a room, by the account that controls it. -/
  | playersByRoomAndAuthId : Index .players
  /-- The active encounter of a room. -/
  | encountersByRoomId : Index .encounters
  /-- The active combat of a room. -/
  | combatsByRoomId : Index .combats
  /-- The pending destination selection of a room. -/
  | roomSelectionsByRoomId : Index .roomSelections
  /-- One hero's inventory. -/
  | playerItemsByPlayerId : Index .playerItems
  /-- The event log in insertion order, for retention sweeps. -/
  | gameEventsByCreatedAt : Index .gameEvents
  /-- Command deduplication for idempotent dispatch. -/
  | gameEventsByCommandId : Index .gameEvents
  /-- One room's event log in insertion order. -/
  | gameEventsByRoomIdAndCreatedAt : Index .gameEvents
  /-- The camera state of a room. -/
  | roomCamerasByRoomId : Index .roomCameras

namespace Index

/-- The index name as it appears in `defineTable(...).index(...)` and in `withIndex`. -/
def name : Index table → String
  | .roomsByCode => "by_code"
  | .playersByRoom => "by_room"
  | .playersByRoomAndAuthId => "by_room_and_authId"
  | .encountersByRoomId => "by_roomId"
  | .combatsByRoomId => "by_roomId"
  | .roomSelectionsByRoomId => "by_roomId"
  | .playerItemsByPlayerId => "by_playerId"
  | .gameEventsByCreatedAt => "by_createdAt"
  | .gameEventsByCommandId => "by_commandId"
  | .gameEventsByRoomIdAndCreatedAt => "by_roomId_and_createdAt"
  | .roomCamerasByRoomId => "by_roomId"

/-- The index key fields, in order. This is what an emitted `q.eq(…)` chain is built from, so the
chain cannot disagree with the schema. -/
def fields : Index table → List String
  | .roomsByCode => ["code"]
  | .playersByRoom => ["roomId"]
  | .playersByRoomAndAuthId => ["roomId", "authId"]
  | .encountersByRoomId => ["roomId"]
  | .combatsByRoomId => ["roomId"]
  | .roomSelectionsByRoomId => ["roomId"]
  | .playerItemsByPlayerId => ["playerId"]
  | .gameEventsByCreatedAt => ["createdAt"]
  | .gameEventsByCommandId => ["commandId"]
  | .gameEventsByRoomIdAndCreatedAt => ["roomId", "createdAt"]
  | .roomCamerasByRoomId => ["roomId"]

end Index

/-- The indexes declared on a table, in the order the generated schema chains them. -/
def Table.indexes : (table : Table) → List (Index table)
  | .rooms => [.roomsByCode]
  | .players => [.playersByRoom, .playersByRoomAndAuthId]
  | .encounters => [.encountersByRoomId]
  | .combats => [.combatsByRoomId]
  | .roomSelections => [.roomSelectionsByRoomId]
  | .playerItems => [.playerItemsByPlayerId]
  | .gameEvents =>
      [.gameEventsByCreatedAt, .gameEventsByCommandId, .gameEventsByRoomIdAndCreatedAt]
  | .roomCameras => [.roomCamerasByRoomId]

end Mythroads.Convex
