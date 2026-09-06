# Dokapon Kingdom — Core Gameplay Loop

Research notes for prior-art on a Dokapon Kingdom-inspired board-game/RPG hybrid. Focused on the minute-to-minute loop, macro structure, the "asset" win condition, modes, and Dokapon's signature PvP/Darkling/town-stealing mechanics. Citations as URLs after each fact or paragraph.

## 1. Minute-to-Minute Loop

- On a player's turn they spin a roulette/spinner (functioning as a die), then move that many spaces along the board. Players choose their direction at branches/intersections; movement is not on rails. (https://www.digitallydownloaded.net/2023/05/review-dokapon-kingdom-connect-nintendo-switch.html , https://www.cgmagonline.com/articles/features/editorial-dokapon-kingdom/)
- Whatever space the spinner lands on resolves immediately: combat, item roulette, store visit, town interaction, event, etc. Most "blank-looking" spaces actually trigger field-monster battles. (https://gamefaqs.gamespot.com/boards/945683-dokapon-kingdom/46932554 , https://www.gamenguides.com/dokapon-kingdom-connect-beginners-guide-and-tips)
- "When everyone has taken their turn, one day passes. Weeks are seven days long." Turn order is fixed during a day; the day-end advances the calendar. (https://steamcommunity.com/sharedfiles/filedetails/?id=3032333450)
- Encounters with other players on the same space trigger optional/forced PvP combat. The game "encourages players to attack each other throughout the game." (https://www.cgmagonline.com/articles/features/editorial-dokapon-kingdom/)

### Combat resolution (rock-paper-scissors-like)
- "Battles in Dokapon follow a simple formula. Attack is a basic attack. Strike is an attack with incredible damage, usually killing the opponent in a single hit, but is countered by Counter. Defense will defend against any physical attacks (Attack and Strike). Counter will counter-strike if the opponent uses Strike, otherwise you take full damage." (https://gamefaqs.gamespot.com/boards/945683-dokapon-kingdom/46932554)
- "The battle system plays out in roshambo style, with the attack option beating counter, the counter option beating strike, and the defend option resisting the attack option." (https://en.wikipedia.org/wiki/Dokapon_Kingdom)
- Attacker options: Attack, Strike, offensive Magic, special ability. Defender options: Defend, Counter, defensive Magic, Give Up. (https://www.cgmagonline.com/articles/features/editorial-dokapon-kingdom/)
- "Give Up" surrenders the battle: the loser gets a 1-turn timeout and pays a smaller penalty than dying. Cannot give up if Wanted, in Arena, or vs. Darkling/assassins. (https://dokapon.fandom.com/wiki/Give_Up via search)

### Death penalties (escalating)
- Cherubs: wait 1 turn, lose an item or 1/4 of money.
- Black-haired/Dark Angels: wait 2 turns, lose half money / a few items / get pranked.
- Grim Reaper: wait 3 turns, may lose ALL money, all items, equipment, or even a Town. (https://dokapon.fandom.com/wiki/Death via search; https://steamcommunity.com/sharedfiles/filedetails/?id=3032333450)

## 2. Space Types

The board is dotted with circular Spaces, each with a different effect. (https://dokapon.fandom.com/wiki/Space_(Kingdom) via search)

- **Yellow / blank field spaces** — most common; trigger field-monster battles or the occasional NPC encounter. (search summary of dokapon.fandom Space page)
- **Town Space** — first visit fights a town boss; if you win, you "liberate" and own the town. Subsequent visits let you invest, rest, or pay tax to a rival owner. (https://gamefaqs.gamespot.com/boards/945683-dokapon-kingdom/46932554 , https://www.digitallydownloaded.net/2023/05/review-dokapon-kingdom-connect-nintendo-switch.html)
- **Castle Space** — like a town but special: granted by the King for completing favors in Story Mode; produces gem local items; value scales with liberated towns on its continent. (https://steamcommunity.com/sharedfiles/filedetails/?id=3032333450)
- **Bank / Collection Space** — "blue spaces with a big G"; landing on one deposits all currently-pending tax G from every town/castle you own. Investment can also be done here. (https://gamefaqs.gamespot.com/boards/945683-dokapon-kingdom/46932554)
- **Loot Spaces** (umbrella) — start a roulette that grants an item or piece of gear. Sub-types include **Item Space** (items only), **Magic Space** (field/battle magic), **Battle Magic Space** (rare; offensive + defensive battle magic), **Equipment / Weapon / Shield Space**. Loot spaces are safe from PvP battles. (https://dokapon.fandom.com/wiki/Loot_Space via search; https://dokapon.fandom.com/wiki/Battle_Magic_Space via search)
- **Locked Box Space** — requires a Magic Key; gives a fixed high-value item; one-time use per box. (https://dokapon.fandom.com/wiki/Locked_Box_Space via search)
- **Store Space (Building Space)** — buy weapons, shields, items, or magic. Stores close on Sunday; Saturday gives a 25% sale. Can also be robbed by Ninja field skill. (https://dokapon.fandom.com/wiki/Stores_(Kingdom) via search; https://gamepretty.com/dokapon-kingdom-connect-begginers-manual/)
- **Temple** — sets your respawn point on death; healing services. (https://dokapon.fandom.com/wiki/Temple via search)
- **Job Center / Bank** — change jobs, deposit money. (https://gamepretty.com/dokapon-kingdom-connect-begginers-manual/)
- **Poison Swamp** — poisons player + forces a battle; cured at Temple/Castle or by Panacea. (https://gamefaqs.gamespot.com/boards/945683-dokapon-kingdom/46932554)
- **Dark Space** — only in Asiana; the trigger location for becoming the Darkling. (https://dokapon.fandom.com/wiki/Dark_Space via search)
- **Event Space / NPC encounters** — NPCs offer minigames or services to "steal or harm the other players." (https://en.wikipedia.org/wiki/Dokapon_Kingdom)

(Note: Dokapon does not strictly use a red/blue/green coding the way Mario Party does. The most consistent color cue is "blue-G" = bank/collection. Other spaces are differentiated by icon + color combinations rather than a uniform 3-color scheme.)

## 3. Week / Calendar Macro Structure

- Day = one full round of turns. Week = 7 days. (https://steamcommunity.com/sharedfiles/filedetails/?id=3032333450)
- Sunday: all stores, banks, and job centers are closed. Saturday: 25% sale at all shops. (search of dokapon.fandom Stores page)
- Each new week may roll a **Weekly Event**: gold/tax modifiers, store-wide closures (e.g., "Paid Holiday" closes all stores all week), arena tournaments, minigames. (https://dokapon.fandom.com/wiki/Weekly_Event_(Kingdom) via search)
- **Weekly results / payday**: every adventurer is paid their salary (job-based), gets ranking feedback, and is shown standings (1st place = highest total assets). (https://dokapon.fandom.com/wiki/Weekly_Results via search)
- Salary scales with job level + 100% bonus per mastered job. Completing your job's weekly bonus goal pays 3x. (https://gamepretty.com/dokapon-kingdom-connect-begginers-manual/)

## 4. Macro Structure: Story Mode Chapters

- Story Mode = Prologue + 8 chapters across 7 continents. Each chapter unlocks the next continent. (https://dokapon.fandom.com/wiki/Story_Mode_(Kingdom) via search; https://www.gamegrin.com/reviews/dokapon-kingdom-connect-review/)
- Pattern per chapter: defeat the continent's town bosses (2-4 per chapter) -> the King gives a fetch/escort favor (e.g., bring an antidote, recover Princess Penny's piggy bank, retrieve the Royal Ring) -> winner of the favor is awarded a Castle. (https://dokapon.fandom.com/wiki/Story_Mode_(Kingdom) via search)
- "At the end of every chapter, players will see their current rankings, receive their salary, and be prompted to save." (https://gamepretty.com/dokapon-kingdom-connect-begginers-manual/)
- Story Mode session length: roughly 20-30 hours to completion. (https://www.digitallydownloaded.net/2023/05/review-dokapon-kingdom-connect-nintendo-switch.html ; https://steamcommunity.com/app/2338140/discussions/0/3825300093333788909/)

## 5. Modes

Dokapon Kingdom: Connect ships five modes: **Normal, Story, Shopping Race, Kill Race, Town Race.** (https://store.steampowered.com/app/2338140/Dokapon_Kingdom_Connect/)

- **Normal Mode**: open sandbox. Player sets game length 1-99 weeks (some sources say 1-999). Win = highest Net Worth at the deadline. The whole map is unlocked from the start, which actually makes Normal more chaotic/imbalanced than Story. (https://dokapon.fandom.com/wiki/Normal_Mode via search)
- **Story Mode**: chapter-driven, gated map, narrative beats; win = most CASH (G) at end of the story. Castles only obtainable here, via King's Favors. (https://dokapon.fandom.com/wiki/Story_Mode_(Kingdom) via search; https://gamepretty.com/dokapon-kingdom-connect-begginers-manual/)
- **Shopping Race / Kill Race / Town Race**: short objective-based modes — first to N purchases / kills / liberated towns. Custom win condition stated at game start. (https://store.steampowered.com/app/2338140/Dokapon_Kingdom_Connect/ ; https://steamcommunity.com/sharedfiles/filedetails/?id=3032333450)

(Note: the user asked about "Adventure Mode" — in Dokapon Kingdom, there is no mode literally named "Adventure." The closest equivalents are Story Mode (single-narrative) and Normal Mode (open sandbox / "free play"). Some reviewers use "adventure mode" loosely as a synonym for Story.)

## 6. Asset / Score System (Net Worth)

- Win condition for the main modes: greatest **Net Worth** (Normal) / greatest **Cash G** (Story) at the deadline. (https://steamcommunity.com/sharedfiles/filedetails/?id=3032333450 ; https://gamepretty.com/dokapon-kingdom-connect-begginers-manual/)
- Net Worth is dominated by **Towns + Castles** owned. Investments raise a town's daily tax and its asset valuation. (https://gamefaqs.gamespot.com/boards/945683-dokapon-kingdom/46932554)
- Towns generate daily taxes; you only realize them by landing on a Bank/Collection Space. Until then they're "uncollected" and another player can steal them by killing you. (https://gamefaqs.gamespot.com/boards/945683-dokapon-kingdom/46932554)
- **Local Items**: each town/castle produces a region-specific item that, gifted to the King, banks Net Worth at "FAR greater than their selling price." Major late-game flex. (https://gamepretty.com/dokapon-kingdom-connect-begginers-manual/)
- **King's Favor** scales an end-of-game bonus: doing King's quests / sending him gifts increases favor and final payout. (https://dokapon.fandom.com/wiki/King's_Favors via search)
- Standings updated weekly: rank 1 = highest total assets right now. (https://dokapon.fandom.com/wiki/Weekly_Results via search)

## 7. Signature Mechanics That Define Dokapon

- **PvP combat between players** (not just vs. monsters) is core, not optional. Loser of a PvP can be looted: stealer takes money or a piece of gear, can transfer their own debuffs onto the loser, or — purely cosmetic — graffiti the loser's character (rename, hair). (https://www.digitallydownloaded.net/2023/05/review-dokapon-kingdom-connect-nintendo-switch.html ; https://www.cgmagonline.com/articles/features/editorial-dokapon-kingdom/)
- **Stealing towns**: defeating the current owner in PvP can transfer ownership of one of their towns. This is the main mechanism for catch-up and griefing. (https://www.cgmagonline.com/articles/features/editorial-dokapon-kingdom/)
- **Field Magic**: one-shot spells used on the overworld map, not in battle, to trap, curse, damage, move, or summon against rival adventurers. Includes Curse (target sometimes hits self), Curse All (all players), summon-type, move-type, etc. (https://dokapon.fandom.com/wiki/Field_Magic_(Kingdom) via search)
- **Wanted status / bounties**: players who attack others enough get marked Wanted; they cannot Give Up in battle and may be targeted. (https://dokapon.fandom.com/wiki/Give_Up via search)
- **Dark Mark / Darkling transformation** (the rubber-band/comeback engine):
  - Players who are stuck in last place long enough hear "the whisper of dark revenge" and gain a Dark Mark. (https://en.wikipedia.org/wiki/Dokapon_Kingdom)
  - Going to the Dark Space in Asiana lets them trade ALL their towns, items, field magic, and cash to Weber in exchange for becoming the **Darkling** for 14 days. (https://dokapon.fandom.com/wiki/Darkling_(Kingdom) via search)
  - The Darkling has tripled base stats, top-tier gear, multiple spinners per turn, deploys traps, and — critically — can **steal towns / castles by simply landing on them**. Landing on a town with a monster fully heals them and cures status. (https://dokapon.fandom.com/wiki/Darkling_(Kingdom) via search; https://www.cgmagonline.com/articles/features/editorial-dokapon-kingdom/)
- **Revenge framing / "anything goes"**: the Steam page advertises "an adventure for money begins, where absolutely anything goes!" and the design rewards backstabbing, last-minute heists, and grief. (https://store.steampowered.com/app/2338140/Dokapon_Kingdom_Connect/)
- **Robbing stores**: the Ninja class can attack stores to steal stock as a field action. (https://dokapon.fandom.com/wiki/Robbing_a_Store via search)

## 8. Notable Numbers / Reference Points for a Clone

- Players: up to 4. (https://en.wikipedia.org/wiki/Dokapon_Kingdom)
- Jobs/classes: 11. (https://store.steampowered.com/app/2338140/Dokapon_Kingdom_Connect/)
- Continents in Story Mode: 7 (across 8 chapters + prologue). (https://www.gamegrin.com/reviews/dokapon-kingdom-connect-review/ ; https://dokapon.fandom.com/wiki/Story_Mode_(Kingdom) via search)
- A typical "default" Normal-Mode session is ~30-40 weeks. A 12-week game runs ~3-4 hours; Story Mode runs 20-30 hours; long Normal games run dozens of hours. (https://www.digitallydownloaded.net/2023/05/review-dokapon-kingdom-connect-nintendo-switch.html)
- Job mastery cap: 6 battles per job-level; full mastery grants permanent +1 stat per remaining level-up. (https://gamefaqs.gamespot.com/boards/945683-dokapon-kingdom/46932554)
- Darkling duration: 14 days. (https://dokapon.fandom.com/wiki/Darkling_(Kingdom) via search)

## 9. Open / Unclear

- A canonical, comprehensive list of every space type with exact color coding was blocked behind 403s on StrategyWiki and the Fandom Spaces page; descriptions here are aggregated from search snippets and may miss minor space types (e.g., specific event-space variants).
- Exact chapter objectives for chapters 3, 4, 6, 7, and 8 weren't fully captured (only prologue, 1, 2, and 5 were detailed in accessible snippets).
- The exact arithmetic of Net Worth (how investment levels translate to G value, how local items convert to Net Worth) wasn't accessible directly; only directional rules.
