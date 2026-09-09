# Authentication

Hanko owns accounts and sessions. Convex owns authorization and game data. A player ID in a URL or
local storage is a navigation hint, never proof that the caller controls that hero.

## Application boundaries

- `/display/:roomCode` is public and receives only public player identity and board position.
- `/`, `/join/:roomCode`, and `/controller/:roomCode/:playerId` require a Hanko session.
- The room creator's Hanko identity owns the host-only start command.
- A joined hero is bound to `identity.tokenIdentifier`; every player event and inventory query checks
  this value inside Convex.
- Returning accounts discover their existing hero from the room and reconnect without matching a
  name or color.
- All game mutations still enter through `game:dispatch`. Authentication is checked before replay
  deduplication and event routing.

## Hanko project setup

Create a dedicated Hanko Cloud project for the game. Configure its application URL and add both the
production domain and `http://localhost:5175` as allowed origins. Email passcodes and passkeys can
remain enabled.

Copy the public API URL into `VITE_HANKO_API_URL` in Vercel. Decode one real session JWT and record
its exact `iss` and `aud` claims. Set these variables on each matching Convex deployment:

| Variable | Value |
| --- | --- |
| `HANKO_API_URL` | Hanko tenant API URL used for `/.well-known/jwks.json` |
| `HANKO_JWT_ISSUER` | Exact session JWT `iss` claim |
| `HANKO_JWT_AUDIENCE` | Exact session JWT `aud` claim |

Convex verifies Hanko tokens using RS256. Do not reuse another product's tenant or audience.

## Local development

Real authentication is the preferred verification path. Until the dedicated Hanko tenant exists,
local development may set `DEV_NO_AUTH=true` on the local Convex deployment and leave
`VITE_HANKO_API_URL` unset. This bypass is deliberately controlled by two separate deployment
settings and must never be configured on preview or production.

## Vercel and Convex

`vercel.json` runs `npx convex deploy` around the Vite build, injects the matching deployment URL as
`VITE_CONVEX_URL`, and rewrites application routes to `index.html`. Vercel needs a production Convex
deploy key for production and a preview deploy key if isolated branch databases are desired.
