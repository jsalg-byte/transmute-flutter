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
      expect(find.text('Next Movement'), findsOneWidget);

      await tester.tap(find.byTooltip('Start 60 second rest'));
      await tester.pump();

      expect(find.byTooltip('Minimize rest timer'), findsOneWidget);
      expect(find.text('1m'), findsOneWidget);

      await tester.tap(find.byTooltip('Custom rest'));
      await tester.pumpAndSettle();
      expect(find.text('Custom rest'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Next Movement'));
      await tester.pumpAndSettle();

      expect(find.text('Chest-supported row'), findsOneWidget);
      expect(find.text('Barbell bench press'), findsNothing);
      await container.read(activeSessionProvider.notifier).discard();
    },
  );

  testWidgets(
    'active workout resumes at the movement with the latest logged set',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final session = await container
          .read(activeSessionProvider.notifier)
          .start('upper-a', 'upper-a-day-1');
      await container
          .read(sessionRepositoryProvider)
          .createSet(session.exercises[1].id, 40, 6);
      await container.read(activeSessionProvider.notifier).refresh();
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

      expect(find.text('Chest-supported row'), findsOneWidget);
      expect(find.text('Barbell bench press'), findsNothing);
      await container.read(activeSessionProvider.notifier).discard();
    },
  );

  testWidgets('editing a set with unchanged values safely saves', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final session = await container
        .read(activeSessionProvider.notifier)
        .start('upper-a', 'upper-a-day-1');
    await container
        .read(sessionRepositoryProvider)
        .createSet(session.exercises.first.id, 40, 6);
    await container.read(activeSessionProvider.notifier).refresh();
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

    await tester.tap(find.byTooltip('Edit set'));
    await tester.pumpAndSettle();
    expect(find.text('Edit set 1'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await container.read(activeSessionProvider.notifier).discard();
  });
}
