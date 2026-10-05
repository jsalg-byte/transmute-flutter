import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/providers.dart';
import 'package:transmute_flutter/features/feature_hubs/presentation/feature_hub_screens.dart';
import 'package:transmute_flutter/features/ranks/presentation/rank_overview_screens.dart';

void main() {
  testWidgets('RankAnalysisScreen renders categories and upcoming targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final mockAnalysisData = RankAnalysisData(
      categories: const [
        RankCategorySummary(
          category: 'barbell',
          rankedCount: 2,
          totalCount: 5,
          averageRatio: 1.15,
          averageTier: ExerciseRankTier.silver,
        ),
      ],
      tierDistribution: const [
        RankTierCount(tier: ExerciseRankTier.silver, count: 2),
      ],
      weeklyRankUps: const [
        WeeklyRankUpCount(weekStart: '2026-09-28', count: 1),
      ],
      upcomingTargets: const [
        RankUpcomingTarget(
          exerciseId: 'bench-press',
          exerciseName: 'Bench Press',
          category: 'barbell',
          muscleGroup: 'Chest',
          trackingMode: ExerciseTrackingMode.reps,
          metric: ExerciseRankMetric.estimatedOneRepMaxKg,
          currentValue: 80.0,
          baselineValue: 60.0,
          tier: ExerciseRankTier.silver,
          progressPoints: 45,
          nextThreshold: 90.0,
        ),
      ],
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const RankAnalysisScreen(),
        ),
        GoRoute(path: '/ranks', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/ranks/gallery', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/ranks/gallery/:id', builder: (_, _) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rankAnalysisProvider.overrideWith((ref) async => mockAnalysisData),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analysis'), findsWidgets);
    expect(find.text('Category averages'), findsOneWidget);
    expect(find.text('Barbell'), findsOneWidget);
    expect(find.text('Next rank targets'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Weekly promotions'), findsOneWidget);
    expect(find.text('Tier distribution'), findsOneWidget);
  });

  testWidgets('ProfileHubScreen renders training activity with filters', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final mockAnalytics = TrainingAnalytics(
      period: TrainingPeriod.sevenDays,
      metric: TrainingMetric.volume,
      summary: const TrainingAnalyticsSummary(
        workoutCount: 3,
        totalDurationSeconds: 7200,
        totalVolumeKg: 4500,
        totalReps: 180,
        workingSetCount: 15,
        personalRecordCount: 2,
      ),
      daily: List.generate(
        7,
        (i) => TrainingDailyBucket(
          date: '2026-10-0$i',
          sessionCount: 1,
          durationSeconds: 2400,
          volumeKg: 1500,
          reps: 60,
        ),
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const ProfileHubScreen(),
        ),
        GoRoute(path: '/history', builder: (_, _) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trainingAnalyticsProvider.overrideWith((ref, _) async => mockAnalytics),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Training activity'), findsOneWidget);
    expect(find.text('7D'), findsOneWidget);
    expect(find.text('14D'), findsOneWidget);
    expect(find.text('30D'), findsOneWidget);
    expect(find.text('Volume'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('Reps'), findsOneWidget);
    expect(find.text('TOTAL VOLUME'), findsOneWidget);
  });
}
