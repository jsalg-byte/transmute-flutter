# Transmute Flutter demonstration: API contract

> Status: the endpoints below are the **retired focused-demo HTTP contract**.
> They are retained as a historical test seam only. Flutter production mode
> uses the separate explicit `/v1` Expo/Fastify adapter documented immediately
> below; it is verified with fixture-based contract tests and can be enabled
> with `TRANSMUTE_REPOSITORY_MODE=api` plus a public API base URL. Mock mode is
> kept as a deliberate local demonstration path.

## Expo adapter contract (implemented core loop)

Flutter production mode now uses the explicit `/v1` adapter below for the core
workout loop. It hydrates plans and history from `GET /v1/record`, then uses
the detail/mutation endpoints for actions. It deliberately does **not** use
the retired endpoints described in the remainder of this document.

| Capability | Verified Expo operations | Adapter behavior |
| --- | --- | --- |
| Authentication | `POST /v1/auth/register`, `/login`, `/refresh`, `/logout`; `GET /v1/me` | Registration accepts normalized 3–64-character no-space username, optional 2–80-character display name, and 8–128-character password; it returns and persists the same session shape as login. |
| Plans and exercises | `GET /v1/record`; `POST/PATCH/DELETE /v1/plans`; day and plan-day-exercise mutations; `POST /v1/exercises`; `PUT /v1/exercises/:id/demo`; `GET /v1/calistree/exercises?q`; `POST /v1/plan-days/:id/calistree-exercises`; `POST /v1/ai/workout-drafts`; `POST /v1/ai/workout-plans` | Maps plan days, prescriptions, and any API-provided `demoUrl`/`demoSourceName` from the record response. Flutter presents unavailable demonstrations honestly, lets the user attach/replace a validated public URL with optional source attribution, and opens it only after an explicit user tap. Catalog search exposes only a name/slug; the server resolves canonical metadata and optional source media when importing. The assistant returns a reviewable constrained draft; Flutter never imports until the user explicitly chooses Add this plan. |
| Session lifecycle | `POST /v1/sessions {routineDayId}`; `GET /v1/sessions/:id`; `POST /complete`; `DELETE`; `POST /v1/sessions/:id/calistree-exercises` | A session always begins from a selected plan day. Its exercise picker can import a catalog entry during an active session; the server owns its canonical exercise metadata and optional demo attribution. |
| Set logging | `GET /v1/capabilities`; `POST /v1/sessions/:id/sets`; `PATCH/DELETE /v1/sets/:id` | Caches the verified set-to-exercise association required by the update payload. When `offlineSetSync` is advertised, Flutter sends a UUID `clientOperationId` for each queued set; the API guarantees that retrying that ID within the same session writes at most one set. A successful working-set response may include the server-calculated `personalRecord` (estimated 1RM for weighted sets, reps for unweighted sets); Flutter reports it only after that confirmed result. |
| Rest timer | No corresponding Expo mutation | Kept as intentional device-local session state. |
| Recovery check-ins | `GET /v1/recovery-checkins`; `PUT /v1/recovery-checkins/{YYYY-MM-DD}` | Scores are required integers 1–5; sleep is optional 0–24 hours and notes are capped at 500 characters. |
| Fasting | `GET /v1/record` fasting aggregate; `POST /v1/fasting` start/end; `DELETE /v1/fasting/:id` | Start accepts optional 1–10,080 minute target and note; ending before five minutes returns `discarded` rather than a history entry. |
| Progress record | `GET /v1/record` progress/sessions; Expo-compatible `POST /v1/progress/presign`, signed storage `PUT`, and `POST /v1/progress`; Flutter `POST /v1/progress/upload` and authenticated `GET /v1/progress/:id/image`; `PATCH/DELETE /v1/progress` | Only images up to 20MB may be uploaded. Flutter sends raw image bytes to its authenticated API route and reads image bytes from the authenticated API route so browser behavior never depends on the storage origin's CORS policy. `capturedAt` is a date/ISO timestamp. |
| Food catalog and meals | `GET /v1/record` nutrition; `POST /v1/foods`; `POST/PATCH/DELETE /v1/meals` | Foods define the reference serving value/unit and macros per reference serving. The numeric meal API field is named `grams`, but the existing product treats it as an amount in that saved serving unit; Flutter preserves that behavior deliberately. |
| Food media and capture | `POST /v1/meals/:id/photo/presign`, signed `PUT`, `POST /v1/meals/:id/photo`; `GET /v1/barcodes/:code`; `POST /v1/nutrition-label/parse` | Meal photos are images up to 20MB. Barcode candidates and label parses are review input only; the app must not create/log food until the user confirms the editable form. |
| Arcana | `GET /v1/arcana`; `PUT /v1/arcana/pins`; `POST /v1/arcana/reconcile` | Stages and evidence remain server-owned. Reconciliation may advance a card but must never retract durable earned state; only revealed cards may be pinned. |
| Friends | `GET /v1/record` friends aggregate; `POST /v1/friends`; `POST /v1/friends/:requestId/accept`; `POST /v1/friends/:requestId/reject`; `DELETE /v1/friends/:userId`; `GET /v1/sessions/:id/share` | Requests are addressed by username, accept/reject operations use the request ID, and removal uses the other user's ID. If a target already has an incoming pending request, `POST /v1/friends` accepts it. Friendship gates the immutable shared-workout set record; the API returns 404 when access is absent or revoked. |
| Preferences | `GET /v1/record` settings; `PUT /v1/preferences/weight-unit`; `PUT /v1/preferences/active-plan`; `GET/PUT /v1/preferences/theme` | Weight unit is exactly `kg` or `lbs`; active-plan mutation accepts a nullable `routineId`; theme stores one of the seven named palettes plus `light`/`dark` mode under the server-owned mobile theme preference. |
| Goals | `GET/POST /v1/goals`; `PATCH /v1/goals/:id`; `POST /v1/goals/:id/assessments` | Goal creation has a category, title, optional baseline/target/unit/date; assessments retain value and decision evidence. |
| Training blocks | `GET/POST/PATCH /v1/training-blocks`; create/update scheduled block sessions | Blocks have inclusive start/end dates, a 1–7 session weekly target, optional linked plan, status, and scheduled-session evidence. |
| Weekly reviews | `GET/POST /v1/weekly-reviews` | A review records a date range, reflection, optional adjustment, and a decision. |

