import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';
import 'package:transmute_flutter/core/providers.dart';
import 'package:transmute_flutter/features/nutrition/presentation/recipe_screens.dart';

void main() {
  group('MockNutritionRepository Recipe Operations', () {
    late MockStore store;
    late NutritionRepository repository;

    setUp(() {
      store = MockStore();
      repository = MockNutritionRepository(store);
    });

    test('getRecipes returns seeded curated recipes', () async {
      final recipes = await repository.getRecipes();
      expect(recipes.isNotEmpty, isTrue);
      expect(recipes.length, greaterThanOrEqualTo(5));
      expect(recipes.any((r) => r.title.contains('Greek Yogurt')), isTrue);
    });

    test('getRecipes filters by title and description query', () async {
      final oatsRecipes = await repository.getRecipes(query: 'oats');
      expect(oatsRecipes.isNotEmpty, isTrue);
      for (final r in oatsRecipes) {
        final matches = r.title.toLowerCase().contains('oats') ||
            r.description.toLowerCase().contains('oats');
        expect(matches, isTrue);
      }

      final nonExistent = await repository.getRecipes(query: 'xyznonexistent123');
      expect(nonExistent, isEmpty);
    });

    test('getRecipe returns single recipe or throws not found', () async {
      final first = (await repository.getRecipes()).first;
      final fetched = await repository.getRecipe(first.id);
      expect(fetched.id, equals(first.id));
      expect(fetched.title, equals(first.title));
      expect(fetched.ingredients, isNotEmpty);
      expect(fetched.instructions, isNotEmpty);

      expect(
        () => repository.getRecipe('non-existent-uuid'),
        throwsA(isA<AppFailure>()),
      );
    });

    test('logRecipeAsMeal logs scaled portion and reproduces macros into diary', () async {
      final recipe = (await repository.getRecipes()).first;
      final portion = 2.0;
      final targetDate = DateTime(2026, 10, 5, 12, 0);

      await repository.logRecipeAsMeal(
        recipeId: recipe.id,
        portionServings: portion,
        mealType: MealType.breakfast,
        consumedAt: targetDate,
      );

      final diary = await repository.getDiaryDay('2026-10-05');
      final logged = diary.meals.where((m) => m.foodName.contains(recipe.title)).toList();
      expect(logged, isNotEmpty);
      final meal = logged.first;
      expect(meal.mealType, equals(MealType.breakfast));
      expect(meal.grams, equals(portion));
      expect(meal.caloriesKcal, closeTo(recipe.servingCaloriesKcal * portion, 1.0));
      expect(meal.proteinG, closeTo(recipe.servingProteinG * portion, 0.1));
      expect(meal.carbsG, closeTo(recipe.servingCarbsG * portion, 0.1));
      expect(meal.fatG, closeTo(recipe.servingFatG * portion, 0.1));
    });
  });

  group('Recipe Discovery UI Widgets', () {
    testWidgets('RecipeDiscoveryScreen renders grid and filters by query', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);

      final store = MockStore();
      final router = GoRouter(
        initialLocation: '/recipes',
        routes: [
          GoRoute(path: '/recipes', builder: (_, __) => const RecipeDiscoveryScreen()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockStoreProvider.overrideWithValue(store),
            repositoryModeProvider.overrideWith(() => _MockModeController()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Discover Recipes'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Alchemical Greek Yogurt Berry Bowl'), findsOneWidget);

      // Search for Oats
      await tester.enterText(find.byType(TextField), 'Oats');
      await tester.pumpAndSettle();

      expect(find.text('Golden Elixir Overnight Oats'), findsOneWidget);
      expect(find.text('Pan-Seared Atlantic Salmon & Sweet Potato Mash'), findsNothing);
    });

    testWidgets('Tapping recipe card opens RecipeDetailSheet and displays details', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);

      final store = MockStore();
      final router = GoRouter(
        initialLocation: '/recipes',
        routes: [
          GoRoute(path: '/recipes', builder: (_, __) => const RecipeDiscoveryScreen()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockStoreProvider.overrideWithValue(store),
            repositoryModeProvider.overrideWith(() => _MockModeController()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the first recipe card
      await tester.tap(find.text('Alchemical Greek Yogurt Berry Bowl'));
      await tester.pumpAndSettle();

      // Bottom sheet details displayed
      expect(find.text('Per Serving Nutrition'), findsOneWidget);
      expect(find.text('Ingredients (4)'), findsOneWidget);
    });

    testWidgets('RecipeDetailSheet allows portion adjustment and diary logging via modal sheet', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);

      final store = MockStore();
      final recipe = (await MockNutritionRepository(store).getRecipes()).first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockStoreProvider.overrideWithValue(store),
            repositoryModeProvider.overrideWith(() => _MockModeController()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => RecipeDetailSheet(recipe: recipe),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Per Serving Nutrition'), findsOneWidget);
      expect(find.text('Ingredients (4)'), findsOneWidget);

      final addIconFinder = find.byIcon(Icons.add_circle_outline);
      await tester.scrollUntilVisible(addIconFinder, 100, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();

      await tester.tap(addIconFinder);
      await tester.pumpAndSettle();
      expect(find.text('1.5 servings'), findsOneWidget);

      final logBtnFinder = find.textContaining('Log Alchemical Greek Yogurt Berry Bowl to Diary');
      await tester.scrollUntilVisible(logBtnFinder, 100, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();

      // Tap Log to Diary
      await tester.tap(logBtnFinder);
      await tester.pumpAndSettle();

      // Meal logged into store
      expect(store.meals.any((m) => m.foodName.contains('Greek Yogurt') && m.grams == 1.5), isTrue);
    });
  });
}

class _MockModeController extends RepositoryModeController {
  @override
  RepositoryMode build() => RepositoryMode.mock;
}
