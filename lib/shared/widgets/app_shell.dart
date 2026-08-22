import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/models.dart';
import '../../core/domain/repositories.dart';
import '../../core/providers.dart';
import '../theme/transmute_palette.dart';

/// The desktop shell intentionally follows the existing Transmute web client:
/// a quiet wordmark header and a full, textual navigation strip. Compact
/// breakpoints retain Material navigation for touch-first use.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  static const _primary = <_ShellDestination>[
    _ShellDestination('Dashboard', '/dashboard'),
    _ShellDestination('Workout Plans', '/plans'),
    _ShellDestination('Workout', '/session'),
    _ShellDestination('Sessions', '/history'),
  ];

  static const _compact = <_ShellDestination>[
    _ShellDestination('Home', '/dashboard', Icons.home_outlined),
    _ShellDestination('Nutrition', '/nutrition', Icons.restaurant_outlined),
    _ShellDestination('Workout', '/session', Icons.fitness_center),
  ];

  static const _record = <_ShellDestination>[
    _ShellDestination('Exercise library', '/exercises'),
    _ShellDestination('Nutrition', '/nutrition'),
    _ShellDestination('Progress', '/progress'),
    _ShellDestination('Fasting', '/fasting'),
  ];

  static const _growth = <_ShellDestination>[
    _ShellDestination('Goals', '/goals'),
    _ShellDestination('Planning', '/planning'),
    _ShellDestination('Arcana', '/arcana'),
    _ShellDestination('Friends', '/friends'),
  ];

  static const _account = <_ShellDestination>[
    _ShellDestination('Settings', '/settings'),
  ];

  static const _desktopDestinations = <_ShellDestination>[
    ..._primary,
    ..._record,
    ..._growth,
    ..._account,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final location = GoRouterState.of(context).matchedLocation;
    if (width >= 1024) return _desktop(context, ref, location);
    return _compactShell(context, ref, location, width);
  }

  Widget _desktop(BuildContext context, WidgetRef ref, String location) {
    final palette = TransmutePalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 18),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.go('/dashboard'),
                        child: const _Wordmark(),
                      ),
                      const Spacer(),
                      _ThemeSwitch(ref: ref),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).logout(),
                        style: TextButton.styleFrom(
                          foregroundColor: palette.ink,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: palette.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        for (final destination in _desktopDestinations)
                          _DesktopNavItem(
                            destination: destination,
                            selected: _isSelected(location, destination.route),
                          ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: palette.divider),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 28, 0, 24),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 840),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactShell(
    BuildContext context,
    WidgetRef ref,
    String location,
    double width,
  ) {
    final compactIndex = _compact.indexWhere(
      (item) => _isSelected(location, item.route),
    );
    final selectedIndex = compactIndex >= 0 ? compactIndex : _compact.length;
    final content = SafeArea(
      child: Padding(
        padding: EdgeInsets.all(width < 600 ? 16 : 24),
        child: child,
      ),
    );
    if (width < 600) {
      return Scaffold(
        appBar: AppBar(
          title: const _Wordmark(compact: true),
          actions: [_destinationMenu(context, ref)],
        ),
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            if (index == _compact.length) {
              _showMoreSheet(context, ref);
              return;
            }
            context.go(_compact[index].route);
          },
          destinations: [
            for (final item in _compact)
              NavigationDestination(icon: Icon(item.icon), label: item.label),
            const NavigationDestination(
              icon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: compactIndex < 0 ? 0 : compactIndex,
            onDestinationSelected: (index) => context.go(_compact[index].route),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.only(top: 16),
              child: _Wordmark(compact: true),
            ),
            destinations: [
              for (final item in _compact)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                ),
            ],
          ),
          VerticalDivider(
            width: 1,
            color: TransmutePalette.of(context).divider,
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(title),
                actions: [_destinationMenu(context, ref)],
              ),
              body: content,
            ),
          ),
        ],
      ),
    );
  }

  static bool _isSelected(String location, String route) {
    if (route == '/dashboard') return location == route;
    return location == route || location.startsWith('$route/');
  }

  Widget _destinationMenu(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: 'Open navigation',
    icon: const Icon(Icons.menu),
    onPressed: () => _showNavigationSheet(context, ref),
  );

  void _showMoreSheet(BuildContext context, WidgetRef ref) {
    _showNavigationSheet(context, ref, includePrimary: false);
  }

  void _showNavigationSheet(
    BuildContext context,
    WidgetRef ref, {
    bool includePrimary = true,
  }) {
    final record = includePrimary
        ? _record
        : _record.where((item) => item.route != '/nutrition').toList();
    final workout = includePrimary
        ? _primary
        : const [
            _ShellDestination('Workout plans', '/plans'),
            _ShellDestination('Sessions', '/history'),
          ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _CompactNavigationMenu(
        sections: [
          _MenuSection('WORKOUT', workout),
          _MenuSection('RECORD', record),
          _MenuSection('GROWTH', _growth),
          _MenuSection('ACCOUNT', _account),
        ],
        onSelect: (route) {
          Navigator.of(sheetContext).pop();
          context.go(route);
        },
        onSignOut: () {
          Navigator.of(sheetContext).pop();
          ref.read(authControllerProvider.notifier).logout();
        },
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination(this.label, this.route, [this.icon]);
  final String label;
  final String route;
  final IconData? icon;
}

class _MenuSection {
  const _MenuSection(this.label, this.destinations);
  final String label;
  final List<_ShellDestination> destinations;
}

class _CompactNavigationMenu extends ConsumerWidget {
  const _CompactNavigationMenu({
    required this.sections,
    required this.onSelect,
    required this.onSignOut,
  });

  final List<_MenuSection> sections;
  final ValueChanged<String> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(effectiveThemePreferenceProvider);
    final isDark = preference.brightness == PreferenceBrightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 600 ? 3 : 2;
            final itemWidth =
                (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.light_mode_outlined, size: 18),
                    Tooltip(
                      message: isDark ? 'Use light mode' : 'Use dark mode',
                      child: Switch(
                        value: isDark,
                        onChanged: (useDark) => _setThemePreference(
                          context,
                          ref,
                          preference,
                          useDark,
                        ),
                      ),
                    ),
                    const Icon(Icons.dark_mode_outlined, size: 18),
                    IconButton(
                      tooltip: 'Close navigation',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                    child: Text(
                      section.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      for (final destination in section.destinations)
                        SizedBox(
                          width: itemWidth,
                          height: 44,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onPressed: () => onSelect(destination.route),
                            child: Text(
                              destination.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const Divider(height: 16),
                SizedBox(
                  height: 44,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({required this.destination, required this.selected});
  final _ShellDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.go(destination.route),
    child: Padding(
      padding: EdgeInsets.zero,
      child: Text(
        destination.label,
        style: TextStyle(
          color: selected
              ? TransmutePalette.of(context).ink
              : TransmutePalette.of(context).muted,
          fontSize: 15,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
          decoration: selected ? TextDecoration.underline : null,
          decorationThickness: 2,
        ),
      ),
    ),
  );
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset(
        'assets/transmute/ouroboros.svg',
        width: compact ? 24 : 38,
        height: compact ? 24 : 38,
        colorFilter: ColorFilter.mode(
          TransmutePalette.of(context).ink,
          BlendMode.srcIn,
        ),
      ),
      SizedBox(width: compact ? 7 : 12),
      Text(
        'TRANSMUTE',
        style: TextStyle(
          color: TransmutePalette.of(context).ink,
          fontSize: compact ? 13 : 19,
          fontWeight: FontWeight.w900,
          letterSpacing: compact ? 1.8 : 3.2,
        ),
      ),
    ],
  );
}

class _ThemeSwitch extends ConsumerWidget {
  const _ThemeSwitch({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final palette = TransmutePalette.of(context);
    final preference = ref.watch(effectiveThemePreferenceProvider);
    final isDark = preference.brightness == PreferenceBrightness.dark;
    return Semantics(
      button: true,
      label: isDark ? 'Use light mode' : 'Use dark mode',
      child: OutlinedButton(
        onPressed: () async {
          await _setThemePreference(context, ref, preference, !isDark);
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(96, 48),
          padding: EdgeInsets.zero,
          side: BorderSide(color: palette.ink),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 47,
              height: 46,
              color: isDark ? Colors.transparent : palette.ink,
              child: Icon(
                Icons.light_mode_outlined,
                size: 20,
                color: isDark ? palette.muted : palette.raised,
              ),
            ),
            SizedBox(
              width: 47,
              height: 46,
              child: Icon(
                Icons.dark_mode_outlined,
                size: 20,
                color: isDark ? palette.raised : palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _setThemePreference(
  BuildContext context,
  WidgetRef ref,
  ThemePreference preference,
  bool useDark,
) async {
  final next = ThemePreference(
    palette: preference.palette,
    brightness: useDark
        ? PreferenceBrightness.dark
        : PreferenceBrightness.light,
  );
  ref.read(themeOverrideProvider.notifier).set(next);
  try {
    final saved = await ref.read(preferencesRepositoryProvider).setTheme(next);
    ref.read(themeOverrideProvider.notifier).set(saved);
    ref.invalidate(themePreferenceProvider);
  } on AppFailure catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${error.message} Theme preference will remain on for this session.',
          ),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Theme preference could not be saved. It will remain on for this session.',
          ),
        ),
      );
    }
  }
}
