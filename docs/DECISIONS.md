# Implementation decisions and gotchas

These notes capture behavior and constraints that are easy to break while changing this client. For the module map and data flow, see [ARCHITECTURE.md](ARCHITECTURE.md). The production release process is in [DEPLOYMENT.md](DEPLOYMENT.md).

## Keep the API contract explicit

- The app adapts the existing Expo/Fastify `/v1` API; its record endpoints are aggregate read models, not a separate Flutter-specific API. Keep wire parsing in `lib/core/api/api_repositories.dart` and follow the documented fields in [API_CONTRACT.md](API_CONTRACT.md). Do not infer alternate casing, legacy aliases, or equivalent-looking fields without verified contract evidence. This has caused misleading mappings in past work.
- `RepositoryMode` selects the mock or API implementation centrally in `lib/core/providers.dart`. Both implementations should satisfy the same repository interface. Mock mode is an isolated local fixture, not a shadow copy of real account data.
- The API owns durable account/workout/record data. A client-side preview or optimistic state is not server confirmation; preserve the repository's explicit pending/error status until the API confirms a write.

## Authentication and concurrent API requests

- `ApiAuthRepository` persists access/refresh tokens in `flutter_secure_storage`. `_AccessTokenRefreshInterceptor` in `lib/core/api/api_repositories.dart` handles one 401 retry.
- Several providers can request data together on route entry. If simultaneous 401s each rotate the refresh token, a later refresh can fail because the first request already replaced it. Before refreshing, compare the failed request's `Authorization` header with Dio's current shared header; if it changed, retry with that newer token. Do not remove this check as redundant.
- Keep `_AccessTokenRefreshInterceptor` as a regular Dio `Interceptor`, not `QueuedInterceptor`. Its error handler awaits the retried request; a serialized error queue can deadlock when the retry itself gets a 401 and has to enter that same queue. `_refreshing` coalesces concurrent refresh calls, and the changed-header check handles requests that fail after another request refreshed. `test/expo_adapter_test.dart` covers a successful refresh and concurrent unauthorized retries that must terminate.
- Settings loads preferences and plan data, while app theme resolution also reads theme preferences. A Settings spinner can therefore come from an auth/API dependency race, not from Cute Pastel rendering. Diagnose the route's requests and auth state before changing theme code. Dio currently has 10-second connect and 15-second send/receive timeouts.
- Bound auth restoration in `AuthController`: secure-storage reads can stall in browser contexts, so public routes must not remain on the startup splash forever (mock restore gets 3 seconds; API restore gets 35 seconds for its network timeouts). `/` also needs a Riverpod-watching entry widget; a router refresh alone may not rebuild the same URL after loading ends.
- The auth-restoration indicator uses the product's Ouroboros SVG, not a generic fitness icon. It rotates continuously during loading, but `MediaQuery.disableAnimations` leaves it static for reduced-motion users; retain the `Loading Transmute` semantic label. Focused coverage lives in `test/pre_login_onboarding_screen_test.dart`.

## Active workout and set logging

- The UI supports one active workout at a time. A second start attempt should recover/show the existing active session rather than create a parallel one; set ordering and completion depend on this invariant. See `ActiveSessionController.start` in `lib/core/providers.dart`.
- `ActiveSessionController` is the sole owner of active-session mutations. Avoid moving optimistic set updates, retries, or invalidation into individual widgets.
- Offline set replay is capability-gated. `ApiSessionRepository.supportsOfflineSetSync()` queues sets only when `/v1/capabilities` explicitly reports `offlineSetSync: true`; older API deployments use direct online writes. Never enqueue an idempotent replay command based on an assumed server capability.
- With replay enabled, a set is written to secure device storage first with a stable UUID `clientOperationId`. Retries must reuse that ID, stay ordered, and only remove the command after API acknowledgement. The UI may display a pending set, but completion must remain blocked while its queue entries are unsynced. Retryable network/server errors remain queued; permanent rejection is retained as blocked for user resolution.
- The first sync attempt has an 8-second UI wait limit, while a periodic 7-second timer checks for pending work. The timeout does not cancel the in-flight future, and sync attempts are coalesced; a new retry starts after the current attempt settles. This prevents the Log button from hanging while preserving the durable command. Keep the UI timeout separate from the retry/acknowledgement lifecycle.
- Planned exercises explicitly distinguish `ExerciseTrackingMode.reps` from `ExerciseTrackingMode.timed`. Timed prescriptions use `targetDurationSeconds`; active-session writes send `durationSeconds` instead of a weight/reps pair. The API keeps `reps=1` as a database-required sentinel and stores duration in `workout_sets.duration_seconds`; exclude timed sets from strength PRs and previous-rep comparisons. Older API payloads that omit `trackingMode` remain reps-based. Keep the schema migration in the sibling API repo deployed before code paths query the new plan/session columns; Coolify does not apply migrations automatically.
- The current `/v1` API cannot remove an exercise after a session has started; `ApiSessionRepository.removeExercise` deliberately returns an explanatory failure. Do not fake a local-only removal that would reappear on refresh.
- Rest countdowns are absolute UTC deadlines stored per session in secure device storage. They are not ticking counters and are not server-authoritative. Clear that local deadline on completion/discard; derive remaining time from the deadline after rebuild/restart.

