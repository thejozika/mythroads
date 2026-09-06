# Magic

Spells, elements, resistances, and the split between battle magic and field magic.

## Scope

- **Spell catalog** — offensive, defensive, status, utility.
- **Elements** — fire / water / wind / earth (or our equivalents) and their interactions.
- **Resistances** — how armor, accessories, and class confer resistance/immunity.
- **Battle magic** — used in combat as the Magic action; cross-references `../combat/`.
- **Field magic** — over-the-board sabotage cast on rival players from a distance.
- **Magic books** — carried in inventory (not equipment), cast from any owned book. See [`../characters/inventory.md`](../characters/inventory.md).
- **MP / casting cost** — every spell costs MP. MP economy and regen TBD.

## Dokapon reference

Dokapon splits magic into three categories with elemental rules and Bracelet-type counters; books are *equipped* to gate access and casts cost gold/charges, not MP. We diverge: books live in inventory (not equipment), spells cost MP (the new sixth stat). Field magic remains a major griefing vector. See `../../sources/dokapon-items-economy/notes.md` (magic shop section) and `../../sources/dokapon-combat/notes.md` (battle-magic interaction).

## Files in this folder

- `overview.md` — this file
- `spells.md` — full catalog (planned)
- `elements.md` — element wheel, resistances, multipliers (planned)
- `field-magic.md` — over-the-board casting rules (planned)
- `combat-magic.md` — battle-magic specifics (planned)

## Open questions

- Element count — 4 classical, or fewer / more?
- MP regen mechanism (cross-cuts [`../characters/stats.md`](../characters/stats.md)).
- MP cost curves per spell tier.
- Field-magic targeting — any player anywhere, only adjacent, or limited per turn?
- Dispel / counter — can defenders nullify field magic?
