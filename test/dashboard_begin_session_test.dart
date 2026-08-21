import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/features/dashboard/presentation/dashboard_screen.dart';

void main() {
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

      final beginSession = find.text('Begin session');
      await tester.tap(beginSession);
      await tester.pumpAndSettle();

      expect(find.text('What are you training today?'), findsOneWidget);
      expect(find.text('Upper strength'), findsOneWidget);
      expect(find.text('Lower strength'), findsOneWidget);

      await tester.tap(find.text('Lower strength'));
      await tester.pumpAndSettle();

      expect(find.text('Active workout destination'), findsOneWidget);
    },
  );
}
