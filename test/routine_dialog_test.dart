import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';
import 'package:transmute_flutter/features/workout_plans/presentation/routine_dialogs.dart';

void main() {
  testWidgets('failed routine save keeps the draft name available for retry', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showRoutineNameDialog<String>(
                context: context,
                title: 'Rename routine',
                label: 'Routine name',
                onSave: (name) async {
                  attempts++;
                  if (attempts == 1)
                    throw const AppFailure('offline', 'Connection lost');
                  return name;
                },
              ),
              child: const Text('Rename'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Long saved routine name');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Connection lost'), findsOneWidget);
    expect(find.text('Long saved routine name'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Rename routine'), findsNothing);
  });
}
