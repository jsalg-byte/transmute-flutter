import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/shared/widgets/app_shell.dart';

void main() {
  testWidgets(
    'desktop wheel scrolls from the outer gutter and only once over content',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => MediaQuery(
              data: const MediaQueryData(size: Size(1600, 900)),
              child: AppShell(
                title: 'Scroll test',
                child: ListView(children: const [SizedBox(height: 2400)]),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();
      final position = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(250, 450),
          scrollDelta: Offset(0, 120),
        ),
      );
      await tester.pump();
      expect(position.pixels, 120);
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(500, 450),
          scrollDelta: Offset(0, 120),
        ),
      );
      await tester.pump();
      expect(position.pixels, 240);
    },
  );
  Future<void> pumpShell(WidgetTester tester, double width) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MediaQuery(
            data: MediaQueryData(size: Size(width, 812)),
            child: const AppShell(
              title: 'Test route',
              child: SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();
  }

  testWidgets('375dp uses the bottom navigation shell', (tester) async {
    await pumpShell(tester, 375);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    for (final label in [
      'Workout',
      'Today',
      'Ranks',
      'Nutrition',
      'Friends',
      'Profile',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    expect(find.text('Workout plans'), findsOneWidget);
    expect(find.text('Workout history'), findsOneWidget);
  });

  testWidgets('375dp navigation remains usable at 200% text', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MediaQuery(
            data: const MediaQueryData(
              size: Size(375, 812),
              textScaler: TextScaler.linear(2),
            ),
            child: const AppShell(title: 'Workout', child: SizedBox.expand()),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('secondary navigation exposes the full record inventory', (
    tester,
  ) async {
    await pumpShell(tester, 375);
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsOneWidget);

    for (final label in [
      'Workout',
      'Exercise library',
      'Nutrition',
      'Progress photos',
      'Fasting',
      'Settings',
    ]) {
      expect(
        find.text(label),
        label == 'Workout' || label == 'Nutrition'
            ? findsWidgets
            : findsOneWidget,
      );
    }
  });

  testWidgets('768dp uses the navigation rail shell', (tester) async {
    await pumpShell(tester, 768);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('primary destinations navigate and return to Today', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final paths = <String>[
      '/session',
      '/dashboard',
      '/ranks',
      '/nutrition',
      '/friends',
      '/profile',
    ];
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        for (final path in paths)
          GoRoute(
            path: path,
            builder: (_, _) => MediaQuery(
              data: const MediaQueryData(size: Size(390, 844)),
              child: AppShell(
                title: path,
                child: Center(child: Text('Current $path')),
              ),
            ),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    for (final (label, path) in [
      ('Workout', '/session'),
      ('Ranks', '/ranks'),
      ('Nutrition', '/nutrition'),
      ('Friends', '/friends'),
      ('Profile', '/profile'),
    ]) {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pumpAndSettle();
      expect(find.text('Current $path'), findsOneWidget);
    }
    await tester.tap(find.widgetWithText(NavigationDestination, 'Today'));
    await tester.pumpAndSettle();
    expect(find.text('Current /dashboard'), findsOneWidget);
  });

  testWidgets('1440dp uses the desktop sidebar navigation', (tester) async {
    await pumpShell(tester, 1440);
    expect(find.text('TRANSMUTE'), findsOneWidget);
    for (final label in [
      'Workout',
      'Today',
      'Ranks',
      'Nutrition',
      'Friends',
      'Profile',
      'More destinations',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Menu'), findsNothing);
    expect(find.byTooltip('Open navigation'), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
