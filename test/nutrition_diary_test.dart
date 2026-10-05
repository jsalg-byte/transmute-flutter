import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';

void main() {
  group('Slice 12: Daily Nutrition Targets & Meal Diary', () {
    test('target persistence, effective date lookup and diary calculation', () async {
      final store = MockStore();
      final repository = MockNutritionRepository(store);

      // Initially no target is set
      final initialTarget = await repository.getDailyTarget(date: '2026-10-05');
      expect(initialTarget, isNull);

      final emptyDiary = await repository.getDiaryDay('2026-10-05');
      expect(emptyDiary.date, '2026-10-05');
      expect(emptyDiary.target, isNull);
      expect(emptyDiary.consumedCalories, 0);
      expect(emptyDiary.remainingCalories, isNull);
      expect(emptyDiary.meals, isEmpty);

      // Save a daily target effective 2026-10-01
      final target = await repository.saveDailyTarget(
        caloriesTarget: 2200,
        proteinGTarget: 160,
        carbsGTarget: 250,
        fatGTarget: 70,
        effectiveDate: '2026-10-01',
      );
      expect(target.caloriesTarget, 2200);
      expect(target.proteinGTarget, 160);

      // Lookup target on 2026-10-05 picks up the effective target
      final targetOnOct5 = await repository.getDailyTarget(date: '2026-10-05');
      expect(targetOnOct5, isNotNull);
      expect(targetOnOct5!.caloriesTarget, 2200);

      // Lookup target on 2026-09-30 (before effective date) returns null
      final targetBefore = await repository.getDailyTarget(date: '2026-09-30');
      expect(targetBefore, isNull);

      // Log meals on 2026-10-05
      final record = await repository.read();
      final banana = record.foods.singleWhere((f) => f.id == 'food-banana');
      final oats = record.foods.singleWhere((f) => f.id == 'food-oats');

      // Banana is 105 cal (serving 1 fruit), Oats is 375 cal / 100g -> 80g is 300 cal
      await repository.createMeal(
        MealType.breakfast,
        [MealItemInput(foodId: banana.id, grams: 1)],
        consumedAt: DateTime.parse('2026-10-05T08:00:00Z'),
      );
      await repository.createMeal(
        MealType.lunch,
        [MealItemInput(foodId: oats.id, grams: 80)],
        consumedAt: DateTime.parse('2026-10-05T12:30:00Z'),
      );
      await repository.createMeal(
        MealType.uncategorized,
        [MealItemInput(foodId: banana.id, grams: 1)],
        consumedAt: DateTime.parse('2026-10-05T16:00:00Z'),
      );

      // Verify diary day calculations
      final diary = await repository.getDiaryDay('2026-10-05');
      expect(diary.date, '2026-10-05');
      expect(diary.target?.caloriesTarget, 2200);
      expect(diary.meals.length, 3);
      // 105 + 300 + 105 = 510 cal
      expect(diary.consumedCalories, 510);
      // Remaining = 2200 - 510 = 1690
      expect(diary.remainingCalories, 1690);

      // Verify uncategorized meal type is preserved
      final uncatMeal = diary.meals.singleWhere((m) => m.mealType == MealType.uncategorized);
      expect(uncatMeal.foodId, banana.id);
    });

    test('negative remaining calories when consumption exceeds target', () async {
      final store = MockStore();
      final repository = MockNutritionRepository(store);

      await repository.saveDailyTarget(
        caloriesTarget: 500,
        effectiveDate: '2026-10-05',
      );

      final record = await repository.read();
      final oats = record.foods.singleWhere((f) => f.id == 'food-oats');

      // 200g oats = 750 cal
      await repository.createMeal(
        MealType.dinner,
        [MealItemInput(foodId: oats.id, grams: 200)],
        consumedAt: DateTime.parse('2026-10-05T19:00:00Z'),
      );

      final diary = await repository.getDiaryDay('2026-10-05');
      expect(diary.consumedCalories, 750);
      expect(diary.remainingCalories, -250);
    });
  });
}
