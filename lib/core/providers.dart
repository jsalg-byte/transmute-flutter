import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api/api_repositories.dart';
import 'data/pending_set_sync.dart';
import 'data/mock_repositories.dart';
import 'domain/models.dart';
import 'domain/daily_transmutation.dart';
import 'domain/recovery.dart';
import 'domain/repositories.dart';

enum RepositoryMode { mock, api }

enum AuthStatus { loading, signedOut, signedIn }

class AuthState {
  const AuthState(
    this.status, [
    this.user,
    this.error,
    this.freshRegistration = false,
  ]);
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool freshRegistration;
}

/// The app starts in the configured mode, but an API build can enter the
/// isolated fixture without needing a second build or a server restart.
final repositoryModeProvider =
    NotifierProvider<RepositoryModeController, RepositoryMode>(
      RepositoryModeController.new,
    );

class RepositoryModeController extends Notifier<RepositoryMode> {
  @override
  RepositoryMode build() =>
      const String.fromEnvironment(
            'TRANSMUTE_REPOSITORY_MODE',
            defaultValue: 'mock',
          ) ==
          'api'
      ? RepositoryMode.api
      : RepositoryMode.mock;

  void select(RepositoryMode mode) => state = mode;
}

final apiLoginAvailableProvider = Provider<bool>(
  (_) => const String.fromEnvironment('TRANSMUTE_API_BASE_URL').isNotEmpty,
);
final dioProvider = Provider<Dio>((_) {
  final configuredBaseUrl = const String.fromEnvironment(
    'TRANSMUTE_API_BASE_URL',
  );
  if (configuredBaseUrl.isEmpty) {
    throw StateError('API mode requires TRANSMUTE_API_BASE_URL.');
  }
  // A same-origin web deployment (such as the temporary phone tunnel) uses
  // the browser's current HTTPS origin rather than passing a relative URL to
  // Dio, which expects an absolute base URL.
  final baseUrl = configuredBaseUrl == '/'
      ? Uri.base.origin
      : configuredBaseUrl;
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: const {'Accept': 'application/json'},
    ),
  );
});
final mockStoreProvider = Provider<MockStore>((_) => MockStore());
final secureStoreProvider = Provider<SecureSessionStore>(
  (_) => SecureSessionStore(const FlutterSecureStorage()),
);
final demoSecureStoreProvider = Provider<SecureSessionStore>(
  (_) => SecureSessionStore(const FlutterSecureStorage(), namespace: 'demo.'),
);
final pendingSetStoreProvider = Provider<PendingSetStore>(
  (ref) => PendingSetStore(
    SecurePendingSetPersistence(ref.watch(secureStoreProvider).storage),
  ),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ref.watch(repositoryModeProvider) == RepositoryMode.mock
      ? MockAuthRepository(ref.watch(demoSecureStoreProvider))
      : ApiAuthRepository(
          ref.watch(dioProvider),
          ref.watch(secureStoreProvider),
        ),
);
final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => ref.watch(repositoryModeProvider) == RepositoryMode.mock
      ? MockPlanRepository(ref.watch(mockStoreProvider))
      : ApiPlanRepository(ref.watch(dioProvider)),
);
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => ref.watch(repositoryModeProvider) == RepositoryMode.mock
      ? MockSessionRepository(
          ref.watch(mockStoreProvider),
          failFirstCreateSet: const bool.fromEnvironment(
            'TRANSMUTE_MOCK_FAIL_FIRST_SET',
          ),
        )
      : ApiSessionRepository(
          ref.watch(dioProvider),
          RestTimerStore(ref.watch(secureStoreProvider).storage),
        ),
);
final recoveryRepositoryProvider = Provider<RecoveryRepository>(
  (ref) => ref.watch(repositoryModeProvider) == RepositoryMode.mock
      ? MockRecoveryRepository(ref.watch(mockStoreProvider))
      : ApiRecoveryRepository(ref.watch(dioProvider)),
);
final recoveryCheckinsProvider = FutureProvider<List<RecoveryCheckin>>(
  (ref) => ref.watch(recoveryRepositoryProvider).listCheckins(),
);
final fastingRepositoryProvider = Provider<FastingRepository>(
  (ref) => ref.watch(repositoryModeProvider) == RepositoryMode.mock
      ? MockFastingRepository(ref.watch(mockStoreProvider))
      : ApiFastingRepository(ref.watch(dioProvider)),
);
final fastingRecordProvider = FutureProvider<FastingRecord>(
  (ref) => ref.watch(fastingRepositoryProvider).read(),
);
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ref.watch(repositoryModeProvider) == RepositoryMode.mock
      ? MockProgressRepository(ref.watch(mockStoreProvider))
      : ApiProgressRepository(ref.watch(dioProvider)),
);
final progressRecordProvider = FutureProvider<ProgressRecord>(
  (ref) => ref.watch(progressRepositoryProvider).read(),
);
final nutritionRepositoryProvider = Provider<NutritionRepository>(
  (ref) => ref.watch(repositoryModeProvider) == RepositoryMode.mock
      ? MockNutritionRepository(ref.watch(mockStoreProvider))
      : ApiNutritionRepository(ref.watch(dioProvider)),
);
final nutritionRecordProvider = FutureProvider<NutritionRecord>(
  (ref) => ref.watch(nutritionRepositoryProvider).read(),
);
final arcanaRepositoryProvider = Provider<ArcanaRepository>(
  (ref) => ref.watch(repositoryModeProvider) == RepositoryMode.mock
      ? MockArcanaRepository()
      : ApiArcanaRepository(ref.watch(dioProvider)),
);
final arcanaProvider = FutureProvider<ArcanaData>(
  (ref) => ref.watch(arcanaRepositoryProvider).read(),
);
final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => ref.watch(repositoryModeProvider) == RepositoryMode.mock
      ? MockFriendsRepository(ref.watch(mockStoreProvider))
      : ApiFriendsRepository(ref.watch(dioProvider)),
);
final friendsProvider = FutureProvider<FriendsRecord>(
  (ref) => ref.watch(friendsRepositoryProvider).read(),
);
final sharedSessionProvider =
    FutureProvider.family<SharedWorkoutSession, String>(
      (ref, sessionId) =>
          ref.watch(friendsRepositoryProvider).getSharedSession(sessionId),
    );
