import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/core/domain/models.dart';
import 'package:transmute_flutter/core/domain/repositories.dart';
import 'package:transmute_flutter/core/providers.dart';
import 'package:transmute_flutter/features/dashboard/presentation/dashboard_screen.dart';

class _FailedActiveSession extends ActiveSessionController {
  @override
  Future<WorkoutSession?> build() async =>
      throw const AppFailure('offline', 'Session check failed.');
}

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
    GoRoute(
      path: '/session',
      builder: (_, _) => const Scaffold(body: Text('Active workout opened')),
    ),
    GoRoute(path: '/plans', builder: (_, _) => const Scaffold()),
    GoRoute(path: '/history', builder: (_, _) => const Scaffold()),
    GoRoute(path: '/goals', builder: (_, _) => const Scaffold()),
    GoRoute(path: '/arcana', builder: (_, _) => const Scaffold()),
  ],
);

void main() {
  testWidgets('history and recovery failures leave a manual day start path', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyProvider.overrideWith(
            (ref) async => throw StateError('history'),
          ),
          recoveryOverviewProvider.overrideWith(
            (ref) async => throw StateError('recovery'),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose day'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('Recovery unavailable'), findsOneWidget);
    await tester.tap(find.text('Retry recovery'));
    await tester.pumpAndSettle();
    expect(find.text('Recovery unavailable'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, 250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose day'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a training day'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Upper strength'));
    await tester.pumpAndSettle();
    expect(find.text('Active workout opened'), findsOneWidget);
  });

  testWidgets('failed active-session read never offers Start', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSessionProvider.overrideWith(_FailedActiveSession.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry session check'), findsOneWidget);
    expect(find.text('Start Workout'), findsNothing);
    expect(find.text('Choose day'), findsNothing);
  });
}
