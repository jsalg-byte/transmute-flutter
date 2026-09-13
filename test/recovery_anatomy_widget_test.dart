import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:transmute_flutter/core/domain/recovery.dart';
import 'package:transmute_flutter/shared/design_system/cute_theme.dart';
import 'package:transmute_flutter/shared/widgets/recovery_anatomy.dart';

void main() {
  Future<List<String>> anatomyTemplates() => Future.value(const [
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><path fill="{{chest}}" stroke="{{chestStroke}}" d="M1 1h8v8H1z"/></svg>''',
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><path fill="{{upper-back}}" stroke="{{upper-backStroke}}" d="M1 1h8v8H1z"/></svg>''',
  ]);

  testWidgets('source-derived anatomy renders front and back recovery maps', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecoveryAnatomy(
            templateLoader: anatomyTemplates(),
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
        'Chest: needs rest, Shoulders: recovering, Arms: ready to train. '
        'Legend: Rest under 24 hours, Recover 24 to 48 hours, Ready after 48 hours.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'red-green-safe Cute Pastel uses an ordered scale with a text legend',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [CuteCustomStyles.defaults(colorBlindSafe: true)],
          ),
          home: Scaffold(
            body: RecoveryAnatomy(
              templateLoader: anatomyTemplates(),
              groups: [
                RecoveryGroup(name: 'Chest', stage: RecoveryStage.needsRest),
                RecoveryGroup(
                  name: 'Shoulders',
                  stage: RecoveryStage.recovering,
                ),
                RecoveryGroup(name: 'Arms', stage: RecoveryStage.ready),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rest · <24h'), findsOneWidget);
      expect(find.text('Recover · 24–48h'), findsOneWidget);
      expect(find.text('Ready · 48h+'), findsOneWidget);
      expect(
        recoveryStageColor(RecoveryStage.needsRest, colorBlindSafe: true),
        const Color(0xff56408A),
      );
      expect(
        recoveryStageColor(RecoveryStage.ready, colorBlindSafe: true),
        const Color(0xffA6C9E2),
      );
    },
  );
}
