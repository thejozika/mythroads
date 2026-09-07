# Combat

The battle system: how two combatants resolve a fight, the choices each makes, the stats that drive damage, and the status effects that modify it.

## Scope

- **Stance decision layer** — the hero alternates between choosing an attack and reading an enemy
  attack with a defensive stance. Choices are private on the controller; results are public.
- **Stats** — HP, Attack, Defense, Magic, Athletics, and Agility.
- **Damage formulas** — basic attack, strike, counter, magic, skill.
- **Status effects** — poison, sleep, curse, seal, fear, etc.
- **Critical hits, accuracy, evasion, RNG** — how much variance and where.
- **PvP vs monster combat** — what differs (give-up, looting, death penalty).
- **Battle skills** — class-specific combat actions.

## Dokapon reference

Dokapon's combat is a simultaneous-reveal RPS over multiple rounds, with role-swap each round. Attacker picks Attack / Strike / Magic / Skill / Give Up; defender picks Defend / Counter / Defensive Magic / Give Up. Strike formula `(AT+MG+SP)×2.5 − (DF+MG+SP)`; Counter `D×4 + A×2`; accuracy clamped 50–100% from SP delta. See `../../sources/dokapon-combat/notes.md` and `../../sources/dokapon-combat/formulas.md`.

## Files in this folder

- `overview.md` — this file
- `rps.md` — action choices, matchup matrix, role-swap rules (planned)
- `stats.md` — stat list, sources (level/class/gear), caps (planned)
- `damage-formulas.md` — exact math for each action (planned)
- `status-effects.md` — full effect list and combat interactions (planned)
- `pvp-rules.md` — give-up, looting, death penalty (planned)

## Playable PvE rules

- Attack phase: choose Quick Stab, High Charge, Side Rush, Leaping Strike, or one of the two actions
  granted by the equipped offensive grimoire.
- Quick Stab is reliable and neutral into every guard. Each committed technique is strong against
  one guard, neutral against one, and weak against one.
- Defense phase: choose High Guard, Side Guard, Brace, or Arcane Ward against the enemy's hidden
  attack.
- High Charge is stopped by High Guard and punishes Side Guard. Side Rush is stopped by Side Guard
  and punishes Brace. Leaping Strike is stopped by Brace and punishes High Guard.
- Magic actions can be pure damage, battle-only debuffs, or Magic-powered Wucht, Stich, and Hieb
  impacts. Impact magic uses the physical guard matrix. Arcane Ward sharply reduces pure magic and
  nullifies debuffs, but is exposed to physical and impact-magic attacks.
- AT drives physical damage, DF resists it, MG drives and resists magic, ATH strengthens committed
  techniques and Brace, and AGI controls physical accuracy/evasion.
- Roles alternate until the monster or hero reaches zero HP. Victory pays the listed gold reward;
  defeat restores the hero to 1 HP and loses up to 3 gold.

## Open questions

- PvP simultaneous reveal and role initiative remain to be designed; the current loop is PvE.
- Variance level: keep ×0.95–1.05 multiplier or wider?
- Battle skills per class: how many, when unlocked?
