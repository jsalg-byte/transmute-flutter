import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/api/api_repositories.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';

void main() {
  test(
    'mock registration creates a session and rejects a duplicate username',
    () async {
      final repository = MockAuthRepository(
        SecureSessionStore(const FlutterSecureStorage()),
      );
      final session = await repository.register('new-lifter', 'eightchars');
      expect(session.user.username, 'new-lifter');
      await expectLater(
        repository.register('new-lifter', 'eightchars'),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test(
    'mock friends preserve the request lifecycle and restrict removal',
    () async {
      final store = MockStore();
      final repository = MockFriendsRepository(store);

      final initial = await repository.read();
      expect(initial.incoming.single.username, 'sparrow');
      await repository.accept(initial.incoming.single.id);
      expect(
        (await repository.read()).outgoing.any(
          (item) => item.username == 'sparrow' && item.status == 'accepted',
        ),
        isTrue,
      );

      await repository.sendRequest('mechanic');
      expect(
        (await repository.read()).outgoing.any(
          (item) => item.username == 'mechanic' && item.status == 'pending',
        ),
        isTrue,
      );
      await expectLater(
        repository.remove('friend-mechanic'),
        throwsA(isA<AppFailure>()),
      );
      await repository.remove('friend-sparrow');
      expect(
        (await repository.read()).outgoing.any(
          (item) => item.username == 'sparrow',
        ),
        isFalse,
      );
      final shared = await repository.getSharedSession(
        'friend-session-alchemist',
      );
      expect(shared.ownerUsername, 'alchemist');
      expect(shared.sets, isNotEmpty);
    },
  );

  test(
    'mock preferences retain units, active plan, and theme selection',
    () async {
      final store = MockStore();
      final repository = MockPreferencesRepository(store);

      final weight = await repository.setWeightUnit(WeightUnit.kg);
      expect(weight.weightUnit, WeightUnit.kg);
      final plan = await repository.setActivePlan('lower-a');
      expect(plan.activePlanId, 'lower-a');
      final theme = await repository.setTheme(
        const ThemePreference(
          palette: ThemePalette.hawkeye,
          brightness: PreferenceBrightness.dark,
        ),
      );
      expect(theme.palette, ThemePalette.hawkeye);
      expect(
        (await repository.read()).theme?.brightness,
        PreferenceBrightness.dark,
      );
    },
  );
}
