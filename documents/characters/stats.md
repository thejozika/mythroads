# Stats

Seven stats define a character's capability in combat and on the board.

> Dokapon reference: Dokapon uses HP / AT / DF / MG / SP with no MP. We add MP and split SP
> into Athletics and Agility so physical power and evasiveness can be tuned independently. Source:
> `../../sources/dokapon-combat/notes.md`.

## The seven stats

| Stat | Name | Role |
|---|---|---|
| **HP** | Hit Points | Damage capacity. Reach 0 → KO. |
| **MP** | Mana Points | Spell-cast resource. Spent per cast. |
| **AT** | Attack | Physical damage output. |
| **DF** | Defense | Physical damage mitigation. |
| **MG** | Magic | Spell damage AND magic-damage mitigation (single combined stat, like Dokapon). |
| **ATH** | Athletics | Committed-technique power, bracing, feats of strength, and physical board checks. |
| **AGI** | Agility | Physical accuracy/evasion, future combat initiative, and finesse board checks. |

## Sources of stat values

A character's current stat = sum of:

1. **Class base** — assigned at job change. Each job has a base stat block (see [`jobs.md`](jobs.md)).
2. **Level growth** — each character level adds class-defined gains (see [`progression.md`](progression.md)).
3. **Mastery bonus** — every mastered job grants +1 chosen stat per character level, *forever* (see [`mastery.md`](mastery.md)).
4. **Equipment** — worn weapons/shields/accessories (see [`../equipment/overview.md`](../equipment/overview.md)).
5. **Permanent items** — stat-up books / shrines from quests (see [`../items/overview.md`](../items/overview.md)).
6. **Status effects** — temporary in-combat or in-week buffs/debuffs.

## Stat caps

- Per-stat hard cap: **999**.
- Soft caps may apply via diminishing returns in damage formulas (see [`../combat/damage-formulas.md`](../combat/damage-formulas.md), planned).

## Stat ↔ system cross-references

- **HP** — combat damage tracking; KO triggers death penalty (see [`../meta/death-and-revival.md`](../meta/death-and-revival.md), planned).
- **MP** — gates spell casting in combat and field magic. Regeneration TBD (see open questions).
- **AT, DF, MG, ATH, AGI** — primary inputs to combat damage and accuracy formulas.
- **ATH** adds power to High Charge, Side Rush, and Leaping Strike, and improves Brace.
- **AGI** changes physical hit chance around a 75% equal-stat baseline, clamped to 50–98%.
- Neither ATH nor AGI directly changes a movement roll. Specific skills or items may grant
  stat-based dice bonuses later.

## Open questions

- **MP regeneration.** Candidates: refill on visiting a town, refill end-of-week, +N per turn (slow regen), item-only, never-refill (one-shot use). Affects how often spells can be cast and balance vs items/potions.
- **Stat-allocation choice on level-up.** Is growth fully automatic per class, or does the player choose to allocate points? Currently spec'd as automatic — keeps pace fast and class identity strong.
- **MG split.** Currently combined offense + defense like Dokapon. Splitting it would expand an
  already readable seven-stat block without adding enough value yet.
- **Diminishing returns curves.** Where do soft caps kick in for AT, DF, MG, ATH, and AGI?
