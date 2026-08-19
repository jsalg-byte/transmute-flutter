import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';

void main() {
  test(
    'mock nutrition uses each food reference serving when logging a meal',
    () async {
      final repository = MockNutritionRepository(MockStore());
      final record = await repository.read();
      final banana = record.foods.singleWhere(
        (food) => food.id == 'food-banana',
      );
      final oats = record.foods.singleWhere((food) => food.id == 'food-oats');

      await repository.createMeal(MealType.breakfast, [
        MealItemInput(foodId: banana.id, grams: 1),
        MealItemInput(foodId: oats.id, grams: 80),
      ], consumedAt: DateTime.utc(2026, 8, 11, 8));

      final meals = (await repository.read()).meals;
      expect(meals, hasLength(2));
      expect(
        meals.singleWhere((meal) => meal.foodId == banana.id).caloriesKcal,
        105,
      );
      expect(
        meals.singleWhere((meal) => meal.foodId == oats.id).caloriesKcal,
        300,
      );

      final oatMeal = meals.singleWhere((meal) => meal.foodId == oats.id);
      await repository.updateMeal(
        oatMeal.id,
        type: MealType.snack,
        grams: 40,
        consumedAt: DateTime.utc(2026, 8, 11, 13),
      );
      expect(
        (await repository.read()).meals
            .singleWhere((meal) => meal.id == oatMeal.id)
            .caloriesKcal,
        150,
      );
    },
  );

  test('mock nutrition handles saved barcode foods and meal photos', () async {
    final repository = MockNutritionRepository(MockStore());
    final created = await repository.createFood(
      const Food(
        id: 'draft',
        name: 'Protein shake',
        barcodeUpc: '12345678',
        caloriesKcal: 160,
        proteinG: 30,
        carbsG: 5,
        fatG: 2,
        servingSizeValue: 1,
        servingSizeUnit: ServingUnit.bottle,
      ),
    );
    final lookup = await repository.lookupBarcode('12345678');
    expect(lookup.found, isTrue);
    expect(lookup.food!.id, created.id);

    await repository.createMeal(MealType.snack, [
      MealItemInput(foodId: created.id, grams: 1),
    ]);
    final meal = (await repository.read()).meals.single;
    await repository.uploadMealPhoto(
      meal.id,
      ProgressPhotoUpload(
        fileName: 'shake.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([1, 2, 3]),
        capturedAt: DateTime.now(),
      ),
    );
    expect((await repository.read()).meals.single.localImageBytes, isNotNull);
    expect((await repository.lookupBarcode('00000000')).found, isFalse);
  });
}
