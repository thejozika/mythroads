# Meta

The frame around a match: modes, win conditions, session length, multiplayer rules, death and revival, catch-up systems.

## Scope

- **Modes** — story mode, sandbox/normal mode, quick mode, single-player vs multiplayer.
- **Win condition** — net worth, total cash, target score, last-player-standing, or a hybrid.
- **Session structure** — turn limits, weeks, end-of-match resolution.
- **Multiplayer** — player count (2–4?), local vs online, AI opponents, hot-seat.
- **Death and revival** — KO consequences, hospital/wait time, escalating penalties.
- **Catch-up mechanics** — our Darkling-equivalent and any other rubber-banding tools.
- **Save / resume** — match persistence between sessions.

## Dokapon reference

Story Mode = prologue + 8 chapters across 7 continents (~20–30 h). Normal Mode = sandbox of 1–99 weeks. Win = highest **Net Worth** (Normal) or most **Cash G** (Story). Death has 3 escalating penalties (Cherub / Dark Angel / Grim Reaper). The **Darkling** is the catch-up mechanic: chronic last-place players surrender everything for 14 days as an overpowered curse-form that can steal towns/castles. See `../../sources/dokapon-core-loop/notes.md` and `../../sources/design-patterns/notes.md` (catch-up taxonomy).

## Files in this folder

- `overview.md` — this file
- `modes.md` — story / sandbox / quick (planned)
- `win-conditions.md` — scoring formulas, end-of-match resolution (planned)
- `session-structure.md` — week count, turn limits, pacing targets (planned)
- `multiplayer.md` — player count, local/online, AI design (planned)
- `death-and-revival.md` — KO penalties, hospital, escalation (planned)
- `catch-up.md` — Darkling-equivalent and other rubber-banding (planned)

## Open questions

- Target session length — Dokapon's 20–30 h Story is a hard sell. 60–90 min, 3–4 h, or open-ended?
- Win condition — Net Worth (Dokapon), KOs, hybrid Norma-style flip, or something new?
- Player count — 2–4 like Dokapon, or scale up?
- Online from day one, or local-first?
- Single-player viability — solo campaign, AI bots, async, or "designed for groups"?
- Catch-up — keep a Darkling-style player-routed mechanic (the genre survey identifies these as the only ones that feel fair).