final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => ref.watch(repositoryModeProvider) == RepositoryMode.mock
      ? MockPreferencesRepository(ref.watch(mockStoreProvider))
      : ApiPreferencesRepository(ref.watch(dioProvider)),
);
final preferencesProvider = FutureProvider<UserPreferences>(
  (ref) => ref.watch(preferencesRepositoryProvider).read(),
);
const defaultThemePreference = ThemePreference(
  palette: ThemePalette.transmute,
  brightness: PreferenceBrightness.light,
);

final themePreferenceProvider = FutureProvider<ThemePreference?>(
  (ref) => ref.watch(preferencesRepositoryProvider).getTheme(),
);

/// Applies a choice as soon as the person makes it. The API remains the
/// durable source for the next launch, but a slow or failed save must not make
/// the theme switch look unresponsive.
final themeOverrideProvider =
    NotifierProvider<ThemeOverrideController, ThemePreference?>(
      ThemeOverrideController.new,
    );

final effectiveThemePreferenceProvider = Provider<ThemePreference>((ref) {
  return ref.watch(themeOverrideProvider) ??
      ref.watch(themePreferenceProvider).asData?.value ??
      defaultThemePreference;
});

class ThemeOverrideController extends Notifier<ThemePreference?> {
  @override
  ThemePreference? build() => null;

  void set(ThemePreference? preference) => state = preference;
}

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => ref.watch(repositoryModeProvider) == RepositoryMode.mock
      ? MockGoalRepository(ref.watch(mockStoreProvider))
      : ApiGoalRepository(ref.watch(dioProvider)),
);
final goalsProvider = FutureProvider<List<Goal>>(
  (ref) => ref.watch(goalRepositoryProvider).listGoals(),
);
final planningRepositoryProvider = Provider<PlanningRepository>(
  (ref) => ref.watch(repositoryModeProvider) == RepositoryMode.mock
      ? MockPlanningRepository(ref.watch(mockStoreProvider))
      : ApiPlanningRepository(ref.watch(dioProvider)),
);
final trainingBlocksProvider = FutureProvider<List<TrainingBlock>>(
  (ref) => ref.watch(planningRepositoryProvider).listBlocks(),
);
final weeklyReviewsProvider = FutureProvider<List<WeeklyReview>>(
  (ref) => ref.watch(planningRepositoryProvider).listReviews(),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future<void>.microtask(restore);
    return const AuthState(AuthStatus.loading);
  }

  Future<void> restore() async {
    try {
      final session = await ref.read(authRepositoryProvider).restore();
      state = session == null
          ? const AuthState(AuthStatus.signedOut)
          : AuthState(AuthStatus.signedIn, session.user);
    } catch (_) {
      state = const AuthState(AuthStatus.signedOut);
    }
  }

  Future<void> login(String username, String password) async {
    state = const AuthState(AuthStatus.loading);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(username, password);
      state = AuthState(AuthStatus.signedIn, session.user);
    } on AppFailure catch (error) {
      state = AuthState(AuthStatus.signedOut, null, error.message);
    }
  }

  Future<void> register(
    String username,
    String password, {
    String? displayName,
  }) async {
    state = const AuthState(AuthStatus.loading);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .register(username, password, displayName: displayName);
      state = AuthState(AuthStatus.signedIn, session.user, null, true);
    } on AppFailure catch (error) {
      state = AuthState(AuthStatus.signedOut, null, error.message);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidate(activeSessionProvider);
    ref.read(themeOverrideProvider.notifier).set(null);
    state = const AuthState(AuthStatus.signedOut);
  }

  void setWeightUnit(WeightUnit unit) {
    final user = state.user;
    if (user == null) return;
    state = AuthState(
      AuthStatus.signedIn,
      User(
        id: user.id,
        username: user.username,
        displayName: user.displayName,
        weightUnit: unit,
      ),
    );
  }

  void finishWelcome() {
    final user = state.user;
    if (user != null) state = AuthState(AuthStatus.signedIn, user);
  }
}

