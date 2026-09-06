# Dice

Dice are the movement engine. Players collect them, equip a subset to a loadout, and roll the loadout each turn. Movement = sum of numeric faces rolled.

> Dokapon reference: Dokapon uses a single 1–6 spinner with item/skill modifiers. We expand it into a collectible-equipment system — same ceiling (~30) at peak, more identity along the way. Source: `../../sources/dokapon-core-loop/notes.md`.

## Core rules

- **Pure number generators.** Dice faces are numbers only. No event triggers, no effect symbols, no movement modifiers from the roll itself.
- **Permanent starter die + collected dice on top.** Every player has one indestructible class-specific starter die that can never be lost or broken.
- **Active loadout.** Players equip a subset of their collection up to their **active slot cap**. The roll is the sum of all dice in the active loadout.
- **Loadout swap is free** during the active player's own turn (see [`movement.md`](movement.md)).
- **Special dice are destroyed on break.** No repair. Once a die breaks, it is gone — players replace it by acquiring a new one.

## The starter die

- **One per player, indestructible.** Always part of the collection.
- **Class-dependent.** Each class has its own starter die — different face values reflecting class identity. Specifics in [`../characters/jobs.md`](../characters/jobs.md).
- **Starter occupies an active slot like any other die.** Players may slot it or replace it with a stronger die for the turn.
- **Cannot be sold, traded, discarded, or destroyed.**
- **Does not count against dice inventory capacity.**

## Standard tiers

Freely available (shops, treasure, drops). All permanent — they do not break.

| Die | Range | Notes |
|---|---|---|
| D4 | 1–4 | Cheap, low-variance. Reliable for short hops. |
| D6 | 1–6 | Workhorse. Default tier. |
| D8 | 1–8 | Higher ceiling, slightly less reliable. |

## Special / rare tiers

Acquired through quests, boss drops, treasure spaces, or rare shop stock. **All special dice can break — and breaking destroys them permanently.**

| Die | Range | Per-roll break chance (target) | Notes |
|---|---|---|---|
| D10 | 1–10 | ~5% | Breaks occasionally. |
| D12 | 1–12 | ~12% | Breaks regularly. |
| Class die | varies | varies | Class-restricted, distinctive distributions. |
| Unique / boss die | varies | varies | One-of-a-kind drops. Named. Rare. |

Break chances are tuning targets, not final.

### Breaking

- A broken die is **removed from the inventory permanently.** Destroyed, not repairable.
- Players replace broken dice by acquiring new ones from the world (see "Acquiring dice").
- The **starter die never breaks.** It is the only guaranteed die a player will always have access to.

This makes special dice genuinely consumable. High-tier dice are powerful but ephemeral. Players who hoard D12s for "important turns" face a real choice: use them now, or wait and risk never having the chance.

## Active slot count (dice rolled per turn)

The number of dice a player can roll each turn.

- **Base slots: class-dependent.** Warrior 2 / Mage 2 / Thief 3 (full per-class spec in [`../characters/jobs.md`](../characters/jobs.md)).
- **+1 slot per mastered job.** Stacks with class base (cross-ref [`../characters/mastery.md`](../characters/mastery.md)).
- **Hard cap: 5 slots** — except **Phantom** (Thief-tree special), whose class bonus raises the cap to **6**.

Peak movement ceiling: 5 × D8 = **40** for most builds; 6 × D8 = **48** for Phantom. Comparable to Dokapon's stacked spinner maximum.

## Dice inventory (collection capacity)

How many dice a player can carry total — separate from how many they can roll per turn.

- **Class-dependent, fixed by current class.** First-pass values:

| Class | Dice inventory |
|---|---|
| Warrior | 6 |
| Mage | 6 |
| Thief | 9 |
| Acrobat (advanced) | 15 (+6 vs Thief base) — collection king |
| Phantom (special) | inherits Acrobat or higher (TBD) |
| Other advanced | inherit primary prerequisite's value unless overridden |

- **Inventory does NOT grow with character level or mastery.** It is set entirely by current class.
- **Switching to a class with smaller inventory** forces players to sell, discard, or refuse-on-pickup excess dice.
- **The starter die does NOT count against inventory capacity.**

This makes class choice a real movement-build decision. Dice-heavy players gravitate toward Thief and especially Acrobat (build flexibility) or Phantom (peak roller); bruisers stay Warrior. Class-cycling for mastery may temporarily change inventory size — a budget consideration when planning job changes.

