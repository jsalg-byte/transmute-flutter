import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/core/providers.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/features/active_session/presentation/active_session_screen.dart';

void main() {
  testWidgets('mobile set entry labels values and advances keyboard focus', (
    tester,
  ) async {
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

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(6));
    final weight = tester.widget<TextField>(fields.at(0));
    final reps = tester.widget<TextField>(fields.at(1));
    expect(double.tryParse(weight.decoration!.hintText!), isNotNull);
    expect(weight.decoration?.suffixText, anyOf('lb', 'kg'));
    expect(int.tryParse(reps.decoration!.hintText!), isNotNull);
    expect(reps.decoration?.suffixText, 'reps');
    expect(weight.textInputAction, TextInputAction.next);
    expect(reps.textInputAction, TextInputAction.done);

    await tester.ensureVisible(fields.at(0));
    await tester.tap(fields.at(0));
    await tester.enterText(fields.at(0), '95');
    expect(
      tester.widget<TextField>(fields.at(0)).decoration?.suffixText,
      anyOf('lb', 'kg'),
    );
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<TextField>(fields.at(1)).focusNode!.hasFocus, isTrue);
    FocusManager.instance.primaryFocus?.unfocus();
    await container.read(activeSessionProvider.notifier).discard();
  });

  testWidgets('timed plan exercise logs and displays duration in seconds', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWith(
          (ref) => _OnlineMockSessionRepository(ref.read(mockStoreProvider)),
        ),
      ],
    );
    addTearDown(container.dispose);
    final plan = await container.read(planRepositoryProvider).getPlan('upper-a');
    final day = plan.days.first;
    final entry = day.exercises.first;
    await container.read(planRepositoryProvider).updatePrescription(
      plan.id,
      day.id,
      entry.id,
      targetSets: 1,
      targetReps: entry.targetReps,
      trackingMode: ExerciseTrackingMode.timed,
      targetDurationSeconds: 45,
    );
    final session = await container
        .read(activeSessionProvider.notifier)
        .start(plan.id, day.id);
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

    final durationField = find.byType(TextField).first;
    expect(
      tester.widget<TextField>(durationField).decoration?.suffixText,
      'sec',
    );
    await tester.ensureVisible(durationField);
    await tester.tap(durationField);
    await tester.enterText(durationField, '55');
    await tester.tap(find.text('Log').first);
    await tester.pumpAndSettle();

    final saved = await container
        .read(sessionRepositoryProvider)
        .getSession(session.id);
    expect(saved.exercises.first.sets.single.durationSeconds, 55);
    expect(find.text('55 sec'), findsOneWidget);
    await container.read(activeSessionProvider.notifier).discard();
  });

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
      expect(find.text('Upper strength'), findsOneWidget);
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

      await tester.tap(find.byTooltip('Go to step 3'));
      await tester.pumpAndSettle();

      expect(find.text('Shoulder press'), findsOneWidget);
      expect(find.text('Chest-supported row'), findsNothing);

      await tester.tap(find.byTooltip('Go to step 1'));
      await tester.pumpAndSettle();

      expect(find.text('Barbell bench press'), findsOneWidget);
      expect(find.text('Shoulder press'), findsNothing);
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

  testWidgets('wide active workout uses the desktop content width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
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
    expect(tester.getTopRight(find.text('Log').first).dx, greaterThan(1000));
    await container.read(activeSessionProvider.notifier).discard();
  });

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

class _OnlineMockSessionRepository extends MockSessionRepository {
  _OnlineMockSessionRepository(super.store);

  @override
  Future<bool> supportsOfflineSetSync() async => false;
}
