import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transmute_flutter/features/authentication/presentation/login_screen.dart';

void main() {
  testWidgets('mock login presents a single explicit demo action', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    expect(find.text('Demo Login'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining('transmute-demo'), findsNothing);
  });
}
