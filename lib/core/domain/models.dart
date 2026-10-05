import 'dart:typed_data';

enum WeightUnit { kg, lb }

enum TimedDurationUnit {
  seconds(1, 'sec'),
  minutes(60, 'min'),
  hours(3600, 'hr');

  const TimedDurationUnit(this.secondsPerUnit, this.label);

  final int secondsPerUnit;
  final String label;

  int toSeconds(num value) => (value * secondsPerUnit).round();

  double fromSeconds(int seconds) => seconds / secondsPerUnit;

  String formatValue(double value) {
    final rounded = value.toStringAsFixed(6);
    return rounded.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static TimedDurationUnit forSeconds(int? seconds) {
    if (seconds != null && seconds >= 3600) {
      return TimedDurationUnit.hours;
    }
    if (seconds != null && seconds >= 60) {
      return TimedDurationUnit.minutes;
    }
    return TimedDurationUnit.seconds;
  }
}

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
    this.durationSeconds,
  });
  final String id;
  final String exerciseName;
  final int order;
  final int reps;
  final double? weight;
  final bool isWarmup;
  final int? durationSeconds;
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

enum ExerciseRankMetric { estimatedOneRepMaxKg, maxReps, maxDurationSeconds }

enum ExerciseRankTier { bronze, silver, gold, platinum, transmuted }

class ExerciseRankEvidence {
  const ExerciseRankEvidence({
    required this.sessionId,
    required this.completedAt,
    required this.value,
  });
  final String sessionId;
  final DateTime completedAt;
  final double value;
}

class ExerciseRankUpdate {
  const ExerciseRankUpdate({
    required this.exerciseId,
    required this.tier,
    required this.established,
  });
  final String exerciseId;
  final ExerciseRankTier tier;
  final bool established;
}

/// A server-owned, personal comparison for one canonical exercise and mode.
/// It deliberately never represents population standing or a percentile.
class ExerciseRank {
  const ExerciseRank({
    required this.exercise,
    this.trackingMode,
    this.metric,
    this.baselineValue,
    this.bestValue,
    this.tier,
    this.subdivision,
    this.progressPoints,
    this.nextThreshold,
    this.ruleVersion,
    this.calculatedAt,
    this.evidence = const [],
  });
  final Exercise exercise;
  final ExerciseTrackingMode? trackingMode;
  final ExerciseRankMetric? metric;
  final double? baselineValue;
  final double? bestValue;
  final ExerciseRankTier? tier;
  final int? subdivision;
  final int? progressPoints;
  final double? nextThreshold;
  final int? ruleVersion;
  final DateTime? calculatedAt;
  final List<ExerciseRankEvidence> evidence;

  bool get isRanked => tier != null && baselineValue != null;
  bool get isProvisional => bestValue != null && !isRanked;
}

/// A derived, personal rank across the documented curated muscle map.
/// It is never a population standing or a recovery score.
class MuscleRank {
  const MuscleRank({
    required this.groupId,
    required this.label,
    required this.regionId,
    required this.bodySide,
    required this.eligibleExerciseCount,
    this.score,
    this.tier,
    this.delta,
    this.calculatedAt,
    this.evidenceExerciseIds = const [],
  });
  final String groupId;
  final String label;
  final String regionId;
  final String bodySide;
  final int eligibleExerciseCount;
  final double? score;
  final ExerciseRankTier? tier;
  final double? delta;
  final DateTime? calculatedAt;
  final List<String> evidenceExerciseIds;
  bool get isRanked => score != null && tier != null;
}

class OverallRank {
  const OverallRank({
    required this.eligibleExerciseCount,
    required this.mappedGroupCount,
    required this.placementEligible,
    this.score,
    this.tier,
    this.delta,
    this.calculatedAt,
    this.evidenceExerciseIds = const [],
  });
  final int eligibleExerciseCount;
  final int mappedGroupCount;
  final bool placementEligible;
  final double? score;
  final ExerciseRankTier? tier;
  final double? delta;
  final DateTime? calculatedAt;
  final List<String> evidenceExerciseIds;
}

class RankOverview {
  const RankOverview({
    required this.overall,
    required this.groups,
    this.lastSessionChanges = const [],
  });
  final OverallRank overall;
  final List<MuscleRank> groups;
  final List<String> lastSessionChanges;
}

class OverallRankHistoryPoint {
  const OverallRankHistoryPoint({
    required this.calculatedAt,
    required this.eligibleExerciseCount,
    this.score,
    this.tier,
  });
  final DateTime calculatedAt;
  final int eligibleExerciseCount;
  final double? score;
  final ExerciseRankTier? tier;
}

enum TrainingPeriod {
  sevenDays('7d', 7),
  fourteenDays('14d', 14),
  thirtyDays('30d', 30);

  const TrainingPeriod(this.wireValue, this.days);
  final String wireValue;
  final int days;
}

enum TrainingMetric {
  volume('volume', 'Volume'),
  duration('duration', 'Duration'),
  reps('reps', 'Reps');

