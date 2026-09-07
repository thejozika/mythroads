# Equipment

Worn gear that modifies a character's stats in combat and on the board. **Equipment is NOT stored in inventory** — when a player picks up a new piece, they must immediately equip it or drop it. This is a deliberate simplicity rule borrowed from Dokapon Kingdom.

## Slots — 11 total, identical for all classes

| Slot | Category | Primary effects |
|---|---|---|
| **Helmet** | Head armor | DF; sometimes MG resist or status immunity |
| **Gloves** | Hand armor | DF; sometimes AT bonus or crit chance |
| **Body armor** | Chest armor | DF (highest of the armor pieces) |
| **Shoes** | Foot armor | DF; sometimes SP bonus or movement-related effect |
| **Necklace** | Accessory | Varied: HP/MP boost, status immunity, signature effects |
| **Ring 1** | Accessory | Varied effects |
| **Ring 2** | Accessory | Varied effects |
| **Right hand** | Held | Main weapon (sword, axe, staff, etc.) |
| **Left hand** | Held | Off-hand: shield, secondary weapon, or focus |
| **Battle spell** | Magic | One equipped offensive spell available during attack phases |
| **Magic ward** | Magic | One equipped defensive spell powering Arcane Ward |

Two-handed weapons (great-axes, war-staves, polearms) occupy **BOTH** hand slots when equipped.

## No inventory storage rule

Equipment **cannot** be carried in inventory. When a player picks up a new piece (drops, treasure, shop, quest reward, PvP loot):

- **Equip immediately** — the new piece replaces what's currently in that slot. The displaced piece is **destroyed** (current placeholder; alternatives in open questions).
- **Refuse and leave it behind** — the piece stays where it was offered.
- **No stashing for later.**

This removes the "is this a good upgrade?" inventory-pressure loop and pushes players to commit on the spot. Matches Dokapon's pattern.

## Acquisition

Same sources as dice: shops (each town has its own stock), treasure spaces, boss drops, monster drops, quest rewards, town liberation rewards, PvP loot.

## Dokapon-reference deltas

| Decision | Dokapon | Dice RPG |
|---|---|---|
| Slot count | 4 (weapon / shield / accessory / book) | 11 including separate offensive and defensive magic |
| Magic books | One shared equipment slot | Dedicated Battle Spell and Magic Ward slots |
| Storage | None — equip or drop | Same — equip or drop |
| Two-handed weapons | One slot, no off-hand | Take both hand slots |

## Files in this folder

- `overview.md` — this file
- `weapons.md` — weapon catalog, R/L-hand rules, two-handed rules (planned)
- `armor.md` — helmet / gloves / body armor / shoes catalogs (planned)
- `accessories.md` — necklace + ring catalogs (planned)

## Open questions

- **Replaced-equipment fate.** Currently destroyed. Alternatives: sold-back to the shop you're at for a partial refund, or dropped on the space for other players to pick up. The drop-on-space variant adds griefing opportunities (drop your old gear to bait a rival) but increases complexity.
- **Weapon affinity / class proficiency.** Can any class wield any weapon, or do classes have proficiency restrictions (e.g., Mages can't wield two-handed axes)?
- **Equipment durability.** Can equipment break like special dice? Currently no, but special unique items might.
- **Set bonuses.** Wearing matching pieces grants extra effects? Fun but adds complexity.
- **Off-hand restrictions.** Any rules on what fits in left hand (shield only? any one-hand weapon?)?
