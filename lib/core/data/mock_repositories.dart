import 'dart:async';

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
    catalog = [bench, row, press, squat, rdl, calf];
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
  final List<Goal> goals = [];
  final List<TrainingBlock> blocks = [];
  final List<WeeklyReview> reviews = [];
  late List<FriendRequest> incomingFriends;
  late List<FriendRequest> outgoingFriends;
  late List<FriendActivity> friendActivity;
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
      assessments: old.assessments,
    );
    _store.goals[index] = updated;
    return updated;
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
    if (plan.days.length == 1)
      throw const AppFailure(
        'last_day',
        'A plan must keep at least one training day.',
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
              targetWeightKg: entries[i].targetWeightKg,
            ),
        ],
      ),
    );
  }

  @override
  Future<PlanExercise> updatePrescription(
    String planId,
    String dayId,
    String planExerciseId, {
    required int targetSets,
    required int targetReps,
    double? targetWeightKg,
  }) async {
    if (targetSets < 1 || targetSets > 20 || targetReps < 1 || targetReps > 100)
      throw const AppFailure(
        'invalid_prescription',
        'Use 1–20 sets and 1–100 reps.',
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
    _store.active = WorkoutSession(
      id: _store.next('session'),
      planId: plan.id,
      planName: plan.name,
      planDayId: day.id,
      planDayName: day.name,
      status: SessionStatus.active,
      startedAt: now,
      updatedAt: now,
      exercises: day.exercises
          .map(
            (row) => SessionExercise(
              id: _store.next('session-exercise'),
              exerciseId: row.exercise.id,
              name: row.exercise.name,
              muscleGroup: row.exercise.muscleGroup,
              demoUrl: row.exercise.demoUrl,
              demoSourceName: row.exercise.demoSourceName,
              sortOrder: row.sortOrder,
              targetSets: row.targetSets,
              targetReps: row.targetReps,
              targetWeightKg: row.targetWeightKg,
              previousPerformance: row.previousPerformance,
              sets: const [],
            ),
          )
          .toList(),
    );
    return _store.active!;
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
      personalRecord: isWarmup || previous == null
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
  Future<List<CompletedSessionSummary>> completedHistory() async =>
      _store.completed
          .map(
            (session) => CompletedSessionSummary(
              id: session.id,
              planName: session.planName,
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
