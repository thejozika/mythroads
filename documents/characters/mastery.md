# Job mastery

Mastering a job is the dominant meta-progression in the game. Mastery bonuses are permanent, stack across all jobs ever mastered, and reward cycling jobs over min-maxing one.

> Dokapon reference: each job has 6 levels; reaching job-level 6 grants +1 stat per character level *forever*. Cycling jobs is mathematically dominant. We keep this exact pattern and add a movement payoff. Source: `../../sources/dokapon-jobs/notes.md`.

## Job level

- Each job has **6 levels**.
- Job level is independent of character level — it's per-job.
- Job XP is gained from any combat while in that job (PvE and PvP).
- Job XP per level: roughly **7 battles for starter jobs, 8 for advanced jobs** as initial tuning targets (Dokapon's pacing).
- Reaching job level 6 in any job = **mastered**. Once mastered, a job stays mastered forever, even after switching away.

## Mastery rewards (per mastered job, permanent)

Every job mastered adds the following to the character forever:

1. **+1 stat per character level.** The player chooses *which* stat each mastery contributes to (or it's fixed per job — see open questions). Compounds with all other mastery bonuses.
2. **+1 active dice slot.** Capped at the active-slot ceiling of 5 (see [`../board/dice.md`](../board/dice.md)).
3. **+1 inventory slot.** Player chooses which category (items / potions / books) to add the slot to (see [`inventory.md`](inventory.md)).

These three rewards are the "mastery package." Any one of them alone would justify cycling; together they make mastery the central progression loop.

## Why cycling matters

A character who masters **3 jobs** at character level 30:

- Has gained **3 × 30 = 90 stat points** from mastery alone (stacked per level since mastery completion). On top of class-base + level growth.
- Has **+3 active dice slots** (so a Warrior with 2 base + 3 mastery = 5, the cap).
- Has **+3 inventory slots** to allocate strategically.

A character who stays in one class to its job-level-6 cap and stops there has only **the first** mastery bonus. Cycling is mathematically dominant.

## Mastery cap considerations

- **Active slots cap at 5.** Mastering more than 4 jobs (3 mastery + 2 base for some classes) gives no further dice-slot benefit. Stat and inventory bonuses still compound.
- **No hard cap on number of mastered jobs.** A long-game player can master all 12 jobs in theory; in practice few will.
- **Character level cap of 50** limits how much the per-level mastery bonuses can accumulate.

## Cross-references

- Stat list: [`stats.md`](stats.md).
- Active dice slots: [`../board/dice.md`](../board/dice.md).
- Inventory categories: [`inventory.md`](inventory.md).
- Character level cap and curve: [`progression.md`](progression.md).

## Open questions

- **Stat selection on mastery.** Two designs:
  - **Player-chosen at mastery time** — flexibility, but optimal-play tax (every mastery picks SP if SP is best).
  - **Fixed per job** — Warrior mastery = +1 AT, Mage mastery = +1 MG, etc. Less flex, more class identity.
  - Hybrid — fixed primary + small player choice.
- **Inventory slot at mastery.** Currently spec'd as +1 player-chosen category. Alternatively: fixed by job (Warrior mastery → +1 potion slot, etc.). Same flex/identity tradeoff.
- **Job XP per battle scaling.** Should it scale with character level, opponent strength, or stay flat?
- **Re-mastering a job for additional reward?** Currently no — mastered is mastered. Could allow a "second mastery" with diminishing reward as a true endgame loop.
