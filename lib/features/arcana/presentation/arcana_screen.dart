import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/theme/transmute_palette.dart';
import '../../../shared/widgets/app_shell.dart';

class ArcanaScreen extends ConsumerStatefulWidget {
  const ArcanaScreen({super.key});

  @override
  ConsumerState<ArcanaScreen> createState() => _ArcanaScreenState();
}

class _ArcanaScreenState extends ConsumerState<ArcanaScreen> {
  ArcanaStage? _filter;
  bool _reconciling = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(arcanaProvider);
    return AppShell(
      title: 'Arcana',
      child: state.when(
        loading: _ArcanaLoading.new,
        error: (error, _) => _ArcanaFailure(
          message: _messageFor(error),
          onRetry: () => ref.read(arcanaProvider.notifier).refresh(),
        ),
        data: _content,
      ),
    );
  }

  Widget _content(ArcanaData data) {
    final revealed = data.cards
        .where((card) => card.stage != ArcanaStage.unrevealed)
        .length;
    final cards = _filter == null
        ? data.cards
        : data.cards.where((card) => card.stage == _filter).toList();

    return ListView(
      children: [
        _Header(
          ruleVersion: data.ruleVersion,
          reconciling: _reconciling,
          onReconcile: _reconciling ? null : () => _reconcile(data),
        ),
        const SizedBox(height: 16),
        _CollectionProgress(revealed: revealed, total: data.cards.length),
        const SizedBox(height: 24),
        const _SectionHeading(
          title: 'Current thread',
          supporting: 'Pin any revealed card to keep its evidence in view.',
        ),
        const SizedBox(height: 10),
        _PinnedThread(data: data, onOpen: _detail),
        const SizedBox(height: 24),
        const _SectionHeading(
          title: 'Collection',
          supporting: 'Each stage is confirmed by your saved record.',
        ),
        const SizedBox(height: 10),
        Semantics(
          label: 'Filter Arcana collection',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All cards'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              ...ArcanaStage.values.map(
                (stage) => ChoiceChip(
                  label: Text(_stageLabel(stage)),
                  selected: _filter == stage,
                  onSelected: (_) => setState(() => _filter = stage),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (cards.isEmpty)
          const _EmptyFilter()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 4
                  : constraints.maxWidth >= 760
                  ? 3
                  : constraints.maxWidth >= 510
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - ((columns - 1) * 12)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: width,
                        child: _ArcanaCard(
                          card: card,
                          onTap: () => _detail(card),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _reconcile(ArcanaData before) async {
    try {
      setState(() => _reconciling = true);
      final after = await ref.read(arcanaProvider.notifier).reconcile();
      if (!mounted) return;
      final changed = after.cards.where((next) {
        final old = before.cards.where((item) => item.id == next.id);
        return old.isNotEmpty && old.first.stage != next.stage;
      }).length;
      _notice(
        changed == 0
            ? 'Arcana reconciled. No new stages earned.'
            : 'Arcana reconciled. $changed card${changed == 1 ? '' : 's'} advanced.',
      );
    } on AppFailure catch (error) {
      _failure(context, error);
    } finally {
      if (mounted) setState(() => _reconciling = false);
    }
  }

  Future<void> _detail(ArcanaCard card) => showDialog<void>(
    context: context,
    builder: (dialogContext) => _ArcanaDetail(
      card: card,
      onPin: (slot) async {
        try {
          await ref.read(arcanaProvider.notifier).pin(slot, card.id);
          if (!mounted) return;
          Navigator.pop(dialogContext);
          _notice('Pinned ${card.name} in the ${_slotLabel(slot)} thread.');
        } on AppFailure catch (error) {
          if (mounted) _failure(context, error);
          rethrow;
        }
      },
    ),
  );

  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _Header extends StatelessWidget {
  const _Header({
    required this.ruleVersion,
    required this.reconciling,
    required this.onReconcile,
  });

  final int ruleVersion;
  final bool reconciling;
  final VoidCallback? onReconcile;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Arcana',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 6),
            Text(
              'A private record of enduring training evidence.',
              style: TextStyle(color: TransmutePalette.of(context).muted),
            ),
            const SizedBox(height: 4),
            Text('Rule set v$ruleVersion', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
      const SizedBox(width: 12),
      OutlinedButton.icon(
        onPressed: onReconcile,
        icon: reconciling
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sync),
        label: Text(reconciling ? 'Reconciling…' : 'Reconcile'),
      ),
    ],
  );
}

class _CollectionProgress extends StatelessWidget {
  const _CollectionProgress({required this.revealed, required this.total});

  final int revealed;
  final int total;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$revealed of $total revealed',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  revealed == total
                      ? 'Every card has a durable record.'
                      : '${total - revealed} milestone${total - revealed == 1 ? '' : 's'} remain ahead.',
                  style: TextStyle(color: TransmutePalette.of(context).muted),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 104,
            child: Semantics(
              label: '$revealed of $total cards revealed',
              value: '$revealed of $total',
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : revealed / total,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.supporting});
  final String title;
  final String supporting;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 2),
      Text(
        supporting,
        style: TextStyle(color: TransmutePalette.of(context).muted),
      ),
    ],
  );
}

