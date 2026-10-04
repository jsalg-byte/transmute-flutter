import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/providers.dart';
import 'package:transmute_flutter/features/active_session/presentation/active_session_screen.dart';

void main() {
  testWidgets('empty-workout entry opens the editable freeform session', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = MockStore();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ActiveSessionScreen()),
        GoRoute(
          path: '/session',
          builder: (_, _) => const ActiveSessionScreen(),
        ),
        GoRoute(path: '/plans', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/history', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/dashboard', builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mockStoreProvider.overrideWithValue(store)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Start Empty Workout'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Start Empty Workout'));
    await tester.pumpAndSettle();
    expect(find.text('Empty Workout'), findsOneWidget);
    expect(find.textContaining('FREEFORM'), findsOneWidget);
    expect(find.text('Add Movement'), findsOneWidget);
    expect(
      (await MockSessionRepository(store).activeSession())?.origin,
      WorkoutSessionOrigin.freeform,
    );
  });

  testWidgets('idle workout tab shows the next day and saved routines', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ActiveSessionScreen()),
        GoRoute(path: '/plans', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/plans/:id', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/session', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/dashboard', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/history', builder: (_, _) => const SizedBox()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Workout"), findsOneWidget);
    expect(find.text('Upper strength'), findsWidgets);
    expect(find.text('Start Workout'), findsOneWidget);
    expect(find.text('New Workout'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Start Empty Workout'), findsOneWidget);
    expect(find.text('Generate Workout'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Quick Add one exercise'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Quick Add one exercise'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Routines'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Routines'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('ACTIVE PLAN'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('ACTIVE PLAN'), findsOneWidget);
    expect(find.text('Barbell bench press'), findsOneWidget);
    expect(find.textContaining('sets'), findsWidgets);
  });

  testWidgets(
    'routine row starts the exact saved day and switches to session',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = MockStore();
      final folder = await MockPlanRepository(store).createPlan('Saved cycle');
      final day = await MockPlanRepository(
        store,
      ).addDay(folder.id, 'Test routine');
      final exercise = (await MockPlanRepository(
        store,
      ).searchExercises('row')).first;
      await MockPlanRepository(
        store,
      ).addExerciseToDay(folder.id, day.id, exercise.id);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ActiveSessionScreen()),
          GoRoute(
            path: '/session',
            builder: (_, _) => const ActiveSessionScreen(),
          ),
          GoRoute(path: '/plans', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/plans/:id', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/dashboard', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/history', builder: (_, _) => const SizedBox()),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mockStoreProvider.overrideWithValue(store)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Test routine'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final routineRow = find.ancestor(
        of: find.text('Test routine'),
        matching: find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_RoutineDayRow',
        ),
      );
      final start = find.descendant(
        of: routineRow,
        matching: find.text('Start'),
      );
      await tester.scrollUntilVisible(
        start,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(store.active?.planDayId, day.id);
      expect(router.routeInformationProvider.value.uri.path, '/session');
    },
  );
}
