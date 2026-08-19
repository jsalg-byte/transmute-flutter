import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';

void main() {
  test('mock Arcana only pins revealed cards', () async {
    final repository = MockArcanaRepository();
    expect((await repository.read()).cards, hasLength(15));
    final initial = await repository.read();
    expect(initial.pins[ArcanaSlot.past], 'fool');

    final pinned = await repository.pin(ArcanaSlot.present, 'fool');
    expect(pinned.pins[ArcanaSlot.present], 'fool');
    expect(
      () => repository.pin(ArcanaSlot.becoming, 'magician'),
      throwsA(isA<AppFailure>()),
    );
  });
}
