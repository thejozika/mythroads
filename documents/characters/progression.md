# Character progression

How players gain XP and level up. Job-level mastery is a parallel track — see [`mastery.md`](mastery.md).

> Dokapon reference: 99-level cap with a ~2.6M EXP curve, only fully reached in long sandbox sessions. We compress to 50 levels with a moderate curve so character growth tracks the match, not the metagame. Source: `../../sources/dokapon-jobs/notes.md`.

## Level cap

**Cap: 50.** A typical match should see top players reaching the high 30s–mid 40s; 50 is reached only by leaders or in long sessions.

## XP sources

| Source | Yield (relative) |
|---|---|
| Defeating a monster | base unit |
| Defeating a player (PvP) | bonus multiplier |
| Defeating a town's monster (liberation) | high multiplier |
| Boss fights / story bosses | very high |
| Quest rewards | situational |
| Event spaces (lucky XP, festivals) | small |

Exact yields are tuning targets. See [`../combat/`](../combat/) for combat-side XP and [`../towns/liberation.md`](../towns/liberation.md), planned, for town XP.

## EXP curve (sketch)

Moderate curve — early levels fast, mid-game steady, late game slow but reachable.

| Level | Cumulative EXP (target) |
|---|---|
| 1 | 0 |
| 5 | ~500 |
| 10 | ~2,500 |
| 20 | ~10,000 |
| 30 | ~25,000 |
| 40 | ~50,000 |
| 50 | ~100,000 |

Numbers are placeholders — final values pending playtest of typical XP/turn yield.

## Per-level rewards

Every level grants:

- **Automatic stat growth** — class-defined per-level gains (e.g. Warrior +5 HP / +1 AT / +1 DF per level). See [`jobs.md`](jobs.md) for per-class growth profiles.
- **Mastery bonus contribution** — every mastered job adds +1 to a chosen stat each time the character levels (see [`mastery.md`](mastery.md)).

Selected milestone levels grant extra:

- **Skill unlocks** — class-specific battle and field skills (see `skills.md`, planned).
- **Inventory slot growth** — every N levels, +1 slot to one inventory category (see [`inventory.md`](inventory.md)).

## Job vs character level

Two parallel progression tracks — both matter:

- **Character level (1–50)** — all-time identity. Carries through job changes.
- **Job level (1–6)** — per-job. Resets on job change but mastery bonuses are permanent.

A character can be Lv 25 with 3 jobs mastered, or Lv 25 with no jobs mastered. Same level, very different power. Mastery is the dominant axis.

## Open questions

- **Final EXP curve.** Above is a sketch; needs playtest data.
- **Soft level cap?** Should there be diminishing returns past Lv 40 to let lower-level players close gaps in long matches? Currently no.
- **Inventory slot pacing.** +1 slot every 10 character levels? Every 5? Different pacing per category? See [`inventory.md`](inventory.md).
- **XP loss on death.** Dokapon does not reduce XP on KO — only gold/items. Keep this rule.
