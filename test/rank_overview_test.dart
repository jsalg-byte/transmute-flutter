import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';

void main() {
  test('mock bodygraph keeps unqualified placement honest', () async {
    final overview = await MockExerciseRankRepository(
      MockStore(),
    ).getOverview();

    expect(overview.overall.placementEligible, isFalse);
    expect(overview.overall.score, isNull);
    expect(overview.overall.eligibleExerciseCount, lessThan(10));
    expect(overview.groups, isEmpty);
  });

  test('mock exercise rank repository returns valid rank analysis data', () async {
    final analysis = await MockExerciseRankRepository(
      MockStore(),
    ).getAnalysis();

    expect(analysis.categories, isNotEmpty);
    expect(analysis.tierDistribution, isA<List<RankTierCount>>());
    expect(analysis.weeklyRankUps, isA<List<WeeklyRankUpCount>>());
    expect(analysis.upcomingTargets, isA<List<RankUpcomingTarget>>());
  });
}
