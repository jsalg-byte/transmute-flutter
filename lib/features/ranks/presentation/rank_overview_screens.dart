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
                          Card(
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
  Widget build(BuildContext context, WidgetRef ref) => AppShell(
    title: 'Rank leagues',
    child: ListView(
      children: [
        const RankTabs(selected: 'Leagues'),
        const SizedBox(height: 22),
        Icon(
          Icons.groups_outlined,
          size: 68,
          color: TransmutePalette.of(context).oxide,
        ),
        const SizedBox(height: 12),
        Text('Leagues', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        ref
            .watch(rankOverviewProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Eligibility is unavailable.'),
              data: (data) => TransmuteStatePanel(
                kind: TransmuteStateKind.empty,
                title: data.overall.placementEligible
                    ? 'Placement complete'
                    : '${10 - data.overall.eligibleExerciseCount > 0 ? 10 - data.overall.eligibleExerciseCount : 0} ranked exercises to placement',
                message: data.overall.placementEligible
                    ? 'League participation will be an explicit opt-in when that verified cohort ships. No opponents are shown yet.'
                    : 'Rank 10 mapped exercises across at least five groups to become eligible. This is not a public standing.',
              ),
            ),
      ],
    ),
  );
}

class RankAnalysisPlaceholderScreen extends StatelessWidget {
  const RankAnalysisPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Rank analysis',
    child: ListView(
      children: [
        const RankTabs(selected: 'Analysis'),
        const SizedBox(height: 22),
        Text('Analysis', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 10),
        const TransmuteStatePanel(
          kind: TransmuteStateKind.empty,
          title: 'Analysis arrives next',
          message:
              'Rank distribution and performance-history statistics are the next slice. Your saved bodygraph and history stay available now.',
        ),
      ],
    ),
  );
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
