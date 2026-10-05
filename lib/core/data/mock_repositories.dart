import 'dart:async';
import 'dart:typed_data';

import '../api/api_repositories.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

class MockStore {
  MockStore() {
    final bench = const Exercise(
      id: 'bench',
      name: 'Barbell bench press',
      muscleGroup: 'Chest',
      category: 'strength',
    );
    final row = const Exercise(
      id: 'row',
      name: 'Chest-supported row',
      muscleGroup: 'Back',
      category: 'strength',
    );
    final press = const Exercise(
      id: 'press',
      name: 'Shoulder press',
      muscleGroup: 'Shoulders',
      category: 'strength',
    );
    final squat = const Exercise(
      id: 'squat',
      name: 'Back squat',
      muscleGroup: 'Quads',
      category: 'strength',
    );
    final rdl = const Exercise(
      id: 'rdl',
      name: 'Romanian deadlift',
      muscleGroup: 'Hamstrings',
      category: 'strength',
    );
    final calf = const Exercise(
      id: 'calf',
      name: 'Standing calf raise',
      muscleGroup: 'Calves',
      category: 'strength',
    );
    final wristCurl = const Exercise(
      id: 'barbell-wrist-curl',
      name: 'Barbell Wrist Curl',
      muscleGroup: 'Arms',
      category: 'strength',
    );
    final reverseCurl = const Exercise(
      id: 'barbell-reverse-curl',
      name: 'Barbell Reverse Curl',
      muscleGroup: 'Arms',
      category: 'strength',
      demoUrl: 'asset://assets/reverse_curl.webm',
    );
    catalog = [bench, row, press, squat, rdl, calf, wristCurl, reverseCurl];
    final historicalAt = DateTime.now().toUtc().subtract(
      const Duration(days: 4),
    );
    final priorBench = PreviousPerformance(
      sessionId: 'completed-upper-a',
      completedAt: historicalAt,
      weightKg: 58.967,
      reps: 8,
    );
    final priorRow = PreviousPerformance(
      sessionId: 'completed-upper-a',
      completedAt: historicalAt,
      weightKg: 45.359,
      reps: 10,
    );
    plans = [
      WorkoutPlan(
        id: 'upper-a',
        name: 'Upper A',
        description: 'Pressing and pulling strength work.',
        updatedAt: DateTime.now().toUtc(),
        days: [
          WorkoutPlanDay(
            id: 'upper-a-day-1',
            name: 'Upper strength',
            sortOrder: 0,
            exercises: [
              PlanExercise(
                id: 'upper-bench',
                exercise: bench,
                sortOrder: 0,
                targetSets: 3,
                targetReps: 8,
                targetWeightKg: 61.235,
                previousPerformance: priorBench,
              ),
              PlanExercise(
                id: 'upper-row',
                exercise: row,
                sortOrder: 1,
                targetSets: 3,
                targetReps: 10,
                targetWeightKg: 47.628,
                previousPerformance: priorRow,
              ),
              PlanExercise(
                id: 'upper-press',
                exercise: press,
                sortOrder: 2,
                targetSets: 3,
                targetReps: 10,
                targetWeightKg: 27.216,
              ),
            ],
          ),
        ],
      ),
      WorkoutPlan(
        id: 'lower-a',
        name: 'Lower A',
        description: 'Squat, hinge, and calf work.',
        updatedAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        days: [
          WorkoutPlanDay(
            id: 'lower-a-day-1',
            name: 'Lower strength',
            sortOrder: 0,
            exercises: [
              PlanExercise(
                id: 'lower-squat',
                exercise: squat,
                sortOrder: 0,
                targetSets: 3,
                targetReps: 6,
                targetWeightKg: 83.915,
              ),
              PlanExercise(
                id: 'lower-rdl',
                exercise: rdl,
                sortOrder: 1,
                targetSets: 3,
                targetReps: 8,
                targetWeightKg: 74.843,
              ),
              PlanExercise(
                id: 'lower-calf',
                exercise: calf,
                sortOrder: 2,
                targetSets: 3,
                targetReps: 12,
                targetWeightKg: 40,
              ),
            ],
          ),
        ],
      ),
    ];
    completed = [
      WorkoutSession(
        id: 'completed-upper-a',
        planId: 'upper-a',
        planName: 'Upper A',
        planDayId: 'upper-a-day-1',
        planDayName: 'Upper strength',
        status: SessionStatus.completed,
        startedAt: historicalAt.subtract(const Duration(minutes: 56)),
        completedAt: historicalAt,
        updatedAt: historicalAt,
        exercises: [
          SessionExercise(
            id: 'history-bench',
            exerciseId: bench.id,
            name: bench.name,
            muscleGroup: bench.muscleGroup,
            sortOrder: 0,
            targetSets: 3,
            targetReps: 8,
            targetWeightKg: 58.967,
            sets: [
              LoggedSet(
                id: 'history-bench-1',
                sessionExerciseId: 'history-bench',
                setOrder: 1,
                weightKg: 58.967,
                reps: 8,
                completedAt: historicalAt,
              ),
              LoggedSet(
                id: 'history-bench-2',
                sessionExerciseId: 'history-bench',
                setOrder: 2,
                weightKg: 58.967,
                reps: 8,
                completedAt: historicalAt,
              ),
            ],
          ),
          SessionExercise(
            id: 'history-row',
            exerciseId: row.id,
            name: row.name,
            muscleGroup: row.muscleGroup,
            sortOrder: 1,
            targetSets: 3,
            targetReps: 10,
            targetWeightKg: 45.359,
            sets: [
              LoggedSet(
                id: 'history-row-1',
                sessionExerciseId: 'history-row',
                setOrder: 1,
                weightKg: 45.359,
                reps: 10,
                completedAt: historicalAt,
              ),
            ],
          ),
        ],
      ),
    ];
    incomingFriends = const [
      FriendRequest(
        id: 'friend-request-sparrow',
        status: 'pending',
        userId: 'friend-sparrow',
        username: 'sparrow',
        name: 'Sparrow',
      ),
    ];
    outgoingFriends = const [
      FriendRequest(
        id: 'friend-alchemist',
        status: 'accepted',
        userId: 'friend-alchemist',
        username: 'alchemist',
        name: 'Alchemist',
      ),
    ];
    friendActivity = [
      FriendActivity(
        id: 'friend-session-alchemist',
        userId: 'friend-alchemist',
        username: 'alchemist',
        name: 'Alchemist',
        startedAt: historicalAt.subtract(const Duration(hours: 5)),
        status: 'completed',
        routineName: 'Full body',
        dayName: 'Strength',
        setCount: 14,
      ),
    ];
  }

  late final List<Exercise> catalog;
  late final List<WorkoutPlan> plans;
  late final List<WorkoutSession> completed;
  final List<RecoveryCheckin> recoveryCheckins = [];
  ActiveFast? activeFast;
  final List<FastingLog> fastingLogs = [];
  final List<ProgressPhoto> progressPhotos = [];
  final List<Food> foods = [
    const Food(
      id: 'food-greek-yogurt',
      name: 'Greek yogurt',
      caloriesKcal: 120,
      proteinG: 22,
      carbsG: 7,
      fatG: 0,
      servingSizeValue: 170,
      servingSizeUnit: ServingUnit.g,
    ),
    const Food(
      id: 'food-oats',
      name: 'Rolled oats',
      caloriesKcal: 150,
      proteinG: 5,
      carbsG: 27,
      fatG: 3,
      servingSizeValue: 40,
      servingSizeUnit: ServingUnit.g,
    ),
    const Food(
      id: 'food-banana',
      name: 'Banana',
      caloriesKcal: 105,
      proteinG: 1.3,
      carbsG: 27,
      fatG: .4,
      servingSizeValue: 1,
      servingSizeUnit: ServingUnit.piece,
    ),
  ];
  final List<NutritionMeal> meals = [];
  final List<Goal> goals = [
    Goal(
      id: 'mock-goal-bodyweight',
      title: 'Target Bodyweight',
      category: GoalCategory.body,
      baseline: 83.0,
      target: 78.0,
      unit: 'kg',
      targetDate: DateTime.now().add(const Duration(days: 60)),
      status: GoalStatus.active,
      assessments: [
        GoalAssessment(
          id: 'mock-bw-assess-1',
          assessedAt: DateTime.now().subtract(const Duration(days: 1)),
          value: 81.5,
          reason: 'Consistent morning weigh-in.',
        ),
      ],
    ),
    Goal(
      id: 'mock-goal-bench',
      title: 'Barbell Bench Press Target',
      category: GoalCategory.strength,
      baseline: 80.0,
      target: 100.0,
      unit: 'kg',
      targetDate: DateTime.now().add(const Duration(days: 75)),
      status: GoalStatus.active,
      exerciseId: 'bench-press',
      exerciseName: 'Barbell Bench Press',
      trackingMode: ExerciseTrackingMode.reps,
      assessments: [
        GoalAssessment(
          id: 'mock-strength-assess-1',
          assessedAt: DateTime.now().subtract(const Duration(days: 2)),
          value: 87.5,
          reason: 'Solid working triples.',
        ),
      ],
    ),
  ];
  final List<BodyweightMeasurement> bodyweightMeasurements = [
    BodyweightMeasurement(
      id: 'mock-bw-1',
      measuredAt: DateTime.now().toIso8601String().substring(0, 10),
      weightKg: 81.5,
      notes: 'Post-workout weigh-in',
      createdAt: DateTime.now(),
    ),
  ];
  final List<TrainingBlock> blocks = [];
  final List<WeeklyReview> reviews = [];
  late List<FriendRequest> incomingFriends;
  late List<FriendRequest> outgoingFriends;
  late List<FriendActivity> friendActivity;
  final List<RoutineShare> routineShares = [];
  UserPreferences preferences = const UserPreferences(
    weightUnit: WeightUnit.lb,
    activePlanId: 'upper-a',
  );
  WorkoutSession? active;
  int sequence = 0;
  String next(String prefix) => '$prefix-${++sequence}';
}

class MockRecoveryRepository implements RecoveryRepository {
  MockRecoveryRepository(this._store);
  final MockStore _store;
  @override
  Future<List<RecoveryCheckin>> listCheckins() async =>
      [..._store.recoveryCheckins]..sort((a, b) => b.date.compareTo(a.date));
  @override
  Future<RecoveryCheckin> saveCheckin(RecoveryCheckin checkin) async {
    _store.recoveryCheckins.removeWhere(
      (item) =>
          item.date.year == checkin.date.year &&
          item.date.month == checkin.date.month &&
          item.date.day == checkin.date.day,
    );
    _store.recoveryCheckins.add(checkin);
    return checkin;
  }
}

class MockFastingRepository implements FastingRepository {
  MockFastingRepository(this._store);
  final MockStore _store;

  @override
  Future<FastingRecord> read() async => FastingRecord(
    active: _store.activeFast,
    logs: [..._store.fastingLogs]
      ..sort((a, b) => b.endedAt.compareTo(a.endedAt)),
  );

  @override
  Future<ActiveFast> start({int? targetMinutes, String? note}) async {
    final active = ActiveFast(
      id: _store.next('fast'),
      startedAt: DateTime.now(),
      targetMinutes: targetMinutes,
      note: note,
    );
    _store.activeFast = active;
    return active;
  }

  @override
  Future<bool> end({String? note}) async {
    final active = _store.activeFast;
    if (active == null) {
      throw const AppFailure(
        'no_active_fast',
        'There is no active fast to end.',
      );
    }
    final endedAt = DateTime.now();
    final duration = endedAt.difference(active.startedAt).inMinutes;
    _store.activeFast = null;
    if (duration < 5) return true;
    _store.fastingLogs.add(
      FastingLog(
        id: _store.next('fast-log'),
        startedAt: active.startedAt,
        endedAt: endedAt,
        durationMinutes: duration,
        targetMinutes: active.targetMinutes,
        note: note ?? active.note,
      ),
    );
    return false;
  }

  @override
  Future<void> deleteLog(String id) async {
    final exists = _store.fastingLogs.any((log) => log.id == id);
    if (!exists) {
      throw const AppFailure(
        'fast_not_found',
        'That fasting record is unavailable.',
      );
    }
    _store.fastingLogs.removeWhere((log) => log.id == id);
  }
}

