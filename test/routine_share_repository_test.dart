import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';

void main() {
  test(
    'routine shares preserve their published prescription after source edits',
    () async {
      final repository = MockPlanRepository(MockStore());
      final source = (await repository.getPlan('upper-a')).days.single;

      final share = await repository.createRoutineShare(source.id);
      expect(share.snapshot.routineName, 'Upper strength');
      expect(share.snapshot.totalSets, 9);
      expect(share.snapshot.exercises.first.targetSets, 3);
      expect(share.snapshot.exercises.first.targetWeightKg, 61.235);

      final plan = await repository.getPlan('upper-a');
      final entry = plan.days.single.exercises.first;
      await repository.updatePrescription(
        plan.id,
        plan.days.single.id,
        entry.id,
        targetSets: 4,
        targetReps: 6,
        targetWeightKg: 72,
      );

      final published = await repository.getRoutineShare(share.token);
      expect(published.totalSets, 9);
      expect(published.exercises.first.targetSets, 3);
      expect(published.exercises.first.targetReps, 8);
      expect(published.exercises.first.targetWeightKg, 61.235);
      expect(published.exercises.first.name, 'Barbell bench press');
    },
  );

  test('import makes an independent editable routine copy', () async {
    final repository = MockPlanRepository(MockStore());
    final share = await repository.createRoutineShare('upper-a-day-1');

    final imported = await repository.importRoutineShare(
      share.token,
      planId: 'lower-a',
      name: 'Shared upper copy',
    );
    final destination = await repository.getPlan('lower-a');
    final copy = destination.days.singleWhere((day) => day.id == imported.id);
    expect(copy.name, 'Shared upper copy');
    expect(copy.exercises.map((entry) => entry.exercise.id), [
      'bench',
      'row',
      'press',
    ]);
    expect(copy.exercises.map((entry) => entry.targetSets), [3, 3, 3]);

    await repository.renameDay(
      destination.id,
      imported.id,
      'Edited by recipient',
    );
    final source = await repository.getPlan('upper-a');
    expect(source.days.single.name, 'Upper strength');
    expect(source.days.single.exercises.first.targetSets, 3);
  });

  test('revoked routine links reject new reads and imports', () async {
    final repository = MockPlanRepository(MockStore());
    final share = await repository.createRoutineShare('upper-a-day-1');
    await repository.revokeRoutineShare(share.token);

    await expectLater(
      repository.getRoutineShare(share.token),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          'routine_share_revoked',
        ),
      ),
    );
    await expectLater(
      repository.importRoutineShare(share.token, planId: 'lower-a'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          'routine_share_revoked',
        ),
      ),
    );
  });
}
