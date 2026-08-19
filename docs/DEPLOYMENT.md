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
.fvm/flutter_sdk/bin/flutter build web --release \
  --no-wasm-dry-run \
  --dart-define=TRANSMUTE_REPOSITORY_MODE=api \
  --dart-define=TRANSMUTE_API_BASE_URL=https://api.transmute.mzootfb.xyz
rsync -a --delete build/web/ release/web/
```

The public API URL is baked into the committed release bundle; it is not a
secret and is not a Coolify runtime variable.

The approved Flutter production origin is `https://transmute2.mzootfb.xyz`.
Configure the Fastify API's `CORS_ORIGINS` runtime variable to contain that
exact value. Do not add wildcard origins and do not leave the temporary
`trycloudflare.com` URL in production configuration.

## Coolify deployment

1. Create a **new** application for this Flutter project; do not replace the
   existing Expo web application without an explicit migration decision.
2. Select **Dockerfile** as the build pack, set base directory to `/`, and use
   `/Dockerfile`.
3. No Coolify environment variables are required; the committed release bundle
   is built with the public API URL before it is pushed.
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
