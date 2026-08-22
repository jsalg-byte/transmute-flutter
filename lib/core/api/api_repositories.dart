import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../domain/models.dart';
import '../domain/repositories.dart';

class SecureSessionStore {
  const SecureSessionStore(this._storage, {this.namespace = ''});
  final FlutterSecureStorage _storage;
  final String namespace;
  FlutterSecureStorage get storage => _storage;
  String get _access => 'transmute.${namespace}access';
  String get _refresh => 'transmute.${namespace}refresh';
  String get _expires => 'transmute.${namespace}expires';
  Future<void> save(AuthSession session) async {
    await _storage.write(key: _access, value: session.accessToken);
    await _storage.write(key: _refresh, value: session.refreshToken);
    await _storage.write(
      key: _expires,
      value: session.expiresAt.toIso8601String(),
    );
  }

  Future<({String access, String refresh, DateTime expires})?> read() async {
    final access = await _storage.read(key: _access);
    final refresh = await _storage.read(key: _refresh);
    final expires = await _storage.read(key: _expires);
    if (access == null || refresh == null || expires == null) return null;
    return (access: access, refresh: refresh, expires: DateTime.parse(expires));
  }

  Future<void> clear() => _storage.deleteAll();
}

/// The Expo client renews a short-lived access token once when an authenticated
/// request receives a 401.  Set sync has the same requirement: without this,
/// a workout that outlives its access token is incorrectly left in the local
/// queue and can never be completed until the user starts over.
void configureAccessTokenRefresh(Dio dio, SecureSessionStore store) {
  dio.interceptors.add(_AccessTokenRefreshInterceptor(dio, store));
}

class _AccessTokenRefreshInterceptor extends QueuedInterceptor {
  _AccessTokenRefreshInterceptor(this._dio, this._store);

  static const _retried = 'transmute.access-token-refreshed';
  final Dio _dio;
  final SecureSessionStore _store;
  Future<AuthSession?>? _refreshing;

  bool _canRefresh(RequestOptions request) =>
      request.extra[_retried] != true &&
      request.path != '/v1/auth/login' &&
      request.path != '/v1/auth/register' &&
      request.path != '/v1/auth/refresh' &&
      request.path != '/v1/auth/logout';

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode != 401 ||
        !_canRefresh(error.requestOptions)) {
      handler.next(error);
      return;
    }

    try {
      final session = await _refresh();
      if (session == null) {
        handler.next(error);
        return;
      }
      final request = error.requestOptions;
      request.headers['Authorization'] = 'Bearer ${session.accessToken}';
      request.extra[_retried] = true;
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(error);
    }
  }

  Future<AuthSession?> _refresh() {
    final existing = _refreshing;
    if (existing != null) return existing;
    final task = _performRefresh();
    _refreshing = task;
    return task.whenComplete(() => _refreshing = null);
  }

  Future<AuthSession?> _performRefresh() async {
    final stored = await _store.read();
    if (stored == null) return null;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refreshToken': stored.refresh},
        options: Options(extra: {_retried: true}),
      );
      final session = _auth(response.data!);
      await _store.save(session);
      _dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      return session;
    } on DioException {
      return null;
    }
  }
}

class RestTimerStore {
  const RestTimerStore(this._storage);
  final FlutterSecureStorage _storage;
  String _key(String sessionId) => 'transmute.rest.$sessionId';

  Future<DateTime?> read(String sessionId) async {
    final raw = await _storage.read(key: _key(sessionId));
    if (raw == null) return null;
    final deadline = DateTime.tryParse(raw)?.toUtc();
    if (deadline == null || !deadline.isAfter(DateTime.now().toUtc())) {
      await _storage.delete(key: _key(sessionId));
      return null;
    }
    return deadline;
  }

  Future<void> write(String sessionId, DateTime? deadline) => deadline == null
      ? _storage.delete(key: _key(sessionId))
      : _storage.write(
          key: _key(sessionId),
          value: deadline.toUtc().toIso8601String(),
        );
}

abstract interface class PendingSetPersistence {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecurePendingSetPersistence implements PendingSetPersistence {
  const SecurePendingSetPersistence(this._storage);
  final FlutterSecureStorage _storage;
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

/// Explicit adapter for the existing Expo/Fastify `/v1` contract. It does not
/// use the retired standalone-demo endpoints documented in older revisions.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio, this._store);
  final Dio _dio;
  final SecureSessionStore _store;
  @override
  Future<AuthSession> login(String username, String password) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/auth/login',
        data: {'username': username, 'password': password},
      ),
    );
    final session = _auth(body.data!);
    await _store.save(session);
    _dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    return session;
  }

  @override
  Future<AuthSession> register(
    String username,
    String password, {
    String? displayName,
  }) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/auth/register',
        data: {
          'username': username.trim(),
          'password': password,
          if (displayName?.trim().isNotEmpty == true)
            'name': displayName!.trim(),
        },
      ),
    );
    final session = _auth(body.data!);
    await _store.save(session);
    _dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    return session;
  }

  @override
  Future<AuthSession?> restore() async {
    final cached = await _store.read();
    if (cached == null) return null;
    try {
      if (cached.expires.isAfter(
        DateTime.now().add(const Duration(minutes: 1)),
      )) {
        final me = await _request(
          () => _dio.get<Map<String, dynamic>>(
            '/v1/me',
            options: Options(
              headers: {'Authorization': 'Bearer ${cached.access}'},
            ),
          ),
        );
        final session = AuthSession(
          accessToken: cached.access,
          refreshToken: cached.refresh,
          expiresAt: cached.expires,
          user: _user(me.data!['user'] as Map<String, dynamic>),
        );
        _dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        return session;
      }
      final response = await _request(
        () => _dio.post<Map<String, dynamic>>(
          '/v1/auth/refresh',
          data: {'refreshToken': cached.refresh},
        ),
      );
      final session = _auth(response.data!);
      await _store.save(session);
      _dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      return session;
    } on AppFailure {
      await _store.clear();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final cached = await _store.read();
    if (cached != null) {
      try {
        await _dio.post<void>(
          '/v1/auth/logout',
          data: {'refreshToken': cached.refresh},
        );
      } catch (_) {}
    }
    await _store.clear();
    _dio.options.headers.remove('Authorization');
  }
}

class ApiPlanRepository implements PlanRepository {
  ApiPlanRepository(this._dio);
  final Dio _dio;
  Future<Map<String, dynamic>> _record() async => (await _request(
    () => _dio.get<Map<String, dynamic>>('/v1/record'),
  )).data!;
  @override
  Future<List<WorkoutPlan>> listPlans() async {
    final record = await _record();
    return _plans(record, _recordWeightUnit(record));
  }

  @override
  Future<WorkoutPlan> getPlan(String planId) async {
    final record = await _record();
    return _plans(
          record,
          _recordWeightUnit(record),
        ).where((plan) => plan.id == planId).cast<WorkoutPlan?>().firstOrNull ??
        (throw const AppFailure(
          'plan_not_found',
          'That workout plan is unavailable.',
        ));
  }

