import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';

void main() {
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
    expect(history.first.totalVolumeKg, closeTo(489.88, 0.01));
    expect(
      displayWeight(history.first.totalVolumeKg, WeightUnit.lb),
      '1080 lb',
    );
    final plan = await MockPlanRepository(store).getPlan('upper-a');
    expect(plan.exercises.first.previousPerformance!.sessionId, completed.id);
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
