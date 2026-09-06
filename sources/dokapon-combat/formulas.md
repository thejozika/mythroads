# Dokapon Kingdom — Damage, Accuracy, and Stat Formulas

Sources: GameFAQs damage-formula thread (74554371), Dokapon Wiki Damage (Kingdom), SP page, Steam dodge-calc thread, Desmos calculator (e7ssnqzwjp), supercheats Class Guide. Formulas come from community reverse-engineering; some pieces are still approximations.

---

## Stat → in-game value
- HP_actual = HP_stat × 10
- DF: 1 DF point ≈ 1.2 raw damage prevented; equivalently ≈ 1/8 of an HP-stat point in effective durability.
- AT vs DF break-even: ~2.333 DF needed to negate 1 AT (Damage page).

---

## Damage formulas

Common multiplicative tail: `× Guard × Proficiency × Random`
- **Random** = 0.95 or 1.05 (binary roll; no continuous range).
- **Guard** depends on the defender's chosen action:
  - Attacker = Attack & Defender = Defend → reduced (Guard < 1)
  - Defender chose unrelated action → Guard ≈ 1
- **Proficiency** = job/weapon affinity multiplier (jobs deal more with their preferred weapon).

### Basic Attack (vs Defend / vs unrelated)
`Damage = (Attacker_AT × k − Defender_DF) × Guard × Proficiency × Random`
where k is small (community fits suggest ~1.0–1.2). Attack accuracy is gated by SP (see below).

### Strike (vs anything other than Counter)
```
A = Attacker.AT + Attacker.MG + Attacker.SP
D = Defender.DF + Defender.MG + Defender.SP
Damage = (A × 2.5 − D) × Guard × Proficiency × Random
```
Strike ignores normal SP-based dodge — it lands at full rate.

### Counter (defender countered the attacker's Strike)
The attacker now takes the hit:
```
A = Attacker.AT − Attacker.DF        # attacker = the original strikerd
D = Defender.AT + Defender.MG + Defender.SP   # defender = the counterer
Damage = (D × 4 + A × 2) × Proficiency × Random
```
Counter is brutal — typically 2–3× the Strike's potential damage on the original striker.

### Offensive Magic (vs not Defensive Magic)
- Most spells: damage scales primarily off Attacker.MG vs Defender.MG.
- Some "physical-type" Offensive Magic uses Attacker.AT instead of MG.
- Always hits (no SP-based miss).
- If defender uses Defensive Magic: damage reduced and **the spell's status side-effect is nullified**, while the defender's Defensive Magic effect activates instead.

### Field Magic (overworld)
- Damage / chance to land scaled by attacker MG.
- Hit chance: `60% + Attacker.SP − Defender.SP`, clamped to [20%, 100%]. (≈ 1% per SP point.)

---

## Accuracy / Evasion in battle (Attack & Strike physical hit-roll)

Two community models, both clamped 50–100%:

### Original (Wii Kingdom)
- HitRate = 75% at equal SP.
- HitRate = 100% if Attacker.SP ≥ 3 × Defender.SP.
- HitRate = 50% if Attacker.SP ≤ Defender.SP / 3.
- Smooth interpolation in between.

### Connect-era community fit
- HitRate ≈ 75% + (Attacker.SP − Defender.SP) × 1% (per SP-point), clamped to [50, 100].
- A 40-SP differential maxes accuracy at 100% under this fit.

Strike & Magic ignore this roll (Strike lands; Magic always hits, only Defensive Magic mitigates).

---

## Critical hits
- Both Attack and Defend can roll **Critical**, amplifying damage / damage-reduction.
- Public sources do not specify the exact crit rate or multiplier — only that it exists and is not very common.
- Likely small flat % per action (community speculation, not confirmed).

---

## Stat sources (composite)
`Stat = Base + Sum(Level-up gains) + Mastery bonuses + Extras (story / casino) + Equipment`
Job-Level (different from character level) gates Battle Skills:
- Job-Level 1 → Charge (default for every class on switch)
- Job-Level 2 → class skill A
- Job-Level 4 → class skill B
- Job-Level 6 → mastery (permanent +1 stat per level afterwards)
- Job-Level rises every 6–7 battles fought.

### Per-level stat growth (supercheats Class Guide)
| Job | AT | DF | MG | SP | HP | Mastery bonus |
|-----|----|----|----|----|----|---------------|
| Warrior | +2 | +1 | 0 | 0 | +10 | +1 AT |
| Magician | 0 | 0 | +2 | +1 | +10 | +1 MG |
| Thief | +1 | 0 | 0 | +2 | +10 | +1 SP |
| Cleric | 0 | +1 | +1 | 0 | +20 | +1 DF |
| Spellsword | +2 | 0 | +2 | 0 | 0 | +1 AT |
| Alchemist | 0 | +1 | +2 | +1 | 0 | +1 MG |
| Ninja | +2 | 0 | 0 | +2 | 0 | +1 SP |
| Monk | +1 | +1 | 0 | 0 | +20 | +10 HP |
| Acrobat | +1 | +1 | 0 | +1 | +10 | — |
| Robo Knight | +1 | +2 | 0 | +1 | 0 | +1 DF |
| Hero | +1 | +1 | +1 | +1 | 0 + random | +1 AT |

---

## Status-effect tick formulas
- **Poison (Kingdom)**: −[character_level] HP per turn. Cannot kill — floors at 1 HP.
- **Poison (DX)**: −10% max HP per turn.
- **Z-Plague**: −2 × current_level HP per turn. **Can kill.** Spread on pass-by.
- **Sleep**: skip action; ends on damage taken or random expiry.
- **Curse**: 1 in N chance per battle action to attack self instead.

---

## Notes / caveats
- Numerical fits (k=2.5, ×4 + ×2 in Counter) are the most-cited community values; small variants exist between Wii and Connect releases.
- Guard / Proficiency multipliers are not fully tabulated publicly — Desmos/GitHub calculators implement them but treat as data tables, not closed forms.
- Crit, item-use ordering, and Battle-Skill scaling are largely empirical.
