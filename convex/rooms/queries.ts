import { query } from '../_generated/server'
import {
    controllerByCodeDefinition,
    displayByCodeDefinition,
    myPlayerByCodeDefinition,
} from './queries.generated'

export const displayByCode = query(displayByCodeDefinition)
export const controllerByCode = query(controllerByCodeDefinition)
export const myPlayerByCode = query(myPlayerByCodeDefinition)
