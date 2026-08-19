import 'dart:typed_data';

enum WeightUnit { kg, lb }

enum ThemePalette {
  transmute,
  flameAlchemist,
  hawkeye,
  automailMechanic,
  avarice,
  scarredMan,
  armorBoundSoul,
}

enum PreferenceBrightness { light, dark }

class ThemePreference {
  const ThemePreference({required this.palette, required this.brightness});
  final ThemePalette palette;
  final PreferenceBrightness brightness;
}

class UserPreferences {
  const UserPreferences({
    required this.weightUnit,
    required this.activePlanId,
    this.theme,
  });
  final WeightUnit weightUnit;
  final String? activePlanId;
  final ThemePreference? theme;
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.status,
    required this.userId,
    required this.username,
    this.name,
  });
  final String id;
  final String status;
  final String userId;
  final String username;
  final String? name;
}

class FriendActivity {
  const FriendActivity({
    required this.id,
    required this.userId,
    required this.username,
    required this.startedAt,
    required this.status,
    required this.setCount,
    this.name,
    this.routineName,
    this.dayName,
  });
  final String id;
  final String userId;
  final String username;
  final String? name;
  final DateTime startedAt;
  final String status;
  final String? routineName;
  final String? dayName;
  final int setCount;
}

class FriendsRecord {
  const FriendsRecord({
    required this.incoming,
    required this.outgoing,
    required this.activity,
  });
  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;
  final List<FriendActivity> activity;
}

class SharedWorkoutSet {
  const SharedWorkoutSet({
    required this.id,
    required this.exerciseName,
    required this.order,
    required this.reps,
    required this.isWarmup,
    this.weight,
  });
  final String id;
  final String exerciseName;
  final int order;
  final int reps;
  final double? weight;
  final bool isWarmup;
}

class SharedWorkoutSession {
  const SharedWorkoutSession({
    required this.ownerId,
    required this.ownerUsername,
    required this.sessionId,
    required this.status,
    required this.startedAt,
    required this.weightUnit,
    required this.sets,
    this.ownerName,
    this.endedAt,
    this.routineName,
    this.dayName,
  });
  final String ownerId;
  final String ownerUsername;
  final String? ownerName;
  final String sessionId;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? routineName;
  final String? dayName;
  final WeightUnit weightUnit;
  final List<SharedWorkoutSet> sets;
}

enum SessionStatus { active, completed, discarded }

enum GoalCategory { strength, nutrition, recovery, body, habit, other }

enum GoalStatus { active, completed, archived }

class GoalAssessment {
  const GoalAssessment({
    required this.id,
    required this.assessedAt,
    required this.value,
    required this.reason,
    this.decision,
  });
  final String id;
  final DateTime assessedAt;
  final double value;
  final String reason;
  final String? decision;
}

class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.category,
    required this.baseline,
    required this.target,
    required this.unit,
    required this.targetDate,
    required this.status,
    this.assessments = const [],
  });
  final String id;
  final String title;
  final GoalCategory category;
  final double baseline;
  final double target;
  final String unit;
  final DateTime targetDate;
  final GoalStatus status;
  final List<GoalAssessment> assessments;
}

enum TrainingBlockStatus { draft, active, completed, archived }

enum ScheduledBlockSessionStatus {
  planned,
  rescheduled,
  completed,
  skipped,
  recovery,
}

class ScheduledBlockSession {
  const ScheduledBlockSession({
    required this.id,
    required this.scheduledFor,
    required this.status,
    this.isDeload = false,
    this.isRecoverySession = false,
    this.note,
  });

  final String id;
  final DateTime scheduledFor;
  final ScheduledBlockSessionStatus status;
  final bool isDeload;
  final bool isRecoverySession;
  final String? note;
}

class TrainingBlock {
  const TrainingBlock({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.targetSessionsPerWeek,
    required this.status,
    this.note,
    this.sessions = const [],
  });
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int targetSessionsPerWeek;
  final TrainingBlockStatus status;
  final String? note;
  final List<ScheduledBlockSession> sessions;
}