**Acrobat vs Phantom identity split:** Acrobat is the *collection king* — biggest dice inventory (15), more loadouts to swap between, more raw build variety. Phantom is the *peak roller* — only class that breaks the 5-slot cap (rolls 6 dice per turn), highest mid-roll movement. Each has its own appeal; both lineages reward dice-focused play.

## Acquiring dice

Six sources, each with its own pacing and tier weighting. The mix is what shapes early/mid/late game movement.

| Source | Notes |
|---|---|
| **Shops** | Towns sell standard dice (D4/D6/D8). Some towns may stock special tiers (D10/D12) or unique dice. Stock varies by town and progression. |
| **Treasure spaces** | Random reward from a tier-weighted pool. Higher-tier zones drop better dice. |
| **Boss drops** | Story / chapter bosses drop unique or class-locked dice as guaranteed rewards. |
| **Monster drops** | Occasional low-chance drops from regular monster encounters. |
| **Quest rewards** | Specific dice as fixed rewards for completing quests. |
| **Town rewards** | Liberating a town can grant a town-specific die or dice voucher. |
| **PvP loot** | Defeating another player can yield one of their dice (see "PvP dice loot"). |

Specific drop tables, shop stock, and reward dice live in:
- [`../towns/`](../towns/) — town shop stock and liberation rewards
- `../world/world-objects.md` (planned) — treasure space tables
- `../world/monsters.md` (planned) — drop chances

## PvP dice loot

When a player defeats another in PvP combat, the winner may steal one die from the loser. Specifics:

- **Winner's choice or random?** TBD — see `../combat/pvp-rules.md` (planned).
- **Equipped only or from full collection?** TBD.
- **Starter die exempt** — the starter die cannot be looted.
- **If loser's inventory is empty (only starter)** — no loot.

This adds a player-routed griefing/comeback vector: trailing players can hunt leaders for their good dice, and leaders must protect their loadouts.

## Selling and discarding dice

- **Sell at shops** — gold value scales with tier (D4 cheap, unique dice expensive). Sell value is a fraction of buy value (curve TBD).
- **Discard freely** — at any time, no cost. Removes from inventory.
- **Starter die cannot be sold or discarded.**

## What this opens up

- **Collection builds** — Thief / Acrobat with a full inventory of varied dice. Acrobat's 15-slot inventory enables swapping between speed/safe/volatile loadouts mid-match.
- **Peak roller builds** — Phantom uses the only cap-6 active slot count to push max movement per turn (6 × D8 = 48). Late-game milestone build.
- **Reliable builds** — Warrior with D4/D6/D6 — predictable mid-roll, no break chance, low maintenance.
- **Volatile builds** — heavy D10/D12 → high ceiling but real risk of permanent loss. Player-routed risk-taking; the "fair" form of catch-up.
- **Hoarder builds** — Mage with smaller dice inventory but more book/magic focus; rolls 2 dice per turn average and spends the rest of their economy on magic.
- **Loot-economy plays** — hunting opponents for their dice can be more valuable than chasing their gold or items.

## Dokapon-reference deltas

| Decision | Dokapon | Dice RPG |
|---|---|---|
| Roll mechanic | Single spinner 1–6 | Multi-dice loadout, sum |
| Modifier source | Items, skills, magic | Loadout + items + skills + magic |
| Collection meta | None — spinner is fixed | Collect dice, equip loadout, manage class-bound inventory |
| Risk on roll | None inherent | Special dice destroyed on break (no repair) |
| Mastery payoff | +1 stat/level forever | Same + 1 active slot per mastered job (cap 5, or 6 for Phantom) |
| Speed builds | Acrobat skill, items | Class-driven (Thief / Acrobat / Phantom) + loadout |
| Dice loot | N/A | Winner can steal a die on PvP defeat |

## Open questions

- **Advanced class dice values.** Each advanced class needs concrete active-slot base + dice inventory size (Acrobat is the only one specified).
- **Advanced class starter dice.** Currently only the 3 starters have unique starter dice. Should advanced classes also have their own?
- **Break chance tuning.** Target rates are placeholders.
- **Tier acquisition rates.** Drop tables across shops/treasure/quests need cross-balanced tuning.
- **PvP dice loot specifics.** Winner's choice vs random, equipped vs full collection.
- **Trading dice between players.** Allowed? Not yet decided.
- **Sell-value curve.** Fraction of buy value, or close to parity?
- **Class-die loot rules.** When defeating a player whose loadout is class-restricted, can the looter take a class-locked die they cannot use? (Probably yes, to discard or sell.)
