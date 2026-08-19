import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/domain/daily_transmutation.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/domain/recovery.dart';

void main() {
  test('daily transmutation resumes an active session before other advice', () {
    final result = deriveDailyTransmutation(
      plans: const [],
      activeSession: WorkoutSession(
        id: 'active',
        planId: 'plan',
        planName: 'Strength',
        planDayId: 'day',
        planDayName: 'Upper',
        status: SessionStatus.active,
        startedAt: DateTime.utc(2026, 8, 11),
        updatedAt: DateTime.utc(2026, 8, 11),
        exercises: const [],
      ),
      readiness: const [],
      checkins: const [],
      nutrition: const NutritionRecord(foods: [], meals: []),
      goals: const [],
      now: DateTime.utc(2026, 8, 11),
    );
    expect(result.action, DailyAction.resumeSession);
  });

  test(
    'daily transmutation requests a check-in before a plan recommendation',
    () {
      final result = deriveDailyTransmutation(
        plans: const [],
        activeSession: null,
        readiness: const [
          RecoveryGroup(name: 'Chest', stage: RecoveryStage.ready),
        ],
        checkins: const [],
        nutrition: const NutritionRecord(foods: [], meals: []),
        goals: const [],
        now: DateTime.utc(2026, 8, 11),
      );
      expect(result.action, DailyAction.recordCheckin);
      expect(result.evidence.single, 'No recovery check-in recorded today');
    },
  );
}
