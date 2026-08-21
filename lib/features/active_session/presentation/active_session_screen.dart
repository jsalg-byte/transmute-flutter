import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/theme/transmute_palette.dart';
import '../../../shared/widgets/app_shell.dart';

class ActiveSessionScreen extends ConsumerWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    return AppShell(
      title: 'Workout',
      child: session.when(
        data: (value) {
          if (value != null) return _SessionBody(session: value);
          return Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No active workout'),
                    const SizedBox(height: 8),
                    const Text('Open a plan to start one workout.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.go('/plans'),
                      child: const Text('Browse plans'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: ElevatedButton(
            onPressed: () => ref.read(activeSessionProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }
}

class _SessionBody extends ConsumerStatefulWidget {
  const _SessionBody({required this.session});
  final WorkoutSession session;

  @override
  ConsumerState<_SessionBody> createState() => _SessionBodyState();
}

class _SessionBodyState extends ConsumerState<_SessionBody> {
  var _movementIndex = 0;

  @override
  void didUpdateWidget(covariant _SessionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_movementIndex >= widget.session.exercises.length) {
      _movementIndex = widget.session.exercises.isEmpty
          ? 0
          : widget.session.exercises.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final pendingCount = session.exercises
        .expand((exercise) => exercise.sets)
        .where((set) => set.pending)
        .length;
    final selected = session.exercises.isEmpty
        ? null
        : session.exercises[_movementIndex];
    final sidebar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () => _finish(context, ref, session),
          child: const Text('Finish workout'),
        ),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: const Color(0xffA33B36)),
          onPressed: () => _discard(context, ref, session),
          child: const Text('Discard workout'),
        ),
      ],
    );
    final movement = selected == null
        ? _EmptyMovementState(
            onAdd: () => _chooseExercise(context, ref, session),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MovementStepper(
                exercise: selected,
                currentIndex: _movementIndex,
                movementCount: session.exercises.length,
                onPrevious: _movementIndex == 0
                    ? null
                    : () => setState(() => _movementIndex -= 1),
                onNext: _movementIndex == session.exercises.length - 1
                    ? null
                    : () => setState(() => _movementIndex += 1),
                onAdd: () => _chooseExercise(context, ref, session),
                onRemove: selected.sets.isEmpty
                    ? () => _removeExercise(context, selected)
                    : null,
              ),
              const SizedBox(height: 8),
              _ExerciseCard(exercise: selected, showIdentity: false),
            ],
          );
    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.planName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Started ${_time(session.startedAt)} · ${session.workingSetCount} working sets',
              ),
              const SizedBox(height: 8),
              if (box.maxWidth >= 1024)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: SingleChildScrollView(child: movement)),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 300,
                        child: SingleChildScrollView(child: sidebar),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [movement, const SizedBox(height: 16), sidebar],
                  ),
                ),
            ],
          ),
          if (pendingCount > 0)
            Positioned(
              top: 0,
              right: 0,
              child: _PendingSyncIndicator(pendingCount: pendingCount),
            ),
          Positioned(right: 0, bottom: 16, child: _RestTimer(session: session)),
        ],
      ),
    );
  }

  Future<void> _chooseExercise(
    BuildContext context,
    WidgetRef ref,
    WorkoutSession session,
  ) async {
    final result = await showDialog<_SessionExerciseSelection>(
      context: context,
      builder: (_) => const _ExerciseDialog(),
    );
    if (result == null) return;
    try {
      if (result.exercise != null) {
        await ref
            .read(activeSessionProvider.notifier)
            .addExercise(result.exercise!.id);
      } else {
        await ref
            .read(activeSessionProvider.notifier)
            .importCalistreeExercise(result.catalog!.slug);
      }
      final updated = ref.read(activeSessionProvider).value;
      if (updated != null && mounted) {
        setState(() => _movementIndex = updated.exercises.length - 1);
      }
    } on AppFailure catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _finish(
    BuildContext context,
    WidgetRef ref,
    WorkoutSession session,
  ) async {
    if (session.workingSetCount == 0) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Finish empty workout?'),
          content: const Text('There are no logged working sets.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Keep logging'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Finish workout'),
            ),
          ],
        ),
      );
      if (yes != true) return;
    }
    try {
      final done = await ref.read(activeSessionProvider.notifier).complete();
      if (context.mounted) context.go('/history/${done.id}');
    } on AppFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _discard(
    BuildContext context,
    WidgetRef ref,
    WorkoutSession session,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Discard workout?'),
        content: const Text(
          'Logged work will be removed and cannot be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Keep workout'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffA33B36),
            ),
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Discard workout'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await ref.read(activeSessionProvider.notifier).discard();
      if (context.mounted) context.go('/plans');
    }
  }

  Future<void> _removeExercise(
    BuildContext context,
    SessionExercise exercise,
  ) async {
    try {
      await ref
          .read(activeSessionProvider.notifier)
          .removeExercise(exercise.id);
    } on AppFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _EmptyMovementState extends StatelessWidget {
  const _EmptyMovementState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('This workout has no movements yet.'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add movement'),
          ),
        ],
      ),
    ),
  );
}

