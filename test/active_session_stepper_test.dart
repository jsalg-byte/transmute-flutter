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
    await tester.pumpAndSettle();
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

  testWidgets('timed plan exercise can log a duration in minutes', (
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
    final plan = await container
        .read(planRepositoryProvider)
        .getPlan('upper-a');
    final day = plan.days.first;
    final entry = day.exercises.first;
    await container
        .read(planRepositoryProvider)
        .updatePrescription(
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
    await tester.ensureVisible(find.byTooltip('Duration unit').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Duration unit').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('min').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(durationField);
    await tester.tap(durationField);
    await tester.enterText(durationField, '2');
    await tester.tap(find.text('Log').first);
    await tester.pumpAndSettle();

    final saved = await container
        .read(sessionRepositoryProvider)
        .getSession(session.id);
    expect(saved.exercises.first.sets.single.durationSeconds, 120);
    expect(find.text('2 min'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Edit set 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit set 1'));
    await tester.pumpAndSettle();
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('Weight (kg)'), findsNothing);
    await tester.enterText(find.byType(TextField).last, '1.5');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    var updated = await container
        .read(sessionRepositoryProvider)
        .getSession(session.id);
    expect(updated.exercises.first.sets.single.durationSeconds, 90);

    await tester.ensureVisible(find.byTooltip('Delete set 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete set 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete set').last);
    await tester.pumpAndSettle();
    updated = await container
        .read(sessionRepositoryProvider)
        .getSession(session.id);
    expect(updated.exercises.first.sets, isEmpty);
    await container.read(activeSessionProvider.notifier).discard();
  });

  testWidgets('rep ledger logs, edits, deletes, and completes confirmed sets', (
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
    final session = await container
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
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Warm-up').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warm-up').first);
    await tester.ensureVisible(find.text('Log').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log').first);
    await tester.pumpAndSettle();
    var saved = await container
        .read(sessionRepositoryProvider)
        .getSession(session.id);
    expect(saved.exercises.first.sets.single.isWarmup, isTrue);
    expect(saved.workingSetCount, 0);
    expect(find.text('Saved'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Edit set 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit set 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warm-up set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    saved = await container
        .read(sessionRepositoryProvider)
        .getSession(session.id);
    expect(saved.exercises.first.sets.single.isWarmup, isFalse);
    expect(saved.workingSetCount, 1);

    await tester.ensureVisible(find.byTooltip('Delete set 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete set 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete set').last);
    await tester.pumpAndSettle();
    saved = await container
        .read(sessionRepositoryProvider)
        .getSession(session.id);
    expect(saved.exercises.first.sets, isEmpty);

    final newSet = await container
        .read(sessionRepositoryProvider)
        .createSet(session.exercises.first.id, 40, 8);
    expect(newSet.set.isWarmup, isFalse);
    final completed = await container
        .read(activeSessionProvider.notifier)
        .complete();
    expect(completed.workingSetCount, 1);
    final history = await container
        .read(sessionRepositoryProvider)
        .completedHistory();
    expect(history.first.id, completed.id);
    expect(history.first.workingSetCount, 1);
  });

  testWidgets('pending set blocks Finish and remains visibly unsynced', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final session = await container
        .read(activeSessionProvider.notifier)
        .start('upper-a', 'upper-a-day-1');
    final exercise = session.exercises.first;
    container.read(mockStoreProvider).active = session.copyWith(
      exercises: [
        exercise.copyWith(
          sets: [
            LoggedSet(
              id: 'pending-operation',
              sessionExerciseId: exercise.id,
              setOrder: 1,
              weightKg: 40,
              reps: 8,
              completedAt: DateTime.now(),
              pending: true,
            ),
          ],
        ),
        ...session.exercises.skip(1),
      ],
    );
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
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending sync'), findsOneWidget);
    expect(
      find.text(
        '1 set is saved on this device and must sync before finishing.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Finish'))
          .onPressed,
      isNull,
    );
    await container.read(activeSessionProvider.notifier).discard();
  });

  testWidgets('200 percent text keeps ledger and finish control available', (
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
        .createSet(session.exercises.first.id, 40, 8);
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
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(
            size: const Size(390, 844),
            textScaler: const TextScaler.linear(2),
          ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SET LEDGER'), findsOneWidget);
    expect(find.byTooltip('Edit set 1'), findsOneWidget);
    expect(find.text('Next Movement'), findsWidgets);
    expect(tester.takeException(), isNull);
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

    await tester.ensureVisible(find.byTooltip('Edit set 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit set 1'));
    await tester.pumpAndSettle();
    expect(find.text('Edit set 1'), findsOneWidget);
    await tester.tap(find.text('Save changes'));
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
