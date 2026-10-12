import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/core/data/opengym_catalog.dart';
import 'package:transmute_flutter/features/exercise_library/presentation/exercise_library_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await OpenGymCatalog.loadAll();
  });
  testWidgets('new barbell arm exercises are targetable with the Arms filter', (
    tester,
  ) async {
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

    await tester.tap(find.text('Arms'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Arms movements'), findsOneWidget);
    expect(find.text('Barbell Wrist Curl'), findsOneWidget);
    expect(find.text('Barbell Reverse Curl'), findsOneWidget);
  });

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

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(ExpansionTile), findsWidgets);
      expect(find.text('Barbell bench press'), findsOneWidget);

      await tester.tap(find.text('Barbell bench press'));
      await tester.pumpAndSettle();

      expect(find.text('DEMONSTRATION'), findsOneWidget);
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

  testWidgets(
    'can view catalog taxonomy filters and movement cues with tabular numerals',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ExerciseLibraryScreen()),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Catalog'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Taxonomy Filters'), findsOneWidget);
      expect(find.text('BODY REGION'), findsOneWidget);
      expect(find.text('EQUIPMENT'), findsOneWidget);
    },
  );
}
