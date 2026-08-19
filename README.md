# Transmute Flutter demonstration

A focused, production-style Flutter demonstration of Transmute’s training-record
loop: sign in, choose a plan, preserve a single active session, log working
sets/rest, and review immutable completed history.

## Requirements

The project is pinned to Flutter `3.44.6` / Dart `3.12.2` in `.fvmrc`. The SDK
is expected at `.fvm/flutter_sdk` when using this checkout.

```sh
.fvm/flutter_sdk/bin/flutter pub get
```

## Run the live Transmute API

The Flutter app has a dedicated adapter for the existing Expo/Fastify `/v1`
API. It uses the same server and account data as the current Transmute app;
the endpoint contains no secret.

```sh
.fvm/flutter_sdk/bin/flutter run -d web-server \
  --web-hostname=localhost \
  --web-port=8081 \
  --dart-define=TRANSMUTE_REPOSITORY_MODE=api \
  --dart-define=TRANSMUTE_API_BASE_URL=https://api.transmute.mzootfb.xyz
```

Sign in or create an account normally. API mode persists bearer tokens in
secure storage and reads/writes canonical server data. This build also keeps a
separate local `Demo Login` path on the same screen; its fixture session uses
different local-storage keys and never contacts or changes a real account.
Open **`http://localhost:8081`** exactly. The current API CORS policy permits
that origin, but intentionally rejects `http://127.0.0.1:8081`; use a
different origin only after adding it to the API's `CORS_ORIGINS` allowlist.
For a same-origin reverse proxy, set `TRANSMUTE_API_BASE_URL=/`; Flutter will
resolve it to the browser's current HTTPS origin.

## Run the local demo

Mock mode is deliberate and needs no server. It presents one `Demo Login`
button and uses a resettable local fixture; it never contacts the API or
changes a real account.

```sh
.fvm/flutter_sdk/bin/flutter run -d chrome \
  --dart-define=TRANSMUTE_REPOSITORY_MODE=mock
```

Use `--dart-define=TRANSMUTE_MOCK_FAIL_FIRST_SET=true` to demonstrate the
retryable create-set failure path.

## Verification

```sh
.fvm/flutter_sdk/bin/dart format lib test
.fvm/flutter_sdk/bin/dart run build_runner build
.fvm/flutter_sdk/bin/flutter analyze
.fvm/flutter_sdk/bin/flutter test
.fvm/flutter_sdk/bin/flutter build web
.fvm/flutter_sdk/bin/flutter build macos
```

## Production deployment

The included Docker image builds the pinned Flutter web release and serves it
with Nginx, including direct-link fallback for GoRouter routes. See
[`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) for required build arguments, API
CORS configuration, health checks, and Coolify deployment steps.

The responsive shell uses bottom navigation below 600dp, a navigation rail from
600–1023dp, and the Expo-style header navigation from 1024dp. Check representative 375dp,
768dp, and 1440dp viewports during human browser QA.

## Architecture

- `lib/core/domain`: immutable domain concepts and repository interfaces.
- `lib/core/data`: mock repositories and fixtures for the full running loop.
- `lib/core/api`: Dio REST adapter, secure token storage, and Freezed DTO type.
- `lib/features`: authentication, workout plans, active session, and history UI.
- `lib/shared`: responsive Material 3 shell and tokens.

The active-session controller is the sole client mutation owner. When the API
advertises idempotent set replay, it stores validated pending sets in protected
device storage, retries them with the same operation ID, and blocks completion
until the server acknowledges them. It also persists rest as an absolute UTC
deadline, refreshes canonical session data, and invalidates history after
completion. See [`docs/DECISIONS.md`](./docs/DECISIONS.md).
