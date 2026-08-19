import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_shell.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Page not found',
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('404', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 10),
                Text(
                  'That record is not here.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '“$path” is not an available page in this Transmute demonstration.',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Go to dashboard'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/plans'),
                      child: const Text('View workout plans'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
