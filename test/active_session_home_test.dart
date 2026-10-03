import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/features/active_session/presentation/active_session_screen.dart';

void main() {
  testWidgets('idle workout tab shows the next day and saved routines', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ActiveSessionScreen()),
        GoRoute(path: '/plans', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/plans/:id', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/session', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/dashboard', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/history', builder: (_, _) => const SizedBox()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text("TODAY'S WORKOUT"), findsOneWidget);
    expect(find.text('Upper strength'), findsWidgets);
    expect(find.text('Start Workout'), findsOneWidget);
    expect(find.text('New workout'), findsOneWidget);
    expect(find.text('Quick Add workout'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Routines'), findsOneWidget);
    expect(find.textContaining('ACTIVE PLAN'), findsOneWidget);
    expect(find.textContaining('Barbell bench press'), findsOneWidget);
  });
}