class WeeklyReview {
  const WeeklyReview({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.reflection,
    required this.decision,
    this.adjustments,
  });
  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final String reflection;
  final String decision;
  final String? adjustments;
}

class RecoveryCheckin {
  const RecoveryCheckin({
    required this.date,
    required this.recoveryScore,
    this.sleepHours,
    this.sorenessScore,
    this.stressScore,
    this.note,
  });
  final DateTime date;
  final int recoveryScore;
  final double? sleepHours;
  final int? sorenessScore;
  final int? stressScore;
  final String? note;
}

class ActiveFast {
  const ActiveFast({
    required this.id,
    required this.startedAt,
    this.targetMinutes,
    this.note,
  });
  final String id;
  final DateTime startedAt;
  final int? targetMinutes;
  final String? note;
}

class FastingLog {
  const FastingLog({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    this.targetMinutes,
    this.note,
  });
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMinutes;
  final int? targetMinutes;
  final String? note;
}

class FastingRecord {
  const FastingRecord({required this.logs, this.active});
  final ActiveFast? active;
  final List<FastingLog> logs;
}

class ProgressPhoto {
  const ProgressPhoto({
    required this.id,
    required this.capturedAt,
    required this.mimeType,
    this.note,
    this.imageUrl,
    this.localBytes,
  });
  final String id;
  final DateTime capturedAt;
  final String mimeType;
  final String? note;
  final String? imageUrl;
  final Uint8List? localBytes;
}

class ProgressPhotoUpload {
  const ProgressPhotoUpload({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    required this.capturedAt,
    this.note,
  });
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
  final DateTime capturedAt;
  final String? note;
}

class ProgressSession {
  const ProgressSession({
    required this.id,
    required this.startedAt,
    required this.status,
    this.endedAt,
    this.planName,
    this.planDayName,
  });
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionStatus status;
  final String? planName;
  final String? planDayName;
}

class ProgressRecord {
  const ProgressRecord({required this.photos, required this.sessions});
  final List<ProgressPhoto> photos;
  final List<ProgressSession> sessions;
}

enum ServingUnit {
  g,
  ml,
  oz,
  flOz,
  cup,
  tbsp,
  tsp,
  piece,
  bottle,
  can,
  packet,
  slice,
  serving,
}

enum MealType { breakfast, lunch, dinner, snack }

class Food {
  const Food({
    required this.id,
    required this.name,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.barcodeUpc,
    this.servingSizeValue,
    this.servingSizeUnit,
    this.servingSizeText,
  });
  final String id;
  final String name;
  final String? barcodeUpc;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? servingSizeValue;
  final ServingUnit? servingSizeUnit;
  final String? servingSizeText;

  String get servingLabel =>
      servingSizeText ??
      (servingSizeValue == null || servingSizeUnit == null
          ? '100 g reference'
          : '${servingSizeValue! % 1 == 0 ? servingSizeValue!.toInt() : servingSizeValue} ${servingUnitLabel(servingSizeUnit!)}');
}

String servingUnitLabel(ServingUnit unit) => switch (unit) {
  ServingUnit.flOz => 'fl oz',
  _ => unit.name,
};

class MealItemInput {
  const MealItemInput({required this.foodId, required this.grams});
  final String foodId;
  final double grams;
}

class NutritionMeal {
  const NutritionMeal({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.mealType,
    required this.grams,
    required this.consumedAt,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.servingSizeValue,
    this.servingSizeUnit,
    this.servingSizeText,
    this.imageUrl,
    this.localImageBytes,
  });
  final String id;
  final String foodId;
  final String foodName;
  final MealType mealType;
  final double grams;
  final DateTime consumedAt;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? servingSizeValue;
  final ServingUnit? servingSizeUnit;
  final String? servingSizeText;
  final String? imageUrl;
  final Uint8List? localImageBytes;

  String get servingLabel =>
      servingSizeText ??
      (servingSizeValue == null || servingSizeUnit == null
          ? 'serving'
          : '${servingSizeValue! % 1 == 0 ? servingSizeValue!.toInt() : servingSizeValue} ${servingUnitLabel(servingSizeUnit!)}');
}

