# Transmute Flutter demonstration: domain and data model

> **Scope note (2026-10-03):** the entities below document the original
> workout-loop baseline and contain early demo shapes; they are not the ceiling
> for the expanded product. Verify the implemented API adapter contract and
> sibling Fastify schema before using a field or changing a payload. The
> target aggregates and exact proposed rules are in
> [COMPETITOR_UPGRADE_PLAN.md](COMPETITOR_UPGRADE_PLAN.md). New contracts below
> are planned, not currently implemented.

## Target aggregates to add

| Aggregate | Canonical evidence and planned persistence | Invariants |
| --- | --- | --- |
| `RoutineShareSnapshot` and `WorkoutSession` origin | Ordered routine/day prescriptions; immutable shared copy stored in `routine_share_snapshots` with owner, unguessable token, expiry/revocation and `routine_days.imported_from_share_id`; persisted session origin `plan_day`, `freeform`, or `quick_add`; freeform/Quick Add have null source routine/day. | A snapshot excludes sessions/history/goals and stores canonical kg targets. One active session spans planned and freeform origins; Quick Add is immediately completed. Imported copy has a new owner and cannot mutate the publisher's routine. |
| `ExerciseRankBaseline` / `ExerciseRankSnapshot` | Exact exercise and tracking mode, comparable completed working sets, baseline, best metric, tier, next threshold, rule version and evidence IDs. | Provisional until two qualifying sessions on distinct dates; corrections/deletions recompute; personal tier is not a population percentile. |
| `MuscleContribution` / `MuscleRankSnapshot` / `OverallRankSnapshot` | Curated exercise-to-front/back-muscle weights, top eligible exercise scores, overall coverage and history. | Missing mapping is explicit; front/back map and text detail use the same snapshot; placement needs documented coverage. |
| `ProgressionLedger` / `Level` / `RewardClaim` | Qualified workout, set, PR and tier-up source events with idempotent XP/reversal entries and claim transaction. | Level and reward state are server-owned and rule-versioned; Arcana is a separate complementary aggregate. |
| `QualifiedTrainingDay` / `StreakSnapshot` | Completed session evidence with the user's timezone frozen at completion. | At most one training-day mark per local date; current/best streak recompute on correction. |
| `TrainingAggregate` / `BodyweightMeasurement` / typed `Goal` | Indexed confirmed-session metrics, dated user-entered bodyweight and exercise-linked estimated 1RM goals. | No invented calories or weight from photos; unit conversion does not mutate kg; goal progress names its baseline and rule. |
| `DailyNutritionTarget` / `NutritionDay` | User-set calories/optional macros effective for local date; confirmed meals in saved food serving units. | Unset target is not zero; remaining defaults to food-only; image candidates never create meals without review. |
| `RecipeVersion` and `MealPhotoCandidate` | Ingredient/serving nutrition provenance, owned media and reviewed photo analysis candidates. | Publishing requires moderation; logged meals retain their confirmed version and values. |
| `FriendActivity` / `LeaderboardPeriod` / `LeagueCohort` | Accepted-friend events, opt-in settings and period-specific verified XP standings. | Authorization and opt-out/removal revoke visibility; no synthetic competitors or undisclosed population claims. |

These aggregates require migrations and API routes in the sibling Fastify
repository, Flutter domain repository interfaces, API/mock adapters and
Riverpod registration. Allocate migration numbers only after checking the
then-current backend state; the upgrade plan lists proposed endpoint shapes.

## Conventions

- IDs are UUID strings.
- Timestamps are UTC ISO-8601 strings, for example `2026-08-11T16:20:00Z`.
- `DateTime` fields are required unless marked nullable.
- All persisted weight uses `weightKg` as canonical kilograms. UI converts only
  for display/input according to `User.weightUnit` (`kg` or `lb`).
- Money-style decimal values use JSON numbers in the demo API and Dart `double`
  at the boundary. Display formatting must never drive stored values.

## Entities

### User

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | UUID | Yes | Stable identity. |
| `username` | string | Yes | Unique, normalized lowercase. |
| `displayName` | string | No | Nullable. |
| `weightUnit` | `"kg" \| "lb"` | Yes | Display preference only. |
| `createdAt` | timestamp | Yes | Server assigned. |

```json
{"id":"9d4f3ddd-9817-4cc5-946b-9c0046ad93c5","username":"demo","displayName":"Demo Lifter","weightUnit":"lb","createdAt":"2026-08-01T12:00:00Z"}
```

### Exercise

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | UUID | Yes | Stable catalog identity. |
| `name` | string | Yes | Immutable for session snapshot purposes. |
| `muscleGroup` | string | No | Display metadata. |
| `category` | `strength \| cardio \| mobility` | Yes | Catalog metadata. |

```json
{"id":"84c9a056-7f17-459b-86d1-bbc698867397","name":"Barbell bench press","muscleGroup":"Chest","category":"strength"}
```

### WorkoutPlan

The app uses explicit `WorkoutPlanDay` records with ordered `PlanExercise`
prescriptions. A selected `planDayId` is recorded on each workout session.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | UUID | Yes | Plan identity. |
| `userId` | UUID | Yes | Owner. |
| `name` | string | Yes | 2–80 characters. |
| `description` | string | No | 0–200 characters. |
| `exercises` | `PlanExercise[]` | Yes | Ordered, at least one for startability. |
| `createdAt` / `updatedAt` | timestamp | Yes | Server assigned. |