class _MovementStepper extends StatelessWidget {
  const _MovementStepper({
    required this.exercise,
    required this.currentIndex,
    required this.movementCount,
    required this.onPrevious,
    required this.onNext,
    required this.onAdd,
    required this.onRemove,
  });

  final SessionExercise exercise;
  final int currentIndex;
  final int movementCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous movement',
              onPressed: onPrevious,
              visualDensity: compact ? VisualDensity.compact : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                exercise.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: compact ? 24 : null,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onRemove != null)
              IconButton(
                tooltip: 'Remove movement',
                onPressed: onRemove,
                visualDensity: compact ? VisualDensity.compact : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
            IconButton(
              tooltip: 'Next movement',
              onPressed: onNext,
              visualDensity: compact ? VisualDensity.compact : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 12),
        Row(
          children: [
            for (var index = 0; index < movementCount; index += 1) ...[
              if (index > 0) SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Container(
                  height: compact ? 4 : 6,
                  color: index == currentIndex
                      ? accent
                      : Theme.of(context).dividerColor,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: compact ? 4 : 12),
        TextButton.icon(
          style: compact
              ? TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                )
              : null,
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add movement'),
        ),
      ],
    );
  }
}

class _ExerciseCard extends ConsumerStatefulWidget {
  const _ExerciseCard({required this.exercise, this.showIdentity = true});
  final SessionExercise exercise;
  final bool showIdentity;
  @override
  ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
  final _drafts = <_SetDraft>[];
  var _nextDraftOrder = 0;
  String? _error;
  bool _saving = false;
  bool _demoExpanded = false;

  @override
  void initState() {
    super.initState();
    _nextDraftOrder = _workingSetCount(widget.exercise);
    _addDrafts(_initialDraftCount(widget.exercise));
  }

