import { ConvexProvider, ConvexReactClient } from 'convex/react'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { App } from './app/App.container'
import './base.css'
import './styles.css'

const convexUrl = import.meta.env.VITE_CONVEX_URL as string | undefined

const rootElement = document.getElementById('root')
if (!rootElement) throw new Error('Missing application root element')
const root = createRoot(rootElement)
root.render(
    <StrictMode>
        {convexUrl ? (
            <ConvexProvider client={new ConvexReactClient(convexUrl)}>
                <App connected />
            </ConvexProvider>
        ) : (
            <App connected={false} />
        )}
    </StrictMode>,
)
