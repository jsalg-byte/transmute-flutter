# Current blockers

## Empty workout slice 4 source versus deployment

The freeform Flutter entry, repository path, API route and migration 011 are
implemented in local source. API-mode use requires migration 011 and the
updated Fastify service; neither has been applied to production. Before the
unique index is applied, inspect the target database for more than one active
session per user. The migration intentionally stops if duplicates exist so
existing user records are not removed silently. The checked-in `release/web`
bundle has not been rebuilt or deployed. Focused mock/adapter tests validate
restore and history contracts, but a mock page reload recreates its fixture
store; authenticated API reload, production migration and production web
behavior remain unverified. The local mock browser at 390×844 did verify
Start Empty Workout, two exercise additions, one confirmed set each, Finish
and the resulting two-exercise history detail. It did not exercise a full
page reload, live API write, production migration, or discard in browser;
discard and repository restoration have focused mock tests.

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
