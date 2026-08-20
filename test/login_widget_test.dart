import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/core/providers.dart';
import 'package:transmute_flutter/features/authentication/presentation/login_screen.dart';

class _MockRepositoryModeController extends RepositoryModeController {
  @override
  RepositoryMode build() => RepositoryMode.mock;
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
}
