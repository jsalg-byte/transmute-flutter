# Transmute Flutter: product-launch roadmap

## Purpose

This roadmap turns the existing Flutter feature work into a complete,
release-ready Transmute product. It deliberately puts integration before new
feature expansion: several feature screens and `/v1` adapters already exist,
but the router and navigation currently expose only the core workout loop.

## Launch definition

Transmute is ready to launch when a real user can:

1. create an account or sign in;
2. discover every supported record area from product navigation;
3. complete each supported create/read/update/delete flow against the live
   API without misleading local success states;
4. use the product on a phone, tablet, and desktop browser; and
5. recover safely from session expiry, bad input, uploads, and temporary
   network failures.

The local `Demo Login` remains a separate, non-production-data preview path.
It is useful for sales, QA, and onboarding, but it does not replace real API
validation.

---

## Milestone 0 — establish the release baseline

**Outcome:** the team agrees on what will ship and can reproduce the build.

**Engineering status (2026-08-18):** `flutter analyze`, the full test suite,
and the release web build pass. The Android release APK and unsigned iOS
release app also compile. This milestone stays open because this directory is
not currently a Git repository with a release-candidate SHA, no stable hosting
target has been selected, and real-account QA is still required.

- [ ] Freeze a release-candidate commit SHA and record the API environment,
  public web URL, and supported platforms.
- [ ] Update stale documentation: the checkout currently has `android/` and
  `ios/` directories, so the older “no mobile host projects” blocker must be
  re-verified rather than carried forward.
- [ ] Create a non-production real API test account and seed enough data to
  exercise plans, sessions, nutrition, media, preferences, friends, and
  history.
- [ ] Confirm the production API CORS allowlist contains the final web domain;
  do not rely on a temporary tunnel for launch.
- [x] Run and record `flutter analyze`, `flutter test`, and `flutter build
  web` from the release candidate.

**Exit gate:** a named candidate build, environment configuration, test user,
and repeatable build evidence exist.

## Milestone 1 — connect the existing product surfaces

**Outcome:** no implemented feature is stranded behind an unregistered route.

**Engineering status (2026-08-18):** complete in source. All listed routes
are registered, the Arcana redirect is removed, the workout-record/share and
shared-friend detail routes are registered, and the responsive secondary menu
now exposes the full feature inventory. `flutter analyze`, the full test
suite, and the release web build pass. User-owned browser/device verification
remains the final acceptance evidence for this milestone.

### Add the missing routes

- [x] `/exercises` — Exercise library.
- [x] `/nutrition` — Food catalog, meal record, barcode, label intake, and
  meal media.
- [x] `/progress` — Photo timeline/calendar and edit/delete detail.
- [x] `/fasting` — Active fast and history.
- [x] `/goals` and `/planning` — Goals, assessments, training blocks, and
  weekly review.
- [x] `/arcana` — Collection, evidence, pins, and reconciliation; remove the
  current dashboard redirect.
- [x] `/friends` and `/friends/sessions/:id` — Requests, activity, and
  privacy-gated shared workout evidence.
- [x] `/settings` — Units, active plan, palette, theme mode, and account
  actions.

### Make the routes discoverable

- [x] Keep the compact primary navigation focused on Today, Plans, Workout,
  and History.
- [x] Expand the secondary destination menu into clear groups: **Record**
  (Nutrition, Progress, Fasting), **Growth** (Goals, Planning, Arcana), and
  **Account** (Friends, Settings).
- [x] Ensure every dashboard recommendation and recent-record destination has
  a registered route and a useful back path.
- [x] Apply protected-route behavior consistently: signed-out visitors go to
  login; expired sessions clear private state and explain the next action.

**Exit gate:** every screen listed above is reachable from navigation, direct
links resolve, and dashboard actions never land on a not-found screen.

## Milestone 2 — prove real API behavior end to end

**Outcome:** the production adapter is verified against server responses, not
just mocks and fixture tests.

- [ ] Authentication: registration, normal login, restore, refresh, logout,
  invalid credentials, duplicate username, and expired refresh token.
- [ ] Training: plan/day/prescription CRUD, catalog import, assistant
  draft/review/import, one-active-session conflict, session edits, working and
  warm-up sets, rest deadline, completion, discard, and personal-record
  feedback.
- [ ] Record: nutrition serving calculations, meal CRUD, meal photo upload,
  barcode lookup, label parse review, progress presign/upload/edit/delete,
  fasting lifecycle, recovery check-in, goals, planning, and weekly review.
- [ ] Social and progression: friend lifecycle, revoked shared-session access,
  Arcana read/pin/reconcile, and preferences persistence.
- [ ] Verify negative paths for 401, 404, 409, validation, upload expiry,
  network loss, and API 5xx errors. Confirm that failed mutations never
  appear as saved.

**Exit gate:** a recorded QA matrix shows each shipping mutation succeeding
and each important failure producing an honest recovery state.

