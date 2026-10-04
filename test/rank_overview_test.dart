import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';

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
}
