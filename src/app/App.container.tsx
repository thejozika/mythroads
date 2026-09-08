import { useMutation, useQuery } from 'convex/react'
import { useEffect, useMemo, useState } from 'react'
import { api } from '../../convex/_generated/api'
import { Controller } from '../game/controller/Controller.container'
import { BoardDisplay } from '../game/display/BoardDisplay.component'
import { gameCommand } from '../game/game-event.util'
import type { RoomState } from '../game/game.type'

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
            <h1>Dicebound</h1>
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
    const state = useQuery(api.rooms.byCode, { code })
    const dispatch = useMutation(api.game.dispatch)
    if (state === undefined) return <div className="loading">Summoning the board…</div>
    if (!state) return <div className="loading">Room not found.</div>
    return (
        <BoardDisplay
            state={state}
            onStart={() =>
                dispatch(
                    gameCommand({
                        type: 'game.start',
                        subjects: { roomId: state.room._id },
                        data: {},
                    }),
                )
            }
        />
    )
}

const DEMO_STATE: NonNullable<RoomState> = {
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
            gold: 12,
            hp: 9,
            maxHp: 10,
            attack: 2,
            dice: [4, 6],
            joinedAt: 1,
        },
        {
            _id: 'rival',
            name: 'Bram',
            color: '#ffbd59',
            position: 9,
            gold: 8,
            hp: 7,
            maxHp: 10,
            attack: 3,
            dice: [4, 6],
            joinedAt: 2,
        },
    ],
    encounter: null,
    combat: null,
    selection: null,
    camera: null,
}

function ConnectedJoin({ code }: { code: string }) {
    const dispatch = useMutation(api.game.dispatch)
    const [name, setName] = useState('')
    const [error, setError] = useState('')
    const colors = ['#4bd3c2', '#ffbd59', '#f875aa', '#71a7ff']
    const [color, setColor] = useState(colors[0])

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
                    Returning? Enter the same name and choose the same color to reconnect.
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

export function App({ connected }: { connected: boolean }) {
    const parts = useMemo(pathParts, [])
    const [code] = useState(() => (parts[1] ?? '').toUpperCase())
    useEffect(() => {
        document.body.dataset.view = parts[0] ?? 'home'
    }, [parts])
    if (parts[0] === 'display' && code === 'DEMO') return <BoardDisplay state={DEMO_STATE} />
    if (parts[0] === 'display' && connected) return <LiveDisplay code={code} />
    if (parts[0] === 'join') return <Join code={code} connected={connected} />
    if (parts[0] === 'controller' && connected)
        return <Controller code={code} routePlayerId={parts[2]} />
    return <Home connected={connected} />
}
