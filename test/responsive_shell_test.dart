import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/shared/widgets/app_shell.dart';

void main() {
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
    expect(find.text('Plans'), findsWidgets);
  });

  testWidgets('secondary navigation exposes the full record inventory', (
    tester,
  ) async {
    await pumpShell(tester, 375);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    for (final label in [
      'Exercise library',
      'Nutrition',
      'Progress',
      'Fasting',
      'Goals',
      'Planning',
      'Arcana',
      'Friends',
      'Settings',
    ]) {
      expect(find.text(label), findsOneWidget);
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
    expect(find.text('Workout Plans'), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
