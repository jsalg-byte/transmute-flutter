import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_shell.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

enum _HistoryRange { sevenDays, thirtyDays, all }

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryRange _range = _HistoryRange.thirtyDays;
  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final unit =
        ref.watch(authControllerProvider).user?.weightUnit ?? WeightUnit.kg;
    return AppShell(
      title: 'Workout history',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Workout history',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: history.when(
              data: (items) {
                if (items.isEmpty)
                  return Center(
                    child: TextButton(
                      onPressed: () => ref.invalidate(historyProvider),
                      child: const Text('No completed workouts yet. Retry'),
                    ),
                  );
                final displayed = _filter(items);
                final sessions = displayed.length;
                final sets = displayed.fold<int>(
                  0,
                  (total, item) => total + item.workingSetCount,
                );
                final volume = displayed.fold<double>(
                  0,
                  (total, item) => total + item.totalVolumeKg,
                );
                final grouped = <String, List<CompletedSessionSummary>>{};
                for (final item in displayed) {
                  grouped
                      .putIfAbsent(_date(item.completedAt), () => [])
                      .add(item);
                }
                return ListView(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _HistoryRange.values
                          .map(
                            (range) => ChoiceChip(
                              label: Text(switch (range) {
                                _HistoryRange.sevenDays => '7 days',
                                _HistoryRange.thirtyDays => '30 days',
                                _HistoryRange.all => 'All time',
                              }),
                              selected: range == _range,
                              onSelected: (_) => setState(() => _range = range),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    _HistorySummary(
                      sessions: sessions,
                      sets: sets,
                      volume: volume,
                      unit: unit,
                    ),
                    const SizedBox(height: 16),
                    if (displayed.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text('No completed workouts in this range'),
                          subtitle: Text(
                            'Try a longer period to inspect earlier session evidence.',
                          ),
                        ),
                      ),
                    ...grouped.entries.expand(
                      (entry) => [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 6),
                          child: Text(
                            entry.key.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        ...entry.value.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _HistoryItem(item: item, unit: unit),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: ElevatedButton(
                  onPressed: () => ref.invalidate(historyProvider),
                  child: const Text('Retry'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<CompletedSessionSummary> _filter(List<CompletedSessionSummary> items) {
    if (_range == _HistoryRange.all) return items;
    final days = _range == _HistoryRange.sevenDays ? 7 : 30;
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: days - 1));
    return items.where((item) => item.completedAt.isAfter(cutoff)).toList();
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.sessions,
    required this.sets,
    required this.volume,
    required this.unit,
  });
  final int sessions;
  final int sets;
  final double volume;
  final WeightUnit unit;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 720 ? 3 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            [
                  ('Sessions', '$sessions'),
                  ('Working sets', '$sets'),
                  ('Total volume', displayWeight(volume, unit)),
                ]
                .map(
                  (stat) => SizedBox(
                    width: width,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stat.$1),
                            const SizedBox(height: 4),
                            Text(
                              stat.$2,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      );
    },
  );
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.item, required this.unit});
  final CompletedSessionSummary item;
  final WeightUnit unit;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(item.planName, style: Theme.of(context).textTheme.titleLarge),
      subtitle: Text(
        '${_date(item.completedAt)} · ${item.durationSeconds ~/ 60} min · ${item.workingSetCount} working sets\n${displayWeight(item.totalVolumeKg, unit)} total volume',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/history/${item.id}'),
    ),
  );
}

