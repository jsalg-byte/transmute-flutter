import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_shell.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    return AppShell(
      title: 'Goals',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Goals',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _create(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New goal'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Set a measurable target, then record assessment evidence as your work changes.',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: goals.when(
              data: (items) => items.isEmpty
                  ? const Center(
                      child: Text(
                        'No active goals yet. Create a measurable next target.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _GoalCard(goal: items[i]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: ElevatedButton(
                  onPressed: () => ref.invalidate(goalsProvider),
                  child: const Text('Retry goals'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final goal = await showDialog<Goal>(
      context: context,
      builder: (_) => const _GoalDialog(),
    );
    if (goal == null) return;
    try {
      await ref.read(goalRepositoryProvider).createGoal(goal);
      ref.invalidate(goalsProvider);
    } on AppFailure catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});
  final Goal goal;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = goal.assessments.isEmpty
        ? goal.baseline
        : goal.assessments.first.value;
    final ratio = _progress(goal.baseline, goal.target, current);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                PopupMenuButton<GoalStatus>(
                  tooltip: 'Change goal status',
                  onSelected: (status) => _setStatus(context, ref, status),
                  itemBuilder: (_) => GoalStatus.values
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text(status.name),
                        ),
                      )
                      .toList(),
                  child: Chip(label: Text(goal.status.name)),
                ),
              ],
            ),
            Text(
              '${goal.category.name} · ${goal.baseline} → ${goal.target} ${goal.unit} by ${goal.targetDate.month}/${goal.targetDate.day}/${goal.targetDate.year}',
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: ratio),
            const SizedBox(height: 4),
            Text(
              '${current.toStringAsFixed(1)} ${goal.unit} · ${(ratio * 100).round()}% toward target',
            ),
            if (goal.assessments.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Assessment history',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...goal.assessments
                  .take(3)
                  .map(
                    (assessment) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${assessment.assessedAt.month}/${assessment.assessedAt.day} · ${assessment.value} ${goal.unit}'
                        '${assessment.decision?.isNotEmpty == true ? ' · ${assessment.decision}' : ''}'
                        '${assessment.reason.isNotEmpty ? '\n${assessment.reason}' : ''}',
                      ),
                    ),
                  ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _assess(context, ref),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Record assessment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assess(BuildContext context, WidgetRef ref) async {
    final value = TextEditingController();
    final note = TextEditingController();
    final decision = TextEditingController();
    final result =
        await showDialog<({double value, String note, String? decision})>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: Text('Assess ${goal.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Current ${goal.unit}',
                  ),
                ),
                TextField(
                  controller: note,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(labelText: 'What changed?'),
                ),
                TextField(
                  controller: decision,
                  maxLength: 500,
                  minLines: 1,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Decision (optional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final parsed = double.tryParse(value.text);
                  if (parsed != null && note.text.trim().length >= 2)
                    Navigator.pop(dialog, (
                      value: parsed,
                      note: note.text.trim(),
                      decision: decision.text.trim().isEmpty
                          ? null
                          : decision.text.trim(),
                    ));
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
    value.dispose();
    note.dispose();
    decision.dispose();
    if (result == null) return;
    try {
      await ref
          .read(goalRepositoryProvider)
          .assess(
            goal.id,
            result.value,
            result.note,
            decision: result.decision,
          );
      ref.invalidate(goalsProvider);
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Assessment recorded.')));
    } on AppFailure catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    GoalStatus status,
  ) async {
    try {
      await ref.read(goalRepositoryProvider).updateStatus(goal.id, status);
      ref.invalidate(goalsProvider);
    } on AppFailure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

double _progress(double baseline, double target, double current) {
  if (target == baseline) return 0;
  final raw = target > baseline
      ? (current - baseline) / (target - baseline)
      : (baseline - current) / (baseline - target);
  return raw.clamp(0, 1).toDouble();
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog();
  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final title = TextEditingController();
  final base = TextEditingController(text: '0');
  final target = TextEditingController(text: '1');
  final unit = TextEditingController(text: 'count');
  GoalCategory category = GoalCategory.strength;
  @override
  void dispose() {
    title.dispose();
    base.dispose();
    target.dispose();
    unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New measurable goal'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            maxLength: 160,
            decoration: const InputDecoration(labelText: 'Goal title'),
          ),
          DropdownButtonFormField(
            initialValue: category,
            items: GoalCategory.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.name)),
                )
                .toList(),
            onChanged: (value) => setState(() => category = value!),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          TextField(
            controller: base,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Baseline'),
          ),
          TextField(
            controller: target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Target'),
          ),
          TextField(
            controller: unit,
            maxLength: 32,
            decoration: const InputDecoration(labelText: 'Unit'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          final b = double.tryParse(base.text);
          final t = double.tryParse(target.text);
          if (title.text.trim().length >= 2 &&
              b != null &&
              t != null &&
              unit.text.trim().isNotEmpty)
            Navigator.pop(
              context,
              Goal(
                id: 'draft-${DateTime.now().microsecondsSinceEpoch}',
                title: title.text.trim(),
                category: category,
                baseline: b,
                target: t,
                unit: unit.text.trim(),
                targetDate: DateTime.now().add(const Duration(days: 90)),
                status: GoalStatus.active,
              ),
            );
        },
        child: const Text('Create'),
      ),
    ],
  );
}
