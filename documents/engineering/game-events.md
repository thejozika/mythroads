# Game events and world definition

All client gameplay writes enter through `game.dispatch`. Its envelope has three stable parts:

- `type` names the requested transition, such as `movement.step` or `shop.buy`.
- `subjects` identifies the room, player, encounter, or owned item being acted upon.
- `data` carries values specific to that event.

The dispatch mutation validates the discriminated event, calls a focused handler, and records the
accepted command in `gameEvents` in the same transaction. Queries remain separate because they do
not alter state. Handler modules are internal TypeScript functions rather than separately callable
mutations, preserving one atomic public write boundary.

The authoritative logical map is `WORLD` in `shared/board.system.ts`. Each node contains rules data
(kind, coordinates, graph neighbors) and a stable `visualId`. The Three.js layer resolves that ID in
`src/game/board/world.material.ts`; shared rules never import rendering code or asset paths.

Add new mechanics by extending the event union, implementing one focused handler, and adding tests
for allowed and rejected phase transitions. Do not add a second public gameplay mutation.
