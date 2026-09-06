# Items

The "Items" inventory category: field-action items used on the board to move faster, place hazards, sabotage rivals, and shape play.

> **Terminology note**: in this codebase "Items" specifically refers to the **field-action category** of inventory — *not* every consumable in the game. Potions and Magic Books are separate inventory pools (see [`../characters/inventory.md`](../characters/inventory.md)). When we mean "anything in inventory," we say "inventory contents" or name the specific pool.

## Scope

- **Field-action items** — used on the board on your turn (Sweet Syrup, Trap, Spinner, Vacuum, Mix-up, Come Here, …).
- **Sabotage / griefing tools** — items targeted at other players (the heart of the genre).
- **Acquisition** — item shops, treasure spaces, loot roulette, quest rewards.

Equipment is NOT in this pool — it cannot be stored at all. See [`../equipment/overview.md`](../equipment/overview.md).

Inventory rules (slot counts, theft on KO, stacking) live in [`../characters/inventory.md`](../characters/inventory.md), since they are character-bound rather than item-bound.

Potions are spec'd in [`../potions/`](../potions/) — *not yet created*; create as a sibling pillar when needed, or fold into items/.

Magic books are spec'd in [`../magic/`](../magic/).

## Dokapon reference

Dokapon's iconic items (Dokapon Ring, Acro Ring, Devil Backup, Deathblock, Sweet Syrup, Trap, Spinner, Vacuum, Mix-up, Charm Potion, Revival, Vanish) are the core sabotage/griefing toolkit and a major source of the game's identity. Dokapon does not split items by category the way we do — its single inventory pool covers all of these. We split because each pool can be tuned independently. See `../../sources/dokapon-items-economy/iconic-items.md`.

## Files in this folder

- `overview.md` — this file
- `field-items.md` — board-action items (planned)
- `sabotage-items.md` — PvP-targeted items (planned)
- `acquisition.md` — sources of items (planned)
- `catalog.md` — the full Items-pool catalog (planned)

## Open questions

- **Sabotage item availability.** How do we tune drop/shop rates so griefing is fun, not relentless?
- **Identification / unknown items.** Keep mystery items (Dokapon's "Mystery") or drop?
- **Stacking.** Multiple of the same item per slot, or one slot each? Owned by [`../characters/inventory.md`](../characters/inventory.md).
- **Should "Potions" get its own folder under `documents/`?** Currently no — could be added as a sibling pillar (`documents/potions/`) when potion design begins.