class MockProgressRepository implements ProgressRepository {
  MockProgressRepository(this._store);
  final MockStore _store;

  @override
  Future<ProgressRecord> read() async => ProgressRecord(
    photos: [..._store.progressPhotos]
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt)),
    sessions: [
      ..._store.completed.map(
        (session) => ProgressSession(
          id: session.id,
          startedAt: session.startedAt,
          endedAt: session.completedAt,
          status: session.status,
          planName: session.planName,
          planDayName: session.planDayName,
        ),
      ),
      if (_store.active != null)
        ProgressSession(
          id: _store.active!.id,
          startedAt: _store.active!.startedAt,
          status: _store.active!.status,
          planName: _store.active!.planName,
          planDayName: _store.active!.planDayName,
        ),
    ],
  );

  @override
  Future<TrainingAnalytics> getTrainingAnalytics({
    TrainingPeriod period = TrainingPeriod.fourteenDays,
    TrainingMetric metric = TrainingMetric.volume,
  }) async {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: period.days));
    final relevant = _store.completed
        .where((s) => s.completedAt != null && s.completedAt!.isAfter(cutoff))
        .toList();

    int totalDuration = 0;
    double totalVolume = 0;
    int totalReps = 0;
    int workingSets = 0;

    final byDate = <String, ({int count, int duration, double volume, int reps})>{};

    for (final s in relevant) {
      final d = s.duration.inSeconds;
      totalDuration += d;
      final dateKey = s.completedAt!.toIso8601String().substring(0, 10);
      double sVol = 0;
      int sReps = 0;

      for (final ex in s.exercises) {
        for (final set in ex.sets.where((st) => !st.isWarmup)) {
          workingSets++;
          if (set.durationSeconds == null) {
            sReps += set.reps;
            totalReps += set.reps;
            if (set.weightKg > 0) {
              final vol = set.weightKg * set.reps;
              sVol += vol;
              totalVolume += vol;
            }
          }
        }
      }

      final prev = byDate[dateKey];
      if (prev == null) {
        byDate[dateKey] = (count: 1, duration: d, volume: sVol, reps: sReps);
      } else {
        byDate[dateKey] = (
          count: prev.count + 1,
          duration: prev.duration + d,
          volume: prev.volume + sVol,
          reps: prev.reps + sReps,
        );
      }
    }

    final daily = byDate.entries.map((e) => TrainingDailyBucket(
      date: e.key,
      sessionCount: e.value.count,
      durationSeconds: e.value.duration,
      volumeKg: e.value.volume,
      reps: e.value.reps,
    )).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return TrainingAnalytics(
      period: period,
      metric: metric,
      summary: TrainingAnalyticsSummary(
        workoutCount: relevant.length,
        totalDurationSeconds: totalDuration,
        totalVolumeKg: totalVolume,
        totalReps: totalReps,
        workingSetCount: workingSets,
        personalRecordCount: 0,
      ),
      daily: daily,
    );
  }

  @override
  Future<void> create(ProgressPhotoUpload upload) async {
    if (!upload.mimeType.startsWith('image/')) {
      throw const AppFailure('invalid_progress_photo', 'Choose an image file.');
    }
    if (upload.bytes.lengthInBytes > 20 * 1024 * 1024) {
      throw const AppFailure(
        'progress_photo_too_large',
        'Choose an image smaller than 20 MB.',
      );
    }
    _store.progressPhotos.add(
      ProgressPhoto(
        id: _store.next('progress'),
        capturedAt: upload.capturedAt,
        mimeType: upload.mimeType,
        note: upload.note,
        localBytes: upload.bytes,
      ),
    );
  }

  @override
  Future<Uint8List> readImageBytes(String id) async {
    final photo = _store.progressPhotos
        .where((item) => item.id == id)
        .firstOrNull;
    if (photo?.localBytes == null) {
      throw const AppFailure(
        'progress_not_found',
        'That progress photo is unavailable.',
      );
    }
    return photo!.localBytes!;
  }

  @override
  Future<void> updateCapturedAt(String id, DateTime capturedAt) async {
    final index = _store.progressPhotos.indexWhere((photo) => photo.id == id);
    if (index < 0) {
      throw const AppFailure(
        'progress_not_found',
        'That progress photo is unavailable.',
      );
    }
    final photo = _store.progressPhotos[index];
    _store.progressPhotos[index] = ProgressPhoto(
      id: photo.id,
      capturedAt: capturedAt,
      mimeType: photo.mimeType,
      note: photo.note,
      imageUrl: photo.imageUrl,
      localBytes: photo.localBytes,
    );
  }

  @override
  Future<void> delete(String id) async {
    if (!_store.progressPhotos.any((photo) => photo.id == id)) {
      throw const AppFailure(
        'progress_not_found',
        'That progress photo is unavailable.',
      );
    }
    _store.progressPhotos.removeWhere((photo) => photo.id == id);
  }
}

class MockNutritionRepository implements NutritionRepository {
  MockNutritionRepository(this._store);
  final MockStore _store;

  @override
  Future<NutritionRecord> read() async => NutritionRecord(
    foods: [..._store.foods]..sort((a, b) => a.name.compareTo(b.name)),
    meals: [..._store.meals]
      ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt)),
  );

  @override
  Future<Food> createFood(Food food) async {
    if (_store.foods.any(
      (candidate) =>
          candidate.barcodeUpc != null &&
          candidate.barcodeUpc == food.barcodeUpc,
    )) {
      throw const AppFailure(
        'duplicate_barcode',
        'That barcode already belongs to a food.',
      );
    }
    final created = Food(
      id: _store.next('food'),
      name: food.name,
      barcodeUpc: food.barcodeUpc,
      caloriesKcal: food.caloriesKcal,
      proteinG: food.proteinG,
      carbsG: food.carbsG,
      fatG: food.fatG,
      servingSizeValue: food.servingSizeValue,
      servingSizeUnit: food.servingSizeUnit,
      servingSizeText: food.servingSizeText,
    );
    _store.foods.add(created);
    return created;
  }

  @override
  Future<void> createMeal(
    MealType type,
    List<MealItemInput> items, {
    DateTime? consumedAt,
  }) async {
    if (items.isEmpty || items.length > 20) {
      throw const AppFailure(
        'invalid_meal',
        'Add between one and twenty foods.',
      );
    }
    final timestamp = consumedAt ?? DateTime.now();
    for (final item in items) {
      final food = _store.foods
          .where((candidate) => candidate.id == item.foodId)
          .firstOrNull;
      if (food == null)
        throw const AppFailure(
          'food_not_found',
          'One of the selected foods is unavailable.',
        );
      if (item.grams <= 0 || item.grams > 5000) {
        throw const AppFailure(
          'invalid_meal_amount',
          'Food amount must be more than 0 and no more than 5,000 g.',
        );
      }
      final base = food.servingSizeValue ?? 100;
      final factor = item.grams / base;
      _store.meals.add(
        NutritionMeal(
          id: _store.next('meal'),
          foodId: food.id,
          foodName: food.name,
          mealType: type,
          grams: item.grams,
          consumedAt: timestamp,
          caloriesKcal: food.caloriesKcal * factor,
          proteinG: food.proteinG * factor,
          carbsG: food.carbsG * factor,
          fatG: food.fatG * factor,
          servingSizeValue: food.servingSizeValue,
          servingSizeUnit: food.servingSizeUnit,
          servingSizeText: food.servingSizeText,
        ),
      );
    }
  }

  @override
  Future<void> updateMeal(
    String id, {
    required MealType type,
    required double grams,
    required DateTime consumedAt,
  }) async {
    final index = _store.meals.indexWhere((meal) => meal.id == id);
    if (index < 0)
      throw const AppFailure(
        'meal_not_found',
        'That logged food is unavailable.',
      );
    if (grams <= 0 || grams > 5000)
      throw const AppFailure(
        'invalid_meal_amount',
        'Food amount must be more than 0 and no more than 5,000 g.',
      );
    final old = _store.meals[index];
    final factor = grams / old.grams;
    _store.meals[index] = NutritionMeal(
      id: old.id,
      foodId: old.foodId,
      foodName: old.foodName,
      mealType: type,
      grams: grams,
      consumedAt: consumedAt,
      caloriesKcal: old.caloriesKcal * factor,
      proteinG: old.proteinG * factor,
      carbsG: old.carbsG * factor,
      fatG: old.fatG * factor,
      servingSizeValue: old.servingSizeValue,
      servingSizeUnit: old.servingSizeUnit,
      servingSizeText: old.servingSizeText,
      imageUrl: old.imageUrl,
      localImageBytes: old.localImageBytes,
    );
  }

  @override
  Future<void> deleteMeal(String id) async {
    if (!_store.meals.any((meal) => meal.id == id))
      throw const AppFailure(
        'meal_not_found',
        'That logged food is unavailable.',
      );
    _store.meals.removeWhere((meal) => meal.id == id);
  }

  @override
  Future<void> uploadMealPhoto(
    String mealId,
    ProgressPhotoUpload upload,
  ) async {
    final index = _store.meals.indexWhere((meal) => meal.id == mealId);
    if (index < 0) {
      throw const AppFailure(
        'meal_not_found',
        'That logged food is unavailable.',
      );
    }
    if (!upload.mimeType.startsWith('image/') ||
        upload.bytes.isEmpty ||
        upload.bytes.lengthInBytes > 20 * 1024 * 1024) {
      throw const AppFailure(
        'invalid_meal_photo',
        'Choose an image smaller than 20 MB.',
      );
    }
    final meal = _store.meals[index];
    _store.meals[index] = NutritionMeal(
      id: meal.id,
      foodId: meal.foodId,
      foodName: meal.foodName,
      mealType: meal.mealType,
      grams: meal.grams,
      consumedAt: meal.consumedAt,
      caloriesKcal: meal.caloriesKcal,
      proteinG: meal.proteinG,
      carbsG: meal.carbsG,
      fatG: meal.fatG,
      servingSizeValue: meal.servingSizeValue,
      servingSizeUnit: meal.servingSizeUnit,
      servingSizeText: meal.servingSizeText,
      imageUrl: meal.imageUrl,
      localImageBytes: upload.bytes,
    );
  }

  @override
  Future<NutritionLookup> lookupBarcode(String code) async {
    final food = _store.foods
        .where((candidate) => candidate.barcodeUpc == code)
        .firstOrNull;
    return NutritionLookup(
      found: food != null,
      source: food == null ? 'none' : 'local',
      food: food,
    );
  }

  @override
  Future<NutritionLookup> parseNutritionLabel(List<int> bytes) async {
    throw const AppFailure(
      'label_parse_unavailable',
      'Nutrition-label parsing requires API mode. Create the food manually in mock mode.',
    );
  }
}

