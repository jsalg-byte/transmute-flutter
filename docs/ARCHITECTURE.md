# Architecture

This repository is the Flutter client for Transmute's existing Expo/Fastify `/v1` API. The code is organized as a compact layered app, not as fully separated feature-local data/domain/presentation packages.

## Layers and modules

- `lib/app/app.dart` boots `MaterialApp.router`, defines the `GoRouter` route table and auth redirects, and selects the active `ThemeData`.
- `lib/core/domain/` contains shared immutable models, repository interfaces, domain calculations, and recovery logic. `AppFailure` is the user-facing repository error type.
- `lib/core/providers.dart` is the Riverpod composition root: it selects mock/API repositories, configures network and storage services, and owns shared async providers and controllers.
- `lib/core/api/api_repositories.dart` implements the repository interfaces over Dio and maps the actual `/v1` payloads into app models. `lib/core/data/mock_repositories.dart` implements the same interfaces against in-memory fixtures.
- `lib/core/data/pending_set_sync.dart` contains the durable pending-set queue and ordered idempotent replay.
- `lib/features/<feature>/presentation/` contains routed screens and their feature-specific UI/state interactions. Feature screens call providers or repositories through Riverpod, not Dio directly.
- `lib/shared/` contains the responsive `AppShell`, reusable widgets, theme palettes, and the original and Cute Pastel design systems.

## State and dependencies

The app starts under `ProviderScope`. `repositoryModeProvider` reads `TRANSMUTE_REPOSITORY_MODE` once (`mock` by default, `api` for the live service); each repository provider supplies either a mock or API implementation behind the same domain interface. HTTP configuration is in `dioProvider`; API mode requires `TRANSMUTE_API_BASE_URL`, and `/` resolves to the browser's current origin.

Riverpod `FutureProvider` and family providers own most read state (plans, history, nutrition, progress, goals, and details). Notifiers own longer-lived state and mutations where sequencing matters: `AuthController`, `ActiveSessionController`, `ArcanaController`, and local theme controllers. Mutations generally update or invalidate the relevant providers after repository success.

## API and authentication

`ApiAuthRepository` logs in/registers through `/v1/auth/*`, stores access/refresh credentials, and restores a cached session using `/v1/me` or `/v1/auth/refresh`. `AuthController` starts restoration when first created and publishes loading, signed-out, or signed-in state. Login and registration then load the saved weight unit from preferences when available.

The `/` route uses `PreLoginEntryRoute` to reactively show the loading splash only during restoration, then the three-slide guest introduction; signed-in users are redirected to the dashboard. Keep this route watching auth state: GoRouter refreshes redirects when auth changes, but the same public URL also needs its page widget to rebuild.

The shared Dio instance attaches the access token and uses `_AccessTokenRefreshInterceptor` for one-time 401 recovery. Concurrent requests can receive 401 together: before refreshing, the interceptor checks whether another request already replaced Dio's shared authorization header and retries with that token. It is a regular Dio `Interceptor`, not a `QueuedInterceptor`: refresh is coalesced through one shared future, while serializing an error callback that awaits its own retried request can deadlock if that retry also fails. `_request` converts Dio failures into `AppFailure` with status and retryability. API JSON parsing and model construction stay in the API repositories; keep mappings aligned to the verified service contract.

## Persistence

- The server is authoritative for user account data, plans, sessions, and records.
- `flutter_secure_storage` backs API credentials, the user-scoped pending-set queue, per-session rest deadlines, and device-local Cute Pastel/accessibility toggles. The demo login uses a separate credential namespace.
- Mock repository data is in-memory fixture state. There is no general local database or shared-preferences persistence layer in the current app.
- A rest timer is stored as an absolute UTC deadline and rendered from that deadline, rather than persisted as a ticking counter.

## Navigation and shell

`GoRouter` and `_RouterRefresh` in `lib/app/app.dart` hold the route table and refresh redirects when `AuthController` changes. Signed-out users are sent to `/`; signed-in users are directed from public entry routes to the dashboard or welcome flow. Most feature routes are top-level; `/friends/sessions/:sessionId`, `/plans/:planId`, and `/history/:sessionId[/share]` are nested detail routes. The design library route is debug-only.

Feature pages use `AppShell` from `lib/shared/widgets/app_shell.dart`. It presents bottom navigation below 600dp, a navigation rail from 600–1023dp, and a desktop header/navigation plus scroll surface from 1024dp upward. Keep route additions in `app.dart` and add their navigation affordance to the shell when appropriate.

## Workout and session flow

Plan screens read plans through `plansProvider`/`planProvider` and mutate through `PlanRepository`. The active plan is a separate account preference (`PreferencesRepository.activePlanId`), selectable in Settings or directly from plan details; selecting it does not start a session. The dashboard combines plan/preferences data, active-session state, history, and other records into overview cards. Beginning a planned workout calls `ActiveSessionController.start(planId, planDayId)`, which delegates to `SessionRepository.startSession`; the API adapter creates the server session using its plan-day ID, then fetches canonical session detail.

`ActiveSessionController` is the sole owner of active-session mutations. It loads the server's active session, restores pending device-local sets, and exposes add/remove exercise, set update/delete, rest, completion, and discard operations. If the API advertises offline set replay, a validated set is first queued in secure storage with a UUID operation ID and shown as pending. Retries run in order with that same ID; server acknowledgement refreshes canonical session detail. Completion is blocked while sets remain unsynced. Without that API capability, set creation uses the direct request path.

Quick Add uses a separate `QuickAddRepository` and dashboard flow to create an independent workout record; it does not start or alter the selected workout plan's active session. Completed history is read through `SessionRepository` and invalidated after completion/deletion.

## Shared repositories and services

The domain interfaces in `lib/core/domain/repositories.dart` are the boundary for plans, sessions, Quick Add, preferences, nutrition, progress, recovery, fasting, goals, planning, Arcana, friends, and auth. For an existing feature, add or extend its contract there, implement both API and mock versions, register/supply it through `providers.dart`, then connect the feature screen. Put reusable visual components or theme tokens in `lib/shared`; put calculations independent of Flutter in `lib/core/domain`.

Further details: [API contract](API_CONTRACT.md), [state transitions](STATE_TRANSITIONS.md), [domain model](DOMAIN_MODEL.md), [design system](DESIGN_SYSTEM.md), and [deployment](DEPLOYMENT.md).
