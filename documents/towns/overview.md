# Towns

The economic engine of the game: liberate towns from monsters, tax them for income, upgrade them for higher returns, lose them when you're defeated.

## Scope

- **Liberation** — how a player claims a town (defeat its monster, complete a quest, …).
- **Taxation / income** — when and how owned towns pay out, how the bank space ties in.
- **Upgrades / investment** — cost curve, income tiers (Lv 1→3→6 in Dokapon), what each tier unlocks.
- **Local items** — town-specific tradable goods, gifting to NPCs for bonuses.
- **Town damage** — what happens when the owner is defeated near the town.
- **Castles** — the high-tier capital spaces (player castles, neutral castles, the King's castle).
- **Town events** — festivals, quests, calamities.

## Dokapon reference

Liberate towns by defeating their monsters; tax accumulates and is collected at Bank Spaces. Investment cost = **32× current income**, doubling at Lv 3 and tripling at Lv 6. Each town produces a unique **Local Item** worth a multiplier when gifted to the King. The economic loop is the dominant scoring mechanism — a mastered hero earns 2–3M G/week. See `../../sources/dokapon-items-economy/notes.md` and `../../sources/dokapon-core-loop/notes.md`.

## Files in this folder

- `overview.md` — this file
- `liberation.md` — town monsters, liberation conditions (planned)
- `taxation.md` — income formula, bank-space mechanic (planned)
- `upgrades.md` — investment tiers, costs, unlock effects (planned)
- `local-items.md` — town-specific goods, gifting bonuses (planned)
- `castles.md` — castle mechanics, throne-room interactions (planned)
- `town-damage.md` — what happens when an owner loses (planned)

## Open questions

- Town count — how many across the whole map?
- Tax collection — Bank-space-triggered (Dokapon) or automatic per-week?
- Investment curve — keep the 32× income / Lv 1→3→6 jumps, or smooth it?
- Local items — one per town like Dokapon, or shared categories?
- Town stealing on player KO at the town: yes/no, partial?
