import { useMutation, useQuery } from 'convex/react'
import { useEffect, useMemo, useState } from 'react'
import { api } from '../../convex/_generated/api'
import { AuthGate } from '../auth/AuthGate.container'
import { HankoSignIn } from '../auth/HankoSignIn.container'
import { SignOutButton } from '../auth/SignOutButton.container'
import { Controller } from '../game/controller/Controller.container'
import { BoardDisplay } from '../game/display/BoardDisplay.component'
import { gameCommand } from '../game/game-event.util'
import type { DisplayRoomState } from '../game/game.type'
import { LeanDefinitions } from './LeanDefinitions.component'
const pathParts = () => window.location.pathname.split('/').filter(Boolean)

function OfflineNotice() {
    return (
        <div className="setup-card">
            <span className="eyebrow">Prototype ready</span>
            <h1>Connect Convex to play across screens</h1>
            <p>
                The 3D board is available in demo mode now. Run <code>npm run convex</code> once to
                create the real-time backend.
            </p>
            <div className="button-row">
                <button
                    type="button"
                    className="primary"
                    onClick={() => (window.location.href = '/display/demo')}
                >
                    Open board demo
                </button>
            </div>
        </div>
    )
}

function ConnectedHome() {
    const dispatch = useMutation(api.game.dispatch)
    const [joining, setJoining] = useState(false)
    const [code, setCode] = useState('')

    const create = async () => {
        const result = await dispatch(gameCommand({ type: 'room.create', subjects: {}, data: {} }))
        if (result.kind === 'room.created') window.location.href = `/display/${result.code}`
    }

    return (
        <main className="home">
            <div className="brand-mark">D20</div>
            <span className="eyebrow">A tiny playable beginning</span>
            <h1>Mythroads</h1>
            <p>Collect your movement dice. Choose the road. Survive what waits there.</p>
            <div className="button-row">
                <button type="button" className="primary" onClick={create}>
                    Create game
                </button>
                <button type="button" onClick={() => setJoining(!joining)}>
                    Join on phone
                </button>
            </div>
            {joining && (
                <form
                    className="join-inline"
                    onSubmit={(event) => {
                        event.preventDefault()
                        window.location.href = `/join/${code.toUpperCase()}`
                    }}
                >
                    <input
                        aria-label="Room code"
                        maxLength={4}
                        placeholder="ROOM CODE"
                        value={code}
                        onChange={(event) => setCode(event.target.value)}
                    />
                    <button type="submit" className="primary" disabled={code.length !== 4}>
                        Join
                    </button>
                </form>
            )}
        </main>
    )
}

function Home({ connected }: { connected: boolean }) {
    if (connected) return <ConnectedHome />
    return (
        <main className="home">
            <OfflineNotice />
        </main>
    )
}

function LiveDisplay({ code }: { code: string }) {
    const state = useQuery(api.rooms.queries.displayByCode, { code })
    const dispatch = useMutation(api.game.dispatch)
    if (state === undefined) return <div className="loading">Summoning the board…</div>
    if (!state) return <div className="loading">Room not found.</div>
    return (
        <BoardDisplay
            state={state}
            onStart={
                state.canStart
                    ? () =>
                          dispatch(
                              gameCommand({
                                  type: 'game.start',
                                  subjects: { roomId: state.room._id },
                                  data: {},
                              }),
                          )
                    : undefined
            }
        />
    )
}

const DEMO_STATE: NonNullable<DisplayRoomState> = {
    room: {
        _id: 'demo',
        code: 'DEMO',
        status: 'playing',
        activePlayerId: 'hero',
        remainingMoves: 0,
        lastRoll: [3, 4],
        message: 'Mira found 3 gold at the Wishing Tree.',
        round: 2,
    },
    players: [
        {
            _id: 'hero',
            name: 'Mira',
            color: '#4bd3c2',
            position: 4,
            previousPosition: 3,
            joinedAt: 1,
        },
        {
            _id: 'rival',
            name: 'Bram',
            color: '#ffbd59',
            position: 9,
            joinedAt: 2,
        },
    ],
    encounter: null,
    combat: null,
    selection: null,
    camera: null,
    canStart: false,
}