class MockArcanaRepository implements ArcanaRepository {
  MockArcanaRepository()
    : _data = ArcanaData(
        ruleVersion: 1,
        cards: [
          ArcanaCard(
            id: 'fool',
            number: '0',
            name: 'The Fool',
            focus: 'Beginning the work.',
            source: 'original-geometric',
            stage: ArcanaStage.revealed,
            stageEvidence: {
              ArcanaStage.revealed: ArcanaEvidence(
                summary: 'A qualified session established the record.',
                stats: {'qualifiedSessions': 1},
              ),
            },
            nextMilestone: ArcanaMilestone(
              stage: ArcanaStage.refined,
              description:
                  'Complete qualified sessions to establish the record.',
              current: 1,
              target: 4,
            ),
          ),
          ArcanaCard(
            id: 'magician',
            number: 'I',
            name: 'The Magician',
            focus: 'Using every tool.',
            source: 'original-geometric',
            stage: ArcanaStage.unrevealed,
            stageEvidence: {},
            nextMilestone: ArcanaMilestone(
              stage: ArcanaStage.revealed,
              description:
                  'Bring training, food, and recovery into the same week.',
              current: 0,
              target: 4,
            ),
          ),
          ArcanaCard(
            id: 'emperor',
            number: 'IV',
            name: 'The Emperor',
            focus: 'Building structure.',
            source: 'original-geometric',
            stage: ArcanaStage.unrevealed,
            stageEvidence: {},
            nextMilestone: ArcanaMilestone(
              stage: ArcanaStage.revealed,
              description:
                  'Complete the work you scheduled in a training block.',
              current: 0,
              target: 4,
            ),
          ),
          _unrevealedArcana(
            'chariot',
            'VII',
            'The Chariot',
            'Creating momentum.',
            'Meet your weekly training target consistently.',
          ),
          _unrevealedArcana(
            'strength',
            'VIII',
            'Strength',
            'Turning effort into greater capacity.',
            'Build repeatable personal progress.',
          ),
          _unrevealedArcana(
            'hermit',
            'IX',
            'The Hermit',
            'Reflecting on the record.',
            'Review the work and make an informed adjustment.',
          ),
          ArcanaCard(
            id: 'justice',
            number: 'XI',
            name: 'Justice',
            focus: 'Measuring honestly.',
            source: 'original-geometric',
            stage: ArcanaStage.unrevealed,
            stageEvidence: {},
            nextMilestone: ArcanaMilestone(
              stage: ArcanaStage.revealed,
              description: 'Assess a goal and record a decision.',
              current: 0,
              target: 4,
            ),
          ),
          _unrevealedArcana(
            'hanged-man',
            'XII',
            'The Hanged Man',
            'Understanding restraint.',
            'Use a planned recovery adjustment when it is needed.',
          ),
          _unrevealedArcana(
            'death',
            'XIII',
            'Death',
            'Ending what no longer works.',
            'Close a plan with intention and begin the next one.',
          ),
          _unrevealedArcana(
            'temperance',
            'XIV',
            'Temperance',
            'Balancing the work.',
            'Sustain training, nutrition, and recovery together.',
          ),
          _unrevealedArcana(
            'tower',
            'XVI',
            'The Tower',
            'Returning after disruption.',
            'Return to the work after a meaningful interruption.',
          ),
          _unrevealedArcana(
            'star',
            'XVII',
            'The Star',
            'Rebuilding momentum.',
            'Turn a return into a steady rebuilding period.',
          ),
          _unrevealedArcana(
            'sun',
            'XIX',
            'The Sun',
            'Reaching a meaningful goal.',
            'Complete a goal you set for yourself.',
          ),
          _unrevealedArcana(
            'judgement',
            'XX',
            'Judgement',
            'Comparing then and now.',
            'Reassess the record and choose the next direction.',
          ),
          ArcanaCard(
            id: 'world',
            number: 'XXI',
            name: 'The World',
            focus: 'Completing the cycle.',
            source: 'original-geometric',
            stage: ArcanaStage.unrevealed,
            stageEvidence: {},
            nextMilestone: ArcanaMilestone(
              stage: ArcanaStage.revealed,
              description:
                  'Close a full cycle of plan, work, review, and assessment.',
              current: 0,
              target: 4,
            ),
          ),
        ],
        pins: const {
          ArcanaSlot.past: 'fool',
          ArcanaSlot.present: null,
          ArcanaSlot.becoming: null,
        },
      );
  ArcanaData _data;

  @override
  Future<ArcanaData> read() async => _data;

  @override
  Future<ArcanaData> pin(ArcanaSlot slot, String cardId) async {
    final cards = _data.cards.where((item) => item.id == cardId);
    final card = cards.isEmpty ? null : cards.first;
    if (card == null || card.stage == ArcanaStage.unrevealed) {
      throw const AppFailure(
        'arcana_unrevealed',
        'Only revealed cards can be pinned.',
      );
    }
    _data = ArcanaData(
      ruleVersion: _data.ruleVersion,
      cards: _data.cards,
      pins: {..._data.pins, slot: cardId},
    );
    return _data;
  }

  @override
  Future<ArcanaData> reconcile() async => _data;
}

ArcanaCard _unrevealedArcana(
  String id,
  String number,
  String name,
  String focus,
  String nextHint,
) => ArcanaCard(
  id: id,
  number: number,
  name: name,
  focus: focus,
  source: 'original-geometric',
  stage: ArcanaStage.unrevealed,
  stageEvidence: const {},
  nextMilestone: ArcanaMilestone(
    stage: ArcanaStage.revealed,
    description: nextHint,
    current: 0,
    target: 4,
  ),
);

class MockFriendsRepository implements FriendsRepository {
  MockFriendsRepository(this._store);
  final MockStore _store;

  @override
  Future<FriendsRecord> read() async => FriendsRecord(
    incoming: List.unmodifiable(_store.incomingFriends),
    outgoing: List.unmodifiable(_store.outgoingFriends),
    activity: List.unmodifiable(_store.friendActivity),
  );

  @override
  Future<SharedWorkoutSession> getSharedSession(String sessionId) async {
    final activity = _store.friendActivity
        .where((item) => item.id == sessionId)
        .cast<FriendActivity?>()
        .firstOrNull;
    if (activity == null ||
        !_store.outgoingFriends.any(
          (friend) =>
              friend.userId == activity.userId && friend.status == 'accepted',
        )) {
      throw const AppFailure(
        'shared_session_not_found',
        'Workout session not found.',
      );
    }
    return SharedWorkoutSession(
      ownerId: activity.userId,
      ownerUsername: activity.username,
      ownerName: activity.name,
      sessionId: activity.id,
      status: activity.status,
      startedAt: activity.startedAt,
      endedAt: activity.status == 'completed'
          ? activity.startedAt.add(const Duration(minutes: 54))
          : null,
      routineName: activity.routineName,
      dayName: activity.dayName,
      weightUnit: WeightUnit.lb,
      sets: const [
        SharedWorkoutSet(
          id: 'shared-bench-1',
          exerciseName: 'Barbell bench press',
          order: 1,
          reps: 8,
          weight: 135,
          isWarmup: false,
        ),
        SharedWorkoutSet(
          id: 'shared-bench-2',
          exerciseName: 'Barbell bench press',
          order: 2,
          reps: 8,
          weight: 135,
          isWarmup: false,
        ),
        SharedWorkoutSet(
          id: 'shared-row-1',
          exerciseName: 'Chest-supported row',
          order: 1,
          reps: 10,
          weight: 100,
          isWarmup: false,
        ),
      ],
    );
  }

  @override
  Future<void> sendRequest(String username) async {
    final value = username.trim().toLowerCase();
    if (value.length < 3) {
      throw const AppFailure(
        'invalid_username',
        'Enter a username with at least 3 characters.',
      );
    }
    if (value == 'demo') {
      throw const AppFailure('self_friend', 'You cannot add yourself.');
    }
    const known = {'alchemist', 'sparrow', 'mechanic'};
    if (!known.contains(value)) {
      throw const AppFailure('friend_not_found', 'User not found.');
    }
    final incoming = _store.incomingFriends.where(
      (request) => request.username == value && request.status == 'pending',
    );
    if (incoming.isNotEmpty) {
      final request = incoming.first;
      _store.incomingFriends = _store.incomingFriends
          .where((item) => item.id != request.id)
          .toList();
      _store.outgoingFriends = [
        ..._store.outgoingFriends.where(
          (item) => item.userId != request.userId,
        ),
        FriendRequest(
          id: request.id,
          status: 'accepted',
          userId: request.userId,
          username: request.username,
          name: request.name,
        ),
      ];
      return;
    }
    if (_store.outgoingFriends.any(
      (request) => request.username == value && request.status == 'accepted',
    )) {
      return;
    }
    if (_store.outgoingFriends.any(
      (request) => request.username == value && request.status == 'pending',
    )) {
      throw const AppFailure(
        'friend_request_pending',
        'Friend request already sent.',
      );
    }
    _store.outgoingFriends = [
      ..._store.outgoingFriends,
      FriendRequest(
        id: _store.next('friend-request'),
        status: 'pending',
        userId: 'friend-$value',
        username: value,
        name: value == 'mechanic' ? 'Mechanic' : value,
      ),
    ];
  }

  @override
  Future<void> accept(String requestId) async {
    final request = _store.incomingFriends
        .where((item) => item.id == requestId && item.status == 'pending')
        .cast<FriendRequest?>()
        .firstOrNull;
    if (request == null) {
      throw const AppFailure(
        'friend_request_not_found',
        'Friend request not found.',
      );
    }
    _store.incomingFriends = _store.incomingFriends
        .where((item) => item.id != requestId)
        .toList();
    _store.outgoingFriends = [
      ..._store.outgoingFriends.where((item) => item.userId != request.userId),
      FriendRequest(
        id: request.id,
        status: 'accepted',
        userId: request.userId,
        username: request.username,
        name: request.name,
      ),
    ];
  }

  @override
  Future<void> reject(String requestId) async {
    final found = _store.incomingFriends.any(
      (item) => item.id == requestId && item.status == 'pending',
    );
    if (!found) {
      throw const AppFailure(
        'friend_request_not_found',
        'Friend request not found.',
      );
    }
    _store.incomingFriends = _store.incomingFriends
        .where((item) => item.id != requestId)
        .toList();
  }

  @override
  Future<void> remove(String userId) async {
    final before =
        _store.incomingFriends.length + _store.outgoingFriends.length;
    _store.incomingFriends = _store.incomingFriends
        .where((item) => !(item.userId == userId && item.status == 'accepted'))
        .toList();
    _store.outgoingFriends = _store.outgoingFriends
        .where((item) => !(item.userId == userId && item.status == 'accepted'))
        .toList();
    if (before ==
        _store.incomingFriends.length + _store.outgoingFriends.length) {
      throw const AppFailure('friendship_not_found', 'Friendship not found.');
    }
  }
}

class MockPreferencesRepository implements PreferencesRepository {
  MockPreferencesRepository(this._store);
  final MockStore _store;
  @override
  Future<UserPreferences> read() async => _store.preferences;
  @override
  Future<UserPreferences> setWeightUnit(WeightUnit unit) async {
    _store.preferences = UserPreferences(
      weightUnit: unit,
      activePlanId: _store.preferences.activePlanId,
      theme: _store.preferences.theme,
    );
    return _store.preferences;
  }

  @override
  Future<UserPreferences> setActivePlan(String? planId) async {
    if (planId != null && !_store.plans.any((plan) => plan.id == planId)) {
      throw const AppFailure('plan_not_found', 'Workout plan not found.');
    }
    _store.preferences = UserPreferences(
      weightUnit: _store.preferences.weightUnit,
      activePlanId: planId,
      theme: _store.preferences.theme,
    );
    return _store.preferences;
  }

  @override
  Future<ThemePreference?> getTheme() async => _store.preferences.theme;
  @override
  Future<ThemePreference> setTheme(ThemePreference preference) async {
    _store.preferences = UserPreferences(
      weightUnit: _store.preferences.weightUnit,
      activePlanId: _store.preferences.activePlanId,
      theme: preference,
    );
    return preference;
  }
}

class MockGoalRepository implements GoalRepository {
  MockGoalRepository(this._store);
  final MockStore _store;
  @override
  Future<List<Goal>> listGoals() async => [..._store.goals];
  @override
  Future<Goal> createGoal(Goal goal) async {
    final created = Goal(
      id: _store.next('goal'),
      title: goal.title,
      category: goal.category,
      baseline: goal.baseline,
      target: goal.target,
      unit: goal.unit,
      targetDate: goal.targetDate,
      status: goal.status,
      exerciseId: goal.exerciseId,
      trackingMode: goal.trackingMode,
      exerciseName: goal.exerciseName,
    );
    _store.goals.insert(0, created);
    return created;
  }

  @override
  Future<Goal> updateStatus(String goalId, GoalStatus status) async {
    final index = _store.goals.indexWhere((goal) => goal.id == goalId);
    if (index < 0) {
      throw const AppFailure('goal_not_found', 'That goal is unavailable.');
    }
    final old = _store.goals[index];
    final updated = Goal(
      id: old.id,
      title: old.title,
      category: old.category,
      baseline: old.baseline,
      target: old.target,
      unit: old.unit,
      targetDate: old.targetDate,
      status: status,
      exerciseId: old.exerciseId,
      trackingMode: old.trackingMode,
      exerciseName: old.exerciseName,
      assessments: old.assessments,
    );
    _store.goals[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    _store.goals.removeWhere((goal) => goal.id == goalId);
  }

  @override
  Future<void> assess(
    String goalId,
    double value,
    String note, {
    String? decision,
  }) async {
    final index = _store.goals.indexWhere((goal) => goal.id == goalId);
    if (index < 0)
      throw const AppFailure('goal_not_found', 'That goal is unavailable.');
    if (note.trim().length < 2)
      throw const AppFailure(
        'invalid_assessment',
        'Add a short assessment note.',
      );
    final old = _store.goals[index];
    _store.goals[index] = Goal(
      id: old.id,
      title: old.title,
      category: old.category,
      baseline: old.baseline,
      target: old.target,
      unit: old.unit,
      targetDate: old.targetDate,
      status: old.status,
      exerciseId: old.exerciseId,
      trackingMode: old.trackingMode,
      exerciseName: old.exerciseName,
      assessments: [
        GoalAssessment(
          id: _store.next('assessment'),
          assessedAt: DateTime.now(),
          value: value,
          reason: note,
          decision: decision,
        ),
        ...old.assessments,
      ],
    );
  }
}

class MockBodyweightRepository implements BodyweightRepository {
  MockBodyweightRepository(this._store);
  final MockStore _store;

