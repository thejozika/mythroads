# Magic

Spells, elements, resistances, and the split between battle magic and field magic.

## Scope

- **Spell catalog** — offensive, defensive, status, utility.
- **Elements** — fire / water / wind / earth (or our equivalents) and their interactions.
- **Resistances** — how armor, accessories, and class confer resistance/immunity.
- **Battle magic** — used in combat as the Magic action; cross-references `../combat/`.
- **Field magic** — over-the-board sabotage cast on rival players from a distance.
- **Magic books** — collected as gear and assigned to either the Battle Spell or Magic Ward slot.
- **MP / casting cost** — playable battle spells cost 2 MP. Long-term MP economy and regen remain TBD.

## Playable battle magic

- Ember (fire), Tide (water), Gale (wind), and Stonebind (earth) form a four-element cycle. Only the
  currently equipped battle spell appears beside physical attacks on the controller.
- Fire beats earth, earth beats wind, wind beats water, and water beats fire.
- Element-neutral targets take normal damage. Arcane Ward is the fourth defense: it sharply reduces
  spell damage but loses badly to all physical options. An equipped defensive spell supplies its
  ward strength and can later carry counter-effects.
- This is deliberately one decision deep: choose a spell from the visible enemy element and spend
  2 MP. Status spells, books, equipment resistances, and field targeting build on this foundation.

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