final plansProvider = FutureProvider<List<WorkoutPlan>>(
  (ref) => ref.watch(planRepositoryProvider).listPlans(),
);
final planProvider = FutureProvider.family<WorkoutPlan, String>(
  (ref, id) => ref.watch(planRepositoryProvider).getPlan(id),
);
final historyProvider = FutureProvider<List<CompletedSessionSummary>>(
  (ref) => ref.watch(sessionRepositoryProvider).completedHistory(),
);
final sessionDetailProvider = FutureProvider.family<WorkoutSession, String>(
  (ref, id) => ref.watch(sessionRepositoryProvider).getSession(id),
);
final exerciseSearchProvider = FutureProvider.family<List<Exercise>, String>(
  (ref, query) => ref.watch(planRepositoryProvider).searchExercises(query),
);
final calistreeSearchProvider =
    FutureProvider.family<List<CatalogExercise>, String>(
      (ref, query) =>
          ref.watch(planRepositoryProvider).searchCalistreeExercises(query),
    );

class RecentRecordItem {
  const RecentRecordItem({
    required this.id,
    required this.title,
    required this.meta,
    required this.at,
    required this.route,
  });
  final String id;
  final String title;
  final String meta;
  final DateTime at;
  final String route;
}

final recentRecordProvider = FutureProvider<List<RecentRecordItem>>((
  ref,
) async {
  final values = await Future.wait<Object>([
    ref.watch(sessionRepositoryProvider).completedHistory(),
    ref.watch(nutritionRepositoryProvider).read(),
    ref.watch(progressRepositoryProvider).read(),
  ]);
  final sessions = values[0] as List<CompletedSessionSummary>;
  final nutrition = values[1] as NutritionRecord;
  final progress = values[2] as ProgressRecord;
  final entries = [
    ...sessions.map(
      (item) => RecentRecordItem(
        id: 'session-${item.id}',
        title: 'Session completed',
        meta: item.planName,
        at: item.completedAt,
        route: '/history/${item.id}',
      ),
    ),
    ...nutrition.meals.map(
      (item) => RecentRecordItem(
        id: 'meal-${item.id}',
        title: 'Meal recorded',
        meta: item.foodName,
        at: item.consumedAt,
        route: '/nutrition',
      ),
    ),
    ...progress.photos.map(
      (item) => RecentRecordItem(
        id: 'progress-${item.id}',
        title: 'Progress updated',
        meta: item.note?.trim().isNotEmpty == true
            ? item.note!.trim()
            : 'Progress photo added',
        at: item.capturedAt,
        route: '/progress',
      ),
    ),
  ];
  entries.sort((left, right) => right.at.compareTo(left.at));
  return entries.take(4).toList();
});

class DailyOverview {
  const DailyOverview({
    required this.plans,
    required this.activeSession,
    required this.completedSessions,
    required this.readiness,
  });
  final List<WorkoutPlan> plans;
  final WorkoutSession? activeSession;
  final List<WorkoutSession> completedSessions;
  final List<RecoveryGroup> readiness;
}

