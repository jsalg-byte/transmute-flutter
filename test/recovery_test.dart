import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/domain/recovery.dart';

void main() {
  test(
    'readiness uses completed non-warm-up muscle work and exact 24/48 thresholds',
    () {
      final now = DateTime.utc(2026, 8, 11, 12);
      final session = WorkoutSession(
        id: 'done',
        planId: 'plan',
        planName: 'Plan',
        planDayId: 'day',
        planDayName: 'Day',
        status: SessionStatus.completed,
        startedAt: now.subtract(const Duration(hours: 25)),
        completedAt: now.subtract(const Duration(hours: 25)),
        updatedAt: now.subtract(const Duration(hours: 25)),
        exercises: [
          SessionExercise(
            id: 'chest',
            exerciseId: 'chest',
            name: 'Bench',
            muscleGroup: 'Chest',
            sortOrder: 0,
            targetSets: 3,
            targetReps: 8,
            sets: [
              LoggedSet(
                id: 'working',
                sessionExerciseId: 'chest',
                setOrder: 1,
                weightKg: 60,
                reps: 8,
                completedAt: now,
              ),
            ],
          ),
          SessionExercise(
            id: 'legs',
            exerciseId: 'legs',
            name: 'Squat',
            muscleGroup: 'Quads',
            sortOrder: 1,
            targetSets: 3,
            targetReps: 8,
            sets: [
              LoggedSet(
                id: 'warmup',
                sessionExerciseId: 'legs',
                setOrder: 2,
                weightKg: 20,
                reps: 8,
                completedAt: now,
                isWarmup: true,
              ),
            ],
          ),
        ],
      );
      final readiness = {
        for (final group in deriveRecovery([session], now: now))
          group.name: group,
      };
      expect(readiness['Chest']!.stage, RecoveryStage.recovering);
      expect(readiness['Legs']!.stage, RecoveryStage.ready);
    },
  );
}
