import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/recovery.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/recovery_anatomy.dart';
import '../../../shared/theme/transmute_palette.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(dailyOverviewProvider);
    final recent = ref.watch(recentRecordProvider);
    ref.watch(lastPerformedPlanDayProvider);
    return AppShell(
      title: 'Dashboard',
      child: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _RetryState(
          label: 'Unable to load the workbench.',
          onRetry: () => ref.invalidate(dailyOverviewProvider),
        ),
        data: (data) {
          final palette = TransmutePalette.of(context);
          final next = data.plans
              .where((plan) => plan.days.isNotEmpty)
              .map((plan) => (plan: plan, day: plan.days.first))
              .firstOrNull;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const _Eyebrow('THE WORKBENCH'),
              const SizedBox(height: 16),
              Text('Welcome back.', style: _DashboardText.welcome(palette)),
              const SizedBox(height: 18),
              _InkButton(
                label: 'Quick Add Workout',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _QuickAddDialog(),
                ),
              ),
              const SizedBox(height: 38),
              Divider(color: palette.ink, height: 1),
              const SizedBox(height: 28),
              _SessionPrescription(active: data.activeSession, next: next),
              const SizedBox(height: 20),
              Divider(color: palette.ink, height: 1),
              const SizedBox(height: 28),
              const _Eyebrow('RECOVERY'),
              const SizedBox(height: 22),
              _RecoveryPanel(groups: data.readiness),
              const SizedBox(height: 36),
              recent.when(
                loading: () => const _InlineLoading(),
                error: (_, __) => _DailyPrompt(
                  title: 'Recent record unavailable',
                  copy: 'Refresh the record to see your latest work.',
                  action: 'Retry',
                  onTap: () => ref.invalidate(recentRecordProvider),
                ),
                data: (items) => _RecentRecord(items: items),
              ),
              const SizedBox(height: 28),
              _WeekSummary(completedSessions: data.completedSessions),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _QuickAddDialog extends ConsumerStatefulWidget {
  const _QuickAddDialog();

  @override
  ConsumerState<_QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends ConsumerState<_QuickAddDialog> {
  final _search = TextEditingController();
  final _weight = TextEditingController();
  final _reps = TextEditingController();
  final _duration = TextEditingController();
  Exercise? _selected;
  bool _saving = false;

  @override
  void dispose() {
    _search.dispose();
    _weight.dispose();
    _reps.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exerciseSearchProvider(_search.text));
    final unit =
        ref.watch(authControllerProvider).user?.weightUnit ?? WeightUnit.lb;
    final cardio = _selected?.category == 'cardio';
    return AlertDialog(
      title: const Text('Quick Add Workout'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  labelText: 'Choose an exercise',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              exercises.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Exercise library unavailable.'),
                data: (items) => SizedBox(
                  height: 180,
                  child: ListView.builder(
                    itemCount: items.take(30).length,
                    itemBuilder: (_, index) {
                      final exercise = items[index];
                      return ListTile(
                        dense: true,
                        title: Text(exercise.name),
                        subtitle: Text(
                          exercise.category == 'cardio'
                              ? 'Duration-based'
                              : 'Weight × reps',
                        ),
                        selected: _selected?.id == exercise.id,
                        onTap: () => setState(() => _selected = exercise),
                      );
                    },
                  ),
                ),
              ),
              if (_selected != null) ...[
                const SizedBox(height: 12),
                Text(
                  _selected!.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (cardio)
                  TextField(
                    controller: _duration,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                    ),
                  )
                else ...[
                  TextField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Weight (${unit.name})',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reps,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _save(unit, cardio),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Workout'),
        ),
      ],
    );
  }

  Future<void> _save(WeightUnit unit, bool cardio) async {
    if (_selected == null) return;
    final weight = double.tryParse(_weight.text.trim());
    final reps = int.tryParse(_reps.text.trim());
    final minutes = int.tryParse(_duration.text.trim());
    if (cardio
        ? minutes == null || minutes <= 0
        : reps == null || reps <= 0 || weight == null || weight < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid workout values.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(quickAddRepositoryProvider)
          .create(
            exerciseId: _selected!.id,
            weightUnit: unit,
            weightKg: cardio ? null : toKg(weight!, unit),
            reps: cardio ? null : reps,
            durationSeconds: cardio ? minutes! * 60 : null,
          );
      ref.invalidate(historyProvider);
      ref.invalidate(recentRecordProvider);
      if (mounted) Navigator.pop(context);
    } on AppFailure catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _SessionPrescription extends ConsumerWidget {
  const _SessionPrescription({required this.active, required this.next});
  final WorkoutSession? active;
  final ({WorkoutPlan plan, WorkoutPlanDay day})? next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TransmutePalette.of(context);
    final label = active != null ? 'ACTIVE WORK' : 'YOUR NEXT SESSION';
    final title = active != null
        ? '${active!.planName} — ${active!.planDayName}'
        : next == null
        ? 'Build the work before you perform it.'
        : '${next!.plan.name} — ${next!.day.name}';
    final meta = active != null
        ? '${active!.workingSetCount} working sets logged'
        : next == null
        ? 'A plan gives your next session a place to begin.'
        : '${next!.day.exercises.length} ${next!.day.exercises.length == 1 ? 'exercise' : 'exercises'} ready to log';
    final movements = active == null && next != null
        ? next!.day.exercises
              .take(3)
              .map((item) => item.exercise.name)
              .join(' · ')
        : null;
    final action = active != null
        ? 'Continue session'
        : next == null
        ? 'Build your first plan'
        : 'Begin session';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(label),
        const SizedBox(height: 12),
        Text(title, style: _DashboardText.sessionTitle(palette)),
        const SizedBox(height: 10),
        Text(meta, style: _DashboardText.body(palette)),
        if (movements != null && movements.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(movements, style: _DashboardText.body(palette)),
        ],
        const SizedBox(height: 26),
        _InkButton(
          label: action,
          onPressed: () {
            if (active != null) {
              context.go('/session');
            } else if (next == null) {
              context.go('/plans');
            } else {
              _chooseDayAndStart(context, ref);
            }
          },
        ),
      ],
    );
  }

  Future<void> _chooseDayAndStart(BuildContext context, WidgetRef ref) async {
    final plan = next?.plan;
    if (plan == null) return;
    final selected = await showModalBottomSheet<_TrainingDayChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _TrainingDayFlyover(
        plan: plan,
        onSelect: (choice) => Navigator.of(sheetContext).pop(choice),
        onBrowsePlans: () {
          Navigator.of(sheetContext).pop();
          context.go('/plans');
        },
      ),
    );
    if (selected == null || !context.mounted) return;

    try {
      await ref
          .read(activeSessionProvider.notifier)
          .start(selected.plan.id, selected.day.id);
      if (context.mounted) context.go('/session');
    } on AppFailure catch (error) {
      if (!context.mounted) return;
      if (error.code == 'active_session_exists') {
        await ref.read(activeSessionProvider.notifier).refresh();
        if (context.mounted) context.go('/session');
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _TrainingDayChoice {
  const _TrainingDayChoice({
    required this.plan,
    required this.day,
    this.lastPerformedAt,
    this.historyStatus,
  });
  final WorkoutPlan plan;
  final WorkoutPlanDay day;
  final DateTime? lastPerformedAt;
  final String? historyStatus;
}

class _TrainingDayFlyover extends ConsumerWidget {
  const _TrainingDayFlyover({
    required this.plan,
    required this.onSelect,
    required this.onBrowsePlans,
  });

  final WorkoutPlan plan;
  final ValueChanged<_TrainingDayChoice> onSelect;
  final VoidCallback onBrowsePlans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TransmutePalette.of(context);
    final history = ref.watch(lastPerformedPlanDayProvider);
    final performedDays = history.asData?.value;
    final historyStatus = switch (history) {
      AsyncLoading() => 'Checking history…',
      AsyncError() => 'Training history unavailable',
      _ => null,
    };
    final choices = [
      for (final day in plan.days)
        _TrainingDayChoice(
          plan: plan,
          day: day,
          lastPerformedAt:
              performedDays?[planDayHistoryKey(plan.name, day.name)],
          historyStatus: historyStatus,
        ),
    ];
    return SafeArea(
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 600 ? 3 : 2;
                final tileWidth =
                    (constraints.maxWidth - (columns - 1) * 10) / columns;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'What are you training today?',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close day picker',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a day to start logging.',
                      style: TextStyle(color: palette.muted),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final choice in choices)
                          SizedBox(
                            width: tileWidth,
                            height: 70,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onPressed: () => onSelect(choice),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    choice.day.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _lastPerformedLabel(
                                      choice.lastPerformedAt,
                                      DateTime.now(),
                                      unavailableLabel: choice.historyStatus,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TextButton(
                          onPressed: onBrowsePlans,
                          child: const Text('Browse plans'),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

String _lastPerformedLabel(
  DateTime? completedAt,
  DateTime now, {
  String? unavailableLabel,
}) {
  if (completedAt == null) return unavailableLabel ?? 'Not performed yet';
  final date = completedAt.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final completedDay = DateTime(date.year, date.month, date.day);
  final daysAgo = today.difference(completedDay).inDays;
  if (daysAgo <= 0) return 'Last performed today';
  if (daysAgo < 7) {
    return 'Last performed $daysAgo ${daysAgo == 1 ? 'day' : 'days'} ago';
  }
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return 'Last performed ${monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

class _DailyPrompt extends StatelessWidget {
  const _DailyPrompt({
    required this.title,
    required this.copy,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String copy;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: palette.divider),
        color: palette.raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('DAILY TRANSMUTATION'),
          const SizedBox(height: 8),
          Text(title, style: _DashboardText.dailyTitle(palette)),
          const SizedBox(height: 6),
          Text(copy, style: _DashboardText.body(palette)),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(foregroundColor: palette.oxide),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _RecoveryPanel extends StatelessWidget {
  const _RecoveryPanel({required this.groups});
  final List<RecoveryGroup> groups;

  @override
  Widget build(BuildContext context) {
    final needsRest = groups
        .where((group) => group.stage == RecoveryStage.needsRest)
        .toList();
    final recovering = groups
        .where((group) => group.stage == RecoveryStage.recovering)
        .toList();
    final ready = groups
        .where((group) => group.stage == RecoveryStage.ready)
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final details = _RecoveryDetails(
          needsRest: needsRest,
          recovering: recovering,
          ready: ready,
        );
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              RecoveryAnatomy(groups: groups),
              const SizedBox(height: 22),
              details,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(child: RecoveryAnatomy(groups: groups)),
            ),
            const SizedBox(width: 34),
            Expanded(child: details),
          ],
        );
      },
    );
  }
}

class _RecoveryDetails extends StatelessWidget {
  const _RecoveryDetails({
    required this.needsRest,
    required this.recovering,
    required this.ready,
  });
  final List<RecoveryGroup> needsRest;
  final List<RecoveryGroup> recovering;
  final List<RecoveryGroup> ready;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (needsRest.isNotEmpty)
          _ReadinessSection(
            label: 'NEEDS REST',
            color: palette.rest,
            groups: needsRest,
            timing: 'Under 24h',
          ),
        if (recovering.isNotEmpty) ...[
          const SizedBox(height: 20),
          _ReadinessSection(
            label: 'RECOVERING',
            color: palette.recovering,
            groups: recovering,
            timing: '24–48h',
          ),
        ],
        const SizedBox(height: 20),
        _ReadinessSection(
          label: 'READY TO TRAIN',
          color: palette.ready,
          groups: ready,
          timing: '48h+',
        ),
      ],
    );
  }
}

class _ReadinessSection extends StatelessWidget {
  const _ReadinessSection({
    required this.label,
    required this.color,
    required this.groups,
    required this.timing,
  });
  final String label;
  final Color color;
  final List<RecoveryGroup> groups;
  final String timing;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(label, color: color),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          Text('No groups in this state.', style: _DashboardText.body(palette))
        else
          for (final group in groups)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: _DashboardText.group(palette),
                    ),
                  ),
                  Text(
                    group.stage == RecoveryStage.recovering &&
                            group.hoursRemaining > 0
                        ? 'Ready in ~${group.hoursRemaining}h'
                        : timing,
                    style: _DashboardText.timing(
                      palette,
                    ).copyWith(color: color),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _RecentRecord extends StatelessWidget {
  const _RecentRecord({required this.items});
  final List<RecentRecordItem> items;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('RECENT RECORD'),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(
            'No recent record entries yet.',
            style: _DashboardText.body(palette),
          )
        else
          for (final item in items)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go(item.route),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: palette.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: _DashboardText.group(palette),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.meta,
                              style: _DashboardText.body(palette),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _shortDate(item.at),
                        style: _DashboardText.timing(palette),
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

class _WeekSummary extends StatelessWidget {
  const _WeekSummary({required this.completedSessions});
  final List<WorkoutSession> completedSessions;

  @override
  Widget build(BuildContext context) {
    final since = DateTime.now().subtract(const Duration(days: 7));
    final total = completedSessions
        .where(
          (session) =>
              session.completedAt != null &&
              session.completedAt!.isAfter(since),
        )
        .length;
    return Text(
      'THIS WEEK  ·  $total ${total == 1 ? 'SESSION' : 'SESSIONS'} COMPLETED',
      style: _DashboardText.timing(TransmutePalette.of(context)),
    );
  }
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.label, required this.onRetry});
  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: _DailyPrompt(
      title: label,
      copy: 'Try refreshing the record.',
      action: 'Retry',
      onTap: onRetry,
    ),
  );
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();
  @override
  Widget build(BuildContext context) =>
      const LinearProgressIndicator(minHeight: 2);
}

