import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/features/authentication/presentation/pre_login_onboarding_screen.dart';

void main() {
  testWidgets('guest onboarding advances to account creation', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const PreLoginOnboardingScreen()),
        GoRoute(
          path: '/login',
          builder: (_, state) => Text(
            state.uri.queryParameters['mode'] == 'register'
                ? 'Registration form'
                : 'Sign-in form',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('01 — NIGREDO'), findsOneWidget);
    expect(find.text('Begin with the\nraw material.'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('02 — ALBEDO'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('03 — RUBEDO'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Registration form'), findsOneWidget);
  });

  testWidgets('last-slide sign-in link opens sign in', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const PreLoginOnboardingScreen()),
        GoRoute(
          path: '/login',
          builder: (_, state) => Text(
            state.uri.queryParameters['mode'] == 'register'
                ? 'Registration form'
                : 'Sign-in form',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Sign-in form'), findsOneWidget);
  });
}