  const TrainingMetric(this.wireValue, this.label);
  final String wireValue;
  final String label;
}

class TrainingDailyBucket {
  const TrainingDailyBucket({
    required this.date,
    required this.sessionCount,
    required this.durationSeconds,
    required this.volumeKg,
    required this.reps,
  });
  final String date;
  final int sessionCount;
  final int durationSeconds;
  final double volumeKg;
  final int reps;
}

class TrainingAnalyticsSummary {
  const TrainingAnalyticsSummary({
    required this.workoutCount,
    required this.totalDurationSeconds,
    required this.totalVolumeKg,
    required this.totalReps,
    required this.workingSetCount,
    required this.personalRecordCount,
  });
  final int workoutCount;
  final int totalDurationSeconds;
  final double totalVolumeKg;
  final int totalReps;
  final int workingSetCount;
  final int personalRecordCount;
}

class TrainingAnalytics {
  const TrainingAnalytics({
    required this.period,
    required this.metric,
    required this.summary,
    required this.daily,
  });
  final TrainingPeriod period;
  final TrainingMetric metric;
  final TrainingAnalyticsSummary summary;
  final List<TrainingDailyBucket> daily;
}

class RankCategorySummary {
  const RankCategorySummary({
    required this.category,
    required this.rankedCount,
    required this.totalCount,
    this.averageRatio,
    this.averageTier,
  });
  final String category;
  final int rankedCount;
  final int totalCount;
  final double? averageRatio;
  final ExerciseRankTier? averageTier;
}

class RankTierCount {
  const RankTierCount({
    required this.tier,
    required this.count,
  });
  final ExerciseRankTier tier;
  final int count;
}

class WeeklyRankUpCount {
  const WeeklyRankUpCount({
    required this.weekStart,
    required this.count,
  });
  final String weekStart;
  final int count;
}

class RankUpcomingTarget {
  const RankUpcomingTarget({
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    this.muscleGroup,
    required this.trackingMode,
    required this.metric,
    required this.currentValue,
    required this.baselineValue,
    required this.tier,
    required this.progressPoints,
    this.nextThreshold,
  });
  final String exerciseId;
  final String exerciseName;
  final String category;
  final String? muscleGroup;
  final ExerciseTrackingMode trackingMode;
  final ExerciseRankMetric metric;
  final double currentValue;
  final double baselineValue;
  final ExerciseRankTier tier;
  final int progressPoints;
  final double? nextThreshold;
}

class RankAnalysisData {
  const RankAnalysisData({
    required this.categories,
    required this.tierDistribution,
    required this.weeklyRankUps,
    required this.upcomingTargets,
  });
  final List<RankCategorySummary> categories;
  final List<RankTierCount> tierDistribution;
  final List<WeeklyRankUpCount> weeklyRankUps;
  final List<RankUpcomingTarget> upcomingTargets;
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
    this.setOrder = 1,
    this.durationSeconds,
  });
  final String sessionId;
  final DateTime completedAt;
  final double weightKg;
  final int reps;
  final int setOrder;
  final int? durationSeconds;
}

enum ExerciseTrackingMode { reps, timed }

enum ReorderDirection { up, down }

class PlanExercise {
  const PlanExercise({
    required this.id,
    required this.exercise,
    required this.sortOrder,
    required this.targetSets,
    required this.targetReps,
    this.trackingMode = ExerciseTrackingMode.reps,
    this.targetDurationSeconds,
    this.targetWeightKg,
    this.previousPerformance,
  });
  final String id;
  final Exercise exercise;
  final int sortOrder;
  final int targetSets;
  final int targetReps;
  final ExerciseTrackingMode trackingMode;
  final int? targetDurationSeconds;
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

/// An immutable, token-addressable copy of a saved routine.  It intentionally
/// contains only routine prescriptions and public exercise metadata; workout
/// history, goals, and active-session state never travel with a share.
class RoutineShare {
  const RoutineShare({
    required this.id,
    required this.token,
    required this.routineDayId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.snapshot,
  });

  final String id;
  final String token;
  final String routineDayId;
  final RoutineShareStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final RoutineShareSnapshot snapshot;

  bool get isActive => status == RoutineShareStatus.active;
}

enum RoutineShareStatus { active, revoked, expired }

class RoutineShareSnapshot {
  const RoutineShareSnapshot({
    required this.routineName,
    required this.folderName,
    required this.exercises,
    this.ownerName,
    this.ownerUsername,
  });

  final String routineName;
  final String folderName;
  final String? ownerName;
  final String? ownerUsername;
  final List<RoutineShareExercise> exercises;

  int get totalSets =>
      exercises.fold(0, (total, exercise) => total + exercise.targetSets);
}

class RoutineShareExercise {
  const RoutineShareExercise({
    required this.exerciseId,
    required this.name,
    required this.category,
    required this.targetSets,
    required this.targetReps,
    required this.trackingMode,
    this.muscleGroup,
    this.targetDurationSeconds,
    this.targetWeightKg,
  });

