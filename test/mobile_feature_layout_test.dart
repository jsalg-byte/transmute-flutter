import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:transmute_flutter/features/exercise_library/presentation/exercise_library_screen.dart';
import 'package:transmute_flutter/features/nutrition/presentation/nutrition_screen.dart';
import 'package:transmute_flutter/features/progress/presentation/progress_screen.dart';
import 'package:transmute_flutter/features/workout_plans/presentation/plan_screens.dart';

void main() {
  testWidgets('priority feature screens fit common phone widths', (
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
        GoRoute(path: '/session', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/history', builder: (_, _) => const SizedBox()),
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
    ];
    for (final width in [375.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 844);
      for (final (route, title) in cases) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(find.text(title), findsWidgets, reason: '$route at $width px');
        final layoutError = tester.takeException();
        expect(
          layoutError,
          isNull,
          reason:
              '$route at $width px: ${layoutError is FlutterError ? layoutError.toStringDeep() : layoutError}',
        );
      }
    }
  });
}
