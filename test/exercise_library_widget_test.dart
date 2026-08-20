import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/features/exercise_library/presentation/exercise_library_screen.dart';

void main() {
  testWidgets(
    'exercise library starts with anatomy, search, and movement accordions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
      expect(find.text('Start with the body'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Create exercise'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Select Chest muscle group'));
      await tester.pumpAndSettle();

      expect(find.text('Chest movements'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Select Back muscle group'));
      await tester.pumpAndSettle();

      expect(find.text('Selected movements'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNWidgets(2));

      await tester.tap(find.text('Barbell bench press'));
      await tester.pumpAndSettle();

      expect(
        find.text('No demonstration is available for this movement yet.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'exercise search preserves the anatomy browser and explains no matches',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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

      await tester.enterText(find.byType(TextField), 'does not exist');
      await tester.pumpAndSettle();

      expect(find.text('No matching exercises'), findsOneWidget);
      expect(find.text('Start with the body'), findsOneWidget);
    },
  );
}
