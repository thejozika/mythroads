# Combat

The battle system: how two combatants resolve a fight, the choices each makes, the stats that drive damage, and the status effects that modify it.

## Scope

- **RPS (rock-paper-scissors) decision layer** — attacker and defender choose actions simultaneously; outcome depends on the matchup.
- **Stats** — HP, attack, defense, magic, speed (or our equivalents), how they're computed from level + class + equipment.
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

## Open questions

- Keep the 5-stat shape (HP/AT/DF/MG/SP) or simplify?
- How many RPS actions in the MVP — keep all 8 or trim?
- Variance level: keep ×0.95–1.05 multiplier or wider?
- Battle skills per class: how many, when unlocked?