class _InkButton extends StatelessWidget {
  const _InkButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: TransmutePalette.of(context).ink,
      foregroundColor: TransmutePalette.of(context).raised,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
    child: Text(label),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label, {this.color});
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return Text(
      label,
      style: TextStyle(
        color: color ?? palette.steel,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _DashboardText {
  static TextStyle welcome(TransmutePalette palette) => TextStyle(
    color: palette.ink,
    fontSize: 48,
    height: 1,
    fontWeight: FontWeight.w900,
    letterSpacing: -2.2,
  );
  static TextStyle sessionTitle(TransmutePalette palette) => TextStyle(
    color: palette.ink,
    fontSize: 30,
    height: 1.08,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.25,
  );
  static TextStyle dailyTitle(TransmutePalette palette) => TextStyle(
    color: palette.ink,
    fontSize: 22,
    height: 1.15,
    fontWeight: FontWeight.w800,
  );
  static TextStyle group(TransmutePalette palette) =>
      TextStyle(color: palette.ink, fontSize: 19, fontWeight: FontWeight.w800);
  static TextStyle body(TransmutePalette palette) =>
      TextStyle(color: palette.muted, fontSize: 16, height: 1.45);
  static TextStyle timing(TransmutePalette palette) => TextStyle(
    color: palette.steel,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: .6,
  );
}

String _shortDate(DateTime value) =>
    '${value.toLocal().month}/${value.toLocal().day}';

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