  @override
  void didUpdateWidget(covariant _ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _disposeDrafts();
      _nextDraftOrder = _workingSetCount(widget.exercise);
      _addDrafts(_initialDraftCount(widget.exercise));
    }
  }

  @override
  void dispose() {
    _disposeDrafts();
    super.dispose();
  }

  int _initialDraftCount(SessionExercise exercise) {
    final remaining = exercise.targetSets - _workingSetCount(exercise);
    return remaining > 0 ? remaining : 1;
  }

  int _workingSetCount(SessionExercise exercise) =>
      exercise.sets.where((set) => !set.isWarmup).length;

  void _addDrafts(int count) {
    for (var index = 0; index < count; index += 1) {
      _drafts.add(_SetDraft(_nextDraftOrder++));
    }
  }

  void _disposeDrafts() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    _drafts.clear();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final unit =
        ref.watch(authControllerProvider).user?.weightUnit ?? WeightUnit.kg;
    final exercise = widget.exercise;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showIdentity)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${exercise.muscleGroup ?? 'Movement'} · target ${exercise.targetSets} × ${exercise.targetReps}',
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: exercise.sets.isEmpty
                        ? 'Remove exercise'
                        : 'Remove unavailable while sets exist',
                    onPressed: exercise.sets.isEmpty
                        ? () async {
                            try {
                              await ref
                                  .read(activeSessionProvider.notifier)
                                  .removeExercise(exercise.id);
                            } on AppFailure catch (error) {
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.message)),
                                );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              )
            else
              Center(
                child: Text(
                  '${exercise.muscleGroup ?? 'Movement'} · target ${exercise.targetSets} × ${exercise.targetReps}',
                  maxLines: compact ? 2 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                  style: compact
                      ? const TextStyle(fontSize: 15, height: 1.2)
                      : null,
                ),
              ),
            if (exercise.demoUrl != null) ...[
              SizedBox(height: compact ? 4 : 8),
              _SessionExerciseDemo(
                name: exercise.name,
                url: exercise.demoUrl!,
                sourceName: exercise.demoSourceName,
                expanded: _demoExpanded,
                onToggle: () => setState(() => _demoExpanded = !_demoExpanded),
              ),
            ],
            SizedBox(height: compact ? 10 : 16),
            Text(
              'SETS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 4 : 8),
            _SetLedgerHeader(unit: unit),
            ...exercise.sets.map(
              (set) => ListTile(
                dense: compact,
                visualDensity: compact
                    ? const VisualDensity(vertical: -3)
                    : null,
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: compact ? 12 : 14,
                  child: Text('${set.setOrder}'),
                ),
                title: Text(
                  '${displayWeight(set.weightKg, unit)} × ${set.reps}',
                  style: compact ? const TextStyle(fontSize: 17) : null,
                ),
                subtitle: set.isWarmup ? const Text('Warm-up set') : null,
                trailing: set.pending
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, color: Color(0xff3E745C)),
                          IconButton(
                            tooltip: 'Edit set',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _edit(set, unit),
                          ),
                        ],
                      ),
              ),
            ),
            for (var index = 0; index < _drafts.length; index += 1)
              _SetDraftRow(
                key: ValueKey(_drafts[index]),
                number: _drafts[index].order + 1,
                draft: _drafts[index],
                unit: unit,
                previous: _previousFor(_drafts[index].order),
                saving: _saving,
                onLog: () => _add(index),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xffA33B36))),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: compact
                    ? TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    : null,
                onPressed: _saving
                    ? null
                    : () => setState(
                        () => _drafts.add(_SetDraft(_nextDraftOrder++)),
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Add set'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(int index) async {
    final draft = _drafts[index];
    final previous = _previousFor(draft.order);
    final weight = draft.weight.text.trim().isEmpty
        ? (previous == null ? 0.0 : _displayWeight(previous.weightKg))
        : double.tryParse(draft.weight.text);
    final reps = draft.reps.text.trim().isEmpty
        ? previous?.reps
        : int.tryParse(draft.reps.text);
    if (weight == null || weight < 0 || weight > 1000) {
      setState(() => _error = 'Enter a weight from 0 to 1,000.');
      return;
    }
    if (reps == null || reps < 1 || reps > 100) {
      setState(() => _error = 'Enter at least 1 rep.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final unit =
          ref.read(authControllerProvider).user?.weightUnit ?? WeightUnit.kg;
      final submission = await ref
          .read(activeSessionProvider.notifier)
          .createSet(
            widget.exercise,
            toKg(weight, unit),
            reps,
            isWarmup: false,
          );
      await ref
          .read(activeSessionProvider.notifier)
          .setRest(DateTime.now().toUtc().add(const Duration(seconds: 60)));
      if (submission.queued && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Set saved on this device. It will sync automatically.',
            ),
          ),
        );
      } else if (submission.personalRecord != null && mounted) {
        _showPersonalRecordCelebration(context, submission.personalRecord!);
      }
      setState(() {
        draft.dispose();
        _drafts.removeAt(index);
      });
    } on AppFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _displayWeight(double weightKg) {
    final unit =
        ref.read(authControllerProvider).user?.weightUnit ?? WeightUnit.kg;
    return unit == WeightUnit.lb ? weightKg * 2.2046226218 : weightKg;
  }

  PreviousPerformance? _previousFor(int zeroBasedOrder) {
    final previous = widget.exercise.previousPerformances;
    if (zeroBasedOrder >= 0 && zeroBasedOrder < previous.length) {
      return previous[zeroBasedOrder];
    }
    return widget.exercise.previousPerformance;
  }

  Future<void> _edit(LoggedSet set, WeightUnit unit) async {
    final weight = TextEditingController(
      text: (unit == WeightUnit.lb ? set.weightKg * 2.2046226218 : set.weightKg)
          .toStringAsFixed(1),
    );
    final reps = TextEditingController(text: '${set.reps}');
    final values = await showDialog<({double weight, int reps})>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Edit set ${set.setOrder}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: 'Weight (${unit.name})'),
            ),
            TextField(
              controller: reps,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
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
              final w = double.tryParse(weight.text);
              final r = int.tryParse(reps.text);
              if (w != null &&
                  w >= 0 &&
                  w <= 1000 &&
                  r != null &&
                  r >= 1 &&
                  r <= 100)
                Navigator.pop(dialog, (weight: w, reps: r));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    weight.dispose();
    reps.dispose();
    if (values == null) return;
    try {
      await ref
          .read(activeSessionProvider.notifier)
          .updateSet(
            set.id,
            toKg(values.weight, unit),
            values.reps,
            isWarmup: set.isWarmup,
          );
    } on AppFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }
}

