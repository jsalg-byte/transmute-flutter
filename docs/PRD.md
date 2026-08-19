# Transmute Flutter demo PRD

## Product statement

Transmute is a private training record. This Flutter demo proves the smallest
credible loop: choose a plan, perform a workout, preserve the evidence, and
use the previous performance when performing the next workout.

## Target user

An intermediate strength/hypertrophy trainee who repeats a plan and needs a
reliable record of what they actually performed, not a broad social or
nutrition product.

## Product outcome

The user can sign in, identify a plan, create or resume exactly one active
workout, log durable sets, manage rest, finish/discard deliberately, then view
the completed result and use its performance as context next time.

## In scope

1. Demo authentication and protected routing.
2. Workout-plan list/detail with prescription and previous performance.
3. Single active-session lifecycle, session-exercise changes, set logging, and
   durable rest timer.
4. Completed-session history/detail with total volume and duration.
5. Responsive mobile/tablet/desktop shell.
6. Mock and REST-backed repositories, error/retry/empty states.

## Out of scope

Nutrition, recovery coaching, AI, Arcana, fasting, progress media, friends,
administration, plan authoring, registration, barcode/label capture, and
offline write synchronization.

## Success criteria

- The loop works entirely in mock mode without a backend.
- API mode is selected only by environment configuration and follows the
  documented contract with no client-side field/endpoint guessing.
- A session and rest deadline survive an application restart.
- Completed evidence is immutable and affects previous-performance read models.
- The same product outcome is usable at 375dp, 768dp, and 1440dp widths.

The exact implementation requirements, data rules, API, and visual rules are
respectively in `FLUTTER_BUILD_SPEC.md`, `DOMAIN_MODEL.md`, `API_CONTRACT.md`,
and `UI_SPEC.md`.
