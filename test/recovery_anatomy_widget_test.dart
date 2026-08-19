import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:transmute_flutter/core/domain/recovery.dart';
import 'package:transmute_flutter/shared/widgets/recovery_anatomy.dart';

void main() {
  testWidgets('source-derived anatomy renders front and back recovery maps', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RecoveryAnatomy(
            groups: [
              RecoveryGroup(name: 'Chest', stage: RecoveryStage.needsRest),
              RecoveryGroup(name: 'Shoulders', stage: RecoveryStage.recovering),
              RecoveryGroup(name: 'Arms', stage: RecoveryStage.ready),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(
      find.bySemanticsLabel(
        'Chest: needs rest, Shoulders: recovering, Arms: ready to train',
      ),
      findsOneWidget,
    );
  });
}
