# Transmute target UI specification

**Target, 2026-10-03.** This replaces the early three-tab demo UI target. Slices 1–4 have established the six-destination shell, workout-first entry, dense active logging, saved routine rows/editor and freeform workouts in Flutter source; later progression, nutrition and social sections remain targets until their [upgrade slices](COMPETITOR_UPGRADE_PLAN.md) ship. The 28 screenshot observations and proposed behavior are distinguished in that plan.

## Experience and navigation

Transmute should have the reference's task clarity and information density without copying its brand. Use a **six-destination** phone bar in this order: Workout, Today, Ranks, Nutrition, Friends, Profile. Tablet uses a rail and desktop a sidebar with the same destinations and route identity. Active destination has a label and indicator, not color alone. Keep History reachable from Today/Profile/Workout completion, Plans and Routines from Workout, Arcana from progression/Profile, and existing Recovery, Fasting, Goals, Exercises and Settings via contextual shortcuts or secondary navigation. Deep links return to a sensible parent.

A compact progress header may show real level, XP toward next level and streak; it must not show a currency balance, rank or friend count without a saved source. During staged delivery, unfinished destinations show honest availability and a path back, not mock numbers. Today has three local tabs: For You, Feed and Discovery, with distinct purposes. Ranks has Your Rank, Bodygraph, Leagues, Gallery and Analysis. Horizontal tab lists scroll with clear selected state and semantic tab labels.

## Screen hierarchy and density

| Screen | Mobile section order and visible controls |
| --- | --- |
| **Workout home** | Today's named workout/Resume card with sets and estimated duration if sourced → New Workout (Start Empty Workout, Generate Workout, separate Quick Add one exercise) → Routines heading with add/folder → compact routine rows (name, total sets, first 2–3 exercises with set counts, more count, overflow, direct Start). Empty starts a freeform active session in the same logger; sharing remains slice 5. |
| **Active session** | Session title and sync state, plus explicit FREEFORM label and exercise/working-set counts for an empty-origin session → exercise navigator or Add Movement empty state → target and previous comparable performance → dense set ledger with ordinal, per-set previous, weight/reps or duration, warm-up, Log control, Saved/Pending sync feedback and edit/delete on confirmed rows → persistent rest and next/finish controls. At narrow widths, saved-row status and actions stack without horizontal scrolling. Pending sets keep Finish disabled with a reason and a retry action. |
| **Today / For You** | Level/streak and next milestone → today's workout → recovery map/explanation → bodyweight/strength goal → last 14 workouts metrics → Discover shortcuts. Optional sections load independently; Start/Resume remains usable. |
| **Ranks** | Your Rank: large personal tier, placement count, CTA, standings/history. Bodygraph: front/back map, selected muscle details, last-session deltas. Leagues: eligibility/cohort. Gallery: search/filter and two-column rank cards. Analysis: average tiers, next targets, rank-up counts and filtered distribution. |
| **Nutrition** | Local-day navigation → target/food/remaining and macro summary → Add Meal → Recently Logged → meal-type sections and add rows → photo/recipe entry points. If no target, show Set target and confirmed food totals. |
| **Friends** | Leaderboards entry → friend search/invite → accepted/pending friend list or helpful empty state → authorized activity. Feed and standings name their time period and privacy state. |
| **Profile** | Identity/rank/level → shortcut grid → completed-day calendar → 7/14/30-day body/training summary and selectable duration/volume/reps → streak → level/rewards → goal/history previews. Hide a section only when genuinely irrelevant; otherwise explain zero/locked data. |
| **Recipe discovery** | Search above image-led cards with title, servings, creator/curation status → detail with ingredients and per-serving nutrition → editable log confirmation. Secondary reference; use Transmute visual tokens. |

## Components and measurements

Use shared `TransmutePanel`, `TransmuteButton`, fields and state panels, then add reusable `ProgressHeader`, `MetricTile`, `RankBadge`, `ProgressTrack`, `CompactRoutineRow`, `SetLedgerRow`, `BodyRegionMap`, `PeriodChart` and `MealSection` as slices ship. A dense card still needs a clear title, unit, date/period, primary value, action and data state. Compact rows use 8–12dp internal gaps; major sections 24–32dp; columns align numerals and unit labels. On phones, two-up metric/rank cards are allowed when each remains readable and tappable; stack at large text sizes. Charts have text tables or summaries. Never convey a rank, recovery state, streak or save status only by color or artwork.

Display weights in the saved user unit but calculate and persist kg. Show the comparison mode for timed/rep ranks, the baseline and next tier on detail, and estimated 1RM as an estimate. “Remaining” is explicit about whether exercise energy is included. A loading, no evidence, unranked, ineligible, private, failed, pending and success state must each have distinct text and action. Saved data should never be visually confused with an optimistic draft.

## Responsive and accessible behavior

Use current theme/palette and shared geometry; do not impose one platform's native visual style on every target. Mobile keeps primary actions above the fold and sticky actions above keyboard/navigation insets. Tablet and desktop may use a detail pane and chart/summary columns, while preserving the same section order. Support 375dp, 768dp and 1440dp review widths, 200% text, logical focus, Tab/Shift-Tab/Enter/Space/Escape, labeled icon controls, 44dp minimum targets, WCAG AA contrast and `MediaQuery.disableAnimations`.

Set inputs identify exercise, set number, value and unit to assistive technology. Bodygraph regions have selectable text alternatives and a list of the same group results. Rank progress exposes current, next and percentage in text. Calendar days announce date and qualification state. Live announcements describe server confirmation, errors and timer completion without repeatedly reading an entire card. Forms keep drafts on validation/network failure; destructive actions explain consequences.

## Verification evidence

Automated checks cover navigation, state transitions, contract mapping, responsive widget layouts and semantics. The user owns browser verification. Capture the same route, auth/data state, theme and viewport in local API or deployed mode; do not compare a signed-in mock view with a deployed onboarding view. Record source commit and `release/web` bundle version for production review. The screenshots in [the reference inventory](COMPETITOR_UPGRADE_PLAN.md#screen-by-screen-reference-inventory) are design evidence, not UI assets.
