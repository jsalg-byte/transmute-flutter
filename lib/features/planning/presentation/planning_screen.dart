import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_shell.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppShell(
    title: 'Planning',
    child: ListView(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Planning',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => _block(context, ref),
              child: const Text('New block'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Set a bounded block, schedule its work, and use the review to decide the next adjustment.',
        ),
        const SizedBox(height: 16),
        const Text('Training blocks'),
        const SizedBox(height: 6),
        const _Blocks(),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Weekly reviews',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton(
              onPressed: () => _review(context, ref),
              child: const Text('Record review'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const _Reviews(),
      ],
    ),
  );
}

class _Blocks extends ConsumerWidget {
  const _Blocks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainingBlocksProvider);
    return state.when(
      data: (items) => items.isEmpty
          ? const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No training blocks yet.'),
              ),
            )
          : Column(
              children: items.map((block) => _BlockCard(block: block)).toList(),
            ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => _Retry(
        label: 'Unable to load blocks.',
        onRetry: () => ref.invalidate(trainingBlocksProvider),
      ),
    );
  }
}

class _BlockCard extends ConsumerWidget {
  const _BlockCard({required this.block});
  final TrainingBlock block;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  block.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PopupMenuButton<TrainingBlockStatus>(
                tooltip: 'Change block status',
                onSelected: (status) => _setBlockStatus(context, ref, status),
                itemBuilder: (_) => TrainingBlockStatus.values
                    .map(
                      (status) => PopupMenuItem(
                        value: status,
                        child: Text(status.name),
                      ),
                    )
                    .toList(),
                child: Chip(label: Text(block.status.name)),
              ),
            ],
          ),
          Text(
            '${_date(block.startDate)} – ${_date(block.endDate)} · ${block.targetSessionsPerWeek} sessions/week',
          ),
          if (block.note?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(block.note!),
          ],
          const Divider(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Scheduled work',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: () => _schedule(context, ref, block),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Schedule'),
              ),
            ],
          ),
          if (block.sessions.isEmpty)
            const Text('No sessions scheduled in this block yet.')
          else
            ...block.sessions.map(
              (session) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_date(session.scheduledFor)),
                subtitle: Text(
                  [
                    session.status.name,
                    if (session.isDeload) 'deload',
                    if (session.isRecoverySession) 'recovery',
                    if (session.note?.isNotEmpty == true) session.note!,
                  ].join(' · '),
                ),
                trailing: PopupMenuButton<ScheduledBlockSessionStatus>(
                  tooltip: 'Update scheduled session',
                  onSelected: (status) =>
                      _setSessionStatus(context, ref, session, status),
                  itemBuilder: (_) => ScheduledBlockSessionStatus.values
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text(status.name),
                        ),
                      )
                      .toList(),
                  child: const Icon(Icons.more_horiz),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Future<void> _setBlockStatus(
    BuildContext context,
    WidgetRef ref,
    TrainingBlockStatus status,
  ) async {
    try {
      await ref
          .read(planningRepositoryProvider)
          .updateBlock(block.id, status: status);
      ref.invalidate(trainingBlocksProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    }
  }

  Future<void> _setSessionStatus(
    BuildContext context,
    WidgetRef ref,
    ScheduledBlockSession session,
    ScheduledBlockSessionStatus status,
  ) async {
    try {
      await ref
          .read(planningRepositoryProvider)
          .updateScheduledSession(session.id, status: status);
      ref.invalidate(trainingBlocksProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    }
  }
}

class _Reviews extends ConsumerWidget {
  const _Reviews();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weeklyReviewsProvider);
    return state.when(
      data: (items) => items.isEmpty
          ? const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No weekly reviews recorded.'),
              ),
            )
          : Column(
              children: items
                  .map(
                    (review) => Card(
                      child: ListTile(
                        title: Text(
                          '${_date(review.weekStart)} – ${_date(review.weekEnd)}',
                        ),
                        subtitle: Text(
                          [
                            review.reflection,
                            if (review.adjustments?.isNotEmpty == true)
                              'Adjustment: ${review.adjustments}',
                          ].join('\n'),
                        ),
                        trailing: SizedBox(
                          width: 132,
                          child: Text(
                            review.decision,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => _Retry(
        label: 'Unable to load reviews.',
        onRetry: () => ref.invalidate(weeklyReviewsProvider),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.label, required this.onRetry});
  final String label;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

Future<void> _block(BuildContext context, WidgetRef ref) async {
  final name = TextEditingController();
  final start = TextEditingController(text: _apiDate(DateTime.now()));
  final end = TextEditingController(
    text: _apiDate(DateTime.now().add(const Duration(days: 28))),
  );
  final target = TextEditingController(text: '3');
  final note = TextEditingController();
  final result = await showDialog<TrainingBlock>(
    context: context,
    builder: (dialog) {
      String? error;
      return StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('New training block'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Block name'),
                ),
                TextField(
                  controller: start,
                  decoration: const InputDecoration(
                    labelText: 'Start date (YYYY-MM-DD)',
                  ),
                ),
                TextField(
                  controller: end,
                  decoration: const InputDecoration(
                    labelText: 'End date (YYYY-MM-DD)',
                  ),
                ),
                TextField(
                  controller: target,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sessions per week (1–7)',
                  ),
                ),
                TextField(
                  controller: note,
                  maxLength: 600,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Primary goal (optional)',
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final startDate = DateTime.tryParse(start.text);
                final endDate = DateTime.tryParse(end.text);
                final sessions = int.tryParse(target.text);
                if (name.text.trim().length < 2 ||
                    startDate == null ||
                    endDate == null ||
                    endDate.isBefore(startDate) ||
                    sessions == null ||
                    sessions < 1 ||
                    sessions > 7) {
                  setState(
                    () => error =
                        'Enter a name, valid inclusive dates, and 1–7 sessions per week.',
                  );
                  return;
                }
                Navigator.pop(
                  dialog,
                  TrainingBlock(
                    id: 'draft',
                    name: name.text.trim(),
                    startDate: startDate,
                    endDate: endDate,
                    targetSessionsPerWeek: sessions,
                    status: TrainingBlockStatus.active,
                    note: note.text.trim().isEmpty ? null : note.text.trim(),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      );
    },
  );
  name.dispose();
  start.dispose();
  end.dispose();
  target.dispose();
  note.dispose();
  if (result == null) return;
  try {
    await ref.read(planningRepositoryProvider).createBlock(result);
    ref.invalidate(trainingBlocksProvider);
  } on AppFailure catch (error) {
    _failure(context, error);
  }
}

Future<void> _schedule(
  BuildContext context,
  WidgetRef ref,
  TrainingBlock block,
) async {
  final scheduled = TextEditingController(text: _apiDate(block.startDate));
  final note = TextEditingController();
  var status = ScheduledBlockSessionStatus.planned;
  var isDeload = false;
  var isRecovery = false;
  final result = await showDialog<ScheduledBlockSession>(
    context: context,
    builder: (dialog) {
      String? error;
      return StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: Text('Schedule ${block.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: scheduled,
                  decoration: const InputDecoration(
                    labelText: 'Scheduled date (YYYY-MM-DD)',
                  ),
                ),
                DropdownButtonFormField(
                  initialValue: status,
                  items: ScheduledBlockSessionStatus.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => status = value!),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                CheckboxListTile(
                  value: isDeload,
                  onChanged: (value) =>
                      setState(() => isDeload = value ?? false),
                  title: const Text('Deload session'),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: isRecovery,
                  onChanged: (value) =>
                      setState(() => isRecovery = value ?? false),
                  title: const Text('Recovery session'),
                  contentPadding: EdgeInsets.zero,
                ),
                TextField(
                  controller: note,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final date = DateTime.tryParse(scheduled.text);
                if (date == null ||
                    date.isBefore(block.startDate) ||
                    date.isAfter(block.endDate)) {
                  setState(() => error = 'Use a date within this block.');
                  return;
                }
                Navigator.pop(
                  dialog,
                  ScheduledBlockSession(
                    id: 'draft',
                    scheduledFor: date,
                    status: status,
                    isDeload: isDeload,
                    isRecoverySession: isRecovery,
                    note: note.text.trim().isEmpty ? null : note.text.trim(),
                  ),
                );
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      );
    },
  );
  scheduled.dispose();
  note.dispose();
  if (result == null) return;
  try {
    await ref
        .read(planningRepositoryProvider)
        .scheduleSession(block.id, result);
    ref.invalidate(trainingBlocksProvider);
  } on AppFailure catch (error) {
    _failure(context, error);
  }
}

Future<void> _review(BuildContext context, WidgetRef ref) async {
  final start = TextEditingController(
    text: _apiDate(DateTime.now().subtract(const Duration(days: 6))),
  );
  final end = TextEditingController(text: _apiDate(DateTime.now()));
  final reflection = TextEditingController();
  final adjustments = TextEditingController();
  final decision = TextEditingController(
    text: 'Continue with the next planned action.',
  );
  final result = await showDialog<WeeklyReview>(
    context: context,
    builder: (dialog) {
      String? error;
      return StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Weekly review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: start,
                  decoration: const InputDecoration(
                    labelText: 'Week start (YYYY-MM-DD)',
                  ),
                ),
                TextField(
                  controller: end,
                  decoration: const InputDecoration(
                    labelText: 'Week end (YYYY-MM-DD)',
                  ),
                ),
                TextField(
                  controller: reflection,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1500,
                  decoration: const InputDecoration(labelText: 'What worked?'),
                ),
                TextField(
                  controller: adjustments,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1500,
                  decoration: const InputDecoration(
                    labelText: 'What needs adjustment? (optional)',
                  ),
                ),
                TextField(
                  controller: decision,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'Decision'),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final startDate = DateTime.tryParse(start.text);
                final endDate = DateTime.tryParse(end.text);
                if (startDate == null ||
                    endDate == null ||
                    endDate.isBefore(startDate) ||
                    reflection.text.trim().length < 2 ||
                    decision.text.trim().isEmpty) {
                  setState(
                    () => error =
                        'Enter inclusive dates, a reflection, and a decision.',
                  );
                  return;
                }
                Navigator.pop(
                  dialog,
                  WeeklyReview(
                    id: 'draft',
                    weekStart: startDate,
                    weekEnd: endDate,
                    reflection: reflection.text.trim(),
                    adjustments: adjustments.text.trim().isEmpty
                        ? null
                        : adjustments.text.trim(),
                    decision: decision.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    },
  );
  start.dispose();
  end.dispose();
  reflection.dispose();
  adjustments.dispose();
  decision.dispose();
  if (result == null) return;
  try {
    await ref.read(planningRepositoryProvider).createReview(result);
    ref.invalidate(weeklyReviewsProvider);
  } on AppFailure catch (error) {
    _failure(context, error);
  }
}

void _failure(BuildContext context, AppFailure error) {
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }
}

String _date(DateTime date) => '${date.month}/${date.day}/${date.year}';
String _apiDate(DateTime date) => date.toIso8601String().substring(0, 10);
