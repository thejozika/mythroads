import { ConvexProvider, ConvexProviderWithAuth, ConvexReactClient } from 'convex/react'
import type { ReactNode } from 'react'
import { useMemo } from 'react'
import { useHankoAuth } from './use-hanko-auth.hook'

export function AuthProvider({
    convexUrl,
    authConfigured,
    children,
}: {
    convexUrl?: string
    authConfigured: boolean
    children: ReactNode
}) {
    const client = useMemo(() => (convexUrl ? new ConvexReactClient(convexUrl) : null), [convexUrl])
    if (!client) return children
    if (!authConfigured) return <ConvexProvider client={client}>{children}</ConvexProvider>
    return (
        <ConvexProviderWithAuth client={client} useAuth={useHankoAuth}>
            {children}
        </ConvexProviderWithAuth>
    )
}
