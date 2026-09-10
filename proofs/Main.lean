import Mythroads.Authz

open Mythroads.Convex

def emitValidator : ValueType → String
  | .string => "v.string()"
  | .id table => s!"v.id('{table}')"
  | .optional inner => s!"v.optional({emitValidator inner})"
  | .custom validator _ => validator

def emitType : ValueType → String
  | .string => "string"
  | .id table => s!"Id<'{table}'>"
  | .optional inner => s!"{emitType inner} | undefined"
  | .custom _ typeName => typeName

def join (separator : String) : List String → String
  | [] => ""
  | [value] => value
  | value :: rest => value ++ separator ++ join separator rest

def emitArgs (fields : List Field) : String :=
  join ", " (fields.map fun field => s!"{field.name}: {emitValidator field.type}")

def emitArgType (fields : List Field) : String :=
  join "; " (fields.map fun field => s!"{field.name}: {emitType field.type}")

def emitQueryStep : QueryStep → String
  | .readOwnedInventory argument table index limit =>
      "        const identity = await ctx.auth.getUserIdentity()\n" ++
      "        if (!identity) throw new ConvexError('Sign in to view an inventory.')\n" ++
      s!"        const player = await ctx.db.get({argument})\n" ++
      "        if (!player) throw new ConvexError('That hero does not exist.')\n" ++
      "        if (!player.authId || identity.tokenIdentifier !== player.authId) {\n" ++
      "            throw new ConvexError('That inventory belongs to another account.')\n" ++
      "        }\n" ++
      s!"        return await ctx.db.query('{table}')\n" ++
      s!"            .withIndex('{index}', (q) => q.eq('{argument}', {argument}))\n" ++
      s!"            .take({limit})\n"

def emitMutationSteps : List MutationStep → String
  | [.authorizeEvent, .returnPriorCommand, .routeEvent, .persistEvent] =>
      "        const actorAuthId = await authorizeGameEvent(ctx, event)\n" ++
      "        const priorResult = await priorDispatchResult(ctx, commandId, actorAuthId)\n" ++
      "        if (priorResult) return priorResult\n" ++
      "        const result = await routeGameEvent(ctx, event, actorAuthId)\n" ++
      "        await persistGameEvent(ctx, event, result, commandId, actorAuthId)\n" ++
      "        return result\n"
  | _ => "        throw new Error('Unsupported generated mutation plan.')\n"

def emitEndpoint (endpoint : Endpoint) : String :=
  let context := match endpoint.plan with | .query _ => "QueryCtx" | .mutation _ => "MutationCtx"
  let body := match endpoint.plan with
    | .query steps => join "" (steps.map emitQueryStep)
    | .mutation steps => emitMutationSteps steps
  "export const " ++ endpoint.exportName ++ " = {\n" ++
  "    args: { " ++ emitArgs endpoint.args ++ " },\n" ++
  s!"    returns: {endpoint.returnsValidator},\n" ++
  "    handler: async (ctx: " ++ context ++ ", { " ++
  join ", " (endpoint.args.map (·.name)) ++ " }: { " ++ emitArgType endpoint.args ++
  " }) => {\n" ++
  body ++ "    },\n}\n"

def generatedHeader : String :=
  "/** Generated from proofs/Mythroads/*.lean. Do not edit by hand. */\n" ++
  "import { v } from 'convex/values'\n" ++
  "import type { MutationCtx } from '../_generated/server'\n" ++
  "import { authorizeGameEvent } from '../auth/authorization'\n" ++
  "import { persistGameEvent, priorDispatchResult } from '../events/persistence'\n" ++
  "import { routeGameEvent } from '../events/router'\n" ++
  "import { dispatchResultValidator, gameEventValidator } from '../events/validators'\n" ++
  "import type { GameEvent } from '../events/validators'\n\n"

def main : IO Unit :=
  IO.print (generatedHeader ++ join "\n" (gameApi.map emitEndpoint))
