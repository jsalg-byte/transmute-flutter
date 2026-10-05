import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';

void main() {
  group('Training Calendar and Streaks', () {
    test('MockStreakRepository computes calendar month, week, and streak rules', () async {
      final store = MockStore();
      final streakRepo = MockStreakRepository(store);
      final sessions = MockSessionRepository(store);

      // Initially, mock store has 1 completed session (4 days ago) with 3 working sets (2 bench + 1 row)
      final initialData = await streakRepo.getStreaks();
      expect(initialData.weekDays, hasLength(7));
      expect(initialData.calendarMonth.days.isNotEmpty, isTrue);

      // Start a workout today, log 3 working sets, and complete it
      final workout = await sessions.startFreeformSession();
      final bench = await sessions.addExercise(workout.id, 'bench');
      await sessions.createSet(bench.id, 60, 10);
      await sessions.createSet(bench.id, 60, 10);
      await sessions.createSet(bench.id, 60, 10);

      await sessions.complete(workout.id);

      final updatedData = await streakRepo.getStreaks();
      // Current streak should now be active (1 day today)
      expect(updatedData.currentStreak, greaterThanOrEqualTo(1));

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayStatus = updatedData.calendarMonth.days.firstWhere(
        (day) => day.date == todayStr,
      );
      expect(todayStatus.type, CalendarDayType.qualified);
      expect(todayStatus.workingSetCount, 3);
    });

    test('Calendar identifies completed days with < 3 working sets', () async {
      final store = MockStore();
      final streakRepo = MockStreakRepository(store);
      final sessions = MockSessionRepository(store);

      // Workout with only 2 working sets
      final workout = await sessions.startFreeformSession();
      final bench = await sessions.addExercise(workout.id, 'bench');
      await sessions.createSet(bench.id, 60, 10);
      await sessions.createSet(bench.id, 60, 10);
      await sessions.complete(workout.id);

      final data = await streakRepo.getStreaks();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayStatus = data.calendarMonth.days.firstWhere(
        (day) => day.date == todayStr,
      );
      expect(todayStatus.type, CalendarDayType.completed);
      expect(todayStatus.workingSetCount, 2);
    });
  });
}
