import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/features/arcana/presentation/arcana_screen.dart';
import 'package:transmute_flutter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:transmute_flutter/features/exercise_library/presentation/exercise_library_screen.dart';
import 'package:transmute_flutter/features/fasting/presentation/fasting_screen.dart';
import 'package:transmute_flutter/features/goals/presentation/goals_screen.dart';
import 'package:transmute_flutter/features/nutrition/presentation/nutrition_screen.dart';
import 'package:transmute_flutter/features/planning/presentation/planning_screen.dart';
import 'package:transmute_flutter/features/progress/presentation/progress_screen.dart';
import 'package:transmute_flutter/features/ranks/presentation/rank_overview_screens.dart';
import 'package:transmute_flutter/features/ranks/presentation/ranks_screens.dart';
import 'package:transmute_flutter/features/social/presentation/social_hub_screen.dart';
import 'package:transmute_flutter/features/workout_history/presentation/history_screens.dart';
import 'package:transmute_flutter/features/workout_plans/presentation/plan_screens.dart';

void main() {
  testWidgets('priority feature screens fit mobile and desktop viewports', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
        GoRoute(path: '/plans', builder: (_, _) => const PlanListScreen()),
        GoRoute(
          path: '/exercises',
          builder: (_, _) => const ExerciseLibraryScreen(),
        ),
        GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
        GoRoute(path: '/nutrition', builder: (_, _) => const NutritionScreen()),
        GoRoute(path: '/fasting', builder: (_, _) => const FastingScreen()),
        GoRoute(path: '/friends', builder: (_, _) => const SocialHubScreen()),
        GoRoute(path: '/arcana', builder: (_, _) => const ArcanaScreen()),
        GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
        GoRoute(path: '/planning', builder: (_, _) => const PlanningScreen()),
        GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
        GoRoute(path: '/ranks', builder: (_, _) => const OverallRanksScreen()),
        GoRoute(
          path: '/ranks/gallery',
          builder: (_, _) => const RanksScreen(),
        ),
        GoRoute(
          path: '/ranks/bodygraph',
          builder: (_, _) => const RankBodygraphScreen(),
        ),
        GoRoute(path: '/session', builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(375, 844);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    const cases = [
      ('/dashboard', "Today's Workout"),
      ('/plans', 'Routine folders'),
      ('/exercises', 'Exercise library'),
      ('/progress', 'Progress'),
      ('/nutrition', 'Nutrition'),
      ('/fasting', 'Fasting'),
      ('/friends', 'Friends & Social'),
      ('/arcana', 'Personal Arcana'),
      ('/goals', 'Goals'),
      ('/planning', 'Planning'),
      ('/history', 'Workout history'),
      ('/ranks', 'Your Rank'),
      ('/ranks/gallery', 'Search exercise ranks'),
      ('/ranks/bodygraph', 'Bodygraph'),
    ];

    // Mobile viewports (375 iPhone SE, 390 iPhone 14/15, 430 Pro Max) + Tablet (768) + Desktop (1200)
    for (final (width, height) in [
      (375.0, 844.0),
      (390.0, 844.0),
      (430.0, 932.0),
      (768.0, 1024.0),
      (1200.0, 900.0),
    ]) {
      tester.view.physicalSize = Size(width, height);
      for (final (route, title) in cases) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(find.text(title), findsWidgets, reason: '$route at $width x $height px');
        final layoutError = tester.takeException();
        expect(
          layoutError,
          isNull,
          reason:
              '$route at $width x $height px: ${layoutError is FlutterError ? layoutError.toStringDeep() : layoutError}',
        );
      }
    }
  });
}
