# Movement

How a turn unfolds: rolling, choosing direction, traveling, and what happens when a path crosses another player.

> Dokapon reference: spinner-roll → branching choice → resolve destination space. We replace the spinner with a multi-dice loadout (see [`dice.md`](dice.md)). Source: `../../sources/dokapon-core-loop/notes.md`.

## Turn structure

1. **Pre-roll phase.** Active player may swap dice in their loadout freely (no cost, no time limit; inside their own turn only).
2. **Roll.** All dice in the active loadout are rolled simultaneously. The total movement value is the **sum of the numeric faces** rolled. Dice are pure number generators — no effect faces, no triggers from rolling itself.
3. **Movement phase.** The player must move exactly the rolled total, choosing direction at every junction.
4. **Resolution phase.** The space the player ends on is resolved (battle, town, store, bank, event, treasure, trap, vending, quiz, warp, castle — see [`spaces.md`](spaces.md), planned).
5. **End-of-turn phase.** Active player may choose to **arm intercept** (see "Player collisions" below), then turn passes.

## Roll rules

- **Roll = sum of all rolled dice.** Numeric faces only. Standard dice yield 1–N depending on tier.
- **Must use the full roll.** No stopping early. The roll is a constraint that creates good and bad outcomes — central to the genre's identity.
- **Active dice loadout.** Players choose which subset of their dice inventory to roll with each turn, up to their **active slot cap** (see [`dice.md`](dice.md)).
- **Pre-set loadout, swap freely on your own turn.** No swap cost. Other players cannot react to your swap before the roll.

## Branching

- **Choose direction at every junction.** Maximum mid-roll agency — players can react to their roll and reroute.
- Branches are presented as on-board prompts; movement pauses until the player commits.
- **No backtracking within a single turn.** Once a direction is chosen at a junction, the player continues forward until the next junction or end-of-roll.

## Player collisions

- **Pass through harmlessly by default.** Crossing another player's space mid-roll triggers nothing.
- **Landing on another player's space** also triggers nothing by default.
- **Intercept arming** (the standing player's opt-in trap):
  - At the end of their turn, a player may declare **intercept** on their current space.
  - While intercept is armed, any other player who passes through OR lands on that space initiates PvP combat against the standing player.
  - Intercept is consumed on the first trigger, OR cleared at the start of the standing player's next turn (whichever comes first).
  - Intercept is publicly visible to all players.

This makes camping a real strategic choice — you forfeit movement to threaten anyone passing a chokepoint. It also keeps the roll's gamble alive without forcing every adjacency into combat.

## Dokapon-reference deltas

| Decision | Dokapon | Dice RPG |
|---|---|---|
| Roll source | Single 1–6 spinner | Multi-dice loadout, sum of rolled dice |
| Effects from rolling | None inherent (items/skills can modify) | None — dice are pure numbers |
| Branching | Per junction | Per junction (same) |
| Forced full roll | Yes | Yes (same) |
| Player collisions | Auto-PvP on landing | Opt-in via intercept arming |

## Open questions

- **Items that modify movement** — are they per-turn (one-shot consumables), passive (always-on while equipped), or both? See [`../items/overview.md`](../items/overview.md).
- **Status effects on movement** — sleep skips a turn; poison costs HP per move; speed-up grants extra dice or +N to total. To be defined in [`../combat/status-effects.md`](../combat/status-effects.md).
- **Stat-based movement bonuses** — does Speed (or our equivalent stat) modify the roll, grant slots, or both? Currently undecided. Affects how "speed builds" feel.
- **Intercept exhaustion** — does intercept persist multi-turn (until triggered) or clear at start of standing player's next turn? Current spec: clears at start of next turn. Worth playtesting.
- **Reverse movement** — any mechanic to send a player backwards? Currently none. Could be an item effect.
