import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/widgets/app_shell.dart';

class RanksScreen extends ConsumerStatefulWidget {
  const RanksScreen({super.key});

  @override
  ConsumerState<RanksScreen> createState() => _RanksScreenState();
}

class _RanksScreenState extends ConsumerState<RanksScreen> {
  final _query = TextEditingController();
  ExerciseTrackingMode? _mode;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ranks = ref.watch(
      exerciseRanksProvider((query: _query.text, mode: _mode)),
    );
    return AppShell(
      title: 'Ranks',
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ranks', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                const Text(
                  'Personal strength progress from confirmed, comparable work.',
                ),
                const SizedBox(height: 16),
                _RankTabs(
                  selected: 'Gallery',
                  onGallery: () {},
                  onCalculator: () => context.go('/ranks/calculator'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Search exercise ranks',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () => setState(_query.clear),
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All modes'),
                      selected: _mode == null,
                      onSelected: (_) => setState(() => _mode = null),
                    ),
                    ChoiceChip(
                      label: const Text('Reps'),
                      selected: _mode == ExerciseTrackingMode.reps,
                      onSelected: (_) =>
                          setState(() => _mode = ExerciseTrackingMode.reps),
                    ),
                    ChoiceChip(
                      label: const Text('Timed'),
                      selected: _mode == ExerciseTrackingMode.timed,
                      onSelected: (_) =>
                          setState(() => _mode = ExerciseTrackingMode.timed),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          ranks.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => SliverFillRemaining(
              child: TransmuteStatePanel(
                kind: TransmuteStateKind.error,
                title: 'Ranks are unavailable',
                message: 'Your saved rank record could not be loaded.',
                action: TransmuteButton(
                  label: 'Try again',
                  onPressed: () => ref.invalidate(
                    exerciseRanksProvider((query: _query.text, mode: _mode)),
                  ),
                ),
              ),
            ),
            data: (items) => items.isEmpty
                ? const SliverFillRemaining(
                    child: TransmuteStatePanel(
                      kind: TransmuteStateKind.empty,
                      title: 'No matching exercises',
                      message: 'Try a different movement name or mode.',
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.only(bottom: 28),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final largeText =
                            MediaQuery.textScalerOf(context).scale(1) > 1.4;
                        final columns =
                            constraints.crossAxisExtent >= 520 && !largeText
                            ? 3
                            : largeText
                            ? 1
                            : 2;
                        return SliverGrid.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: largeText ? 1.7 : .78,
                              ),
                          itemCount: items.length,
                          itemBuilder: (_, index) => _RankCard(
                            rank: items[index],
                            onTap: () => context.go(
                              '/ranks/${items[index].exercise.id}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class RankDetailScreen extends ConsumerWidget {
  const RankDetailScreen({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rank = ref.watch(exerciseRankProvider(exerciseId));
    return AppShell(
      title: 'Exercise rank',
      child: rank.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => TransmuteStatePanel(
          kind: TransmuteStateKind.error,
          title: 'Rank unavailable',
          message: 'This exercise rank could not be loaded.',
          action: TransmuteButton(
            label: 'Back to gallery',
            onPressed: () => context.go('/ranks'),
          ),
        ),
        data: (item) => ListView(
          children: [
            _RankTabs(
              selected: 'Gallery',
              onGallery: () => context.go('/ranks'),
              onCalculator: () => context.go('/ranks/calculator'),
            ),
            const SizedBox(height: 20),
            Text(
              item.exercise.name,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 6),
            Text(item.exercise.muscleGroup ?? item.exercise.category),
            const SizedBox(height: 20),
            _RankSummary(rank: item),
            const SizedBox(height: 16),
            TransmutePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How this rank works',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Two qualifying completed sessions on different dates establish a personal baseline. Confirmed non-warm-up results then compare only against this exact exercise and mode. This is personal progress, not a population percentile.',
                  ),
                  if (item.nextThreshold != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Next threshold: ${_formatValue(context, item, item.nextThreshold!)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Evidence', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (item.evidence.isEmpty)
              const TransmuteStatePanel(
                kind: TransmuteStateKind.empty,
                title: 'No qualifying evidence yet',
                message:
                    'Finish a workout with three confirmed non-warm-up sets to begin the record.',
              )
            else
              ...item.evidence.map(
                (evidence) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: Text(_formatValue(context, item, evidence.value)),
                    subtitle: Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(evidence.completedAt.toLocal()),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RankCalculatorScreen extends ConsumerStatefulWidget {
  const RankCalculatorScreen({super.key});
  @override
  ConsumerState<RankCalculatorScreen> createState() =>
      _RankCalculatorScreenState();
}

class _RankCalculatorScreenState extends ConsumerState<RankCalculatorScreen> {
  Exercise? _exercise;
  ExerciseTrackingMode _mode = ExerciseTrackingMode.reps;
  final _value = TextEditingController();
  final _baseline = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    _baseline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(exerciseRanksProvider((query: '', mode: null)));
    final value = double.tryParse(_value.text);
    final baseline = double.tryParse(_baseline.text);
    final preview = _exercise == null || value == null || value <= 0
        ? null
        : ref
              .read(exerciseRankRepositoryProvider)
              .preview(
                exercise: _exercise!,
                mode: _mode,
                value: value,
                baselineValue: baseline,
              );
    return AppShell(
      title: 'Rank calculator',
      child: ListView(
        children: [
          _RankTabs(
            selected: 'Calculator',
            onGallery: () => context.go('/ranks'),
            onCalculator: () {},
          ),
          const SizedBox(height: 20),
          Text(
            'Rank Calculator',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore the published personal-progress rule. Nothing entered here changes your saved rank.',
          ),
          const SizedBox(height: 20),
          library.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) =>
                const Text('Exercise choices are unavailable right now.'),
            data: (items) => DropdownButtonFormField<Exercise>(
              initialValue: _exercise,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Exercise'),
              items: items
                  .map(
                    (rank) => DropdownMenuItem(
                      value: rank.exercise,
                      child: Text(
                        rank.exercise.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _exercise = value),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ExerciseTrackingMode>(
            segments: const [
              ButtonSegment(
                value: ExerciseTrackingMode.reps,
                label: Text('Reps'),
              ),
              ButtonSegment(
                value: ExerciseTrackingMode.timed,
                label: Text('Timed'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (value) => setState(() => _mode = value.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _mode == ExerciseTrackingMode.timed
                  ? 'Best duration in seconds'
                  : 'Comparable result (estimated 1RM in kg, or max reps if unweighted)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _baseline,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Established baseline (optional)',
              helperText: 'Leave blank to see the provisional state.',
            ),
          ),
          const SizedBox(height: 20),
          if (preview == null)
            const TransmuteStatePanel(
              kind: TransmuteStateKind.empty,
              title: 'Enter a result',
              message:
                  'Choose an exercise and a positive comparable result to preview its rank.',
            )
          else
            _RankSummary(rank: preview),
        ],
      ),
    );
  }
}

class _RankTabs extends StatelessWidget {
  const _RankTabs({
    required this.selected,
    required this.onGallery,
    required this.onCalculator,
  });
  final String selected;
  final VoidCallback onGallery;
  final VoidCallback onCalculator;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'Gallery',
          label: Text('Gallery'),
          icon: Icon(Icons.grid_view_outlined),
        ),
        ButtonSegment(
          value: 'Calculator',
          label: Text('Calculator'),
          icon: Icon(Icons.calculate_outlined),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (value) =>
          value.first == 'Gallery' ? onGallery() : onCalculator(),
    ),
  );
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.rank, required this.onTap});
  final ExerciseRank rank;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${rank.exercise.name} ${rank.tier?.name ?? 'unranked'}',
    child: Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                rank.tier == null
                    ? (rank.isProvisional ? 'PROVISIONAL' : 'UNRANKED')
                    : '${rank.tier!.name.toUpperCase()} ${rank.subdivision ?? ''}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              Icon(
                rank.tier == null
                    ? Icons.auto_awesome_outlined
                    : Icons.workspace_premium,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                rank.exercise.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                rank.bestValue == null
                    ? 'Needs qualifying evidence'
                    : 'Best ${_formatValue(context, rank, rank.bestValue!)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: rank.isRanked
                    ? (rank.progressPoints! / 100).clamp(0, 1)
                    : 0,
              ),
              const SizedBox(height: 4),
              Text(
                rank.isRanked
                    ? '${rank.progressPoints} points'
                    : '2 dates to establish',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RankSummary extends StatelessWidget {
  const _RankSummary({required this.rank});
  final ExerciseRank rank;
  @override
  Widget build(BuildContext context) => TransmutePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              rank.isRanked
                  ? Icons.workspace_premium
                  : Icons.auto_awesome_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                rank.isRanked
                    ? '${rank.tier!.name} ${rank.subdivision ?? ''}'
                    : rank.isProvisional
                    ? 'Provisional evidence'
                    : 'Unranked',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          rank.isRanked
              ? '${rank.progressPoints} Transmute progress points'
              : 'Two qualifying sessions on different dates are required.',
        ),
        if (rank.bestValue != null) ...[
          const SizedBox(height: 8),
          Text(
            'Best comparable result: ${_formatValue(context, rank, rank.bestValue!)}',
          ),
        ],
        if (rank.baselineValue != null)
          Text('Baseline: ${_formatValue(context, rank, rank.baselineValue!)}'),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: rank.isRanked ? (rank.progressPoints! / 100).clamp(0, 1) : 0,
        ),
      ],
    ),
  );
}

String _formatValue(BuildContext context, ExerciseRank rank, double value) {
  if (rank.metric == ExerciseRankMetric.maxDurationSeconds)
    return '${value.round()} sec';
  if (rank.metric == ExerciseRankMetric.maxReps) return '${value.round()} reps';
  final unit =
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(authControllerProvider).user?.weightUnit ??
      WeightUnit.lb;
  final display = unit == WeightUnit.lb ? value * 2.2046226218 : value;
  return '${display.toStringAsFixed(1)} ${unit == WeightUnit.lb ? 'lb' : 'kg'} e1RM';
}
