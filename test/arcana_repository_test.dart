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

  test('Arcana controller can rebuild after its repository is refreshed', () async {
    final repository = MockArcanaRepository();
    final container = ProviderContainer(
      overrides: [arcanaRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(arcanaProvider.future);
    container.invalidate(arcanaRepositoryProvider);
    await Future<void>.delayed(Duration.zero);

    final data = await container.read(arcanaProvider.future);
    expect(data.cards, hasLength(15));
  });
}
