# Dokapon Kingdom — Items, Magic, Towns, and Economy

Research notes on the systems that turn Dokapon Kingdom from a board-game roll-and-move into a "friendship-destroying" RPG. Focus areas: item categories, the town/tax loop, stores, field magic, board spaces, and the griefing toolkit.

## 1. Equipment and Item Categories

Adventurers carry two parallel inventories: an **equipment loadout** (worn) and a **bag** (consumables/field items/field magic). Equipment slots are Weapon, Shield, and Accessory; armor as a separate slot is folded in via shields and clothing-style gear in Kingdom (Dokapon Wiki, "Item (Kingdom)").

Categories surfaced repeatedly across sources:

- **Weapons** — boost AT (Attack); some have on-hit effects (poison, sleep) or counters.
- **Shields** — boost DF (Defense); some grant elemental resistance.
- **Accessories** — the most flavorful slot; ranges from raw stat boosts (Power Ring, Magic Ring, Speed Ring) to fight-changing effects (Deathblock, Revival, Angel Choker) to elemental halvers (Fire/Ice/Thunder Bracelets) (Dokapon Wiki, "Accessory (Kingdom)").
- **Field Items / Consumables** — single-use bag items used at the start of your turn or automatically: Vanish, Spinner, Trap, Crystals, Wings, Sweet Syrup, Dokapon Ball, etc. ("Item (Kingdom)").
- **Magic Books / Field Magic** — bag-slot spells cast on the world map: Come Here, Mix-up, Mystery, Charm Potion, Magic Medicine, etc. ("Field Magic (Kingdom)").
- **Battle Magic** — Offensive (Fire, Ice, Lightning, Bomb, Physical) and Defensive (counter-spells / Magic Mirror) used during the rock-paper-scissors battle phase ("Offensive Magic", "Magic").
- **Local Items / Specialties** — produced by Lv 3+ towns; not used directly but counted as net worth (Dokapon Wiki, "Local Items").

## 2. Towns: Liberation, Tax, Upgrade, Damage

Towns are the spine of the economy. A neutral town can be claimed by simply landing on it; an enemy-held town requires defeating the **town monster** that occupies it (Dokapon Wiki, "Town (Kingdom)"). Once owned:

- The town's base value is added to the owner's **net worth** (the score the game ranks players by).
- It accrues **daily tax** that the owner collects when they land on **Bank/Collection spaces** (the blue spaces with a big "G").
- The owner can **invest** at the town or via a Bank Space. **Cost to upgrade = current daily income x 32.** Each level raises tax. At **Lv 3 the base value doubles** and the town starts producing a **Local Item** specialty; at **Lv 6 it triples** ("Town (Kingdom)", "Invest").
- Non-owners landing on the town can pay the daily-income amount to **rest** (heal HP/SP).
- Damaging mechanics: monsters periodically **occupy / destroy** unowned or enemy towns; the Darkling can wreck towns, and on player death the Grim Reaper can claim assets. Towns under monster attack lose levels until liberated. Castles can be stolen via **Castle Panic**, never via Charm Potion.

## 3. Stores

Cities contain a rotating mix of shops (Dokapon Wiki, "Stores"):

- **Weapon Store** — weapons and shields by region tier.
- **Magic Store** — buys/sells Field, Offensive, and Defensive magic books ("Magic Store (Kingdom)").
- **Item Store** — Vanishes, Traps, Spinners, Wings, Crystals, Dokapon Balls, etc.
- **Casino** — Building Space with slot machine and high-stakes mini-games; can be closed if you are Wanted, a Darkling, or via Worker Strike/Day Off ("Casino (Kingdom)"). Late-game casinos pay out endgame gear.
- **Jobs Office (Class Change Agent)** — change job; Lv 6 jobs are "mastered" and grant a permanent stat point on every future level-up ("Job"). Each mastered job adds a permanent **+100% Salary** ("Job Mastery Bonus").
- **Bank** — invest in your towns from anywhere on the same continent.

Ninjas can **Attack/Rob a store** as a field skill, illustrating that even the storefronts are not safe.

## 4. Board Spaces (Field/Event)

Spaces define what happens when you land (Dokapon Wiki, "Space (Kingdom)"; StrategyWiki, "Spaces"):

- **Town / Castle / Village** — own/liberate/rest.
- **Bank (Collection) Space** — collect taxes; invest in towns.
- **Item / Magic / Equipment Spaces** — free pickup of an item, field magic, or weapon+shield.
- **Loot Spaces** (White / Red / Gold) — random higher-tier rewards including iconic items.
- **Trap Space** — Trap items can be **placed by players** on any space; landing victims take damage or status (Dokapon Wiki, "Trap").
- **Vending Machine Space** — pay gold for random consumables.
- **Quiz Space** — trivia for a reward.
- **Random Battle Space** — forced monster encounter.
- **Encounter Spaces / Castle Gates / Warps** — set-piece events.

## 5. Magic System

Three magic categories (Dokapon Wiki, "Magic"):

- **Offensive Magic** — ignores Speed (always hits) but can be countered by a Defensive spell. Most use MG; "Physical-type" offensive spells use AT. Comes in Fire, Ice, Lightning, Bomb, and Physical flavors. Damage of the elemental three is halved by the matching **Elemental Bracelet**.
- **Defensive Magic** — only triggers if the holder picks Defensive Magic in the battle RPS; nullifies/reflects offensive spells (Magic Mirror reflects Field Magic too).
- **Field Magic** — board-level spells in the bag. Mostly local-map only, but **Come Here**, **Mix-up**, and **Mystery** ignore the map boundary. Highlights: **Come Here** teleports every other player to your tile (combo with high SP + Deathblock = battle ambush); **Mystery** rolls a random self-effect (heal, steal town income, stat boosts); **Samaritan** fully heals; **Vacuum** drains gold; **Charm Potion** lets you walk in and **steal a town** outright (does not work on castles).

