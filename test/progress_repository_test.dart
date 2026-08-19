import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';

void main() {
  test(
    'mock progress records a photo, updates its date, and removes it',
    () async {
      final repository = MockProgressRepository(MockStore());
      final firstDate = DateTime.utc(2026, 8, 10);
      await repository.create(
        ProgressPhotoUpload(
          fileName: 'check-in.jpg',
          mimeType: 'image/jpeg',
          bytes: Uint8List.fromList([1, 2, 3]),
          capturedAt: firstDate,
          note: 'Week one.',
        ),
      );
      final saved = await repository.read();
      expect(saved.photos.single.localBytes, isNotNull);
      expect(saved.photos.single.capturedAt, firstDate);

      final nextDate = DateTime.utc(2026, 8, 17);
      await repository.updateCapturedAt(saved.photos.single.id, nextDate);
      expect((await repository.read()).photos.single.capturedAt, nextDate);

      await repository.delete(saved.photos.single.id);
      expect((await repository.read()).photos, isEmpty);
    },
  );
}
