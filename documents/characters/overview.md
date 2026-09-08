# Characters

Player characters: how they level up, change jobs, master classes, grow stats, learn skills, and carry their inventory.

## Scope

- **Stats** — HP / AT / DF / MG / Athletics / Agility and where they come from.
- **Character level** — XP curve to Lv 50, what each level grants.
- **Jobs / classes** — 3 starter jobs, 9 advanced jobs, the tree, change requirements.
- **Job mastery** — within-job progression, the permanent bonuses from mastering jobs.
- **Inventory** — three category pools (Items / Potions / Magic Books), class-weighted, growing with progression.
- **Skills** — class-specific battle + field abilities.

## Dokapon reference

Two parallel progression tracks (character level + job level), with mastery as the dominant meta-progression. We mirror the structure (12 jobs total in a 3-starter / 9-advanced tree), keep the +1-stat-per-level-forever mastery payoff, and add two new mastery rewards (+1 active dice slot, +1 inventory slot) to keep dice and inventory tied to the same loop. Character level cap reduced from 99 to 50 for shorter sessions. We avoid MP and split Dokapon's Speed into Athletics and Agility. See `../../sources/dokapon-jobs/notes.md`.

## Files in this folder

- `overview.md` — this file
- [`stats.md`](stats.md) — the 6 stats, sources, caps
- [`progression.md`](progression.md) — character level, XP curve, per-level rewards
- [`jobs.md`](jobs.md) — starter + advanced classes, job tree, per-class specs
- [`mastery.md`](mastery.md) — job-level progression, mastery rewards, cycling logic
- [`inventory.md`](inventory.md) — items / potions / books, class weights, growth
- `skills.md` — battle + field skills per class (planned)
- `class-list.md` — full per-class spec sheet for advanced classes (planned)

## Decisions confirmed

- Stat list: HP / AT / DF / MG / Athletics / Agility (no MP resource).
- Level cap: 50, moderate curve.
- Job count: 3 starters + 9 advanced = 12 total.
- Job tree shape: Dokapon-style with 6 single-prereq + 3 dual-prereq advanced.
- Inventory: 3 categories (Items / Potions / Magic Books), class-weighted, grows with progression.
- Mastery package: +1 stat/level + 1 active dice slot + 1 inventory slot, all permanent.
- Magic books live in inventory, not equipment.

## Open questions

- Stat-allocation choice on level-up — currently automatic; could be player-chosen.
- Stat selection on mastery — player-chosen vs fixed per job.
- Inventory growth pacing per class (uniform vs class-specific).
- Skill set per class (each class needs 2–4 named skills).
- Job change cost curve.
- Stack rules for inventory (1 item per slot vs stackable).
