import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/features/authentication/presentation/pre_login_onboarding_screen.dart';

void main() {
  testWidgets('auth restoration has a branded loading splash', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthLoadingSplashScreen()));

    expect(find.byType(SvgPicture), findsOneWidget);
    final spinnerFinder = find.ancestor(
      of: find.byType(SvgPicture),
      matching: find.byType(RotationTransition),
    );
    expect(spinnerFinder, findsOneWidget);
    expect(find.bySemanticsLabel('Loading Transmute'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    final spinner = tester.widget<RotationTransition>(spinnerFinder);
    expect(spinner.turns.value, greaterThan(0));
  });

  testWidgets('auth splash respects reduced-motion preference', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const AuthLoadingSplashScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    final spinner = tester.widget<RotationTransition>(
      find.ancestor(
        of: find.byType(SvgPicture),
        matching: find.byType(RotationTransition),
      ),
    );
    expect(spinner.turns.value, 0);
  });

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
