# Dokapon Kingdom — Combat System Research

Scope: combat-specific mechanics in *Dokapon Kingdom* (Wii) and the modern remaster *Dokapon Kingdom: Connect* (Switch/PC). Both share the same core systems.

---

## 1. Battle Flow & The RPS Mind-Game

A battle is a fixed two-side encounter: one side is the **attacker** (the player who moved into the other), the other is the **defender** (the one who was sat on / approached, including monsters). Each round, the attacker picks one of four offensive options and the defender simultaneously picks one of four defensive options; the choices then resolve against each other. After resolution, roles **swap** and the next round happens, repeating until one side dies, gives up, or both sides survive a fixed number of rounds.

**Attacker options** (Battle Commands, Fandom):
- **Attack** — basic physical hit. Beaten by Defend.
- **Strike** — heavy physical hit. Beaten by Counter (defender returns big damage). Otherwise hits for huge damage regardless of SP.
- **Offensive Magic** — equipped spell. Always hits. Counterable only by Defensive Magic.
- **Battle Skill** — class-learned ability (e.g., Charge, buffs/debuffs). Often replaces a turn but produces unique effects.

**Defender options**:
- **Defend** — reduces physical damage from Attack / Strike.
- **Counter** — only useful vs Strike: reflects huge damage at the attacker. If attacker chose Attack/Magic, defender takes full damage.
- **Defensive Magic** — equipped spell. Reduces magic damage and nullifies the spell's status side-effects; activates the defender's own spell side-effect.
- **Give Up** — surrender. Ends the battle, attacker takes the defender's belongings (gold/items/town claim), but penalty is **less severe** than dying.

The interactions form a soft rock-paper-scissors:

| Attacker \ Defender | Defend | Counter | Defensive Magic |
|---|---|---|---|
| Attack | reduced dmg | full dmg | full dmg |
| Strike | partial reduce | huge backfire on attacker | full Strike dmg |
| Offensive Magic | full magic dmg + status | full magic dmg + status | reduced + status nullified |

[Battle Commands — Dokapon Wiki]; [Battle — Dokapon Wiki]

The depth comes from reading the opponent: a low-HP attacker leaning to Strike vs. a defender suspecting Strike (Counter) creates a real bluff loop.

---

## 2. Stats

Five core stats plus HP. Each stat is a simple integer that comes from **Base + Level-Up + Mastery + Extras + Equipment** (Level Up — Dokapon Wiki).

- **HP** — 1 HP-stat point = 10 actual HP.
- **AT (Attack)** — drives weapon damage.
- **DF (Defense)** — reduces physical damage by ~1.2 per point. Widely considered a "trap stat" — investing in HP gives more durability per point (Steam stats discussion).
- **MG (Magic)** — both magical attack and magical defense; also bonuses field magic damage.
- **SP (Speed)** — accuracy + evasion for physical attacks and field magic; **also feeds into Strike/Counter damage formulas**, making SP arguably the strongest stat in PvP.

Damage and accuracy formulas live in `formulas.md`.

[Damage (Kingdom) — Dokapon Wiki]; [Steam: How exactly do stats help…]; [SP — Dokapon Wiki]

---

## 3. Magic, Books, and Status Effects

### Magic categories
- **Offensive Magic** (battle): equipped like a weapon. Always hits. Most use MG vs MG, but some "physical-type" use AT. Elements include **fire (Scorch), ice (Chill), lightning (Zap), wind (Gust), dark (Rust, Banish, Sleepy), light (Aurora)**.
- **Defensive Magic** (battle): equipped. Counters Offensive Magic and may apply its own buff/effect.
- **Field Magic** (overworld): consumable spells thrown at other players on the board (lightning to damage HP, Trap to set traps, etc.). Field magic accuracy uses SP at ~1% per point.

[Offensive Magic — Dokapon Wiki]; [Field Magic (Kingdom) — Dokapon Wiki]

### Status ailments (battle and overworld)
- **Poison** — loses HP/turn (level-equal damage in Kingdom; 10% max-HP/turn in DX). Won't kill — leaves victim at 1 HP. Persists outside battle.
- **Sleep** — skip actions in battle and on the board; ends on damage or after a few turns.
- **Curse** — randomly attack self in battle.
- **Seal/Lock** — disables Field Magic (and items in Sword of Fury+).
- **Fear** — cannot land on spaces that would force a battle (avoids other players, monster towns). Doesn't block random monster encounters.
- **Z-Plague** — only from Chimpy. Loses HP = 2 × current level / turn. Lethal. Spreads by passing players.
- **Frog** — transformed; recover by visiting a Church / castle.
- **Rock Costume** — item that turns user into an immobile roadblock blocking the tile.
- **Possessed/Haunted** (Sword of Fury / DX) — chance to lose action in battle.
- **Doom / Death Call** — death-by-countdown effects.

[Status Ailment / Kingdom — Dokapon Wiki]; [Sleep, Poison, Curse, Doom — Dokapon Wiki]