void _showPersonalRecordCelebration(
  BuildContext context,
  PersonalRecord record,
) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      duration: const Duration(seconds: 4),
      content: PersonalRecordCelebration(record: record),
    ),
  );
}

class PersonalRecordCelebration extends StatefulWidget {
  const PersonalRecordCelebration({super.key, required this.record});
  final PersonalRecord record;

  @override
  State<PersonalRecordCelebration> createState() =>
      _PersonalRecordCelebrationState();
}

class _PersonalRecordCelebrationState extends State<PersonalRecordCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    final type = widget.record.kind == PersonalRecordKind.estimatedOneRepMax
        ? 'ESTIMATED 1RM PR'
        : 'REP PR';
    final foreground =
        ThemeData.estimateBrightnessForColor(palette.gold) == Brightness.dark
        ? Colors.white
        : palette.ink;
    return Semantics(
      liveRegion: true,
      label: '$type for ${widget.record.exerciseName}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 92),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.gold, palette.ready, palette.oxide],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: palette.gold, width: 2),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _burst,
                    builder: (_, _) => CustomPaint(
                      painter: _ConfettiBurstPainter(
                        progress: _burst.value,
                        colors: [
                          palette.raised,
                          palette.gold,
                          palette.ink,
                          palette.recovering,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: foreground.withValues(alpha: .16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: foreground,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: TextStyle(
                              color: foreground,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.record.exerciseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.auto_awesome, color: foreground),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfettiBurstPainter extends CustomPainter {
  const _ConfettiBurstPainter({required this.progress, required this.colors});
  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .64);
    final burst = Curves.easeOut.transform(progress);
    for (var index = 0; index < 18; index += 1) {
      final angle = (math.pi * 2 * index / 18) - math.pi / 2;
      final distance = (24 + (index % 4) * 10) * burst;
      final offset = Offset(
        center.dx + math.cos(angle) * distance * 4.4,
        center.dy + math.sin(angle) * distance * 1.8 + 28 * burst * burst,
      );
      final paint = Paint()..color = colors[index % colors.length];
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(angle + progress * math.pi * 2);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 5, height: 9),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiBurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}

class _SetDraft {
  _SetDraft(this.order);
  final int order;
  final weight = TextEditingController();
  final reps = TextEditingController();
  void dispose() {
    weight.dispose();
    reps.dispose();
  }
}

class _SetLedgerHeader extends StatelessWidget {
  const _SetLedgerHeader({required this.unit});
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    if (compact) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 240) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.only(left: 48, right: 84),
          child: Row(
            children: [
              Expanded(child: Text('WEIGHT (${unit.name.toUpperCase()})')),
              const SizedBox(width: 16),
              const Expanded(child: Text('REPS')),
            ],
          ),
        );
      },
    );
  }
}

class _SetDraftRow extends StatelessWidget {
  const _SetDraftRow({
    super.key,
    required this.number,
    required this.draft,
    required this.unit,
    required this.previous,
    required this.saving,
    required this.onLog,
  });
  final int number;
  final _SetDraft draft;
  final WeightUnit unit;
  final PreviousPerformance? previous;
  final bool saving;
  final VoidCallback onLog;

  String? get _weightPlaceholder => previous == null
      ? null
      : _number(
          unit == WeightUnit.lb
              ? previous!.weightKg * 2.2046226218
              : previous!.weightKg,
        );

  String? get _repsPlaceholder => previous == null ? null : '${previous!.reps}';

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    Widget weightInput() => TextField(
      controller: draft.weight,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: _weightPlaceholder,
        border: const UnderlineInputBorder(),
        isDense: compact,
        contentPadding: compact
            ? const EdgeInsets.symmetric(vertical: 7)
            : null,
      ),
    );
    Widget repsInput() => TextField(
      controller: draft.reps,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: _repsPlaceholder,
        border: const UnderlineInputBorder(),
        isDense: compact,
        contentPadding: compact
            ? const EdgeInsets.symmetric(vertical: 7)
            : null,
      ),
    );
    final logButton = SizedBox(
      width: compact ? 64 : 72,
      child: ElevatedButton(
        onPressed: saving ? null : onLog,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(compact ? 64 : 72, compact ? 40 : 48),
          padding: EdgeInsets.zero,
        ),
        child: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Log', maxLines: 1, softWrap: false),
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final numberLabel = Text(
            number.toString().padLeft(2, '0'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          );
          if (constraints.maxWidth < 240) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox(width: 28, child: numberLabel),
                    Expanded(child: weightInput()),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: repsInput(),
                ),
                Align(alignment: Alignment.centerRight, child: logButton),
              ],
            );
          }
          return Row(
            children: [
              SizedBox(width: compact ? 40 : 48, child: numberLabel),
              Expanded(child: weightInput()),
              SizedBox(width: compact ? 10 : 16),
              Expanded(child: repsInput()),
              SizedBox(width: compact ? 8 : 12),
              logButton,
            ],
          );
        },
      ),
    );
  }
}

