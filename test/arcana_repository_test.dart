import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';
import 'package:transmute_flutter/core/providers.dart';

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

  test('Arcana controller retains the canonical pin after a refresh', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(arcanaProvider.future);
    await container.read(arcanaProvider.notifier).pin(
      ArcanaSlot.present,
      'fool',
    );
    await container.read(arcanaProvider.notifier).refresh();

    expect(
      container.read(arcanaProvider).value!.pins[ArcanaSlot.present],
      'fool',
    );
  });
}
