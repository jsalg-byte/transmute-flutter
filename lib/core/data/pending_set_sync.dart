import 'dart:convert';
import 'dart:math';

import '../api/api_repositories.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

/// Device-local queue for set commands. It deliberately stores only validated
/// workout input, never credentials or a copy of the server workout record.
class PendingSetStore {
  const PendingSetStore(this._persistence);
  final PendingSetPersistence _persistence;

  String _key(String userId) => 'transmute.pending-sets.$userId';

  Future<List<PendingSetLog>> read(String userId) async {
    final raw = await _persistence.read(_key(userId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((value) => PendingSetLog.fromJson(value as Map<String, dynamic>))
          .toList();
    } on FormatException {
      await _persistence.delete(_key(userId));
      return const [];
    } on TypeError {
      await _persistence.delete(_key(userId));
      return const [];
    }
  }

  Future<void> write(String userId, List<PendingSetLog> logs) async {
    if (logs.isEmpty) return _persistence.delete(_key(userId));
    await _persistence.write(
      _key(userId),
      jsonEncode(logs.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> enqueue(String userId, PendingSetLog log) async {
    final current = await read(userId);
    if (current.any((item) => item.operationId == log.operationId)) return;
    await write(userId, [...current, log]);
  }

  Future<void> removeSession(String userId, String sessionId) async {
    final current = await read(userId);
    await write(
      userId,
      current.where((item) => item.sessionId != sessionId).toList(),
    );
  }
}

/// Replays durable set commands in order. The API contract makes retries safe:
/// the same [PendingSetLog.operationId] is accepted at most once per session.
class PendingSetSyncService {
  const PendingSetSyncService(this._store, this._sessions);
  final PendingSetStore _store;
  final SessionRepository _sessions;

  Future<PendingSetSyncReport> sync(
    String userId,
    String sessionId, {
    bool retryBlocked = false,
  }) async {
    final current = await _store.read(userId);
    final forSession = current
        .where((item) => item.sessionId == sessionId)
        .toList();
    if (forSession.isEmpty) return const PendingSetSyncReport();

    final retained = current
        .where((item) => item.sessionId != sessionId)
        .toList();
    final synced = <SetLogResult>[];
    final deferred = <PendingSetLog>[];
    final blocked = <PendingSetLog>[];
    for (final log in forSession) {
      if (log.blocked && !retryBlocked) {
        blocked.add(log);
        continue;
      }
      try {
        synced.add(
          await _sessions.createSet(
            log.sessionExerciseId,
            log.weightKg,
            log.reps,
            isWarmup: log.isWarmup,
            clientOperationId: log.operationId,
          ),
        );
      } on AppFailure catch (error) {
        if (error.retryable) {
          deferred.add(log);
        } else {
          blocked.add(log.copyWith(blocked: true));
        }
      }
    }
    await _store.write(userId, [...retained, ...deferred, ...blocked]);
    return PendingSetSyncReport(
      synced: synced,
      deferred: deferred,
      blocked: blocked,
    );
  }
}

String newSetOperationId() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
