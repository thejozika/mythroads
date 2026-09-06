# Inventory

Four independent inventory pools: **Dice**, **Items**, **Potions**, **Magic Books**. Slot counts are class-weighted and (for non-dice pools) grow with progression.

> Dokapon reference: Dokapon uses one combined item inventory plus equipped magic-book slots. We split into four pools to give each type its own pressure and tie pool sizes into class identity. Source: `../../sources/dokapon-items-economy/notes.md`.

## The four categories

| Category | Contains | Use |
|---|---|---|
| **Dice** | Collected movement dice | Equipped to the active loadout for rolling. Canonical home: [`../board/dice.md`](../board/dice.md). |
| **Items** | Field-action items (Trap, Spinner, Vacuum, Sweet Syrup, Mix-up, Charm, etc.) | Played on the board on your turn, or used between turns. See [`../items/overview.md`](../items/overview.md). |
| **Potions** | Consumables (HP/MP recovery, status cure, buffs) | Used in or out of combat for self-effect. |
| **Magic Books** | Spell containers | Cast directly from inventory — no separate "equipped" book slot. See [`../magic/overview.md`](../magic/overview.md). |

**Equipment is NOT inventory.** Worn gear (helmet, gloves, body, shoes, 2 rings, necklace, L-hand, R-hand) lives in equipment slots only. Equipment cannot be stored — pickups must be equipped immediately or dropped. See [`../equipment/overview.md`](../equipment/overview.md).

## Class-weighted starting slots — full draft (all 15 classes)

First-pass values per class (tuning targets, not final). Dice canonical home is [`../board/dice.md`](../board/dice.md); shown here as a 4th column for reference.

| Class | Dice | Items | Potions | Books | Non-dice total |
|---|---|---|---|---|---|
| **Warrior** | 6 | 4 | 4 | 2 | 10 |
| **Mage** | 6 | 3 | 3 | 4 | 10 |
| **Thief** | 9 | 5 | 3 | 2 | 10 |
| **Knight** | 6 | 3 | 5 | 2 | 10 |
| **Berserker** | 6 | 4 | 5 | 1 | 10 |
| **Cleric** | 6 | 3 | 4 | 4 | 11 |
| **Sorcerer** | 6 | 2 | 3 | 5 | 10 |
| **Ninja** | 9 | 5 | 3 | 2 | 10 |
| **Acrobat** | 15 | 5 | 3 | 2 | 10 |
| **Spellsword** (W+M) | 6 | 4 | 4 | 3 | 11 |
| **Sage** (M+T) | 7 | 3 | 3 | 4 | 10 |
| **Alchemist** (T+W) | 7 | 4 | 5 | 3 | 12 |
| **Templar** (W special) | 6 | 4 | 4 | 3 | 11 |
| **Mystic** (M special) | 6 | 3 | 4 | 5 | 12 |
| **Phantom** (T special) | 15 | 5 | 4 | 3 | 12 |

Class identity at a glance:
- **Warrior tree** — balanced potions, low books. Knight = potion-heavy. Berserker = potion-rich, magic-poor. Templar = balanced.
- **Mage tree** — book-heavy across the line. Sorcerer = pure magic, item-poor. Mystic = peak magic carrier (5 books).
- **Thief tree** — item-heavy (sabotage tools), low books. Acrobat = peak dice (15). Phantom = peak dice + balanced support.
- **Hybrids** — interpolate between parents. Alchemist gets bonus potion slots (potion-as-weapon flavor).

## Slot growth

Two growth sources:

1. **Per character level** — every **5 levels**, +1 slot to one category. Allocation is class-defined (see per-class profile in [`jobs.md`](jobs.md)) — players don't pick.
2. **Per mastered job** — +1 slot to one category, **player-chosen** at mastery time (see [`mastery.md`](mastery.md)).

This means a Lv 30, 3-job-mastered character has roughly: starting 10 + (30/5) × 1 = 6 from levels + 3 from mastery = **19 slots total**, vs Lv 1 starting 10. Significant but not infinite.

## Inventory management rules

- **Pickup at cap = choose to discard or skip.** When inventory is full and a new item is offered (treasure space, drop, reward), the player chooses which existing item to drop or whether to refuse the new one.
- **No cross-category overflow.** Full Items pool doesn't spill into Potions.
- **Selling at shops.** Empty unwanted items for gold (see [`../towns/`](../towns/)).
- **Bank deposit.** TBD — does the bank accept item deposits, or is it gold-only? Open question.

## Theft and loss on KO

When a player is KO'd (PvP or PvE), the victor / situation may take items from the inventory:

- **PvP win** — winner steals 1 item from a category of their choice, or the loser drops 1 item per category (rules TBD in [`../combat/pvp-rules.md`](../combat/pvp-rules.md), planned).
- **PvE death** — escalating death penalty (Cherub / Dark Angel / Grim Reaper) may drop items in addition to gold (see [`../meta/death-and-revival.md`](../meta/death-and-revival.md), planned).

Cross-cutting design — do not finalize theft rules here; they belong in PvP and death-penalty specs.

## Worn vs carried magic books

We made a deliberate divergence from Dokapon: **magic books live in inventory, not in an equipment slot.**

- Pro: lets players carry many spells and choose tactically without "rotating" book gear.
- Pro: simplifies the equipment slot system.
- Con: removes the "equipped book gives passive bonus" hook (Dokapon doesn't really do this anyway).
- Con: spells are always available — no "I'm out of fire spells today" tension.

If we want passive-from-equipped-book later, add a single "active book" slot in equipment that grants passives but doesn't gate casting.

## Open questions

- **Slot growth pacing per class.** Currently uniform "+1 every 5 character levels"; could vary by class (Mage gets faster book growth, etc.).
- **Bank deposit for items.** Yes/no, and what's the cost?
- **Stack rules.** Can you carry 3 of the same potion in 1 slot, or does each potion take a slot? Affects slot pressure significantly.
- **Theft details.** Owned by [`../combat/pvp-rules.md`](../combat/pvp-rules.md).
- **Magic book contents.** Each book = 1 spell, or 1 element/category? Owned by [`../magic/overview.md`](../magic/overview.md).
