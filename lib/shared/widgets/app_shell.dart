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
    _ShellDestination('Today', '/dashboard', Icons.home_outlined),
    _ShellDestination('Plans', '/plans', Icons.format_list_bulleted),
    _ShellDestination('Workout', '/session', Icons.fitness_center),
    _ShellDestination('History', '/history', Icons.history),
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
                SizedBox(
                  height: 70,
                  child: Row(
                    children: [
                      for (final destination in _primary)
                        _DesktopNavItem(
                          destination: destination,
                          selected: _isSelected(location, destination.route),
                        ),
                      const Spacer(),
                      _desktopDestinationMenu(context, location),
                    ],
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
    final selectedIndex = _compact.indexWhere(
      (item) => _isSelected(location, item.route),
    );
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
          selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
          onDestinationSelected: (index) => context.go(_compact[index].route),
          destinations: [
            for (final item in _compact)
              NavigationDestination(icon: Icon(item.icon), label: item.label),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
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

  Widget _destinationMenu(
    BuildContext context,
    WidgetRef ref,
  ) => PopupMenuButton<String>(
    tooltip: 'Open navigation',
    icon: const Icon(Icons.menu),
    onSelected: (route) {
      if (route == '/logout') {
        ref.read(authControllerProvider.notifier).logout();
      } else {
        context.go(route);
      }
    },
    itemBuilder: (_) => [
      for (final item in _primary)
        PopupMenuItem(value: item.route, child: Text(item.label)),
      const PopupMenuDivider(),
      const PopupMenuItem(
        enabled: false,
        child: Text('RECORD', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      for (final item in _record)
        PopupMenuItem(value: item.route, child: Text(item.label)),
      const PopupMenuItem(
        enabled: false,
        child: Text('GROWTH', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      for (final item in _growth)
        PopupMenuItem(value: item.route, child: Text(item.label)),
      const PopupMenuItem(
        enabled: false,
        child: Text('ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      for (final item in _account)
        PopupMenuItem(value: item.route, child: Text(item.label)),
      const PopupMenuDivider(),
      const PopupMenuItem(value: '/logout', child: Text('Sign out')),
    ],
  );

  Widget _desktopDestinationMenu(
    BuildContext context,
    String location,
  ) => PopupMenuButton<String>(
    tooltip: 'Open all navigation',
    onSelected: context.go,
    itemBuilder: (_) => [
      const PopupMenuItem(
        enabled: false,
        child: Text('RECORD', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      for (final item in _record) _desktopMenuItem(context, location, item),
      const PopupMenuItem(
        enabled: false,
        child: Text('GROWTH', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      for (final item in _growth) _desktopMenuItem(context, location, item),
      const PopupMenuItem(
        enabled: false,
        child: Text('ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      for (final item in _account) _desktopMenuItem(context, location, item),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu, size: 19, color: TransmutePalette.of(context).ink),
          const SizedBox(width: 7),
          Text(
            'Menu',
            style: TextStyle(
              color: TransmutePalette.of(context).ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );

  PopupMenuItem<String> _desktopMenuItem(
    BuildContext context,
    String location,
    _ShellDestination item,
  ) => PopupMenuItem(
    value: item.route,
    child: Text(
      item.label,
      style: TextStyle(
        fontWeight: _isSelected(location, item.route)
            ? FontWeight.w800
            : FontWeight.w400,
        decoration: _isSelected(location, item.route)
            ? TextDecoration.underline
            : null,
      ),
    ),
  );
}

class _ShellDestination {
  const _ShellDestination(this.label, this.route, [this.icon]);
  final String label;
  final String route;
  final IconData? icon;
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({required this.destination, required this.selected});
  final _ShellDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.go(destination.route),
    child: Padding(
      padding: const EdgeInsets.only(right: 20),
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
          final next = ThemePreference(
            palette: preference.palette,
            brightness: isDark
                ? PreferenceBrightness.light
                : PreferenceBrightness.dark,
          );
          ref.read(themeOverrideProvider.notifier).set(next);
          try {
            final saved = await ref
                .read(preferencesRepositoryProvider)
                .setTheme(next);
            ref.read(themeOverrideProvider.notifier).set(saved);
            ref.invalidate(themePreferenceProvider);
          } on AppFailure catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${error.message} Dark mode will remain on for this session.',
                  ),
                ),
              );
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Theme preference could not be saved. Dark mode will remain on for this session.',
                  ),
                ),
              );
            }
          }
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
