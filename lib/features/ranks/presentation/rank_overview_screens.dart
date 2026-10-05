import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/theme/transmute_palette.dart';
import '../../../shared/widgets/app_shell.dart';
import 'ranks_screens.dart';

class OverallRanksScreen extends ConsumerWidget {
  const OverallRanksScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(rankOverviewProvider);
    final history = ref.watch(overallRankHistoryProvider);
    return AppShell(
      title: 'Ranks',
      child: ListView(
        children: [
          Text('Your Rank', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          const Text(
            'A personal projection from confirmed, mapped exercise ranks.',
          ),
          const SizedBox(height: 16),
          const RankTabs(selected: 'Your Rank'),
          const SizedBox(height: 18),
          overview.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const TransmuteStatePanel(
              kind: TransmuteStateKind.error,
              title: 'Rank projection unavailable',
              message: 'Your saved rank projection could not be loaded.',
            ),
            data: (data) => Column(
              children: [
                _OverallHero(overall: data.overall),
                const SizedBox(height: 14),
                _PlacementCard(overall: data.overall),
                const SizedBox(height: 22),
                Text(
                  'Rank over time',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                history.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Rank history is unavailable.'),
                  data: (items) => _HistoryCard(items: items),
                ),
                const SizedBox(height: 16),
                const TransmuteStatePanel(
                  kind: TransmuteStateKind.empty,
                  title: 'Standings unlock later',
                  message:
                      'There is no global standing or percentile here. Leagues will require your explicit opt-in after placement.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RankBodygraphScreen extends ConsumerStatefulWidget {
  const RankBodygraphScreen({super.key});
  @override
  ConsumerState<RankBodygraphScreen> createState() =>
      _RankBodygraphScreenState();
}

class _RankBodygraphScreenState extends ConsumerState<RankBodygraphScreen> {
  String? selected;
  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(rankOverviewProvider);
    return AppShell(
      title: 'Rank bodygraph',
      child: ListView(
        children: [
          Text('Bodygraph', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          const Text(
            'Personal rank coverage, separate from recovery readiness.',
          ),
          const SizedBox(height: 16),
          const RankTabs(selected: 'Bodygraph'),
          const SizedBox(height: 18),
          overview.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const TransmuteStatePanel(
              kind: TransmuteStateKind.error,
              title: 'Bodygraph unavailable',
              message: 'Muscle rank projections could not be loaded.',
            ),
            data: (data) {
              final groups = _allGroups(data.groups);
              final active =
                  groups
                      .where((item) => item.groupId == selected)
                      .firstOrNull ??
                  groups.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth >= 720
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: RankAnatomy(
                                  groups: groups,
                                  selected: active.groupId,
                                  onSelect: (id) =>
                                      setState(() => selected = id),
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 280,
                                child: _MuscleDetail(group: active),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              RankAnatomy(
                                groups: groups,
                                selected: active.groupId,
                                onSelect: (id) => setState(() => selected = id),
                              ),
                              const SizedBox(height: 12),
                              _MuscleDetail(group: active),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  TransmutePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latest confirmed changes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.lastSessionChanges.isEmpty
                              ? 'No confirmed muscle-rank increase in the latest projection.'
                              : '${data.lastSessionChanges.length} group${data.lastSessionChanges.length == 1 ? '' : 's'} improved: ${data.lastSessionChanges.join(', ')}.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Muscle rankings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Bodygraph legend and muscle details',
                    child: Column(
                      children: [
                        for (final group in groups)
                          TransmutePanel(
                            padding: EdgeInsets.zero,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(group.label),
                              subtitle: Text(_groupStatus(group)),
                              trailing: group.tier == null
                                  ? const Icon(Icons.help_outline)
                                  : Text(_tierName(group.tier!)),
                              selected: active.groupId == group.groupId,
                              onTap: () =>
                                  setState(() => selected = group.groupId),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class RankLeaguesScreen extends ConsumerWidget {
  const RankLeaguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueAsync = ref.watch(leagueStandingsProvider(null));
    final theme = Theme.of(context);

    return AppShell(
      title: 'Rank leagues',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const RankTabs(selected: 'Leagues'),
          const SizedBox(height: 18),
          Text('Rank Leagues', style: theme.textTheme.displaySmall),
          const SizedBox(height: 6),
          const Text(
            'Verified monthly league cohorts based on placement eligibility (10 ranked exercises across at least 5 muscle groups).',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),

          leagueAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => TransmuteStatePanel(
              kind: TransmuteStateKind.error,
              title: 'Leagues unavailable',
              message: 'Could not load league standings: $err',
              action: TransmuteButton(
                label: 'Retry',
                onPressed: () => ref.invalidate(leagueStandingsProvider(null)),
              ),
            ),
            data: (data) => _buildLeagueContent(context, ref, data),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueContent(BuildContext context, WidgetRef ref, LeagueResponse data) {
    final theme = Theme.of(context);

    if (!data.isEligible) {
      final remaining = 10 - data.eligibleExerciseCount;
      return Column(
        children: [
          TransmuteStatePanel(
            kind: TransmuteStateKind.empty,
            title: remaining > 0 ? '$remaining exercises to placement' : 'Placement in progress',
            message: 'You currently have ${data.eligibleExerciseCount}/10 ranked exercises. Rank at least 10 mapped exercises across 5 muscle groups to unlock league participation.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/ranks/gallery'),
            icon: const Icon(Icons.fitness_center),
            label: const Text('Browse Exercise Ranks'),
          ),
        ],
      );
    }

    if (!data.isOptedIn) {
      return Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.workspace_premium_outlined, size: 54, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Placement Complete!',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'You are eligible for Competitive Leagues! Participation is strictly opt-in. Opt in to compete against other verified lifters in your monthly cohort.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      await ref.read(friendsRepositoryProvider).updateSocialPreferences(leagueOptIn: true);
                      ref.invalidate(socialPreferencesProvider);
                      ref.invalidate(leagueStandingsProvider(null));
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Opt In to Leagues'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta cohort info & Opt-out option
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Period: ${data.period}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () async {
                        await ref.read(friendsRepositoryProvider).updateSocialPreferences(leagueOptIn: false);
                        ref.invalidate(socialPreferencesProvider);
                        ref.invalidate(leagueStandingsProvider(null));
                      },
                      child: const Text('Leave League'),
                    ),
                  ],
                ),
                Text(
                  'Cohort size: ${data.cohortSize} lifters · Tie Rule: ${data.tieRule}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (data.entries.isEmpty)
          const TransmuteStatePanel(
            kind: TransmuteStateKind.empty,
            title: 'No cohort lifters yet',
            message: 'You are the first opted-in eligible lifter in this period cohort.',
          )
        else
          ...data.entries.map((entry) {
            final isTop3 = entry.rank <= 3;
            final isCurrentUser = entry.isCurrentUser;

            Color? rankColor;
            if (entry.rank == 1) rankColor = const Color(0xFFFFD700);
            else if (entry.rank == 2) rankColor = const Color(0xFFC0C0C0);
            else if (entry.rank == 3) rankColor = const Color(0xFFCD7F32);

            return Card(
              color: isCurrentUser
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : null,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isCurrentUser
                    ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isTop3 ? rankColor?.withValues(alpha: 0.2) : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${entry.rank}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isTop3 ? rankColor : null,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                title: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      entry.name ?? entry.username,
                      style: TextStyle(
                        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.tier.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSecondaryContainer),
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  '@${entry.username} · ${entry.qualifiedSessions} workouts',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                trailing: Text(
                  '${entry.xp} XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class RankAnalysisScreen extends ConsumerWidget {
  const RankAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(rankAnalysisProvider);
    final unit =
        ref.watch(preferencesProvider).asData?.value.weightUnit ??
        WeightUnit.kg;

    return AppShell(
      title: 'Rank analysis',
      child: ListView(
        children: [
          const RankTabs(selected: 'Analysis'),
          const SizedBox(height: 22),
          Text('Analysis', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          const Text(
            'Performance history, category averages and rank distribution.',
          ),
          const SizedBox(height: 18),
          analysisAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => TransmuteStatePanel(
              kind: TransmuteStateKind.error,
              title: 'Analysis unavailable',
              message: 'Your saved rank analysis could not be loaded.',
              action: TransmuteButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: () => ref.invalidate(rankAnalysisProvider),
              ),
            ),
            data: (data) {
              final hasRankedExercises =
                  data.categories.any((c) => c.rankedCount > 0) ||
                  data.upcomingTargets.isNotEmpty ||
                  data.tierDistribution.any((t) => t.count > 0);

              if (!hasRankedExercises) {
                return Column(
                  children: [
                    const TransmuteStatePanel(
                      kind: TransmuteStateKind.empty,
                      title: 'No ranked exercise analysis yet',
                      message:
                          'Category averages, upcoming targets, and tier distributions appear once you log qualifying sets across sessions.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TransmuteButton(
                        label: 'Explore exercise ranks',
                        icon: Icons.grid_view_outlined,
                        onPressed: () => context.go('/ranks/gallery'),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CategoryAveragesCard(categories: data.categories),
                  const SizedBox(height: 20),
                  if (data.upcomingTargets.isNotEmpty) ...[
                    _UpcomingTargetsCard(
                      targets: data.upcomingTargets,
                      unit: unit,
                    ),
                    const SizedBox(height: 20),
                  ],
                  _WeeklyRankUpsCard(weeklyRankUps: data.weeklyRankUps),
                  const SizedBox(height: 20),
                  _TierDistributionCard(
                    distribution: data.tierDistribution,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

typedef RankAnalysisPlaceholderScreen = RankAnalysisScreen;

Color _tierColor(ExerciseRankTier tier, TransmutePalette palette) {
  switch (tier) {
    case ExerciseRankTier.bronze:
      return const Color(0xFFCD7F32);
    case ExerciseRankTier.silver:
      return const Color(0xFFC0C0C0);
    case ExerciseRankTier.gold:
      return palette.gold;
    case ExerciseRankTier.platinum:
      return const Color(0xFF00CED1);
    case ExerciseRankTier.transmuted:
      return palette.oxide;
  }
}

String _formatTargetValue(
  double value,
  ExerciseTrackingMode mode,
  ExerciseRankMetric metric,
  WeightUnit unit,
) {
  if (mode == ExerciseTrackingMode.timed ||
      metric == ExerciseRankMetric.maxDurationSeconds) {
    final s = value.round();
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final rem = s % 60;
    return rem > 0 ? '${m}m ${rem}s' : '${m}m';
  }
  if (metric == ExerciseRankMetric.maxReps) {
    return '${value.round()} reps';
  }
  final displayVal = unit == WeightUnit.lb ? value * 2.2046226218 : value;
  return '${displayVal.toStringAsFixed(1)} ${unit == WeightUnit.lb ? 'lb' : 'kg'}';
}

class _CategoryAveragesCard extends StatelessWidget {
  const _CategoryAveragesCard({required this.categories});
  final List<RankCategorySummary> categories;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return TransmutePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category averages',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Average rank tier and strength progress across equipment categories',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 12),
          for (final cat in categories) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _categoryIcon(cat.category),
                color: palette.oxide,
              ),
              title: Text(
                cat.category[0].toUpperCase() + cat.category.substring(1),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${cat.rankedCount} of ${cat.totalCount} ranked',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    cat.averageTier != null
                        ? _tierName(cat.averageTier!)
                        : 'Unranked',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cat.averageTier != null
                          ? _tierColor(cat.averageTier!, palette)
                          : palette.muted,
                    ),
                  ),
                  if (cat.averageRatio != null)
                    Text(
                      '${(cat.averageRatio! * 100).toStringAsFixed(0)}% score',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (cat != categories.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'barbell':
        return Icons.fitness_center;
      case 'dumbbell':
        return Icons.fitness_center_outlined;
      case 'bodyweight':
        return Icons.accessibility_new;
      case 'machine':
        return Icons.precision_manufacturing_outlined;
      case 'cable':
        return Icons.cable_outlined;
      default:
        return Icons.sports_gymnastics;
    }
  }
}

class _UpcomingTargetsCard extends StatelessWidget {
  const _UpcomingTargetsCard({
    required this.targets,
    required this.unit,
  });
  final List<RankUpcomingTarget> targets;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return TransmutePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next rank targets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Exercises closest to promoting to the next tier',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 12),
          for (final target in targets) ...[
            InkWell(
              onTap: () => context.go('/ranks/gallery/${target.exerciseId}'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          color: _tierColor(target.tier, palette),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            target.exerciseName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          _tierName(target.tier),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _tierColor(target.tier, palette),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${target.category.toUpperCase()}${target.muscleGroup != null ? ' · ${target.muscleGroup}' : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: palette.muted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current: ${_formatTargetValue(target.currentValue, target.trackingMode, target.metric, unit)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${target.progressPoints} / 100 pts',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (target.progressPoints / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: palette.divider,
                        color: palette.oxide,
                      ),
                    ),
                    if (target.nextThreshold != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Next tier threshold: ${_formatTargetValue(target.nextThreshold!, target.trackingMode, target.metric, unit)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.oxide,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (target != targets.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _WeeklyRankUpsCard extends StatelessWidget {
  const _WeeklyRankUpsCard({required this.weeklyRankUps});
  final List<WeeklyRankUpCount> weeklyRankUps;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    final totalRankUps =
        weeklyRankUps.fold<int>(0, (sum, w) => sum + w.count);

    return TransmutePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly promotions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (totalRankUps > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: palette.oxide.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$totalRankUps total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: palette.oxide,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'New rank tiers achieved across recent training weeks',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 12),
          if (weeklyRankUps.isEmpty || totalRankUps == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No rank promotions recorded in recent weeks.',
                style: TextStyle(color: palette.muted),
              ),
            )
          else ...[
            for (final week in weeklyRankUps) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Week of ${week.weekStart}'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: week.count > 0
                            ? palette.oxide.withValues(alpha: .2)
                            : palette.divider,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        week.count > 0
                            ? '+${week.count} rank up${week.count == 1 ? '' : 's'}'
                            : '0',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: week.count > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: week.count > 0 ? palette.oxide : palette.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (week != weeklyRankUps.last) const Divider(height: 1),
            ],
          ],
        ],
      ),
    );
  }
}

class _TierDistributionCard extends StatelessWidget {
  const _TierDistributionCard({required this.distribution});
  final List<RankTierCount> distribution;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    final rankedTiers = distribution;
    final totalRanked =
        rankedTiers.fold<int>(0, (sum, t) => sum + t.count);

    return TransmutePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tier distribution',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Distribution of all ranked exercises by tier ($totalRanked ranked)',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 14),
          if (totalRanked == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No exercises currently ranked.',
                style: TextStyle(color: palette.muted),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (final tierCount in rankedTiers)
                      if (tierCount.count > 0)
                        Expanded(
                          flex: tierCount.count,
                          child: Container(
                            color: _tierColor(tierCount.tier, palette),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final tierCount in rankedTiers)
                  if (tierCount.count > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _tierColor(tierCount.tier, palette),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_tierName(tierCount.tier)}: ${tierCount.count}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OverallHero extends StatelessWidget {
  const _OverallHero({required this.overall});
  final OverallRank overall;
  @override
  Widget build(BuildContext context) => TransmutePanel(
    child: Column(
      children: [
        Icon(
          Icons.workspace_premium_outlined,
          size: 62,
          color: TransmutePalette.of(context).oxide,
        ),
        const SizedBox(height: 8),
        Text(
          overall.placementEligible
              ? '${_tierName(overall.tier!)} personal rank'
              : 'Placement in progress',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          overall.score == null
              ? 'Not enough mapped evidence yet'
              : 'Personal score ${(overall.score! * 100).toStringAsFixed(0)}',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _PlacementCard extends StatelessWidget {
  const _PlacementCard({required this.overall});
  final OverallRank overall;
  @override
  Widget build(BuildContext context) {
    final filled = overall.eligibleExerciseCount.clamp(0, 10);
    return TransmutePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Placement', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            overall.placementEligible
                ? 'Your mapped rank evidence meets placement requirements.'
                : '${10 - filled} more ranked exercise${10 - filled == 1 ? '' : 's'} and ${5 - overall.mappedGroupCount > 0 ? 5 - overall.mappedGroupCount : 0} more mapped group${5 - overall.mappedGroupCount == 1 ? '' : 's'} are needed.',
          ),
          const SizedBox(height: 12),
          Semantics(
            label: '$filled of 10 ranked exercise placement tokens filled',
            child: Row(
              children: [
                for (var i = 0; i < 10; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 10,
                      decoration: BoxDecoration(
                        color: i < filled
                            ? TransmutePalette.of(context).oxide
                            : TransmutePalette.of(context).divider,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TransmuteButton(
              label: 'Rank exercises',
              onPressed: () => context.go('/ranks/gallery'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.items});
  final List<OverallRankHistoryPoint> items;
  @override
  Widget build(BuildContext context) => items.isEmpty
      ? const TransmuteStatePanel(
          kind: TransmuteStateKind.empty,
          title: 'No rank history yet',
          message:
              'History begins after eligible mapped evidence is confirmed.',
        )
      : TransmutePanel(
          child: Column(
            children: [
              for (final item in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timeline_outlined),
                  title: Text(
                    item.tier == null
                        ? 'Placement update'
                        : '${_tierName(item.tier!)} projection',
                  ),
                  subtitle: Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(item.calculatedAt.toLocal()),
                  ),
                  trailing: Text('${item.eligibleExerciseCount}/10'),
                ),
            ],
          ),
        );
}

class _MuscleDetail extends StatelessWidget {
  const _MuscleDetail({required this.group});
  final MuscleRank group;
  @override
  Widget build(BuildContext context) => TransmutePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(_groupStatus(group)),
        if (group.delta != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${group.delta! >= 0 ? '+' : ''}${(group.delta! * 100).toStringAsFixed(1)}% since prior projection',
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Region ID: ${group.regionId}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class RankAnatomy extends StatelessWidget {
  const RankAnatomy({
    super.key,
    required this.groups,
    required this.selected,
    required this.onSelect,
  });
  final List<MuscleRank> groups;
  final String selected;
  final ValueChanged<String> onSelect;
  static final _templates = Future.wait([
    rootBundle.loadString('assets/transmute/muscle-front.svg'),
    rootBundle.loadString('assets/transmute/muscle-back.svg'),
  ]);
  @override
  Widget build(BuildContext context) => FutureBuilder<List<String>>(
    future: _templates,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox(height: 270);
      final colors = <String, Color>{};
      for (final group in groups) {
        final color = group.groupId == selected
            ? TransmutePalette.of(context).oxide
            : group.isRanked
            ? TransmutePalette.of(context).oxide.withValues(alpha: .55)
            : TransmutePalette.of(context).divider;
        for (final region in _regions[group.regionId] ?? const [])
          colors[region] = color;
      }
      return Semantics(
        label:
            'Front and back ranked muscle bodygraph. Selected ${groups.firstWhere((item) => item.groupId == selected).label}. Use the muscle ranking list to choose a region.',
        child: SizedBox(
          height: 270,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SvgPicture.string(
                  _colorSvg(
                    snapshot.data![0],
                    colors,
                    TransmutePalette.of(context).divider,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SvgPicture.string(
                  _colorSvg(
                    snapshot.data![1],
                    colors,
                    TransmutePalette.of(context).surface,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

const _regions = <String, List<String>>{
  'chest': ['chest'],
  'back': ['upper-back', 'lower-back', 'trapezius'],
  'deltoids': ['deltoids'],
  'quadriceps': ['quadriceps'],
  'hamstrings': ['hamstring'],
  'calves': ['calves'],
  'forearms': ['forearm', 'biceps', 'triceps'],
  'glutes': ['gluteal'],
  'core': ['abs', 'obliques'],
};
const _svgRegions = [
  'abs',
  'adductors',
  'ankles',
  'biceps',
  'calves',
  'chest',
  'deltoids',
  'feet',
  'forearm',
  'gluteal',
  'hair',
  'hamstring',
  'hands',
  'head',
  'knees',
  'lower-back',
  'neck',
  'obliques',
  'quadriceps',
  'tibialis',
  'trapezius',
  'triceps',
  'upper-back',
];
String _colorSvg(String source, Map<String, Color> colors, Color fallback) {
  var svg = source;
  for (final region in _svgRegions) {
    final color = colors[region] ?? fallback;
    final fill = '#${color.toARGB32().toRadixString(16).substring(2)}';
    final stroke =
        '#${color.withValues(alpha: .8).toARGB32().toRadixString(16).substring(2)}';
    svg = svg
        .replaceAll('{{$region}}', fill)
        .replaceAll(
          '{{$region'
          'Stroke}}',
          stroke,
        );
  }
  return svg;
}

List<MuscleRank> _allGroups(List<MuscleRank> groups) {
  const base = [
    ('chest', 'Chest', 'chest', 'front'),
    ('back', 'Back', 'back', 'back'),
    ('shoulders', 'Shoulders', 'deltoids', 'front'),
    ('quads', 'Quads', 'quadriceps', 'front'),
    ('hamstrings', 'Hamstrings', 'hamstrings', 'back'),
    ('calves', 'Calves', 'calves', 'back'),
    ('arms', 'Arms', 'forearms', 'front'),
    ('core', 'Core / Abs', 'core', 'front'),
    ('glutes', 'Glutes', 'glutes', 'back'),
  ];
  return [
    for (final item in base)
      groups.where((group) => group.groupId == item.$1).firstOrNull ??
          MuscleRank(
            groupId: item.$1,
            label: item.$2,
            regionId: item.$3,
            bodySide: item.$4,
            eligibleExerciseCount: 0,
          ),
  ];
}

String _tierName(ExerciseRankTier tier) =>
    '${tier.name[0].toUpperCase()}${tier.name.substring(1)}';
String _groupStatus(MuscleRank group) => group.isRanked
    ? '${_tierName(group.tier!)} · ${(group.score! * 100).toStringAsFixed(0)} personal score · ${group.eligibleExerciseCount} eligible exercise${group.eligibleExerciseCount == 1 ? '' : 's'}'
    : 'Unranked: ${group.eligibleExerciseCount == 0 ? 'no mapped ranked exercises yet' : 'not enough comparable evidence'}';