  @override
  Future<WorkoutPlan> createPlan(String name, {String? description}) async {
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/plans',
        data: {
          'name': name,
          if (description?.isNotEmpty == true) 'description': description,
        },
      ),
    );
    return (await listPlans()).first;
  }

  @override
  Future<AiWorkoutPlanDraft> generateAiWorkoutDraft(String prompt) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/ai/workout-drafts',
        data: {'prompt': prompt},
      ),
    );
    return _aiWorkoutDraft(body.data!['draft'] as Map<String, dynamic>);
  }

  @override
  Future<WorkoutPlan> importAiWorkoutPlan(AiWorkoutPlanDraft draft) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/ai/workout-plans',
        data: {'plan': _aiWorkoutDraftBody(draft)},
      ),
    );
    final plan = body.data!['plan'] as Map<String, dynamic>;
    return getPlan(plan['id'] as String);
  }

  @override
  Future<WorkoutPlan> renamePlan(String planId, String name) async {
    await _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/v1/plans/$planId',
        data: {'name': name},
      ),
    );
    return getPlan(planId);
  }

  @override
  Future<void> deletePlan(String planId) async {
    await _request(() => _dio.delete<void>('/v1/plans/$planId'));
  }

  @override
  Future<WorkoutPlanDay> addDay(String planId, String name) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/plans/$planId/days',
        data: {'dayName': name},
      ),
    );
    final value = body.data!['day'] as Map<String, dynamic>;
    return WorkoutPlanDay(
      id: value['id'] as String,
      name: value['name'] as String,
      sortOrder: value['sortOrder'] as int,
      exercises: const [],
    );
  }

  @override
  Future<WorkoutPlanDay> renameDay(
    String planId,
    String dayId,
    String name,
  ) async {
    await _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/v1/plan-days/$dayId',
        data: {'dayName': name},
      ),
    );
    return (await getPlan(planId)).days.where((day) => day.id == dayId).first;
  }

  @override
  Future<void> deleteDay(String planId, String dayId) async {
    await _request(() => _dio.delete<void>('/v1/plan-days/$dayId'));
  }

  @override
  Future<PlanExercise> addExerciseToDay(
    String planId,
    String dayId,
    String exerciseId,
  ) async {
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/plan-days/$dayId/exercises',
        data: {'exerciseId': exerciseId},
      ),
    );
    return (await getPlan(
      planId,
    )).days.where((day) => day.id == dayId).first.exercises.last;
  }

  @override
  Future<void> removeExerciseFromDay(
    String planId,
    String dayId,
    String planExerciseId,
  ) async {
    await _request(
      () => _dio.delete<void>('/v1/plan-day-exercises/$planExerciseId'),
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
    final unit = _recordWeightUnit(await _record());
    await _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/v1/plan-day-exercises/$planExerciseId',
        data: {
          'targetSets': targetSets,
          'targetReps': targetReps,
          'targetWeight': targetWeightKg == null
              ? null
              : fromKg(targetWeightKg, unit),
        },
      ),
    );
    return (await getPlan(planId)).days
        .where((day) => day.id == dayId)
        .first
        .exercises
        .where((entry) => entry.id == planExerciseId)
        .first;
  }

  @override
  Future<Exercise> createExercise({
    required String name,
    required String category,
    String? muscleGroup,
  }) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/exercises',
        data: {
          'name': name,
          'category': category,
          if (muscleGroup?.isNotEmpty == true) 'muscleGroup': muscleGroup,
        },
      ),
    );
    return _exercise(body.data!['exercise'] as Map<String, dynamic>);
  }

  @override
  Future<Exercise> updateExerciseDemo(
    String exerciseId, {
    required String demoUrl,
    String? sourceName,
  }) async {
    await _request(
      () => _dio.put<Map<String, dynamic>>(
        '/v1/exercises/$exerciseId/demo',
        data: {
          'demoUrl': demoUrl,
          if (sourceName?.isNotEmpty == true) 'sourceName': sourceName,
        },
      ),
    );
    return (await searchExercises('')).firstWhere(
      (exercise) => exercise.id == exerciseId,
      orElse: () => throw const AppFailure(
        'exercise_not_found',
        'The demonstration was saved, but the exercise record could not be refreshed.',
      ),
    );
  }

  @override
  Future<List<CatalogExercise>> searchCalistreeExercises(String query) async {
    final value = query.trim();
    if (value.length < 2) return const [];
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>(
        '/v1/calistree/exercises',
        queryParameters: {'q': value},
      ),
    );
    return (body.data!['results'] as List<dynamic>)
        .map(
          (item) => CatalogExercise(
            name: (item as Map<String, dynamic>)['name'] as String,
            slug: item['slug'] as String,
          ),
        )
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
    final unit = _recordWeightUnit(await _record());
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/plan-days/$dayId/calistree-exercises',
        data: {
          'slug': slug,
          'targetSets': targetSets,
          ...?(targetReps == null
              ? null
              : <String, dynamic>{'targetReps': targetReps}),
          ...?(targetWeightKg == null
              ? null
              : <String, dynamic>{
                  'targetWeight': fromKg(targetWeightKg, unit),
                }),
        },
      ),
    );
    final plan = await getPlan(planId);
    return plan.days.where((day) => day.id == dayId).first.exercises.last;
  }

  @override
  Future<List<Exercise>> searchExercises(String query) async {
    final record = await _record();
    final all = (record['exercises'] as List<dynamic>).map(
      (value) => _exercise(value as Map<String, dynamic>),
    );
    final needle = query.trim().toLowerCase();
    return all
        .where(
          (item) => needle.isEmpty || item.name.toLowerCase().contains(needle),
        )
        .toList();
  }
}

