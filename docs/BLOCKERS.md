# Current blockers

## Production migration safeguard (2026-10-04)

The production API was healthy but `/v1/record` returned 500 because the
deployed service expected `workout_sessions.origin` before migration 011 had
run. The non-destructive column/backfill/constraint portion of migration 011
is now applied, along with migrations 012–014; an authenticated production
dashboard load now returns active-workout and recovery content rather than
perpetual loaders. The migration's final partial unique index was deliberately
not applied: two users each have two existing `active` sessions. A dedicated
data-reconciliation decision is required before enforcing that index; no
sessions were deleted or altered to make the migration pass. The router now
also retains a protected deep link through the existing auth loading splash,
so a signed-in restoration does not briefly route through public onboarding or
lose its destination.

## Routine slice 3 source versus deployment

The routine folder/reorder endpoints are implemented in the sibling Fastify source and Flutter adapters. Local mock browser flow was verified at 390×844, but the deployed API, production schema, and checked-in Flutter `release/web` have not been updated or verified in this slice. Local mock persistence lasts for the running app only; a full browser reload resets its fixture store. API-backed reload persistence uses the server's canonical `/v1/record` read path and is covered by adapter contract tests, but not yet by a live account check. A routine used by workout history cannot currently be deleted because the history model joins its name and prescriptions to that row; preserving history through deletion needs a later snapshot/archive migration.

## Per-exercise ranks slice 6 source versus deployment

The gallery, detail, calculator, mock rule and Fastify scoring service are in
local source. API mode requires migration 013 and the paired service release;
neither is applied to production. Before applying it, inspect the current live
schema and migration history. The rank baseline currently uses a UTC completion
date because the account contract has no persisted timezone; this is explicitly
not the final frozen-local-date contract required for streaks in slice 11.
The agent browser-checked the local mock app at 390×844, but did not verify a
live rank write/correction, authenticated API reload, production schema or the
checked-in release bundle.

## Ranked bodygraph slice 7 release state

The local Flutter/Fastify source now has the front/back rank bodygraph,
placement progress, curated canonical exercise-to-region contribution map and
versioned muscle/overall projections. Production schema inspection confirmed
that migrations 011–014 are present (with the unique-index exception above).
The Slice 7 source and checked-in web bundle still require the paired commit,
push, and deployment verification. The successful dashboard read does not by
itself establish rank recalculation/correction history or routine-share flows.

## Native signing and physical-device verification remain

**Evidence (2026-08-18):** this checkout now contains standard `android/` and
`ios/` host projects. A release Android APK built at
`build/app/outputs/flutter-apk/app-release.apk`, and an unsigned iOS release
app built at `build/ios/iphoneos/Runner.app`. iOS privacy declarations now
cover camera barcode/label capture and choosing progress/meal photos; the
Android release manifest includes the camera permission supplied by
`mobile_scanner`.

**Impact:** native code compiles, but it cannot ship to devices or app stores
until the app is signed with the correct Apple/Google identities and exercised
on physical devices. Browser responsive verification remains separate.

**Smallest decisions:** select the launch channel (web/PWA, Android, iOS, or
all three), then provide or authorize the associated signing and store-release
workflow. Do not treat an unsigned build as a distributable iOS app.

## Browser and release verification

The usual project default is user-owned browser review. For the competitor
upgrade slices, the user explicitly authorized agent browser verification.
Slices 1–2 were checked in a local mock web build at a 390×844 phone viewport;
slice 2 included set logging, editing, deletion, completion and history.
Authenticated API reload, production schema/migration state, tablet/desktop
browser review and the checked-in `release/web` bundle remain separate release
checks. A mock browser pass does not establish live API persistence.
