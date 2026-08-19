# Deploying Transmute Flutter

This application is a static Flutter web app. The included `Dockerfile` builds
the pinned Flutter SDK release, then serves the result with Nginx on port 80.
It intentionally does not contain database credentials, JWT secrets, object
storage credentials, or an API proxy.

## Checked-in deployment configuration

- `docker-compose.yml` is the Coolify Docker Compose definition. It builds the
  root `Dockerfile`, exposes only internal port `80`, and carries a `/healthz`
  container health check.
- `.env.coolify.example` is the exact non-secret environment configuration to
  enter in Coolify. Do not commit an `.env` file with infrastructure secrets.
- There are deliberately no custom Docker networks or hand-written Traefik
  labels. In a normal Git-based Docker Compose application, Coolify owns the
  generated proxy labels and its managed network.

## Required production settings

Configure these Docker build arguments in the deployment system:

| Build argument | Required value |
| --- | --- |
| `TRANSMUTE_REPOSITORY_MODE` | `api` |
| `TRANSMUTE_API_BASE_URL` | The public HTTPS Fastify API URL, for example `https://api.transmute.mzootfb.xyz` |

The API base URL is public client configuration, not a secret. The Compose file
defaults to the production API URL but the explicit Coolify values above remain
the release configuration of record.

The approved Flutter production origin is `https://transmute2.mzootfb.xyz`.
Configure the Fastify API's `CORS_ORIGINS` runtime variable to contain that
exact value. Do not add wildcard origins and do not leave the temporary
`trycloudflare.com` URL in production configuration.

## Coolify deployment

1. Create a **new** application for this Flutter project; do not replace the
   existing Expo web application without an explicit migration decision.
2. Select **Docker Compose** as the build pack, set base directory to `/`, and
   set the Compose file to `docker-compose.yml`.
3. In Coolify Environment Variables, add the two values from
   `.env.coolify.example`: `TRANSMUTE_REPOSITORY_MODE=api` and
   `TRANSMUTE_API_BASE_URL=https://api.transmute.mzootfb.xyz`.
4. In the generated `Domains for transmute-flutter` field, set
   `https://transmute2.mzootfb.xyz`. Coolify will route it to port 80 and
   manage HTTPS; do not manually enable editable container labels.
5. Point the DNS `A`/`AAAA` record for `transmute2.mzootfb.xyz` at the Coolify
   server, then wait for DNS propagation before deployment.
6. Add `https://transmute2.mzootfb.xyz` to the API's `CORS_ORIGINS`, deploy the
   API setting, then deploy this app.

The repository now contains every non-secret application setting. DNS records,
the Coolify resource/domain entry, and the API runtime CORS setting remain
external control-plane changes because they belong to the deployment account,
not a source checkout.

## Pre-promotion checks

- `flutter analyze`
- `flutter test`
- `flutter build web --dart-define=TRANSMUTE_REPOSITORY_MODE=api --dart-define=TRANSMUTE_API_BASE_URL=<public-api-url>`
- `GET /healthz` returns `200`.
- Direct navigation to `/plans`, `/nutrition`, `/progress`, `/friends`, and
  `/history/<session-id>/share` returns the Flutter shell rather than a 404.
- A real account can sign in, refresh, sign out, and perform representative
  workout, upload, and nutrition mutations.

## Launch boundaries

The temporary phone tunnel is only a review environment. A public launch still
requires an approved hostname, source-control/deployment integration, live API
CORS configuration, real-account QA, and—if native distribution is included—
Apple/Google signing and physical-device verification.