final dailyOverviewProvider = FutureProvider<DailyOverview>((ref) async {
  final plans = await ref.watch(planRepositoryProvider).listPlans();
  final preferences = await ref.watch(preferencesRepositoryProvider).read();
  final orderedPlans = preferences.activePlanId == null
      ? plans
      : [
          ...plans.where((plan) => plan.id == preferences.activePlanId),
          ...plans.where((plan) => plan.id != preferences.activePlanId),
        ];
  final active = await ref.watch(sessionRepositoryProvider).activeSession();
  final summaries = await ref
      .watch(sessionRepositoryProvider)
      .completedHistory();
  final sessions = await Future.wait(
    summaries
        .take(20)
        .map((item) => ref.read(sessionRepositoryProvider).getSession(item.id)),
  );
  return DailyOverview(
    plans: orderedPlans,
    activeSession: active,
    completedSessions: sessions,
    readiness: deriveRecovery(sessions),
  );
});

final dailyRecommendationProvider = FutureProvider<DailyRecommendation>((
  ref,
) async {
  final overview = await ref.watch(dailyOverviewProvider.future);
  final values = await Future.wait<Object>([
    ref.watch(recoveryRepositoryProvider).listCheckins(),
    ref.watch(nutritionRepositoryProvider).read(),
    ref.watch(goalRepositoryProvider).listGoals(),
  ]);
  return deriveDailyTransmutation(
    plans: overview.plans,
    activeSession: overview.activeSession,
    readiness: overview.readiness,
    checkins: values[0] as List<RecoveryCheckin>,
    nutrition: values[1] as NutritionRecord,
    goals: values[2] as List<Goal>,
  );
});

final activeSessionProvider =
    AsyncNotifierProvider<ActiveSessionController, WorkoutSession?>(
      ActiveSessionController.new,
    );

class ActiveSessionController extends AsyncNotifier<WorkoutSession?> {
  Timer? _syncTimer;
  Future<PendingSetSyncReport>? _syncing;
  bool _offlineSyncAvailable = false;

  @override
  Future<WorkoutSession?> build() async {
    ref.onDispose(() => _syncTimer?.cancel());
    final session = await ref.read(sessionRepositoryProvider).activeSession();
    if (session == null) return null;
    _offlineSyncAvailable = await ref
        .read(sessionRepositoryProvider)
        .supportsOfflineSetSync();
    if (!_offlineSyncAvailable) return session;
    _scheduleSync();
    return _withPending(session);
  }

  String? get _userId => ref.read(authControllerProvider).user?.id;

  PendingSetSyncService get _pendingSync => PendingSetSyncService(
    ref.read(pendingSetStoreProvider),
    ref.read(sessionRepositoryProvider),
  );

  void _scheduleSync() {
    _syncTimer ??= Timer.periodic(const Duration(seconds: 12), (_) {
      unawaited(syncPending());
    });
  }

  Future<WorkoutSession> _withPending(WorkoutSession session) async {
    final userId = _userId;
    if (userId == null) return session;
    final pending = (await ref.read(pendingSetStoreProvider).read(userId))
        .where((item) => item.sessionId == session.id)
        .toList();
    if (pending.isEmpty) return session;
    return session.copyWith(
      exercises: session.exercises.map((exercise) {
        final logs = pending
            .where((item) => item.sessionExerciseId == exercise.id)
            .toList();
        return logs.isEmpty
            ? exercise
            : exercise.copyWith(
                sets: [
                  ...exercise.sets,
                  for (var index = 0; index < logs.length; index += 1)
                    logs[index].asPendingSet(exercise.sets.length + index + 1),
                ],
              );
      }).toList(),
    );
  }

  Future<WorkoutSession> start(String planId, String planDayId) async {
    try {
      final session = await ref
          .read(sessionRepositoryProvider)
          .startSession(planId, planDayId);
      _offlineSyncAvailable = await ref
          .read(sessionRepositoryProvider)
          .supportsOfflineSetSync();
      if (_offlineSyncAvailable) _scheduleSync();
      state = AsyncData(session);
      ref.invalidate(plansProvider);
      return session;
    } on AppFailure catch (error) {
      if (error.code == 'active_session_exists') await refresh();
      rethrow;
    }
  }

