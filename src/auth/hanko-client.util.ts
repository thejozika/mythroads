import { Hanko } from '@teamhanko/hanko-elements'

let instance: Hanko | null = null

export function getHankoClient() {
    if (typeof window === 'undefined') throw new Error('Hanko is only available in the browser.')
    const apiUrl = import.meta.env.VITE_HANKO_API_URL
    if (!apiUrl) throw new Error('VITE_HANKO_API_URL is not configured.')
    if (!instance) instance = new Hanko(apiUrl)
    return instance
}