class ApiSessionRepository implements SessionRepository {
  ApiSessionRepository(this._dio, this._restStore);
  final Dio _dio;
  final RestTimerStore _restStore;
  final _rest = <String, DateTime?>{};
  final _setExercise = <String, String>{};
  final _sessionWeightUnits = <String, WeightUnit>{};
  bool? _offlineSetSyncSupported;
  Future<Map<String, dynamic>> _record() async => (await _request(
    () => _dio.get<Map<String, dynamic>>('/v1/record'),
  )).data!;
  Future<WorkoutSession> _detail(
    String id, {
    String planId = 'unknown',
    String planDayId = 'unknown',
  }) async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/sessions/$id'),
    );
    final weightUnit = _expoSessionWeightUnit(body.data!);
    final session = _session(
      body.data!,
      planId: planId,
      planDayId: planDayId,
      restEndsAt: _rest[id] ?? await _restStore.read(id),
      setExercise: _setExercise,
      weightUnit: weightUnit,
    );
    _sessionWeightUnits[session.id] = weightUnit;
    return session;
  }

  @override
  Future<WorkoutSession?> activeSession() async {
    final record = await _record();
    final active =
        (record['dashboard'] as Map<String, dynamic>)['activeSession'];
    if (active == null) return null;
    final item = active as Map<String, dynamic>;
    return _detail(item['id'] as String, planDayId: 'unknown');
  }

  @override
  Future<WorkoutSession> getSession(String id) => _detail(id);
  @override
  Future<WorkoutSession> startSession(
    String planId, [
    String? planDayId,
  ]) async {
    if (planDayId == null)
      throw const AppFailure(
        'day_required',
        'Choose a training day before starting.',
      );
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/sessions',
        data: {'routineDayId': planDayId},
      ),
    );
    final session = body.data!['session'] as Map<String, dynamic>;
    return _detail(
      session['id'] as String,
      planId: planId,
      planDayId: planDayId,
    );
  }

  @override
  Future<WorkoutSession> updateRest(String id, DateTime? restEndsAt) async {
    _rest[id] = restEndsAt;
    await _restStore.write(id, restEndsAt);
    return _detail(id);
  }

  @override
  Future<SessionExercise> addExercise(
    String sessionId,
    String exerciseId,
  ) async {
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/sessions/$sessionId/exercises',
        data: {'exerciseId': exerciseId},
      ),
    );
    return (await _detail(
      sessionId,
    )).exercises.where((row) => row.exerciseId == exerciseId).first;
  }

  @override
  Future<SessionExercise> importCalistreeExercise(
    String sessionId,
    String slug,
  ) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/sessions/$sessionId/calistree-exercises',
        data: {'slug': slug},
      ),
    );
    final entry = body.data!['entry'] as Map<String, dynamic>;
    return (await _detail(
      sessionId,
    )).exercises.where((row) => row.exerciseId == entry['exerciseId']).first;
  }

  @override
  Future<void> removeExercise(
    String sessionId,
    String sessionExerciseId,
  ) async => throw const AppFailure(
    'session_exercise_remove_unavailable',
    'The current Expo API does not support removing an exercise from a started session.',
  );

  @override
  Future<bool> supportsOfflineSetSync() async {
    if (_offlineSetSyncSupported != null) return _offlineSetSyncSupported!;
    try {
      final body = await _request(
        () => _dio.get<Map<String, dynamic>>('/v1/capabilities'),
      );
      return _offlineSetSyncSupported = body.data?['offlineSetSync'] == true;
    } on AppFailure {
      // Older deployments remain online-only. Never queue a command unless
      // the server has explicitly promised idempotent replay support.
      return _offlineSetSyncSupported = false;
    }
  }

  @override
  Future<SetLogResult> createSet(
    String sessionExerciseId,
    double weightKg,
    int reps, {
    bool isWarmup = false,
    String? clientOperationId,
  }) async {
    final sessionId = await _activeId();
    final weightUnit = _sessionWeightUnits[sessionId];
    if (weightUnit == null) {
      throw const AppFailure(
        'session_weight_unit_missing',
        'Reload the workout before logging a set.',
      );
    }
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/sessions/$sessionId/sets',
        data: {
          'exerciseId': sessionExerciseId,
          'weight': fromKg(weightKg, weightUnit),
          'reps': reps,
          'isWarmup': isWarmup,
          'clientOperationId': ?clientOperationId,
        },
      ),
    );
    final set = body.data!['set'] as Map<String, dynamic>;
    _setExercise[set['id'] as String] = sessionExerciseId;
    final record = body.data!['personalRecord'] as Map<String, dynamic>?;
    return SetLogResult(
      set: _set(set, weightUnit),
      personalRecord: record == null
          ? null
          : _personalRecord(record, weightUnit),
    );
  }

  @override
  Future<LoggedSet> updateSet(
    String id,
    double weightKg,
    int reps, {
    bool isWarmup = false,
  }) async {
    final exerciseId = _setExercise[id];
    if (exerciseId == null)
      throw const AppFailure(
        'set_context_missing',
        'Reload the workout before editing this set.',
      );
    final sessionId = await _activeId();
    final weightUnit = _sessionWeightUnits[sessionId];
    if (weightUnit == null) {
      throw const AppFailure(
        'session_weight_unit_missing',
        'Reload the workout before editing this set.',
      );
    }
    await _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/v1/sets/$id',
        data: {
          'exerciseId': exerciseId,
          'weight': fromKg(weightKg, weightUnit),
          'reps': reps,
          'isWarmup': isWarmup,
        },
      ),
    );
    return (await _detail(
      sessionId,
    )).exercises.expand((row) => row.sets).where((set) => set.id == id).first;
  }

  @override
  Future<void> deleteSet(String id) async {
    await _request(() => _dio.delete<void>('/v1/sets/$id'));
    _setExercise.remove(id);
  }

  @override
  Future<WorkoutSession> complete(String id) async {
    await _request(
      () => _dio.post<Map<String, dynamic>>('/v1/sessions/$id/complete'),
    );
    _rest.remove(id);
    await _restStore.write(id, null);
    return _detail(id);
  }

  @override
  Future<void> discard(String id) async {
    await _request(() => _dio.delete<void>('/v1/sessions/$id'));
    _rest.remove(id);
    await _restStore.write(id, null);
  }

  @override
  Future<List<CompletedSessionSummary>> completedHistory() async {
    final record = await _record();
    final raw = (record['sessions'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((item) => item['status'] == 'completed')
        .toList();
    final sessions = await Future.wait(
      raw.map((item) => _detail(item['id'] as String)),
    );
    return sessions
        .map(
          (item) => CompletedSessionSummary(
            id: item.id,
            planName: item.planName,
            startedAt: item.startedAt,
            completedAt: item.completedAt!,
            durationSeconds: item.duration.inSeconds,
            workingSetCount: item.workingSetCount,
            totalVolumeKg: item.totalVolumeKg,
          ),
        )
        .toList();
  }

  Future<String> _activeId() async {
    final active = await activeSession();
    if (active == null)
      throw const AppFailure(
        'session_not_active',
        'This workout is no longer active.',
      );
    return active.id;
  }
}

class ApiRecoveryRepository implements RecoveryRepository {
  ApiRecoveryRepository(this._dio);
  final Dio _dio;
  @override
  Future<List<RecoveryCheckin>> listCheckins() async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/recovery-checkins'),
    );
    return (body.data!['checkins'] as List<dynamic>).map((value) {
      final item = value as Map<String, dynamic>;
      return RecoveryCheckin(
        date: DateTime.parse(item['checked_on'] as String),
        recoveryScore: item['energy'] as int,
        sleepHours: (item['sleep_duration_minutes'] as num?)?.toDouble() == null
            ? null
            : (item['sleep_duration_minutes'] as num).toDouble() / 60,
        sorenessScore: item['soreness'] as int?,
        stressScore: item['stress'] as int?,
        note: item['note'] as String?,
      );
    }).toList();
  }

  @override
  Future<RecoveryCheckin> saveCheckin(RecoveryCheckin checkin) async {
    final date =
        '${checkin.date.year.toString().padLeft(4, '0')}-${checkin.date.month.toString().padLeft(2, '0')}-${checkin.date.day.toString().padLeft(2, '0')}';
    await _request(
      () => _dio.put<Map<String, dynamic>>(
        '/v1/recovery-checkins/$date',
        data: {
          'recoveryScore': checkin.recoveryScore,
          if (checkin.sleepHours != null) 'sleepHours': checkin.sleepHours,
          if (checkin.sorenessScore != null)
            'sorenessScore': checkin.sorenessScore,
          if (checkin.stressScore != null) 'stressScore': checkin.stressScore,
          if (checkin.note?.isNotEmpty == true) 'note': checkin.note,
        },
      ),
    );
    return checkin;
  }
}

Future<Response<T>> _request<T>(Future<Response<T>> Function() request) async {
  try {
    return await request();
  } on DioException catch (error) {
    final data = error.response?.data;
    final rawError = data is Map ? data['error'] : null;
    final message = rawError is String
        ? rawError
        : rawError is Map && rawError['message'] is String
        ? rawError['message'] as String
        : 'Unable to reach the Transmute service. Check your connection and retry.';
    final status = error.response?.statusCode;
    final network = switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => true,
      _ => false,
    };
    final code = switch (status) {
      401 => 'unauthorized',
      404 => 'not_found',
      409 => 'conflict',
      400 || 422 => 'validation_error',
      int value when value >= 500 => 'server_error',
      _ when network => 'network_error',
      _ => 'request_failed',
    };
    throw AppFailure(code, message, retryable: network || (status ?? 0) >= 500);
  }
}

