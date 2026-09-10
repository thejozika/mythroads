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
import type * as events_authority from "../events/authority.js";
import type * as events_persistence from "../events/persistence.js";
import type * as events_policy from "../events/policy.js";
import type * as events_retention from "../events/retention.js";
import type * as events_validators from "../events/validators.js";
import type * as game from "../game.js";
import type * as rooms_queries from "../rooms/queries.js";
import type * as shops from "../shops.js";

import type {
  ApiFromModules,
  FilterApi,
  FunctionReference,
} from "convex/server";

declare const fullApi: ApiFromModules<{
  "auth/authorization": typeof auth_authorization;
  "events/authority": typeof events_authority;
  "events/persistence": typeof events_persistence;
  "events/policy": typeof events_policy;
  "events/retention": typeof events_retention;
  "events/validators": typeof events_validators;
  game: typeof game;
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
