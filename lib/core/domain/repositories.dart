import 'dart:typed_data';

import 'models.dart';

class AppFailure implements Exception {
  const AppFailure(
    this.code,
    this.message, {
    this.field,
    this.retryable = false,
    this.activeSessionId,
  });
  final String code;
  final String message;
  final String? field;
  final bool retryable;
  final String? activeSessionId;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final User user;
}

abstract class AuthRepository {
  Future<AuthSession> login(String username, String password);
  Future<AuthSession> register(
    String username,
    String password, {
    String? displayName,
  });
  Future<AuthSession?> restore();
  Future<void> logout();
}

abstract class PlanRepository {
  Future<List<WorkoutPlan>> listPlans();
  Future<WorkoutPlan> getPlan(String planId);
  Future<WorkoutPlan> createPlan(String name, {String? description});
  Future<AiWorkoutPlanDraft> generateAiWorkoutDraft(String prompt);
  Future<WorkoutPlan> importAiWorkoutPlan(AiWorkoutPlanDraft draft);
  Future<WorkoutPlan> renamePlan(String planId, String name);
  Future<void> deletePlan(String planId);
  Future<WorkoutPlanDay> addDay(String planId, String name);
  Future<WorkoutPlanDay> renameDay(String planId, String dayId, String name);
  Future<void> deleteDay(String planId, String dayId);
  Future<WorkoutPlanDay> reorderDay(
    String planId,
    String dayId,
    ReorderDirection direction,
  );
  Future<PlanExercise> addExerciseToDay(
    String planId,
    String dayId,
    String exerciseId,
  );
  Future<void> removeExerciseFromDay(
    String planId,
    String dayId,
    String planExerciseId,
  );
  Future<PlanExercise> reorderExerciseInDay(
    String planId,
    String dayId,
    String planExerciseId,
    ReorderDirection direction,
  );
  Future<PlanExercise> updatePrescription(
    String planId,
    String dayId,
    String planExerciseId, {
    required int targetSets,
    required int targetReps,
    ExerciseTrackingMode trackingMode = ExerciseTrackingMode.reps,
    int? targetDurationSeconds,
    double? targetWeightKg,
  });
  Future<Exercise> createExercise({
    required String name,
    required String category,
    String? muscleGroup,
  });
  Future<Exercise> updateExerciseDemo(
    String exerciseId, {
    required String demoUrl,
    String? sourceName,
  });
  Future<List<CatalogExercise>> searchCalistreeExercises(String query);
  Future<PlanExercise> importCalistreeExerciseToDay(
    String planId,
    String dayId,
    String slug, {
    int targetSets = 3,
    int? targetReps,
    double? targetWeightKg,
  });
  Future<List<Exercise>> searchExercises(String query);
  Future<List<RoutineShare>> listRoutineShares(String routineDayId);
  Future<RoutineShare> createRoutineShare(String routineDayId);
  Future<void> revokeRoutineShare(String token);
  Future<RoutineShareSnapshot> getRoutineShare(String token);
  Future<WorkoutPlanDay> importRoutineShare(
    String token, {
    required String planId,
    String? name,
  });
}

abstract class SessionRepository {
  Future<WorkoutSession?> activeSession();
  Future<WorkoutSession> getSession(String id);
  Future<WorkoutSession> startSession(String planId, [String? planDayId]);
  Future<WorkoutSession> startFreeformSession();
  Future<WorkoutSession> updateRest(String id, DateTime? restEndsAt);
  Future<SessionExercise> addExercise(String sessionId, String exerciseId);
  Future<SessionExercise> importCalistreeExercise(
    String sessionId,
    String slug,
  );
  Future<void> removeExercise(String sessionId, String sessionExerciseId);
  Future<bool> supportsOfflineSetSync();
  Future<SetLogResult> createSet(
    String sessionExerciseId,
    double weightKg,
    int reps, {
    bool isWarmup = false,
    int? durationSeconds,
    String? clientOperationId,
  });
  Future<LoggedSet> updateSet(
    String id,
    double weightKg,
    int reps, {
    bool isWarmup = false,
    int? durationSeconds,
  });
  Future<void> deleteSet(String id);
  Future<WorkoutSession> complete(String id);
  Future<void> discard(String id);
  Future<void> deleteCompletedSession(String id);
  Future<List<CompletedSessionSummary>> completedHistory();
}

abstract class ExerciseRankRepository {
  Future<List<ExerciseRank>> listRanks({
    String query = '',
    ExerciseTrackingMode? mode,
  });
  Future<ExerciseRank> getRank(String exerciseId);

  /// Runs the documented rule locally for exploration only; it never writes.
  ExerciseRank preview({
    required Exercise exercise,
    required ExerciseTrackingMode mode,
    required double value,
    double? baselineValue,
  });
  Future<RankOverview> getOverview();
  Future<List<OverallRankHistoryPoint>> getHistory();
  Future<RankAnalysisData> getAnalysis();
}