AuthSession _auth(Map<String, dynamic> map) => AuthSession(
  accessToken: map['accessToken'] as String,
  refreshToken: map['refreshToken'] as String,
  expiresAt: DateTime.now().add(
    Duration(seconds: map['accessTokenExpiresInSeconds'] as int),
  ),
  user: _user(map['user'] as Map<String, dynamic>),
);
User _user(Map<String, dynamic> map) => User(
  id: map['id'] as String,
  username: map['username'] as String,
  displayName: map['name'] as String?,
  weightUnit: WeightUnit.lb,
);
Exercise _exercise(Map<String, dynamic> map) => Exercise(
  id: map['id'] as String,
  name: map['name'] as String,
  category: map['category'] as String,
  muscleGroup: (map['muscleGroup'] ?? map['muscle_group']) as String?,
  demoUrl: (map['demoUrl'] ?? map['demo_url']) as String?,
  demoSourceName: (map['demoSourceName'] ?? map['demo_source_name']) as String?,
);
AiWorkoutPlanDraft _aiWorkoutDraft(Map<String, dynamic> map) =>
    AiWorkoutPlanDraft(
      name: map['name'] as String,
      description: map['description'] as String?,
      days: (map['days'] as List<dynamic>).map((value) {
        final day = value as Map<String, dynamic>;
        return AiWorkoutDay(
          name: day['name'] as String,
          exercises: (day['exercises'] as List<dynamic>).map((value) {
            final exercise = value as Map<String, dynamic>;
            return AiWorkoutExercise(
              exerciseName: exercise['exerciseName'] as String,
              targetSets: (exercise['targetSets'] as num).toInt(),
              targetReps: (exercise['targetReps'] as num?)?.toInt(),
              targetWeightKg: double.tryParse(
                '${exercise['targetWeight'] ?? ''}',
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
Map<String, dynamic> _aiWorkoutDraftBody(AiWorkoutPlanDraft draft) => {
  'name': draft.name,
  if (draft.description?.isNotEmpty == true) 'description': draft.description,
  'days': draft.days
      .map(
        (day) => {
          'name': day.name,
          'exercises': day.exercises
              .map(
                (exercise) => {
                  'exerciseName': exercise.exerciseName,
                  'targetSets': exercise.targetSets,
                  if (exercise.targetReps != null)
                    'targetReps': exercise.targetReps,
                  if (exercise.targetWeightKg != null)
                    'targetWeight': exercise.targetWeightKg,
                },
              )
              .toList(),
        },
      )
      .toList(),
};
WeightUnit _recordWeightUnit(Map<String, dynamic> record) =>
    ((record['settings'] as Map<String, dynamic>)['weight_unit'] as String) ==
        'kg'
    ? WeightUnit.kg
    : WeightUnit.lb;

List<WorkoutPlan> _plans(Map<String, dynamic> record, WeightUnit weightUnit) =>
    (record['workoutPlans'] as List<dynamic>).map((value) {
      final plan = value as Map<String, dynamic>;
      return WorkoutPlan(
        id: plan['id'] as String,
        name: plan['name'] as String,
        description: plan['description'] as String?,
        updatedAt: DateTime.parse(plan['createdAt'] as String),
        days: (plan['days'] as List<dynamic>).map((value) {
          final day = value as Map<String, dynamic>;
          return WorkoutPlanDay(
            id: day['id'] as String,
            name: day['name'] as String,
            sortOrder: day['sortOrder'] as int,
            exercises: (day['exercises'] as List<dynamic>).map((value) {
              final entry = value as Map<String, dynamic>;
              return PlanExercise(
                id: entry['id'] as String,
                exercise: Exercise(
                  id: entry['exerciseId'] as String,
                  name: entry['name'] as String,
                  category: entry['category'] as String,
                  muscleGroup: entry['muscleGroup'] as String?,
                  demoUrl: entry['demoUrl'] as String?,
                  demoSourceName: entry['demoSourceName'] as String?,
                ),
                sortOrder: entry['sortOrder'] as int,
                targetSets: (entry['targetSets'] as num?)?.toInt() ?? 3,
                targetReps: (entry['targetReps'] as num?)?.toInt() ?? 10,
                targetWeightKg: entry['targetWeight'] == null
                    ? null
                    : toKg(_number(entry['targetWeight']), weightUnit),
              );
            }).toList(),
          );
        }).toList(),
      );
    }).toList();
WorkoutSession _session(
  Map<String, dynamic> body, {
  required String planId,
  required String planDayId,
  DateTime? restEndsAt,
  required Map<String, String> setExercise,
  required WeightUnit weightUnit,
}) {
  final info = body['session'] as Map<String, dynamic>;
  final previous = <String, List<PreviousPerformance>>{};
  for (final value in (body['previousPerformances'] as List<dynamic>)) {
    final row = value as Map<String, dynamic>;
    final exerciseId = row['exerciseId'] as String;
    previous
        .putIfAbsent(exerciseId, () => [])
        .add(
          PreviousPerformance(
            sessionId: 'previous',
            completedAt: DateTime.parse(row['startedAt'] as String),
            weightKg: toKg(
              double.tryParse('${row['weight'] ?? ''}') ?? 0,
              weightUnit,
            ),
            reps: row['reps'] as int,
            setOrder: (row['order'] as num?)?.toInt() ?? 1,
          ),
        );
  }
  for (final performances in previous.values) {
    performances.sort((left, right) => left.setOrder.compareTo(right.setOrder));
  }
  final sets = (body['sets'] as List<dynamic>)
      .map((value) => _set(value as Map<String, dynamic>, weightUnit))
      .toList();
  for (final set in sets) {
    setExercise[set.id] = set.sessionExerciseId;
  }
  return WorkoutSession(
    id: info['id'] as String,
    planId: planId,
    planName: (info['routineName'] as String?) ?? 'Workout',
    planDayId: planDayId,
    planDayName: (info['dayName'] as String?) ?? 'Workout day',
    status: SessionStatus.values.byName(info['status'] as String),
    startedAt: DateTime.parse(info['startedAt'] as String),
    completedAt: info['endedAt'] == null
        ? null
        : DateTime.parse(info['endedAt'] as String),
    updatedAt: DateTime.parse(info['startedAt'] as String),
    restEndsAt: restEndsAt,
    exercises: (body['exercises'] as List<dynamic>).map((value) {
      final row = value as Map<String, dynamic>;
      final id = row['id'] as String;
      final sessionPrevious = previous[id] ?? const <PreviousPerformance>[];
      return SessionExercise(
        id: id,
        exerciseId: id,
        name: row['name'] as String,
        muscleGroup: row['muscleGroup'] as String?,
        demoUrl: row['demoUrl'] as String?,
        demoSourceName: row['demoSourceName'] as String?,
        sortOrder: 0,
        targetSets: (row['targetSets'] as num?)?.toInt() ?? 3,
        targetReps: (row['targetReps'] as num?)?.toInt() ?? 10,
        targetWeightKg: row['targetWeight'] == null
            ? null
            : toKg(_number(row['targetWeight']), weightUnit),
        previousPerformance: sessionPrevious.isEmpty
            ? null
            : sessionPrevious.last,
        previousPerformances: sessionPrevious,
        sets: sets.where((set) => set.sessionExerciseId == id).toList(),
      );
    }).toList(),
  );
}

class ApiFastingRepository implements FastingRepository {
  ApiFastingRepository(this._dio);
  final Dio _dio;

  @override
  Future<FastingRecord> read() async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/record'),
    );
    final fasting = body.data!['fasting'] as Map<String, dynamic>;
    return FastingRecord(
      active: fasting['active'] == null
          ? null
          : _activeFast(fasting['active'] as Map<String, dynamic>),
      logs: (fasting['logs'] as List<dynamic>)
          .map((item) => _fastingLog(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<ActiveFast> start({int? targetMinutes, String? note}) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/fasting',
        data: {
          'action': 'start',
          'targetMinutes': ?targetMinutes,
          'note': ?note,
        },
      ),
    );
    return _activeFastResponse(body.data!['active'] as Map<String, dynamic>);
  }

  @override
  Future<bool> end({String? note}) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/fasting',
        data: {'action': 'end', 'note': ?note},
      ),
    );
    return body.data!['discarded'] == true;
  }

  @override
  Future<void> deleteLog(String id) async {
    await _request(() => _dio.delete<void>('/v1/fasting/$id'));
  }
}

class ApiProgressRepository implements ProgressRepository {
  ApiProgressRepository(this._dio);
  final Dio _dio;

  @override
  Future<ProgressRecord> read() async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/record'),
    );
    final record = body.data!;
    return ProgressRecord(
      photos: (record['progress'] as List<dynamic>)
          .map((item) => _progressPhoto(item as Map<String, dynamic>))
          .toList(),
      sessions: (record['sessions'] as List<dynamic>)
          .map((item) => _progressSession(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<void> create(ProgressPhotoUpload upload) async {
    if (!upload.mimeType.startsWith('image/')) {
      throw const AppFailure('invalid_progress_photo', 'Choose an image file.');
    }
    if (upload.bytes.lengthInBytes == 0 ||
        upload.bytes.lengthInBytes > 20 * 1024 * 1024) {
      throw const AppFailure(
        'progress_photo_too_large',
        'Choose an image smaller than 20 MB.',
      );
    }
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/progress/upload',
        queryParameters: {
          'fileName': upload.fileName,
          'capturedAt': _date(upload.capturedAt),
          if (upload.note != null) 'note': upload.note,
        },
        data: upload.bytes,
        options: Options(contentType: upload.mimeType),
      ),
    );
  }

  @override
  Future<Uint8List> readImageBytes(String id) async {
    final response = await _request(
      () => _dio.get<List<int>>(
        '/v1/progress/$id/image',
        options: Options(responseType: ResponseType.bytes),
      ),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const AppFailure(
        'progress_image_unavailable',
        'That progress photo is unavailable.',
      );
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> updateCapturedAt(String id, DateTime capturedAt) async {
    await _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/v1/progress/$id',
        data: {'capturedAt': _date(capturedAt)},
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _request(() => _dio.delete<void>('/v1/progress/$id'));
  }
}

class ApiNutritionRepository implements NutritionRepository {
  ApiNutritionRepository(this._dio);
  final Dio _dio;

  @override
  Future<NutritionRecord> read() async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/record'),
    );
    final nutrition = body.data!['nutrition'] as Map<String, dynamic>;
    return NutritionRecord(
      foods: (nutrition['foods'] as List<dynamic>)
          .map((item) => _food(item as Map<String, dynamic>))
          .toList(),
      meals: (nutrition['meals'] as List<dynamic>)
          .map((item) => _nutritionMeal(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Food> createFood(Food food) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/foods',
        data: {
          'name': food.name,
          'barcodeUpc': ?food.barcodeUpc,
          'caloriesKcal': food.caloriesKcal.round(),
          'proteinG': food.proteinG,
          'carbsG': food.carbsG,
          'fatG': food.fatG,
          'servingSizeValue': ?food.servingSizeValue,
          'servingSizeUnit': ?food.servingSizeUnit?.name.replaceFirst(
            'flOz',
            'fl oz',
          ),
          'servingSizeText': ?food.servingSizeText,
        },
      ),
    );
    final created = body.data!['food'] as Map<String, dynamic>;
    return Food(
      id: created['id'] as String,
      name: created['name'] as String,
      caloriesKcal: (created['calories_kcal'] as num).toDouble(),
      proteinG: _number(created['protein_g']),
      carbsG: _number(created['carbs_g']),
      fatG: _number(created['fat_g']),
      barcodeUpc: food.barcodeUpc,
      servingSizeValue: food.servingSizeValue,
      servingSizeUnit: food.servingSizeUnit,
      servingSizeText: food.servingSizeText,
    );
  }

  @override
  Future<void> createMeal(
    MealType type,
    List<MealItemInput> items, {
    DateTime? consumedAt,
  }) async {
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/meals',
        data: {
          'mealType': type.name,
          if (consumedAt != null)
            'consumedAt': consumedAt.toUtc().toIso8601String(),
          'items': items
              .map((item) => {'foodId': item.foodId, 'grams': item.grams})
              .toList(),
        },
      ),
    );
  }

  @override
  Future<void> updateMeal(
    String id, {
    required MealType type,
    required double grams,
    required DateTime consumedAt,
  }) async {
    await _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/v1/meals/$id',
        data: {
          'mealType': type.name,
          'grams': grams,
          'consumedAt': consumedAt.toUtc().toIso8601String(),
        },
      ),
    );
  }

  @override
  Future<void> deleteMeal(String id) async {
    await _request(() => _dio.delete<void>('/v1/meals/$id'));
  }

  @override
  Future<void> uploadMealPhoto(
    String mealId,
    ProgressPhotoUpload upload,
  ) async {
    if (!upload.mimeType.startsWith('image/') ||
        upload.bytes.isEmpty ||
        upload.bytes.lengthInBytes > 20 * 1024 * 1024) {
      throw const AppFailure(
        'invalid_meal_photo',
        'Choose an image smaller than 20 MB.',
      );
    }
    final signed = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/meals/$mealId/photo/presign',
        data: {'fileName': upload.fileName, 'contentType': upload.mimeType},
      ),
    );
    try {
      await Dio().put<void>(
        signed.data!['url'] as String,
        data: upload.bytes,
        options: Options(headers: {'content-type': upload.mimeType}),
      );
    } on DioException catch (_) {
      throw const AppFailure(
        'meal_photo_upload_failed',
        'The meal photo could not be uploaded.',
      );
    }
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/meals/$mealId/photo',
        data: {
          'objectKey': signed.data!['key'] as String,
          'mimeType': upload.mimeType,
          'sizeBytes': upload.bytes.lengthInBytes,
        },
      ),
    );
  }

  @override
  Future<NutritionLookup> lookupBarcode(String code) async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/barcodes/$code'),
    );
    final value = body.data!;
    return NutritionLookup(
      found: value['found'] == true,
      source: value['source'] as String,
      food: value['food'] == null
          ? null
          : _barcodeFood(value['food'] as Map<String, dynamic>),
    );
  }

  @override
  Future<NutritionLookup> parseNutritionLabel(List<int> bytes) async {
    if (bytes.length > 9 * 1024 * 1024) {
      throw const AppFailure(
        'label_too_large',
        'Choose a readable nutrition-label image smaller than 9 MB.',
      );
    }
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/nutrition-label/parse',
        data: {'imageBase64': base64Encode(bytes)},
      ),
    );
    final value = body.data!;
    final parsed = value['parsed'] as Map<String, dynamic>;
    return NutritionLookup(
      found: true,
      source: value['source'] as String,
      confidence: _number(parsed['parseConfidence']),
      food: Food(
        id: 'draft',
        name: parsed['name'] as String? ?? '',
        caloriesKcal: _number(parsed['caloriesKcal']),
        proteinG: _number(parsed['proteinG']),
        carbsG: _number(parsed['carbsG']),
        fatG: _number(parsed['fatG']),
        servingSizeValue: parsed['servingSizeValue'] == null
            ? null
            : _number(parsed['servingSizeValue']),
        servingSizeUnit: _servingUnit(parsed['servingSizeUnit']),
        servingSizeText: parsed['servingSizeText'] as String?,
      ),
    );
  }
}

