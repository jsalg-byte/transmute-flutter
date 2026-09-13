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
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(20, 450),
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
    for (final label in ['Home', 'Nutrition', 'Workout', 'More']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Workout plans'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
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
      'Progress',
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

  testWidgets('1440dp uses the full desktop header navigation', (tester) async {
    await pumpShell(tester, 1440);
    expect(find.text('TRANSMUTE'), findsOneWidget);
    for (final label in [
      'Dashboard',
      'Workout Plans',
      'Workout',
      'Sessions',
      'Exercise library',
      'Nutrition',
      'Progress',
      'Fasting',
      'Settings',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Menu'), findsNothing);
    expect(find.byTooltip('Open navigation'), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
