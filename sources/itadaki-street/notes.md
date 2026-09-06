# Itadaki Street / Fortune Street — Research Notes

A research dossier on the Square Enix board-game series, assembled as prior art for a Dokapon Kingdom-inspired board/RPG hybrid.

## 1. Series Overview & Origins

**Itadaki Street** (lit. "Welcome to ___'s Shop / Boulevard") is a long-running Japanese board-game video game franchise created by **Yuji Horii** — the same designer responsible for **Dragon Quest**. The first entry, *Itadaki Street: Watashi no Omise ni Yottette* ("Drop by my Shop"), launched on the Famicom in **1991**, published by **ASCII**. The series has since lived on the Super Famicom, PlayStation, PS2, PSP, DS, mobile, Wii, and PS4/Vita, with most entries published by Enix and later Square Enix [Wikipedia, Fortune Street Wiki].

Horii reportedly began toying with the board-game concept in 1989 alongside a Famitsu editor as a deliberate change of pace from RPG design. The mini-game later folded back into Horii's RPG work — a stripped-down Itadaki Street appears as a casino/sugoroku mini-game in remakes of *Dragon Quest III* [Itadaki Street Wikipedia entry; Fortune Street Wiki series page].

The DNA is **traditional Japanese sugoroku + Western Monopoly + a real stock market**, an oddly economic-flavored hybrid that has no direct analog in the Western console party-game canon.

## 2. Core Mechanics (Fortune Street / Itadaki Street Wii baseline)

The mechanical loop, as documented in Nintendo Life, Nintendo World Report, GameSpot, and Quarter to Three reviews:

