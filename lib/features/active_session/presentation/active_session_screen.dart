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
  late int _movementIndex;

  @override
  void initState() {
    super.initState();
    _movementIndex = _resumeMovementIndex(widget.session);
  }

  @override
  void didUpdateWidget(covariant _SessionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.id != widget.session.id) {
      _movementIndex = _resumeMovementIndex(widget.session);
    } else if (_movementIndex >= widget.session.exercises.length) {
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
    final isFinalMovement =
        selected != null && _movementIndex == session.exercises.length - 1;
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
              ),
              const SizedBox(height: 8),
              _ExerciseCard(exercise: selected, showIdentity: false),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isFinalMovement
                    ? () => _finish(context, ref, session)
                    : () => setState(() => _movementIndex += 1),
                icon: Icon(
                  isFinalMovement
                      ? Icons.check_circle_outline
                      : Icons.arrow_forward,
                ),
                label: Text(
                  isFinalMovement ? 'Finish Workout' : 'Next Movement',
                ),
              ),
            ],
          );
    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.planName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (pendingCount > 0)
                    _PendingSyncIndicator(pendingCount: pendingCount),
                  TextButton(
                    onPressed: () => _finish(context, ref, session),
                    child: const Text('Finish'),
                  ),
                  IconButton(
                    tooltip: 'Discard Workout',
                    onPressed: () => _discard(context, ref, session),
                    color: const Color(0xffA33B36),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Started ${_time(session.startedAt)} · ${session.workingSetCount} working sets',
              ),
              const SizedBox(height: 8),
              if (box.maxWidth >= 1024)
                Expanded(child: SingleChildScrollView(child: movement))
              else
                Expanded(child: ListView(children: [movement])),
            ],
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
              child: const Text('Finish Workout'),
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
        title: const Text('Discard Workout?'),
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
            child: const Text('Discard Workout'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await ref.read(activeSessionProvider.notifier).discard();
      if (context.mounted) context.go('/plans');
    }
  }
}

int _resumeMovementIndex(WorkoutSession session) {
  var resumeIndex = 0;
  DateTime? lastLoggedAt;
  for (
    var exerciseIndex = 0;
    exerciseIndex < session.exercises.length;
    exerciseIndex += 1
  ) {
    for (final set in session.exercises[exerciseIndex].sets) {
      if (lastLoggedAt == null ||
          set.completedAt.isAfter(lastLoggedAt) ||
          (set.completedAt.isAtSameMomentAs(lastLoggedAt) &&
              exerciseIndex >= resumeIndex)) {
        lastLoggedAt = set.completedAt;
        resumeIndex = exerciseIndex;
      }
    }
  }
  return resumeIndex;
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
            label: const Text('Add Movement'),
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
  });

  final SessionExercise exercise;
  final int currentIndex;
  final int movementCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onAdd;

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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  exercise.name,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: compact ? 24 : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next Movement',
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
          label: const Text('Add Movement'),
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
  _SetDraft? _savingDraft;
  Set<String>? _setIdsBeforeSave;
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
    final visibleSets = _setIdsBeforeSave == null
        ? exercise.sets
        : exercise.sets
              .where((set) => _setIdsBeforeSave!.contains(set.id))
              .toList();
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
            ...visibleSets.map(
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
                isSubmitting: identical(_savingDraft, _drafts[index]),
                disabled: _savingDraft != null,
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
                onPressed: _savingDraft != null
                    ? null
                    : () => setState(
                        () => _drafts.add(_SetDraft(_nextDraftOrder++)),
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Add Set'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(int index) async {
    if (_savingDraft != null) return;
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
      _savingDraft = draft;
      _setIdsBeforeSave = widget.exercise.sets.map((set) => set.id).toSet();
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
      if (!mounted) return;
      setState(() {
        draft.dispose();
        _drafts.removeAt(index);
        _savingDraft = null;
        _setIdsBeforeSave = null;
      });
    } on AppFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted && identical(_savingDraft, draft)) {
        setState(() {
          _savingDraft = null;
          _setIdsBeforeSave = null;
        });
      }
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
    final values = await showModalBottomSheet<({double weight, int reps})>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _EditSetSheet(set: set, unit: unit),
    );
    if (values == null || !mounted) return;
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

class _EditSetSheet extends StatefulWidget {
  const _EditSetSheet({required this.set, required this.unit});

  final LoggedSet set;
  final WeightUnit unit;

  @override
  State<_EditSetSheet> createState() => _EditSetSheetState();
}

