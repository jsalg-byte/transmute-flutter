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
- `lib/shared/widgets/exercise_video_controller.dart` routes ordinary public URLs to network playback and `asset://` values to Flutter's asset bundle. Shared demo defaults can therefore use a packaged video such as `assets/reverse_curl.webm` across Flutter web/native builds.

## State and dependencies

The app starts under `ProviderScope`. `repositoryModeProvider` reads `TRANSMUTE_REPOSITORY_MODE` once (`mock` by default, `api` for the live service); each repository provider supplies either a mock or API implementation behind the same domain interface. HTTP configuration is in `dioProvider`; API mode requires `TRANSMUTE_API_BASE_URL`, and `/` resolves to the browser's current origin.

Riverpod `FutureProvider` and family providers own most read state (plans, history, nutrition, progress, goals, and details). Notifiers own longer-lived state and mutations where sequencing matters: `AuthController`, `ActiveSessionController`, `ArcanaController`, and local theme controllers. Mutations generally update or invalidate the relevant providers after repository success.

## API and authentication

`ApiAuthRepository` logs in/registers through `/v1/auth/*`, stores access/refresh credentials, and restores a cached session using `/v1/me` or `/v1/auth/refresh`. `AuthController` starts restoration when first created and publishes loading, signed-out, or signed-in state. Login and registration then load the saved weight unit from preferences when available.

The `/` route uses `PreLoginEntryRoute` to reactively show the loading splash only during restoration, then the three-slide guest introduction; signed-in users are redirected to the dashboard. Keep this route watching auth state: GoRouter refreshes redirects when auth changes, but the same public URL also needs its page widget to rebuild.

The auth-restoration splash is intentionally branded with `assets/transmute/ouroboros.svg`, rotated by a lightweight repeating animation. It stops when the platform requests reduced motion and keeps a single semantic “Loading Transmute” announcement.

The shared Dio instance attaches the access token and uses `_AccessTokenRefreshInterceptor` for one-time 401 recovery. Concurrent requests can receive 401 together: before refreshing, the interceptor checks whether another request already replaced Dio's shared authorization header and retries with that token. It is a regular Dio `Interceptor`, not a `QueuedInterceptor`: refresh is coalesced through one shared future, while serializing an error callback that awaits its own retried request can deadlock if that retry also fails. `_request` converts Dio failures into `AppFailure` with status and retryability. API JSON parsing and model construction stay in the API repositories; keep mappings aligned to the verified service contract.

## Persistence

- The server is authoritative for user account data, plans, sessions, and records.
- `flutter_secure_storage` backs API credentials, the user-scoped pending-set queue, per-session rest deadlines, and device-local Cute Pastel/accessibility toggles. The demo login uses a separate credential namespace.
- Mock repository data is in-memory fixture state. There is no general local database or shared-preferences persistence layer in the current app.
- A rest timer is stored as an absolute UTC deadline and rendered from that deadline, rather than persisted as a ticking counter.

## Navigation and shell

`GoRouter` and `_RouterRefresh` in `lib/app/app.dart` hold the route table and refresh redirects when `AuthController` changes. Signed-out users are sent to `/`; signed-in users are directed from public entry routes to the dashboard or welcome flow. Most feature routes are top-level; `/friends/sessions/:sessionId`, `/plans/:planId`, and `/history/:sessionId[/share]` are nested detail routes. The design library route is debug-only.

Feature pages use `AppShell` from `lib/shared/widgets/app_shell.dart`. It presents six primary destinations (Workout, Today, Ranks, Nutrition, Friends, Profile) as bottom navigation below 600dp, a navigation rail from 600–1023dp, and a sidebar plus independent content scroll surface from 1024dp upward. The shell menu keeps existing secondary routes reachable. Keep route additions in `app.dart` and add their navigation affordance to the shell when appropriate.

## Workout and session flow

