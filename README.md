# Dicebound prototype

A small 3D, web-based vertical slice for the Dice RPG design documents in this repository.

## What is playable

- A shared Three.js board at `/display/:roomCode`
- Phone joining via QR code at `/join/:roomCode`
- Private player stats and movement controls at `/controller/:roomCode`
- Convex-synchronized rooms, turns, players, health, and gold
- A `D4 + D6` starter movement loadout
- Exact movement with step-by-step choices at junctions and no immediate backtracking
- Automatic first-pass combat and event resolution
- An offline visual board at `/display/demo`

## Run the visual demo

```sh
npm install
npm run dev
```

Open `http://localhost:5175/display/demo`.

## Connect Convex for multiple screens

```sh
npm run dev:full
```

This repository is configured for a local Convex deployment. The command keeps Convex and Vite
running together and prints the computer's LAN address. Open that address on the main screen, create
a room, and scan its QR code from phones on the same network.

The phone route is `/controller/:roomCode`. It contains a virtual D-pad, ABXY buttons, private
stats, and inventory. The D-pad becomes active after the current player presses A to roll.

## Repository checks

```sh
npm run check
```

This runs architecture limits, quality-script tests, Biome lint/format checks, TypeScript, and the
production build. See `documents/engineering/code-architecture.md` for the filename taxonomy and
Three.js-specific module roles.

The current player ID stored by the phone is suitable for prototyping, not production authentication. Proper anonymous sessions and command authorization should be added before exposing rooms publicly.
