# Jobs

The class system. **3 starting jobs, 9 advanced jobs, 3 special "found-on-map" jobs — 15 total.** Class identity is the primary axis of build differentiation alongside dice loadout and equipment.

> Dokapon reference: 12 jobs (3 starters → advanced → Hero/Darkling). We mirror the tree shape but extend with 3 hidden-NPC-locked specials, one per starter tree. Source: `../../sources/dokapon-jobs/notes.md`, `../../sources/dokapon-jobs/class-list.md`.

## Tree

```
                  ┌─── Knight         (Warrior mastered)
                  ├─── Berserker      (Warrior mastered)
   Warrior ───────┼─── Templar        (Knight + Berserker + Spellsword mastered + found on map)
                  │
                  ├─── Spellsword     (Warrior + Mage mastered)
                  │
                  ├─── Cleric         (Mage mastered)
                  ├─── Sorcerer       (Mage mastered)
   Mage    ───────┼─── Mystic         (Cleric + Sorcerer + Sage mastered + found on map)
                  │
                  ├─── Sage           (Mage + Thief mastered)
                  │
                  ├─── Ninja          (Thief mastered)
                  ├─── Acrobat        (Thief mastered)
   Thief   ───────┼─── Phantom        (Ninja + Acrobat + Alchemist mastered + found on map)
                  │
                  └─── Alchemist      (Thief + Warrior mastered)

Hybrid assignment for specials follows a clockwise cycle (Warrior→Mage→Thief→Warrior):
- Templar (Warrior tree) ← Spellsword hybrid (Warrior+Mage)
- Mystic (Mage tree) ← Sage hybrid (Mage+Thief)
- Phantom (Thief tree) ← Alchemist hybrid (Thief+Warrior)
```

- **3 starters** — chosen at character creation, free swap between them at the Jobs Office (see [`../towns/`](../towns/), planned).
- **6 single-prereq advanced** — unlock after mastering one starter + meeting level/stat thresholds at any Jobs Office.
- **3 specials** — unlock after mastering BOTH single-prereq advanced classes from one starter tree, AND finding a hidden NPC somewhere on the map. The pinnacle of each archetype.
- **3 dual-prereq hybrids** — unlock after mastering two starters + thresholds at any Jobs Office.

All names are placeholders pending lore/world pass.

## Starting jobs (specs)

Numbers are first-pass starting values. All values are tuning targets, not final.

### Warrior — physical bruiser

| Field | Value |
|---|---|
| HP / MP / AT / DF / MG / SP (Lv 1) | 60 / 5 / 12 / 10 / 4 / 6 |
| Per-level growth | +6 HP / +0 MP / +2 AT / +2 DF / +0 MG / +1 SP |
| Starter die | "Warrior's Edge" — D6 with steady distribution `[2,3,3,4,4,5]` |
| Active dice slots (base) | 2 |
| Dice inventory (collection capacity) | 6 |
| Item-pool inventory (items/potions/books) | 4 / 4 / 2 |
| Starting battle skill | Cleave — basic AT-scaled attack with bonus vs DF |
| Starting field skill | Forced March — once per week, +N to next move roll |

### Mage — magical glass cannon

| Field | Value |
|---|---|
| HP / MP / AT / DF / MG / SP (Lv 1) | 35 / 20 / 4 / 6 / 14 / 8 |
| Per-level growth | +3 HP / +3 MP / +0 AT / +1 DF / +3 MG / +1 SP |
| Starter die | "Apprentice Tome" — D6 with bipolar distribution `[1,1,2,5,6,6]` |
| Active dice slots (base) | 2 |
| Dice inventory (collection capacity) | 6 |
| Item-pool inventory (items/potions/books) | 3 / 3 / 4 |
| Starting battle skill | Spark — MG-scaled magic attack |
| Starting field skill | Detect — reveal next 3 spaces ahead before committing direction |

### Thief — fast and dirty

| Field | Value |
|---|---|
| HP / MP / AT / DF / MG / SP (Lv 1) | 45 / 10 / 9 / 7 / 8 / 12 |
| Per-level growth | +4 HP / +1 MP / +1 AT / +1 DF / +1 MG / +2 SP |
| Starter die | "Loaded Coin" — D6 with high-variance distribution `[1,1,1,6,6,6]` |
| Active dice slots (base) | 3 |
| Dice inventory (collection capacity) | 9 |
| Item-pool inventory (items/potions/books) | 5 / 3 / 2 |
| Starting battle skill | Backstab — AT-scaled attack with SP-scaled crit chance |
| Starting field skill | Pickpocket — chance to steal 1 item from a player on the same space |

## Advanced jobs (sketch)

Full spec per advanced job lives in `class-list.md` (planned). High-level identities below.

### From Warrior

- **Knight** — defensive specialist. High DF, shield-mastery skills, taunt-style abilities. Prereq: master Warrior + character Lv 12 + DF threshold.
- **Berserker** — offensive specialist. High AT, low DF, rage skills that scale with missing HP. Prereq: master Warrior + character Lv 12 + AT threshold.