---

## 4. Field Skills vs Battle Skills

Both come from **Jobs (classes)**. Job-level rises every 6–7 battles fought; mastery at Job-Level 6 grants permanent stat-points/level retained across class changes (Job — Dokapon Wiki).

- **Battle Skills** — earned at Job-Level 2 and 4. Every job starts with **Charge** (the Job-Level 1 default). Activate as the "Skill" attack option. Effects: damage, self-buffs, debuffs; buffs only persist for that one battle.
- **Field Skills** — class-locked overworld abilities. Examples: Warrior **War Cry** (battle AT buff), Thief **Pickpocket** (steal during board movement), Cleric **Holy Aura** (random HP heal at turn start), Ninja **Item Combo** (use 2 items/turn) and store-rob, Acrobat **Play Dead** (50% revive), Hero **Full Combo** (1 item + 1 field magic same turn).

[Battle Skill (Kingdom)]; [Field Skill (Kingdom)]; supercheats Class Guide.

### Class growths (per level, supercheats Class Guide)
- Warrior: +2 AT / +1 DF / +10 HP — mastery +1 AT
- Magician: +2 MG / +1 SP / +10 HP — mastery +1 MG
- Thief: +1 AT / +2 SP / +10 HP — mastery +1 SP
- Cleric: +1 DF / +1 MG / +20 HP
- Spellsword: +2 AT / +2 MG
- Alchemist: +1 DF / +2 MG / +1 SP
- Ninja: +2 AT / +2 SP
- Monk: +1 AT / +1 DF / +20 HP
- Acrobat: +1 AT / +1 DF / +1 SP / +10 HP
- Robo Knight: +1 AT / +2 DF / +1 SP
- Hero: +1 AT / +1 DF / +1 MG / +1 SP + random extra

Each Job has an affinity for specific weapons (better damage when wielding them).

---

## 5. PvP Encounters

- Triggered by landing on the same tile as another player.
- The mover is the attacker, sitter is the defender. Same RPS battle system.
- Defender may **Give Up** to skip dying — pays a smaller price (some gold/items) but no death-revival countdown.
- Defeating another player lets you steal **gold, items, field magic, and sometimes equipment / town deeds**.
- Thief Steal (Battle Skill, Job-Level 2) reliably nicks an item or field magic.
- Killing players awards XP — but not as much as monsters. (GameFAQs: Getting experience from killing other players)

[Battle — Dokapon Wiki]; [Thief (Kingdom) — Dokapon Wiki]

---

## 6. Monster Encounters & Bosses

- **Normal monsters** — random encounters on empty board spaces. Drop XP, gold, items.
- **Town Bosses** — sit on towns; defeating them transfers town ownership to the player.
- **Big Monsters** — stronger Town Boss variants. Steal gold from towns/players (returned in their drop). On defeat, the tile becomes a **treasure site** owned by the killer; other players pay to dig.
- **Boss Monsters** (Enemy IDs ≥ 119) — Rico Jr., Overlord Rico, Comacho, Wabbit, Wallace, Chimpy, Robo-Sassin; plus Royal-Ring holder and Clonus (story).
- Monsters' **Drop 1** is given when stolen via Thief Steal or Hero Glory; **Drop 2** when they Give Up.

[Monsters], [Big Monster], [Town Boss], [Bestiary (Kingdom)] — Dokapon Wiki.

---

## 7. Death, Penalties, and Revival

When killed, a death angel rolls one of three penalties:
- **Cherubs** (mildest) — 1 turn dead, lose an item or 1/4 of money.
- **Dark-haired Angels** — 2 turns dead, lose half money, several items, or get pranked.
- **Grim Reaper** (worst) — 3 turns dead, may lose all money, all items, equipment, and even an owned **Town**.

Auto-revive after the dead-turn count. **Revival** (item) restores 50% HP automatically on death (in battle or overworld) and clears all status/stat-debuffs. There's no "hospital" — revival is automatic at Dokapon Castle / Church respawn.

[Death — Dokapon Wiki]; [Revival (Kingdom) — Dokapon Wiki].

---

## 8. Critical Hits, Accuracy, RNG

- **Crits** exist for both attacks and guards; effects are amplified. Exact formula not publicly documented.
- **Accuracy** for Attack/Strike: 75% at equal SP; 100% at SP_atk ≥ 3× SP_def; 50% at SP_atk ≤ 1/3 SP_def. Capped 50–100%. Community ±1% per SP-point linear approximation in Connect.
- **Field Magic accuracy** = 60% + atk SP − def SP, clamped 20–100%.
- Damage gets a final ×0.95 or ×1.05 random multiplier (binary roll, no continuous spread).

[Damage Formula — GameFAQs board]; [Steam: dodge calc]; [Damage (Kingdom)]; see `formulas.md`.

---

## 9. What Makes Combat Tactically Interesting in a Board Game

