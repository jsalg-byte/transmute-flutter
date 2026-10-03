# Shared Design System

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