class _PinnedThread extends StatelessWidget {
  const _PinnedThread({required this.data, required this.onOpen});
  final ArcanaData data;
  final ValueChanged<ArcanaCard> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 760 ? 3 : 1;
      final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: ArcanaSlot.values.map((slot) {
          final id = data.pins[slot];
          final match = data.cards.where((item) => item.id == id);
          final card = match.isEmpty ? null : match.first;
          return SizedBox(
            width: width,
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                title: Text(_slotLabel(slot)),
                subtitle: Text(
                  card == null ? 'No card pinned' : '${card.number} · ${card.name}',
                ),
                trailing: card == null
                    ? const Icon(Icons.add_circle_outline)
                    : const Icon(Icons.arrow_forward),
                onTap: card == null ? null : () => onOpen(card),
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}

class _ArcanaCard extends StatelessWidget {
  const _ArcanaCard({required this.card, required this.onTap});
  final ArcanaCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final revealed = card.stage != ArcanaStage.unrevealed;
    final palette = TransmutePalette.of(context);
    final milestone = card.nextMilestone;
    return Semantics(
      button: true,
      label: '${card.number} ${revealed ? card.name : 'unrevealed'}, ${_stageLabel(card.stage)}',
      child: InkWell(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 226,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        card.number,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      _StageChip(stage: card.stage),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    revealed ? card.name : 'UNREVEALED',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    revealed
                        ? card.focus
                        : milestone?.description ??
                              'Continue the work to discover this card.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted),
                  ),
                  if (milestone != null) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _milestoneProgress(milestone),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${milestone.current} of ${milestone.target} · next: ${_stageLabel(milestone.stage)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ] else if (revealed) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${card.stageEvidence.length} confirmed evidence record${card.stageEvidence.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.stage});
  final ArcanaStage stage;

  @override
  Widget build(BuildContext context) => Chip(
    visualDensity: VisualDensity.compact,
    label: Text(_stageLabel(stage)),
    side: BorderSide(color: _stageColor(context, stage)),
    labelStyle: TextStyle(
      color: _stageColor(context, stage),
      fontWeight: FontWeight.w700,
    ),
  );
}

class _ArcanaDetail extends StatefulWidget {
  const _ArcanaDetail({
    required this.card,
    required this.onPin,
  });
  final ArcanaCard card;
  final Future<void> Function(ArcanaSlot slot) onPin;

  @override
  State<_ArcanaDetail> createState() => _ArcanaDetailState();
}

class _ArcanaDetailState extends State<_ArcanaDetail> {
  bool _pinning = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final revealed = card.stage != ArcanaStage.unrevealed;
    final evidence = card.stageEvidence[card.stage];
    final milestone = card.nextMilestone;
    return AlertDialog(
      title: Text(
        revealed
            ? '${card.number} · ${card.name}'
            : '${card.number} · Unrevealed Arcana',
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StageChip(stage: card.stage),
            const SizedBox(height: 14),
            if (revealed) ...[
              Text(card.focus),
              const SizedBox(height: 14),
              Text('Evidence', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(evidence?.summary ?? 'No evidence summary was returned.'),
              if (evidence?.earnedAt != null) ...[
                const SizedBox(height: 4),
                Text('Earned ${_dateLabel(evidence!.earnedAt!)}'),
              ],
              if (evidence?.stats.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                ...evidence!.stats.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${_humanize(entry.key)}: ${entry.value}'),
                  ),
                ),
              ],
            ] else
              const Text(
                'This card remains hidden until its next milestone is confirmed.',
              ),
            if (milestone != null) ...[
              const SizedBox(height: 16),
              Text(
                'Next milestone',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(milestone.description),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _milestoneProgress(milestone),
              ),
              const SizedBox(height: 4),
              Text(
                '${milestone.current} of ${milestone.target} toward ${_stageLabel(milestone.stage)}',
              ),
            ] else if (revealed) ...[
              const SizedBox(height: 16),
              const Text('All stages are earned.'),
            ],
          ],
        ),
      ),
      actions: [
        if (revealed)
          PopupMenuButton<ArcanaSlot>(
            enabled: !_pinning,
            tooltip: 'Pin card',
            onSelected: (slot) async {
              setState(() => _pinning = true);
              try {
                await widget.onPin(slot);
              } finally {
                if (mounted) setState(() => _pinning = false);
              }
            },
            itemBuilder: (_) => [
              for (final slot in ArcanaSlot.values)
                PopupMenuItem(
                  value: slot,
                  child: Text('Pin to ${_slotLabel(slot)}'),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _pinning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.push_pin_outlined),
                  const SizedBox(width: 8),
                  Text(_pinning ? 'Pinning…' : 'Pin card'),
                ],
              ),
            ),
          ),
        TextButton(
          onPressed: _pinning ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ArcanaLoading extends StatelessWidget {
  const _ArcanaLoading();

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Text('Personal Arcana', style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 16),
      const _Skeleton(height: 96),
      const SizedBox(height: 24),
      const _Skeleton(height: 20, width: 150),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (_, constraints) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            constraints.maxWidth >= 510 ? 4 : 3,
            (_) => SizedBox(
              width: constraints.maxWidth >= 510
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth,
              child: const _Skeleton(height: 226),
            ),
          ),
        ),
      ),
    ],
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height, this.width});
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading Arcana',
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: TransmutePalette.of(context).divider.withValues(alpha: .45),
        border: Border.all(color: TransmutePalette.of(context).divider),
      ),
    ),
  );
}