- **Information asymmetry & bluff**: choices are simultaneous & hidden; HP, equipment, and class loadout of the opponent are visible, so players reason about likely choices (low-HP defender → likely Defensive Magic).
- **Role swapping per round** removes "first strike wins" and forces planning two layers deep.
- **Strike–Counter** is a high-variance bluff axis on top of the more predictable Attack/Defend.
- **Magic tier** is a parallel RPS that bypasses SP/RNG accuracy, rewarding equipment investment differently from physical builds.
- **Asymmetric loss** (Give Up vs Death) means sometimes throwing a battle is correct — adds resource-management tension to every encounter.
- **Persistent consequences** (turns dead, lost towns, lost equipment) make every battle outcome ripple into the board game's long economy, not just an HP bar.

---

## Sources
- Dokapon Wiki – Battle Commands: https://dokapon.fandom.com/wiki/Battle_Commands
- Dokapon Wiki – Battle: https://dokapon.fandom.com/wiki/Battle
- Dokapon Wiki – Damage (Kingdom): https://dokapon.fandom.com/wiki/Damage_(Kingdom)
- Dokapon Wiki – Defensive Magic (Kingdom): https://dokapon.fandom.com/wiki/Defensive_Magic_(Kingdom)
- Dokapon Wiki – Offensive Magic (Kingdom): https://dokapon.fandom.com/wiki/Offensive_Magic_(Kingdom)
- Dokapon Wiki – Field Magic (Kingdom): https://dokapon.fandom.com/wiki/Field_Magic_(Kingdom)
- Dokapon Wiki – Battle Skill (Kingdom): https://dokapon.fandom.com/wiki/Battle_Skill_(Kingdom)
- Dokapon Wiki – Field Skill (Kingdom): https://dokapon.fandom.com/wiki/Field_Skill_(Kingdom)
- Dokapon Wiki – Job: https://dokapon.fandom.com/wiki/Job
- Dokapon Wiki – Level Up: https://dokapon.fandom.com/wiki/Level_Up
- Dokapon Wiki – SP: https://dokapon.fandom.com/wiki/SP
- Dokapon Wiki – Status Ailment / Kingdom: https://dokapon.fandom.com/wiki/Status_Ailment/Kingdom
- Dokapon Wiki – Poison: https://dokapon.fandom.com/wiki/Poison
- Dokapon Wiki – Sleep: https://dokapon.fandom.com/wiki/Sleep
- Dokapon Wiki – Curse: https://dokapon.fandom.com/wiki/Curse_(Status_Ailment)
- Dokapon Wiki – Doom: https://dokapon.fandom.com/wiki/Doom
- Dokapon Wiki – Rock Costume: https://dokapon.fandom.com/wiki/Rock_Costume
- Dokapon Wiki – Monsters: https://dokapon.fandom.com/wiki/Monsters
- Dokapon Wiki – Big Monster: https://dokapon.fandom.com/wiki/Big_Monster
- Dokapon Wiki – Town Boss: https://dokapon.fandom.com/wiki/Town_Boss
- Dokapon Wiki – Bestiary (Kingdom): https://dokapon.fandom.com/wiki/Bestiary_(Kingdom)
- Dokapon Wiki – Death: https://dokapon.fandom.com/wiki/Death
- Dokapon Wiki – Revival (Kingdom): https://dokapon.fandom.com/wiki/Revival_(Kingdom)
- Dokapon Wiki – Thief (Kingdom): https://dokapon.fandom.com/wiki/Thief_(Kingdom)
- Dokapon Wiki – Dokapon Kingdom/Strategies: https://dokapon.fandom.com/wiki/Dokapon_Kingdom/Strategies
- GameFAQs board – Damage Formula (Attack, Strike, and Counter): https://gamefaqs.gamespot.com/boards/945683-dokapon-kingdom/74554371
- GameFAQs Class Guide (KainVermillion): https://gamefaqs.gamespot.com/wii/945683-dokapon-kingdom/faqs/54529
- supercheats Class Guide: https://www.supercheats.com/wii/walkthroughs/dokaponkingdom-walkthrough01.txt
- Steam – Missing Manual: https://steamcommunity.com/sharedfiles/filedetails/?id=3032333450
- Steam – How exactly do stats help: https://steamcommunity.com/app/2338140/discussions/0/6553383644009880734/
- Steam – Dodging calculation: https://steamcommunity.com/app/2338140/discussions/0/6194224803801652884/
- Desmos – Dokapon Damage/Accuracy Calculator: https://www.desmos.com/calculator/e7ssnqzwjp
- GitHub – subzero258/Dokapon-Damage-Calculator: https://github.com/subzero258/Dokapon-Damage-Calculator
- TV Tropes – Dokapon Kingdom: https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/DokaponKingdom
- gameplay.tips – Connect General Guide: https://gameplay.tips/guides/dokapon-kingdom-connect-general-guide-stats-character-advancement-basic-gameplay-concepts-etc.html
