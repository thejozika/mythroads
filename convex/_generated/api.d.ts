/* eslint-disable */
/**
 * Generated `api` utility.
 *
 * THIS CODE IS AUTOMATICALLY GENERATED.
 *
 * To regenerate, run `npx convex dev`.
 * @module
 */

import type * as auth_authorization from "../auth/authorization.js";
import type * as camera from "../camera.js";
import type * as combat from "../combat.js";
import type * as encounters from "../encounters.js";
import type * as events_authority from "../events/authority.js";
import type * as events_persistence from "../events/persistence.js";
import type * as events_policy from "../events/policy.js";
import type * as events_retention from "../events/retention.js";
import type * as events_router from "../events/router.js";
import type * as events_validators from "../events/validators.js";
import type * as game from "../game.js";
import type * as gameHelpers from "../gameHelpers.js";
import type * as landings from "../landings.js";
import type * as players from "../players.js";
import type * as rooms from "../rooms.js";
import type * as rooms_queries from "../rooms/queries.js";
import type * as shops from "../shops.js";

import type {
  ApiFromModules,
  FilterApi,
  FunctionReference,
} from "convex/server";

declare const fullApi: ApiFromModules<{
  "auth/authorization": typeof auth_authorization;
  camera: typeof camera;
  combat: typeof combat;
  encounters: typeof encounters;
  "events/authority": typeof events_authority;
  "events/persistence": typeof events_persistence;
  "events/policy": typeof events_policy;
  "events/retention": typeof events_retention;
  "events/router": typeof events_router;
  "events/validators": typeof events_validators;
  game: typeof game;
  gameHelpers: typeof gameHelpers;
  landings: typeof landings;
  players: typeof players;
  rooms: typeof rooms;
  "rooms/queries": typeof rooms_queries;
  shops: typeof shops;
}>;

/**
 * A utility for referencing Convex functions in your app's public API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = api.myModule.myFunction;
 * ```
 */
export declare const api: FilterApi<
  typeof fullApi,
  FunctionReference<any, "public">
>;

/**
 * A utility for referencing Convex functions in your app's internal API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = internal.myModule.myFunction;
 * ```
 */
export declare const internal: FilterApi<
  typeof fullApi,
  FunctionReference<any, "internal">
>;

export declare const components: {};
