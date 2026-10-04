# Transmute product requirements

**Target direction (2026-10-03).** [The competitor upgrade plan](COMPETITOR_UPGRADE_PLAN.md) is the detailed screenshot evidence, rules, backend work and end-to-end slice order. This PRD states the intended product. Existing source and the implemented Expo adapter API contract remain the baseline for what works today; they are not a limit on new features. The former narrow Flutter demonstration scope is superseded for product planning.

## Product statement

Transmute is a workout-first fitness app that makes each training session easy to plan and log, then turns confirmed effort into understandable strength progress and motivating, honest progression. It should approach Liftoff's breadth, screen structure, information density and gamified training loop while using Transmute's identity, themes and original alchemical visual system. Arcana complements exercise rankings, levels and streaks rather than replacing them.

## Users and jobs

- A lifter wants to choose today's training, start immediately, see a previous result, record/edit sets quickly, run rest timers, and trust the saved outcome.
- A repeat trainee wants routines that are easy to scan, create, adjust, start and share; an unplanned day should still be loggable as a full session.
- A progress-focused user wants rank movement for each exercise, muscle-group/bodygraph improvement, overall rank and history, records, charts and specific goals with explained calculations.
- A consistency-focused user wants XP/levels, milestones/rewards, streaks and a calendar that reflect real completed training.
- A user who tracks food wants a daily target, remaining calories/macros, direct meal logging, optional photo-assisted review, and recipe discovery.
- A social user wants activity from accepted friends and real, privacy-controlled leaderboards and leagues.

## Core experience and information architecture

Mobile primary destinations are **Workout, Today, Ranks, Nutrition, Friends, Profile**, with matching rail/sidebar navigation at larger widths. Workout shows today's session, new-session choices and saved routines. Today shows level/streak, actionable progression, workout/recovery, goals and training summaries, then discovery. Ranks has Your Rank, Bodygraph, Leagues, Gallery and Analysis. Nutrition has the day overview and meal diary with food/recipe discovery. Friends has activity, search/invitations and standings. Profile has identity, shortcuts, calendar, training charts, streak, level/rewards and goals. Completed history and existing Arcana remain accessible from contextual entry points.

The first visible action should be the user's actual next action; data-dense cards must name period, unit and source. No screen presents decorative metrics that lack a persisted source. Empty and eligibility states tell the user what unlocks the next view. Visual treatment is substantially upgraded within Transmute's saved themes, shared components and original assets.

## Required capabilities

1. Reliable one-active-session lifecycle, dense rep/timed set logging, previous performance, editable and acknowledged sets, rest, resume, completion and history.
2. Routine creation/editing, compact previews, direct start, freeform multi-exercise sessions, and authorized routine snapshot sharing/import.
3. Versioned per-exercise personal strength tiers and next-tier progress; overall placement, rank history, curated muscle-group rankings and front/back bodygraph.
4. Versioned XP ledger, levels, original milestone rewards, qualified training days, streaks and calendar. Existing server-owned Arcana remains a separate complementary system.
5. Period training charts and source-backed bodyweight and exercise-strength goals.
6. Daily user-set calorie and optional macro targets, meal-type diary, confirmed serving-based meal logging, separate photo candidate review, and a secondary recipe catalog.
7. Accepted-friend activity, invitations/search, opt-in friend leaderboards and eligible opt-in leagues using real participating accounts.

The screenshots support many of these visible surfaces but do not reveal hidden behavior or proprietary scoring. Proposed implementation rules are documented and versioned in the upgrade plan. No personal rank is called a population percentile. No activity, standing, calorie burn, recipe nutrition or reward balance is fabricated.

## Delivery principles

- Deliver one usable UI→state→API→persistence improvement per slice. Backend schema, endpoints and scoring services in the sibling Fastify repository are part of feature work, not grounds for indefinite deferral.
- Server data is canonical; Flutter preserves pending versus acknowledged state, uses repository interfaces and mirrors features in mock mode for a non-durable demo.
- Keep user-set nutrition targets explicit, private data private by default, and social participation opt-in. Photo analysis is always reviewed before creating a meal.
- Reconcile corrections/deletions across projections, XP and standings. Rule revisions must identify their version and should not silently rewrite history.
- Use accessible text alongside color/diagrams, reduced-motion-aware animation, touch and keyboard paths, and sensible layout at phone/tablet/desktop widths.

## Product acceptance

A signed-in real-API user can start and finish a planned or freeform workout, see exact saved sets after reload, inspect exercise and muscle rank changes explained by evidence, earn correctly calculated XP/levels/streaks, review training history/goals, log meals against a chosen target, and opt into real friend activity/standings. Failed or pending mutations never count as saved evidence. Feature-specific criteria and phased delivery live in [COMPETITOR_UPGRADE_PLAN.md](COMPETITOR_UPGRADE_PLAN.md).

The user owns browser verification. Compare like-for-like auth/data/theme/viewport states; a local signed-in mock and deployed pre-login screen cannot establish visual parity. Production web serves checked-in `release/web`, not uncommitted Dart source.