abstract class QuickAddRepository {
  Future<void> create({
    required String exerciseId,
    required WeightUnit weightUnit,
    double? weightKg,
    int? reps,
    int? durationSeconds,
  });
}

abstract class RecoveryRepository {
  Future<List<RecoveryCheckin>> listCheckins();
  Future<RecoveryCheckin> saveCheckin(RecoveryCheckin checkin);
}

abstract class FastingRepository {
  Future<FastingRecord> read();
  Future<ActiveFast> start({int? targetMinutes, String? note});

  /// Returns true when a fast lasted less than five minutes and was discarded.
  Future<bool> end({String? note});
  Future<void> deleteLog(String id);
}

abstract class ProgressRepository {
  Future<ProgressRecord> read();
  Future<TrainingAnalytics> getTrainingAnalytics({
    TrainingPeriod period = TrainingPeriod.fourteenDays,
    TrainingMetric metric = TrainingMetric.volume,
  });
  Future<void> create(ProgressPhotoUpload upload);
  Future<Uint8List> readImageBytes(String id);
  Future<void> updateCapturedAt(String id, DateTime capturedAt);
  Future<void> delete(String id);
}

abstract class NutritionRepository {
  Future<NutritionRecord> read();
  Future<DailyNutritionTarget?> getDailyTarget({String? date});
  Future<DailyNutritionTarget> saveDailyTarget({
    required int caloriesTarget,
    double proteinGTarget = 0,
    double carbsGTarget = 0,
    double fatGTarget = 0,
    String? effectiveDate,
  });
  Future<NutritionDiaryDay> getDiaryDay(String date);
  Future<Food> createFood(Food food);
  Future<void> createMeal(
    MealType type,
    List<MealItemInput> items, {
    DateTime? consumedAt,
  });
  Future<void> updateMeal(
    String id, {
    required MealType type,
    required double grams,
    required DateTime consumedAt,
  });
  Future<void> deleteMeal(String id);
  Future<void> uploadMealPhoto(String mealId, ProgressPhotoUpload upload);
  Future<NutritionLookup> lookupBarcode(String code);
  Future<NutritionLookup> parseNutritionLabel(List<int> bytes);
  Future<FoodPhotoAnalysis> analyzeFoodPhoto(List<int> bytes);
}

abstract class ArcanaRepository {
  Future<ArcanaData> read();
  Future<ArcanaData> pin(ArcanaSlot slot, String cardId);
  Future<ArcanaData> reconcile();
}

abstract class FriendsRepository {
  Future<FriendsRecord> read();
  Future<SharedWorkoutSession> getSharedSession(String sessionId);
  Future<void> sendRequest(String username);
  Future<void> accept(String requestId);
  Future<void> reject(String requestId);
  Future<void> remove(String userId);
}

abstract class PreferencesRepository {
  Future<UserPreferences> read();
  Future<UserPreferences> setWeightUnit(WeightUnit unit);
  Future<UserPreferences> setActivePlan(String? planId);
  Future<ThemePreference?> getTheme();
  Future<ThemePreference> setTheme(ThemePreference preference);
}

abstract class GoalRepository {
  Future<List<Goal>> listGoals();
  Future<Goal> createGoal(Goal goal);
  Future<Goal> updateStatus(String goalId, GoalStatus status);
  Future<void> deleteGoal(String goalId);
  Future<void> assess(
    String goalId,
    double value,
    String note, {
    String? decision,
  });
}

abstract class BodyweightRepository {
  Future<List<BodyweightMeasurement>> listMeasurements();
  Future<BodyweightMeasurement> logMeasurement({
    required String measuredAt,
    required double weightKg,
    String? notes,
  });
  Future<void> deleteMeasurement(String id);
}

abstract class ProgressionRepository {
  Future<ProgressionData> getProgression();
  Future<void> claimReward(String rewardId);
}

abstract class StreakRepository {
  Future<StreakData> getStreaks({int? year, int? month});
  Future<void> updateTimezone(String timezone);
}

abstract class PlanningRepository {
  Future<List<TrainingBlock>> listBlocks();
  Future<TrainingBlock> createBlock(TrainingBlock block);
  Future<TrainingBlock> updateBlock(
    String blockId, {
    TrainingBlockStatus? status,
    String? note,
  });
  Future<ScheduledBlockSession> scheduleSession(
    String blockId,
    ScheduledBlockSession session,
  );
  Future<ScheduledBlockSession> updateScheduledSession(
    String sessionId, {
    DateTime? scheduledFor,
    ScheduledBlockSessionStatus? status,
    bool? isDeload,
    bool? isRecoverySession,
    String? note,
  });
  Future<List<WeeklyReview>> listReviews();
  Future<WeeklyReview> createReview(WeeklyReview review);
}
