import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/providers.dart';

void main() {
  test('recent dashboard record is ordered, bounded, and navigable', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final entries = await container.read(recentRecordProvider.future);

    expect(entries, isNotEmpty);
    expect(entries.length, lessThanOrEqualTo(4));
    for (var index = 1; index < entries.length; index++) {
      expect(
        entries[index - 1].at.compareTo(entries[index].at),
        greaterThanOrEqualTo(0),
      );
    }
    expect(entries.every((entry) => entry.route.startsWith('/')), isTrue);
  });
}
