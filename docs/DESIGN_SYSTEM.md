# Shared Design System

## Expanded product direction (2026-10-03)

The shared library is the **foundation**, not a limit on the larger experience
in [COMPETITOR_UPGRADE_PLAN.md](COMPETITOR_UPGRADE_PLAN.md) and
[UI_SPEC.md](UI_SPEC.md). The target has a denser, workout-first shell, a
prominent progression header, rank gallery/bodygraph, training charts, meal
diary, and social standings. Those surfaces should look and feel like one
Transmute product across every saved palette and light/dark choice. Liftoff's
hierarchy and information density are reference patterns; its badges,
illustrations, mascot, branding, and exact colors are not assets to use.

Extend tokens and shared components before adding feature-local styling:

| New shared pattern | Design intent and required behavior |
| --- | --- |
| Progress header and level track | Compact level/XP/streak values with source-backed labels, semantic progress, and graceful absence before the progression API exists. |
| Rank badge and tier track | Original alchemical emblems, readable tier name, current/next threshold, text progress and versioned rule explanation. Maintain a common silhouette across tiers; color is supplemental. |
| Ranked bodygraph | Original front/back vector with stable region IDs, selected-region state, legend and an equivalent text list. Keep recovery and rank color semantics distinct. |
| Compact workout/routine/set rows | Dense numeric alignment, visible previous result and saved/pending/error state, large hit areas despite tighter visual spacing. |
| Metric tile and period chart | Unit, metric, period, source and no-data text; use local filters and text summaries as chart alternatives. |
| Meal/day and social cards | Direct actions adjacent to the relevant section; provenance, privacy and loading state visible before a user acts. |

Keep the current Ledger geometry and Spectral/editorial plus sans typography
as Transmute's default; Soft and the existing palette choices remain valid.
The upgrade may change screen composition, sizing and density substantially
where the new hierarchy requires it. Build original alchemy-inspired vectors
for ranks, milestones and body regions; use clear fitness words such as Ranks,
Level and Streak rather than hiding those systems behind Arcana terms. Arcana
can link to the same verified workout evidence without replacing them.

All patterns need loading, empty, error, pending, saved, disabled and reduced
motion states as relevant. Use 44dp touch areas, readable contrast, keyboard
focus, `Semantics`, and 200% text reflow. A compressed card must not compress
its tap target or truncate its primary metric. The user performs browser
verification; component tests and analyzer results are separate evidence.

The first version centralizes existing Transmute components without changing
workout behavior or introducing a new account preference contract.

## Preview

Run the debug web app and open `http://localhost:8081/#/design-library`.
The catalog is debug-only, works without signing in, and uses local sample data.
It never saves preferences, logs workouts, or uploads anything. Browser review
is performed by the user.

Switch between all seven existing palettes, light/dark, and two component
styles: **Ledger** (the application default) and **Soft** (a rounded prototype).
Style and palette are independent. The prototype is not a saved account setting.

## Layers

| Layer | Source | Responsibility |
| --- | --- | --- |
| Color | `lib/shared/theme/transmute_palette.dart` | Existing semantic colors, selected by the saved palette and brightness. |
| Geometry and motion | `lib/shared/design_system/design_tokens.dart` | Shape, spacing scale, control/row minimum sizes, elevation, focus width, and reduced-motion-aware duration helpers. |
| Theme | `lib/shared/design_system/transmute_theme.dart` | Explicit semantic Material roles, complete Spectral/editorial + sans body typography, and shared component themes. |
| Components | `lib/shared/design_system/components.dart` | Reusable panels, list rows, state panels, and accessible control states. |
| Features | `lib/features/` | Data, validation, async actions, controller lifetime, and navigation. |

Import `shared/design_system/design_system.dart` from feature screens. Do not
branch a screen on palette/style or copy the catalog's mock data into a feature.
Read semantic colors through `TransmutePalette.of(context)` and geometry through
`DesignTokens.of(context)` when composing additional shared widgets.

The default Ledger style keeps Transmute's sharp, printed-record surfaces and
Spectral display headings; body and control text use the platform sans family.
Soft geometry is an alternate style preset, and Cute Pastel injects the same
soft geometry tokens so shared widgets remain coherent when that preference is
active. Use `DesignMotion.duration(context, DesignMotion.standard)` for custom
transitions so system reduced-motion settings can shorten them to zero. Prefer
Material's built-in pressed/focus/disabled behavior for controls over bespoke
screen-local animations.

## Components

- `TransmutePanel`: themed container with shared padding. Pass `EdgeInsets.zero`
  for already-padded content such as ListTile.
- `TransmuteButton`: primary, secondary, quiet, destructive, disabled and loading
  states. Loading keeps label dimensions and disables the action. For a group of
  asynchronous actions, pass `loading: true` only to the submitting action and
  `onPressed: null` to its disabled siblings.
- `TransmuteTextField`: outlined forms and compact underlined ledger inputs.
  Supports hint units, error text, disabled state, numeric keyboards, and semantic
  labels. Callers own controllers and validation; placeholders remain display-only.
- `TransmuteStepper`: selected title, clickable segment indicators,
  previous/next controls, and optional footer. Callers own the index, disable
  boundary callbacks, and can pass `onStepSelected` for direct step jumps. The
  title scales down to preserve the existing one-line movement layout; semantics
  always expose the full title and step position.
- `TransmuteListRow`: shared touch-sized title/subtitle rows with optional icons,
  trailing content, tap behavior, and a single accessible name.
- `TransmuteStatePanel`: consistent loading, empty, error, and success treatment;
  errors are announced as a live region and every state has text, not color alone.

Panels and controls take their shape, spacing, focus, and disabled states from
the active `ThemeData`; new feature screens should compose these shared parts
rather than set local colors or radii for common patterns.

```dart
TransmutePanel(
  child: TransmuteTextField(
    controller: weightController,
    hint: '70 lb',
    semanticLabel: 'Set 1, Weight (lb)',
    kind: TransmuteFieldKind.ledger,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
  ),
)
```

## Adoption and next steps

The app now uses the theme factory globally. The active workout uses shared set
inputs, movement navigation and next/finish action; history uses shared panels.
Other feature-specific components remain unchanged. The original UI contract in
`UI_SPEC.md` describes the early demo; this document describes the new library,
not a rewrite of current navigation or existing user-requested interactions.

For another design system, add a `DesignStyle` and token preset, then preview it
using the same components. For account-wide style selection later, first define
the persistence/API contract and provide a default for older accounts. Do not
overload the existing color-palette field with layout preferences.

Future incremental extractions: dialogs/sheets, banners, async panels, session
set rows and timers. Keep mutation and lifecycle logic in their owning features.

## Checks

Use `.fvm/flutter_sdk/bin/flutter analyze` and
`.fvm/flutter_sdk/bin/flutter test test/design_system_test.dart test/active_session_stepper_test.dart`.
The library tests cover theme combinations, preview widths/text scaling, boundary
navigation, disabled/loading states, and sample form interactions. These tests do
not replace user browser review.