class ApiArcanaRepository implements ArcanaRepository {
  ApiArcanaRepository(this._dio);
  final Dio _dio;

  @override
  Future<ArcanaData> read() async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/arcana'),
    );
    return mapArcanaResponse(body.data!);
  }

  @override
  Future<ArcanaData> pin(ArcanaSlot slot, String cardId) async {
    final body = await _request(
      () => _dio.put<Map<String, dynamic>>(
        '/v1/arcana/pins',
        data: {'slot': slot.name, 'cardId': cardId},
      ),
    );
    return mapArcanaResponse(body.data!);
  }

  @override
  Future<ArcanaData> reconcile() async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>('/v1/arcana/reconcile'),
    );
    return mapArcanaResponse(body.data!['arcana'] as Map<String, dynamic>);
  }
}

class ApiFriendsRepository implements FriendsRepository {
  ApiFriendsRepository(this._dio);
  final Dio _dio;

  @override
  Future<FriendsRecord> read() async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/record'),
    );
    return _friends(body.data!['friends'] as Map<String, dynamic>);
  }

  @override
  Future<SharedWorkoutSession> getSharedSession(String sessionId) async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/sessions/$sessionId/share'),
    );
    return _sharedWorkoutSession(body.data!);
  }

  @override
  Future<void> sendRequest(String username) async {
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/friends',
        data: {'username': username.trim()},
      ),
    );
  }

  @override
  Future<void> accept(String requestId) async {
    await _request(() => _dio.post<void>('/v1/friends/$requestId/accept'));
  }

  @override
  Future<void> reject(String requestId) async {
    await _request(() => _dio.post<void>('/v1/friends/$requestId/reject'));
  }

  @override
  Future<void> remove(String userId) async {
    await _request(() => _dio.delete<void>('/v1/friends/$userId'));
  }
}

