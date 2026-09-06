# Momotaro Dentetsu (Momotetsu) — Research Notes

Long-running Japanese digital board game series. Players are rail-company presidents racing trains around a map of Japan, buying properties, sabotaging rivals, and trying to become the country's richest tycoon over up to 100 in-game years. Often described as "Monopoly meets sugoroku, with curses." Crucial reference for Dokapon-style design because Momotetsu is the canonical example of a Japanese board-RPG hybrid that thrives on player-vs-player griefing without being a fighting game. ([Wikipedia](https://en.wikipedia.org/wiki/Momotaro_Dentetsu), [Nintendo Life](https://www.nintendolife.com/news/2021/01/feature_hands-on_with_momotaro_dentetsu_the_switch_game_thats_beating_zelda_and_animal_crossing_in_japan))

## Series History

- **1988**: First entry on Famicom by **Hudson Soft**. Spun off from Hudson's RPG *Momotaro Densetsu* (a separate series).
- **1989–1996 (Super era)**: PC Engine and Super Famicom releases formalize the formula. *Super Momotarou Dentetsu III* (1994, SNES) introduces **King Bombii** in its subtitle ("It's King Bombie!!").
- **1997–2008 (PS1/PS2/Wii era, peak Hudson)**: *Momotaro Dentetsu 7* (PS1, 1997) sells 500k+; series total shipments cross **12 million units by 2011**. *Momotaro Dentetsu 11: Black Bombee Shutsugen!* (2002) cements Bombii's iconography.
- **2012**: Konami absorbs Hudson; series enters multi-year hibernation.
- **2016**: *Momotaro Dentetsu 2017: Tachiagare Nippon!!* (3DS) revives the series under Konami, published by Nintendo.
- **2020 — the breakout**: *Momotaro Dentetsu: Showa, Heisei, Reiwa mo Teiban!* (Switch, Nov 19 2020). Adds online multiplayer. Hits **750k by Dec 2020 → 2M Jan 2021 → 3M Jun 2021 → 3.5M+ later → 4M+ shipped**. At launch it beat *Zelda* and *Animal Crossing* on Japanese charts. ([Gematsu](https://www.gematsu.com/2020/12/momotaro-dentetsu-showa-heisei-reiwa-mo-teiban-sales-top-1-5-million), [VGChartz](https://www.vgchartz.com/article/457887/momotaro-dentetsu-showa-heisei-reiwa-mo-teiban-ships-over-4-million-units/))
- **2023**: *Momotaro Dentetsu World: Chikyuu wa Kibou de Mawatteru!* (Switch) — first entry to leave Japan, using a globe-shaped board with cities worldwide. Still Japanese-only language.
- **2024 (Dec 12)**: *Showa, Heisei, Reiwa mo Teiban!* **Asia Edition** ships in 8 Asian markets with **English and Korean** support, 13 in-game currencies. The **first-ever official English release** in 36 years of the series. ([Gematsu Asia Edition](https://www.gematsu.com/2024/10/momotaro-dentetsu-showa-heisei-reiwa-mo-teiban-asia-edition-launches-december-12-with-english-language-support))
- **2025**: *Momotaro Dentetsu 2: Anata no Machi mo Kitto Aru* (Switch / Switch 2, Nov 13 2025) — split into East-Japan and West-Japan editions.

See `entries-table.md` for full list.

## Core Mechanics

**Goal city + dice movement.** Each turn you roll a die and move that many spaces in any direction along a rail/sea/air network. Cards can be played instead of rolling (extra dice, teleport, debuff opponent). The game cycles a calendar (April → March = one fiscal year), and one player's destination city ("goal station") rotates every few turns.

**Station/tile types** ([Konami official rules](https://www.konami.com/games/momotetsu/teiban/asia/en/play/)):
- **Plus (blue)** — pay out money; payouts swing seasonally (more in summer).
- **Minus (red)** — drain money; harsher in winter.
- **Card (yellow)** — free random card; "Nice Card" variants give better odds.
- **Card Shop** — buy/sell cards.
- **Property stations** — buy real estate tied to the city's actual specialty (Hiroshima okonomiyaki, Sapporo ramen, Kobe beef, etc.).

**Property + monopoly.** Each property has a price and a profit ratio. End-of-fiscal-year payout = price × profit ratio. **Owning every property at one station doubles its profits** — Monopoly-style monopolies, but localized to a single city's portfolio rather than color groups.

**Arrival grants.** First player to reach the rotating goal city gets a large cash bonus, with consecutive wins escalating it. This is the carrot that pulls players across the map; the Bombii is the stick that pushes the laggard.

**Cards: 100+** — split into self-buff (Sonic Card for extra dice, teleport cards, double-grant cards) and offensive (debt cards, blockades, property destruction, time bombs). ([Nintendo Life](https://www.nintendolife.com/news/2021/01/feature_hands-on_with_momotaro_dentetsu_the_switch_game_thats_beating_zelda_and_animal_crossing_in_japan))

## Bombii (Bonbii / Binbougami / "God of Poverty")

The **load-bearing griefing system** of the entire franchise.

- When any player reaches the goal city, the player **furthest from that city is possessed by Bombii** (Bonby). It rides their train, drains their money, redirects their movement, eats their cards.
- **Hot-potato transfer**: landing on the same square as another player passes Bombii to them. Players spend real strategic effort positioning to dump it on a rival — a sabotage primitive built into pure positioning.
- **Escalation tiers**: Mini Bonby → regular Bonby → Big Bonby → **King Bombii**. The longer you carry it, the worse it transforms. King Bombii's "evil deeds" include: throwing away huge sums of cash, **selling your properties without permission**, planting **time-bomb cards** that erase your entire hand on detonation, and forcing huge expenditures.
- It is explicitly designed to produce dramatic late-game reversals — a leader can lose the lead in a single Bombii cycle. This is also the source of Momotetsu's reputation as a "friendship-ruiner." ([Konami rules](https://www.konami.com/games/momotetsu/teiban/asia/en/play/), [Giant Bomb: King Bonby](https://www.giantbomb.com/king-bomby/3005-24700/))

Other curses/rivals beyond Bombii: cursed cards (debt, time bomb), blockade cards that wall off rail lines, and event NPCs (the series has a roster of "historical heroes" you can summon and a small bestiary of antagonists).

## What Makes the Rivalry Engaging

1. **Asymmetric pressure.** The leader chases arrival grants; the laggard literally has a demon riding them. Both poles of the standings have urgent, opposite jobs — the middle isn't a safe place to coast.
2. **Sabotage is positional, not just card-based.** Because Bombii transfers by sharing a square, every dice roll is also a sabotage decision. Movement is the offense.
3. **Long-fuse payoffs.** Annual property income compounds; monopolies double output; arrival-grant streaks compound. So small early advantages snowball — but King Bombii and time-bomb cards are designed to nuke leaders, keeping the snowball in check.
4. **Dramatic single-turn swings.** Reviewers repeatedly call out "reversal of fortune" as the core feeling. That's intentional, and is exactly why the player base is split between people who love it and people who say it ends friendships.
5. **CPU rivals are personalities, not stats.** AI opponents have named characters with distinct play personalities; matches feel like a campaign with rotating villains rather than abstract opponents.

## Why It's Huge in Japan, Unknown in the West

- **Cultural specificity is the whole product.** The board IS Japan. Every property is a real local specialty (Sapporo ramen, Hiroshima okonomiyaki, Kobe beef, Choshi soy sauce). Stations correspond to real JR network stops. The series partnered with the **Choshi Electric Railway** in 2007 to run a themed train; two real-world Momotetsu-themed restaurants opened at Haijima and Kaminagaya stations in 2009. The game teaches Japanese geography — Konami markets it to schools as edutainment ([Automaton](https://automaton-media.com/en/news/20220915-15736/)). Strip Japan out and you strip out the soul.
- **Heavy text dependency.** Card descriptions, NPC banter, real-estate trivia, and the comedic Bombii dialogue are all dense Japanese. Nintendo Life: "if you can't read Japanese then you're going to struggle."
- **Genre mismatch in the West.** Japanese sugoroku party-board games (Momotetsu, Itadaki Street, Mario Party, Dokapon) are a recognizable shelf in Japan; in the West they're niche. Konami had no obvious ROI on a full Western localization.
- **Localization actually started in 2024.** The Asia Edition (Dec 12 2024) was the first English support ever — released only in 8 Asian countries (Hong Kong, Taiwan, Singapore, Malaysia, Thailand, Indonesia, Philippines, Korea), not North America or Europe. As of April 2026 there is still **no native Western release** of any Momotetsu game. *World* (2023) is the most "exportable" entry conceptually (global cities) but remained Japanese-only.

## Session Length, Multiplayer, AI

- **Modes**: 3-year (fast competitive, ~30 min), 10-year (single-player ranked), and **classic up to 100 years** (~30 hours full century, ~20 min per in-game year).
- **Players**: 1–4. Local couch multiplayer + online (added in the 2020 entry). AI fills any empty seat — a key reason the series works as a couch game with two humans.
- **AI**: Adjustable difficulty, with named CPU characters (Sachiko, Yumiko, etc. across entries) that have distinguishable risk profiles and card-play preferences. Online ranked play exists but the series' social weight is overwhelmingly couch / family / New Year's gathering — it became a pandemic phenomenon partly because it scratched the in-person itch.

## Design Takeaways for Dice RPG

- **Rotating goal + lagging-player demon** is a clean two-sided tension. Worth adapting: a moving objective the leader chases, plus an *escalating* curse that the trailing player is forced to host.
- **Tier-escalating curse** (Mini → King Bombii) — punishment that gets worse if you fail to offload it. Pairs naturally with positional transfer mechanics.
- **Property monopolies tied to flavorful regions** rather than abstract color groups. Each region tells a story.
- **Short and long modes from the same rules**. 30-min and 30-hour both feel "right" because the per-year loop is self-contained.
- **AI as named personalities** rather than difficulty sliders.
- **Cultural ground-truth as a feature, not a feature.** Momotetsu's Western inaccessibility is the cost of its Japanese authenticity — a clear lesson that for this genre, *concrete place > generic fantasy* is fine if your audience matches.

## Sources

- [Momotaro Dentetsu — Wikipedia](https://en.wikipedia.org/wiki/Momotaro_Dentetsu)
- [Nintendo Life — Hands-On: The Switch Game Beating Zelda and Animal Crossing in Japan](https://www.nintendolife.com/news/2021/01/feature_hands-on_with_momotaro_dentetsu_the_switch_game_thats_beating_zelda_and_animal_crossing_in_japan)
- [Konami — Showa, Heisei, Reiwa mo Teiban! Asia Edition: How to Play](https://www.konami.com/games/momotetsu/teiban/asia/en/play/)
- [Gematsu — 1.5M sales](https://www.gematsu.com/2020/12/momotaro-dentetsu-showa-heisei-reiwa-mo-teiban-sales-top-1-5-million)
- [Gematsu — Asia Edition / English support](https://www.gematsu.com/2024/10/momotaro-dentetsu-showa-heisei-reiwa-mo-teiban-asia-edition-launches-december-12-with-english-language-support)
- [VGChartz — 4M units shipped](https://www.vgchartz.com/article/457887/momotaro-dentetsu-showa-heisei-reiwa-mo-teiban-ships-over-4-million-units/)
- [Giant Bomb — King Bonby character](https://www.giantbomb.com/king-bomby/3005-24700/)
- [Konami Wiki — Super Momotarou Dentetsu III: It's King Bombie!!](https://konami.fandom.com/wiki/Super_Momotarou_Dentetsu_III:_It's_King_Bombie!!)
- [Automaton — Momotetsu in Japanese schools](https://automaton-media.com/en/news/20220915-15736/)
- [Anime News Network — Momotaro Dentetsu 2 announcement (Aug 2025)](https://www.animenewsnetwork.com/news/2025-08-01/konami-reveals-momotaro-dentetsu-2-game-for-release-on-switch-switch-2-on-november-13/.227244)
- [GameFAQs — Momotarou Dentetsu franchise](https://gamefaqs.gamespot.com/games/franchise/1559-momotarou-dentetsu)
