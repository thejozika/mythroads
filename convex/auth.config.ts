import type { AuthConfig } from 'convex/server'

declare const process: { env: Record<string, string | undefined> }

const issuer = process.env.HANKO_JWT_ISSUER
const audience = process.env.HANKO_JWT_AUDIENCE
const apiUrl = process.env.HANKO_API_URL

export default {
    providers:
        issuer && audience && apiUrl
            ? [
                  {
                      type: 'customJwt' as const,
                      applicationID: audience,
                      issuer,
                      jwks: `${apiUrl}/.well-known/jwks.json`,
                      algorithm: 'RS256' as const,
                  },
              ]
            : [],
} satisfies AuthConfig