  Future<void> refresh() async => state = await AsyncValue.guard(() async {
    final session = await ref.read(sessionRepositoryProvider).activeSession();
    return session == null ? null : _withPending(session);
  });
  Future<void> setRest(DateTime? deadline) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(restEndsAt: deadline, clearRest: deadline == null),
    );
    state = await AsyncValue.guard(
      () =>
          ref.read(sessionRepositoryProvider).updateRest(current.id, deadline),
    );
  }

  Future<void> addExercise(String exerciseId) async {
    final current = state.value;
    if (current == null) return;
    await ref
        .read(sessionRepositoryProvider)
        .addExercise(current.id, exerciseId);
    await refresh();
  }

  Future<void> importCalistreeExercise(String slug) async {
    final current = state.value;
    if (current == null) return;
    await ref
        .read(sessionRepositoryProvider)
        .importCalistreeExercise(current.id, slug);
    await refresh();
  }

  Future<void> removeExercise(String id) async {
    final current = state.value;
    if (current == null) return;
    await ref.read(sessionRepositoryProvider).removeExercise(current.id, id);
    await refresh();
  }

  Future<SetSubmissionResult> createSet(
    SessionExercise exercise,
    double weightKg,
    int reps, {
    bool isWarmup = false,
  }) async {
    final current = state.value;
    if (current == null) return const SetSubmissionResult(queued: false);
    if (!_offlineSyncAvailable) {
      final result = await ref
          .read(sessionRepositoryProvider)
          .createSet(exercise.id, weightKg, reps, isWarmup: isWarmup);
      await refresh();
      return SetSubmissionResult(
        personalRecord: result.personalRecord,
        queued: false,
      );
    }
    final userId = _userId;
    if (userId == null) {
      throw const AppFailure(
        'session_unavailable',
        'Sign in again to log this set.',
      );
    }
    final queued = PendingSetLog(
      operationId: newSetOperationId(),
      sessionId: current.id,
      sessionExerciseId: exercise.id,
      weightKg: weightKg,
      reps: reps,
      isWarmup: isWarmup,
      createdAt: DateTime.now().toUtc(),
    );
    await ref.read(pendingSetStoreProvider).enqueue(userId, queued);
    final pending = queued.asPendingSet(exercise.sets.length + 1);
    state = AsyncData(
      current.copyWith(
        exercises: current.exercises
            .map(
              (row) => row.id == exercise.id
                  ? row.copyWith(sets: [...row.sets, pending])
                  : row,
            )
            .toList(),
      ),
    );
    final report = await syncPending();
    final remains = (await ref.read(pendingSetStoreProvider).read(userId)).any(
      (item) => item.operationId == queued.operationId,
    );
    return SetSubmissionResult(
      personalRecord: report.synced.isEmpty
          ? null
          : report.synced.last.personalRecord,
      queued: remains,
    );
  }

  Future<PendingSetSyncReport> syncPending() async {
    final current = state.value;
    final userId = _userId;
    if (!_offlineSyncAvailable || current == null || userId == null) {
      return const PendingSetSyncReport();
    }
    final running = _syncing;
    if (running != null) return running;
    final task = _syncPending(current, userId);
    _syncing = task;
    try {
      return await task;
    } finally {
      _syncing = null;
    }
  }

  Future<PendingSetSyncReport> _syncPending(
    WorkoutSession current,
    String userId,
  ) async {
    final report = await _pendingSync.sync(userId, current.id);
    if (report.synced.isEmpty) return report;
    try {
      final remote = await ref
          .read(sessionRepositoryProvider)
          .getSession(current.id);
      state = AsyncData(await _withPending(remote));
    } on AppFailure {
      // The queue already records the truth. Preserve the optimistic screen
      // until a subsequent reconnect can refresh the server projection.
    }
    return report;
  }

  Future<void> updateSet(
    String setId,
    double weightKg,
    int reps, {
    bool isWarmup = false,
  }) async {
    await ref
        .read(sessionRepositoryProvider)
        .updateSet(setId, weightKg, reps, isWarmup: isWarmup);
    await refresh();
  }

  Future<void> deleteSet(String setId) async {
    await ref.read(sessionRepositoryProvider).deleteSet(setId);
    await refresh();
  }

  Future<WorkoutSession> complete() async {
    final current = state.value!;
    if (_offlineSyncAvailable) {
      await syncPending();
      final userId = _userId;
      final unsynced = userId == null
          ? const <PendingSetLog>[]
          : (await ref.read(pendingSetStoreProvider).read(userId))
                .where((item) => item.sessionId == current.id)
                .toList();
      if (unsynced.isNotEmpty) {
        throw AppFailure(
          'pending_set_sync',
          'Sync the ${unsynced.length} pending ${unsynced.length == 1 ? 'set' : 'sets'} before finishing this workout.',
          retryable: true,
        );
      }
    }
    final result = await ref
        .read(sessionRepositoryProvider)
        .complete(current.id);
    state = const AsyncData(null);
    ref.invalidate(historyProvider);
    return result;
  }

  Future<void> discard() async {
    final current = state.value!;
    await ref.read(sessionRepositoryProvider).discard(current.id);
    final userId = _userId;
    if (userId != null) {
      await ref.read(pendingSetStoreProvider).removeSession(userId, current.id);
    }
    state = const AsyncData(null);
  }
}
