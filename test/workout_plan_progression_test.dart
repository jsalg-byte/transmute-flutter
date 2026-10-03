import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/domain/daily_transmutation.dart';
import 'package:transmute_flutter/core/domain/models.dart';

void main() {
  final plan = WorkoutPlan(
    id: 'plan-a',
    name: 'Strength',
    updatedAt: DateTime.utc(2026, 10, 1),
    days: [
      WorkoutPlanDay(id: 'day-b', name: 'Pull', sortOrder: 2, exercises: []),
      WorkoutPlanDay(id: 'day-a', name: 'Push', sortOrder: 1, exercises: []),
      WorkoutPlanDay(id: 'day-c', name: 'Legs', sortOrder: 3, exercises: []),
    ],
  );

  test('requires the selected plan and starts at its first scheduled day', () {
    expect(
      nextPlannedWorkout(plans: [plan], activePlanId: null, history: const []),
      isNull,
    );
    expect(
      nextPlannedWorkout(
        plans: [plan],
        activePlanId: 'plan-a',
        history: const [],
      )?.day.id,
      'day-a',
    );
  });

  test('advances after latest completed day in that exact plan and wraps', () {
    final history = [
      _summary(
        id: 'other-plan-session',
        planId: 'plan-b',
        planDayId: 'day-c',
        completedAt: DateTime.utc(2026, 10, 3),
      ),
      _summary(
        id: 'older-plan-session',
        planId: 'plan-a',
        planDayId: 'day-a',
        completedAt: DateTime.utc(2026, 10, 1),
      ),
      _summary(
        id: 'latest-plan-session',
        planId: 'plan-a',
        planDayId: 'day-b',
        completedAt: DateTime.utc(2026, 10, 2),
      ),
    ];

    expect(
      nextPlannedWorkout(
        plans: [plan],
        activePlanId: 'plan-a',
        history: history,
      )?.day.id,
      'day-c',
    );
    expect(
      nextPlannedWorkout(
        plans: [plan],
        activePlanId: 'plan-a',
        history: [
          _summary(
            id: 'last-day',
            planId: 'plan-a',
            planDayId: 'day-c',
            completedAt: DateTime.utc(2026, 10, 4),
          ),
        ],
      )?.day.id,
      'day-a',
    );
  });
}

CompletedSessionSummary _summary({
  required String id,
  required String planId,
  required String planDayId,
  required DateTime completedAt,
}) => CompletedSessionSummary(
  id: id,
  planId: planId,
  planDayId: planDayId,
  planName: 'Plan',
  planDayName: 'Day',
  startedAt: completedAt.subtract(const Duration(hours: 1)),
  completedAt: completedAt,
  durationSeconds: 3600,
  workingSetCount: 12,
  totalVolumeKg: 100,
);
