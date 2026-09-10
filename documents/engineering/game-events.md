# Game events and world definition

All client gameplay writes enter through `game.dispatch`. Its envelope has three stable parts:

- `type` names the requested transition, such as `movement.step` or `shop.buy`.
- `subjects` identifies the room, player, encounter, or owned item being acted upon.
- `data` carries values specific to that event.

The dispatch mutation validates the discriminated event, calls the router, and records persistent
commands in `gameEvents` in the same transaction. Stored events use a versioned, typed envelope with
event ID, optional client command ID, room, actor, event payload, and result. Legacy untyped rows are
accepted only as a migration bridge. A repeated command ID returns its original result instead of
applying the transition twice.

Validators, routing, persistence policy, and bounded retention live separately under
`convex/events/`. Domain handlers remain internal TypeScript functions rather than separately
callable mutations, preserving one atomic public gameplay-write boundary.

The authoritative logical map is `WORLD` in `shared/board.system.ts`. Each node contains rules data
(kind, coordinates, graph neighbors) and a stable `visualId`. The Three.js layer resolves that ID in
`src/game/board/world.material.ts`; shared rules never import rendering code or asset paths.

Add new mechanics by adding a constructor to `Engine.Event` in `proofs/Mythroads/Engine/Event.lean`,
classifying it (`name`, `authority`, `durable`, `permitted`), adding its arm to `transition`, its
invariant lemma, its wire mapping in `Backend/Aggregate/Envelope.lean`, and tests for allowed and
rejected phase transitions. Lean's exhaustiveness checks make a missing classification a build
error. Do not add a second public gameplay mutation.

Camera commands are explicitly ephemeral: they use the same realtime gateway and update the
dedicated `roomCameras` projection, but are never appended to durable `gameEvents`. Follow mode
derives its target from the active player's logical world node. Free mode shares a temporary display
target and distance between the phone and main screen without changing logical game history.

`retention.ts` contains the bounded deletion primitive for a future scheduled retention job; nothing
schedules it yet. The actor of every event is the verified Hanko identity from `ctx.auth`, and the
engine's `authorized` gate decides account, room-host, or player-owner authority per event kind.
