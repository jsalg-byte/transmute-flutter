import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/core/providers.dart';
import 'package:transmute_flutter/features/workout_history/presentation/history_screens.dart';

void main() {
  testWidgets(
    'cancel preserves history; confirmation deletes the selected session',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repository = container.read(sessionRepositoryProvider);
      final before = await repository.completedHistory();
      expect(before, isNotEmpty);
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => const HistoryScreen())],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete Session').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('This cannot be undone.'), findsOneWidget);
      expect((await repository.completedHistory()).length, before.length);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await repository.completedHistory()).length, before.length);
      await tester.tap(find.byTooltip('Delete Session').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete Session'));
      await tester.pumpAndSettle();
      final after = await repository.completedHistory();
      expect(after.length, before.length - 1);
      expect(after.any((item) => item.id == before.first.id), isFalse);
      expect(find.text('Session deleted.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
