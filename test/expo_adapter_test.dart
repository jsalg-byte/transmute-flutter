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
      plan.days.single.exercises.single.exercise.demoUrl,
      'https://media.example.test/bench.gif',
    );
  });

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
    },
  );

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