## 6. The Economic Loop

Gold flows in from many small streams that snowball:

1. **Combat & Loot** — kill monsters, take their gold; defeat Wanted criminals for bounties; loot spaces drop cash.
2. **Weekly Salary** — flat by job and job level, multiplied by **+100% per mastered job** (Job Mastery Bonus). Bonus goal pays **3x salary**. Late game heroes hit **2-3M G/week** (Dokapon Kingdom/Strategies).
3. **Town Tax + Local Items** — taxes collected at Bank Spaces; Lv 3+ towns add fixed-value Local Items to net worth; investment converts liquid gold into compounding revenue.
4. **PvP** — winning a battle takes the loser's gold and optionally an item or piece of gear.
5. **Casino** — high variance, but the casino is "in the player's favor" and a primary route to top-tier gear.
6. **Weekly Events / King's Favors** — scripted bonuses.

Crucially, **"the gold value of some things is multiplied by the number of weeks that have passed,"** so the game intentionally inflates rewards over time (Steam guide, "The Missing Manual"). This is the explicit catch-up mechanic — late-comers earn proportionally more, and a single big swing (a stolen town, a casino jackpot, an Alchemy run worth 300k/turn) can flip the standings.

## 7. The Griefing Toolkit (Core to Identity)

Dokapon's identity is built on items that punish the leader (Dokapon Wiki, "Item (Kingdom)"; CGMagazine):

- **Trap** — placeable bombs/status spaces.
- **Vanish** — escape one steal/death penalty; "3 Vanishes blanks an entire Darkling reign."
- **Spinner** — guarantees you land on the next picked space (used to chain Casino visits).
- **Charm Potion** — walk into a rival's town and **take it**.
- **Magic Medicine** — double all stats for a week, then crash to 1 HP.
- **Come Here** — yank everyone to you for a forced fight.
- **Mix-up** — randomly swap players' positions on the board.
- **Sweet Syrup** — sticky-status field item (immobilizes target on next move).
- **Devil Backup / Acro Ring / Dokapon Ring** — chase/anti-death accessories that swing comebacks.
- **Pickpocket / Steal** — Thief job skills that strip items just by passing rivals.
- **Darkling form** — last-place catch-up class with town-stealing gear; available for two weeks to whoever sits in last.

The takeaway for a Dokapon-inspired design: every system feeds into the others. Towns produce gold, gold buys gear and casino spins, gear wins fights, fights take towns and items, and the entire pile is wrapped in an item economy explicitly designed to let losers strip winners.

## Sources

- Dokapon Wiki — [Town (Kingdom)](https://dokapon.fandom.com/wiki/Town_(Kingdom)), [Item (Kingdom)](https://dokapon.fandom.com/wiki/Item_(Kingdom)), [Accessory (Kingdom)](https://dokapon.fandom.com/wiki/Accessory_(Kingdom)), [Field Magic (Kingdom)](https://dokapon.fandom.com/wiki/Field_Magic_(Kingdom)), [Offensive Magic](https://dokapon.fandom.com/wiki/Offensive_Magic), [Magic Store (Kingdom)](https://dokapon.fandom.com/wiki/Magic_Store_(Kingdom)), [Stores](https://dokapon.fandom.com/wiki/Stores), [Casino (Kingdom)](https://dokapon.fandom.com/wiki/Casino_(Kingdom)), [Space (Kingdom)](https://dokapon.fandom.com/wiki/Space_(Kingdom)), [Trap](https://dokapon.fandom.com/wiki/Trap), [Invest](https://dokapon.fandom.com/wiki/Invest), [Local Items](https://dokapon.fandom.com/wiki/Local_Items), [Magic Medicine](https://dokapon.fandom.com/wiki/Magic_Medicine), [Charm Potion](https://dokapon.fandom.com/wiki/Charm_Potion), [Come Here](https://dokapon.fandom.com/wiki/Come_Here), [Deathblock](https://dokapon.fandom.com/wiki/Deathblock), [Revival (Kingdom)](https://dokapon.fandom.com/wiki/Revival_(Kingdom)), [Job](https://dokapon.fandom.com/wiki/Job), [Thief (Kingdom)](https://dokapon.fandom.com/wiki/Thief_(Kingdom)), [Strategies](https://dokapon.fandom.com/wiki/Dokapon_Kingdom/Strategies).
- StrategyWiki — [Dokapon Kingdom/Spaces](https://strategywiki.org/wiki/Dokapon_Kingdom/Spaces).
- Steam Community — ["The Missing Manual" guide for Dokapon Kingdom: Connect](https://steamcommunity.com/sharedfiles/filedetails/?id=3032333450).
- GameFAQs — [Item tier list thread](https://gamefaqs.gamespot.com/boards/945683-dokapon-kingdom/47221678), [Locked chest list](https://gamefaqs.gamespot.com/boards/945683-dokapon-kingdom/52497152), [Casino combos](https://gamefaqs.gamespot.com/boards/945683-dokapon-kingdom/52540352).
- CGMagazine — [Dokapon Kingdom: The Ultimate RPG Board Game Adventure](https://www.cgmagonline.com/articles/features/editorial-dokapon-kingdom/).
- TV Tropes — [Dokapon Kingdom](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/DokaponKingdom).
