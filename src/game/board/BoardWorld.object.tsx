import { BOARD, reachableRoutes } from '../../../shared/board.system'
import type { Player } from '../game.type'
import { BoardGround } from './BoardGround.object'
import { BoardPawn } from './BoardPawn.object'
import { BoardRoads } from './BoardRoads.object'
import { BoardSpace } from './BoardSpace.object'

type BoardWorldProps = {
    players: Player[]
    activePlayer?: Player
    remainingMoves: number
    selectedDestination?: number
    selectedPath?: number[]
}

export function BoardWorld({
    players,
    activePlayer,
    remainingMoves,
    selectedDestination,
    selectedPath,
}: BoardWorldProps) {
    const targeting = selectedDestination !== undefined
    const reachable = new Set(
        targeting && activePlayer && remainingMoves > 0
            ? reachableRoutes(
                  activePlayer.position,
                  activePlayer.previousPosition,
                  remainingMoves,
              ).map((route) => route.destination)
            : [],
    )
    const selectedRoute =
        activePlayer && selectedPath ? [activePlayer.position, ...selectedPath] : undefined
    return (
        <>
            <BoardGround />
            <BoardRoads selectedRoute={selectedRoute} />
            {BOARD.map((node) => (
                <BoardSpace
                    key={node.id}
                    node={node}
                    reachable={reachable.has(node.id)}
                    selected={node.id === selectedDestination}
                />
            ))}
            {players.map((player, index) => (
                <BoardPawn
                    key={player._id}
                    player={player}
                    offset={index - (players.length - 1) / 2}
                />
            ))}
        </>
    )
}