### From Mage

- **Cleric** — healer / support. High HP for caster, healing spells, status cures. Prereq: master Mage + character Lv 12 + HP threshold.
- **Sorcerer** — pure offense magic. Highest MG, glass cannon. Prereq: master Mage + character Lv 12 + MG threshold.

### From Thief

- **Ninja** — speed + burst. Highest SP. Crits, evasion, multiple attacks. Prereq: master Thief + character Lv 12 + SP threshold.
- **Acrobat** — dice collection specialist. **Dice inventory +6 over Thief base = 15** — the largest collection capacity in the game. Active slot cap stays at 5; Acrobat's identity is **build flexibility** (carry many loadouts and swap between them) rather than peak per-turn movement. Likely also gets a quick-swap or build-related field skill. Prereq: master Thief + character Lv 12 + SP threshold.

### Hybrids

- **Spellsword** (Warrior + Mage). Balanced attack/magic. Weapon-spells, hybrid scaling. Prereq: master both + character Lv 20.
- **Sage** (Mage + Thief). MP efficiency, status spells, utility. Prereq: master both + character Lv 20.
- **Alchemist** (Thief + Warrior). Item synergy, gold generation, potion-as-weapon skills. Prereq: master both + character Lv 20.

## Special / found-on-map jobs

Three pinnacle classes that cannot be unlocked at any Jobs Office. Each requires **mastery of BOTH single-prereq advanced classes from the home tree, PLUS mastery of the tree's assigned hybrid, PLUS finding a hidden NPC on the map** (location per class TBD in [`../world/`](../world/)).

Hybrid assignments follow a clockwise cycle: Templar pairs with Spellsword (Warrior+Mage), Mystic with Sage (Mage+Thief), Phantom with Alchemist (Thief+Warrior). Each special is uniquely tied to one hybrid; no overlap.

This is a heavy late-game milestone. To unlock a special, a player must master 5 jobs total — both starters that gate the path, both specializations of the home tree, and the assigned hybrid — then find the NPC.

These are peak-progression specialties — rare, identity-defining, end-of-match power spikes. Players who reach a special class have effectively committed deeply to one archetype.

### From the Warrior tree

- **Templar** — pinnacle martial class. Sacred warrior of an ancient order, combining Knight's defense, Berserker's offense, and Spellsword's martial-magic discipline. Suggested kit: top-tier HP / AT / DF, signature high-impact attack skill, possibly an intimidation or aura field skill. Prereq: master Knight + master Berserker + master Spellsword + find the hidden NPC.

### From the Mage tree

- **Mystic** — pinnacle magical class. Esoteric secret-keeper combining Cleric's support, Sorcerer's offense, and Sage's deep wisdom into a master of all magic. Suggested kit: highest MG, MP-pool bonus, signature high-cost spell, possibly a passive that reduces all spell MP costs. Prereq: master Cleric + master Sorcerer + master Sage + find the hidden NPC.

### From the Thief tree

- **Phantom** — pinnacle agility/dice class. Mythic and intangible, combining Ninja's burst, Acrobat's collection depth, and Alchemist's resourcefulness. **Active dice slot cap raised from 5 to 6** — the only class that breaks the default cap, making Phantom the peak per-turn roller. Likely also gets one additional dice signature (TBD — re-roll, minimum-roll floor, or guaranteed-min-on-one-die). Suggested combat kit: highest SP, signature high-impact movement skill. Prereq: master Ninja + master Acrobat + master Alchemist + find the hidden NPC.

## Job changing

- Players change jobs at the **Jobs Office** in towns (cross-ref [`../towns/overview.md`](../towns/overview.md)).
- Job change cost: gold (curve TBD).
- Switching jobs **resets job level to 1** for the new job (or to existing job level if returning to a previously-played one).
- Mastery bonuses are **permanent** — they don't reset on job change.
- Stats are **recalculated** to reflect the new class base + accumulated mastery bonuses + level growth applied retroactively (TBD: do we apply growth at the new class's rate retroactively, or only forward?).

## Open questions

- **Final stat values per class** — current values are first-pass.
- **Stat values for advanced classes and specials** — unspec'd.
- **Skills per class** — each class needs 2–4 distinct skills (battle + field). See `skills.md`, planned.
- **Job change cost curve** — flat, scaling with character level, or scaling with number of jobs mastered?
- **Retroactive growth on job change** — recalc stats at new class's rate, or only forward gains use new rate?
- **Hidden NPC locations** — where the 3 specials are found. Owned by [`../world/`](../world/).
- **Thief-special dice mechanic** — Acrobat already breaks the slot cap to 6. Does the Thief-special go further (cap 7), or use a different signature (re-roll, minimum-roll-floor)?
- **Darkling-equivalent catch-up class** — separate from this 15-class tree, lives in [`../meta/catch-up.md`](../meta/catch-up.md), planned.
- **Class names** — starters and 9 advanced are placeholders; specials confirmed (Templar, Mystic, Phantom). Full lore pass owned by [`../world/`](../world/).
