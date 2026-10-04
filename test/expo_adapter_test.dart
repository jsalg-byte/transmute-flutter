import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:transmute_flutter/core/api/api_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  test(
    'freeform adapter uses the dedicated route and restores origin',
    () async {
      final paths = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
      dio.httpClientAdapter = _StubAdapter((options) {
        paths.add(options.path);
        if (options.path == '/v1/sessions/freeform') {
          expect(options.method, 'POST');
          return {
            'session': {
              'id': 'freeform-1',
              'origin': 'freeform',
              'startedAt': '2026-10-03T12:00:00Z',
            },
          };
        }
        if (options.path == '/v1/record') {
          return {
            'dashboard': {
              'activeSession': {'id': 'freeform-1', 'origin': 'freeform'},
            },
          };
        }
        if (options.path == '/v1/sessions/freeform-1') {
          return {
            'session': {
              'id': 'freeform-1',
              'status': 'active',
              'origin': 'freeform',
              'startedAt': '2026-10-03T12:00:00Z',
              'endedAt': null,
              'routineName': null,
              'dayName': null,
              'weightUnit': 'lbs',
            },
            'exercises': <Map<String, dynamic>>[],
            'sets': <Map<String, dynamic>>[],
            'previousPerformances': <Map<String, dynamic>>[],
          };
        }
        throw StateError('Unexpected ${options.method} ${options.path}');
      });
      final first = ApiSessionRepository(
        dio,
        RestTimerStore(const FlutterSecureStorage()),
      );
      final started = await first.startFreeformSession();
      final restored = await ApiSessionRepository(
        dio,
        RestTimerStore(const FlutterSecureStorage()),
      ).activeSession();
      expect(started.origin, WorkoutSessionOrigin.freeform);
      expect(started.planDayId, isNull);
      expect(started.planName, 'Empty Workout');
      expect(restored?.id, started.id);
      expect(restored?.origin, WorkoutSessionOrigin.freeform);
      expect(paths, [
        '/v1/sessions/freeform',
        '/v1/sessions/freeform-1',
        '/v1/record',
        '/v1/sessions/freeform-1',
      ]);
    },
  );

  test('exercise rank adapter uses canonical rank paths and fields', () async {
    final paths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    dio.httpClientAdapter = _StubAdapter((options) {
      paths.add(options.path);
      final rank = {
        'exerciseId': 'rank-bench',
        'exerciseName': 'Bench press',
        'category': 'strength',
        'muscleGroup': 'Chest',
        'trackingMode': 'reps',
        'metric': 'estimated_1rm_kg',
        'baselineValue': 100,
        'bestValue': 115,
        'tier': 'Gold',
        'subdivision': 1,
        'progressPoints': 0,
        'nextThreshold': 130,
        'ruleVersion': 1,
        'calculatedAt': '2026-10-04T12:00:00Z',
      };
      if (options.path == '/v1/exercise-ranks')
        return {
          'ranks': [rank],
        };
      if (options.path == '/v1/exercise-ranks/rank-bench')
        return {
          'rank': {
            ...rank,
            'evidence': [
              {
                'sessionId': 'session-a',
                'completedAt': '2026-10-03T12:00:00Z',
                'value': 115,
              },
            ],
          },
        };
      throw StateError('Unexpected ${options.path}');
    });
    final repository = ApiExerciseRankRepository(dio);
    final list = await repository.listRanks(query: 'bench');
    final detail = await repository.getRank('rank-bench');
    expect(list.single.exercise.id, 'rank-bench');
    expect(detail.tier, ExerciseRankTier.gold);
    expect(detail.evidence.single.sessionId, 'session-a');
    expect(paths, ['/v1/exercise-ranks', '/v1/exercise-ranks/rank-bench']);
  });

  test(
    'freeform start exposes the existing active session on conflict',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
      dio.httpClientAdapter = _StatusAdapter({
        'code': 'active_session_exists',
        'error': 'Resume your existing workout.',
        'activeSessionId': 'existing-1',
      }, 409);
      await expectLater(
        ApiSessionRepository(
          dio,
          RestTimerStore(const FlutterSecureStorage()),
        ).startFreeformSession(),
        throwsA(
          isA<AppFailure>()
              .having(
                (failure) => failure.code,
                'code',
                'active_session_exists',
              )
              .having(
                (failure) => failure.activeSessionId,
                'active ID',
                'existing-1',
              ),
        ),
      );
    },
  );

  test('Expo plan adapter maps the aggregate record into plan days', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    dio.httpClientAdapter = _StubAdapter((options) {
      expect(options.path, '/v1/record');
      return {
        'workoutPlans': [
          {
            'id': 'plan-1',
            'name': 'Strength',
            'description': 'A verified plan.',
            'createdAt': '2026-08-11T12:00:00.000Z',
            'days': [
              {
                'id': 'day-1',
                'name': 'Push',
                'sortOrder': 0,
                'exercises': [
                  {
                    'id': 'entry-1',
                    'exerciseId': 'bench-1',
                    'name': 'Bench press',
                    'category': 'strength',
                    'muscleGroup': 'Chest',
                    'sortOrder': 0,
                    'targetSets': 3,
                    'targetReps': 8,
                    'targetWeight': '61.25',
                    'trackingMode': 'timed',
                    'targetDurationSeconds': 45,
                    'demoUrl': 'https://media.example.test/bench.gif',
                    'demoSourceName': 'Verified exercise source',
                  },
                ],
              },
            ],
          },
        ],
        'exercises': const [],
        'settings': {'weight_unit': 'kg'},
      };
    });

    final plan = (await ApiPlanRepository(dio).listPlans()).single;
    expect(plan.name, 'Strength');
    expect(plan.days.single.name, 'Push');
    expect(plan.days.single.exercises.single.targetWeightKg, 61.25);
    expect(
      plan.days.single.exercises.single.trackingMode,
      ExerciseTrackingMode.timed,
    );
    expect(plan.days.single.exercises.single.targetDurationSeconds, 45);
    expect(
      plan.days.single.exercises.single.exercise.demoUrl,
      'https://media.example.test/bench.gif',
    );
  });

  test(
    'routine adapter creates an empty folder and reads canonical reordered days',
    () async {
      final paths = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
      dio.httpClientAdapter = _StubAdapter((options) {
        paths.add(options.path);
        if (options.path == '/v1/plans') {
          expect(options.data, {'name': 'New cycle', 'empty': true});
          return {
            'plan': {'id': 'plan-new', 'name': 'New cycle', 'days': []},
          };
        }
        if (options.path == '/v1/plan-days/day-2/reorder') {
          expect(options.data, {'direction': 'up'});
          return {'id': 'day-2'};
        }
        expect(options.path, '/v1/record');
        return {
          'workoutPlans': [
            {
              'id': 'plan-new',
              'name': 'New cycle',
              'createdAt': '2026-10-03T12:00:00Z',
              'days': paths.contains('/v1/plan-days/day-2/reorder')
                  ? [
                      {
                        'id': 'day-2',
                        'name': 'Pull',
                        'sortOrder': 0,
                        'exercises': [],
                      },
                      {
                        'id': 'day-1',
                        'name': 'Push',
                        'sortOrder': 1,
                        'exercises': [],
                      },
                    ]
                  : [],
            },
          ],
          'exercises': [],
          'settings': {'weight_unit': 'kg'},
        };
      });
      final plans = ApiPlanRepository(dio);
      final created = await plans.createPlan('New cycle');
      expect(created.id, 'plan-new');
      expect(created.days, isEmpty);
      final reordered = await plans.reorderDay(
        'plan-new',
        'day-2',
        ReorderDirection.up,
      );
      expect(reordered.name, 'Pull');
      expect(paths, [
        '/v1/plans',
        '/v1/record',
        '/v1/plan-days/day-2/reorder',
        '/v1/record',
      ]);
    },
  );

  test(
    'routine share adapter uses immutable share endpoints and fields',
    () async {
      final paths = <String>[];
      const snapshot = {
        'routineName': 'Upper strength',
        'folderName': 'Upper A',
        'ownerName': 'Demo Alchemist',
        'ownerUsername': 'demo',
        'exercises': [
          {
            'exerciseId': 'bench-1',
            'name': 'Bench press',
            'category': 'strength',
            'muscleGroup': 'Chest',
            'targetSets': 3,
            'targetReps': 8,
            'trackingMode': 'reps',
            'targetDurationSeconds': null,
            'targetWeightKg': 61.235,
          },
        ],
      };
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
      dio.httpClientAdapter = _StubAdapter((options) {
        paths.add('${options.method} ${options.path}');
        if (options.method == 'POST' && options.path == '/v1/routine-shares') {
          expect(options.data, {'routineDayId': 'day-1'});
          return {
            'share': {
              'id': 'share-1',
              'token': 'share-token-12345678901234567890',
              'routineDayId': 'day-1',
              'status': 'active',
              'createdAt': '2026-10-03T12:00:00Z',
              'expiresAt': '2026-11-02T12:00:00Z',
              'snapshot': snapshot,
            },
          };
        }
        if (options.method == 'GET' && options.path == '/v1/routine-shares') {
          expect(options.queryParameters, {'routineDayId': 'day-1'});
          return {'shares': const []};
        }
        if (options.method == 'GET' &&
            options.path ==
                '/v1/routine-shares/share-token-12345678901234567890') {
          return {'share': snapshot};
        }
        if (options.method == 'POST' &&
            options.path ==
                '/v1/routine-shares/share-token-12345678901234567890/import') {
          expect(options.data, {
            'routineId': 'folder-1',
            'name': 'Recipient copy',
          });
          return {
            'day': {
              'id': 'copy-1',
              'name': 'Recipient copy',
              'sortOrder': 2,
              'sourceShareToken': 'share-token-12345678901234567890',
            },
          };
        }
        if (options.method == 'DELETE') return const <String, dynamic>{};
        throw StateError('Unexpected ${options.method} ${options.path}');
      });
      final repository = ApiPlanRepository(dio);
      final created = await repository.createRoutineShare('day-1');
      final preview = await repository.getRoutineShare(created.token);
      final imported = await repository.importRoutineShare(
        created.token,
        planId: 'folder-1',
        name: 'Recipient copy',
      );
      await repository.revokeRoutineShare(created.token);
      await repository.listRoutineShares('day-1');

      expect(created.snapshot.totalSets, 3);
      expect(preview.exercises.single.targetWeightKg, 61.235);
      expect(imported.id, 'copy-1');
      expect(paths, [
        'POST /v1/routine-shares',
        'GET /v1/routine-shares/share-token-12345678901234567890',
        'POST /v1/routine-shares/share-token-12345678901234567890/import',
        'DELETE /v1/routine-shares/share-token-12345678901234567890',
        'GET /v1/routine-shares',
      ]);
    },
  );

  test(
    'Expo adapter exposes conflicts as non-retryable domain failures',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
      dio.httpClientAdapter = _StatusAdapter({
        'error': 'Friend request already sent.',
      }, 409);

      try {
        await ApiPlanRepository(dio).listPlans();
        fail('Expected an AppFailure');
      } on AppFailure catch (failure) {
        expect(failure.code, 'conflict');
        expect(failure.retryable, isFalse);
        expect(failure.message, 'Friend request already sent.');
      }
    },
  );

  test(
    'Expo session weights convert exactly once at the API boundary',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
      Map<String, dynamic>? postedSet;
      dio.httpClientAdapter = _StubAdapter((options) {
        if (options.path == '/v1/record') {
          return {
            'dashboard': {
              'activeSession': {'id': 'session-1'},
            },
          };
        }
        if (options.path == '/v1/sessions/session-1') {
          return _poundSession();
        }
        if (options.path == '/v1/sessions/session-1/sets') {
          postedSet = Map<String, dynamic>.from(options.data as Map);
          return {
            'set': {
              'id': 'set-2',
              'exerciseId': 'entry-1',
              'setOrder': 2,
              'weight': 135,
              'reps': 8,
              'isWarmup': false,
              'createdAt': '2026-08-20T12:00:00.000Z',
            },
            'personalRecord': null,
          };
        }
        throw StateError('Unexpected ${options.method} ${options.path}');
      });

      final repository = ApiSessionRepository(
        dio,
        RestTimerStore(const FlutterSecureStorage()),
      );
      final session = (await repository.activeSession())!;

      expect(
        session.exercises.single.sets.single.weightKg,
        closeTo(61.235, .001),
      );
      expect(
        session.exercises.single.previousPerformance!.weightKg,
        closeTo(70.307, .001),
      );
      expect(session.exercises.single.previousPerformances, hasLength(2));
      expect(session.exercises.single.previousPerformances.first.reps, 8);
      expect(session.exercises.single.previousPerformances.last.reps, 5);
      expect(session.exercises.single.targetWeightKg, closeTo(61.235, .001));

      final result = await repository.createSet(
        'entry-1',
        toKg(135, WeightUnit.lb),
        8,
        clientOperationId: '123e4567-e89b-42d3-a456-426614174000',
      );

      expect(postedSet!['weight'], 135);
      expect(result.set.weightKg, closeTo(61.235, .001));

      await repository.createSet('entry-1', 0, 1, durationSeconds: 45);
      expect(postedSet!['durationSeconds'], 45);
      expect(postedSet!.containsKey('reps'), isFalse);
      expect(postedSet!.containsKey('weight'), isFalse);
    },
  );

  test('timed previous performance maps only the saved duration', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    dio.httpClientAdapter = _StubAdapter((options) {
      if (options.path == '/v1/record') {
        return {
          'dashboard': {
            'activeSession': {'id': 'session-1'},
          },
        };
      }
      if (options.path == '/v1/sessions/session-1') {
        final body = _poundSession();
        (body['exercises'] as List).single['trackingMode'] = 'timed';
        (body['exercises'] as List).single['targetDurationSeconds'] = 45;
        body['sets'] = <Map<String, dynamic>>[];
        body['previousPerformances'] = [
          {
            'exerciseId': 'entry-1',
            'startedAt': '2026-08-18T12:00:00.000Z',
            'order': 1,
            'weight': null,
            'reps': 1,
            'durationSeconds': 60,
          },
        ];
        return body;
      }
      throw StateError('Unexpected ${options.method} ${options.path}');
    });

    final session = (await ApiSessionRepository(
      dio,
      RestTimerStore(const FlutterSecureStorage()),
    ).activeSession())!;
    expect(session.exercises.single.trackingMode, ExerciseTrackingMode.timed);
    expect(session.exercises.single.previousPerformance?.durationSeconds, 60);
  });

  test('a set-sync request refreshes an expired access token once', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = SecureSessionStore(const FlutterSecureStorage());
    await store.save(
      AuthSession(
        accessToken: 'expired-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime.utc(2026, 8, 20, 13),
        user: const User(
          id: 'user-1',
          username: 'lifter',
          weightUnit: WeightUnit.lb,
        ),
      ),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    final paths = <String>[];
    dio.httpClientAdapter = _DynamicAdapter((options) {
      paths.add(options.path);
      if (options.path == '/v1/auth/refresh') {
        return _jsonResponse({
          'accessToken': 'fresh-token',
          'refreshToken': 'next-refresh-token',
          'accessTokenExpiresInSeconds': 3600,
          'user': {'id': 'user-1', 'username': 'lifter', 'name': 'Lifter'},
        });
      }
      if (options.path == '/v1/record' &&
          options.headers['Authorization'] == 'Bearer fresh-token') {
        return _jsonResponse({'ok': true});
      }
      return _jsonResponse({'error': 'Unauthorized'}, statusCode: 401);
    });
    configureAccessTokenRefresh(dio, store);

    final response = await dio.get<Map<String, dynamic>>('/v1/record');

    expect(response.data, {'ok': true});
    expect(paths, ['/v1/record', '/v1/auth/refresh', '/v1/record']);
    expect((await store.read())!.access, 'fresh-token');
  });

  test('concurrent unauthorized retries fail instead of hanging', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = SecureSessionStore(const FlutterSecureStorage());
    await store.save(
      AuthSession(
        accessToken: 'expired-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime.utc(2026, 8, 20, 13),
        user: const User(
          id: 'user-1',
          username: 'lifter',
          weightUnit: WeightUnit.lb,
        ),
      ),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    var refreshCount = 0;
    dio.httpClientAdapter = _DynamicAdapter((options) {
      if (options.path == '/v1/auth/refresh') {
        refreshCount += 1;
        return _jsonResponse({
          'accessToken': 'fresh-token',
          'refreshToken': 'next-refresh-token',
          'accessTokenExpiresInSeconds': 3600,
          'user': {'id': 'user-1', 'username': 'lifter', 'name': 'Lifter'},
        });
      }
      return _jsonResponse({'error': 'Unauthorized'}, statusCode: 401);
    });
    configureAccessTokenRefresh(dio, store);
    dio.options.headers['Authorization'] = 'Bearer expired-token';

    await expectLater(
      Future.wait([
        dio.get<void>('/v1/preferences'),
        dio.get<void>('/v1/plans/plan-1'),
      ]).timeout(const Duration(seconds: 2)),
      throwsA(isA<DioException>()),
    );

    expect(refreshCount, 1);
  });

  test('Arcana adapter unwraps a legacy encoded stage-evidence map', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    dio.httpClientAdapter = _StubAdapter((options) {
      expect(options.path, '/v1/arcana');
      return {
        'ruleVersion': 1,
        'pins': const <String, String?>{},
        'cards': [
          {
            'id': 'fool',
            'number': '0',
            'name': 'The Fool',
            'focus': 'Beginning the work.',
            'source': 'original-geometric',
            'stage': 'illuminated',
            'earnedAt': '2026-07-28T18:39:05.388Z',
            'stageEvidence': {
              'revealed': jsonEncode({
                'illuminated': {
                  'triggeringEventIds': const [],
                  'summary':
                      'Qualified sessions recover the beginning of the work.',
                  'stats': {'qualifiedSessions': 25, 'activeWeeks': 8},
                  'source': 'recovered',
                  'earnedAt': '2026-07-28T18:39:05.388Z',
                },
              }),
            },
            'nextMilestone': null,
          },
        ],
      };
    });

    final data = await ApiArcanaRepository(dio).read();

    expect(
      data.cards.single.stageEvidence[ArcanaStage.illuminated]!.summary,
      'Qualified sessions recover the beginning of the work.',
    );
    expect(
      data.cards.single.stageEvidence[ArcanaStage.illuminated]!.stats,
      containsPair('qualifiedSessions', 25),
    );
  });
}