  @override
  Future<List<BodyweightMeasurement>> listMeasurements() async {
    final sorted = [..._store.bodyweightMeasurements]
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    return sorted;
  }

  @override
  Future<BodyweightMeasurement> logMeasurement({
    required String measuredAt,
    required double weightKg,
    String? notes,
  }) async {
    if (weightKg <= 0 || weightKg >= 1000) {
      throw const AppFailure(
        'invalid_weight',
        'Please enter a valid weight measurement.',
      );
    }
    _store.bodyweightMeasurements.removeWhere((m) => m.measuredAt == measuredAt);
    final created = BodyweightMeasurement(
      id: _store.next('bodyweight'),
      measuredAt: measuredAt,
      weightKg: weightKg,
      notes: notes,
      createdAt: DateTime.now(),
    );
    _store.bodyweightMeasurements.insert(0, created);
    return created;
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    _store.bodyweightMeasurements.removeWhere((m) => m.id == id);
  }
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._secureStore);
  final SecureSessionStore _secureStore;
  AuthSession? _memorySession;
  User? _registeredUser;
  String? _registeredPassword;
  static const _user = User(
    id: 'demo-user',
    username: 'demo',
    displayName: 'Demo Lifter',
    weightUnit: WeightUnit.lb,
  );

  @override
  Future<AuthSession> login(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final normalized = username.trim().toLowerCase();
    final user = normalized == 'demo' && password == 'transmute-demo'
        ? _user
        : normalized == _registeredUser?.username &&
              password == _registeredPassword
        ? _registeredUser
        : null;
    if (user == null) {
      throw const AppFailure(
        'invalid_credentials',
        'The demo username or password is incorrect.',
      );
    }
    final session = AuthSession(
      accessToken: 'mock-access',
      refreshToken: 'mock-refresh',
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      user: user,
    );
    _memorySession = session;
    try {
      await _secureStore.save(session);
    } catch (_) {
      // Unsigned native demo builds may lack Keychain access.
    }
    return session;
  }

  @override
  Future<AuthSession> register(
    String username,
    String password, {
    String? displayName,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.length < 3 ||
        normalized.length > 64 ||
        normalized.contains(' ')) {
      throw const AppFailure(
        'invalid_username',
        'Username must be 3–64 characters with no spaces.',
      );
    }
    if (password.length < 8 || password.length > 128) {
      throw const AppFailure(
        'invalid_password',
        'Password must be 8–128 characters.',
      );
    }
    if (normalized == 'demo' || normalized == _registeredUser?.username) {
      throw const AppFailure('username_taken', 'Username already taken.');
    }
    _registeredUser = User(
      id: 'mock-$normalized',
      username: normalized,
      displayName: displayName?.trim().isEmpty == false
          ? displayName!.trim()
          : normalized,
      weightUnit: WeightUnit.lb,
    );
    _registeredPassword = password;
    return login(normalized, password);
  }

  @override
  Future<void> logout() async {
    _memorySession = null;
    try {
      await _secureStore.clear();
    } catch (_) {}
  }

  @override
  Future<AuthSession?> restore() async {
    try {
      final stored = await _secureStore.read();
      if (stored != null && stored.expires.isAfter(DateTime.now())) {
        return AuthSession(
          accessToken: stored.access,
          refreshToken: stored.refresh,
          expiresAt: stored.expires,
          user: _memorySession?.user ?? _user,
        );
      }
    } catch (_) {}
    return _memorySession;
  }
}