  final String exerciseId;
  final String name;
  final String category;
  final String? muscleGroup;
  final int targetSets;
  final int targetReps;
  final ExerciseTrackingMode trackingMode;
  final int? targetDurationSeconds;
  final double? targetWeightKg;
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
    this.durationSeconds,
  });
  final String id;
  final String sessionExerciseId;
  final int setOrder;
  final double weightKg;
  final int reps;
  final DateTime completedAt;
  final bool isWarmup;
  final bool pending;
  final int? durationSeconds;

  LoggedSet copyWith({
    String? id,
    int? setOrder,
    double? weightKg,
    int? reps,
    DateTime? completedAt,
    bool? isWarmup,
    bool? pending,
    int? durationSeconds,
  }) => LoggedSet(
    id: id ?? this.id,
    sessionExerciseId: sessionExerciseId,
    setOrder: setOrder ?? this.setOrder,
    weightKg: weightKg ?? this.weightKg,
    reps: reps ?? this.reps,
    completedAt: completedAt ?? this.completedAt,
    isWarmup: isWarmup ?? this.isWarmup,
    pending: pending ?? this.pending,
    durationSeconds: durationSeconds ?? this.durationSeconds,
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
    this.durationSeconds,
    required this.isWarmup,
    required this.createdAt,
    this.blocked = false,
  });
  final String operationId;
  final String sessionId;
  final String sessionExerciseId;
  final double weightKg;
  final int reps;
  final int? durationSeconds;
  final bool isWarmup;
  final DateTime createdAt;
  final bool blocked;

  LoggedSet asPendingSet(int order) => LoggedSet(
    id: 'pending-$operationId',
    sessionExerciseId: sessionExerciseId,
    setOrder: order,
    weightKg: weightKg,
    reps: reps,
    durationSeconds: durationSeconds,
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
    'durationSeconds': ?durationSeconds,
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
    durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
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
    durationSeconds: durationSeconds,
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
    this.trackingMode = ExerciseTrackingMode.reps,
    this.targetDurationSeconds,
    required this.sets,
    this.muscleGroup,
    this.demoUrl,
    this.demoSourceName,
    this.targetWeightKg,
    this.previousPerformance,
    this.previousPerformances = const [],
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
  final ExerciseTrackingMode trackingMode;
  final int? targetDurationSeconds;
  final double? targetWeightKg;
  final PreviousPerformance? previousPerformance;
  final List<PreviousPerformance> previousPerformances;
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
    trackingMode: trackingMode,
    targetDurationSeconds: targetDurationSeconds,
    targetWeightKg: targetWeightKg,
    previousPerformance: previousPerformance,
    previousPerformances: previousPerformances,
    sets: sets ?? this.sets,
  );
}

enum WorkoutSessionOrigin { planDay, freeform, quickAdd }

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
    this.origin = WorkoutSessionOrigin.planDay,
    this.completedAt,
    this.discardedAt,
    this.restEndsAt,
    this.rankUpdates = const [],
  });
  final String id;
  final String? planId;
  final String planName;
  final String? planDayId;
  final String planDayName;
  final WorkoutSessionOrigin origin;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? discardedAt;
  final DateTime? restEndsAt;
  final List<ExerciseRankUpdate> rankUpdates;
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
    List<ExerciseRankUpdate>? rankUpdates,
  }) => WorkoutSession(
    id: id,
    planId: planId,
    planName: planName,
    planDayId: planDayId,
    planDayName: planDayName,
    origin: origin,
    status: status ?? this.status,
    startedAt: startedAt,
    completedAt: completedAt ?? this.completedAt,
    discardedAt: discardedAt ?? this.discardedAt,
    restEndsAt: clearRest ? null : (restEndsAt ?? this.restEndsAt),
    rankUpdates: rankUpdates ?? this.rankUpdates,
    exercises: exercises ?? this.exercises,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class CompletedSessionSummary {
  const CompletedSessionSummary({
    required this.id,
    required this.planId,
    required this.planDayId,
    required this.planName,
    required this.planDayName,
    required this.startedAt,
    required this.completedAt,
    required this.durationSeconds,
    required this.workingSetCount,
    required this.totalVolumeKg,
  });
  final String id;
  final String? planId;
  final String? planDayId;
  final String planName;
  final String planDayName;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationSeconds;
  final int workingSetCount;
  final double totalVolumeKg;
}

String displayWeight(double kg, WeightUnit unit) {
  final value = unit == WeightUnit.lb ? kg * 2.2046226218 : kg;
  final nearestWhole = value.roundToDouble();
  final decimals = (value - nearestWhole).abs() < 0.01 ? 0 : 1;
  return '${value.toStringAsFixed(decimals)} ${unit.name}';
}

double toKg(double value, WeightUnit unit) =>
    unit == WeightUnit.lb ? value / 2.2046226218 : value;

/// Expo's workout API stores values in the session's declared display unit.
/// Flutter converts exactly once at that boundary and keeps the domain model
/// canonical in kilograms.
double fromKg(double value, WeightUnit unit) =>
    unit == WeightUnit.lb ? value * 2.2046226218 : value;