## Plans, Quick Add, and history

- Planned sessions start with a plan-day ID and then load canonical session detail. Keep day identity and plan identity attached to this flow; the API's aggregate record does not replace the individual session detail read.
- An active workout plan is an account preference, not an in-progress workout session. It can be selected from Settings or a plan's detail page; this selection must not implicitly start a session. Starting a day creates/resumes the distinct single active session owned by `ActiveSessionController`.
- Quick Add is an independent recording path through `QuickAddRepository` and `/v1/quick-add`. It must not start a planned session or change the selected active plan. Strength entries use weight/reps; duration-based activities send `durationSeconds`.
- The duration field requires API migration `007_quick_add_duration.sql` in the sibling `/Users/mzootfb/Sites/transmute-mobile` repository. Docker/Coolify deployment does not automatically apply API migrations. Inspect the live schema and apply/verify an explicit migration before relying on a new DB field; a healthy `/health` response alone does not prove the affected endpoint works.
- Session history is built from completed server sessions. Completion/deletion should invalidate the history and dependent “last performed” providers so dates and day subtitles refresh.

## Nutrition quantities and local dates

- A food's nutrition values describe its saved serving size. A logged quantity must scale calories and every macro (protein, carbohydrates, fat) by `logged quantity / serving size`; scaling calories alone creates internally inconsistent tracking. The `/v1/record` meal read model should return quantities/macros consistent with what was logged; Flutter totals sum those meal values rather than rescaling them a second time.
- Meal timestamps are instants: build the selected calendar day in the user's local timezone, send `consumedAt` as UTC, and filter/display returned timestamps after converting them back to local time. Do not use the server's calendar date or UTC date as the user's nutrition day. See the date helpers and `_Totals` in `lib/features/nutrition/presentation/nutrition_screen.dart`.
- The catalog search/log flow is intentionally separated from the visible food record. Avoid restoring a permanently expanded catalog to the main nutrition page; adding a food definition and logging a serving are distinct actions.

## Web build and test constraints

- Production Docker copies checked-in `release/web`; `flutter build web` only updates `build/web`. Run `./scripts/build_web_release.sh` for a production bundle: it builds API mode, syncs the release directory, and versions bootstrap/app URLs. Commit the generated bundle with its source changes or Coolify can redeploy the old UI.
- `deploy/nginx.conf` serves GoRouter fallbacks and sets cache policy. Mutable Flutter entry files must revalidate; do not mark the fixed `main.dart.js` or bootstrap filenames immutable. Versioning in the build script is also part of avoiding stale browser bundles.
- Use the pinned `.fvm/flutter_sdk/bin/flutter`. Flutter widget tests bind a local socket; if the sandbox rejects socket creation, that is an environment permission failure before test execution, not a failed assertion. SVG `metadata`, `defs`, and `sodipodi:namedview` warnings in test output are non-fatal.
- Local API web testing must use the origin allowed by API CORS (`http://localhost:8081` by default); `127.0.0.1:8081` is a different origin. A relative API base `/` is resolved against `Uri.base.origin` for same-origin proxy setups.
