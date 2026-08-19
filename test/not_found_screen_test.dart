import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/features/not_found/presentation/not_found_screen.dart';

void main() {
  testWidgets(
    'not-found screen explains the missing path and provides recovery',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const NotFoundScreen(path: '/missing-record'),
          ),
          GoRoute(path: '/dashboard', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/plans', builder: (_, _) => const SizedBox()),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      expect(find.text('404'), findsOneWidget);
      expect(find.text('That record is not here.'), findsOneWidget);
      expect(find.textContaining('/missing-record'), findsOneWidget);
      expect(find.text('Go to dashboard'), findsOneWidget);
      expect(find.text('View workout plans'), findsOneWidget);
    },
  );
}
