import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:transmute_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mock user can sign in and reach plans', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'demo');
    await tester.enterText(find.byType(EditableText).at(1), 'transmute-demo');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Workout plans'), findsWidgets);
    expect(find.text('Upper A'), findsOneWidget);
  });
}