class ApiPreferencesRepository implements PreferencesRepository {
  ApiPreferencesRepository(this._dio);
  final Dio _dio;

  @override
  Future<UserPreferences> read() async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/record'),
    );
    return _preferences(body.data!['settings'] as Map<String, dynamic>);
  }

  @override
  Future<UserPreferences> setWeightUnit(WeightUnit unit) async {
    await _request(
      () => _dio.put<Map<String, dynamic>>(
        '/v1/preferences/weight-unit',
        data: {'weightUnit': unit == WeightUnit.kg ? 'kg' : 'lbs'},
      ),
    );
    return read();
  }

  @override
  Future<UserPreferences> setActivePlan(String? planId) async {
    await _request(
      () => _dio.put<Map<String, dynamic>>(
        '/v1/preferences/active-plan',
        data: {'routineId': planId},
      ),
    );
    return read();
  }

  @override
  Future<ThemePreference?> getTheme() async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/preferences/theme'),
    );
    final preference = body.data!['preference'];
    return preference == null
        ? null
        : _themePreference(preference as Map<String, dynamic>);
  }

  @override
  Future<ThemePreference> setTheme(ThemePreference preference) async {
    final body = await _request(
      () => _dio.put<Map<String, dynamic>>(
        '/v1/preferences/theme',
        data: _themePreferenceBody(preference),
      ),
    );
    return _themePreference(body.data!['preference'] as Map<String, dynamic>);
  }
}

class ApiGoalRepository implements GoalRepository {
  ApiGoalRepository(this._dio);
  final Dio _dio;
  @override
  Future<List<Goal>> listGoals() async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/goals'),
    );
    return (body.data!['goals'] as List<dynamic>)
        .map((value) => _goal(value as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Goal> createGoal(Goal goal) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/goals',
        data: {
          'title': goal.title,
          'category': goal.category.name,
          'baselineValue': goal.baseline,
          'targetValue': goal.target,
          'unit': goal.unit,
          'targetDate': goal.targetDate.toIso8601String().substring(0, 10),
        },
      ),
    );
    return _goal(body.data!['goal'] as Map<String, dynamic>);
  }

  @override
  Future<Goal> updateStatus(String goalId, GoalStatus status) async {
    final body = await _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/v1/goals/$goalId',
        data: {'status': status.name},
      ),
    );
    return _goal(body.data!['goal'] as Map<String, dynamic>);
  }

  @override
  Future<void> assess(
    String goalId,
    double value,
    String note, {
    String? decision,
  }) async {
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/goals/$goalId/assessments',
        data: {
          'value': value,
          'note': note,
          if (decision?.isNotEmpty == true) 'decision': decision,
        },
      ),
    );
  }
}

class ApiPlanningRepository implements PlanningRepository {
  ApiPlanningRepository(this._dio);
  final Dio _dio;
  @override
  Future<List<TrainingBlock>> listBlocks() async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/training-blocks'),
    );
    return (body.data!['blocks'] as List<dynamic>)
        .map((item) => _block(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TrainingBlock> createBlock(TrainingBlock block) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/training-blocks',
        data: {
          'name': block.name,
          'startDate': _date(block.startDate),
          'endDate': _date(block.endDate),
          'targetSessionsPerWeek': block.targetSessionsPerWeek,
          if (block.note?.isNotEmpty == true) 'note': block.note,
        },
      ),
    );
    return _block(body.data!['block'] as Map<String, dynamic>);
  }

  @override
  Future<TrainingBlock> updateBlock(
    String blockId, {
    TrainingBlockStatus? status,
    String? note,
  }) async {
    final body = await _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/v1/training-blocks/$blockId',
        data: {'status': ?status?.name, 'note': ?note},
      ),
    );
    return _block(body.data!['block'] as Map<String, dynamic>);
  }

  @override
  Future<ScheduledBlockSession> scheduleSession(
    String blockId,
    ScheduledBlockSession session,
  ) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/training-blocks/$blockId/sessions',
        data: {
          'scheduledFor': _date(session.scheduledFor),
          'status': session.status.name,
          'isDeload': session.isDeload,
          'isRecoverySession': session.isRecoverySession,
          'note': ?session.note,
        },
      ),
    );
    return _scheduledSession(body.data!['session'] as Map<String, dynamic>);
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
    final body = await _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/v1/training-block-sessions/$sessionId',
        data: {
          'scheduledFor': ?(scheduledFor == null ? null : _date(scheduledFor)),
          'status': ?status?.name,
          'isDeload': ?isDeload,
          'isRecoverySession': ?isRecoverySession,
          'note': ?note,
        },
      ),
    );
    return _scheduledSession(body.data!['session'] as Map<String, dynamic>);
  }

  @override
  Future<List<WeeklyReview>> listReviews() async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/v1/weekly-reviews'),
    );
    return (body.data!['reviews'] as List<dynamic>)
        .map((item) => _review(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WeeklyReview> createReview(WeeklyReview review) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/weekly-reviews',
        data: {
          'weekStart': _date(review.weekStart),
          'weekEnd': _date(review.weekEnd),
          'reflection': review.reflection,
          'decision': review.decision,
          if (review.adjustments?.isNotEmpty == true)
            'adjustments': review.adjustments,
        },
      ),
    );
    return _review(body.data!['review'] as Map<String, dynamic>);
  }
}

String _date(DateTime value) => value.toIso8601String().substring(0, 10);
TrainingBlock _block(Map<String, dynamic> map) => TrainingBlock(
  id: map['id'] as String,
  name: map['title'] as String,
  startDate: DateTime.parse(map['start_date'] as String),
  endDate: DateTime.parse(map['end_date'] as String),
  targetSessionsPerWeek: map['weekly_target'] as int,
  status: TrainingBlockStatus.values.byName(map['status'] as String),
  note: map['primary_goal'] as String?,
  sessions: ((map['sessions'] as List<dynamic>?) ?? const [])
      .map((item) => _scheduledSession(item as Map<String, dynamic>))
      .toList(),
);
ScheduledBlockSession _scheduledSession(Map<String, dynamic> map) =>
    ScheduledBlockSession(
      id: map['id'] as String,
      scheduledFor: DateTime.parse(map['scheduled_on'] as String),
      status: ScheduledBlockSessionStatus.values.byName(
        map['status'] as String,
      ),
      isDeload: map['is_deload'] as bool? ?? false,
      isRecoverySession: map['is_recovery_session'] as bool? ?? false,
      note: map['skip_reason'] as String?,
    );
