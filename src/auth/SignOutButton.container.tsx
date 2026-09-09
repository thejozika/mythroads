import { getHankoClient } from './hanko-client.util'

export function SignOutButton({ compact = false }: { compact?: boolean }) {
    return (
        <button
            type="button"
            className={compact ? 'auth-sign-out compact' : 'auth-sign-out'}
            onClick={async () => {
                await getHankoClient().logout()
                window.location.assign('/')
            }}
        >
            Sign out
        </button>
    )
}