function ConnectedJoin({ code }: { code: string }) {
    const dispatch = useMutation(api.game.dispatch)
    const existingPlayerId = useQuery(api.rooms.queries.myPlayerByCode, { code })
    const [name, setName] = useState('')
    const [error, setError] = useState('')
    const colors = ['#4bd3c2', '#ffbd59', '#f875aa', '#71a7ff']
    const [color, setColor] = useState(colors[0])

    useEffect(() => {
        if (!existingPlayerId) return
        localStorage.setItem(`dicebound:${code}`, existingPlayerId)
        window.location.replace(`/controller/${code}/${existingPlayerId}`)
    }, [code, existingPlayerId])

    const join = async (event: React.FormEvent) => {
        event.preventDefault()
        try {
            const result = await dispatch(
                gameCommand({
                    type: 'player.join',
                    subjects: { code },
                    data: { name, color },
                }),
            )
            if (result.kind === 'player.joined') {
                localStorage.setItem(`dicebound:${code}`, result.playerId)
                window.location.href = `/controller/${code}/${result.playerId}`
            }
        } catch (caught) {
            setError(caught instanceof Error ? caught.message : 'Could not join room')
        }
    }

    return (
        <main className="phone-shell">
            <form className="controller-card join-card" onSubmit={join}>
                <span className="eyebrow">Joining room {code}</span>
                <h1>Choose your hero</h1>
                <p className="rejoin-hint">
                    {existingPlayerId === undefined
                        ? 'Checking for your hero…'
                        : 'Your account securely reconnects to this hero on every device.'}
                </p>
                <label>
                    Name
                    <input
                        required
                        maxLength={16}
                        value={name}
                        onChange={(event) => setName(event.target.value)}
                        placeholder="Your name"
                    />
                </label>
                <span className="field-label">Color</span>
                <div className="color-picker">
                    {colors.map((choice) => (
                        <button
                            type="button"
                            aria-label={choice}
                            aria-pressed={color === choice}
                            className={color === choice ? 'selected' : ''}
                            style={{ background: choice }}
                            onClick={() => setColor(choice)}
                            key={choice}
                        />
                    ))}
                </div>
                {error && <p className="error">{error}</p>}
                <button type="submit" className="primary big" disabled={!name}>
                    Enter game
                </button>
            </form>
        </main>
    )
}

function Join({ code, connected }: { code: string; connected: boolean }) {
    if (connected) return <ConnectedJoin code={code} />
    return (
        <main className="phone-shell">
            <div className="controller-card">
                <h1>Controller offline</h1>
                <p>Start the game with npm run dev:full, then scan the room code again.</p>
            </div>
        </main>
    )
}

function AuthSetupRequired() {
    return (
        <main className="auth-shell">
            <section className="auth-card">
                <span className="eyebrow">Authentication setup</span>
                <h1>Connect Hanko</h1>
                <p>Add VITE_HANKO_API_URL to enable secure accounts on this deployment.</p>
            </section>
        </main>
    )
}

export function App({
    connected,
    authConfigured,
    authBypassed,
}: {
    connected: boolean
    authConfigured: boolean
    authBypassed: boolean
}) {
    const parts = useMemo(pathParts, [])
    const [code] = useState(() => (parts[1] ?? '').toUpperCase())
    useEffect(() => {
        document.body.dataset.view = parts[0] ?? 'home'
    }, [parts])
    if (parts[0] === 'lean') return <LeanDefinitions />
    if (parts[0] === 'display' && code === 'DEMO') return <BoardDisplay state={DEMO_STATE} />
    if (parts[0] === 'display' && connected) return <LiveDisplay code={code} />
    if (parts[0] === 'sign-in') {
        if (!authConfigured) return <AuthSetupRequired />
        return <HankoSignIn next={new URLSearchParams(window.location.search).get('next') ?? '/'} />
    }
    if (!authConfigured) {
        if (!authBypassed) return <AuthSetupRequired />
        if (parts[0] === 'join') return <Join code={code} connected={connected} />
        if (parts[0] === 'controller' && connected)
            return <Controller code={code} routePlayerId={parts[2]} />
        return <Home connected={connected} />
    }
    if (parts[0] === 'join')
        return (
            <AuthGate>
                <ConnectedJoin code={code} />
            </AuthGate>
        )
    if (parts[0] === 'controller' && connected)
        return (
            <AuthGate>
                <Controller code={code} routePlayerId={parts[2]} />
                <SignOutButton compact />
            </AuthGate>
        )
    return (
        <AuthGate>
            <Home connected={connected} />
            <SignOutButton compact />
        </AuthGate>
    )
}