class NutritionRecord {
  const NutritionRecord({required this.foods, required this.meals});
  final List<Food> foods;
  final List<NutritionMeal> meals;
}

class NutritionLookup {
  const NutritionLookup({
    required this.found,
    required this.source,
    this.food,
    this.confidence,
  });
  final bool found;
  final String source;
  final Food? food;
  final double? confidence;
}

enum ArcanaStage { unrevealed, revealed, refined, illuminated, mastered }

enum ArcanaSlot { past, present, becoming }

class ArcanaEvidence {
  const ArcanaEvidence({
    required this.summary,
    this.stats = const {},
    this.earnedAt,
  });
  final String? summary;
  final Map<String, Object?> stats;
  final DateTime? earnedAt;
}

class ArcanaMilestone {
  const ArcanaMilestone({
    required this.stage,
    required this.description,
    required this.current,
    required this.target,
  });
  final ArcanaStage stage;
  final String description;
  final int current;
  final int target;
}

class ArcanaCard {
  const ArcanaCard({
    required this.id,
    required this.number,
    required this.name,
    required this.focus,
    required this.source,
    required this.stage,
    required this.stageEvidence,
    this.earnedAt,
    this.nextMilestone,
  });
  final String id;
  final String number;
  final String name;
  final String focus;
  final String source;
  final ArcanaStage stage;
  final DateTime? earnedAt;
  final Map<ArcanaStage, ArcanaEvidence> stageEvidence;
  final ArcanaMilestone? nextMilestone;
}

class ArcanaData {
  const ArcanaData({
    required this.ruleVersion,
    required this.cards,
    required this.pins,
  });
  final int ruleVersion;
  final List<ArcanaCard> cards;
  final Map<ArcanaSlot, String?> pins;
}

class User {
  const User({
    required this.id,
    required this.username,
    required this.weightUnit,
    this.displayName,
  });
  final String id;
  final String username;
  final String? displayName;
  final WeightUnit weightUnit;
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.muscleGroup,
    this.demoUrl,
    this.demoSourceName,
  });
  final String id;
  final String name;
  final String category;
  final String? muscleGroup;
  final String? demoUrl;
  final String? demoSourceName;
}

class CatalogExercise {
  const CatalogExercise({required this.name, required this.slug});
  final String name;
  final String slug;
}

class AiWorkoutExercise {
  const AiWorkoutExercise({
    required this.exerciseName,
    required this.targetSets,
    this.targetReps,
    this.targetWeightKg,
  });
  final String exerciseName;
  final int targetSets;
  final int? targetReps;
  final double? targetWeightKg;
}

class AiWorkoutDay {
  const AiWorkoutDay({required this.name, required this.exercises});
  final String name;
  final List<AiWorkoutExercise> exercises;
}

class AiWorkoutPlanDraft {
  const AiWorkoutPlanDraft({
    required this.name,
    required this.days,
    this.description,
  });
  final String name;
  final String? description;
  final List<AiWorkoutDay> days;
}

class PreviousPerformance {
  const PreviousPerformance({
    required this.sessionId,
    required this.completedAt,
    required this.weightKg,
    required this.reps,
  });
  final String sessionId;
  final DateTime completedAt;
  final double weightKg;
  final int reps;
}

class PlanExercise {
  const PlanExercise({
    required this.id,
    required this.exercise,
    required this.sortOrder,
    required this.targetSets,
    required this.targetReps,
    this.targetWeightKg,
    this.previousPerformance,
  });
  final String id;
  final Exercise exercise;
  final int sortOrder;
  final int targetSets;
  final int targetReps;
  final double? targetWeightKg;
  final PreviousPerformance? previousPerformance;
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.days,
    this.description,
  });
  final String id;
  final String name;
  final String? description;
  final DateTime updatedAt;
  final List<WorkoutPlanDay> days;

  /// Compatibility view for callers that have not selected a training day.
  /// New workout flows must use [days] explicitly.
  List<PlanExercise> get exercises =>
      days.isEmpty ? const [] : days.first.exercises;
  int get exerciseCount =>
      days.fold(0, (total, day) => total + day.exercises.length);
}

