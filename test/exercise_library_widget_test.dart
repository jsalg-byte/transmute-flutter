import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/features/exercise_library/presentation/exercise_library_screen.dart';

void main() {
  testWidgets('exercise library renders the source workflow entry points', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ExerciseLibraryScreen()),
        GoRoute(path: '/dashboard', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/plans', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/session', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/history', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/nutrition', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/fasting', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/progress', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/goals', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/planning', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/arcana', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/friends', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/settings', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/exercises', builder: (_, _) => const SizedBox()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exercise library'), findsWidgets);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Barbell bench press'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
