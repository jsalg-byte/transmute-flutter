import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_shell.dart';

class FastingScreen extends ConsumerStatefulWidget {
  const FastingScreen({super.key});

  @override
  ConsumerState<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends ConsumerState<FastingScreen> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(fastingRecordProvider);
    return AppShell(
      title: 'Fasting',
      child: record.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(fastingRecordProvider),
            child: const Text('Retry fasting record'),
          ),
        ),
        data: (data) => ListView(
          children: [
            Text('Fasting', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            const Text(
              'Keep the timer, target, note, and completed record in the same private training log.',
            ),
            const SizedBox(height: 20),
            _ActiveFastCard(active: data.active, onStart: _start, onEnd: _end),
            const SizedBox(height: 20),
            Text(
              'Completed fasts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            if (data.logs.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No completed fasts yet.'),
                ),
              )
            else
              ...data.logs.map(
                (log) => Card(
                  child: ListTile(
                    title: Text(_duration(log.durationMinutes)),
                    subtitle: Text(
                      '${_dateTime(log.startedAt)} — ${_dateTime(log.endedAt)}'
                      '${log.targetMinutes == null ? '' : ' · Target ${_duration(log.targetMinutes!)}'}'
                      '${log.note?.isEmpty == false ? '\n${log.note}' : ''}',
                    ),
                    isThreeLine: log.note?.isNotEmpty == true,
                    trailing: IconButton(
                      tooltip: 'Remove fasting record',
                      onPressed: () => _remove(log),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    final target = TextEditingController(text: '16');
    final note = TextEditingController();
    final result = await showDialog<({int? targetMinutes, String? note})>(
      context: context,
      builder: (dialog) {
        String? error;
        return StatefulBuilder(
          builder: (_, setState) => AlertDialog(
            title: const Text('Start a fast'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: target,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Target hours (optional, up to 168)',
                  ),
                ),
                TextField(
                  controller: note,
                  maxLength: 240,
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final hours = target.text.trim().isEmpty
                      ? null
                      : double.tryParse(target.text);
                  if (hours != null && (hours <= 0 || hours > 168)) {
                    setState(
                      () => error =
                          'Target hours must be more than 0 and no more than 168.',
                    );
                    return;
                  }
                  Navigator.pop(dialog, (
                    targetMinutes: hours == null ? null : (hours * 60).round(),
                    note: note.text.trim().isEmpty ? null : note.text.trim(),
                  ));
                },
                child: const Text('Start'),
              ),
            ],
          ),
        );
      },
    );
    target.dispose();
    note.dispose();
    if (result == null) return;
    try {
      await ref
          .read(fastingRepositoryProvider)
          .start(targetMinutes: result.targetMinutes, note: result.note);
      ref.invalidate(fastingRecordProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    }
  }

  Future<void> _end() async {
    final note = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('End fast?'),
        content: TextField(
          controller: note,
          maxLength: 240,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Ending note (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Keep fasting'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialog, note.text.trim()),
            child: const Text('End fast'),
          ),
        ],
      ),
    );
    note.dispose();
    if (result == null) return;
    try {
      final discarded = await ref
          .read(fastingRepositoryProvider)
          .end(note: result.isEmpty ? null : result);
      ref.invalidate(fastingRecordProvider);
      if (mounted && discarded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fast ended before five minutes and was discarded.'),
          ),
        );
      }
    } on AppFailure catch (error) {
      _failure(context, error);
    }
  }

  Future<void> _remove(FastingLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Remove fasting record?'),
        content: Text(
          'Remove the ${_duration(log.durationMinutes)} fast from your record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(fastingRepositoryProvider).deleteLog(log.id);
      ref.invalidate(fastingRecordProvider);
    } on AppFailure catch (error) {
      _failure(context, error);
    }
  }
}

class _ActiveFastCard extends StatelessWidget {
  const _ActiveFastCard({
    required this.active,
    required this.onStart,
    required this.onEnd,
  });
  final ActiveFast? active;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    if (active == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No active fast',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Start a target when it is useful context for your day.',
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onStart,
                child: const Text('Start fast'),
              ),
            ],
          ),
        ),
      );
    }
    final elapsed = DateTime.now()
        .difference(active!.startedAt)
        .inMinutes
        .clamp(0, 7 * 24 * 60);
    final progress = active!.targetMinutes == null
        ? null
        : (elapsed / active!.targetMinutes!).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fast in progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              '${_duration(elapsed)} elapsed · started ${_dateTime(active!.startedAt)}',
            ),
            if (active!.targetMinutes != null) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Text(
                '${(progress! * 100).round()}% of ${_duration(active!.targetMinutes!)} target',
              ),
            ],
            if (active!.note?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(active!.note!),
            ],
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onEnd, child: const Text('End fast')),
          ],
        ),
      ),
    );
  }
}

void _failure(BuildContext context, AppFailure error) {
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }
}

String _duration(int minutes) => '${minutes ~/ 60}h ${minutes % 60}m';
String _dateTime(DateTime date) =>
    '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
