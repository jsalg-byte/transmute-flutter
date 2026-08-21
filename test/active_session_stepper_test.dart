import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/core/providers.dart';
import 'package:transmute_flutter/features/active_session/presentation/active_session_screen.dart';

void main() {
  testWidgets(
    'active workout shows one movement and steps to the next movement',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(activeSessionProvider.notifier)
          .start('upper-a', 'upper-a-day-1');
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ActiveSessionScreen()),
          GoRoute(path: '/dashboard', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/plans', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/session', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/history', builder: (_, _) => const SizedBox()),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Barbell bench press'), findsOneWidget);
      expect(find.text('Chest-supported row'), findsNothing);

      await tester.tap(find.byTooltip('Start 60 second rest'));
      await tester.pump();

      expect(find.byTooltip('Minimize rest timer'), findsOneWidget);
      expect(find.text('1m'), findsOneWidget);

      await tester.tap(find.byTooltip('Next movement'));
      await tester.pumpAndSettle();

      expect(find.text('Chest-supported row'), findsOneWidget);
      expect(find.text('Barbell bench press'), findsNothing);
      await container.read(activeSessionProvider.notifier).discard();
    },
  );
}
