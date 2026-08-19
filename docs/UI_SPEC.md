# Transmute Flutter demonstration: UI contract

## Visual direction

Use the Transmute default light theme as the demo baseline: private training
ledger, square-edged cards/buttons, warm paper surface, dark ink, muted
blue-oxide accent, and restrained alchemical identity. Use iconography, not
emoji. Do not copy external franchise artwork.

## Tokens

| Token | Value | Use |
| --- | --- | --- |
| `surface` | `#F4EBD8` | App background. |
| `raised` | `#FCF7EC` | Cards, fields, dialogs. |
| `ink` | `#171821` | Headlines and primary buttons. |
| `body` | `#292B35` | Body copy. |
| `muted` | `#605D63` | Supporting copy. |
| `divider` | `#D9CEB9` | Borders/separators. |
| `oxide` | `#6D79A0` | Links, selected navigation, focus ring. |
| `destructive` | `#A33B36` | Destructive action/error emphasis. |
| `gold` | `#D1A742` | Sparing evidence/highlight use. |
| `success` | `#3E745C` | Set/session completion confirmation. |

Use Material 3 with a custom `ColorScheme` derived from these tokens. Minimum
touch target is 44x44dp. Cards, buttons, and inputs use a 1dp square corner
border; do not use pill shapes except compact status chips.

## Typography and spacing

| Role | Font/size/weight | Notes |
| --- | --- | --- |
| Display | Georgia or platform serif, 32/38, 700 | Page/session headings. |
| Heading | system sans, 20/26, 700 | Card headings. |
| Body | system sans, 16/24, 400 | Default content. |
| Label | system sans, 12/16, 700, 1.2px tracking | Uppercase ledger labels. |
| Button | system sans, 15/20, 700 | Never all caps unless a compact label. |

Base spacing scale: `4, 8, 12, 16, 24, 32, 48`. Page padding is 16dp on
mobile, 24dp tablet, and 32dp desktop. Content max width is 1180dp.

## Navigation

| Width | Structure | Exact items |
| --- | --- | --- |
| `<600dp` | Bottom `NavigationBar` | Plans, Workout, History. Workout routes to active session or plans with an inline no-active state. |
| `600–1023dp` | `NavigationRail` | Same three items and logout at the bottom. |
| `>=1024dp` | Persistent 240dp sidebar | Wordmark, same three items, active-session indicator, logout. |

Active navigation is visible by label color plus a left/upper oxide indicator;
never color alone. The content route title is always present in the body, not
only in navigation chrome.

## Component states

| Component | Required states |
| --- | --- |
| Button | default, hover (desktop), focus-visible, pressed, disabled, loading. |
| Text field | default, hover, focused oxide border, invalid destructive border/message, disabled. |
| Plan/session card | default, hover/focus, selected where applicable, loading skeleton. |
| Async panel | loading skeleton, empty explanation, error + retry, success. |
| Set row | pending optimistic, saved, retry-needed, editing, read-only completed. |
| Rest timer | idle, running, elapsed, paused/reset. |

Show progress in the action that is waiting; do not block unrelated read-only
navigation while a set mutation is pending.

## Dialog and form rules

- Add-exercise dialog is modal, labelled `Add exercise`, initially focuses the
  search field, traps focus, supports Escape, and returns focus on close.
- Discard dialog is destructive and requires explicit `Discard workout`; its
  safe option is `Keep workout` and receives initial focus.
- Finish has a confirmation only if there are zero logged sets. Otherwise it is
  a direct action with a progress state.
- Form errors appear beneath their field and in a polite live region. Network
  errors appear at panel level with an explicit retry.
- Numeric keyboard/input accepts decimal display values then converts to/from
  `weightKg`. Preserve raw invalid text until corrected.

## Layout rules

- Plan list: one column below 600dp; two columns from 600–1023dp; three columns
  at 1024dp+ when cards remain at least 280dp wide.
- Plan detail: prescription list is one column on mobile; at desktop, place a
  300dp summary/start panel beside the list.
- Active session: one column under 1024dp. At desktop, put movement navigator
  and sticky action/timer column beside the 640dp set ledger. Do not hide sets
  behind horizontal scrolling.
- History: list at small/medium widths; desktop may use a two-column list plus
  detail pane only when a session is selected.
- Use `SafeArea`, scrollable content, and inset-aware sticky action bars. No
  text or actions may be obscured by navigation/keyboard.

## Accessibility and interaction

- Meet WCAG 2.1 AA contrast; verify `oxide` link/focus treatment against
  `surface` and use `ink` text where contrast requires it.
- Every icon-only control has a semantic label. Set fields include exercise and
  set ordinal in their accessible label.
- Support Tab/Shift-Tab, Enter/Space, Escape, mouse, trackpad, and touch.
- Announce optimistic completion, mutation failure, timer elapsed, and route
  heading changes to assistive technology.
- Respect text scaling through at least 200%; wrap/reflow rather than clip.

## Screenshot checklist

Capture after implementation, in mock mode, with no debug overlays:

1. 375x812: plan list with bottom navigation.
2. 375x812: active session with a logged set and running rest timer.
3. 768x1024: plan detail with navigation rail.
4. 1440x900: active session desktop two-column layout/sidebar.
5. 1440x900: completed-session detail/history.

Store them under `docs/screenshots/` with descriptive filenames. They are a
verification artifact, not design input to invent behavior.
