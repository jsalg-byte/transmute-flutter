import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/providers.dart';
import 'package:transmute_flutter/features/authentication/presentation/login_screen.dart';

class _MockRepositoryModeController extends RepositoryModeController {
  @override
  RepositoryMode build() => RepositoryMode.mock;
}

class _ApiRepositoryModeController extends RepositoryModeController {
  @override
  RepositoryMode build() => RepositoryMode.api;
}

void main() {
  testWidgets('mock login presents a single explicit demo action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryModeProvider.overrideWith(
            _MockRepositoryModeController.new,
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Demo Login', skipOffstage: false), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining('transmute-demo'), findsNothing);
  });

  testWidgets(
    'api login password field supports eye toggle and accepts 7+ character password',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryModeProvider.overrideWith(
              _ApiRepositoryModeController.new,
            ),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();

      // In API mode, form fields are displayed
      expect(find.text('Sign in'), findsOneWidget);
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2)); // Username and Password

      // Initial state: password is obscured and toggle shows visibility_outlined
      final passwordFinder = textFields.at(1);
      TextField passwordWidget = tester.widget<TextField>(passwordFinder);
      expect(passwordWidget.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Tap toggle: should reveal password (obscureText = false)
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      passwordWidget = tester.widget<TextField>(passwordFinder);
      expect(passwordWidget.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Tap toggle again: should obscure password again
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      passwordWidget = tester.widget<TextField>(passwordFinder);
      expect(passwordWidget.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Enter 6 characters -> validator fails with 7–128 character message
      await tester.enterText(textFields.at(0), 'claudia');
      await tester.enterText(passwordFinder, '123456');
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(find.text('Enter a 7–128 character password.'), findsOneWidget);

      // Enter 7 characters ('fitness') -> validation passes
      await tester.enterText(passwordFinder, 'fitness');
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(find.text('Enter a 7–128 character password.'), findsNothing);
    },
  );
}
