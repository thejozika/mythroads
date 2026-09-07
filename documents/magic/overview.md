# Magic

Spells, elements, resistances, and the split between battle magic and field magic.

## Scope

- **Spell catalog** — offensive, defensive, status, utility.
- **Elements** — fire / water / wind / earth (or our equivalents) and their interactions.
- **Resistances** — how armor, accessories, and class confer resistance/immunity.
- **Battle magic** — used in combat as the Magic action; cross-references `../combat/`.
- **Field magic** — over-the-board sabotage cast on rival players from a distance.
- **Magic books** — collected as gear and assigned to either the Battle Spell or Magic Ward slot.
- **No mana resource** — equipped techniques are always available; their opportunity cost is the
  combat turn and the grimoire occupying the Battle Spell slot.

## Playable battle magic

- Every offensive grimoire grants exactly two combat actions. The current four starter pairs are:
  Ember Blast + Scorch Armor, Tide Needle + Undertow, Gale Blade + Wind Shear, and Stone Crash +
  Calcify.
- Fire beats earth, earth beats wind, wind beats water, and water beats fire.
- A technique can deal pure magic damage, apply a battle-only debuff, or use Magic to deliver one of
  three physical impact types: **Wucht**, **Stich**, or **Hieb**. Wucht/Stich/Hieb are read by the
  normal physical guards, while pure magic and debuffs are answered by Arcane Ward.
- The two-action data model also supports future books containing two debuffs, two damage actions,
  or any mixed pair without changing the combat protocol.
- Arcane Ward sharply reduces pure spell damage and nullifies debuffs, but is exposed to physical
  and physical-magic attacks. An equipped defensive spell supplies its ward strength.

## Dokapon reference

Dokapon splits magic into three categories with elemental rules and Bracelet-type counters. We keep
equipped battle magic and no MP stat, while making each offensive grimoire a visible pair of actions.
Field magic remains a separate board-system design problem. See
`../../sources/dokapon-items-economy/notes.md` and `../../sources/dokapon-combat/notes.md`.

## Files in this folder

- `overview.md` — this file
- `spells.md` — full catalog (planned)
- `elements.md` — element wheel, resistances, multipliers (planned)
- `field-magic.md` — over-the-board casting rules (planned)
- `combat-magic.md` — battle-magic specifics (planned)

## Open questions

- Element count — 4 classical, or fewer / more?
- Field-magic targeting — any player anywhere, only adjacent, or limited per turn?
- Dispel / counter — can defenders nullify field magic?
