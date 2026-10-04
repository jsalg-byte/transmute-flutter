import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';

void main() {
  test('rank preview is unsaved and uses the documented threshold', () async {
    final repository = MockExerciseRankRepository(MockStore());
    final before = await repository.listRanks(query: 'bench');
    final preview = repository.preview(
      exercise: before.single.exercise,
      mode: ExerciseTrackingMode.reps,
      value: 115,
      baselineValue: 100,
    );
    final after = await repository.listRanks(query: 'bench');

    expect(preview.tier, ExerciseRankTier.gold);
    expect(preview.progressPoints, 0);
    expect(after.single.bestValue, before.single.bestValue);
  });

  test('gallery search preserves the canonical exercise identifier', () async {
    final ranks = await MockExerciseRankRepository(
      MockStore(),
    ).listRanks(query: 'bench');
    expect(ranks.single.exercise.id, 'bench');
  });
}
