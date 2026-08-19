import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(arcanaProvider),
            child: const Text('Retry Arcana'),
          ),
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
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Arcana',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  Text(
                    'Rules v${data.ruleVersion} · your work leaves durable evidence.',
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _reconciling ? null : _reconcile,
              icon: const Icon(Icons.sync),
              label: Text(_reconciling ? 'Reconciling…' : 'Reconcile'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$revealed of ${data.cards.length} Arcana revealed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: LinearProgressIndicator(
                    value: data.cards.isEmpty
                        ? 0
                        : revealed / data.cards.length,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Current thread',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ArcanaSlot.values.map((slot) {
              final id = data.pins[slot];
              final card = data.cards.where((item) => item.id == id);
              return SizedBox(
                width: constraints.maxWidth >= 760
                    ? (constraints.maxWidth - 16) / 3
                    : constraints.maxWidth,
                child: Card(
                  child: ListTile(
                    title: Text(slot.name),
                    subtitle: Text(
                      card.isEmpty ? 'No card pinned' : card.first.name,
                    ),
                    onTap: card.isEmpty
                        ? null
                        : () => _detail(card.first, data),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            ...ArcanaStage.values.map(
              (stage) => ChoiceChip(
                label: Text(stage.name),
                selected: _filter == stage,
                onSelected: (_) => setState(() => _filter = stage),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                (constraints.maxWidth - ((columns - 1) * 10)) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: cards
                  .map(
                    (card) => SizedBox(
                      width: width,
                      child: _ArcanaCard(
                        card: card,
                        onTap: () => _detail(card, data),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _reconcile() async {
    try {
      setState(() => _reconciling = true);
      await ref.read(arcanaRepositoryProvider).reconcile();
      ref.invalidate(arcanaProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    } finally {
      if (mounted) setState(() => _reconciling = false);
    }
  }

  Future<void> _detail(ArcanaCard card, ArcanaData data) => showDialog<void>(
    context: context,
    builder: (dialog) => _ArcanaDetail(
      card: card,
      data: data,
      onPin: (slot) async {
        try {
          await ref.read(arcanaRepositoryProvider).pin(slot, card.id);
          ref.invalidate(arcanaProvider);
          if (dialog.mounted) Navigator.pop(dialog);
        } on AppFailure catch (error) {
          _failure(context, error);
        }
      },
    ),
  );
}

class _ArcanaCard extends StatelessWidget {
  const _ArcanaCard({required this.card, required this.onTap});
  final ArcanaCard card;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final revealed = card.stage != ArcanaStage.unrevealed;
    return Semantics(
      button: true,
      label: '${card.number} ${card.name}, ${card.stage.name}',
      child: InkWell(
        onTap: onTap,
        child: Card(
          child: SizedBox(
            height: 205,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.number,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    revealed ? card.name : 'UNREVEALED',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    revealed
                        ? card.stage.name
                        : card.nextMilestone?.description ??
                              'Continue the work to discover.',
                  ),
                  if (revealed)
                    Text(
                      '${card.stageEvidence.length} evidence record${card.stageEvidence.length == 1 ? '' : 's'}',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcanaDetail extends StatelessWidget {
  const _ArcanaDetail({
    required this.card,
    required this.data,
    required this.onPin,
  });
  final ArcanaCard card;
  final ArcanaData data;
  final ValueChanged<ArcanaSlot> onPin;
  @override
  Widget build(BuildContext context) {
    final evidence = card.stageEvidence[card.stage];
    return AlertDialog(
      title: Text('${card.number} · ${card.name}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              card.stage.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(card.focus),
            const SizedBox(height: 10),
            Text(
              evidence?.summary ??
                  'No qualifying evidence has been recorded yet.',
            ),
            if (evidence?.stats.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              ...evidence!.stats.entries.map(
                (entry) => Text('${entry.key}: ${entry.value}'),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              card.nextMilestone == null
                  ? 'All stages are earned.'
                  : 'Next: ${card.nextMilestone!.description}',
            ),
          ],
        ),
      ),
      actions: [
        if (card.stage != ArcanaStage.unrevealed)
          ...ArcanaSlot.values.map(
            (slot) => TextButton(
              onPressed: () => onPin(slot),
              child: Text('Pin ${slot.name}'),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

void _failure(BuildContext context, AppFailure error) {
  if (context.mounted)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
}
