# 100% Orange Juice — Research Notes

## Overview

**100% Orange Juice** is a 2D anime-styled digital multiplayer board game developed by the Japanese doujin circle **Orange_Juice** and published in the West by **Fruitbat Factory**. The Steam release landed on **September 10, 2013** (commonly cited as 2014 due to its real popularity surge after early DLC waves). It is a crossover party-RPG that brings together characters from Orange_Juice's prior shooters — *Flying Red Barrel*, *QP Shooting*, *Suguri*, and *Sora* — alongside dozens of original mascots, all duking it out on dice-driven game boards. The game is widely regarded as a Mario-Party-meets-Dokapon spiritual cousin and is one of the most-played indie board games on Steam.

Steam reviews sit at **94% positive across ~8,683 reviews** with ~33,735 community-hub followers, indicating an unusually loyal player base for a niche indie title ([Steam](https://store.steampowered.com/app/282800/100_Orange_Juice/)).

## Core Loop & Movement

Each match supports up to **4 players** (online, LAN, hot-seat, or vs CPU). On their turn a player **rolls a six-sided die** to move along a board built from interconnected **panels** (the wiki uses "panels" rather than hexes — boards are graph-shaped, not strict hex grids). Boards range from roughly **36 to 80+ panels**, and each has a unique layout, theme, and gimmick (one-way arrows, warps, ice slides, branching paths, etc.) ([Fruitbat](https://fruitbatfactory.com/100orange/)).

### Panel Types

- **Neutral** — nothing happens.
- **Home** — the player's starting/level-up panel; landing here triggers a **Norma check**.
- **Bonus** — gain stars equal to a die-roll × player level.
- **Drop** — lose stars equal to a die-roll × level.
- **Draw** — draw a card from the center deck.
- **Encounter** — fight a wandering NPC enemy ("wild") for stars.
- **Boss** — fight a strong boss when the boss event triggers (usually after a player passes Norma 4).
- **Warp / Move / Heal** and chapter-special panels round out the set ([Wiki - Battle](https://orangejuice.wiki/wiki/Battle)).

## Stats & Combat

Each unit has four core stats (the wiki actually uses **HP / ATK / DEF / EVD**, sometimes written DFC/AVD):

- **HP** — max hit points (typically 3–6).
- **ATK** — attack modifier added to the attack die.
- **DEF** — defense modifier; on a "Defend" choice damage = max(1, attacker_roll − defender_roll).
- **EVD** — evasion modifier; on an "Evade" choice the defender takes 0 damage if their roll exceeds the attacker's, otherwise full damage.
- **REC** (recovery) — die threshold needed to stand up after being KO'd.

Combat is a back-and-forth of d6 rolls plus stat modifiers, with the defender choosing **Defend or Evade** each exchange — a small but elegant decision layer that gives high-EVD glass-cannons (e.g. Suguri) a different feel from tanky DEF units (e.g. Tomomo's HP-stack) ([Wiki](https://orangejuice.wiki/wiki/Battle)).

## Cards & Hyper Cards

Players hold a hand of cards drawn from a shared **center deck**. Cards come in five types: **Battle, Boost, Event, Gift, Trap**. Trap cards are placed face-down on panels; events fire globally; boosts buff a unit; gifts are stars/items.

The signature mechanic is the **Hyper card**: each character has a **personal Hyper** that exists as 8 "blank" slots in the center deck and resolves into that character's unique card when drawn. Hypers are character-defining ultimates — e.g. Suguri's *Accelerator* (re-roll movement), QP's *Hyper Mode* (ATK buff + heal), Marie Poppo's *Mimyuu's Hammer* (random target damage). There are **~122 Hyper cards** game-wide ([Fandom — Hypers](https://100orangejuice.fandom.com/wiki/Category:Hyper_cards)).

## Win Condition: Norma

Victory is gated by the **Norma system**, a 5-step level ladder culminating at level 6:

| Norma | Stars goal | Wins (KO) goal |
|-------|------------|----------------|
| 1 | 10 | 1 |
| 2 | 30 | 2 |
| 3 | 70 | 5 |
| 4 | 120 | 9 |
| 5 | 200 | 14 |

On level-up the player **chooses one of two tracks** — **Star Norma** (collect stars) or **Wins Norma** (rack up KOs of opponents/wilds). Tracks can be switched at each level. To level up the player must pass through their **Home panel** (with an exact roll, or by surviving a battle there) and trigger a Norma check; if their objective is met they level. The first player to clear Norma 5 and reach **Norma Level 6** wins immediately ([Fandom — Norma](https://100orangejuice.fandom.com/wiki/Norma)).

This dual-track condition is the design's masterstroke: it keeps brawler builds and economic builds both viable, and it disincentivizes a single dominant strategy mid-match because trailing players can flip to wins-Norma and farm the leader.

## Roster & Expansions

The roster is **~95 playable units** (21 base, 68 via paid DLC, 6 cross-promo bonuses) plus 9 limited-time event characters. The DLC model is unusually generous: most character packs come in pairs of two units with their Hypers, voices, and sometimes new boards or campaigns. **45+ DLC packs** plus card packs, music packs, voice packs, and cosmetic packs are on Steam — packs continue shipping regularly through 2025–2026 (Extracurricular Pack July 2025; Mimomo/Kurie pack March 2026) ([Wiki — DLC](https://orangejuice.wiki/wiki/Downloadable_Content)).

The game also includes **4 single-player campaigns** that double as character unlock paths and tutorials.

## Cross-Promotional Crossovers

Orange_Juice / Fruitbat Factory aggressively cross-promote their own catalog: owning **Acceleration of SUGURI 2**, **QP Shooting**, **Sora**, **Flying Red Barrel**, or **200% Mixed Juice** on Steam unlocks free bonus characters in 100% OJ (e.g. owning AoS2 unlocks **Suguri (Ver.2)**) ([Fandom — Suguri V2](https://100orangejuice.fandom.com/wiki/Suguri_(Ver.2))). The game has also done licensed character collabs with other indie titles (Re;Lord, Xmas Shooting, etc.), and a robust modding community produces total-conversion mods like *100% Touhou Juice* ([Steam Modding](https://steamcommunity.com/app/282800/discussions/3/2250056952665123615/)).

## Multiplayer & Session Length

There is **no skill-based matchmaking** — players use a **lobby browser** (rooms hold 4 players + 4 spectators). The dev rationale: outcomes are luck-heavy enough that level-1s and level-100s play comparably, so SBMM would add friction without value ([Wiki — Multiplayer](https://orangejuice.wiki/wiki/Multiplayer)).

**Average online match length: ~25–45 minutes**, with some matches running over an hour on larger boards. This is a deliberate sweet spot — long enough for comeback dynamics, short enough for "one more round" sessions ([Steam discussion](https://steamcommunity.com/app/282800/discussions/0/1489992080523300140/)).

## Popularity & Sales Indicators

- All-time peak concurrent: **~5,486 players (May 18, 2024)**.
- 30-day average around **~250 concurrent** in 2026 (typical for a 13-year-old niche indie).
- Aggressive seasonal sales (often -85% to -86%) and a deep-discount DLC model.
- **94% positive reviews / ~8,683 reviews** ([SteamDB](https://steamdb.info/app/282800/), [SteamCharts](https://steamcharts.com/app/282800)).

Exact lifetime unit sales are not publicly disclosed; SteamSpy/VG Insights estimates put owners well into six figures, with the bulk of revenue generated through the long-tail DLC catalog rather than the (very cheap) base game.

## Why It Succeeded

1. **Cute, low-stakes, dice-luck-forward** — friend-group party game that doesn't punish skill gaps.
2. **Norma's dual win-track** — fixes the runaway-leader problem that plagues Mario Party / Dokapon clones.
3. **Hyper cards as identity** — cheap way to make 95 characters feel mechanically distinct.
4. **Generous cross-promotion** — owning any other Orange_Juice game is rewarded inside 100% OJ.
5. **Long-tail DLC + free events** — Christmas, Halloween, anniversary events with limited characters keep the base coming back for over a decade.
6. **Cheap base price** — the game is frequently bundled and sometimes even given as part of "free to own" Fruitbat promos.

## Sources

- [Steam — 100% Orange Juice](https://store.steampowered.com/app/282800/100_Orange_Juice/)
- [Fruitbat Factory — Game page](https://fruitbatfactory.com/100orange/)
- [Official Wiki — Battle / Stats](https://orangejuice.wiki/wiki/Battle)
- [Fandom Wiki — Norma](https://100orangejuice.fandom.com/wiki/Norma)
- [Official Wiki — Downloadable Content](https://orangejuice.wiki/wiki/Downloadable_Content)
- [Fandom — Hyper Cards Category](https://100orangejuice.fandom.com/wiki/Category:Hyper_cards)
- [Fandom — Multiplayer](https://100orangejuice.fandom.com/wiki/Multiplayer)
- [SteamDB — App 282800](https://steamdb.info/app/282800/)
- [SteamCharts — App 282800](https://steamcharts.com/app/282800)
- [The Experiment — 2025 Character Tier Guide](https://md-eksperiment.org/en/post/20251219-100-orange-juice-characters-ranked-base-roster-stats-dlc-unlocks-and-beginner-builds)
- [Steam Discussion — Match length](https://steamcommunity.com/app/282800/discussions/0/1489992080523300140/)
- [Fandom — Suguri (Ver.2) cross-promo unlock](https://100orangejuice.fandom.com/wiki/Suguri_(Ver.2))
