import 'models.dart';

enum RecoveryStage { needsRest, recovering, ready }

class RecoveryGroup {
  const RecoveryGroup({
    required this.name,
    required this.stage,
    this.hoursRemaining = 0,
  });
  final String name;
  final RecoveryStage stage;
  final int hoursRemaining;
}

const recoveryBodyGroups = [
  'Chest',
  'Shoulders',
  'Arms',
  'Back',
  'Core',
  'Legs',
];

List<String> bodyGroupsForMuscleGroup(String? muscleGroup) {
  final value = muscleGroup?.toLowerCase() ?? '';
  final groups = <String>[];
  void add(String name, bool match) {
    if (match && !groups.contains(name)) groups.add(name);
  }

  add('Chest', RegExp(r'chest|pectoral').hasMatch(value));
  add('Shoulders', RegExp(r'deltoid|shoulder|trapezius').hasMatch(value));
  add(
    'Arms',
    RegExp(r'biceps|triceps|brachialis|forearm|wrist').hasMatch(value),
  );
  add(
    'Back',
    RegExp(
      r'infraspinatus|teres|rhomboid|latissimus|\blat\b|back',
    ).hasMatch(value),
  );
  add('Core', RegExp(r'abdominal|rectus|oblique').hasMatch(value));
  add(
    'Legs',
    RegExp(
      r'glute|quadriceps|\bquad\b|hamstring|calf|gastrocnemius|soleus|tibialis|adductor|legs|lower body',
    ).hasMatch(value),
  );
  return groups;
}

List<RecoveryGroup> deriveRecovery(
  List<WorkoutSession> sessions, {
  DateTime? now,
}) {
  final at = (now ?? DateTime.now()).toUtc();
  final latest = <String, DateTime>{};
  for (final session in sessions.where(
    (item) =>
        item.status == SessionStatus.completed && item.completedAt != null,
  )) {
    for (final exercise in session.exercises) {
      if (!exercise.sets.any((set) => !set.isWarmup)) continue;
      for (final group in bodyGroupsForMuscleGroup(exercise.muscleGroup)) {
        final ended = session.completedAt!;
        if ((latest[group]?.isBefore(ended) ?? true)) latest[group] = ended;
      }
    }
  }
  return recoveryBodyGroups.map((name) {
    final ended = latest[name];
    if (ended == null)
      return RecoveryGroup(name: name, stage: RecoveryStage.ready);
    final hours = at.difference(ended.toUtc()).inMinutes / 60;
    if (hours < 24)
      return RecoveryGroup(
        name: name,
        stage: RecoveryStage.needsRest,
        hoursRemaining: (48 - hours).ceil(),
      );
    if (hours < 48)
      return RecoveryGroup(
        name: name,
        stage: RecoveryStage.recovering,
        hoursRemaining: (48 - hours).ceil(),
      );
    return RecoveryGroup(name: name, stage: RecoveryStage.ready);
  }).toList();
}