The current Fastify API has no remove-session-exercise endpoint. Flutter
therefore shows the documented server limitation rather than implying that a
remove action succeeded.

## Failure and offline policy

Flutter queues only validated workout-set commands—and only after the API
advertises `offlineSetSync: true` from `GET /v1/capabilities`. Each command
uses one durable UUID `clientOperationId`; the API's session-scoped unique
constraint makes retries safe after a lost response. Pending sets are shown as
device-saved rather than server-logged, retry on reconnect/explicit sync, and
block workout completion until acknowledged. If the capability is absent,
Flutter keeps the previous online-only behavior. Sessions, meal uploads,
friend changes, and progress uploads remain unqueued because they do not yet
have an equivalent idempotency contract. Network/timeouts and 5xx responses
are retryable; validation, 401, 404, and 409 responses are retained for user
attention but are not retried automatically.

## General rules

- Base URL is selected by `--dart-define=TRANSMUTE_API_BASE_URL=...`.
  The current Expo app uses `https://api.transmute.mzootfb.xyz`; the endpoint
  is public configuration, not a credential.
- For browser development, the current production API permits
  `http://localhost:8081` but rejects the distinct origin
  `http://127.0.0.1:8081`. A new Flutter web origin must be added to the
  server-side `CORS_ORIGINS` allowlist; browser CORS cannot be bypassed in the
  client.
- Request/response bodies are JSON except the Flutter-only progress upload,
  which posts raw image bytes with an `image/*` content type. All timestamps
  are UTC ISO-8601.
- Authenticated requests use `Authorization: Bearer <accessToken>`.
- Successful mutation responses return the canonical server entity, not a
  client echo.
- Errors have this exact envelope:

```json
{"error":{"code":"validation_error","message":"Reps must be between 1 and 100.","field":"reps","retryable":false}}
```

`field` is omitted when not applicable. `401` means refresh/login; `409` is a
domain conflict and must be rendered without retrying blindly; `5xx` and
network failures are retryable.

## Authentication

| Method/path | Request | Success | Errors |
| --- | --- | --- | --- |
| `POST /auth/login` | `{username,password}` | `200 {accessToken,refreshToken,expiresAt,user}` | `401 invalid_credentials`, `422 validation_error` |
| `POST /auth/refresh` | `{refreshToken}` | same shape as login | `401 refresh_expired` |
| `POST /auth/logout` | `{refreshToken}` | `204` | `204` if already absent/revoked |
| `GET /auth/me` | none | `200 {user}` | `401 unauthorized` |

## Plans and catalog

| Method/path | Success body | Required behavior |
| --- | --- | --- |
| `GET /workout-plans` | `200 {plans: WorkoutPlanSummary[]}` | Only caller-owned plans; sorted `updatedAt DESC`. |
| `GET /workout-plans/{id}` | `200 {plan: WorkoutPlanDetail}` | Includes ordered exercises and each exact-exercise latest previous performance. |
| `GET /exercises?q={query}` | `200 {exercises: Exercise[]}` | Case-insensitive search; return at most 50. |

`GET /workout-plans/{id}` returns `404 plan_not_found` for missing/not-owned
plans. An empty plan list is a successful `200` with `plans: []`.

