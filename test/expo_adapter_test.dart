import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/api/api_repositories.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';

void main() {
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
}

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
