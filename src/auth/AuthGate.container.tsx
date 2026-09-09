import { useConvexAuth } from 'convex/react'
import type { ReactNode } from 'react'
import { HankoSignIn } from './HankoSignIn.container'

export function AuthGate({ children }: { children: ReactNode }) {
    const { isLoading, isAuthenticated } = useConvexAuth()
    if (isLoading) return <div className="loading">Checking your account…</div>
    if (!isAuthenticated) return <HankoSignIn next={window.location.pathname} />
    return children
}
