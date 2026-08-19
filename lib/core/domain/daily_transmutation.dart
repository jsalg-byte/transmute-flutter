import 'models.dart';
import 'recovery.dart';

enum DailyAction {
  resumeSession,
  recordCheckin,
  recover,
  assessGoal,
  logMeal,
  openPlan,
  createPlan,
}

class DailyRecommendation {
  const DailyRecommendation({
    required this.action,
    required this.title,
    required this.explanation,
    required this.route,
    required this.evidence,
  });
  final DailyAction action;
  final String title;
  final String explanation;
  final String route;
  final List<String> evidence;
}

DailyRecommendation deriveDailyTransmutation({
  required List<WorkoutPlan> plans,
  required WorkoutSession? activeSession,
  required List<RecoveryGroup> readiness,
  required List<RecoveryCheckin> checkins,
  required NutritionRecord nutrition,
  required List<Goal> goals,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  if (activeSession != null) {
    return DailyRecommendation(
      action: DailyAction.resumeSession,
      title: 'Resume your active workout',
      explanation:
          'One workout is already in progress; preserve the existing record before starting anything else.',
      route: '/session',
      evidence: [
        '${activeSession.planName} · ${activeSession.planDayName}',
        '${activeSession.workingSetCount} working sets logged',
      ],
    );
  }
  final todayCheckin = checkins.any((item) => _sameDay(item.date, today));
  if (!todayCheckin) {
    return const DailyRecommendation(
      action: DailyAction.recordCheckin,
      title: 'Record today’s recovery',
      explanation:
          'Today has no recovery check-in, so a training prescription would be based on incomplete evidence.',
      route: '/dashboard#checkin',
      evidence: ['No recovery check-in recorded today'],
    );
  }
  ({WorkoutPlan plan, WorkoutPlanDay day})? next;
  for (final plan in plans) {
    if (plan.days.isNotEmpty) {
      next = (plan: plan, day: plan.days.first);
      break;
    }
  }
  if (next != null) {
    final targeted = next.day.exercises
        .expand(
          (exercise) => bodyGroupsForMuscleGroup(exercise.exercise.muscleGroup),
        )
        .toSet();
    final resting = readiness
        .where((group) => group.stage == RecoveryStage.needsRest)
        .map((group) => group.name)
        .toSet();
    if (targeted.isNotEmpty && targeted.every(resting.contains)) {
      return DailyRecommendation(
        action: DailyAction.recover,
        title: 'Recover before ${next.day.name}',
        explanation:
            'Every mapped body group in the next training day is still inside the under-24-hour rest window.',
        route: '/dashboard',
        evidence: targeted.map((group) => '$group needs rest').toList(),
      );
    }
  }
  final overdue = goals
      .where(
        (goal) =>
            goal.status == GoalStatus.active &&
            !goal.targetDate.isAfter(_dateOnly(today)),
      )
      .toList();
  if (overdue.isNotEmpty) {
    return DailyRecommendation(
      action: DailyAction.assessGoal,
      title: 'Assess ${overdue.first.title}',
      explanation:
          'This active goal has reached its target date without a recorded decision today.',
      route: '/goals',
      evidence: [
        'Target date: ${_date(overdue.first.targetDate)}',
        '${overdue.first.assessments.length} assessments recorded',
      ],
    );
  }
  if (!nutrition.meals.any((meal) => _sameDay(meal.consumedAt, today))) {
    return const DailyRecommendation(
      action: DailyAction.logMeal,
      title: 'Log today’s first meal',
      explanation:
          'There is no nutrition evidence for today yet. Record what you ate before drawing conclusions from the day.',
      route: '/nutrition',
      evidence: ['No meal items logged today'],
    );
  }
  if (next != null) {
    return DailyRecommendation(
      action: DailyAction.openPlan,
      title: 'Open ${next.day.name}',
      explanation:
          'Today’s recovery, nutrition, and plan record do not show a stronger constraint than the next planned day.',
      route: '/plans/${next.plan.id}',
      evidence: [
        '${next.plan.name} · ${next.day.exercises.length} exercises',
        'Recovery check-in and at least one meal recorded today',
      ],
    );
  }
  return const DailyRecommendation(
    action: DailyAction.createPlan,
    title: 'Create your first plan',
    explanation:
        'There is no active workout or plan prescription to turn into a next action.',
    route: '/plans',
    evidence: ['No plan with a training day is available'],
  );
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';