Plan screens read plans through `plansProvider`/`planProvider` and mutate through `PlanRepository`. The active plan is a separate account preference (`PreferencesRepository.activePlanId`), selectable in Settings or directly from plan details; selecting it does not start a session. `workoutEntryProvider` combines saved plans and this preference without waiting on history or recovery. Today and Workout use the same `WorkoutLaunchCard`, with `activeSessionProvider` as the canonical Start/Resume gate. `nextWorkoutRecommendationProvider` uses completed summaries only to choose a suggested day; if that read fails, the card still offers a saved-day picker. `recoveryOverviewProvider` reads historical details independently, so its error cannot hide workout entry. Beginning a planned workout calls `ActiveSessionController.start(planId, planDayId)`, which delegates to `SessionRepository.startSession`; the API adapter creates the server session using its plan-day ID, then fetches canonical session detail.

In the routine UI, a `WorkoutPlan` is a folder and each `WorkoutPlanDay` is a startable routine. Workout previews come from the canonical `plansProvider` read, and editing deep-links to `/plans/:planId?dayId=:dayId`. The Flutter API adapter creates empty folders explicitly, while the legacy API request without `empty` still creates Day 1. Day and prescription order are server-owned `sortOrder` values. Routine deletion is blocked for any day with a workout session so the existing history joins remain intact.

Routine sharing stays inside `PlanRepository`. Owner review and recipient preview use `RoutineShare`/`RoutineShareSnapshot` models and the API/mock adapters; `/routine-shares/:token` is protected by sign-in, with an allowed login return path for an incoming link. The server, not Flutter, captures the ordered snapshot, expiry/revocation state, canonical kg weights, and source attribution. Import creates an independent routine day in a caller-selected folder. Do not repurpose the existing friend-only shared workout-record route for routine sharing.

`ActiveSessionController` is the sole owner of active-session mutations. It loads the server's active session, restores pending device-local sets, and exposes add/remove exercise, set update/delete, rest, completion, and discard operations. If the API advertises offline set replay, a validated set is first queued in secure storage with a UUID operation ID and shown as pending. Retries run in order with that same ID; server acknowledgement refreshes canonical session detail. Completion is blocked while sets remain unsynced. Without that API capability, set creation uses the direct request path.

Each plan-day prescription carries `trackingMode` (`reps` or `timed`); timed mode also carries `targetDurationSeconds`. The active-session UI follows that prescription and writes either repetitions or elapsed `durationSeconds`, never both. The API persists timed duration separately from weight/reps; see [API_CONTRACT.md](API_CONTRACT.md) and [DECISIONS.md](DECISIONS.md) before changing the mapping.

The active screen keeps an exercise switcher above a compact set ledger and a persistent rest/next/finish footer. Per-set previous values come from the latest completed session with the same exercise ID and tracking mode. Drafts are editable until submitted; acknowledged rows can be edited or deleted through the controller; queued rows remain visibly pending and block Finish. The API adapter maps the verified `previousPerformances.durationSeconds` field, while mock mode derives the same comparison from completed sessions. Rest writes update controller state only after local persistence succeeds.

The Workout home also starts an empty multi-exercise session through `ActiveSessionController.startFreeform` and `SessionRepository.startFreeformSession`. The API persists `origin=freeform` with null routine/day references; the exercise picker and logger then use the same session-exercise, set and completion routes as a planned session. The planned and freeform start endpoints lock the user row, with migration 011 enforcing one active session at the database level. Quick Add uses a separate `QuickAddRepository` and dashboard flow to create an independent completed single-exercise record with `origin=quick_add`; it does not start or alter the selected workout plan's active session. Completed history is read through `SessionRepository` and invalidated after completion/deletion.

## Shared repositories and services

The domain interfaces in `lib/core/domain/repositories.dart` are the boundary for plans, sessions, Quick Add, preferences, nutrition, progress, recovery, fasting, goals, planning, Arcana, friends, and auth. For an existing feature, add or extend its contract there, implement both API and mock versions, register/supply it through `providers.dart`, then connect the feature screen. Put reusable visual components or theme tokens in `lib/shared`; put calculations independent of Flutter in `lib/core/domain`.

Further details: [API contract](API_CONTRACT.md), [state transitions](STATE_TRANSITIONS.md), [domain model](DOMAIN_MODEL.md), [design system](DESIGN_SYSTEM.md), and [deployment](DEPLOYMENT.md).