class _ArcanaFailure extends StatelessWidget {
  const _ArcanaFailure({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arcana is unavailable',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter();

  @override
  Widget build(BuildContext context) => Card(
    child: const Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        'No cards have reached this stage yet. Reconcile when new record evidence is available.',
      ),
    ),
  );
}

String _stageLabel(ArcanaStage stage) => switch (stage) {
  ArcanaStage.unrevealed => 'Unrevealed',
  ArcanaStage.revealed => 'Revealed',
  ArcanaStage.refined => 'Refined',
  ArcanaStage.illuminated => 'Illuminated',
  ArcanaStage.mastered => 'Mastered',
};

String _slotLabel(ArcanaSlot slot) => switch (slot) {
  ArcanaSlot.past => 'Past',
  ArcanaSlot.present => 'Present',
  ArcanaSlot.becoming => 'Becoming',
};

Color _stageColor(BuildContext context, ArcanaStage stage) {
  final palette = TransmutePalette.of(context);
  return switch (stage) {
    ArcanaStage.unrevealed => palette.muted,
    ArcanaStage.revealed => palette.oxide,
    ArcanaStage.refined => palette.recovering,
    ArcanaStage.illuminated => palette.gold,
    ArcanaStage.mastered => palette.ready,
  };
}

String _humanize(String value) => value.replaceAllMapped(
  RegExp(r'([a-z])([A-Z])'),
  (match) => '${match.group(1)} ${match.group(2)}',
);

String _dateLabel(DateTime value) => '${value.month}/${value.day}/${value.year}';

double _milestoneProgress(ArcanaMilestone milestone) {
  if (milestone.target <= 0) return 0;
  return (milestone.current / milestone.target).clamp(0.0, 1.0).toDouble();
}

String _messageFor(Object error) {
  if (error is AppFailure) return error.message;
  if (kDebugMode) {
    return 'Debug detail: ${error.runtimeType}: $error';
  }
  return 'Your collection could not be loaded. Try again.';
}

void _failure(BuildContext context, AppFailure error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(error.message)));
}