String _number(double value) =>
    value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

class _PendingSyncIndicator extends ConsumerWidget {
  const _PendingSyncIndicator({required this.pendingCount});
  final int pendingCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TransmutePalette.of(context);
    final noun = pendingCount == 1 ? 'set' : 'sets';
    return Material(
      color: palette.raised,
      elevation: 2,
      shape: const CircleBorder(),
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          tooltip: 'Sync $pendingCount pending $noun',
          padding: EdgeInsets.zero,
          iconSize: 20,
          color: palette.oxide,
          icon: const Icon(Icons.cloud_sync_outlined),
          onPressed: () async {
            final report = await ref
                .read(activeSessionProvider.notifier)
                .syncPending(retryBlocked: true);
            if (context.mounted) {
              final message = report.synced.isNotEmpty
                  ? '${report.synced.length} pending ${report.synced.length == 1 ? 'set' : 'sets'} synced.'
                  : 'Still offline or the workout needs attention before these sets can sync.';
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
        ),
      ),
    );
  }
}

class _SessionExerciseDemo extends StatelessWidget {
  const _SessionExerciseDemo({
    required this.name,
    required this.url,
    required this.expanded,
    required this.onToggle,
    this.sourceName,
  });
  final String name;
  final String url;
  final String? sourceName;
  final bool expanded;
  final VoidCallback onToggle;

  bool get _directVideo {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.path.toLowerCase().endsWith('.mp4') ||
        uri.host.toLowerCase().endsWith('firebasestorage.googleapis.com');
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onToggle,
        icon: Icon(expanded ? Icons.expand_less : Icons.play_circle_outline),
        label: Text(expanded ? 'Hide demonstration' : 'Watch demonstration'),
      ),
      if (expanded)
        _directVideo
            ? _DirectExerciseVideo(name: name, url: url, sourceName: sourceName)
            : Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  title: const Text('Open exercise demonstration'),
                  subtitle: Text(
                    sourceName?.trim().isNotEmpty == true
                        ? sourceName!
                        : 'The source hosts this demonstration externally.',
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final launched = await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                    if (!launched && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'The demonstration could not be opened.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
    ],
  );
}

class _DirectExerciseVideo extends StatefulWidget {
  const _DirectExerciseVideo({
    required this.name,
    required this.url,
    this.sourceName,
  });
  final String name;
  final String url;
  final String? sourceName;
  @override
  State<_DirectExerciseVideo> createState() => _DirectExerciseVideoState();
}

