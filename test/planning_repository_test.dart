import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';

void main() {
  test('mock planning preserves scheduled work and status changes', () async {
    final store = MockStore();
    final repository = MockPlanningRepository(store);
    final block = await repository.createBlock(
      TrainingBlock(
        id: 'draft',
        name: 'Strength block',
        startDate: DateTime.utc(2026, 8, 10),
        endDate: DateTime.utc(2026, 9, 7),
        targetSessionsPerWeek: 3,
        status: TrainingBlockStatus.active,
      ),
    );
    final scheduled = await repository.scheduleSession(
      block.id,
      ScheduledBlockSession(
        id: 'draft',
        scheduledFor: DateTime.utc(2026, 8, 12),
        status: ScheduledBlockSessionStatus.planned,
        isDeload: true,
      ),
    );
    await repository.updateScheduledSession(
      scheduled.id,
      status: ScheduledBlockSessionStatus.completed,
    );
    await repository.updateBlock(
      block.id,
      status: TrainingBlockStatus.completed,
    );

    final saved = (await repository.listBlocks()).single;
    expect(saved.status, TrainingBlockStatus.completed);
    expect(saved.sessions.single.status, ScheduledBlockSessionStatus.completed);
    expect(saved.sessions.single.isDeload, isTrue);
  });
}