class WorkoutPlanDay {
  const WorkoutPlanDay({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.exercises,
  });
  final String id;
  final String name;
  final int sortOrder;
  final List<PlanExercise> exercises;
}

class LoggedSet {
  const LoggedSet({
    required this.id,
    required this.sessionExerciseId,
    required this.setOrder,
    required this.weightKg,
    required this.reps,
    required this.completedAt,
    this.isWarmup = false,
    this.pending = false,
  });
  final String id;
  final String sessionExerciseId;
  final int setOrder;
  final double weightKg;
  final int reps;
  final DateTime completedAt;
  final bool isWarmup;
  final bool pending;

  LoggedSet copyWith({
    String? id,
    int? setOrder,
    double? weightKg,
    int? reps,
    DateTime? completedAt,
    bool? isWarmup,
    bool? pending,
  }) => LoggedSet(
    id: id ?? this.id,
    sessionExerciseId: sessionExerciseId,
    setOrder: setOrder ?? this.setOrder,
    weightKg: weightKg ?? this.weightKg,
    reps: reps ?? this.reps,
    completedAt: completedAt ?? this.completedAt,
    isWarmup: isWarmup ?? this.isWarmup,
    pending: pending ?? this.pending,
  );
}

enum PersonalRecordKind { estimatedOneRepMax, reps }

class PersonalRecord {
  const PersonalRecord({
    required this.exerciseName,
    required this.kind,
    required this.currentReps,
    required this.currentWeightKg,
    required this.previousReps,
    required this.previousWeightKg,
  });
  final String exerciseName;
  final PersonalRecordKind kind;
  final int currentReps;
  final double currentWeightKg;
  final int previousReps;
  final double previousWeightKg;
}

class SetLogResult {
  const SetLogResult({required this.set, this.personalRecord});
  final LoggedSet set;
  final PersonalRecord? personalRecord;
}

/// A validated set that is durable on this device but has not yet received a
/// server acknowledgement. Its [operationId] is sent unchanged on every retry
/// so the server can apply the command at most once.
class PendingSetLog {
  const PendingSetLog({
    required this.operationId,
    required this.sessionId,
    required this.sessionExerciseId,
    required this.weightKg,
    required this.reps,
    required this.isWarmup,
    required this.createdAt,
    this.blocked = false,
  });
  final String operationId;
  final String sessionId;
  final String sessionExerciseId;
  final double weightKg;
  final int reps;
  final bool isWarmup;
  final DateTime createdAt;
  final bool blocked;

  LoggedSet asPendingSet(int order) => LoggedSet(
    id: 'pending-$operationId',
    sessionExerciseId: sessionExerciseId,
    setOrder: order,
    weightKg: weightKg,
    reps: reps,
    completedAt: createdAt,
    isWarmup: isWarmup,
    pending: true,
  );

  Map<String, Object> toJson() => {
    'operationId': operationId,
    'sessionId': sessionId,
    'sessionExerciseId': sessionExerciseId,
    'weightKg': weightKg,
    'reps': reps,
    'isWarmup': isWarmup,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'blocked': blocked,
  };

