import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/features/active_session/presentation/active_session_screen.dart';

void main() {
  testWidgets('personal records use a bright celebratory presentation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PersonalRecordCelebration(
            record: const PersonalRecord(
              exerciseName: 'Barbell bench press',
              kind: PersonalRecordKind.estimatedOneRepMax,
              currentReps: 10,
              currentWeightKg: 100,
              previousReps: 8,
              previousWeightKg: 80,
            ),
          ),
        ),
      ),
    );

    expect(find.text('ESTIMATED 1RM PR'), findsOneWidget);
    expect(find.text('Barbell bench press'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
