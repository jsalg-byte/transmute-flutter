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
}
