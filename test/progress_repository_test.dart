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

  test(
    'mock progress accepts multiple photos for one dated check-in',
    () async {
      final repository = MockProgressRepository(MockStore());
      final capturedAt = DateTime.utc(2026, 9, 12);
      for (final fileName in ['front.jpg', 'side.jpg', 'back.jpg']) {
        await repository.create(
          ProgressPhotoUpload(
            fileName: fileName,
            mimeType: 'image/jpeg',
            bytes: Uint8List.fromList([1, 2, 3]),
            capturedAt: capturedAt,
            note: 'Monthly check-in',
          ),
        );
      }

      final saved = await repository.read();
      expect(saved.photos, hasLength(3));
      expect(
        saved.photos.map((photo) => photo.capturedAt),
        everyElement(capturedAt),
      );
      expect(
        saved.photos.map((photo) => photo.note),
        everyElement('Monthly check-in'),
      );
    },
  );
}
