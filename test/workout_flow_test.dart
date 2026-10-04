import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';

void main() {
  test(
    'freeform workout restores, logs two exercises, and enters history',
    () async {
      final store = MockStore();
      final sessions = MockSessionRepository(store);
      final initialHistoryCount = (await sessions.completedHistory()).length;
      final started = await sessions.startFreeformSession();
      expect(started.origin, WorkoutSessionOrigin.freeform);
      expect(started.planDayId, isNull);
      expect(started.exercises, isEmpty);

      final bench = await sessions.addExercise(started.id, 'bench');
      final row = await sessions.addExercise(started.id, 'row');
      await sessions.createSet(bench.id, 50, 8);
      await sessions.createSet(row.id, 40, 10);

      final restored = (await MockSessionRepository(store).activeSession())!;
      expect(restored.id, started.id);
      expect(restored.exercises.map((exercise) => exercise.exerciseId), [
        'bench',
        'row',
      ]);
      expect(restored.workingSetCount, 2);
      await expectLater(
        MockSessionRepository(store).startSession('upper-a'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.code,
            'code',
            'active_session_exists',
          ),
        ),
      );

      await sessions.complete(started.id);
      expect(await sessions.activeSession(), isNull);
      expect(
        (await sessions.completedHistory()).first.planName,
        'Empty Workout',
      );
      final next = await sessions.startFreeformSession();
      final repeated = await sessions.addExercise(next.id, 'bench');
      expect(repeated.previousPerformance?.reps, 8);
      await sessions.discard(next.id);
      expect(
        (await sessions.completedHistory()),
        hasLength(initialHistoryCount + 1),
      );
      expect(await sessions.activeSession(), isNull);
    },
  );

  test('planned and freeform starts share the one-active constraint', () async {
    final sessions = MockSessionRepository(MockStore());
    final planned = await sessions.startSession('upper-a');
    await expectLater(
      sessions.startFreeformSession(),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.activeSessionId,
          'activeSessionId',
          planned.id,
        ),
      ),
    );
  });

  test('timed duration units convert to the API seconds contract', () {
    expect(TimedDurationUnit.minutes.toSeconds(1.5), 90);
    expect(TimedDurationUnit.hours.toSeconds(2), 7200);
    expect(TimedDurationUnit.forSeconds(3600), TimedDurationUnit.hours);
    final minuteValue = TimedDurationUnit.minutes.fromSeconds(90);
    expect(TimedDurationUnit.minutes.formatValue(minuteValue), '1.5');
    expect(TimedDurationUnit.minutes.toSeconds(minuteValue), 90);
  });

  test('mock mode completes a workout into immutable history', () async {
    final store = MockStore();
    final sessions = MockSessionRepository(store);
    final session = await sessions.startSession('upper-a');
    await sessions.createSet(session.exercises.first.id, 61.235, 8);
    final completed = await sessions.complete(session.id);
    final history = await sessions.completedHistory();

    expect(completed.workingSetCount, 1);
    expect(await sessions.activeSession(), isNull);
    expect(history.first.id, completed.id);
    expect(history.first.planDayName, completed.planDayName);
    expect(history.first.totalVolumeKg, closeTo(489.88, 0.01));
    expect(
      displayWeight(history.first.totalVolumeKg, WeightUnit.lb),
      '1080 lb',
    );
    final plan = await MockPlanRepository(store).getPlan('upper-a');
    expect(plan.exercises.first.previousPerformance!.sessionId, completed.id);
  });

  test('starting a saved day restores the same active session', () async {
    final store = MockStore();
    final firstRepository = MockSessionRepository(store);
    final plan = await MockPlanRepository(store).getPlan('upper-a');
    final day = plan.days.first;

    final started = await firstRepository.startSession(plan.id, day.id);
    final restored = await MockSessionRepository(store).activeSession();

    expect(restored?.id, started.id);
    expect(restored?.planDayId, day.id);
    await expectLater(
      MockSessionRepository(store).startSession(plan.id, day.id),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          'active_session_exists',
        ),
      ),
    );
    expect((await firstRepository.activeSession())?.id, started.id);
  });

  test('rest deadline survives session repository recreation', () async {
    final store = MockStore();
    final firstRepository = MockSessionRepository(store);
    final session = await firstRepository.startSession('upper-a');
    final deadline = DateTime.now().add(const Duration(seconds: 90));
    await firstRepository.updateRest(session.id, deadline);

    final restored = await MockSessionRepository(store).activeSession();
    expect(restored?.restEndsAt, deadline);
  });

  test('mock working set reports a verified personal record', () async {
    final store = MockStore();
    final session = await MockSessionRepository(store).startSession('upper-a');

    final result = await MockSessionRepository(
      store,
    ).createSet(session.exercises.first.id, 70, 8);

    expect(result.personalRecord?.exerciseName, 'Barbell bench press');
    expect(result.personalRecord?.kind.name, 'estimatedOneRepMax');
  });

  test(
    'timed prescriptions carry their target into session set records',
    () async {
      final store = MockStore();
      final plans = MockPlanRepository(store);
      final plan = await plans.getPlan('upper-a');
      final day = plan.days.first;
      final entry = day.exercises.first;
      await plans.updatePrescription(
        plan.id,
        day.id,
        entry.id,
        targetSets: 2,
        targetReps: entry.targetReps,
        trackingMode: ExerciseTrackingMode.timed,
        targetDurationSeconds: 45,
      );
      final session = await MockSessionRepository(
        store,
      ).startSession(plan.id, day.id);
      final exercise = session.exercises.first;
      expect(exercise.trackingMode, ExerciseTrackingMode.timed);
      expect(exercise.targetDurationSeconds, 45);

      final result = await MockSessionRepository(
        store,
      ).createSet(exercise.id, 0, 1, durationSeconds: 55);
      expect(result.set.durationSeconds, 55);
      expect(result.personalRecord, isNull);
    },
  );

  test('timed previous results use the exact exercise and mode', () async {
    final store = MockStore();
    final plans = MockPlanRepository(store);
    final plan = await plans.getPlan('upper-a');
    final day = plan.days.first;
    final entry = day.exercises.first;
    await plans.updatePrescription(
      plan.id,
      day.id,
      entry.id,
      targetSets: 1,
      targetReps: entry.targetReps,
      trackingMode: ExerciseTrackingMode.timed,
      targetDurationSeconds: 45,
    );
    final sessions = MockSessionRepository(store);
    final first = await sessions.startSession(plan.id, day.id);
    await sessions.createSet(
      first.exercises.first.id,
      0,
      1,
      durationSeconds: 55,
    );
    await sessions.complete(first.id);

    final next = await sessions.startSession(plan.id, day.id);
    expect(next.exercises.first.previousPerformance?.durationSeconds, 55);
    expect(next.exercises.first.previousPerformance?.sessionId, first.id);
    await sessions.discard(next.id);

    await plans.updatePrescription(
      plan.id,
      day.id,
      entry.id,
      targetSets: 1,
      targetReps: 8,
      trackingMode: ExerciseTrackingMode.reps,
      targetWeightKg: 40,
    );
    final repsSession = await sessions.startSession(plan.id, day.id);
    expect(
      repsSession.exercises.first.previousPerformances.where(
        (result) => result.durationSeconds != null,
      ),
      isEmpty,
    );
  });

  test('mock plan builder creates a day and uses its prescriptions', () async {
    final store = MockStore();
    final plans = MockPlanRepository(store);
    final created = await plans.createPlan('Four-day split');
    final day = await plans.addDay(created.id, 'Pull');
    final exercise = (await plans.searchExercises('row')).single;
    final entry = await plans.addExerciseToDay(created.id, day.id, exercise.id);
    await plans.updatePrescription(
      created.id,
      day.id,
      entry.id,
      targetSets: 4,
      targetReps: 8,
      targetWeightKg: 50,
    );

    final plan = await plans.getPlan(created.id);
    expect(plan.days.single.name, 'Pull');
    expect(plan.days.single.exercises.single.targetSets, 4);
    final session = await MockSessionRepository(
      store,
    ).startSession(created.id, day.id);
    expect(session.planDayName, 'Pull');
    expect(session.exercises.single.targetWeightKg, 50);
  });

  test(
    'routine folder, order, preview and exact direct start persist',
    () async {
      final store = MockStore();
      final plans = MockPlanRepository(store);
      final folder = await plans.createPlan('Strength cycle');
      expect(folder.days, isEmpty);
      final push = await plans.addDay(folder.id, 'Push');
      final pull = await plans.addDay(folder.id, 'Pull');
      final bench = (await plans.searchExercises('bench')).first;
      final row = (await plans.searchExercises('row')).first;
      final benchEntry = await plans.addExerciseToDay(
        folder.id,
        push.id,
        bench.id,
      );
      final rowEntry = await plans.addExerciseToDay(folder.id, push.id, row.id);
      await plans.updatePrescription(
        folder.id,
        push.id,
        benchEntry.id,
        targetSets: 4,
        targetReps: 8,
      );
      await plans.updatePrescription(
        folder.id,
        push.id,
        rowEntry.id,
        targetSets: 2,
        targetReps: 10,
      );
      await plans.reorderExerciseInDay(
        folder.id,
        push.id,
        rowEntry.id,
        ReorderDirection.up,
      );
      await plans.reorderDay(folder.id, pull.id, ReorderDirection.up);

      final reloaded = await MockPlanRepository(store).getPlan(folder.id);
      expect(reloaded.days.map((day) => day.id), [pull.id, push.id]);
      expect(reloaded.days.last.exercises.map((entry) => entry.id), [
        rowEntry.id,
        benchEntry.id,
      ]);
      expect(
        reloaded.days.last.exercises.fold<int>(
          0,
          (sum, entry) => sum + entry.targetSets,
        ),
        6,
      );

      final session = await MockSessionRepository(
        store,
      ).startSession(folder.id, push.id);
      expect(session.planDayId, push.id);
      expect(session.exercises.map((exercise) => exercise.exerciseId), [
        row.id,
        bench.id,
      ]);
      await expectLater(
        plans.deleteDay(folder.id, push.id),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.code,
            'code',
            'day_active',
          ),
        ),
      );
      await MockSessionRepository(store).discard(session.id);
      await plans.deleteDay(folder.id, push.id);
      await plans.deleteDay(folder.id, pull.id);
      expect(
        (await MockPlanRepository(store).getPlan(folder.id)).days,
        isEmpty,
      );
    },
  );

  test('mock exercise demo update persists into plan detail', () async {
    final store = MockStore();
    final plans = MockPlanRepository(store);

    await plans.updateExerciseDemo(
      'bench',
      demoUrl: 'https://media.example.test/bench.gif',
      sourceName: 'Verified exercise source',
    );

    final plan = await plans.getPlan('upper-a');
    expect(
      plan.days.single.exercises.first.exercise.demoUrl,
      'https://media.example.test/bench.gif',
    );
    expect(
      plan.days.single.exercises.first.exercise.demoSourceName,
      'Verified exercise source',
    );
  });

  test('mock catalog import preserves a plan prescription', () async {
    final store = MockStore();
    final plans = MockPlanRepository(store);

    final entry = await plans.importCalistreeExerciseToDay(
      'upper-a',
      'upper-a-day-1',
      'pull-up',
      targetSets: 4,
      targetReps: 6,
    );

    expect(entry.exercise.name, 'Pull-up');
    expect(entry.exercise.muscleGroup, 'Back');
    expect(entry.targetSets, 4);
    expect(entry.targetReps, 6);
  });

  test('mock catalog import adds an exercise to an active session', () async {
    final store = MockStore();
    final sessions = MockSessionRepository(store);
    final session = await sessions.startSession('upper-a');

    final entry = await sessions.importCalistreeExercise(session.id, 'pull-up');

    expect(entry.name, 'Pull-up');
    expect((await sessions.activeSession())!.exercises, contains(entry));
  });

  test(
    'mock active session retains the exercise demonstration metadata',
    () async {
      final store = MockStore();
      final plans = MockPlanRepository(store);
      await plans.updateExerciseDemo(
        'bench',
        demoUrl: 'https://media.example.test/bench.mp4',
        sourceName: 'Exercise catalog',
      );

      final session = await MockSessionRepository(
        store,
      ).startSession('upper-a');

      expect(
        session.exercises.first.demoUrl,
        'https://media.example.test/bench.mp4',
      );
      expect(session.exercises.first.demoSourceName, 'Exercise catalog');
    },
  );

  test(
    'mock assistant draft is reviewed then imported as an editable plan',
    () async {
      final plans = MockPlanRepository(MockStore());

      final draft = await plans.generateAiWorkoutDraft(
        'Three strength days with a bench and no knee aggravation.',
      );
      final imported = await plans.importAiWorkoutPlan(draft);

      expect(draft.days, hasLength(2));
      expect(imported.days, hasLength(2));
      expect(
        imported.days.first.exercises.first.exercise.name,
        'Barbell bench press',
      );
    },
  );

  test(
    'mock assistant import validates before creating a partial plan',
    () async {
      final plans = MockPlanRepository(MockStore());
      const unresolved = AiWorkoutPlanDraft(
        name: 'Invalid draft',
        days: [
          AiWorkoutDay(
            name: 'Day 1',
            exercises: [
              AiWorkoutExercise(
                exerciseName: 'Unresolvable movement',
                targetSets: 3,
              ),
            ],
          ),
        ],
      );

      expect(
        () => plans.importAiWorkoutPlan(unresolved),
        throwsA(isA<AppFailure>()),
      );
      expect(
        (await plans.listPlans()).map((plan) => plan.name),
        isNot(contains('Invalid draft')),
      );
    },
  );
}
