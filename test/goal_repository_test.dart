import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';

void main() {
  test('mock goals retain assessment evidence and status', () async {
    final repository = MockGoalRepository(MockStore());
    final goal = await repository.createGoal(
      Goal(
        id: 'draft',
        title: 'Bench press',
        category: GoalCategory.strength,
        baseline: 60,
        target: 80,
        unit: 'kg',
        targetDate: DateTime.utc(2026, 9, 1),
        status: GoalStatus.active,
      ),
    );
    await repository.assess(
      goal.id,
      67.5,
      'Added a clean rep.',
      decision: 'Keep progressing.',
    );
    await repository.updateStatus(goal.id, GoalStatus.completed);

    final saved = (await repository.listGoals()).single;
    expect(saved.status, GoalStatus.completed);
    expect(saved.assessments.single.value, 67.5);
    expect(saved.assessments.single.decision, 'Keep progressing.');
  });

  test('mock bodyweight repository saves, lists, and deletes measurements', () async {
    final store = MockStore();
    final repository = MockBodyweightRepository(store);

    final m1 = await repository.logMeasurement(
      measuredAt: '2026-10-01',
      weightKg: 82.5,
      notes: 'Morning weigh-in',
    );
    expect(m1.weightKg, 82.5);
    expect(m1.measuredAt, '2026-10-01');

    final m2 = await repository.logMeasurement(
      measuredAt: '2026-10-02',
      weightKg: 82.1,
    );
    expect(m2.weightKg, 82.1);

    final list = await repository.listMeasurements();
    expect(list.length, 2);
    expect(list.first.measuredAt, '2026-10-02'); // Sorted desc

    await repository.deleteMeasurement(m1.id);
    final afterDelete = await repository.listMeasurements();
    expect(afterDelete.length, 1);
    expect(afterDelete.first.id, m2.id);
  });

  test('strength goal calculates progressRatio and daysRemaining correctly', () {
    final goal = Goal(
      id: 'g-bench',
      title: 'Bench 100kg',
      category: GoalCategory.strength,
      baseline: 80,
      target: 100,
      unit: 'kg',
      targetDate: DateTime.now().add(const Duration(days: 45)),
      status: GoalStatus.active,
      exerciseId: 'ex-bench',
      exerciseName: 'Bench Press',
      assessments: [
        GoalAssessment(
          id: 'a-1',
          assessedAt: DateTime.now(),
          value: 90,
          reason: 'Felt strong',
        ),
      ],
    );

    expect(goal.current, 90.0);
    expect(goal.progressRatio, 0.5); // (90 - 80) / (100 - 80) = 0.5
    expect(goal.daysRemaining, inInclusiveRange(44, 46));
  });
}