## Milestone 3 — close launch-critical feature gaps

**Outcome:** the product is coherent at normal personal-record scale.

### Required before public launch

- [ ] Account profile edit if the API contract is approved; otherwise remove
  any implication that identity details are editable.
- [ ] Pagination or bounded loading strategy for large workout and meal
  history.
- [ ] Reliable upload UX: progress and meal-photo retries, expired signed URL
  handling, compression/size messaging, and clear permission fallbacks.
- [ ] Accessibility pass: labels, focus order, color-independent recovery
  states, touch targets, dialog scroll behavior, and text scaling.
- [ ] Empty-state, error-state, and deletion-confirmation review across every
  route.

### Schedule after launch unless product strategy changes

- [ ] Per-plan rest prescriptions (requires API support).
- [ ] Nutrition-adherence trend (requires an audited target contract).
- [ ] Visual progress comparison, fasting presets/day linking, friend feed
  filtering, full Arcana artwork/journal shortcuts, and goal/block/day links.
- [ ] Server-owned Daily Transmutation recommendation. The current
  deterministic evidence-based rule is safe to ship.
- [ ] Offline mutation queueing. Do not add it before idempotency and conflict
  rules are designed and server-supported.
- [ ] Upgrade or replace `mobile_scanner` before the next Flutter toolchain
  upgrade; the current Android release build succeeds but warns that the
  plugin still applies the legacy Kotlin Gradle Plugin.

**Exit gate:** there is no known P0/P1 flow break, data-loss path, or
inaccessible required action.

## Milestone 4 — release engineering and observability

**Outcome:** a production incident can be detected, understood, and rolled
back safely.

**Engineering status (2026-08-18):** a production `Dockerfile`, Nginx
deep-link fallback, `/healthz` endpoint, and Coolify deployment instructions
are present. The local Docker daemon is unavailable, so the container smoke
test must run in the selected deployment environment before promotion.

- [ ] Build a stable HTTPS web deployment with separate staging and production
  configuration; remove the temporary tunnel from any release instructions.
- [ ] Configure API CORS only for real approved origins.
- [ ] Add privacy-conscious crash/error reporting and API failure telemetry;
  exclude credentials, tokens, raw health notes, and image data.
- [ ] Define health checks, dashboards, alert thresholds, a rollback procedure,
  and a small support runbook for login/upload failures.
- [ ] Review account security: token storage, logout/revocation, rate limits,
  brute-force protection, upload authorization, and least-privilege signed
  URLs.
- [ ] Add a release checklist with versioning, changelog, migration notes, and
  rollback owner.

**Exit gate:** staging is production-like, production is observable, and a
rollback rehearsal succeeds.

## Milestone 5 — device and store readiness

**Outcome:** the supported delivery targets are intentionally validated.

**Engineering status (2026-08-18):** Android release compilation succeeded
with `build/app/outputs/flutter-apk/app-release.apk`; unsigned iOS release
compilation succeeded with `build/ios/iphoneos/Runner.app`. iOS camera and
photo-library usage descriptions are present, and the merged Android release
manifest includes camera permission. Signing, physical-device testing, and
store configuration remain open.

- [ ] Browser acceptance at phone, tablet, and desktop breakpoints with real
  accounts and real media permissions.
- [ ] Verify Android and iOS host projects, dependency builds, app identifiers,
  icons, privacy manifests, camera/photo permissions, and secure storage.
- [ ] Run on at least one physical Android device and iPhone: login, session
  logging, camera scan, image upload, external demo media, logout, and resume.
- [ ] Decide the launch target: responsive web only, installable PWA, app
  stores, or a staged combination. Do not begin store submission until this
  decision, signing, and privacy copy are final.

**Exit gate:** every promised platform has a successful signed or deployable
release artifact and device QA evidence.

## Milestone 6 — staged launch

**Outcome:** ship with controlled feedback and a clear promotion decision.

- [ ] Internal dogfood: team accounts, seeded workflows, and daily issue
  triage.
- [ ] Closed beta: small invited cohort; monitor activation, successful
  workouts, retained records, upload failures, and auth failures.
- [ ] Fix only verified P0/P1 issues in the release-candidate branch; keep the
  candidate SHA frozen otherwise.
- [ ] Publish release notes, support contact, privacy terms, and known
  limitations.
- [ ] Promote to public launch after the beta gate is met; monitor closely for
  the first 48 hours and retain rollback readiness.

**Exit gate:** product owner approves promotion with no unresolved launch
blocker and a verified rollback path.

---

## Recommended delivery order

1. Milestone 0 — release baseline.
2. Milestone 1 — route and navigation integration.
3. Milestone 2 — real API QA while fixing routing defects.
4. Milestone 3 — launch-critical hardening only.
5. Milestone 4 and 5 in parallel where responsibilities permit.
6. Milestone 6 — dogfood, beta, then public release.

This sequence prevents adding more feature surface before users can discover
and reliably use the functionality already implemented.
