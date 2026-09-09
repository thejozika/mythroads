import { register } from '@teamhanko/hanko-elements'
import { useEffect, useState } from 'react'
import { getHankoClient } from './hanko-client.util'

function safeTarget(target?: string) {
    if (!target) return '/'
    try {
        const url = new URL(target, window.location.origin)
        return url.origin === window.location.origin ? url.pathname + url.search + url.hash : '/'
    } catch {
        return '/'
    }
}

export function HankoSignIn({ next }: { next?: string }) {
    const [ready, setReady] = useState(false)
    const [error, setError] = useState('')

    useEffect(() => {
        const apiUrl = import.meta.env.VITE_HANKO_API_URL
        if (!apiUrl) return
        const hanko = getHankoClient()
        const redirect = () => window.location.assign(safeTarget(next))
        const sessionCleanup = hanko.onSessionCreated(redirect)
        void register(apiUrl, { enablePasskeys: true })
            .then(() => setReady(true))
            .catch(() => setError('Authentication could not be loaded.'))
        return sessionCleanup
    }, [next])

    return (
        <main className="auth-shell">
            <section className="auth-card">
                <span className="eyebrow">Dicebound account</span>
                <h1>Enter the adventure</h1>
                <p>Your account securely reconnects you to the same hero on every device.</p>
                {!ready && !error && <div className="auth-loading">Opening the gate…</div>}
                {error ? <p className="error">{error}</p> : <hanko-auth />}
            </section>
        </main>
    )
}
