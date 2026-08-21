import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/api/api_repositories.dart';
import 'package:transmute_flutter/core/data/pending_set_sync.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';

void main() {
  test(
    'a set survives a network failure and replays with the same operation ID',
    () async {
      final persistence = _MemoryPersistence();
      final store = PendingSetStore(persistence);
      final sessions = _ReplaySessionRepository();
      final service = PendingSetSyncService(store, sessions);
      const userId = 'user-1';
      const sessionId = 'session-1';
      const operationId = '123e4567-e89b-42d3-a456-426614174000';
      final log = PendingSetLog(
        operationId: operationId,
        sessionId: sessionId,
        sessionExerciseId: 'exercise-1',
        weightKg: 61.25,
        reps: 8,
        isWarmup: false,
        createdAt: DateTime.utc(2026, 8, 13, 12),
      );

      await store.enqueue(userId, log);
      final deferred = await service.sync(userId, sessionId);
      expect(deferred.deferred.single.operationId, operationId);
      expect((await store.read(userId)).single.operationId, operationId);

      sessions.online = true;
      final completed = await service.sync(userId, sessionId);
      expect(completed.synced, hasLength(1));
      expect(await store.read(userId), isEmpty);
      expect(sessions.operationIds, [operationId, operationId]);
    },
  );

  test('pending sets are isolated by signed-in user', () async {
    final store = PendingSetStore(_MemoryPersistence());
    final first = PendingSetLog(
      operationId: '123e4567-e89b-42d3-a456-426614174000',
      sessionId: 'session-1',
      sessionExerciseId: 'exercise-1',
      weightKg: 20,
      reps: 10,
      isWarmup: false,
      createdAt: DateTime.utc(2026, 8, 13),
    );
    await store.enqueue('first-user', first);

    expect(await store.read('second-user'), isEmpty);
    await store.removeSession('first-user', 'session-1');
    expect(await store.read('first-user'), isEmpty);
  });

  test(
    'a rejected command is retained but not retried automatically',
    () async {
      final store = PendingSetStore(_MemoryPersistence());
      final sessions = _ReplaySessionRepository()
        ..failure = const AppFailure(
          'conflict',
          'Workout is already complete.',
        );
      final service = PendingSetSyncService(store, sessions);
      final log = PendingSetLog(
        operationId: '123e4567-e89b-42d3-a456-426614174001',
        sessionId: 'session-1',
        sessionExerciseId: 'exercise-1',
        weightKg: 20,
        reps: 10,
        isWarmup: false,
        createdAt: DateTime.utc(2026, 8, 13),
      );
      await store.enqueue('user-1', log);

      expect((await service.sync('user-1', 'session-1')).blocked, hasLength(1));
      expect((await service.sync('user-1', 'session-1')).blocked, hasLength(1));
      expect(sessions.operationIds, [log.operationId]);
      expect((await store.read('user-1')).single.blocked, isTrue);
    },
  );

  test('an explicit sync retries a set that was previously blocked', () async {
    final store = PendingSetStore(_MemoryPersistence());
    final sessions = _ReplaySessionRepository()
      ..failure = const AppFailure('unauthorized', 'Sign in again.');
    final service = PendingSetSyncService(store, sessions);
    final log = PendingSetLog(
      operationId: '123e4567-e89b-42d3-a456-426614174002',
      sessionId: 'session-1',
      sessionExerciseId: 'exercise-1',
      weightKg: 20,
      reps: 10,
      isWarmup: false,
      createdAt: DateTime.utc(2026, 8, 13),
    );
    await store.enqueue('user-1', log);

    await service.sync('user-1', 'session-1');
    expect((await store.read('user-1')).single.blocked, isTrue);

    sessions
      ..failure = null
      ..online = true;
    final retry = await service.sync('user-1', 'session-1', retryBlocked: true);

    expect(retry.synced, hasLength(1));
    expect(await store.read('user-1'), isEmpty);
  });
}

class _MemoryPersistence implements PendingSetPersistence {
  final _values = <String, String>{};
  @override
  Future<void> delete(String key) async => _values.remove(key);
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

class _ReplaySessionRepository implements SessionRepository {
  bool online = false;
  AppFailure? failure;
  final operationIds = <String?>[];

  @override
  Future<SetLogResult> createSet(
    String sessionExerciseId,
    double weightKg,
    int reps, {
    bool isWarmup = false,
    String? clientOperationId,
  }) async {
    operationIds.add(clientOperationId);
    if (failure != null) throw failure!;
    if (!online) {
      throw const AppFailure(
        'network_error',
        'Unable to reach the Transmute service.',
        retryable: true,
      );
    }
    return SetLogResult(
      set: LoggedSet(
        id: 'server-set',
        sessionExerciseId: sessionExerciseId,
        setOrder: 1,
        weightKg: weightKg,
        reps: reps,
        completedAt: DateTime.utc(2026, 8, 13),
        isWarmup: isWarmup,
      ),
    );
  }

  @override
  Future<bool> supportsOfflineSetSync() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
