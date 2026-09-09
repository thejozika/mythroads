import { useCallback, useEffect, useMemo, useState } from 'react'
import { getHankoClient } from './hanko-client.util'

type AuthState = 'loading' | 'authenticated' | 'unauthenticated'

export function useHankoAuth() {
    const [state, setState] = useState<AuthState>('loading')

    useEffect(() => {
        const hanko = getHankoClient()
        let cancelled = false
        void hanko
            .validateSession()
            .then(({ is_valid }) => {
                if (!cancelled) setState(is_valid ? 'authenticated' : 'unauthenticated')
            })
            .catch(() => {
                if (!cancelled) setState('unauthenticated')
            })
        const cleanups = [
            hanko.onSessionCreated(() => setState('authenticated')),
            hanko.onSessionExpired(() => setState('unauthenticated')),
            hanko.onUserLoggedOut(() => setState('unauthenticated')),
            hanko.onUserDeleted(() => setState('unauthenticated')),
        ]
        return () => {
            cancelled = true
            for (const cleanup of cleanups) cleanup()
        }
    }, [])

    const fetchAccessToken = useCallback(
        async ({ forceRefreshToken }: { forceRefreshToken: boolean }) => {
            const hanko = getHankoClient()
            if (forceRefreshToken) {
                const result = await hanko
                    .validateSession()
                    .catch(() => ({ is_valid: false }) as const)
                if (!result.is_valid) {
                    setState('unauthenticated')
                    return null
                }
            }
            return hanko.getSessionToken() || null
        },
        [],
    )

    return useMemo(
        () => ({
            isLoading: state === 'loading',
            isAuthenticated: state === 'authenticated',
            fetchAccessToken,
        }),
        [state, fetchAccessToken],
    )
}