class _DirectExerciseVideoState extends State<_DirectExerciseVideo> {
  late final VideoPlayerController _controller;
  String? _error;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.setLooping(true);
      await _controller.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'The demonstration could not be loaded.');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Padding(padding: const EdgeInsets.all(12), child: Text(_error!));
    }
    if (!_controller.value.isInitialized) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Semantics(
      label: '${widget.name} movement demonstration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          Row(
            children: [
              IconButton(
                tooltip: _controller.value.isPlaying
                    ? 'Pause demo'
                    : 'Play demo',
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: () => setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                }),
              ),
              if (widget.sourceName?.trim().isNotEmpty == true)
                Expanded(child: Text(widget.sourceName!)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestTimer extends ConsumerStatefulWidget {
  const _RestTimer({required this.session});
  final WorkoutSession session;
  @override
  ConsumerState<_RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends ConsumerState<_RestTimer> {
  Timer? _ticker;
  var _open = false;
  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _RestTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.restEndsAt != widget.session.restEndsAt &&
        widget.session.restEndsAt != null) {
      _open = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.session.restEndsAt;
    final seconds = deadline == null
        ? 0
        : deadline.difference(DateTime.now().toUtc()).inSeconds.clamp(0, 600);
    final label =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    final palette = TransmutePalette.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: _open ? 280 : 132,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.ink,
        border: Border.all(color: palette.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: _open
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: palette.raised,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Minimize rest timer',
                      onPressed: () => setState(() => _open = false),
                      icon: Icon(Icons.close, color: palette.raised),
                    ),
                  ],
                ),
                Row(
                  children: [
                    for (final duration in [60, 120, 300])
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                          ),
                          onPressed: () => _start(duration),
                          child: Text(
                            duration == 60 ? '1m' : '${duration ~/ 60}m',
                            style: TextStyle(color: palette.raised),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Custom rest',
                        onPressed: _custom,
                        icon: Icon(Icons.more_time, color: palette.gold),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Reset rest timer',
                        onPressed: deadline == null
                            ? null
                            : () async {
                                await ref
                                    .read(activeSessionProvider.notifier)
                                    .setRest(null);
                                if (mounted) setState(() => _open = false);
                              },
                        icon: Icon(Icons.restart_alt, color: palette.gold),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Open rest timer',
                  onPressed: () => setState(() => _open = true),
                  icon: Icon(Icons.timer_outlined, color: palette.gold),
                ),
                VerticalDivider(color: palette.divider, width: 1),
                IconButton(
                  tooltip: 'Start 60 second rest',
                  onPressed: () => _start(60),
                  icon: Icon(Icons.play_arrow, color: palette.gold),
                ),
              ],
            ),
    );
  }

  Future<void> _start(int seconds) async {
    setState(() => _open = true);
    await ref
        .read(activeSessionProvider.notifier)
        .setRest(DateTime.now().toUtc().add(Duration(seconds: seconds)));
  }

  Future<void> _custom() async {
    final input = TextEditingController();
    final seconds = await showDialog<int>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Custom rest'),
        content: TextField(
          controller: input,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Seconds (10–600)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(input.text);
              if (value != null && value >= 10 && value <= 600)
                Navigator.pop(dialog, value);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
    input.dispose();
    if (seconds != null) await _start(seconds);
  }
}

class _ExerciseDialog extends ConsumerStatefulWidget {
  const _ExerciseDialog();
  @override
  ConsumerState<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _SessionExerciseSelection {
  const _SessionExerciseSelection.exercise(this.exercise) : catalog = null;
  const _SessionExerciseSelection.catalog(this.catalog) : exercise = null;
  final Exercise? exercise;
  final CatalogExercise? catalog;
}

class _ExerciseDialogState extends ConsumerState<_ExerciseDialog> {
  final _query = TextEditingController();
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(exerciseSearchProvider(_query.text));
    final catalog = _query.text.trim().length < 2
        ? const AsyncData<List<CatalogExercise>>([])
        : ref.watch(calistreeSearchProvider(_query.text));
    return AlertDialog(
      title: const Text('Exercise library'),
      content: SizedBox(
        width: 420,
        height: 380,
        child: Column(
          children: [
            TextField(
              controller: _query,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Search exercises'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: results.when(
                data: (items) => ListView(
                  children: [
                    if (items.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          'YOUR LIBRARY',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ...items.map(
                      (item) => ListTile(
                        title: Text(item.name),
                        subtitle: Text(item.muscleGroup ?? item.category),
                        onTap: () => Navigator.pop(
                          context,
                          _SessionExerciseSelection.exercise(item),
                        ),
                      ),
                    ),
                    ...catalog.when(
                      data: (catalogItems) => [
                        if (catalogItems.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 16, bottom: 4),
                            child: Text(
                              'EXERCISE CATALOG',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ...catalogItems.map(
                          (item) => ListTile(
                            leading: const Icon(Icons.travel_explore_outlined),
                            title: Text(item.name),
                            subtitle: const Text(
                              'Import from exercise catalog',
                            ),
                            trailing: const Icon(Icons.add_circle_outline),
                            onTap: () => Navigator.pop(
                              context,
                              _SessionExerciseSelection.catalog(item),
                            ),
                          ),
                        ),
                      ],
                      loading: () => const [
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: LinearProgressIndicator(),
                        ),
                      ],
                      error: (_, __) => const [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Exercise catalog unavailable. You can still use your library.',
                          ),
                        ),
                      ],
                    ),
                    if (items.isEmpty && catalog.asData?.value.isEmpty == true)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No matching exercises yet.'),
                      ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(exerciseSearchProvider(_query.text)),
                    child: const Text('Retry'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

String _time(DateTime at) =>
    '${at.toLocal().hour.toString().padLeft(2, '0')}:${at.toLocal().minute.toString().padLeft(2, '0')}';