class _EditSetSheetState extends State<_EditSetSheet> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  String? _error;

  @override
  void initState() {
    super.initState();
    final value = widget.unit == WeightUnit.lb
        ? widget.set.weightKg * 2.2046226218
        : widget.set.weightKg;
    _weight = TextEditingController(text: value.toStringAsFixed(1));
    _reps = TextEditingController(text: '${widget.set.reps}');
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_weight.text);
    final reps = int.tryParse(_reps.text);
    if (weight == null || weight < 0 || weight > 1000) {
      setState(() => _error = 'Enter a weight from 0 to 1,000.');
      return;
    }
    if (reps == null || reps < 1 || reps > 100) {
      setState(() => _error = 'Enter at least 1 rep.');
      return;
    }
    Navigator.of(context).pop((weight: weight, reps: reps));
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = widget.unit == WeightUnit.lb ? 'lb' : 'kg';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit set ${widget.set.setOrder}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Close set editor',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weight,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: 'Weight ($unitLabel)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _reps,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _save(),
                  decoration: const InputDecoration(labelText: 'Reps'),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
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
        ThemeData.estimateBrightnessForColor(palette.ready) == Brightness.dark
        ? Colors.white
        : palette.ink;
    return Semantics(
      liveRegion: true,
      label: '$type for ${widget.record.exerciseName}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          decoration: BoxDecoration(
            color: palette.ready,
            border: Border.all(color: foreground.withValues(alpha: .26)),
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                        child: SizedBox(
                          height: 46,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                              const SizedBox(height: 3),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    widget.record.exerciseName,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: foreground,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
    required this.isSubmitting,
    required this.disabled,
    required this.onLog,
  });
  final int number;
  final _SetDraft draft;
  final WeightUnit unit;
  final PreviousPerformance? previous;
  final bool isSubmitting;
  final bool disabled;
  final VoidCallback onLog;

  String? get _weightPlaceholder => previous == null
      ? null
      : '${_number(unit == WeightUnit.lb ? previous!.weightKg * 2.2046226218 : previous!.weightKg)} ${unit.name}';

  String? get _repsPlaceholder =>
      previous == null ? null : '${previous!.reps} reps';

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
        onPressed: disabled ? null : onLog,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(compact ? 64 : 72, compact ? 40 : 48),
          padding: EdgeInsets.zero,
        ),
        child: isSubmitting
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
      Align(
        alignment: Alignment.center,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onToggle,
          icon: Icon(expanded ? Icons.expand_less : Icons.play_circle_outline),
          label: Text(expanded ? 'Hide Demo' : 'Watch Demo'),
        ),
      ),
      if (expanded)
        _directVideo
            ? _DirectExerciseVideo(name: name, url: url, sourceName: sourceName)
            : Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  title: const Text('Open Demo'),
                  subtitle: Text(
                    sourceName?.trim().isNotEmpty == true
                        ? sourceName!
                        : 'The source hosts this demo externally.',
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
      await _controller.play();
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
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(_controller),
            Positioned(
              left: 8,
              bottom: 8,
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller,
                builder: (context, value, _) => Material(
                  color: Colors.black.withValues(alpha: .58),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: value.isPlaying
                        ? 'Pause demonstration'
                        : 'Play demonstration',
                    color: Colors.white,
                    onPressed: () {
                      value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    },
                    icon: Icon(
                      value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
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
      width: _open ? 224 : 112,
      padding: const EdgeInsets.all(6),
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
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Minimize rest timer',
                      onPressed: () => setState(() => _open = false),
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.close, color: palette.raised, size: 20),
                    ),
                  ],
                ),
                Row(
                  children: [
                    for (final duration in [60, 120, 300])
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _start(duration),
                          child: Text(
                            duration == 60 ? '1m' : '${duration ~/ 60}m',
                            style: TextStyle(color: palette.raised),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: 32,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 36,
                        ),
                        tooltip: 'Custom rest',
                        onPressed: _custom,
                        icon: Icon(
                          Icons.more_time,
                          size: 20,
                          color: palette.gold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 36,
                        ),
                        tooltip: 'Reset rest timer',
                        onPressed: deadline == null
                            ? null
                            : () async {
                                await ref
                                    .read(activeSessionProvider.notifier)
                                    .setRest(null);
                                if (mounted) setState(() => _open = false);
                              },
                        icon: Icon(
                          Icons.restart_alt,
                          size: 20,
                          color: palette.gold,
                        ),
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
    final seconds = await showDialog<int>(
      context: context,
      builder: (_) => const _CustomRestDialog(),
    );
    if (seconds != null && mounted) await _start(seconds);
  }
}

class _CustomRestDialog extends StatefulWidget {
  const _CustomRestDialog();

  @override
  State<_CustomRestDialog> createState() => _CustomRestDialogState();
}

class _CustomRestDialogState extends State<_CustomRestDialog> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _start() {
    final seconds = int.tryParse(_input.text);
    if (seconds == null || seconds < 10 || seconds > 600) return;
    Navigator.of(context).pop(seconds);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Custom rest'),
    content: TextField(
      controller: _input,
      autofocus: true,
      keyboardType: TextInputType.number,
      onSubmitted: (_) => _start(),
      decoration: const InputDecoration(labelText: 'Seconds (10–600)'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      ElevatedButton(onPressed: _start, child: const Text('Start')),
    ],
  );
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