Map<String, dynamic> _poundSession() => {
  'session': {
    'id': 'session-1',
    'status': 'active',
    'startedAt': '2026-08-20T12:00:00.000Z',
    'endedAt': null,
    'routineName': 'Upper',
    'dayName': 'Push',
    'weightUnit': 'lbs',
  },
  'exercises': [
    {
      'id': 'entry-1',
      'name': 'Bench press',
      'muscleGroup': 'Chest',
      'targetSets': 3,
      'targetReps': 8,
      'targetWeight': 135,
    },
  ],
  'sets': [
    {
      'id': 'set-1',
      'exerciseId': 'entry-1',
      'setOrder': 1,
      'weight': 135,
      'reps': 8,
      'isWarmup': false,
      'createdAt': '2026-08-20T12:00:00.000Z',
    },
  ],
  'previousPerformances': [
    {
      'exerciseId': 'entry-1',
      'startedAt': '2026-08-18T12:00:00.000Z',
      'order': 1,
      'weight': 135,
      'reps': 8,
    },
    {
      'exerciseId': 'entry-1',
      'startedAt': '2026-08-18T12:00:00.000Z',
      'order': 2,
      'weight': 155,
      'reps': 5,
    },
  ],
};

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._handler);
  final Map<String, dynamic> Function(RequestOptions options) _handler;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(_handler(options)),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this._body, this._statusCode);
  final Map<String, dynamic> _body;
  final int _statusCode;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(_body),
    _statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}

class _DynamicAdapter implements HttpClientAdapter {
  _DynamicAdapter(this._handler);
  final ResponseBody Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => _handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
