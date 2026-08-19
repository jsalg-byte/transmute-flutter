import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';

void main() {
  test(
    'mock fasting records a completed fast and removes it explicitly',
    () async {
      final store = MockStore()
        ..activeFast = ActiveFast(
          id: 'active',
          startedAt: DateTime.now().subtract(const Duration(minutes: 6)),
          targetMinutes: 16 * 60,
        );
      final repository = MockFastingRepository(store);

      expect(await repository.end(note: 'Finished after training.'), isFalse);
      final saved = await repository.read();
      expect(saved.active, isNull);
      expect(saved.logs, hasLength(1));
      expect(saved.logs.single.note, 'Finished after training.');

      await repository.deleteLog(saved.logs.single.id);
      expect((await repository.read()).logs, isEmpty);
    },
  );
}
