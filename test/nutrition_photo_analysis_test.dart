import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';
import 'package:transmute_flutter/features/nutrition/presentation/nutrition_screen.dart';

void main() {
  group('Slice 13: Photo-assisted food candidate review', () {
    test('mock repository returns labeled simulation analysis with multiple candidates', () async {
      final repository = MockNutritionRepository(MockStore());
      final fakeBytes = Uint8List.fromList([1, 2, 3, 4]);

      final analysis = await repository.analyzeFoodPhoto(fakeBytes);
      expect(analysis.source, 'simulation');
      expect(analysis.candidates, hasLength(2));

      final first = analysis.candidates.first;
      expect(first.name, 'Grilled chicken salad');
      expect(first.caloriesKcal, 360);
      expect(first.proteinG, 38);
      expect(first.carbsG, 12);
      expect(first.fatG, 16);
      expect(first.confidence, 0.88);
      expect(first.estimatedPortionGrams, 280);

      final second = analysis.candidates.last;
      expect(second.name, 'Caesar chicken wrap');
      expect(second.caloriesKcal, 480);
      expect(second.proteinG, 32);
      expect(second.confidence, 0.65);
    });

    test('rejection of food photo exceeding 9 MB limit', () async {
      final repository = MockNutritionRepository(MockStore());
      final largeBytes = Uint8List(10 * 1024 * 1024);

      expect(
        () => repository.analyzeFoodPhoto(largeBytes),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.code,
            'code',
            'food_photo_too_large',
          ),
        ),
      );
    });

    testWidgets('FoodCandidateReviewDialog renders photo, candidates, portion scaling and returns edited values', (
      tester,
    ) async {
      const analysis = FoodPhotoAnalysis(
        source: 'simulation',
        suggestedPortionGrams: 280,
        candidates: [
          FoodCandidate(
            name: 'Grilled chicken salad',
            caloriesKcal: 360,
            proteinG: 38,
            carbsG: 12,
            fatG: 16,
            servingSizeValue: 280,
            servingSizeUnit: ServingUnit.g,
            confidence: 0.88,
            estimatedPortionGrams: 280,
          ),
          FoodCandidate(
            name: 'Caesar chicken wrap',
            caloriesKcal: 480,
            proteinG: 32,
            carbsG: 44,
            fatG: 20,
            servingSizeValue: 1,
            servingSizeUnit: ServingUnit.piece,
            confidence: 0.65,
            estimatedPortionGrams: 240,
          ),
        ],
      );

      final fakeBytes = Uint8List.fromList([137, 80, 78, 71]); // dummy png header
      FoodCandidateReviewResult? result;

      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<FoodCandidateReviewResult>(
                    context: context,
                    builder: (_) => FoodCandidateReviewDialog(
                      analysis: analysis,
                      imageBytes: fakeBytes,
                      initialMealType: MealType.lunch,
                      day: DateTime(2026, 10, 5),
                    ),
                  );
                },
                child: const Text('Open Review'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Review'));
      await tester.pumpAndSettle();

      // Verify title, source chip, and date
      expect(find.text('Review Food & Portion'), findsOneWidget);
      expect(find.text('Simulation Candidate'), findsOneWidget);
      expect(find.text('Logging for 10/5/2026'), findsOneWidget);

      // Verify candidate chips: Grilled chicken salad (88%) and Caesar chicken wrap (65%)
      expect(find.text('Grilled chicken salad (88%)'), findsOneWidget);
      expect(find.text('Caesar chicken wrap (65%)'), findsOneWidget);

      // Initial fields populated from candidate 0
      expect(find.byWidgetPredicate((w) => w is TextField && w.controller?.text == 'Grilled chicken salad'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is TextField && w.controller?.text == '280'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is TextField && w.controller?.text == '360'), findsOneWidget);

      // Switch candidate to Caesar chicken wrap
      await tester.tap(find.text('Caesar chicken wrap (65%)'));
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((w) => w is TextField && w.controller?.text == 'Caesar chicken wrap'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is TextField && w.controller?.text == '480'), findsOneWidget);

      // Switch back to Grilled chicken salad
      await tester.tap(find.text('Grilled chicken salad (88%)'));
      await tester.pumpAndSettle();

      // Change portion from 280 to 140 (half portion) -> calories should scale to 180
      final portionField = find.byWidgetPredicate((w) => w is TextField && w.controller?.text == '280');
      await tester.enterText(portionField, '140');
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((w) => w is TextField && w.controller?.text == '180'), findsOneWidget); // 360 * 140 / 280 = 180

      // Confirm as meal
      await tester.tap(find.text('Confirm as Meal'));
      await tester.pumpAndSettle();

      // Check result returned
      expect(result, isNotNull);
      expect(result!.food.name, 'Grilled chicken salad');
      expect(result!.portionGrams, 140);
      expect(result!.food.caloriesKcal, 180);
      expect(result!.food.proteinG, 19); // 38 * 0.5
      expect(result!.mealType, MealType.lunch);
    });

    testWidgets('FoodCandidateReviewDialog discard returns null without logging meal', (
      tester,
    ) async {
      const analysis = FoodPhotoAnalysis(
        source: 'simulation',
        suggestedPortionGrams: 200,
        candidates: [
          FoodCandidate(
            name: 'Apple',
            caloriesKcal: 95,
            proteinG: 0.5,
            carbsG: 25,
            fatG: 0.3,
            servingSizeValue: 1,
            servingSizeUnit: ServingUnit.piece,
          ),
        ],
      );

      final fakeBytes = Uint8List.fromList([1, 2, 3]);
      FoodCandidateReviewResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<FoodCandidateReviewResult>(
                    context: context,
                    builder: (_) => FoodCandidateReviewDialog(
                      analysis: analysis,
                      imageBytes: fakeBytes,
                      initialMealType: MealType.snack,
                      day: DateTime(2026, 10, 5),
                    ),
                  );
                },
                child: const Text('Open Review'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Review'));
      await tester.pumpAndSettle();

      // Discard
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
