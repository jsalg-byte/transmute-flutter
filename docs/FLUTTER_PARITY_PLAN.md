# Flutter parity plan

The first focused demo established authentication, a persistent active
workout, set logging, a local rest timer, completed history, and mock/API
repository seams. This plan expands it in coherent product increments without
claiming compatibility with the Expo API until the adapter is built.

## MVP 1 — Core workout loop

**Outcome:** a lifter can create and edit a multi-day plan, choose the active
plan/day, start or resume exactly one session, log warm-up and working sets,
use a local rest timer, finish it, and inspect immutable evidence/history.

- Replace the demo's flat-plan model with plan days and ordered prescriptions.
- Add plan CRUD and plan-day CRUD in mock mode first.
- Add exercise library search, creation, metadata, and plan/session insertion.
- Search the server-backed Calistree catalog from both plan and active-session
  pickers, importing canonical metadata only after a deliberate user choice.
- Offer the source plan assistant as a prompt → constrained draft → explicit
  import workflow; never create an AI plan merely from generation.
- Preserve previous-performance and progression cues in the active session.
- Keep local rest timer separate from API payloads.
- Expand completed history with per-set evidence, muscle summaries, and totals.
- Build an explicit `Expo*Repository` adapter only after the model is stable.

**Exit criteria:** no active session can be overwritten; a session always
records its selected day; all state mutations have visible pending/failure
handling; mock mode demonstrates the entire loop. Current implementation meets
these criteria, including manual/catalog/assistant plan creation and review.

## MVP 2 — Daily readiness and progress record

**Outcome:** the home screen explains what to do today and why.

- Dashboard: next day, resume state, weekly totals, recent record.
- Calculated muscle readiness using the verified 24h / 48h non-warm-up rule.
- Progress calendar/timeline, photo upload, notes, and session linking.
- Fasting lifecycle and history.

Current progress: the dashboard route, responsive Today navigation, weekly
session count, verified muscle-readiness calculation, accessible heatmap,
recovery check-ins, fasting lifecycle/history, goals, training blocks,
scheduled block work, weekly reviews, and the progress calendar/timeline with
real signed photo upload, date editing, deletion, and session correlation are
implemented with mock and `/v1` repositories where the API contract exists.
Active-plan preference is now persisted and directly orders the Dashboard and
Daily Transmutation prescription. Recovery/adherence trends remain a focused
hardening item, not a blocker to the completed workflow.

## MVP 3 — Nutrition record (next)

**Outcome:** food and training evidence can live in the same daily record.

- Food catalog/search, food creation, serving units, meal CRUD and day totals.
- Meal history/date filters and meal photos.
- Barcode and nutrition-label capture with review-before-save.

Current progress: food catalog search/creation, saved serving units, serving-aware
macro calculation, multi-item meal logging, daily totals, date navigation, meal
editing/deletion, signed meal photos, camera/manual barcode lookup, and OCR/AI
nutrition-label prefill with mandatory review are implemented in mock and `/v1`
modes. The next coherent product outcome is Daily Transmutation.

## MVP 4 — Daily Transmutation (complete)

**Outcome:** recovery, goals, planning, and review create a coherent training
cycle rather than isolated logs.

- Recovery check-ins and adherence target.
- Goals/assessments, weekly reviews, training blocks, scheduled block work.
- Daily Transmutation is a deterministic, explainable Flutter rule because no
  server recommendation contract exists. It prioritizes active work, missing
  recovery evidence, contraindicated recovery, overdue goals, missing meal
  evidence, and then the next plan.

## MVP 5 — Community, Arcana, and preferences

**Outcome:** personal evidence can be reflected socially and thematically.

- Arcana cards, evidence, pins, and reconciliation are implemented with the
  server-owned stage/evidence contract; mock mode mirrors all 15 source cards.
- Friends requests, accepted-state removal, responsive activity, and
  privacy-gated read-only shared workouts are implemented.
- Persisted weight unit, active plan, seven named theme palettes, and
  light/dark mode are implemented and visibly applied.
- Account registration and the source’s four-step first-record orientation are
  implemented alongside session restore and logout.

## Intentionally later

- Admin account management and IP access record require a separate security
  decision; they are not part of the consumer Flutter product.
- Offline queueing, sync conflict resolution, analytics/telemetry, and push
  notifications are cross-cutting hardening work, not a substitute for a
  complete workout loop.

## Current hardening sequence

1. History now provides bounded 7-day, 30-day, and all-time analytics from
   completed-session evidence only; recovery now provides a seven-entry
   check-in/sleep trend. Nutrition-adherence targets require a separate
   contract audit before surfacing a metric.
2. Exercise detail retains source metadata and opens a supplied demonstration
   only on a user tap. Both plan and active-session pickers now expose the
   source catalog, and the plan assistant exposes a reviewable draft before
   import. Active sessions embed direct source-video playback with controls and
   open hosted source pages explicitly.
3. The adapter now distinguishes retryable network/5xx failures from resolved
   validation/auth/missing/conflict failures. Mutations are deliberately not
   queued or replayed offline until an idempotency and conflict policy exists.
4. Run user-owned visual browser verification on mobile, tablet, and desktop
   after each responsive-shell change.

The remaining work is user-owned visual/responsive verification, scalable
history, and the deliberately deferred offline/telemetry decisions; mock mode
remains a deliberate, runnable demonstration. Web and macOS builds are
verified. Android/iOS build evidence needs explicit approval to generate their
currently absent Flutter host projects; see `docs/BLOCKERS.md`.