- **Movement**: Roll one die. Boards include junctions/branching paths rather than the linear loop of Monopoly, so route choice matters.
- **Shops (properties)**: Land on an unowned tile and choose to buy a shop. Future visitors pay a fee. Owners can **invest cash to upgrade** a shop, raising its rent.
- **Districts / Areas (color groups)**: Shops are grouped into districts. Owning multiple shops in one district **multiplies their rent** — the monopoly mechanic from Monopoly, but soft (you don't need full ownership; rent scales with concentration).
- **Stock Market**: Each district has a tradable stock. Any player can **buy shares in any district**, regardless of who owns the shops there. Share price is tied to total district shop value, so when an owner upgrades a shop, every shareholder benefits. This is the series' signature mechanic — you can profit from rivals' empires without owning a single tile.
- **Dividends**: Periodically issued to shareholders; quarter-to-three coverage emphasizes that "you will not pass go, but you will collect dividends."
- **Suits (♠ ♥ ♦ ♣)**: Scattered around the board. Collecting one of each, then returning to the central **bank**, awards a **salary** and promotes the player to the next level (higher salary tier next time). Suit collection is the series' substitute for Monopoly's "pass GO" loop and gives the board a directional pull toward the center.
- **Special tiles**: Arcade/casino mini-game squares; **Venture Cards** (chance-style cards that may help opponents); Suit squares that grant the suit shown.
- **Win condition**: Reach a target net worth (cash + shop value + stock value), then return to the bank to cash out. The target is set per board, which **gives every match a hard finish line** — explicitly a design fix for Monopoly's open-ended grind [Nintendo World Report Editorial; Nintendo Life review].

Mode-wise, Fortune Street's **Easy** mode disables stocks; **Standard** mode includes them. This recognizes the depth gap between the basic property loop and the full economic sim.

## 3. How It Differs from Dokapon Kingdom

| Axis | Itadaki Street / Fortune Street | Dokapon Kingdom |
|---|---|---|
| Genre lean | Economic sim / Monopoly+ | RPG / combat-on-a-board |
| Player vs player interaction | **Indirect** — landing on shops, share-price moves | **Direct** — duels, stealing items/jobs/gold |
| Win condition | Hit a cash target, return to bank | Conquer towns / loot / story-mode goals |
| Random output | Dice + stock fluctuation + Venture cards | Dice + spells + battle RNG + jobs |
| Tone | Polite, mathematical, polite-mean | Slapstick-cruel, openly griefing |
| Combat | None (mini-games at casino tiles only) | Central — turn-based RPG battles |
| Progression | Salary level via suit collection | Levels, gear, job classes |

Dokapon is "Mario Party meets a JRPG"; Itadaki Street is "Mario Party meets *The Wall Street Journal*." Both share the multi-hour board-game-with-mascots format and the friendship-corroding reputation, but the levers are different: Itadaki rewards *patient capital allocation*; Dokapon rewards *opportunistic violence*.

## 4. Crossover Entries

The series's mainline-vs-crossover split is the key to understanding its catalog:

- **Mainline** (1991, 1994, 1998, 2002, 2007 DS): original or generic-cute characters, on themed boards.
- **DQ + FF crossovers**: *Dragon Quest & Final Fantasy in Itadaki Street Special* (PS2, 2004) and *Portable* (PSP, 2006) — the Square Enix mega-mashup. Sold strongly in Japan (~380k by Aug 2005 for Special).
- **DQ + Mario crossover** for the **first global release**: *Itadaki Street Wii* (2011 JP) / *Fortune Street* (NA 2011) / *Boom Street* (EU 2012). Developed by Marvelous AQL, published by Nintendo. 13 Mario-side and 13 DQ-side characters; Mario-themed and DQ-themed boards (e.g., Starship Mario from *Galaxy 2*) [Mario Wiki].
- **30th Anniversary** *Dragon Quest & Final Fantasy in Itadaki Street* (PS4/Vita, 2017) — JP only.

The Mario partnership was almost certainly what unlocked Western publishing: Nintendo wanted a Wii party title; Square Enix had the engine; the DQ side travelled with Mario as ballast.

## 5. Why So Few Western Releases

Multiple converging reasons:

1. **License entanglement**: Most entries lean on Dragon Quest (and later Final Fantasy) IP, which until late had soft Western brand recognition for DQ specifically.
2. **Genre risk**: A Japanese sugoroku-style economic game with a stock market is an unusual sell to Western publishers used to Mario Party-shaped party games.
3. **Translation cost**: Heavy text load (Venture cards, dialogue, tutorials) for a niche genre.
4. **The 2011 alignment**: Pairing with Mario on the Wii — the West's biggest party-game platform at the time — solved both the brand and the genre legibility problem at once. It remains the **only mainline console release** localized for the West [Wikipedia].
5. *Fortune Street Smart* (mobile, 2012) briefly extended worldwide reach but was delisted.

## 6. Reception & Reputation

- **Critical reception**: Generally favorable but split. Nintendo Life **8/10**, praising strategic depth; warning sessions are "very long" and that the only barrier is its own complexity. Nintendo World Report and Game Informer were positive; IGN milder ("Good," noting limited interactivity).
- **Length**: GameFAQs forum consensus and reviews put a single match at **2–3+ hours** even on small boards. Tour mode is single-player only and described as "tiring."
- **AI difficulty**: Difficulty scales by character; CPU opponents have varied victory conditions (some try to bankrupt you, some race net worth). Reviewers note CPU is competent on the basic loop but exploitable on stocks once you understand share-price feedback with shop upgrades.
- **"Friendship-ending" reputation**: Like Monopoly, it's the canonical "long, polite, slowly devastating" game. Stock crashes triggered by another player upgrading and dumping shares feel personal. Combined with the multi-hour runtime, it's a known relationship-stresser, often cited alongside Mario Party and Dokapon in "games that ruin friendships" lists.

## 7. Implications for a Dokapon-likes Project

Useful takeaways for the dice_rpg design:

- **Hard finish line beats Monopoly drag**: Itadaki's net-worth-target-plus-return-to-bank is a clean way to bound session length. Dokapon Kingdom's Story Mode does similar work via objectives.
- **Indirect interaction layer**: A stock-style "invest in your rivals' regions" system is a strong tension-builder that doesn't require combat. Could complement Dokapon-style combat as a parallel economy.
- **Suit / circuit reward**: Suits-to-bank gives the board a *gravitational center* and a non-rent income source so falling-behind players still progress. A useful anti-snowball lever.
- **Mode tiers**: Easy-no-stocks / Standard-with-stocks is a smart accessibility ramp for an inherently complex genre.
- **License-as-vehicle**: The Western release happened because of crossover IP. For an indie clone, themed boards built around recognizable archetypes (genre tropes, not licensed IP) carry similar legibility weight.

## Sources

- [Itadaki Street — Wikipedia](https://en.wikipedia.org/wiki/Itadaki_Street)
- [Fortune Street (series) — Fortune Street Wiki](https://fortune-street.fandom.com/wiki/Fortune_Street_(series))
- [Fortune Street — Wikipedia](https://en.wikipedia.org/wiki/Fortune_Street)
- [Fortune Street Review — Nintendo Life (8/10)](https://www.nintendolife.com/reviews/2011/12/fortune_street_wii)
- [Fortune Street Review — Nintendo World Report](http://www.nintendoworldreport.com/review/28606/fortune-street-wii)
- [Fortune Street Is the Best Version of Monopoly Ever — NWR Editorial](http://www.nintendoworldreport.com/editorial/38482/fortune-street-is-the-best-version-of-monopoly-ever)
- [Fortune Street Review — GameSpot](https://www.gamespot.com/reviews/fortune-street-review/1900-6347175/)
- [You will not pass go in Fortune Street, but you will collect dividends — Quarter to Three](https://www.quartertothree.com/fp/2011/12/06/you-will-not-pass-go-in-fortune-street-but-you-will-collect-dividends/)
- [Fortune Street — Super Mario Wiki](https://www.mariowiki.com/Fortune_Street)
- [Itadaki Street DS — Super Mario Wiki](https://www.mariowiki.com/Itadaki_Street_DS)
- [Itadaki Street (series) — Dragon Quest Wiki](https://dragon-quest.org/wiki/Itadaki_Street_(series))
- [Itadaki Street — Grokipedia / HG101 mirror](https://grokipedia.com/page/Itadaki_Street)
- [Fortune Street (Video Game) — TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/FortuneStreet)
