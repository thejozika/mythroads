import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { App } from './app/App.container'
import { AuthProvider } from './auth/AuthProvider.container'
import './auth/auth.css'
import './base.css'
import './styles.css'

const convexUrl = import.meta.env.VITE_CONVEX_URL as string | undefined
const authConfigured = Boolean(import.meta.env.VITE_HANKO_API_URL)
const authBypassed = import.meta.env.DEV && import.meta.env.VITE_DEV_NO_AUTH === 'true'

const rootElement = document.getElementById('root')
if (!rootElement) throw new Error('Missing application root element')
const root = createRoot(rootElement)
root.render(
    <StrictMode>
        <AuthProvider convexUrl={convexUrl} authConfigured={authConfigured}>
            <App
                connected={Boolean(convexUrl)}
                authConfigured={authConfigured}
                authBypassed={authBypassed}
            />
        </AuthProvider>
    </StrictMode>,
)
