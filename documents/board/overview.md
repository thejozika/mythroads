# Board

The shared map players move across, the spaces they land on, the dice/spinner that drives movement, and the turn structure that frames it.

## Scope

- **Space types** — every kind of square a player can land on (battle, town, store, bank, event, treasure, trap, vending, quiz, warp, castle, …) and what triggers when they do.
- **Board layout / topology** — continents, regions, branching paths, bridges/ferries, choke points.
- **Movement** — dice/spinner mechanics, range, branching choice at junctions, items that modify movement.
- **Turn structure** — day, week, turn order, round resolution, simultaneous vs sequential phases.

## Dokapon reference

Dokapon's board is a graph of color-coded panels: red (battle), blue (gold), green (item), orange (town), white (event), plus stores, banks, castles, and special spaces (vending/quiz/warp/trap). 1 day = one round of turns; 7 days = 1 week. Spinner is 1–6 (with rare modifiers). See `../../sources/dokapon-core-loop/notes.md` and `../../sources/dokapon-items-economy/notes.md`.

## Files in this folder

- `overview.md` — this file
- [`movement.md`](movement.md) — turn structure, branching, collisions, intercept rule
- [`dice.md`](dice.md) — dice tiers, slots, breakage, inventory, loadout selection
- `spaces.md` — full taxonomy of space types and on-land effects (planned)
- `layout.md` — board topology, regions, design constraints (planned)
- `turn-structure.md` — day/week, turn order, phases (planned)

## Open questions

- How many space types in the MVP?
- Fixed map or procedural?
- Single connected world or per-region maps with travel?
- Map size sized for what peak roll? (See dice.md — current ceiling is 5 × D8 = 40.)