WeeklyReview _review(Map<String, dynamic> map) => WeeklyReview(
  id: map['id'] as String,
  weekStart: DateTime.parse(map['period_start'] as String),
  weekEnd: DateTime.parse(map['period_end'] as String),
  reflection: map['what_worked'] as String,
  decision: map['decision'] as String,
  adjustments: map['what_did_not'] as String?,
);

Goal _goal(Map<String, dynamic> map) => Goal(
  id: map['id'] as String,
  title: map['metric_type'] as String,
  category: GoalCategory.values.byName(map['domain'] as String),
  baseline: (map['baseline_value'] as num).toDouble(),
  target: (map['target_value'] as num).toDouble(),
  unit: map['measurement_method'] as String,
  targetDate: DateTime.parse(map['target_date'] as String),
  status: GoalStatus.values.byName(map['status'] as String),
  assessments: ((map['assessments'] as List<dynamic>?) ?? const [])
      .map((item) => _assessment(item as Map<String, dynamic>))
      .toList(),
);
GoalAssessment _assessment(Map<String, dynamic> map) => GoalAssessment(
  id: map['id'] as String,
  assessedAt: DateTime.parse(map['assessed_on'] as String),
  value: (map['value'] as num).toDouble(),
  reason: map['decision_reason'] as String? ?? '',
  decision: map['decision'] as String?,
);

ActiveFast _activeFast(Map<String, dynamic> map) => ActiveFast(
  id: map['id'] as String,
  startedAt: DateTime.parse(map['started_at'] as String),
  targetMinutes: map['target_minutes'] as int?,
  note: map['note'] as String?,
);
ActiveFast _activeFastResponse(Map<String, dynamic> map) => ActiveFast(
  id: map['id'] as String,
  startedAt: DateTime.parse(map['startedAt'] as String),
  targetMinutes: map['targetMinutes'] as int?,
  note: map['note'] as String?,
);
FastingLog _fastingLog(Map<String, dynamic> map) => FastingLog(
  id: map['id'] as String,
  startedAt: DateTime.parse(map['started_at'] as String),
  endedAt: DateTime.parse(map['ended_at'] as String),
  durationMinutes: map['duration_minutes'] as int,
  targetMinutes: map['target_minutes'] as int?,
  note: map['note'] as String?,
);
ProgressPhoto _progressPhoto(Map<String, dynamic> map) => ProgressPhoto(
  id: map['id'] as String,
  capturedAt: DateTime.parse(map['captured_at'] as String),
  mimeType: map['mime_type'] as String,
  note: map['note'] as String?,
  imageUrl: map['imageUrl'] as String?,
);
ProgressSession _progressSession(Map<String, dynamic> map) => ProgressSession(
  id: map['id'] as String,
  startedAt: DateTime.parse(map['started_at'] as String),
  endedAt: map['ended_at'] == null
      ? null
      : DateTime.parse(map['ended_at'] as String),
  status: SessionStatus.values.byName(map['status'] as String),
  planName: map['routine_name'] as String?,
  planDayName: map['day_name'] as String?,
);
double _number(Object? value) =>
    value is num ? value.toDouble() : double.parse('$value');
ServingUnit? _servingUnit(Object? value) {
  final raw = value as String?;
  if (raw == null) return null;
  for (final unit in ServingUnit.values) {
    if (servingUnitLabel(unit) == raw) return unit;
  }
  return null;
}

Food _food(Map<String, dynamic> map) => Food(
  id: map['id'] as String,
  name: map['name'] as String,
  barcodeUpc: map['barcode_upc'] as String?,
  caloriesKcal: _number(map['calories_kcal']),
  proteinG: _number(map['protein_g']),
  carbsG: _number(map['carbs_g']),
  fatG: _number(map['fat_g']),
  servingSizeValue: map['serving_size_g'] == null
      ? null
      : _number(map['serving_size_g']),
  servingSizeUnit: _servingUnit(map['serving_size_unit']),
  servingSizeText: map['serving_size_text'] as String?,
);
NutritionMeal _nutritionMeal(Map<String, dynamic> map) => NutritionMeal(
  id: map['id'] as String,
  foodId: map['food_id'] as String,
  foodName: map['name'] as String,
  mealType: MealType.values.byName(map['meal_type'] as String),
  grams: _number(map['quantity']),
  consumedAt: DateTime.parse(map['consumed_at'] as String),
  caloriesKcal: _number(map['calories_kcal']),
  proteinG: _number(map['protein_g']),
  carbsG: _number(map['carbs_g']),
  fatG: _number(map['fat_g']),
  servingSizeValue: map['serving_size_g'] == null
      ? null
      : _number(map['serving_size_g']),
  servingSizeUnit: _servingUnit(map['serving_size_unit']),
  servingSizeText: map['serving_size_text'] as String?,
  imageUrl: map['imageUrl'] as String?,
);
Food _barcodeFood(Map<String, dynamic> map) => Food(
  id: map['id'] as String? ?? 'draft',
  name: map['name'] as String,
  barcodeUpc: map['barcodeUpc'] as String?,
  caloriesKcal: _number(map['caloriesKcal']),
  proteinG: _number(map['proteinG']),
  carbsG: _number(map['carbsG']),
  fatG: _number(map['fatG']),
  servingSizeValue: map['servingSizeValue'] == null
      ? null
      : _number(map['servingSizeValue']),
  servingSizeUnit: _servingUnit(map['servingSizeUnit']),
  servingSizeText: map['servingSizeText'] as String?,
);
ArcanaData mapArcanaResponse(Map<String, dynamic> map) => ArcanaData(
  ruleVersion: map['ruleVersion'] as int,
  cards: (map['cards'] as List<dynamic>)
      .map((item) => _arcanaCard(item as Map<String, dynamic>))
      .toList(),
  pins: {
    for (final slot in ArcanaSlot.values)
      slot: (map['pins'] as Map<String, dynamic>)[slot.name] as String?,
  },
);

FriendsRecord _friends(Map<String, dynamic> map) => FriendsRecord(
  incoming: ((map['incoming'] as List<dynamic>?) ?? const [])
      .map((item) => _friendRequest(item as Map<String, dynamic>))
      .toList(),
  outgoing: ((map['outgoing'] as List<dynamic>?) ?? const [])
      .map((item) => _friendRequest(item as Map<String, dynamic>))
      .toList(),
  activity: ((map['activity'] as List<dynamic>?) ?? const [])
      .map((item) => _friendActivity(item as Map<String, dynamic>))
      .toList(),
);
SharedWorkoutSession _sharedWorkoutSession(Map<String, dynamic> map) {
  final owner = map['owner'] as Map<String, dynamic>;
  final session = map['session'] as Map<String, dynamic>;
  return SharedWorkoutSession(
    ownerId: owner['id'] as String,
    ownerUsername: owner['username'] as String,
    ownerName: owner['name'] as String?,
    sessionId: session['id'] as String,
    status: session['status'] as String,
    startedAt: DateTime.parse(session['startedAt'] as String),
    endedAt: session['endedAt'] == null
        ? null
        : DateTime.parse(session['endedAt'] as String),
    routineName: session['routineName'] as String?,
    dayName: session['dayName'] as String?,
    weightUnit: session['weightUnit'] == 'kg' ? WeightUnit.kg : WeightUnit.lb,
    sets: (map['sets'] as List<dynamic>)
        .map((item) => _sharedWorkoutSet(item as Map<String, dynamic>))
        .toList(),
  );
}