## Sessions

| Method/path | Request | Success | Errors |
| --- | --- | --- | --- |
| `GET /workout-sessions/active` | none | `200 {session: WorkoutSessionDetail \| null}` | `401` |
| `POST /workout-sessions` | `{planId}` | `201 {session}` | `404 plan_not_found`, `409 active_session_exists` with `{activeSessionId}` |
| `GET /workout-sessions/{id}` | none | `200 {session}` | `404 session_not_found` |
| `PATCH /workout-sessions/{id}` | `{restEndsAt?: timestamp\|null}` | `200 {session}` | `409 session_not_active` |
| `POST /workout-sessions/{id}/exercises` | `{exerciseId}` | `201 {sessionExercise}` | `409 duplicate_exercise` or `session_not_active` |
| `DELETE /workout-sessions/{id}/exercises/{sessionExerciseId}` | none | `204` | `409 exercise_has_sets` or `session_not_active` |
| `POST /session-exercises/{id}/sets` | `{weightKg,reps}` | `201 {loggedSet}` | `409 session_not_active` |
| `PATCH /logged-sets/{id}` | `{weightKg,reps}` | `200 {loggedSet}` | `404 set_not_found`, `409 session_not_active` |
| `DELETE /logged-sets/{id}` | none | `204` | `404 set_not_found`, `409 session_not_active` |
| `POST /workout-sessions/{id}/complete` | `{}` | `200 {session}` | `409 session_not_active` |
| `DELETE /workout-sessions/{id}` | none | `204` | `409 session_not_active` |
| `GET /workout-sessions?status=completed` | none | `200 {sessions: CompletedSessionSummary[]}` | Only completed caller-owned sessions, newest first. |

`DELETE /workout-sessions/{id}` is the confirmed discard command. It marks the
session discarded rather than exposing any destructive implementation detail.

## DTO shapes

`WorkoutSessionDetail` is exactly:

```json
{
  "id":"e83d99a2-1a79-43ee-a9b7-8d7a2d3f7e2c",
  "planId":"2fe5c405-5935-4f48-887d-75d89c40bbca",
  "planNameSnapshot":"Upper A",
  "status":"active",
  "startedAt":"2026-08-11T16:00:00Z",
  "completedAt":null,
  "discardedAt":null,
  "restEndsAt":"2026-08-11T16:32:00Z",
  "updatedAt":"2026-08-11T16:30:00Z",
  "exercises":[{
    "id":"1a1947d2-b22f-4aed-b9db-6d7f2cacf2a7",
    "exerciseId":"84c9a056-7f17-459b-86d1-bbc698867397",
    "exerciseNameSnapshot":"Barbell bench press",
    "muscleGroupSnapshot":"Chest",
    "sortOrder":0,
    "targetSetsSnapshot":3,
    "targetRepsSnapshot":8,
    "targetWeightKgSnapshot":61.235,
    "previousPerformance":{"sessionId":"d1efc383-0dc4-4f50-8d11-7d69a0d86086","completedAt":"2026-08-07T15:00:00Z","weightKg":58.967,"reps":8},
    "sets":[{"id":"2c0d97fe-1a23-4552-9f1f-823b37a76581","sessionExerciseId":"1a1947d2-b22f-4aed-b9db-6d7f2cacf2a7","setOrder":1,"weightKg":61.235,"reps":8,"completedAt":"2026-08-11T16:24:00Z"}]
  }]
}
```

`CompletedSessionSummary` contains `id`, `planNameSnapshot`, `startedAt`,
`completedAt`, `durationSeconds`, `workingSetCount`, and `totalVolumeKg`.

## Mock fixtures

Mock mode supplies:

- User `demo` / password `transmute-demo` with display unit `lb`.
- Two plans: `Upper A` (bench press, chest-supported row, shoulder press) and
  `Lower A` (back squat, Romanian deadlift, calf raise).
- One completed `Upper A` session with at least bench/row historical sets so
  prior-performance UI is populated.
- No active session on first launch. Starting `Upper A`, logging sets, setting
  a rest deadline, completing, and reopening history must mutate in-memory
  mock state for the running process.
- A configurable mock failure mode: the first create-set request returns a
  retryable `503`, then the retry succeeds. This is test-only and off by
  default.

## Configuration and real-API adapter

`TRANSMUTE_REPOSITORY_MODE=mock|api` chooses repository implementation. Mock
is the default, with one explicit `Demo Login` action and resettable fixtures.
API mode requires a non-empty HTTPS base URL and uses the explicit `/v1`
adapter above. No production secrets are compiled into the app.

The existing Expo/Fastify API has different route and DTO names. It is not
implicitly compatible with this focused demo contract. Connect it only through
an explicit server adapter or a separately documented translation layer; do
not scatter endpoint/field fallbacks through Flutter widgets or repositories.