### PlanExercise

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | UUID | Yes | Prescribed-row identity. |
| `planId` | UUID | Yes | Parent plan. |
| `exerciseId` | UUID | Yes | Catalog reference. |
| `sortOrder` | integer | Yes | Zero-based unique within plan. |
| `targetSets` | integer | Yes | 1–20. |
| `targetReps` | integer | Yes | 1–50 when `trackingMode` is `reps`; retained as a legacy/default rep value in timed mode. |
| `trackingMode` | `reps \| timed` | Yes | Defaults to `reps`; controls the prescription and active-session input type. |
| `targetDurationSeconds` | integer | Timed only | 1–86,400 seconds per set. |
| `targetWeightKg` | number | No | Canonical target. |

```json
{"id":"752f8f8d-04d8-4ae2-a5c1-8efb03ef9f85","planId":"2fe5c405-5935-4f48-887d-75d89c40bbca","exerciseId":"84c9a056-7f17-459b-86d1-bbc698867397","sortOrder":0,"targetSets":3,"targetReps":8,"targetWeightKg":61.235}
```

For timed prescriptions, `trackingMode` is `timed` and `targetDurationSeconds`
contains the target duration per set. Rep prescriptions use `trackingMode: reps`;
older payloads without a mode are interpreted as reps.

### WorkoutSession

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | UUID | Yes | Session identity. |
| `userId` | UUID | Yes | Owner. |
| `planId` | UUID | Yes | Source plan, retained for traceability only. |
| `planNameSnapshot` | string | Yes | Historical display name. |
| `status` | `active \| completed \| discarded` | Yes | State machine value. |
| `startedAt` | timestamp | Yes | Server assigned at start. |
| `completedAt` | timestamp | No | Required only when completed. |
| `discardedAt` | timestamp | No | Required only when discarded. |
| `restEndsAt` | timestamp | No | Absolute deadline; null means inactive/paused timer. |
| `exercises` | `SessionExercise[]` | Yes | Ordered historical snapshots. |
| `updatedAt` | timestamp | Yes | Server assigned. |

### SessionExercise

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | UUID | Yes | Session-row identity. |
| `sessionId` | UUID | Yes | Parent session. |
| `exerciseId` | UUID | Yes | Catalog identity for matching history. |
| `exerciseNameSnapshot` | string | Yes | Historical name. |
| `muscleGroupSnapshot` | string | No | Historical metadata. |
| `sortOrder` | integer | Yes | Zero-based unique within session. |
| `targetSetsSnapshot` | integer | Yes | 1–20. |
| `targetRepsSnapshot` | integer | Yes | 1–100. |
| `targetWeightKgSnapshot` | number | No | Historical target. |
| `previousPerformance` | `PreviousPerformance` | No | Read model; not authoritative session data. |
| `sets` | `LoggedSet[]` | Yes | Ordered by `setOrder`. |

`PreviousPerformance` contains `sessionId`, `completedAt`, `weightKg`, and
`reps`; it is the latest working set from a prior completed session for the
same `exerciseId`.

### LoggedSet

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | UUID | Yes | Set identity. |
| `sessionExerciseId` | UUID | Yes | Parent session exercise. |
| `setOrder` | integer | Yes | One-based unique within session exercise. |
| `weightKg` | number | Yes | Canonical `0–1000`. |
| `reps` | integer | Yes | `1–100`. |
| `completedAt` | timestamp | Yes | Server assigned. |

```json
{"id":"2c0d97fe-1a23-4552-9f1f-823b37a76581","sessionExerciseId":"1a1947d2-b22f-4aed-b9db-6d7f2cacf2a7","setOrder":2,"weightKg":61.235,"reps":8,"completedAt":"2026-08-11T16:34:00Z"}
```

## Aggregate relationships

```mermaid
erDiagram
  USER ||--o{ WORKOUT_PLAN : owns
  WORKOUT_PLAN ||--|{ PLAN_EXERCISE : prescribes
  EXERCISE ||--o{ PLAN_EXERCISE : referenced_by
  USER ||--o{ WORKOUT_SESSION : owns
  WORKOUT_PLAN ||--o{ WORKOUT_SESSION : originated
  WORKOUT_SESSION ||--|{ SESSION_EXERCISE : snapshots
  EXERCISE ||--o{ SESSION_EXERCISE : identifies
  SESSION_EXERCISE ||--o{ LOGGED_SET : contains
```

## Domain invariants

1. A user has **at most one** `active` workout session. Enforce it in the
   persistence transaction/unique constraint, not only in Flutter state.
2. Only an active session accepts set edits, session-exercise additions/removal,
   rest-deadline changes, completion, or discard.
3. A completed session and its snapshots are immutable. A discarded session is
   excluded from history and cannot be resumed.
4. Starting a session atomically snapshots plan name, exercise name/metadata,
   order, and target fields. Later plan or catalog changes cannot rewrite
   historical evidence.
5. A `SessionExercise` can appear at most once in one session for a given
   `exerciseId`. It may be removed only when it has no logged sets.
6. `LoggedSet.setOrder` is contiguous and one-based per `SessionExercise`.
   Server assigns/recalculates it; clients never choose it.
7. `completedAt` is non-null iff session status is `completed`; `discardedAt`
   is non-null iff status is `discarded`; the two are mutually exclusive.
8. `restEndsAt` is an absolute future/past timestamp, never a remaining
   counter. Remaining seconds are `max(0, restEndsAt - clock.now())`.
9. The latest previous performance ignores the current session, discarded
   sessions, and any non-completed historical session.
10. API actor identity determines all owner-scoped reads/writes. User IDs in
    request payloads are forbidden.
