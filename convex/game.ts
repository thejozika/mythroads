import { internalMutation, mutation } from './_generated/server'
import {
    dispatchMutationDefinition,
    executeMutationDefinition,
} from './generated/game-api.generated'

export const dispatch = mutation(dispatchMutationDefinition)
export const execute = internalMutation(executeMutationDefinition)