class MockPlanRepository implements PlanRepository {
  MockPlanRepository(this._store);
  final MockStore _store;
  @override
  Future<WorkoutPlan> getPlan(String planId) async {
    final plan =
        _store.plans
            .where((plan) => plan.id == planId)
            .cast<WorkoutPlan?>()
            .firstOrNull ??
        (throw const AppFailure(
          'plan_not_found',
          'That workout plan is no longer available.',
        ));
    return WorkoutPlan(
      id: plan.id,
      name: plan.name,
      description: plan.description,
      updatedAt: plan.updatedAt,
      days: plan.days
          .map(
            (day) => WorkoutPlanDay(
              id: day.id,
              name: day.name,
              sortOrder: day.sortOrder,
              exercises: day.exercises
                  .map(
                    (row) => PlanExercise(
                      id: row.id,
                      exercise: row.exercise,
                      sortOrder: row.sortOrder,
                      targetSets: row.targetSets,
                      targetReps: row.targetReps,
                      trackingMode: row.trackingMode,
                      targetDurationSeconds: row.targetDurationSeconds,
                      targetWeightKg: row.targetWeightKg,
                      previousPerformance: _previous(row.exercise.id),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  PreviousPerformance? _previous(String exerciseId) {
    final matches =
        _store.completed
            .where(
              (session) =>
                  session.exercises.any((row) => row.exerciseId == exerciseId),
            )
            .toList()
          ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    if (matches.isEmpty) return null;
    final sets = matches.first.exercises
        .firstWhere((row) => row.exerciseId == exerciseId)
        .sets;
    if (sets.isEmpty) return null;
    final latest = sets.last;
    return PreviousPerformance(
      sessionId: matches.first.id,
      completedAt: matches.first.completedAt!,
      weightKg: latest.weightKg,
      reps: latest.reps,
    );
  }

  @override
  Future<List<WorkoutPlan>> listPlans() async =>
      [..._store.plans]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  WorkoutPlan _replace(WorkoutPlan next) {
    final index = _store.plans.indexWhere((plan) => plan.id == next.id);
    if (index < 0)
      throw const AppFailure(
        'plan_not_found',
        'That workout plan is no longer available.',
      );
    _store.plans[index] = next;
    return next;
  }

  WorkoutPlan _requirePlan(String planId) =>
      _store.plans
          .where((plan) => plan.id == planId)
          .cast<WorkoutPlan?>()
          .firstOrNull ??
      (throw const AppFailure(
        'plan_not_found',
        'That workout plan is no longer available.',
      ));

  @override
  Future<WorkoutPlan> createPlan(String name, {String? description}) async {
    if (name.trim().isEmpty)
      throw const AppFailure('invalid_plan_name', 'Give the plan a name.');
    final now = DateTime.now().toUtc();
    final plan = WorkoutPlan(
      id: _store.next('plan'),
      name: name.trim(),
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      updatedAt: now,
      days: const [],
    );
    _store.plans.insert(0, plan);
    return plan;
  }

  @override
  Future<AiWorkoutPlanDraft> generateAiWorkoutDraft(String prompt) async {
    if (prompt.trim().length < 12) {
      throw const AppFailure(
        'invalid_ai_prompt',
        'Describe the plan you want in at least 12 characters.',
      );
    }
    return const AiWorkoutPlanDraft(
      name: 'Assistant strength draft',
      description:
          'A reviewable mock draft. Adjust it after import before training.',
      days: [
        AiWorkoutDay(
          name: 'Upper strength',
          exercises: [
            AiWorkoutExercise(
              exerciseName: 'Barbell bench press',
              targetSets: 3,
              targetReps: 8,
            ),
            AiWorkoutExercise(
              exerciseName: 'Chest-supported row',
              targetSets: 3,
              targetReps: 10,
            ),
          ],
        ),
        AiWorkoutDay(
          name: 'Lower strength',
          exercises: [
            AiWorkoutExercise(
              exerciseName: 'Back squat',
              targetSets: 3,
              targetReps: 8,
            ),
            AiWorkoutExercise(
              exerciseName: 'Romanian deadlift',
              targetSets: 3,
              targetReps: 10,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<WorkoutPlan> importAiWorkoutPlan(AiWorkoutPlanDraft draft) async {
    if (draft.days.isEmpty || draft.days.any((day) => day.exercises.isEmpty)) {
      throw const AppFailure(
        'invalid_ai_plan',
        'An imported plan needs at least one training day and exercise.',
      );
    }
    final resolved = <String, Exercise>{};
    for (final exercise in draft.days.expand((day) => day.exercises)) {
      final source = _store.catalog
          .where(
            (item) =>
                item.name.toLowerCase() == exercise.exerciseName.toLowerCase(),
          )
          .cast<Exercise?>()
          .firstOrNull;
      if (source == null) {
        throw AppFailure(
          'ai_exercise_unresolved',
          'The plan assistant suggested “${exercise.exerciseName},” which could not be resolved. Generate the plan again.',
        );
      }
      resolved[exercise.exerciseName.toLowerCase()] = source;
    }
    final plan = await createPlan(draft.name, description: draft.description);
    for (final draftDay in draft.days) {
      final day = await addDay(plan.id, draftDay.name);
      for (final exercise in draftDay.exercises) {
        final source = resolved[exercise.exerciseName.toLowerCase()]!;
        final entry = await addExerciseToDay(plan.id, day.id, source.id);
        await updatePrescription(
          plan.id,
          day.id,
          entry.id,
          targetSets: exercise.targetSets,
          targetReps: exercise.targetReps ?? 10,
          targetWeightKg: exercise.targetWeightKg,
        );
      }
    }
    return getPlan(plan.id);
  }

  @override
  Future<WorkoutPlan> renamePlan(String planId, String name) async {
    if (name.trim().isEmpty)
      throw const AppFailure('invalid_plan_name', 'Give the plan a name.');
    final plan = _requirePlan(planId);
    return _replace(
      WorkoutPlan(
        id: plan.id,
        name: name.trim(),
        description: plan.description,
        updatedAt: DateTime.now().toUtc(),
        days: plan.days,
      ),
    );
  }

  @override
  Future<void> deletePlan(String planId) async {
    if (_store.active?.planId == planId)
      throw const AppFailure(
        'plan_active',
        'Finish or discard the active workout before deleting its plan.',
      );
    if (_store.completed.any((session) => session.planId == planId))
      throw const AppFailure(
        'plan_has_history',
        'This folder has workout history and cannot be deleted. Rename it to keep that history intact.',
      );
    final before = _store.plans.length;
    _store.plans.removeWhere((plan) => plan.id == planId);
    if (before == _store.plans.length)
      throw const AppFailure(
        'plan_not_found',
        'That workout plan is no longer available.',
      );
  }

  @override
  Future<WorkoutPlanDay> addDay(String planId, String name) async {
    if (name.trim().isEmpty)
      throw const AppFailure(
        'invalid_day_name',
        'Give the training day a name.',
      );
    final plan = _requirePlan(planId);
    final day = WorkoutPlanDay(
      id: _store.next('plan-day'),
      name: name.trim(),
      sortOrder: plan.days.length,
      exercises: const [],
    );
    _replace(
      WorkoutPlan(
        id: plan.id,
        name: plan.name,
        description: plan.description,
        updatedAt: DateTime.now().toUtc(),
        days: [...plan.days, day],
      ),
    );
    return day;
  }

  @override
  Future<WorkoutPlanDay> renameDay(
    String planId,
    String dayId,
    String name,
  ) async {
    if (name.trim().isEmpty)
      throw const AppFailure(
        'invalid_day_name',
        'Give the training day a name.',
      );
    final plan = _requirePlan(planId);
    late WorkoutPlanDay changed;
    final days = plan.days.map((day) {
      if (day.id != dayId) return day;
      changed = WorkoutPlanDay(
        id: day.id,
        name: name.trim(),
        sortOrder: day.sortOrder,
        exercises: day.exercises,
      );
      return changed;
    }).toList();
    _replace(
      WorkoutPlan(
        id: plan.id,
        name: plan.name,
        description: plan.description,
        updatedAt: DateTime.now().toUtc(),
        days: days,
      ),
    );
    return changed;
  }

  @override
  Future<void> deleteDay(String planId, String dayId) async {
    final plan = _requirePlan(planId);
    if (_store.active?.planDayId == dayId)
      throw const AppFailure(
        'day_active',
        'Finish or discard the active workout before deleting this routine.',
      );
    if (_store.completed.any((session) => session.planDayId == dayId))
      throw const AppFailure(
        'day_has_history',
        'This routine has workout history and cannot be deleted. Rename it to keep that history intact.',
      );
    final days = plan.days.where((day) => day.id != dayId).toList();
    if (days.length == plan.days.length)
      throw const AppFailure(
        'day_not_found',
        'That training day is unavailable.',
      );
    _replace(
      WorkoutPlan(
        id: plan.id,
        name: plan.name,
        description: plan.description,
        updatedAt: DateTime.now().toUtc(),
        days: [
          for (var i = 0; i < days.length; i++)
            WorkoutPlanDay(
              id: days[i].id,
              name: days[i].name,
              sortOrder: i,
              exercises: days[i].exercises,
            ),
        ],
      ),
    );
  }

  @override
  Future<WorkoutPlanDay> reorderDay(
    String planId,
    String dayId,
    ReorderDirection direction,
  ) async {
    final plan = _requirePlan(planId);
    final days = [...plan.days]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final from = days.indexWhere((day) => day.id == dayId);
    if (from < 0)
      throw const AppFailure('day_not_found', 'That routine is unavailable.');
    final to = from + (direction == ReorderDirection.up ? -1 : 1);
    if (to < 0 || to >= days.length) return days[from];
    final moved = days.removeAt(from);
    days.insert(to, moved);
    final ordered = [
      for (var index = 0; index < days.length; index++)
        WorkoutPlanDay(
          id: days[index].id,
          name: days[index].name,
          sortOrder: index,
          exercises: days[index].exercises,
        ),
    ];
    _replace(
      WorkoutPlan(
        id: plan.id,
        name: plan.name,
        description: plan.description,
        updatedAt: DateTime.now().toUtc(),
        days: ordered,
      ),
    );
    return ordered.firstWhere((day) => day.id == dayId);
  }

  WorkoutPlanDay _day(WorkoutPlan plan, String id) =>
      plan.days
          .where((day) => day.id == id)
          .cast<WorkoutPlanDay?>()
          .firstOrNull ??
      (throw const AppFailure(
        'day_not_found',
        'That training day is unavailable.',
      ));

  @override
  Future<PlanExercise> addExerciseToDay(
    String planId,
    String dayId,
    String exerciseId,
  ) async {
    final plan = _requirePlan(planId);
    final day = _day(plan, dayId);
    if (day.exercises.any((entry) => entry.exercise.id == exerciseId))
      throw const AppFailure(
        'duplicate_exercise',
        'That exercise is already in this training day.',
      );
    final exercise =
        _store.catalog
            .where((item) => item.id == exerciseId)
            .cast<Exercise?>()
            .firstOrNull ??
        (throw const AppFailure(
          'exercise_not_found',
          'That exercise is unavailable.',
        ));
    final entry = PlanExercise(
      id: _store.next('plan-exercise'),
      exercise: exercise,
      sortOrder: day.exercises.length,
      targetSets: 3,
      targetReps: 10,
    );
    _writeDay(
      plan,
      dayId,
      WorkoutPlanDay(
        id: day.id,
        name: day.name,
        sortOrder: day.sortOrder,
        exercises: [...day.exercises, entry],
      ),
    );
    return entry;
  }

  void _writeDay(WorkoutPlan plan, String dayId, WorkoutPlanDay replacement) =>
      _replace(
        WorkoutPlan(
          id: plan.id,
          name: plan.name,
          description: plan.description,
          updatedAt: DateTime.now().toUtc(),
          days: plan.days
              .map((day) => day.id == dayId ? replacement : day)
              .toList(),
        ),
      );

  @override
  Future<void> removeExerciseFromDay(
    String planId,
    String dayId,
    String planExerciseId,
  ) async {
    final plan = _requirePlan(planId);
    final day = _day(plan, dayId);
    final entries = day.exercises
        .where((entry) => entry.id != planExerciseId)
        .toList();
    if (entries.length == day.exercises.length)
      throw const AppFailure(
        'plan_exercise_not_found',
        'That prescription is unavailable.',
      );
    _writeDay(
      plan,
      dayId,
      WorkoutPlanDay(
        id: day.id,
        name: day.name,
        sortOrder: day.sortOrder,
        exercises: [
          for (var i = 0; i < entries.length; i++)
            PlanExercise(
              id: entries[i].id,
              exercise: entries[i].exercise,
              sortOrder: i,
              targetSets: entries[i].targetSets,
              targetReps: entries[i].targetReps,
              trackingMode: entries[i].trackingMode,
              targetDurationSeconds: entries[i].targetDurationSeconds,
              targetWeightKg: entries[i].targetWeightKg,
            ),
        ],
      ),
    );
  }

  @override
  Future<PlanExercise> reorderExerciseInDay(
    String planId,
    String dayId,
    String planExerciseId,
    ReorderDirection direction,
  ) async {
    final plan = _requirePlan(planId);
    final day = _day(plan, dayId);
    final entries = [...day.exercises]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final from = entries.indexWhere((entry) => entry.id == planExerciseId);
    if (from < 0)
      throw const AppFailure(
        'plan_exercise_not_found',
        'That prescription is unavailable.',
      );
    final to = from + (direction == ReorderDirection.up ? -1 : 1);
    if (to < 0 || to >= entries.length) return entries[from];
    final moved = entries.removeAt(from);
    entries.insert(to, moved);
    final ordered = [
      for (var index = 0; index < entries.length; index++)
        PlanExercise(
          id: entries[index].id,
          exercise: entries[index].exercise,
          sortOrder: index,
          targetSets: entries[index].targetSets,
          targetReps: entries[index].targetReps,
          trackingMode: entries[index].trackingMode,
          targetDurationSeconds: entries[index].targetDurationSeconds,
          targetWeightKg: entries[index].targetWeightKg,
          previousPerformance: entries[index].previousPerformance,
        ),
    ];
    _writeDay(
      plan,
      dayId,
      WorkoutPlanDay(
        id: day.id,
        name: day.name,
        sortOrder: day.sortOrder,
        exercises: ordered,
      ),
    );
    return ordered.firstWhere((entry) => entry.id == planExerciseId);
  }

  @override
  Future<PlanExercise> updatePrescription(
    String planId,
    String dayId,
    String planExerciseId, {
    required int targetSets,
    required int targetReps,
    ExerciseTrackingMode trackingMode = ExerciseTrackingMode.reps,
    int? targetDurationSeconds,
    double? targetWeightKg,
  }) async {
    if (targetSets < 1 ||
        targetSets > 20 ||
        (trackingMode == ExerciseTrackingMode.reps &&
            (targetReps < 1 || targetReps > 50)) ||
        (trackingMode == ExerciseTrackingMode.timed &&
            (targetDurationSeconds == null ||
                targetDurationSeconds < 1 ||
                targetDurationSeconds > 86400)))
      throw const AppFailure(
        'invalid_prescription',
        'Use 1–20 sets and a valid rep target or duration.',
      );
    final plan = _requirePlan(planId);
    final day = _day(plan, dayId);
    late PlanExercise changed;
    final entries = day.exercises.map((entry) {
      if (entry.id != planExerciseId) return entry;
      changed = PlanExercise(
        id: entry.id,
        exercise: entry.exercise,
        sortOrder: entry.sortOrder,
        targetSets: targetSets,
        targetReps: targetReps,
        trackingMode: trackingMode,
        targetDurationSeconds: targetDurationSeconds,
        targetWeightKg: targetWeightKg,
        previousPerformance: entry.previousPerformance,
      );
      return changed;
    }).toList();
    _writeDay(
      plan,
      dayId,
      WorkoutPlanDay(
        id: day.id,
        name: day.name,
        sortOrder: day.sortOrder,
        exercises: entries,
      ),
    );
    return changed;
  }

  @override
  Future<Exercise> createExercise({
    required String name,
    required String category,
    String? muscleGroup,
  }) async {
    if (name.trim().isEmpty)
      throw const AppFailure(
        'invalid_exercise_name',
        'Give the exercise a name.',
      );
    final exercise = Exercise(
      id: _store.next('exercise'),
      name: name.trim(),
      category: category,
      muscleGroup: muscleGroup?.trim().isEmpty == true
          ? null
          : muscleGroup?.trim(),
    );
    _store.catalog.add(exercise);
    return exercise;
  }

  @override
  Future<Exercise> updateExerciseDemo(
    String exerciseId, {
    required String demoUrl,
    String? sourceName,
  }) async {
    final parsed = Uri.tryParse(demoUrl);
    if (parsed == null ||
        !(parsed.scheme == 'https' || parsed.scheme == 'http') ||
        parsed.host.isEmpty) {
      throw const AppFailure(
        'invalid_demo_url',
        'Enter a valid public demo URL.',
      );
    }
    final existing = _store.catalog
        .where((exercise) => exercise.id == exerciseId)
        .cast<Exercise?>()
        .firstOrNull;
    if (existing == null) {
      throw const AppFailure('exercise_not_found', 'Exercise not found.');
    }
    final updated = Exercise(
      id: existing.id,
      name: existing.name,
      category: existing.category,
      muscleGroup: existing.muscleGroup,
      demoUrl: demoUrl,
      demoSourceName: sourceName?.trim().isEmpty == true
          ? null
          : sourceName?.trim(),
    );
    final catalogIndex = _store.catalog.indexWhere(
      (exercise) => exercise.id == exerciseId,
    );
    _store.catalog[catalogIndex] = updated;
    for (var planIndex = 0; planIndex < _store.plans.length; planIndex++) {
      final plan = _store.plans[planIndex];
      _store.plans[planIndex] = WorkoutPlan(
        id: plan.id,
        name: plan.name,
        description: plan.description,
        updatedAt: plan.updatedAt,
        days: plan.days
            .map(
              (day) => WorkoutPlanDay(
                id: day.id,
                name: day.name,
                sortOrder: day.sortOrder,
                exercises: day.exercises
                    .map(
                      (entry) => PlanExercise(
                        id: entry.id,
                        exercise: entry.exercise.id == exerciseId
                            ? updated
                            : entry.exercise,
                        sortOrder: entry.sortOrder,
                        targetSets: entry.targetSets,
                        targetReps: entry.targetReps,
                        trackingMode: entry.trackingMode,
                        targetDurationSeconds: entry.targetDurationSeconds,
                        targetWeightKg: entry.targetWeightKg,
                        previousPerformance: entry.previousPerformance,
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      );
    }
    return updated;
  }

  @override
  Future<List<CatalogExercise>> searchCalistreeExercises(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.length < 2) return const [];
    const catalog = [
      CatalogExercise(name: 'Barbell bench press', slug: 'barbell-bench-press'),
      CatalogExercise(name: 'Push-up', slug: 'push-up'),
      CatalogExercise(name: 'Pull-up', slug: 'pull-up'),
      CatalogExercise(name: 'Goblet squat', slug: 'goblet-squat'),
    ];
    return catalog
        .where((item) => item.name.toLowerCase().contains(needle))
        .toList();
  }

  @override
  Future<PlanExercise> importCalistreeExerciseToDay(
    String planId,
    String dayId,
    String slug, {
    int targetSets = 3,
    int? targetReps,
    double? targetWeightKg,
  }) async {
    const catalog = {
      'barbell-bench-press': ('Barbell bench press', 'strength', 'Chest'),
      'push-up': ('Push-up', 'strength', 'Chest'),
      'pull-up': ('Pull-up', 'strength', 'Back'),
      'goblet-squat': ('Goblet squat', 'strength', 'Quads'),
    };
    final source = catalog[slug];
    if (source == null) {
      throw const AppFailure(
        'catalog_exercise_not_found',
        'No matching exercise was found.',
      );
    }
    final existing = _store.catalog
        .where((item) => item.name.toLowerCase() == source.$1.toLowerCase())
        .cast<Exercise?>()
        .firstOrNull;
    final exercise =
        existing ??
        await createExercise(
          name: source.$1,
          category: source.$2,
          muscleGroup: source.$3,
        );
    final entry = await addExerciseToDay(planId, dayId, exercise.id);
    return updatePrescription(
      planId,
      dayId,
      entry.id,
      targetSets: targetSets,
      targetReps: targetReps ?? entry.targetReps,
      targetWeightKg: targetWeightKg,
    );
  }

  @override
  Future<List<Exercise>> searchExercises(String query) async {
    final needle = query.trim().toLowerCase();
    return _store.catalog
        .where(
          (exercise) =>
              needle.isEmpty || exercise.name.toLowerCase().contains(needle),
        )
        .take(50)
        .toList();
  }

  RoutineShareSnapshot _shareSnapshot(WorkoutPlan plan, WorkoutPlanDay day) =>
      RoutineShareSnapshot(
        routineName: day.name,
        folderName: plan.name,
        ownerName: 'Demo Alchemist',
        ownerUsername: 'demo',
        exercises: day.exercises
            .map(
              (entry) => RoutineShareExercise(
                exerciseId: entry.exercise.id,
                name: entry.exercise.name,
                category: entry.exercise.category,
                muscleGroup: entry.exercise.muscleGroup,
                targetSets: entry.targetSets,
                targetReps: entry.targetReps,
                trackingMode: entry.trackingMode,
                targetDurationSeconds: entry.targetDurationSeconds,
                targetWeightKg: entry.targetWeightKg,
              ),
            )
            .toList(),
      );

  RoutineShare _shareWithStatus(RoutineShare share) {
    if (share.status != RoutineShareStatus.active ||
        !share.expiresAt.isBefore(DateTime.now().toUtc())) {
      return share;
    }
    return RoutineShare(
      id: share.id,
      token: share.token,
      routineDayId: share.routineDayId,
      status: RoutineShareStatus.expired,
      createdAt: share.createdAt,
      expiresAt: share.expiresAt,
      snapshot: share.snapshot,
    );
  }

  @override
  Future<List<RoutineShare>> listRoutineShares(String routineDayId) async =>
      _store.routineShares
          .where((share) => share.routineDayId == routineDayId)
          .map(_shareWithStatus)
          .toList()
        ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

  @override
  Future<RoutineShare> createRoutineShare(String routineDayId) async {
    final plan = _store.plans
        .where(
          (candidate) => candidate.days.any((day) => day.id == routineDayId),
        )
        .cast<WorkoutPlan?>()
        .firstOrNull;
    if (plan == null) {
      throw const AppFailure(
        'routine_not_found',
        'That routine is unavailable.',
      );
    }
    final day = _day(plan, routineDayId);
    if (day.exercises.isEmpty) {
      throw const AppFailure(
        'routine_share_empty',
        'Add at least one exercise before sharing this routine.',
      );
    }
    final now = DateTime.now().toUtc();
    final share = RoutineShare(
      id: _store.next('routine-share'),
      token: _store.next('share-token'),
      routineDayId: day.id,
      status: RoutineShareStatus.active,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 30)),
      snapshot: _shareSnapshot(plan, day),
    );
    _store.routineShares.add(share);
    return share;
  }

  @override
  Future<void> revokeRoutineShare(String token) async {
    final index = _store.routineShares.indexWhere(
      (share) => share.token == token,
    );
    if (index < 0) {
      throw const AppFailure(
        'routine_share_not_found',
        'That routine link is unavailable.',
      );
    }
    final share = _store.routineShares[index];
    _store.routineShares[index] = RoutineShare(
      id: share.id,
      token: share.token,
      routineDayId: share.routineDayId,
      status: RoutineShareStatus.revoked,
      createdAt: share.createdAt,
      expiresAt: share.expiresAt,
      snapshot: share.snapshot,
    );
  }

  @override
  Future<RoutineShareSnapshot> getRoutineShare(String token) async {
    final share = _store.routineShares
        .where((candidate) => candidate.token == token)
        .cast<RoutineShare?>()
        .firstOrNull;
    if (share == null) {
      throw const AppFailure(
        'routine_share_not_found',
        'This routine link is unavailable.',
      );
    }
    final current = _shareWithStatus(share);
    if (current.status == RoutineShareStatus.revoked) {
      throw const AppFailure(
        'routine_share_revoked',
        'This routine link was revoked by its owner.',
      );
    }
    if (current.status == RoutineShareStatus.expired) {
      throw const AppFailure(
        'routine_share_expired',
        'This routine link has expired.',
      );
    }
    return current.snapshot;
  }

  @override
  Future<WorkoutPlanDay> importRoutineShare(
    String token, {
    required String planId,
    String? name,
  }) async {
    final snapshot = await getRoutineShare(token);
    final plan = _requirePlan(planId);
    final routineName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : snapshot.routineName;
    if (routineName.length < 2 || routineName.length > 32) {
      throw const AppFailure(
        'invalid_day_name',
        'Use 2–32 characters for the routine name.',
      );
    }
    final exercises = <PlanExercise>[];
    for (final entry in snapshot.exercises) {
      final exercise = _store.catalog
          .where((candidate) => candidate.id == entry.exerciseId)
          .cast<Exercise?>()
          .firstOrNull;
      if (exercise == null) {
        throw AppFailure(
          'routine_share_exercise_unavailable',
          '“${entry.name}” is no longer available to import.',
        );
      }
      exercises.add(
        PlanExercise(
          id: _store.next('plan-exercise'),
          exercise: exercise,
          sortOrder: exercises.length,
          targetSets: entry.targetSets,
          targetReps: entry.targetReps,
          trackingMode: entry.trackingMode,
          targetDurationSeconds: entry.targetDurationSeconds,
          targetWeightKg: entry.targetWeightKg,
        ),
      );
    }
    final day = WorkoutPlanDay(
      id: _store.next('plan-day'),
      name: routineName,
      sortOrder: plan.days.length,
      exercises: exercises,
    );
    _replace(
      WorkoutPlan(
        id: plan.id,
        name: plan.name,
        description: plan.description,
        updatedAt: DateTime.now().toUtc(),
        days: [...plan.days, day],
      ),
    );
    return day;
  }
}

PersonalRecord? _mockPersonalRecord(
  String exerciseName, {
  required double currentWeightKg,
  required int currentReps,
  required double previousWeightKg,
  required int previousReps,
}) {
  final weighted = currentWeightKg > 0;
  if (weighted != (previousWeightKg > 0)) return null;
  final currentScore = weighted
      ? currentWeightKg * (1 + currentReps / 30)
      : currentReps.toDouble();
  final previousScore = weighted
      ? previousWeightKg * (1 + previousReps / 30)
      : previousReps.toDouble();
  if (currentScore <= previousScore) return null;
  return PersonalRecord(
    exerciseName: exerciseName,
    kind: weighted
        ? PersonalRecordKind.estimatedOneRepMax
        : PersonalRecordKind.reps,
    currentReps: currentReps,
    currentWeightKg: currentWeightKg,
    previousReps: previousReps,
    previousWeightKg: previousWeightKg,
  );
}

class MockExerciseRankRepository implements ExerciseRankRepository {
  MockExerciseRankRepository(this._store);
  final MockStore _store;

  @override
  Future<List<ExerciseRank>> listRanks({
    String query = '',
    ExerciseTrackingMode? mode,
  }) async {
    final normalized = query.trim().toLowerCase();
    return _store.catalog
        .where(
          (exercise) =>
              normalized.isEmpty ||
              exercise.name.toLowerCase().contains(normalized),
        )
        .map((exercise) => _rankFor(exercise, mode))
        .whereType<ExerciseRank>()
        .toList()
      ..sort((left, right) {
        if (left.isRanked != right.isRanked) return left.isRanked ? -1 : 1;
        return left.exercise.name.compareTo(right.exercise.name);
      });
  }

  @override
  Future<ExerciseRank> getRank(String exerciseId) async {
    final exercise = _store.catalog
        .where((item) => item.id == exerciseId)
        .firstOrNull;
    if (exercise == null)
      throw const AppFailure('not_found', 'Exercise not found.');
    return _rankFor(exercise, null)!;
  }

  @override
  ExerciseRank preview({
    required Exercise exercise,
    required ExerciseTrackingMode mode,
    required double value,
    double? baselineValue,
  }) => _preview(exercise, mode, value, baselineValue);

  @override
  Future<RankOverview> getOverview() async {
    final ranks = await listRanks();
    const mapped = <String, (String label, String region, String side)>{
      'bench': ('Chest', 'chest', 'front'),
      'row': ('Back', 'back', 'back'),
      'press': ('Shoulders', 'deltoids', 'front'),
      'squat': ('Quads', 'quadriceps', 'front'),
      'rdl': ('Hamstrings', 'hamstrings', 'back'),
      'calf': ('Calves', 'calves', 'back'),
      'barbell-wrist-curl': ('Arms', 'forearms', 'front'),
      'barbell-reverse-curl': ('Arms', 'forearms', 'front'),
    };
    final groups = <String, List<ExerciseRank>>{};
    for (final rank in ranks.where((item) => item.isRanked)) {
      final definition = mapped[rank.exercise.id];
      if (definition != null)
        groups.putIfAbsent(definition.$1, () => []).add(rank);
    }
    final result = <MuscleRank>[];
    for (final entry in groups.entries) {
      final definition = mapped.values.firstWhere(
        (item) => item.$1 == entry.key,
      );
      final strongest = [...entry.value]
        ..sort(
          (a, b) => (b.bestValue! / b.baselineValue!).compareTo(
            a.bestValue! / a.baselineValue!,
          ),
        );
      final selected = strongest.take(2).toList();
      final score =
          selected
              .map((item) => item.bestValue! / item.baselineValue!)
              .reduce((a, b) => a + b) /
          selected.length;
      final tier = _preview(
        selected.first.exercise,
        selected.first.trackingMode!,
        score,
        1,
      ).tier;
      result.add(
        MuscleRank(
          groupId: entry.key.toLowerCase(),
          label: definition.$1,
          regionId: definition.$2,
          bodySide: definition.$3,
          eligibleExerciseCount: entry.value.length,
          score: score,
          tier: tier,
          evidenceExerciseIds: selected
              .map((item) => item.exercise.id)
              .toList(),
        ),
      );
    }
    final eligible = ranks
        .where((item) => item.isRanked && mapped.containsKey(item.exercise.id))
        .length;
    final placement = eligible >= 10 && result.length >= 5;
    final score = placement
        ? result.map((item) => item.score!).reduce((a, b) => a + b) /
              result.length
        : null;
    return RankOverview(
      overall: OverallRank(
        eligibleExerciseCount: eligible,
        mappedGroupCount: result.length,
        placementEligible: placement,
        score: score,
        tier: score == null
            ? null
            : _preview(
                ranks.first.exercise,
                ExerciseTrackingMode.reps,
                score,
                1,
              ).tier,
        evidenceExerciseIds: result
            .expand((item) => item.evidenceExerciseIds)
            .toList(),
      ),
      groups: result,
      lastSessionChanges: const [],
    );
  }

  @override
  Future<List<OverallRankHistoryPoint>> getHistory() async {
    final overview = await getOverview();
    if (overview.overall.score == null) return const [];
    return [
      OverallRankHistoryPoint(
        calculatedAt: DateTime.now().toUtc(),
        score: overview.overall.score,
        tier: overview.overall.tier,
        eligibleExerciseCount: overview.overall.eligibleExerciseCount,
      ),
    ];
  }

  @override
  Future<RankAnalysisData> getAnalysis() async {
    final allRanks = await listRanks();
    final ranked = allRanks.where((r) => r.isRanked).toList();

    // Group by category
    final byCat = <String, List<ExerciseRank>>{};
    for (final r in allRanks) {
      byCat.putIfAbsent(r.exercise.category, () => []).add(r);
    }

    final categories = byCat.entries.map((e) {
      final inCat = e.value;
      final rankedInCat = inCat.where((r) => r.isRanked).toList();
      double? avgRatio;
      ExerciseRankTier? avgTier;
      if (rankedInCat.isNotEmpty) {
        final sum = rankedInCat.fold<double>(
          0,
          (prev, r) => prev + (r.bestValue! / r.baselineValue!),
        );
        avgRatio = sum / rankedInCat.length;
        avgTier = _preview(
          rankedInCat.first.exercise,
          rankedInCat.first.trackingMode ?? ExerciseTrackingMode.reps,
          avgRatio,
          1,
        ).tier;
      }
      return RankCategorySummary(
        category: e.key,
        rankedCount: rankedInCat.length,
        totalCount: inCat.length,
        averageRatio: avgRatio,
        averageTier: avgTier,
      );
    }).toList()
      ..sort((a, b) => a.category.compareTo(b.category));

    // Tier distribution
    final byTier = <ExerciseRankTier, int>{};
    for (final r in ranked) {
      if (r.tier != null) {
        byTier[r.tier!] = (byTier[r.tier!] ?? 0) + 1;
      }
    }
    final tierDistribution = byTier.entries
        .map((e) => RankTierCount(tier: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.tier.index.compareTo(b.tier.index));

    // Upcoming targets
    final withNext = ranked.where((r) => r.nextThreshold != null).toList()
      ..sort((a, b) => (b.progressPoints ?? 0).compareTo(a.progressPoints ?? 0));

    final upcomingTargets = withNext.take(6).map((r) => RankUpcomingTarget(
      exerciseId: r.exercise.id,
      exerciseName: r.exercise.name,
      category: r.exercise.category,
      muscleGroup: r.exercise.muscleGroup,
      trackingMode: r.trackingMode ?? ExerciseTrackingMode.reps,
      metric: r.metric ?? ExerciseRankMetric.estimatedOneRepMaxKg,
      currentValue: r.bestValue ?? 0,
      baselineValue: r.baselineValue ?? 0,
      tier: r.tier ?? ExerciseRankTier.bronze,
      progressPoints: r.progressPoints ?? 0,
      nextThreshold: r.nextThreshold,
    )).toList();

    return RankAnalysisData(
      categories: categories,
      tierDistribution: tierDistribution,
      weeklyRankUps: const [],
      upcomingTargets: upcomingTargets,
    );
  }

  ExerciseRank? _rankFor(
    Exercise exercise,
    ExerciseTrackingMode? requestedMode,
  ) {
    final samples =
        <({WorkoutSession session, SessionExercise row, LoggedSet set})>[];
    for (final session in _store.completed) {
      if (session.workingSetCount < 3) continue;
      for (final row in session.exercises.where(
        (row) => row.exerciseId == exercise.id,
      )) {
        for (final set in row.sets.where((set) => !set.isWarmup)) {
          final mode = set.durationSeconds == null
              ? ExerciseTrackingMode.reps
              : ExerciseTrackingMode.timed;
          if (requestedMode == null || requestedMode == mode)
            samples.add((session: session, row: row, set: set));
        }
      }
    }
    if (samples.isEmpty) return ExerciseRank(exercise: exercise);
    final mode = samples.first.set.durationSeconds == null
        ? ExerciseTrackingMode.reps
        : ExerciseTrackingMode.timed;
    final metric = mode == ExerciseTrackingMode.timed
        ? ExerciseRankMetric.maxDurationSeconds
        : samples.any((item) => item.set.weightKg > 0)
        ? ExerciseRankMetric.estimatedOneRepMaxKg
        : ExerciseRankMetric.maxReps;
    double valueOf(LoggedSet set) => switch (metric) {
      ExerciseRankMetric.maxDurationSeconds => set.durationSeconds!.toDouble(),
      ExerciseRankMetric.estimatedOneRepMaxKg =>
        set.weightKg * (1 + (set.reps.clamp(1, 12)) / 30),
      ExerciseRankMetric.maxReps => set.reps.toDouble(),
    };
    final perSession =
        <String, ({DateTime date, double value, String setId})>{};
    for (final item in samples) {
      if (metric == ExerciseRankMetric.estimatedOneRepMaxKg &&
          item.set.weightKg <= 0)
        continue;
      if (metric == ExerciseRankMetric.maxReps && item.set.weightKg > 0)
        continue;
      final value = valueOf(item.set);
      final prior = perSession[item.session.id];
      if (prior == null || value > prior.value)
        perSession[item.session.id] = (
          date: item.session.completedAt!,
          value: value,
          setId: item.set.id,
        );
    }
    final ordered = perSession.entries.toList()
      ..sort((left, right) => left.value.date.compareTo(right.value.date));
    final dates = <String>{};
    final foundations = <double>[];
    for (final item in ordered) {
      final date = item.value.date.toIso8601String().substring(0, 10);
      if (dates.add(date)) foundations.add(item.value.value);
      if (foundations.length == 2) break;
    }
    final best = perSession.values.fold(
      0.0,
      (best, item) => item.value > best ? item.value : best,
    );
    final baseline = foundations.length == 2
        ? foundations.reduce((a, b) => a > b ? a : b)
        : null;
    final preview = _preview(exercise, mode, best, baseline);
    return ExerciseRank(
      exercise: preview.exercise,
      trackingMode: mode,
      metric: metric,
      baselineValue: preview.baselineValue,
      bestValue: best,
      tier: preview.tier,
      progressPoints: preview.progressPoints,
      nextThreshold: preview.nextThreshold,
      ruleVersion: 1,
      evidence: ordered
          .map(
            (item) => ExerciseRankEvidence(
              sessionId: item.key,
              completedAt: item.value.date,
              value: item.value.value,
            ),
          )
          .toList(),
    );
  }
}

ExerciseRank _preview(
  Exercise exercise,
  ExerciseTrackingMode mode,
  double value,
  double? baseline,
) {
  final reference = baseline ?? value;
  final ratio = value / reference;
  const levels = <(ExerciseRankTier, double, double?)>[
    (ExerciseRankTier.bronze, 1, 1.05),
    (ExerciseRankTier.silver, 1.05, 1.15),
    (ExerciseRankTier.gold, 1.15, 1.30),
    (ExerciseRankTier.platinum, 1.30, 1.50),
    (ExerciseRankTier.transmuted, 1.50, null),
  ];
  final level = levels.reversed.firstWhere((item) => ratio >= item.$2);
  final points = level.$3 == null
      ? 100
      : (100 * (ratio - level.$2) / (level.$3! - level.$2)).floor().clamp(
          0,
          99,
        );
  return ExerciseRank(
    exercise: exercise,
    trackingMode: mode,
    metric: mode == ExerciseTrackingMode.timed
        ? ExerciseRankMetric.maxDurationSeconds
        : ExerciseRankMetric.estimatedOneRepMaxKg,
    baselineValue: baseline,
    bestValue: value,
    tier: baseline == null ? null : level.$1,
    progressPoints: baseline == null ? null : points,
    nextThreshold: baseline == null || level.$3 == null
        ? null
        : baseline * level.$3!,
    ruleVersion: 1,
  );
}

class MockQuickAddRepository implements QuickAddRepository {
  MockQuickAddRepository(this._store);
  final MockStore _store;

  @override
  Future<void> create({
    required String exerciseId,
    required WeightUnit weightUnit,
    double? weightKg,
    int? reps,
    int? durationSeconds,
  }) async {
    final exercise = _store.catalog
        .where((item) => item.id == exerciseId)
        .firstOrNull;
    if (exercise == null) {
      throw const AppFailure(
        'exercise_not_found',
        'That exercise is unavailable.',
      );
    }
    final now = DateTime.now().toUtc();
    final startedAt = durationSeconds == null
        ? now
        : now.subtract(Duration(seconds: durationSeconds));
    final sessionId = _store.next('quick-session');
    final exerciseIdInSession = _store.next('quick-session-exercise');
    _store.completed.insert(
      0,
      WorkoutSession(
        id: sessionId,
        planId: null,
        planName: 'Quick Add',
        planDayId: null,
        planDayName: 'Quick Add',
        origin: WorkoutSessionOrigin.quickAdd,
        status: SessionStatus.completed,
        startedAt: startedAt,
        completedAt: now,
        updatedAt: now,
        exercises: [
          SessionExercise(
            id: exerciseIdInSession,
            exerciseId: exercise.id,
            name: exercise.name,
            muscleGroup: exercise.muscleGroup,
            sortOrder: 0,
            targetSets: 1,
            targetReps: reps ?? 1,
            sets: [
              LoggedSet(
                id: _store.next('quick-set'),
                sessionExerciseId: exerciseIdInSession,
                setOrder: 1,
                weightKg: weightKg ?? 0,
                reps: reps ?? 0,
                durationSeconds: durationSeconds,
                completedAt: now,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MockSessionRepository implements SessionRepository {
  MockSessionRepository(this._store, {this.failFirstCreateSet = false});
  final MockStore _store;
  final bool failFirstCreateSet;
  bool _hasFailed = false;

  WorkoutSession _requireActive(String id) {
    final session = _store.active;
    if (session == null ||
        session.id != id ||
        session.status != SessionStatus.active)
      throw const AppFailure(
        'session_not_active',
        'This workout is no longer active.',
      );
    return session;
  }

  @override
  Future<WorkoutSession?> activeSession() async => _store.active;
  @override
  Future<WorkoutSession> getSession(String id) async {
    if (_store.active?.id == id) return _store.active!;
    return _store.completed
            .where((session) => session.id == id)
            .cast<WorkoutSession?>()
            .firstOrNull ??
        (throw const AppFailure(
          'session_not_found',
          'That workout is unavailable.',
        ));
  }

  @override
  Future<WorkoutSession> startSession(
    String planId, [
    String? planDayId,
  ]) async {
    if (_store.active != null)
      throw AppFailure(
        'active_session_exists',
        'Resume your existing workout.',
        activeSessionId: _store.active!.id,
      );
    final plan = await MockPlanRepository(_store).getPlan(planId);
    final day =
        plan.days
            .where((day) => day.id == (planDayId ?? plan.days.firstOrNull?.id))
            .cast<WorkoutPlanDay?>()
            .firstOrNull ??
        (throw const AppFailure(
          'day_not_found',
          'That training day is unavailable.',
        ));
    final now = DateTime.now().toUtc();
    List<PreviousPerformance> previousFor(PlanExercise prescription) {
      final completed = [..._store.completed]
        ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
      final timed = prescription.trackingMode == ExerciseTrackingMode.timed;
      for (final session in completed) {
        final prior = session.exercises
            .where(
              (exercise) => exercise.exerciseId == prescription.exercise.id,
            )
            .firstOrNull;
        if (prior == null) continue;
        final comparable = prior.sets
            .where(
              (set) => !set.isWarmup && (set.durationSeconds != null) == timed,
            )
            .toList();
        if (comparable.isEmpty) continue;
        return [
          for (var index = 0; index < comparable.length; index += 1)
            PreviousPerformance(
              sessionId: session.id,
              completedAt: session.completedAt ?? session.startedAt,
              weightKg: comparable[index].weightKg,
              reps: comparable[index].reps,
              durationSeconds: comparable[index].durationSeconds,
              setOrder: index + 1,
            ),
        ];
      }
      return timed || prescription.previousPerformance == null
          ? const []
          : [prescription.previousPerformance!];
    }

    _store.active = WorkoutSession(
      id: _store.next('session'),
      planId: plan.id,
      planName: plan.name,
      planDayId: day.id,
      planDayName: day.name,
      status: SessionStatus.active,
      startedAt: now,
      updatedAt: now,
      exercises: day.exercises.map((row) {
        final previous = previousFor(row);
        return SessionExercise(
          id: _store.next('session-exercise'),
          exerciseId: row.exercise.id,
          name: row.exercise.name,
          muscleGroup: row.exercise.muscleGroup,
          demoUrl: row.exercise.demoUrl,
          demoSourceName: row.exercise.demoSourceName,
          sortOrder: row.sortOrder,
          targetSets: row.targetSets,
          targetReps: row.targetReps,
          trackingMode: row.trackingMode,
          targetDurationSeconds: row.targetDurationSeconds,
          targetWeightKg: row.targetWeightKg,
          previousPerformance: previous.lastOrNull,
          previousPerformances: previous,
          sets: const [],
        );
      }).toList(),
    );
    return _store.active!;
  }

  @override
  Future<WorkoutSession> startFreeformSession() async {
    if (_store.active != null) {
      throw AppFailure(
        'active_session_exists',
        'Resume your existing workout.',
        activeSessionId: _store.active!.id,
      );
    }
    final now = DateTime.now().toUtc();
    return _store.active = WorkoutSession(
      id: _store.next('session'),
      planId: null,
      planName: 'Empty Workout',
      planDayId: null,
      planDayName: 'Freeform',
      origin: WorkoutSessionOrigin.freeform,
      status: SessionStatus.active,
      startedAt: now,
      updatedAt: now,
      exercises: const [],
    );
  }

  @override
  Future<WorkoutSession> updateRest(String id, DateTime? restEndsAt) async {
    final session = _requireActive(id);
    return _store.active = session.copyWith(
      restEndsAt: restEndsAt,
      clearRest: restEndsAt == null,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<SessionExercise> addExercise(
    String sessionId,
    String exerciseId,
  ) async {
    final session = _requireActive(sessionId);
    if (session.exercises.any((row) => row.exerciseId == exerciseId))
      throw const AppFailure(
        'duplicate_exercise',
        'That exercise is already in this workout.',
      );
    final exercise = _store.catalog
        .where((item) => item.id == exerciseId)
        .first;
    final previousSession =
        ([
              ..._store.completed,
            ]..sort((left, right) => right.startedAt.compareTo(left.startedAt)))
            .where(
              (done) => done.exercises.any(
                (row) =>
                    row.exerciseId == exerciseId &&
                    row.sets.any(
                      (set) => !set.isWarmup && set.durationSeconds == null,
                    ),
              ),
            )
            .firstOrNull;
    final priorSets =
        previousSession?.exercises
            .firstWhere((row) => row.exerciseId == exerciseId)
            .sets
            .where((set) => !set.isWarmup && set.durationSeconds == null)
            .toList() ??
        const <LoggedSet>[];
    final previous = [
      for (var index = 0; index < priorSets.length; index += 1)
        PreviousPerformance(
          sessionId: previousSession!.id,
          completedAt: previousSession.completedAt ?? previousSession.startedAt,
          weightKg: priorSets[index].weightKg,
          reps: priorSets[index].reps,
          setOrder: index + 1,
        ),
    ];
    final row = SessionExercise(
      id: _store.next('session-exercise'),
      exerciseId: exercise.id,
      name: exercise.name,
      muscleGroup: exercise.muscleGroup,
      demoUrl: exercise.demoUrl,
      demoSourceName: exercise.demoSourceName,
      sortOrder: session.exercises.length,
      targetSets: 3,
      targetReps: 10,
      previousPerformance: previous.lastOrNull,
      previousPerformances: previous,
      sets: const [],
    );
    _store.active = session.copyWith(
      exercises: [...session.exercises, row],
      updatedAt: DateTime.now().toUtc(),
    );
    return row;
  }

  @override
  Future<SessionExercise> importCalistreeExercise(
    String sessionId,
    String slug,
  ) async {
    const catalog = {
      'barbell-bench-press': ('Barbell bench press', 'strength', 'Chest'),
      'push-up': ('Push-up', 'strength', 'Chest'),
      'pull-up': ('Pull-up', 'strength', 'Back'),
      'goblet-squat': ('Goblet squat', 'strength', 'Quads'),
    };
    final source = catalog[slug];
    if (source == null) {
      throw const AppFailure(
        'catalog_exercise_not_found',
        'No matching exercise was found.',
      );
    }
    final existing = _store.catalog
        .where((item) => item.name.toLowerCase() == source.$1.toLowerCase())
        .cast<Exercise?>()
        .firstOrNull;
    final exercise =
        existing ??
        await MockPlanRepository(_store).createExercise(
          name: source.$1,
          category: source.$2,
          muscleGroup: source.$3,
        );
    return addExercise(sessionId, exercise.id);
  }

  @override
  Future<void> removeExercise(
    String sessionId,
    String sessionExerciseId,
  ) async {
    final session = _requireActive(sessionId);
    final row = session.exercises
        .where((item) => item.id == sessionExerciseId)
        .first;
    if (row.sets.isNotEmpty)
      throw const AppFailure(
        'exercise_has_sets',
        'Remove logged sets before removing this exercise.',
      );
    _store.active = session.copyWith(
      exercises: session.exercises
          .where((item) => item.id != sessionExerciseId)
          .toList(),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<bool> supportsOfflineSetSync() async => true;

  @override
  Future<SetLogResult> createSet(
    String sessionExerciseId,
    double weightKg,
    int reps, {
    bool isWarmup = false,
    int? durationSeconds,
    String? clientOperationId,
  }) async {
    if (failFirstCreateSet && !_hasFailed) {
      _hasFailed = true;
      throw const AppFailure(
        'server_error',
        'The mock server is temporarily unavailable.',
        retryable: true,
      );
    }
    final session = _store.active;
    final row = session?.exercises
        .where((item) => item.id == sessionExerciseId)
        .firstOrNull;
    if (session == null || row == null)
      throw const AppFailure(
        'session_not_active',
        'This workout is no longer active.',
      );
    final set = LoggedSet(
      id: _store.next('set'),
      sessionExerciseId: row.id,
      setOrder: row.sets.length + 1,
      weightKg: weightKg,
      reps: reps,
      durationSeconds: durationSeconds,
      completedAt: DateTime.now().toUtc(),
      isWarmup: isWarmup,
    );
    final exercises = session.exercises
        .map(
          (item) => item.id == row.id
              ? item.copyWith(sets: [...item.sets, set])
              : item,
        )
        .toList();
    _store.active = session.copyWith(
      exercises: exercises,
      updatedAt: DateTime.now().toUtc(),
    );
    final previous = row.previousPerformance;
    return SetLogResult(
      set: set,
      personalRecord: isWarmup || previous == null || durationSeconds != null
          ? null
          : _mockPersonalRecord(
              row.name,
              currentWeightKg: weightKg,
              currentReps: reps,
              previousWeightKg: previous.weightKg,
              previousReps: previous.reps,
            ),
    );
  }

  @override
  Future<LoggedSet> updateSet(
    String id,
    double weightKg,
    int reps, {
    bool isWarmup = false,
    int? durationSeconds,
  }) async {
    final session = _store.active;
    if (session == null)
      throw const AppFailure(
        'session_not_active',
        'This workout is no longer active.',
      );
    LoggedSet? updated;
    final exercises = session.exercises.map((row) {
      final sets = row.sets.map((set) {
        if (set.id != id) return set;
        updated = set.copyWith(
          weightKg: weightKg,
          reps: reps,
          durationSeconds: durationSeconds,
          isWarmup: isWarmup,
        );
        return updated!;
      }).toList();
      return row.copyWith(sets: sets);
    }).toList();
    if (updated == null)
      throw const AppFailure(
        'set_not_found',
        'That logged set is unavailable.',
      );
    _store.active = session.copyWith(
      exercises: exercises,
      updatedAt: DateTime.now().toUtc(),
    );
    return updated!;
  }

  @override
  Future<void> deleteSet(String id) async {
    final session = _store.active;
    if (session == null)
      throw const AppFailure(
        'session_not_active',
        'This workout is no longer active.',
      );
    var found = false;
    final exercises = session.exercises.map((row) {
      final sets = row.sets.where((set) {
        if (set.id == id) found = true;
        return set.id != id;
      }).toList();
      return row.copyWith(
        sets: [
          for (var i = 0; i < sets.length; i++)
            sets[i].copyWith(setOrder: i + 1),
        ],
      );
    }).toList();
    if (!found)
      throw const AppFailure(
        'set_not_found',
        'That logged set is unavailable.',
      );
    _store.active = session.copyWith(
      exercises: exercises,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<WorkoutSession> complete(String id) async {
    final session = _requireActive(id);
    final done = session.copyWith(
      status: SessionStatus.completed,
      completedAt: DateTime.now().toUtc(),
      clearRest: true,
      updatedAt: DateTime.now().toUtc(),
    );
    _store.active = null;
    _store.completed.insert(0, done);
    return done;
  }

  @override
  Future<void> discard(String id) async {
    _requireActive(id);
    _store.active = null;
  }

  @override
  Future<void> deleteCompletedSession(String id) async {
    _store.completed.removeWhere((session) => session.id == id);
  }

  @override
  Future<List<CompletedSessionSummary>> completedHistory() async =>
      _store.completed
          .map(
            (session) => CompletedSessionSummary(
              id: session.id,
              planId: session.planId,
              planDayId: session.planDayId,
              planName: session.planName,
              planDayName: session.planDayName,
              startedAt: session.startedAt,
              completedAt: session.completedAt!,
              durationSeconds: session.duration.inSeconds,
              workingSetCount: session.workingSetCount,
              totalVolumeKg: session.totalVolumeKg,
            ),
          )
          .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
}

class MockPlanningRepository implements PlanningRepository {
  MockPlanningRepository(this._store);
  final MockStore _store;
  @override
  Future<List<TrainingBlock>> listBlocks() async => [..._store.blocks];
  @override
  Future<TrainingBlock> createBlock(TrainingBlock block) async {
    final created = TrainingBlock(
      id: _store.next('block'),
      name: block.name,
      startDate: block.startDate,
      endDate: block.endDate,
      targetSessionsPerWeek: block.targetSessionsPerWeek,
      status: block.status,
      note: block.note,
      sessions: block.sessions,
    );
    _store.blocks.insert(0, created);
    return created;
  }

  @override
  Future<TrainingBlock> updateBlock(
    String blockId, {
    TrainingBlockStatus? status,
    String? note,
  }) async {
    final index = _store.blocks.indexWhere((block) => block.id == blockId);
    if (index < 0) {
      throw const AppFailure(
        'block_not_found',
        'That training block is unavailable.',
      );
    }
    final old = _store.blocks[index];
    final updated = TrainingBlock(
      id: old.id,
      name: old.name,
      startDate: old.startDate,
      endDate: old.endDate,
      targetSessionsPerWeek: old.targetSessionsPerWeek,
      status: status ?? old.status,
      note: note ?? old.note,
      sessions: old.sessions,
    );
    _store.blocks[index] = updated;
    return updated;
  }

  @override
  Future<ScheduledBlockSession> scheduleSession(
    String blockId,
    ScheduledBlockSession session,
  ) async {
    final index = _store.blocks.indexWhere((block) => block.id == blockId);
    if (index < 0) {
      throw const AppFailure(
        'block_not_found',
        'That training block is unavailable.',
      );
    }
    final created = ScheduledBlockSession(
      id: _store.next('scheduled-session'),
      scheduledFor: session.scheduledFor,
      status: session.status,
      isDeload: session.isDeload,
      isRecoverySession: session.isRecoverySession,
      note: session.note,
    );
    final old = _store.blocks[index];
    _store.blocks[index] = TrainingBlock(
      id: old.id,
      name: old.name,
      startDate: old.startDate,
      endDate: old.endDate,
      targetSessionsPerWeek: old.targetSessionsPerWeek,
      status: old.status,
      note: old.note,
      sessions: [...old.sessions, created]
        ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor)),
    );
    return created;
  }

  @override
  Future<ScheduledBlockSession> updateScheduledSession(
    String sessionId, {
    DateTime? scheduledFor,
    ScheduledBlockSessionStatus? status,
    bool? isDeload,
    bool? isRecoverySession,
    String? note,
  }) async {
    for (var index = 0; index < _store.blocks.length; index++) {
      final block = _store.blocks[index];
      final sessionIndex = block.sessions.indexWhere(
        (item) => item.id == sessionId,
      );
      if (sessionIndex < 0) continue;
      final current = block.sessions[sessionIndex];
      final updated = ScheduledBlockSession(
        id: current.id,
        scheduledFor: scheduledFor ?? current.scheduledFor,
        status: status ?? current.status,
        isDeload: isDeload ?? current.isDeload,
        isRecoverySession: isRecoverySession ?? current.isRecoverySession,
        note: note ?? current.note,
      );
      final sessions = [...block.sessions]..[sessionIndex] = updated;
      sessions.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
      _store.blocks[index] = TrainingBlock(
        id: block.id,
        name: block.name,
        startDate: block.startDate,
        endDate: block.endDate,
        targetSessionsPerWeek: block.targetSessionsPerWeek,
        status: block.status,
        note: block.note,
        sessions: sessions,
      );
      return updated;
    }
    throw const AppFailure(
      'scheduled_session_not_found',
      'That scheduled session is unavailable.',
    );
  }

  @override
  Future<List<WeeklyReview>> listReviews() async => [..._store.reviews];
  @override
  Future<WeeklyReview> createReview(WeeklyReview review) async {
    _store.reviews.insert(0, review);
    return review;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