SharedWorkoutSet _sharedWorkoutSet(Map<String, dynamic> map) =>
    SharedWorkoutSet(
      id: map['id'] as String,
      exerciseName: map['exerciseName'] as String,
      order: map['order'] as int,
      reps: map['reps'] as int,
      weight: map['weight'] == null ? null : _number(map['weight']),
      isWarmup: map['isWarmup'] == true,
    );
FriendRequest _friendRequest(Map<String, dynamic> map) => FriendRequest(
  id: map['id'] as String,
  status: map['status'] as String,
  userId: map['userId'] as String,
  username: map['username'] as String,
  name: map['name'] as String?,
);
FriendActivity _friendActivity(Map<String, dynamic> map) => FriendActivity(
  id: map['id'] as String,
  userId: map['userId'] as String,
  username: map['username'] as String,
  name: map['name'] as String?,
  startedAt: DateTime.parse(map['startedAt'] as String),
  status: map['status'] as String,
  routineName: map['routineName'] as String?,
  dayName: map['dayName'] as String?,
  setCount: map['setCount'] as int,
);
UserPreferences _preferences(Map<String, dynamic> map) => UserPreferences(
  weightUnit: map['weight_unit'] == 'kg' ? WeightUnit.kg : WeightUnit.lb,
  activePlanId: map['active_routine_id'] as String?,
  theme: _themeFromOverrides(map['theme_overrides']),
);
ThemePreference? _themeFromOverrides(Object? value) {
  if (value is! Map<String, dynamic> || value['mobileTheme'] == null) {
    return null;
  }
  return _themePreference(value['mobileTheme'] as Map<String, dynamic>);
}

ThemePreference _themePreference(Map<String, dynamic> map) => ThemePreference(
  palette: _palette(map['theme'] as String),
  brightness: (map['mode'] as String) == 'dark'
      ? PreferenceBrightness.dark
      : PreferenceBrightness.light,
);
ThemePalette _palette(String value) => switch (value) {
  'flame-alchemist' => ThemePalette.flameAlchemist,
  'hawkeye' => ThemePalette.hawkeye,
  'automail-mechanic' => ThemePalette.automailMechanic,
  'avarice' => ThemePalette.avarice,
  'scarred-man' => ThemePalette.scarredMan,
  'armor-bound-soul' => ThemePalette.armorBoundSoul,
  _ => ThemePalette.transmute,
};
Map<String, dynamic> _themePreferenceBody(ThemePreference preference) => {
  'theme': switch (preference.palette) {
    ThemePalette.flameAlchemist => 'flame-alchemist',
    ThemePalette.hawkeye => 'hawkeye',
    ThemePalette.automailMechanic => 'automail-mechanic',
    ThemePalette.avarice => 'avarice',
    ThemePalette.scarredMan => 'scarred-man',
    ThemePalette.armorBoundSoul => 'armor-bound-soul',
    ThemePalette.transmute => 'transmute',
  },
  'mode': preference.brightness == PreferenceBrightness.dark ? 'dark' : 'light',
};
ArcanaCard _arcanaCard(Map<String, dynamic> map) {
  return ArcanaCard(
    id: map['id'] as String,
    number: map['number'] as String,
    name: map['name'] as String,
    focus: map['focus'] as String,
    source: map['source'] as String,
    stage: ArcanaStage.values.byName(map['stage'] as String),
    earnedAt: map['earnedAt'] == null
        ? null
        : DateTime.parse(map['earnedAt'] as String),
    stageEvidence: _arcanaEvidenceByStage(map['stageEvidence']),
    nextMilestone: map['nextMilestone'] == null
        ? null
        : _arcanaMilestone(map['nextMilestone'] as Map<String, dynamic>),
  );
}

/// Normalizes the actual Arcana response while preserving its one canonical
/// model. Older persisted `user_arcana_states` rows can contain a JSON-encoded
/// stage map inside one stage entry; the API currently returns that exact
/// shape. We unwrap only valid Arcana stage keys, then map the evidence.
Map<ArcanaStage, ArcanaEvidence> _arcanaEvidenceByStage(Object? value) {
  final raw = _arcanaJsonMap(value);
  final evidence = <ArcanaStage, ArcanaEvidence>{};
  for (final entry in raw.entries) {
    final stage = ArcanaStage.values.byName(entry.key);
    final candidate = _arcanaJsonMap(entry.value);
    final nestedStages = candidate.keys
        .where((key) => ArcanaStage.values.any((stage) => stage.name == key))
        .toList();
    if (nestedStages.isEmpty) {
      evidence[stage] = _arcanaEvidence(candidate);
      continue;
    }
    if (nestedStages.length != candidate.length) {
      throw const AppFailure(
        'arcana_contract_error',
        'Arcana returned an invalid evidence record.',
      );
    }
    for (final nested in candidate.entries) {
      evidence[ArcanaStage.values.byName(nested.key)] = _arcanaEvidence(
        _arcanaJsonMap(nested.value),
      );
    }
  }
  return evidence;
}

Map<String, dynamic> _arcanaJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  if (value is String) {
    final decoded = jsonDecode(value);
    if (decoded is Map) return decoded.cast<String, dynamic>();
  }
  throw const AppFailure(
    'arcana_contract_error',
    'Arcana returned an invalid evidence record.',
  );
}

ArcanaEvidence _arcanaEvidence(Map<String, dynamic> map) => ArcanaEvidence(
  summary: map['summary'] as String?,
  stats:
      (map['stats'] as Map<String, dynamic>?)?.cast<String, Object?>() ??
      const {},
  earnedAt: map['earnedAt'] == null
      ? null
      : DateTime.parse(map['earnedAt'] as String),
);
ArcanaMilestone _arcanaMilestone(Map<String, dynamic> map) => ArcanaMilestone(
  stage: ArcanaStage.values.byName(map['stage'] as String),
  description: map['description'] as String,
  current: map['current'] as int,
  target: map['target'] as int,
);

WeightUnit _expoSessionWeightUnit(Map<String, dynamic> body) =>
    (body['session'] as Map<String, dynamic>)['weightUnit'] == 'kg'
    ? WeightUnit.kg
    : WeightUnit.lb;

LoggedSet _set(Map<String, dynamic> map, WeightUnit weightUnit) => LoggedSet(
  id: map['id'] as String,
  sessionExerciseId: map['exerciseId'] as String,
  setOrder: map['setOrder'] as int,
  weightKg: map['weight'] == null
      ? 0
      : toKg(_number(map['weight']), weightUnit),
  reps: map['reps'] as int,
  completedAt: DateTime.parse(map['createdAt'] as String),
  isWarmup: map['isWarmup'] == true,
);
PersonalRecord _personalRecord(
  Map<String, dynamic> map,
  WeightUnit weightUnit,
) {
  final current = map['current'] as Map<String, dynamic>;
  final previous = map['previous'] as Map<String, dynamic>;
  return PersonalRecord(
    exerciseName: map['exerciseName'] as String,
    kind: map['kind'] == 'estimated_1rm'
        ? PersonalRecordKind.estimatedOneRepMax
        : PersonalRecordKind.reps,
    currentReps: current['reps'] as int,
    currentWeightKg: current['weight'] == null
        ? 0
        : toKg(_number(current['weight']), weightUnit),
    previousReps: previous['reps'] as int,
    previousWeightKg: previous['weight'] == null
        ? 0
        : toKg(_number(previous['weight']), weightUnit),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
