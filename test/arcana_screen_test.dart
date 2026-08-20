import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/features/arcana/presentation/arcana_screen.dart';

void main() {
  testWidgets('Arcana exposes evidence and an honest empty stage filter', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ArcanaScreen()),
        GoRoute(path: '/dashboard', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/plans', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/session', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/history', builder: (_, _) => const SizedBox()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Personal Arcana'), findsOneWidget);
    expect(find.text('1 of 15 revealed'), findsOneWidget);
    expect(find.bySemanticsLabel('0 The Fool, Revealed'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('0 The Fool, Revealed'));
    await tester.pumpAndSettle();
    expect(find.text('Evidence'), findsOneWidget);
    expect(
      find.text('A qualified session established the record.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Refined'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No cards have reached this stage yet'), findsOneWidget);
  });
}