class CompletedSessionScreen extends ConsumerWidget {
  const CompletedSessionScreen({super.key, required this.sessionId});
  final String sessionId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(sessionDetailProvider(sessionId));
    return AppShell(
      title: 'Completed workout',
      child: data.when(
        data: (session) => _CompletedDetail(session: session),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(sessionDetailProvider(sessionId)),
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }
}

class _CompletedDetail extends ConsumerWidget {
  const _CompletedDetail({required this.session});
  final WorkoutSession session;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit =
        ref.watch(authControllerProvider).user?.weightUnit ?? WeightUnit.kg;
    return ListView(
      children: [
        TextButton.icon(
          onPressed: () => context.go('/history'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Workout history'),
        ),
        Text(
          session.planName,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Completed ${_date(session.completedAt!)} · ${session.duration.inMinutes} min · ${session.workingSetCount} working sets',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${displayWeight(session.totalVolumeKg, unit)} total volume',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/history/${session.id}/share'),
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('Workout record'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: _workoutJson(session)),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Workout JSON copied.')),
                    );
                  }
                },
                icon: const Icon(Icons.content_copy_outlined),
                label: const Text('Copy workout JSON'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...session.exercises.map(
          (exercise) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...exercise.sets.map(
                    (set) => Text(
                      'Set ${set.setOrder}: ${displayWeight(set.weightKg, unit)} × ${set.reps}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WorkoutShareScreen extends ConsumerWidget {
  const WorkoutShareScreen({super.key, required this.sessionId});
  final String sessionId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(sessionDetailProvider(sessionId));
    final unit =
        ref.watch(authControllerProvider).user?.weightUnit ?? WeightUnit.kg;
    return AppShell(
      title: 'Workout record',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(sessionDetailProvider(sessionId)),
            child: const Text('Retry workout record'),
          ),
        ),
        data: (session) => _WorkoutRecord(session: session, unit: unit),
      ),
    );
  }
}

class _WorkoutRecord extends StatelessWidget {
  const _WorkoutRecord({required this.session, required this.unit});
  final WorkoutSession session;
  final WeightUnit unit;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      TextButton.icon(
        onPressed: () => context.go('/history/${session.id}'),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back to workout'),
      ),
      const Text(
        'TRANSMUTE · WORKOUT RECORD',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
      const SizedBox(height: 12),
      Text(session.planName, style: Theme.of(context).textTheme.displaySmall),
      Text('${session.planDayName} · ${_date(session.startedAt)}'),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 720 ? 3 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
          final stats = [
            ('Movements', '${session.exercises.length}'),
            ('Working sets', '${session.workingSetCount}'),
            ('Total volume', displayWeight(session.totalVolumeKg, unit)),
          ];
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stats
                .map(
                  (stat) => SizedBox(
                    width: width,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stat.$1),
                            const SizedBox(height: 4),
                            Text(
                              stat.$2,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
      const SizedBox(height: 16),
      const Text(
        'MOVEMENTS',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
      const SizedBox(height: 8),
      ...session.exercises.asMap().entries.map(
        (entry) => Card(
          child: ListTile(
            leading: Text('${entry.key + 1}'.padLeft(2, '0')),
            title: Text(entry.value.name),
            subtitle: Text(_setSummary(entry.value, unit)),
          ),
        ),
      ),
    ],
  );
}

String _setSummary(SessionExercise exercise, WeightUnit unit) {
  if (exercise.sets.isEmpty) return 'No sets recorded';
  return exercise.sets
      .map(
        (set) =>
            '${set.reps} reps @ ${displayWeight(set.weightKg, unit)}${set.isWarmup ? ' warm-up' : ''}',
      )
      .join(' · ');
}

String _workoutJson(WorkoutSession session) =>
    const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'workout': {
        'routine': session.planName,
        'day': session.planDayName,
        'startedAt': session.startedAt.toUtc().toIso8601String(),
        'endedAt': session.completedAt?.toUtc().toIso8601String(),
        'exercises': session.exercises
            .map(
              (exercise) => {
                'name': exercise.name,
                'muscleGroup': exercise.muscleGroup,
                'sets': exercise.sets
                    .map(
                      (set) => {
                        'order': set.setOrder,
                        'reps': set.reps,
                        'weightKg': set.weightKg,
                        'isWarmup': set.isWarmup,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      },
    });

String _date(DateTime date) =>
    '${date.toLocal().month}/${date.toLocal().day}/${date.toLocal().year}';
