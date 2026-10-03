import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/features/workout_plans/presentation/plan_screens.dart';

void main() {
  testWidgets('adding a day opens the newly created day editor', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/plans/upper-a',
      routes: [
        GoRoute(
          path: '/plans/:planId',
          builder: (_, state) =>
              PlanDetailScreen(planId: state.pathParameters['planId']!),
        ),
        GoRoute(path: '/plans', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/session', builder: (_, _) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add day'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Core day');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No exercises yet. Add movements from the library to form this day.',
      ),
      findsOneWidget,
    );
    final newDayChip = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text('Core day'),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(newDayChip.selected, isTrue);
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Add exercise from library'), findsOneWidget);
  });
}
