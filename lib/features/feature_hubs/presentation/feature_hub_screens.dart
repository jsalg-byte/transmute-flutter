import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/theme/transmute_palette.dart';
import '../../../shared/widgets/app_shell.dart';

/// A truthful destination for the rank area while its persisted scoring
/// service and bodygraph arrive in the next product phase.
class RanksPreviewScreen extends StatelessWidget {
  const RanksPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Ranks',
    child: ListView(
      children: [
        Text('Ranks', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 14),
        const TransmuteStatePanel(
          kind: TransmuteStateKind.empty,
          title: 'Exercise ranks are taking shape',
          message:
              'Per-exercise tiers, your bodygraph and rank history will appear here when their saved scoring records are ready. No ranking is estimated from unfinished data.',
        ),
        const SizedBox(height: 18),
        _HubLink(
          icon: Icons.fitness_center_outlined,
          title: 'Browse exercises',
          subtitle: 'Find a movement for your next training day.',
          route: '/exercises',
        ),
        _HubLink(
          icon: Icons.auto_awesome_outlined,
          title: 'Explore Arcana',
          subtitle: 'See your existing evidence and collection.',
          route: '/arcana',
        ),
      ],
    ),
  );
}

class ProfileHubScreen extends ConsumerWidget {
  const ProfileHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final palette = TransmutePalette.of(context);
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.username ?? 'Your profile';
    return AppShell(
      title: 'Profile',
      child: ListView(
        children: [
          TransmutePanel(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: palette.oxide,
                  foregroundColor: palette.raised,
                  child: const Icon(Icons.person_outline, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (user != null) Text('@${user.username}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Your record', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          const _HubLink(
            icon: Icons.history,
            title: 'Workout history',
            subtitle: 'Review completed sessions and sets.',
            route: '/history',
          ),
          const _HubLink(
            icon: Icons.auto_awesome_outlined,
            title: 'Arcana',
            subtitle: 'Explore your earned evidence.',
            route: '/arcana',
          ),
          const _HubLink(
            icon: Icons.flag_outlined,
            title: 'Goals',
            subtitle: 'Check your saved training goals.',
            route: '/goals',
          ),
          const _HubLink(
            icon: Icons.calendar_month_outlined,
            title: 'Planning',
            subtitle: 'Review training blocks and weekly plans.',
            route: '/planning',
          ),
          const _HubLink(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Manage units, theme and active plan.',
            route: '/settings',
          ),
          const SizedBox(height: 18),
          const TransmuteStatePanel(
            kind: TransmuteStateKind.empty,
            title: 'Levels and streaks are coming',
            message:
                'Your verified workouts will power the level, rewards and training calendar sections in the progression phase.',
          ),
        ],
      ),
    );
  }
}

class _HubLink extends StatelessWidget {
  const _HubLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => context.go(route),
    ),
  );
}
