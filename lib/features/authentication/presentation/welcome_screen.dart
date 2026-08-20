import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _slides = [
    (
      'THE RANKS',
      'Build your rank through the work.',
      'Every logged session, meal, recovery day, and check-in adds weight to the record. Your rank is earned, not assigned.',
      Icons.workspace_premium_outlined,
    ),
    (
      'THE BODY',
      'Discover your body’s potential.',
      'See the signals your work creates. Training, recovery, and consistency make it easier to understand where to build next.',
      Icons.accessibility_new_outlined,
    ),
    (
      'THE PLAN',
      'A workout shaped around you.',
      'Turn your available time, equipment, and training history into a clear next session—built for the work you can actually do.',
      Icons.route_outlined,
    ),
    (
      'THE GUIDE',
      'Your health and fitness guide.',
      'Keep training, nutrition, recovery, and progress in one working record. The next decision gets clearer every time you return.',
      Icons.auto_awesome_outlined,
    ),
  ];
  int _page = 0;
  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'TRANSMUTE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const Spacer(),
                      TextButton(onPressed: _finish, child: const Text('Skip')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                            right: index == _slides.length - 1 ? 0 : 7,
                          ),
                          color: index <= _page
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    slide.$4,
                    size: 116,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 42),
                  Text(
                    slide.$1,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    slide.$2,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    slide.$3,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.55),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: last
                        ? _finish
                        : () => setState(() => _page += 1),
                    child: Text(last ? 'Enter your record' : 'Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _finish() {
    ref.read(authControllerProvider.notifier).finishWelcome();
    context.go('/dashboard');
  }
}
