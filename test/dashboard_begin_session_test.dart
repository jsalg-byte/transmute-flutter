import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:transmute_flutter/core/providers.dart';
import 'package:transmute_flutter/core/domain/models.dart';

void main() {
  test(
    'last performed uses named history without detail IDs or requests',
    () async {
      final at = DateTime(2026, 9, 12);
      final container = ProviderContainer(
        overrides: [
          historyProvider.overrideWith(
            (ref) async => [
              CompletedSessionSummary(
                id: 'legacy-session',
                planName: 'GAROU II',
                planDayName: 'PUSH 1',
                startedAt: at,
                completedAt: at,
                durationSeconds: 60,
                workingSetCount: 3,
                totalVolumeKg: 100,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(await container.read(lastPerformedPlanDayProvider.future), {
        planDayHistoryKey('GAROU II', 'PUSH 1'): at,
      });
    },
  );
  testWidgets(
    'Begin session selects a training day and opens the active workout',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
          GoRoute(
            path: '/session',
            builder: (_, _) => const Scaffold(
              body: Center(child: Text('Active workout destination')),
            ),
          ),
          GoRoute(path: '/plans', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/history', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/dashboard', builder: (_, _) => const SizedBox()),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Record today’s recovery'), findsNothing);
      expect(find.text('DAILY TRANSMUTATION'), findsNothing);

      final beginSession = find.text('Begin session');
      await tester.tap(beginSession);
      await tester.pumpAndSettle();

      expect(find.text('What are you training today?'), findsOneWidget);
      expect(find.text('Upper strength'), findsOneWidget);
      expect(find.textContaining('Last performed'), findsOneWidget);
      expect(find.text('Lower strength'), findsNothing);

      await tester.tap(find.text('Upper strength'));
      await tester.pumpAndSettle();

      expect(find.text('Active workout destination'), findsOneWidget);
    },
  );
}
