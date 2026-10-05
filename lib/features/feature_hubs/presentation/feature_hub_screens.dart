import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
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
          const SizedBox(height: 20),
          const _ProfileActivitySection(),
          const SizedBox(height: 20),
          const _ProfileStrengthGoalsSection(),
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

class _ProfileActivitySection extends ConsumerStatefulWidget {
  const _ProfileActivitySection();

  @override
  ConsumerState<_ProfileActivitySection> createState() =>
      _ProfileActivitySectionState();
}

class _ProfileActivitySectionState
    extends ConsumerState<_ProfileActivitySection> {
  TrainingPeriod _period = TrainingPeriod.sevenDays;
  TrainingMetric _metric = TrainingMetric.volume;

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(
      trainingAnalyticsProvider((period: _period, metric: _metric)),
    );
    final unit =
        ref.watch(preferencesProvider).asData?.value.weightUnit ??
        WeightUnit.kg;
    final palette = TransmutePalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Training activity',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<TrainingPeriod>(
              segments: const [
                ButtonSegment(
                  value: TrainingPeriod.sevenDays,
                  label: Text('7D'),
                ),
                ButtonSegment(
                  value: TrainingPeriod.fourteenDays,
                  label: Text('14D'),
                ),
                ButtonSegment(
                  value: TrainingPeriod.thirtyDays,
                  label: Text('30D'),
                ),
              ],
              selected: {_period},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  setState(() => _period = set.first);
                }
              },
            ),
            SegmentedButton<TrainingMetric>(
              segments: const [
                ButtonSegment(
                  value: TrainingMetric.volume,
                  label: Text('Volume'),
                ),
                ButtonSegment(
                  value: TrainingMetric.duration,
                  label: Text('Duration'),
                ),
                ButtonSegment(
                  value: TrainingMetric.reps,
                  label: Text('Reps'),
                ),
              ],
              selected: {_metric},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  setState(() => _metric = set.first);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        analyticsAsync.when(
          loading: () => const TransmuteStatePanel(
            kind: TransmuteStateKind.loading,
            title: 'Loading activity',
            message: 'Calculating activity records for selected period...',
          ),
          error: (_, _) => TransmuteStatePanel(
            kind: TransmuteStateKind.error,
            title: 'Activity unavailable',
            message: 'Your training activity could not be loaded.',
            action: TransmuteButton(
              label: 'Retry',
              icon: Icons.refresh,
              onPressed: () => ref.invalidate(
                trainingAnalyticsProvider((period: _period, metric: _metric)),
              ),
            ),
          ),
          data: (analytics) {
            if (analytics.summary.workoutCount == 0) {
              return TransmuteStatePanel(
                kind: TransmuteStateKind.empty,
                title: 'No workouts in this period',
                message:
                    'Completed workouts in the last ${_period.days} days will appear here.',
                action: TransmuteButton(
                  label: 'View history',
                  onPressed: () => context.go('/history'),
                ),
              );
            }

            final summary = analytics.summary;
            String dominantLabel;
            String dominantValue;
            switch (_metric) {
              case TrainingMetric.volume:
                final vol = unit == WeightUnit.lb
                    ? summary.totalVolumeKg * 2.2046226218
                    : summary.totalVolumeKg;
                dominantLabel = 'TOTAL VOLUME';
                dominantValue =
                    '${vol.toStringAsFixed(0)} ${unit == WeightUnit.lb ? 'lb' : 'kg'}';
              case TrainingMetric.duration:
                dominantLabel = 'TOTAL DURATION';
                dominantValue = _formatDuration(summary.totalDurationSeconds);
              case TrainingMetric.reps:
                dominantLabel = 'TOTAL REPS';
                dominantValue = '${summary.totalReps} reps';
            }

            double getDailyValue(TrainingDailyBucket b) {
              switch (_metric) {
                case TrainingMetric.volume:
                  return unit == WeightUnit.lb
                      ? b.volumeKg * 2.2046226218
                      : b.volumeKg;
                case TrainingMetric.duration:
                  return b.durationSeconds.toDouble();
                case TrainingMetric.reps:
                  return b.reps.toDouble();
              }
            }

            final maxVal = analytics.daily.fold<double>(
              0.0,
              (m, b) => math.max(m, getDailyValue(b)),
            );

            return TransmutePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dominantLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.muted,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dominantValue,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary.workoutCount} workout${summary.workoutCount == 1 ? '' : 's'} · ${summary.workingSetCount} working sets · ${summary.personalRecordCount} PR${summary.personalRecordCount == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    label:
                        'Daily ${_metric.label} chart for last ${_period.days} days',
                    child: SizedBox(
                      height: 120,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final bucket in analytics.daily)
                            Expanded(
                              child: _DailyBarItem(
                                bucket: bucket,
                                value: getDailyValue(bucket),
                                maxValue: maxVal,
                                metric: _metric,
                                unit: unit,
                                palette: palette,
                                period: _period,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;
    return remMinutes > 0 ? '${hours}h ${remMinutes}m' : '${hours}h';
  }
}

class _DailyBarItem extends StatelessWidget {
  const _DailyBarItem({
    required this.bucket,
    required this.value,
    required this.maxValue,
    required this.metric,
    required this.unit,
    required this.palette,
    required this.period,
  });

  final TrainingDailyBucket bucket;
  final double value;
  final double maxValue;
  final TrainingMetric metric;
  final WeightUnit unit;
  final TransmutePalette palette;
  final TrainingPeriod period;

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(bucket.date);
    final dayLabel = parsedDate != null ? '${parsedDate.day}' : '';
    final weekdayLabel = parsedDate != null
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][parsedDate.weekday - 1]
        : '';
    final label = period == TrainingPeriod.sevenDays ? weekdayLabel : dayLabel;

    final ratio = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final barHeight = ratio > 0 ? (ratio * 75).clamp(4.0, 75.0) : 0.0;

    String tooltipValue;
    switch (metric) {
      case TrainingMetric.volume:
        tooltipValue =
            '${value.toStringAsFixed(0)} ${unit == WeightUnit.lb ? 'lb' : 'kg'}';
      case TrainingMetric.duration:
        final min = (value / 60).round();
        tooltipValue = '${min}m';
      case TrainingMetric.reps:
        tooltipValue = '${value.toInt()} reps';
    }

    return Tooltip(
      message: '${bucket.date}: $tooltipValue',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: value > 0 ? palette.oxide : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: palette.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ],
        ),
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

class _ProfileStrengthGoalsSection extends ConsumerWidget {
  const _ProfileStrengthGoalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TransmutePalette.of(context);
    final unit =
        ref.watch(preferencesProvider).asData?.value.weightUnit ??
        WeightUnit.kg;
    final goalsAsync = ref.watch(goalsProvider);

    return goalsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (goals) {
        final strengthGoals = goals.where((g) => g.category == GoalCategory.strength).toList();
        if (strengthGoals.isEmpty) {
          return TransmutePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag_outlined, color: palette.oxide),
                    const SizedBox(width: 8),
                    Text(
                      'Strength target',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Set a strength goal linked to an exercise to track your estimated 1RM progression.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.muted,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/goals'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Set strength goal'),
                ),
              ],
            ),
          );
        }

        final topGoal = strengthGoals.first;
        final exerciseRanksAsync = ref.watch(
          exerciseRanksProvider((query: '', mode: null)),
        );
        final rank = exerciseRanksAsync.asData?.value
            .where((r) => r.exercise.id == topGoal.exerciseId)
            .firstOrNull;

        // Current value: prefer rank bestValue (confirmed estimated 1RM or max rep) if available
        final currentEstimated1RM = rank?.bestValue ?? topGoal.current;
        final currentDisplay = (topGoal.unit.toLowerCase().contains('lb') || unit == WeightUnit.lb)
            ? (topGoal.unit.toLowerCase().contains('kg') ? currentEstimated1RM * 2.2046226218 : currentEstimated1RM)
            : currentEstimated1RM;
        final targetDisplay = (topGoal.unit.toLowerCase().contains('lb') || unit == WeightUnit.lb)
            ? (topGoal.unit.toLowerCase().contains('kg') ? topGoal.target * 2.2046226218 : topGoal.target)
            : topGoal.target;

        final ratio = (topGoal.target - topGoal.baseline).abs() > 0.0001
            ? ((currentEstimated1RM - topGoal.baseline) / (topGoal.target - topGoal.baseline)).clamp(0.0, 1.0)
            : topGoal.progressRatio;

        final daysLeft = topGoal.daysRemaining;

        return TransmutePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STRENGTH TARGET · ${topGoal.exerciseName?.toUpperCase() ?? topGoal.title.toUpperCase()}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: palette.oxide,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              currentDisplay.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              topGoal.unit,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: palette.muted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(est. 1RM)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: palette.muted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target: ${targetDisplay.toStringAsFixed(1)} ${topGoal.unit}'
                          '${daysLeft >= 0 ? ' · $daysLeft days left' : ' · Overdue'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: ratio,
                          strokeWidth: 5,
                          backgroundColor: palette.divider,
                          color: palette.oxide,
                        ),
                        Text(
                          '${(ratio * 100).round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: palette.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${strengthGoals.length} active strength goal${strengthGoals.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.muted,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/goals'),
                    child: const Text('View goals'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

