import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/recovery.dart';
import '../../../core/providers.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/theme/transmute_palette.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/recovery_anatomy.dart';
import '../../../shared/widgets/workout_launch_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: AppShell(
      title: 'Today',
      desktopContentMaxWidth: 960,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          TabBar(
            tabs: [
              Tab(text: 'For You'),
              Tab(text: 'Feed'),
              Tab(text: 'Discovery'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_ForYouView(), _FeedView(), _DiscoveryView()],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ForYouView extends ConsumerWidget {
  const _ForYouView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TransmutePalette.of(context);
    return ListView(
      padding: const EdgeInsets.only(top: 18, bottom: 28),
      children: [
        const _ProgressionBanner(),
        const SizedBox(height: 26),
        Text(
          "Today's Workout",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const WorkoutLaunchCard(),
        const SizedBox(height: 26),
        Text('Recovery Zone', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const _RecoverySection(),
        const SizedBox(height: 26),
        Text('Goals', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        TransmutePanel(
          child: Row(
            children: [
              Icon(Icons.flag_outlined, color: palette.oxide),
              const SizedBox(width: 12),
              const Expanded(child: Text('Review your saved training goals.')),
              TextButton(
                onPressed: () => context.go('/goals'),
                child: const Text('View goals'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Last 14 Workouts',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const _TrainingSummary(),
        const SizedBox(height: 26),
        Text('Discover', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const _DiscoveryGrid(compact: true),
      ],
    );
  }
}

class _ProgressionBanner extends StatelessWidget {
  const _ProgressionBanner();

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return TransmutePanel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR PROGRESSION',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.oxide,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Every session adds to the record.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  'Explore the evidence and milestones you have earned in Arcana.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 7),
                TextButton.icon(
                  onPressed: () => context.go('/arcana'),
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Explore Arcana'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ExcludeSemantics(
            child: SvgPicture.asset(
              'assets/transmute/ouroboros.svg',
              width: 66,
              height: 66,
              colorFilter: ColorFilter.mode(palette.gold, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoverySection extends ConsumerWidget {
  const _RecoverySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recovery = ref.watch(recoveryOverviewProvider);
    return recovery.when(
      skipLoadingOnRefresh: true,
      loading: () => const TransmuteStatePanel(
        kind: TransmuteStateKind.loading,
        title: 'Reading recovery',
        message: 'Your workout is ready while recovery loads.',
      ),
      error: (_, _) => TransmuteStatePanel(
        kind: TransmuteStateKind.error,
        title: 'Recovery unavailable',
        message: 'You can still start or choose a workout.',
        action: TransmuteButton(
          label: 'Retry recovery',
          icon: Icons.refresh,
          onPressed: () => ref.invalidate(recoveryOverviewProvider),
        ),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return const TransmuteStatePanel(
            kind: TransmuteStateKind.empty,
            title: 'No recovery record yet',
            message: 'Complete a workout to see muscle recovery here.',
          );
        }
        final ready = groups
            .where((g) => g.stage == RecoveryStage.ready)
            .length;
        final recovering = groups
            .where((g) => g.stage == RecoveryStage.recovering)
            .length;
        final needsRest = groups
            .where((g) => g.stage == RecoveryStage.needsRest)
            .length;
        return TransmutePanel(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final map = RecoveryAnatomy(
                groups: groups,
                compact: constraints.maxWidth < 560,
              );
              final detail = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Based on completed workouts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$ready ready · $recovering recovering · $needsRest need rest',
                  ),
                  const SizedBox(height: 8),
                  for (final group
                      in groups
                          .where((g) => g.stage != RecoveryStage.ready)
                          .take(4))
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${group.name}: ${group.stage == RecoveryStage.recovering ? 'recovering' : 'needs rest'}',
                      ),
                    ),
                ],
              );
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [map, const SizedBox(height: 12), detail],
                );
              }
              return Row(
                children: [
                  Expanded(child: map),
                  const SizedBox(width: 24),
                  Expanded(child: detail),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _TrainingSummary extends ConsumerWidget {
  const _TrainingSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(
      trainingAnalyticsProvider(
        (period: TrainingPeriod.fourteenDays, metric: TrainingMetric.volume),
      ),
    );
    final unit =
        ref.watch(preferencesProvider).asData?.value.weightUnit ??
        WeightUnit.kg;
    final palette = TransmutePalette.of(context);

    return analyticsAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => const TransmuteStatePanel(
        kind: TransmuteStateKind.loading,
        title: 'Loading training summary',
        message: 'Your workout entry remains available.',
      ),
      error: (_, _) => TransmuteStatePanel(
        kind: TransmuteStateKind.error,
        title: 'Training summary unavailable',
        message: 'Your workout entry remains available.',
        action: TransmuteButton(
          label: 'Retry summary',
          icon: Icons.refresh,
          onPressed: () => ref.invalidate(
            trainingAnalyticsProvider(
              (
                period: TrainingPeriod.fourteenDays,
                metric: TrainingMetric.volume,
              ),
            ),
          ),
        ),
      ),
      data: (analytics) {
        if (analytics.summary.workoutCount == 0) {
          return TransmuteStatePanel(
            kind: TransmuteStateKind.empty,
            title: 'No completed workouts in last 14 days',
            message: 'Your next finished session will appear in this summary.',
            action: TransmuteButton(
              label: 'View history',
              onPressed: () => context.go('/history'),
            ),
          );
        }

        final volumeKg = analytics.summary.totalVolumeKg;
        final displayVolume = unit == WeightUnit.lb
            ? volumeKg * 2.2046226218
            : volumeKg;
        final durationMin = (analytics.summary.totalDurationSeconds / 60).round();

        // Daily volume for sparkline
        final maxDailyVol = analytics.daily.fold<double>(
          0,
          (m, b) => b.volumeKg > m ? b.volumeKg : m,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dominant volume card with mini bar sparkline
            TransmutePanel(
              child: InkWell(
                onTap: () => context.go('/profile'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL VOLUME (14D)',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: palette.muted,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${displayVolume.toStringAsFixed(0)} ${unit == WeightUnit.lb ? 'lb' : 'kg'}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${analytics.summary.workoutCount} workouts completed',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        // Right mini bar sparkline
                        if (analytics.daily.isNotEmpty && maxDailyVol > 0)
                          Semantics(
                            label: 'Volume trend sparkline over 14 days',
                            child: SizedBox(
                              height: 48,
                              width: 90,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  for (final bucket in analytics.daily.take(14))
                                    Container(
                                      width: 4,
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      height: (bucket.volumeKg / maxDailyVol * 44).clamp(4.0, 48.0),
                                      decoration: BoxDecoration(
                                        color: palette.oxide,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Three compact tiles: Duration, Records, Sets (burned calories honestly labeled unmeasured)
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.timer_outlined, size: 20, color: palette.oxide),
                          const SizedBox(height: 6),
                          Text(
                            '$durationMin min',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Duration',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.fitness_center_outlined, size: 20, color: palette.oxide),
                          const SizedBox(height: 6),
                          Text(
                            '${analytics.summary.workingSetCount}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Working sets',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 20, color: palette.gold),
                          const SizedBox(height: 6),
                          Text(
                            '${analytics.summary.personalRecordCount}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Records',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/history'),
                icon: const Icon(Icons.history),
                label: const Text('View history'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeedView extends ConsumerWidget {
  const _FeedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider);
    return ListView(
      padding: const EdgeInsets.only(top: 22, bottom: 28),
      children: [
        Text(
          'Friends’ activity',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        friends.when(
          loading: () => const TransmuteStatePanel(
            kind: TransmuteStateKind.loading,
            title: 'Loading friend activity',
            message: 'Checking shared workouts.',
          ),
          error: (_, _) => TransmuteStatePanel(
            kind: TransmuteStateKind.error,
            title: 'Activity unavailable',
            message: 'Try again to see workouts shared by friends.',
            action: TransmuteButton(
              label: 'Retry',
              onPressed: () => ref.invalidate(friendsProvider),
            ),
          ),
          data: (record) => record.activity.isEmpty
              ? TransmuteStatePanel(
                  kind: TransmuteStateKind.empty,
                  title: 'No friend workouts yet',
                  message: 'Connect with a friend to see shared training here.',
                  action: TransmuteButton(
                    label: 'Open Friends',
                    onPressed: () => context.go('/friends'),
                  ),
                )
              : Column(
                  children: [
                    for (final item in record.activity.take(8))
                      Card(
                        child: ListTile(
                          title: Text(item.name ?? item.username),
                          subtitle: Text(
                            '${item.routineName ?? 'Workout'} · ${item.dayName ?? 'Training day'} · ${item.setCount} sets',
                          ),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () =>
                              context.go('/friends/sessions/${item.id}'),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.go('/friends'),
                        child: const Text('See all friends'),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DiscoveryView extends StatelessWidget {
  const _DiscoveryView();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(top: 22, bottom: 28),
    children: [
      Text('Discover', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 5),
      const Text('Explore training, people and the record you are building.'),
      const SizedBox(height: 16),
      const _DiscoveryGrid(compact: false),
    ],
  );
}

class _DiscoveryGrid extends StatelessWidget {
  const _DiscoveryGrid({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = <(IconData, String, String, String)>[
      (
        Icons.calculate_outlined,
        'Rank Calculator',
        'Preview your personal progress rule.',
        '/ranks/calculator',
      ),
      (Icons.people_outline, 'Friends', 'See shared workouts.', '/friends'),
      (
        Icons.auto_awesome_outlined,
        'Arcana',
        'Explore earned evidence.',
        '/arcana',
      ),
      (Icons.history, 'History', 'Review completed sessions.', '/history'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (icon, title, subtitle, route) in cards)
              SizedBox(
                width: width,
                child: Card(
                  child: InkWell(
                    onTap: () => context.go(route),
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, size: 26),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
