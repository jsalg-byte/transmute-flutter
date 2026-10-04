# Deploying Transmute Flutter

This application is a static Flutter web app. The checked-in `release/web`
bundle is served by the included native Nginx image on port 80. This avoids
emulating Flutter's AMD64 Linux SDK on the ARM64 Coolify host. It intentionally
does not contain database credentials, JWT secrets, object storage credentials,
or an API proxy.

## Checked-in deployment configuration

- `Dockerfile` is the Coolify build definition. It serves the release bundle
  on internal port `80` and carries a `/healthz` container health check.
- There are deliberately no custom Docker networks or hand-written Traefik
  labels. In a normal Git-based Docker Compose application, Coolify owns the
  generated proxy labels and its managed network.

## Required production settings

Build the API-mode bundle before committing a release:

```sh
./scripts/build_web_release.sh
```

The public API URL is baked into the committed release bundle; it is not a
secret and is not a Coolify runtime variable. The script also versions the
Flutter bootstrap and application URLs so browsers cannot reuse an old bundle
after a deployment.

For API changes that add schema requirements, apply and verify the matching
numbered migration in the sibling `transmute-mobile/api/migrations/` repo
(locally `/Users/mzootfb/Sites/transmute-mobile/api/migrations/`) before
deploying the API code. Coolify does not run migrations automatically. Deploy
the migration and compatible API code before promoting a Flutter bundle that
uses new fields.

The approved Flutter production origin is `https://transmute.mzootfb.xyz`.
Configure the Fastify API's `CORS_ORIGINS` runtime variable to contain that
exact value. Do not add wildcard origins and do not leave the temporary
`trycloudflare.com` URL in production configuration.

## Current production topology and release order

- Flutter web: this repository, `release/web`, Dockerfile/Nginx, public origin
  `https://transmute.mzootfb.xyz`.
- API: sibling `/Users/mzootfb/Sites/transmute-mobile`, Fastify service at
  `https://api.transmute.mzootfb.xyz`; the sibling Expo app is a separate client.
- Coolify watches the production Git branches. A pushed source commit can
  deploy, but Flutter changes are only visible when the same commit contains a
  freshly generated `release/web` bundle.

For a release that changes both API and Flutter, apply and verify the required
API migration first, push/deploy the API, then run
`./scripts/build_web_release.sh` and push the Flutter source plus bundle. Do not
assume that migration files have been applied just because they exist in Git;
inspect the live schema and affected catalog/data. Migrations 008 (timed
prescriptions/session tracking), 009 (shared exercise demos), and 010 (bundled
reverse-curl demo mapping) were verified applied to production on 2026-10-03;
recheck before any later release. Production CORS and secrets stay in the API's
Coolify runtime settings, not in Dart defines or the web bundle.

After push, verify the running container image revisions match the commits,
check the API health plus affected schema/data, and confirm the served Flutter
index references the current cache version and required assets. The user owns
interactive browser verification; a healthy container or successful static
build is not visual QA.

## Pre-promotion checks

- `flutter analyze`
- `flutter test`
- `./scripts/build_web_release.sh` succeeds and includes the new assets.
- The web container health check (`/healthz`) and API health (`/health`) return
  `200`; also verify affected authenticated API behavior/schema, not health alone.
- Direct navigation to `/plans`, `/nutrition`, `/progress`, `/friends`, and
  `/history/<session-id>/share` returns the Flutter shell rather than a 404.
- A real account can sign in, refresh, sign out, and perform representative
  workout, upload, and nutrition mutations.

## Launch boundaries

The temporary phone tunnel is only a review environment. A public launch still
requires an approved hostname, source-control/deployment integration, live API
CORS configuration, real-account QA, and—if native distribution is included—
Apple/Google signing and physical-device verification.