  static PendingSetLog fromJson(Map<String, dynamic> json) => PendingSetLog(
    operationId: json['operationId'] as String,
    sessionId: json['sessionId'] as String,
    sessionExerciseId: json['sessionExerciseId'] as String,
    weightKg: (json['weightKg'] as num).toDouble(),
    reps: json['reps'] as int,
    isWarmup: json['isWarmup'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    blocked: json['blocked'] == true,
  );

  PendingSetLog copyWith({bool? blocked}) => PendingSetLog(
    operationId: operationId,
    sessionId: sessionId,
    sessionExerciseId: sessionExerciseId,
    weightKg: weightKg,
    reps: reps,
    isWarmup: isWarmup,
    createdAt: createdAt,
    blocked: blocked ?? this.blocked,
  );
}

class PendingSetSyncReport {
  const PendingSetSyncReport({
    this.synced = const [],
    this.deferred = const [],
    this.blocked = const [],
  });
  final List<SetLogResult> synced;
  final List<PendingSetLog> deferred;
  final List<PendingSetLog> blocked;
  bool get hasUnresolved => deferred.isNotEmpty || blocked.isNotEmpty;
}

class SetSubmissionResult {
  const SetSubmissionResult({this.personalRecord, required this.queued});
  final PersonalRecord? personalRecord;
  final bool queued;
}

class SessionExercise {
  const SessionExercise({
    required this.id,
    required this.exerciseId,
    required this.name,
    required this.sortOrder,
    required this.targetSets,
    required this.targetReps,
    required this.sets,
    this.muscleGroup,
    this.demoUrl,
    this.demoSourceName,
    this.targetWeightKg,
    this.previousPerformance,
  });
  final String id;
  final String exerciseId;
  final String name;
  final String? muscleGroup;
  final String? demoUrl;
  final String? demoSourceName;
  final int sortOrder;
  final int targetSets;
  final int targetReps;
  final double? targetWeightKg;
  final PreviousPerformance? previousPerformance;
  final List<LoggedSet> sets;

  SessionExercise copyWith({List<LoggedSet>? sets}) => SessionExercise(
    id: id,
    exerciseId: exerciseId,
    name: name,
    muscleGroup: muscleGroup,
    demoUrl: demoUrl,
    demoSourceName: demoSourceName,
    sortOrder: sortOrder,
    targetSets: targetSets,
    targetReps: targetReps,
    targetWeightKg: targetWeightKg,
    previousPerformance: previousPerformance,
    sets: sets ?? this.sets,
  );
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.planId,
    required this.planName,
    required this.planDayId,
    required this.planDayName,
    required this.status,
    required this.startedAt,
    required this.exercises,
    required this.updatedAt,
    this.completedAt,
    this.discardedAt,
    this.restEndsAt,
  });
  final String id;
  final String planId;
  final String planName;
  final String planDayId;
  final String planDayName;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? discardedAt;
  final DateTime? restEndsAt;
  final List<SessionExercise> exercises;
  final DateTime updatedAt;
  int get workingSetCount => exercises.fold(
    0,
    (sum, exercise) =>
        sum +
        exercise.sets.where((set) => !set.isWarmup && !set.pending).length,
  );
  int get warmupSetCount => exercises.fold(
    0,
    (sum, exercise) => sum + exercise.sets.where((set) => set.isWarmup).length,
  );
  double get totalVolumeKg => exercises
      .expand((exercise) => exercise.sets.where((set) => !set.pending))
      .fold(0, (sum, set) => sum + set.weightKg * set.reps);
  Duration get duration =>
      (completedAt ?? DateTime.now()).difference(startedAt);
  WorkoutSession copyWith({
    SessionStatus? status,
    DateTime? completedAt,
    DateTime? discardedAt,
    DateTime? restEndsAt,
    bool clearRest = false,
    List<SessionExercise>? exercises,
    DateTime? updatedAt,
  }) => WorkoutSession(
    id: id,
    planId: planId,
    planName: planName,
    planDayId: planDayId,
    planDayName: planDayName,
    status: status ?? this.status,
    startedAt: startedAt,
    completedAt: completedAt ?? this.completedAt,
    discardedAt: discardedAt ?? this.discardedAt,
    restEndsAt: clearRest ? null : (restEndsAt ?? this.restEndsAt),
    exercises: exercises ?? this.exercises,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class CompletedSessionSummary {
  const CompletedSessionSummary({
    required this.id,
    required this.planName,
    required this.startedAt,
    required this.completedAt,
    required this.durationSeconds,
    required this.workingSetCount,
    required this.totalVolumeKg,
  });
  final String id;
  final String planName;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationSeconds;
  final int workingSetCount;
  final double totalVolumeKg;
}

String displayWeight(double kg, WeightUnit unit) {
  final value = unit == WeightUnit.lb ? kg * 2.2046226218 : kg;
  return '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} ${unit.name}';
}

double toKg(double value, WeightUnit unit) =>
    unit == WeightUnit.lb ? value / 2.2046226218 : value;
