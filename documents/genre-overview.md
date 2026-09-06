# Dokapon-likes: Genre Overview

A synthesis of prior art for the Dice RPG project. Detailed source notes per topic live under `../sources/<topic>/notes.md`; this document is the curated summary.

---

## 1. What "Dokapon-like" means

A **board-game RPG hybrid** for 2–4 players built around four pillars:

1. **Dice/spinner movement on a shared map** of node-and-edge spaces (not a hex grid in most cases — it's a graph of panels).
2. **Persistent character growth** — levels, stats, equipment, jobs/classes, magic — that carries between turns and accumulates across the whole match.
3. **Direct or indirect player-vs-player interaction** — combat, theft, sabotage, market manipulation, curses — so other players are obstacles, not just scoreboard rivals.
4. **An asset/score win condition** — net worth, total currency, property value — measured at a hard finish line (turn limit) or unbounded sandbox.

The defining tension is **schadenfreude**: every player's progress is at constant risk from luck and from the other players. This produces emergent narrative, dramatic reversals, and the "friendship-ending game" reputation the entire genre shares.

Sources: `dokapon-core-loop/`, `design-patterns/`.

---

## 2. The canonical reference: Dokapon Kingdom

Released 2007 (PS2) / 2008 (Wii, Atlus USA) / 2023 (Switch+PC, *Dokapon Kingdom Connect*). Developed by **Sting Entertainment**, building on the 1993 Super Famicom original *Dokapon!* and its 1994 follow-up *Dokapon 3-2-1*.

**Core loop** (one "day"):
- Spin a die → pick a direction at branch nodes → resolve the destination space (battle / town / store / bank / loot-roulette / event / trap).
- 7 days = 1 week. Story Mode = prologue + 8 chapters across 7 continents (~20–30 h). Normal Mode = sandbox 1–99 weeks.
- Win condition: highest **Net Worth** (Normal) or most **Cash G** (Story). Towns and castles dominate scoring; gifting **Local Items** to the King is the high-multiplier flex.

**Combat** is a simultaneous-reveal RPS:
- Attacker chooses *Attack / Strike / Magic / Skill / Give Up*.
- Defender chooses *Defend / Counter / Defensive Magic / Give Up*.
- Roles swap each round. Stats: HP, AT, DF, MG, SP. Strike formula `(AT+MG+SP)×2.5 − (DF+MG+SP)`; Counter `D×4 + A×2`. Accuracy clamped 50–100% from SP delta.

**Progression has two tracks:**
- Character level (1–99, EXP curve ~2.63M).
- Job level (1–6, mastery). 12 jobs branch from Warrior/Magician/Thief into advanced classes (Spellsword, Cleric, Ninja, Robo Knight, Acrobat, Alchemist, Monk, Hero) plus the Darkling. **Mastering a job grants +1 stat/level forever**, so cycling jobs is mathematically dominant — this is the dominant meta-progression.

**Economy & griefing toolkit:**
- Liberate towns by killing their monsters → tax them at Bank Spaces → invest at 32× current income → income doubles at Lv 3, triples at Lv 6 → towns produce Local Items.
- Iconic items (Dokapon Ring, Acro Ring, Devil Backup, Sweet Syrup, Trap, Spinner, Vacuum, Mix-up) and field magic make over-the-board sabotage central to the experience.

**Catch-up: the Darkling.** When a player finishes last enough times, they surrender everything for 14 days as the Darkling: overpowered stats and the ability to steal towns/castles by landing on them. This is a **player-routed** rubber-band that keeps the loser engaged without artificially nerfing the leader.

Source: `dokapon-core-loop/`, `dokapon-combat/`, `dokapon-jobs/`, `dokapon-items-economy/`, `dokapon-franchise/`.

---

## 3. Adjacent franchises

### Itadaki Street / Fortune Street (Square Enix, 1991–2017)
Yuji Horii's economic-board cousin to Dokapon. Buy shops in districts, collect district suits for a salary boost on returning to the bank, **trade stocks whose dividends pay out from rivals' sales** — the indirect-interaction layer. Win condition: hit a target net worth and return to the bank. Crossover entries with DQ + FF + Mario; the 2011 Wii **Fortune Street / Boom Street** is the only Western console release. 2–3+ hour sessions, "friendship-ending" reputation. Source: `itadaki-street/`.

### Momotaro Dentetsu (Hudson 1988 → Konami 2012, ongoing)
Japan's juggernaut — *Showa, Heisei, Reiwa mo Teiban!* (Switch, 2020) shipped 4M+ and outsold Animal Crossing on Japanese charts. Train-themed: ride between Japanese cities, buy regional property, win by accumulating net worth. **Bombii** is the load-bearing griefing mechanic: when a player hits the rotating goal city, the player furthest away gets cursed (escalating Mini → Big → King Bombii, which sells your properties and plants time-bomb cards). The first English support landed only in Dec 2024 (Asia Edition). Cultural specificity (real JR map, regional foods) is why it never crossed to the West. Source: `momotaro-dentetsu/`.

### Culdcept (Omiya Soft, 1997 → 2017, revival 2026)
Card-game/board hybrid: Monopoly-shaped board, but each territory is held by a **creature summoned from your 50-card deck**, and combat is creature-stat math with item-card modifiers. Four elements (Fire/Water/Earth/Air) drive territory bonuses; multi-tile monocolor stacking is the strategic core. Single currency Magic = both resource and victory metric. Cult following, "Best Game No One Played" reputation, ~28k JP for *Saga* (360). New entry *Culdcept Begins* announced for July 2026. Source: `culdcept/`.

### Mario Party (Nintendo, 1998–present)
The party-board genre's mainstream face in the West. Trades RPG persistence for **minigame variety** between turns; coins → stars; sessions are bounded (~30–90 min). MP9–10's car-mode misstep, then *Superstars* (2021) and *Jamboree* (2024) restored the formula with online play and Pro Rules. Different flavor of "anti-friendship": luck-driven, resetting, no persistent power → grievances are short-lived. Source: `mario-party/`.

### 100% Orange Juice (Orange_Juice / Fruitbat Factory, 2014)
The successful indie spiritual cousin. 4-player digital board on Steam, 25–45 min sessions, 94% positive across 8.6k reviews, peak 5.5k CCU; long-tail DLC model (45+ packs). Standout mechanic: **Norma dual-track win condition** — every level-up players choose Star-Norma (economic) or Wins-Norma (combat KOs) and can flip tracks. This directly answers the runaway-leader problem: trailing players pivot to hunting the leader. Hyper cards (one signature card per character) give a 95+ roster identity at low design cost. Source: `100-orange-juice/`.

### Other clones and the open Western niche
- **VIractal: World of Viractalia** (Sting, EA Sept 2025, full release Jan 2026, "Very Positive" 89%) — Sting's own spiritual successor; shifts the genre to procedural co-op rather than PvP-griefing. Highest-priority deep-dive (see `sources/other-clones/leads-to-investigate.md`).
- **Billion Road** (Bandai Namco, 2019) — modern Momotetsu-like, delisted from Steam Sept 2024 (licensing).
- **Talisman Digital 5th Edition** — closest active Western precedent.
- **Korean mobile**: Game of Dice (JOYCITY; Steam port Dec 2025), Lord of Dice, Disney Magical Dice (shut down 2018).
- **Adjacent-but-not-the-same**: Dicey Dungeons, Slice & Dice, Astrea (dice-RPG combat without the multiplayer board); Pummel Party (Mario-Party-with-griefing without RPG persistence).

**Key gap: no Western indie has shipped the full board + RPG + PvP combo at a modern session length.** Source: `other-clones/`.

---

## 4. Mechanics that recur across the genre

| Pattern | Dokapon | Itadaki | Momotetsu | Culdcept | OJ | Mario Party |
|---|---|---|---|---|---|---|
| Dice/spinner movement | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Branching board paths | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Persistent stats/levels | ✓ | — | — | ✓(deck) | ✓ | — |
| Direct PvP combat | ✓ | — | — | ✓ | ✓ | minigame only |
| Property / territory ownership | ✓ | ✓ | ✓ | ✓ | — | — |
| Currency = score | ✓ | ✓ | ✓ | ✓ | partial | partial |
| Player-routed griefing | ✓ | ✓ stocks | ✓ Bombii | ✓ invasion | ✓ | items only |
| Catch-up / rubber-band | ✓ Darkling | suits/dividends | rotating goal | — | Norma flip | bonus stars |
| Hard turn limit | optional | ✓ | ✓ | ✓ Magic target | ✓ Norma | ✓ |
| Local + online | both | mixed | local mostly | both | online-first | both |
| Session length | 8–25h (Story) | 2–3h | 30 min – 30h | 1–2h | 25–45 min | 30–90 min |

---

## 5. What makes the genre *work*

From the design-patterns review (`design-patterns/notes.md`):

- **Schadenfreude as a feature, not a bug.** The fun is watching others fall and surviving your own falls. Every system is a story-generator.
- **Emergent narrative.** Persistent state + PvP + RNG yields anecdotes that survive the session — the "remember when" effect.
- **Comeback tension > comeback guarantees.** Players accept losing to a comeback if it was *earned* by another player's action; they resent comebacks delivered by the system (Mario Party bonus stars, end-of-race AI rubber-banding).
- **Low skill floor + high randomness** keeps the table mixed (kids beat adults, novices beat veterans), which is the social premise.
- **Defacement and identity tools** (renaming, mocking emotes, taunt animations) compound the social element — players consistently single these out in praise.

## 6. The chronic problems

- **Session length.** 8–25 h (Dokapon Story), 2–3 h (Itadaki) is a hard sell to modern multiplayer audiences. Critic scores cluster at 70–73 even where players score 87–94%.
- **Single-player tedium.** AI is the universal weakness; bots cheat or feel disconnected from the social premise.
- **Opaque mechanics.** Damage formulas, magic resists, stat caps, and class-balance numbers are typically hidden. Community calculators and FAQs do the work the game refuses to.
- **Pacing on a per-turn basis.** Animations, dialog speed, watching opponents' turns. Mario Party Superstars' speed-up options are the modern baseline.
- **System-routed catch-up.** Rubber-band that the system imposes feels unfair; rubber-band that another *player* opts into (Darkling, Bombii transfer, Wanted bounties, Norma flip) feels fair.
- **Snowballing leaders** when no catch-up tool exists.
- **Local-vs-online split.** No major entry has shipped a single lobby that mixes local and online players. DK Connect's online netcode was the most-praised improvement of 2023.

## 7. Lessons for the Dice RPG project

1. **Compress the session.** Aim for the 60–90 minute roguelike-Dokapon nobody has shipped. Bounded turn count, fast animations, optional skip.
2. **Online-first, local-compatible.** Ship netcode at parity with local play. Mixed lobbies are the moat.
3. **Catch-up has to be player-routed.** Bounty/wanted systems, transferable curses, dual-track Norma-style win conditions, the Darkling pattern. Avoid "the system gave the loser free stuff."
4. **Persistent power is the genre's defensible moat against Mario Party.** Lean into it; don't sand it off.
5. **Class/job mastery is a dominant meta-progression hook.** Dokapon's "+1/level forever" rewards experimentation without forcing optimality.
6. **Variety floor matters.** Mario Party invests in minigames; Dokapon invests in items, classes, and event spaces. Pick one and over-deliver.
7. **Identity tools are cheap and high-impact.** Rename targets, taunt, hyper cards (one signature card per character) deliver roster diversity at low design cost.
8. **Show the math.** Modern players expect transparency in damage/odds/economic returns. The opacity in DK Connect is the largest reviewer complaint.
9. **Single-player is the AI problem.** Either solve it well or be honest that the game is designed for human opponents and lean into asynchronous/online modes.
10. **Defacement and emergent narrative > balanced fairness.** When in doubt, optimize for the story players will tell after the match, not for tournament integrity.

---

## 8. Source map

| Topic | Folder under `sources/` |
|---|---|
| Dokapon core loop & board | `dokapon-core-loop/` |
| Dokapon combat | `dokapon-combat/` |
| Dokapon jobs/classes | `dokapon-jobs/` |
| Dokapon items & economy | `dokapon-items-economy/` |
| Dokapon franchise history | `dokapon-franchise/` |
| Itadaki Street / Fortune Street | `itadaki-street/` |
| Momotaro Dentetsu | `momotaro-dentetsu/` |
| Culdcept | `culdcept/` |
| 100% Orange Juice | `100-orange-juice/` |
| Mario Party comparison | `mario-party/` |
| Other clones / VIractal / mobile | `other-clones/` |
| Design patterns & reception | `design-patterns/` |

Each folder contains a cited `notes.md` and, where relevant, supporting files (formulas, class lists, entries tables, leads to investigate).
