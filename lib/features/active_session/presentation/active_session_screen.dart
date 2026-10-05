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
import '../../../shared/design_system/design_system.dart';
import '../../../shared/theme/transmute_palette.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/workout_launch_card.dart';
import '../../../shared/widgets/exercise_video_controller.dart';
import '../../quick_add/presentation/quick_add_dialog.dart';
import '../../workout_plans/presentation/routine_dialogs.dart';

class ActiveSessionScreen extends ConsumerWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    return AppShell(
      title: 'Workout',
      desktopContentMaxWidth: null,
      child: session.when(
        data: (value) {
          if (value != null) return _SessionBody(session: value);
          return const _WorkoutHome();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => TransmuteStatePanel(
          kind: TransmuteStateKind.error,
          title: 'Workout unavailable',
          message: 'We could not check for an active session.',
          action: TransmuteButton(
            label: 'Retry',
            icon: Icons.refresh,
            onPressed: () => ref.read(activeSessionProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }
}

class _WorkoutHome extends ConsumerStatefulWidget {
  const _WorkoutHome();

  @override
  ConsumerState<_WorkoutHome> createState() => _WorkoutHomeState();
}

class _WorkoutHomeState extends ConsumerState<_WorkoutHome> {
  String? _startingDayId;
  bool _startingFreeform = false;

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(workoutEntryProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return ListView(
      padding: EdgeInsets.only(bottom: compact ? 24 : 32),
      children: [
        _WorkoutSectionHeading(
          title: "Today's Workout",
          trailing: const SizedBox.shrink(),
        ),
        const SizedBox(height: 10),
        const WorkoutLaunchCard(),
        const SizedBox(height: 28),
        _WorkoutSectionHeading(
          title: 'New Workout',
          trailing: const SizedBox.shrink(),
        ),
        const SizedBox(height: 10),
        _NewWorkoutAction(
          icon: Icons.fitness_center_outlined,
          title: _startingFreeform
              ? 'Starting workout…'
              : 'Start Empty Workout',
          subtitle: 'Choose exercises and log as you train.',
          onTap: _startFreeform,
        ),
        const SizedBox(height: 8),
        _NewWorkoutAction(
          icon: Icons.edit_note_outlined,
          title: 'Generate Workout',
          subtitle: 'Build a routine manually or with plan assist.',
          onTap: () => context.go('/plans'),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const QuickAddWorkoutDialog(),
            ),
            icon: const Icon(Icons.bolt_outlined),
            label: const Text('Quick Add one exercise'),
          ),
        ),
        const SizedBox(height: 28),
        _WorkoutSectionHeading(
          title: 'Routines',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Manage routine folders',
                onPressed: () => context.go('/plans'),
                icon: const Icon(Icons.folder_outlined),
              ),
              IconButton(
                tooltip: 'Create a routine',
                onPressed: entry.asData == null
                    ? null
                    : () => _createRoutine(entry.asData!.value.plans),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        entry.when(
          skipLoadingOnRefresh: true,
          loading: () => const TransmuteStatePanel(
            kind: TransmuteStateKind.loading,
            title: 'Loading routines',
          ),
          error: (_, _) => TransmuteStatePanel(
            kind: TransmuteStateKind.error,
            title: 'Routines unavailable',
            message: 'Retry to view and start your saved training days.',
            action: TransmuteButton(
              label: 'Retry routines',
              icon: Icons.refresh,
              onPressed: () => ref.invalidate(workoutEntryProvider),
            ),
          ),
          data: (data) => data.plans.isEmpty
              ? TransmuteStatePanel(
                  kind: TransmuteStateKind.empty,
                  title: 'No routines yet',
                  message:
                      'Create a routine and add exercises from the library.',
                  action: TransmuteButton(
                    label: 'Create a routine',
                    icon: Icons.add,
                    onPressed: () => _createRoutine(const []),
                  ),
                )
              : Column(
                  children: [
                    for (final plan in data.plans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RoutinePanel(
                          plan: plan,
                          isActive: plan.id == data.activePlanId,
                          startingDayId: _startingDayId,
                          onStart: (day) => _start(plan, day),
                          onOpen: () => context.go('/plans/${plan.id}'),
                          onCreate: () => _createRoutine(data.plans, plan.id),
                          onOpenDay: (day) =>
                              context.go('/plans/${plan.id}?dayId=${day.id}'),
                          onRename: (day) => _renameRoutine(plan, day),
                          onDelete: (day) => _deleteRoutine(plan, day),
                          onMove: (day, direction) =>
                              _moveRoutine(plan, day, direction),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => context.go('/history'),
          icon: const Icon(Icons.history),
          label: const Text('View workout history'),
        ),
      ],
    );
  }

  Future<void> _createRoutine(
    List<WorkoutPlan> folders, [
    String? folderId,
  ]) async {
    final location = await showCreateRoutineDialog(
      context: context,
      repository: ref.read(planRepositoryProvider),
      folders: folders,
      initialFolderId: folderId,
    );
    if (!mounted) return;
    ref.invalidate(plansProvider);
    if (location == null) return;
    context.go('/plans/${location.planId}?dayId=${location.dayId}');
  }

  Future<void> _renameRoutine(WorkoutPlan plan, WorkoutPlanDay day) async {
    final saved = await showRoutineNameDialog<WorkoutPlanDay>(
      context: context,
      title: 'Rename routine',
      label: 'Routine name',
      initial: day.name,
      onSave: (name) =>
          ref.read(planRepositoryProvider).renameDay(plan.id, day.id, name),
    );
    if (saved != null) ref.invalidate(plansProvider);
  }

  Future<void> _deleteRoutine(WorkoutPlan plan, WorkoutPlanDay day) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${day.name}?'),
        content: const Text(
          'This removes the saved routine and its prescriptions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(planRepositoryProvider).deleteDay(plan.id, day.id);
      ref.invalidate(plansProvider);
    } on AppFailure catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _moveRoutine(
    WorkoutPlan plan,
    WorkoutPlanDay day,
    ReorderDirection direction,
  ) async {
    try {
      await ref
          .read(planRepositoryProvider)
          .reorderDay(plan.id, day.id, direction);
      ref.invalidate(plansProvider);
    } on AppFailure catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _start(WorkoutPlan plan, WorkoutPlanDay day) async {
    if (_startingDayId != null || _startingFreeform) return;
    setState(() => _startingDayId = day.id);
    try {
      await ref.read(activeSessionProvider.notifier).start(plan.id, day.id);
      if (mounted) context.go('/session');
    } on AppFailure catch (error) {
      if (!mounted) return;
      if (error.code == 'active_session_exists') {
        await ref.read(activeSessionProvider.notifier).refresh();
        if (!mounted) return;
        if (ref.read(activeSessionProvider).asData?.value != null) {
          context.go('/session');
          return;
        }
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _startingDayId = null);
    }
  }

  Future<void> _startFreeform() async {
    if (_startingFreeform || _startingDayId != null) return;
    setState(() => _startingFreeform = true);
    try {
      await ref.read(activeSessionProvider.notifier).startFreeform();
      if (mounted) context.go('/session');
    } on AppFailure catch (error) {
      if (!mounted) return;
      if (error.code == 'active_session_exists') {
        await ref.read(activeSessionProvider.notifier).refresh();
        if (!mounted) return;
        if (ref.read(activeSessionProvider).asData?.value != null) {
          context.go('/session');
          return;
        }
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _startingFreeform = false);
    }
  }
}

class _WorkoutSectionHeading extends StatelessWidget {
  const _WorkoutSectionHeading({required this.title, required this.trailing});
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      trailing,
    ],
  );
}

class _NewWorkoutAction extends StatelessWidget {
  const _NewWorkoutAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: TransmuteListRow(
      title: title,
      subtitle: subtitle,
      leading: Icon(icon),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    ),
  );
}

class _RoutinePanel extends StatelessWidget {
  const _RoutinePanel({
    required this.plan,
    required this.isActive,
    required this.startingDayId,
    required this.onStart,
    required this.onOpen,
    required this.onCreate,
    required this.onOpenDay,
    required this.onRename,
    required this.onDelete,
    required this.onMove,
  });

  final WorkoutPlan plan;
  final bool isActive;
  final String? startingDayId;
  final ValueChanged<WorkoutPlanDay> onStart;
  final VoidCallback onOpen;
  final VoidCallback onCreate;
  final ValueChanged<WorkoutPlanDay> onOpenDay;
  final ValueChanged<WorkoutPlanDay> onRename;
  final ValueChanged<WorkoutPlanDay> onDelete;
  final void Function(WorkoutPlanDay, ReorderDirection) onMove;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    final exerciseTotal = plan.exerciseCount;
    final activeLabel = isActive ? ' · ACTIVE PLAN' : '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: DesignSpace.lg),
        childrenPadding: const EdgeInsets.fromLTRB(
          DesignSpace.lg,
          0,
          DesignSpace.lg,
          DesignSpace.md,
        ),
        title: Text(plan.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${plan.days.length} ${plan.days.length == 1 ? 'day' : 'days'} · $exerciseTotal ${exerciseTotal == 1 ? 'exercise' : 'exercises'}$activeLabel',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isActive ? palette.steel : palette.muted,
          ),
        ),
        initiallyExpanded: true,
        children: [
          if (plan.days.isEmpty)
            TransmuteListRow(
              title: 'No training days yet',
              subtitle: 'Add a routine to this folder.',
              leading: const Icon(Icons.event_note_outlined),
              onTap: onCreate,
            )
          else
            for (var index = 0; index < plan.days.length; index++)
              _RoutineDayRow(
                day: plan.days[index],
                busy: startingDayId == plan.days[index].id,
                disabled: startingDayId != null,
                onStart: () => onStart(plan.days[index]),
                onOpen: () => onOpenDay(plan.days[index]),
                onRename: () => onRename(plan.days[index]),
                onDelete: () => onDelete(plan.days[index]),
                onMoveUp: index == 0
                    ? null
                    : () => onMove(plan.days[index], ReorderDirection.up),
                onMoveDown: index == plan.days.length - 1
                    ? null
                    : () => onMove(plan.days[index], ReorderDirection.down),
              ),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              TextButton(onPressed: onOpen, child: const Text('Manage folder')),
              TextButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add routine'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineDayRow extends StatelessWidget {
  const _RoutineDayRow({
    required this.day,
    required this.busy,
    required this.disabled,
    required this.onStart,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final WorkoutPlanDay day;
  final bool busy;
  final bool disabled;
  final VoidCallback onStart;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final sets = day.exercises.fold<int>(
      0,
      (total, exercise) => total + exercise.targetSets,
    );
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: DesignSpace.xs),
        Text(
          '$sets sets · ${day.exercises.length} ${day.exercises.length == 1 ? 'exercise' : 'exercises'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
    final startButton = OutlinedButton(
      onPressed: disabled || day.exercises.isEmpty ? null : onStart,
      child: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Start'),
    );
    final menu = PopupMenuButton<String>(
      tooltip: 'Options for ${day.name}',
      onSelected: (action) {
        switch (action) {
          case 'edit':
            onOpen();
          case 'rename':
            onRename();
          case 'up':
            onMoveUp?.call();
          case 'down':
            onMoveDown?.call();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit routine')),
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        if (onMoveUp != null)
          const PopupMenuItem(value: 'up', child: Text('Move up')),
        if (onMoveDown != null)
          const PopupMenuItem(value: 'down', child: Text('Move down')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: DesignSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth < 240
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: summary),
                          menu,
                        ],
                      ),
                      startButton,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: summary),
                      const SizedBox(width: DesignSpace.sm),
                      menu,
                      startButton,
                    ],
                  ),
          ),
          for (final exercise in day.exercises.take(3))
            Padding(
              padding: const EdgeInsets.only(top: DesignSpace.xs),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, size: 15),
                  const SizedBox(width: DesignSpace.sm),
                  Expanded(
                    child: Text(
                      exercise.exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    '${exercise.targetSets} sets',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          if (day.exercises.length > 3)
            Text(
              'and ${day.exercises.length - 3} more',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (day.exercises.isEmpty)
            TextButton(
              onPressed: onOpen,
              child: const Text('Add exercises to start'),
            ),
          const Divider(height: DesignSpace.xl),
        ],
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
  final _compactScrollController = ScrollController();

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
      _scrollCompactToTop(animate: false);
    } else if (_movementIndex >= widget.session.exercises.length) {
      _movementIndex = widget.session.exercises.isEmpty
          ? 0
          : widget.session.exercises.length - 1;
      _scrollCompactToTop();
    }
  }

  @override
  void dispose() {
    _compactScrollController.dispose();
    super.dispose();
  }

  void _selectMovement(int index) {
    if (index == _movementIndex) return;
    FocusScope.of(context).unfocus();
    setState(() => _movementIndex = index);
    _scrollCompactToTop();
  }

  void _scrollCompactToTop({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_compactScrollController.hasClients) return;
      if (!animate || MediaQuery.sizeOf(context).width >= 1024) {
        _compactScrollController.jumpTo(0);
        return;
      }
      _compactScrollController.animateTo(
        0,
        duration: DesignMotion.duration(context, DesignMotion.standard),
        curve: DesignMotion.curve,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final pendingCount = session.exercises
        .expand((exercise) => exercise.sets)
        .where((set) => set.pending)
        .length;
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 1024;
        final compact = box.maxWidth < 600;
        final selected = session.exercises.isEmpty
            ? null
            : session.exercises[_movementIndex];
        final isFinalMovement =
            selected != null && _movementIndex == session.exercises.length - 1;
        final action = selected == null
            ? null
            : TransmuteButton(
                onPressed: isFinalMovement
                    ? pendingCount > 0
                          ? null
                          : () => _finish(context, ref, session)
                    : () => _selectMovement(_movementIndex + 1),
                icon: isFinalMovement
                    ? Icons.check_circle_outline
                    : Icons.arrow_forward,
                label: isFinalMovement
                    ? pendingCount > 0
                          ? 'Sync sets to finish'
                          : 'Finish Workout'
                    : 'Next Movement',
              );
        final movement = selected == null
            ? _EmptyMovementState(
                onAdd: () => _chooseExercise(context, ref, session),
              )
            : wide
            ? _WideMovementLayout(
                exercise: selected,
                currentIndex: _movementIndex,
                movementCount: session.exercises.length,
                onPrevious: _movementIndex == 0
                    ? null
                    : () => _selectMovement(_movementIndex - 1),
                onNext: _movementIndex == session.exercises.length - 1
                    ? null
                    : () => _selectMovement(_movementIndex + 1),
                onStepSelected: _selectMovement,
                onAdd: () => _chooseExercise(context, ref, session),
              )
            : _CompactMovementLayout(
                exercise: selected,
                currentIndex: _movementIndex,
                movementCount: session.exercises.length,
                onPrevious: _movementIndex == 0
                    ? null
                    : () => _selectMovement(_movementIndex - 1),
                onNext: _movementIndex == session.exercises.length - 1
                    ? null
                    : () => _selectMovement(_movementIndex + 1),
                onStepSelected: _selectMovement,
                onAdd: () => _chooseExercise(context, ref, session),
              );
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.planName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 22 : 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (session.origin == WorkoutSessionOrigin.freeform)
                  Text(
                    'FREEFORM · ${session.exercises.length} ${session.exercises.length == 1 ? 'exercise' : 'exercises'} · ${session.workingSetCount} ${session.workingSetCount == 1 ? 'working set' : 'working sets'}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: TransmutePalette.of(context).muted,
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.end,
                    children: [
                      if (pendingCount > 0)
                        _PendingSyncIndicator(pendingCount: pendingCount),
                      TextButton(
                        onPressed: pendingCount > 0
                            ? null
                            : () => _finish(context, ref, session),
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
                ),
                const SizedBox(height: 4),
                Text(
                  session.planDayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Started ${_time(session.startedAt)} · ${session.workingSetCount} working ${session.workingSetCount == 1 ? 'set' : 'sets'}',
                ),
                if (pendingCount > 0)
                  Text(
                    '$pendingCount ${pendingCount == 1 ? 'set is' : 'sets are'} saved on this device and must sync before finishing.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: wide
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: movement,
                        )
                      : ListView(
                          controller: _compactScrollController,
                          padding: const EdgeInsets.only(bottom: 16),
                          children: [movement],
                        ),
                ),
                if (selected != null) ...[
                  const SizedBox(height: 8),
                  if (compact) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: _RestTimer(session: session),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: action),
                  ] else
                    Row(
                      children: [
                        _RestTimer(session: session),
                        const SizedBox(width: 12),
                        Expanded(child: action!),
                      ],
                    ),
                ] else
                  Align(
                    alignment: Alignment.centerRight,
                    child: _RestTimer(session: session),
                  ),
              ],
            ),
          ],
        );
      },
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
      if (done.rankUpdates.isNotEmpty && context.mounted) {
        final update = done.rankUpdates.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              update.established
                  ? 'Personal ${update.tier.name} rank established.'
                  : 'Personal rank improved to ${update.tier.name}.',
            ),
          ),
        );
      }
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

class _CompactMovementLayout extends StatelessWidget {
  const _CompactMovementLayout({
    required this.exercise,
    required this.currentIndex,
    required this.movementCount,
    required this.onPrevious,
    required this.onNext,
    required this.onStepSelected,
    required this.onAdd,
  });

  final SessionExercise exercise;
  final int currentIndex;
  final int movementCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onStepSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _MovementStepper(
        exercise: exercise,
        currentIndex: currentIndex,
        movementCount: movementCount,
        onPrevious: onPrevious,
        onNext: onNext,
        onStepSelected: onStepSelected,
        onAdd: onAdd,
      ),
      const SizedBox(height: 8),
      _ExerciseCard(exercise: exercise, showIdentity: false),
    ],
  );
}

class _WideMovementLayout extends StatelessWidget {
  const _WideMovementLayout({
    required this.exercise,
    required this.currentIndex,
    required this.movementCount,
    required this.onPrevious,
    required this.onNext,
    required this.onStepSelected,
    required this.onAdd,
  });

  final SessionExercise exercise;
  final int currentIndex;
  final int movementCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onStepSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final hasDemo = exercise.demoUrl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MovementStepper(
          exercise: exercise,
          currentIndex: currentIndex,
          movementCount: movementCount,
          onPrevious: onPrevious,
          onNext: onNext,
          onStepSelected: onStepSelected,
          onAdd: onAdd,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ExerciseCard(
                    exercise: exercise,
                    showIdentity: false,
                    showDemo: false,
                  ),
                ],
              ),
            ),
            if (hasDemo) ...[
              const SizedBox(width: 20),
              SizedBox(
                width: 360,
                child: _ExerciseDemoRail(exercise: exercise),
              ),
            ],
          ],
        ),
      ],
    );
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
    required this.onStepSelected,
    required this.onAdd,
  });

  final SessionExercise exercise;
  final int currentIndex;
  final int movementCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onStepSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return TransmuteStepper(
      title: exercise.name,
      currentIndex: currentIndex,
      stepCount: movementCount,
      onPrevious: onPrevious,
      onNext: onNext,
      onStepSelected: onStepSelected,
      previousLabel: 'Previous movement',
      nextLabel: 'Next Movement',
      footer: TextButton.icon(
        style: compact
            ? TextButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              )
            : null,
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Movement'),
      ),
    );
  }
}

class _ExerciseCard extends ConsumerStatefulWidget {
  const _ExerciseCard({
    required this.exercise,
    this.showIdentity = true,
    this.showDemo = true,
  });
  final SessionExercise exercise;
  final bool showIdentity;
  final bool showDemo;
  @override
  ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
  final _drafts = <_SetDraft>[];
  String? _error;
  _SetDraft? _savingDraft;
  Set<String>? _setIdsBeforeSave;
  String? _deletingSetId;
  bool _demoExpanded = false;

  @override
  void initState() {
    super.initState();
    _addDrafts(_initialDraftCount(widget.exercise));
  }

  @override
  void didUpdateWidget(covariant _ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _disposeDrafts();
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
      final workingIndex =
          _workingSetCount(widget.exercise) +
          _drafts.where((draft) => !draft.isWarmup).length;
      final previous = _previousFor(workingIndex);
      final draft = _SetDraft(
        targetDurationSeconds: widget.exercise.targetDurationSeconds,
      );
      if (widget.exercise.trackingMode == ExerciseTrackingMode.timed) {
        final seconds =
            previous?.durationSeconds ?? widget.exercise.targetDurationSeconds;
        if (seconds != null) {
          draft.duration.text = draft.durationUnit.formatValue(
            draft.durationUnit.fromSeconds(seconds),
          );
        }
      } else {
        final weightKg =
            previous?.weightKg ?? widget.exercise.targetWeightKg ?? 0;
        draft.weight.text = _number(_displayWeight(weightKg));
        draft.reps.text = '${previous?.reps ?? widget.exercise.targetReps}';
      }
      _drafts.add(draft);
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
                          '${exercise.muscleGroup ?? 'Movement'} · target ${exercise.targetSets} × ${exercise.trackingMode == ExerciseTrackingMode.timed ? _formatTimedDuration(exercise.targetDurationSeconds) : '${exercise.targetReps} reps'}',
                        ),
                      ],
                    ),
                  ),
                  if (exercise.trackingMode == ExerciseTrackingMode.reps)
                    IconButton(
                      tooltip: 'Barbell plate calculator',
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => BarbellPlateCalculatorDialog(
                          initialWeight: exercise.sets.isNotEmpty
                              ? (unit == WeightUnit.lb
                                  ? exercise.sets.last.weightKg * 2.2046226218
                                  : exercise.sets.last.weightKg)
                              : (unit == WeightUnit.lb ? 135.0 : 60.0),
                          unit: unit,
                        ),
                      ),
                      icon: const Icon(Icons.calculate_outlined),
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
            Text(
              '${exercise.muscleGroup ?? 'Movement'} · ${exercise.targetSets} working sets · ${exercise.trackingMode == ExerciseTrackingMode.timed ? 'target ${_formatTimedDuration(exercise.targetDurationSeconds)}' : 'target ${exercise.targetReps} reps'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              exercise.trackingMode == ExerciseTrackingMode.timed
                  ? 'Previous timed result: ${_performanceLabel(_previousFor(0), unit)}'
                  : 'Previous working set: ${_performanceLabel(_previousFor(0), unit)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TransmutePalette.of(context).muted,
              ),
            ),
            if (widget.showDemo && exercise.demoUrl != null) ...[
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
              'SET LEDGER',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 4 : 8),
            for (var index = 0; index < visibleSets.length; index += 1)
              _SavedSetRow(
                set: visibleSets[index],
                unit: unit,
                previous: visibleSets[index].isWarmup
                    ? null
                    : _previousFor(
                        visibleSets
                            .take(index)
                            .where((set) => !set.isWarmup)
                            .length,
                      ),
                deleting: _deletingSetId == visibleSets[index].id,
                onEdit: () => _edit(visibleSets[index], unit),
                onDelete: () => _delete(visibleSets[index]),
              ),
            for (var index = 0; index < _drafts.length; index += 1)
              _SetDraftRow(
                key: ValueKey(_drafts[index]),
                number: exercise.sets.length + index + 1,
                draft: _drafts[index],
                unit: unit,
                trackingMode: exercise.trackingMode,
                targetDurationSeconds: exercise.targetDurationSeconds,
                onDurationUnitChanged: (unit) => setState(() {
                  final previousSeconds = double.tryParse(
                    _drafts[index].duration.text.trim(),
                  );
                  final seconds = previousSeconds == null
                      ? null
                      : _drafts[index].durationUnit.toSeconds(previousSeconds);
                  _drafts[index].durationUnit = unit;
                  if (seconds != null) {
                    final value = unit.fromSeconds(seconds);
                    _drafts[index].duration.text = unit.formatValue(value);
                  }
                }),
                previous: _drafts[index].isWarmup
                    ? null
                    : _previousFor(
                        _workingSetCount(exercise) +
                            _drafts
                                .take(index)
                                .where((draft) => !draft.isWarmup)
                                .length,
                      ),
                isSubmitting: identical(_savingDraft, _drafts[index]),
                disabled: _savingDraft != null,
                onWarmupChanged: (value) =>
                    setState(() => _drafts[index].isWarmup = value),
                onLog: () => _add(index),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: compact
                    ? TextButton.styleFrom(minimumSize: const Size(0, 44))
                    : null,
                onPressed: _savingDraft != null
                    ? null
                    : () => setState(
                        () => _drafts.add(
                          _SetDraft(
                            targetDurationSeconds:
                                exercise.targetDurationSeconds,
                          ),
                        ),
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
    final previous = draft.isWarmup
        ? null
        : _previousFor(
            _workingSetCount(widget.exercise) +
                _drafts.take(index).where((row) => !row.isWarmup).length,
          );
    final timed = widget.exercise.trackingMode == ExerciseTrackingMode.timed;
    final durationValue = double.tryParse(draft.duration.text.trim());
    final duration = timed
        ? durationValue == null
              ? widget.exercise.targetDurationSeconds
              : draft.durationUnit.toSeconds(durationValue)
        : null;
    if (timed && (duration == null || duration < 1 || duration > 86400)) {
      setState(() => _error = 'Enter a duration from 1 second to 24 hours.');
      return;
    }
    final weight = draft.weight.text.trim().isEmpty
        ? (previous == null ? 0.0 : _displayWeight(previous.weightKg))
        : double.tryParse(draft.weight.text);
    final reps = draft.reps.text.trim().isEmpty
        ? previous?.reps
        : int.tryParse(draft.reps.text);
    if (!timed && (weight == null || weight < 0 || weight > 1000)) {
      setState(() => _error = 'Enter a weight from 0 to 1,000.');
      return;
    }
    if (!timed && (reps == null || reps < 1 || reps > 100)) {
      setState(() => _error = 'Enter at least 1 rep.');
      return;
    }
    FocusScope.of(context).unfocus();
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
            timed ? 0 : toKg(weight!, unit),
            timed ? 1 : reps!,
            isWarmup: draft.isWarmup,
            durationSeconds: duration,
          );
      // Rest-timer persistence is secondary to logging the set. It must not
      // hold the Log button in its loading state if the server is slow.
      unawaited(
        ref
            .read(activeSessionProvider.notifier)
            .setRest(DateTime.now().toUtc().add(const Duration(seconds: 60)))
            .catchError((Object error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Set saved. Rest timer could not be saved.'),
                  ),
                );
              }
            }),
      );
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
    final timed = widget.exercise.trackingMode == ExerciseTrackingMode.timed;
    final previous = widget.exercise.previousPerformances
        .where((row) => (row.durationSeconds != null) == timed)
        .toList();
    if (zeroBasedOrder >= 0 && zeroBasedOrder < previous.length) {
      return previous[zeroBasedOrder];
    }
    final fallback = widget.exercise.previousPerformance;
    return fallback != null && (fallback.durationSeconds != null) == timed
        ? fallback
        : null;
  }

  Future<void> _edit(LoggedSet set, WeightUnit unit) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _EditSetSheet(
        set: set,
        unit: unit,
        onSave: (values) => ref
            .read(activeSessionProvider.notifier)
            .updateSet(
              set.id,
              toKg(values.weight, unit),
              values.reps,
              isWarmup: values.isWarmup,
              durationSeconds: values.durationSeconds,
            ),
      ),
    );
  }

  Future<void> _delete(LoggedSet set) async {
    if (set.pending || _deletingSetId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Delete set ${set.setOrder}?'),
        content: const Text(
          'This logged set will be removed from the workout.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Keep set'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Delete set'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _deletingSetId = set.id;
      _error = null;
    });
    try {
      await ref.read(activeSessionProvider.notifier).deleteSet(set.id);
    } on AppFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _deletingSetId = null);
    }
  }
}

class _EditSetSheet extends StatefulWidget {
  const _EditSetSheet({
    required this.set,
    required this.unit,
    required this.onSave,
  });

  final LoggedSet set;
  final WeightUnit unit;
  final Future<void> Function(
    ({double weight, int reps, int? durationSeconds, bool isWarmup}) values,
  )
  onSave;

  @override
  State<_EditSetSheet> createState() => _EditSetSheetState();
}

class _EditSetSheetState extends State<_EditSetSheet> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  late final TextEditingController _duration;
  late TimedDurationUnit _durationUnit;
  late bool _isWarmup;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final value = widget.unit == WeightUnit.lb
        ? widget.set.weightKg * 2.2046226218
        : widget.set.weightKg;
    _weight = TextEditingController(text: value.toStringAsFixed(1));
    _reps = TextEditingController(text: '${widget.set.reps}');
    _durationUnit = TimedDurationUnit.forSeconds(widget.set.durationSeconds);
    _isWarmup = widget.set.isWarmup;
    final durationValue = widget.set.durationSeconds == null
        ? null
        : _durationUnit.fromSeconds(widget.set.durationSeconds!);
    _duration = TextEditingController(
      text: durationValue == null
          ? ''
          : _durationUnit.formatValue(durationValue),
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final timed = widget.set.durationSeconds != null;
    final durationValue = double.tryParse(_duration.text);
    final duration = durationValue == null
        ? null
        : _durationUnit.toSeconds(durationValue);
    final weight = timed ? 0.0 : double.tryParse(_weight.text);
    final reps = timed ? 1 : int.tryParse(_reps.text);
    if (timed && (duration == null || duration < 1 || duration > 86400)) {
      setState(() => _error = 'Enter a duration from 1 second to 24 hours.');
      return;
    }
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
      await widget.onSave((
        weight: weight,
        reps: reps,
        durationSeconds: duration,
        isWarmup: _isWarmup,
      ));
      if (mounted) Navigator.of(context).pop();
    } on AppFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.set.durationSeconds != null)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _duration,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: 'Duration',
                      suffixText: _durationUnit.label,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<TimedDurationUnit>(
                  value: _durationUnit,
                  items: TimedDurationUnit.values
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.label),
                        ),
                      )
                      .toList(),
                  onChanged: (unit) {
                    if (unit == null || unit == _durationUnit) return;
                    final parsed = double.tryParse(_duration.text);
                    final seconds = parsed == null
                        ? null
                        : _durationUnit.toSeconds(parsed);
                    setState(() {
                      _durationUnit = unit;
                      if (seconds != null) {
                        _duration.text = _durationUnit.formatValue(
                          _durationUnit.fromSeconds(seconds),
                        );
                      }
                    });
                  },
                ),
              ],
            )
          else
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
                    decoration: InputDecoration(
                      labelText: 'Weight ($unitLabel)',
                    ),
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
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Warm-up set'),
            subtitle: const Text('Excluded from working-set progress'),
            value: _isWarmup,
            onChanged: _saving
                ? null
                : (value) => setState(() => _isWarmup = value),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save changes'),
              ),
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
    final cuteStyles = Theme.of(context).extension<CuteCustomStyles>();
    final isCute = cuteStyles != null;
    final type = widget.record.kind == PersonalRecordKind.estimatedOneRepMax
        ? 'ESTIMATED 1RM PR'
        : 'REP PR';
    final foreground = isCute
        ? palette.ink
        : ThemeData.estimateBrightnessForColor(palette.ready) == Brightness.dark
        ? Colors.white
        : palette.ink;
    return Semantics(
      liveRegion: true,
      label: '$type for ${widget.record.exerciseName}',
      child: ClipRRect(
        borderRadius: cuteStyles?.extraLargeRadius ?? BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          decoration: BoxDecoration(
            color: isCute ? null : palette.ready,
            gradient: cuteStyles?.accentGradient,
            border: Border.all(color: foreground.withValues(alpha: .26)),
            boxShadow: cuteStyles?.softShadow,
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
  _SetDraft({int? targetDurationSeconds})
    : durationUnit = TimedDurationUnit.forSeconds(targetDurationSeconds);
  bool isWarmup = false;
  TimedDurationUnit durationUnit;
  final weight = TextEditingController();
  final reps = TextEditingController();
  final duration = TextEditingController();
  final weightFocus = FocusNode();
  final repsFocus = FocusNode();
  final durationFocus = FocusNode();
  void dispose() {
    weight.dispose();
    reps.dispose();
    duration.dispose();
    weightFocus.dispose();
    repsFocus.dispose();
    durationFocus.dispose();
  }
}

class _SavedSetRow extends StatelessWidget {
  const _SavedSetRow({
    required this.set,
    required this.unit,
    required this.previous,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  final LoggedSet set;
  final WeightUnit unit;
  final PreviousPerformance? previous;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final value = set.durationSeconds == null
        ? '${displayWeight(set.weightKg, unit)} × ${set.reps}'
        : _formatTimedDuration(set.durationSeconds);
    final status = deleting
        ? 'Deleting…'
        : set.pending
        ? 'Pending sync'
        : 'Saved';
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 270;
        final statusWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              set.pending ? Icons.cloud_upload_outlined : Icons.check_circle,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(status, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        );
        final controls = <Widget>[
          if (!set.pending) ...[
            IconButton(
              tooltip: 'Edit set ${set.setOrder}',
              onPressed: deleting ? null : onEdit,
              icon: const Icon(Icons.edit_outlined, size: 19),
            ),
            IconButton(
              tooltip: 'Delete set ${set.setOrder}',
              onPressed: deleting ? null : onDelete,
              icon: const Icon(Icons.delete_outline, size: 19),
            ),
          ],
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: narrow ? 28 : 38,
                    child: Text(
                      set.setOrder.toString().padLeft(2, '0'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$value${set.isWarmup ? '  ·  Warm-up' : ''}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (!narrow) statusWidget,
                ],
              ),
              if (narrow)
                Align(alignment: Alignment.centerLeft, child: statusWidget),
              Row(
                children: [
                  if (!narrow) const SizedBox(width: 38),
                  Expanded(
                    child: Text(
                      'Previous ${set.isWarmup ? '—' : _performanceLabel(previous, unit)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (!narrow) ...controls,
                ],
              ),
              if (narrow && controls.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: controls,
                  ),
                ),
              const Divider(height: 8),
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
    required this.trackingMode,
    required this.targetDurationSeconds,
    required this.onDurationUnitChanged,
    required this.previous,
    required this.isSubmitting,
    required this.disabled,
    required this.onWarmupChanged,
    required this.onLog,
  });
  final int number;
  final _SetDraft draft;
  final WeightUnit unit;
  final ExerciseTrackingMode trackingMode;
  final int? targetDurationSeconds;
  final ValueChanged<TimedDurationUnit> onDurationUnitChanged;
  final PreviousPerformance? previous;
  final bool isSubmitting;
  final bool disabled;
  final ValueChanged<bool> onWarmupChanged;
  final VoidCallback onLog;

  String? get _weightPlaceholder => previous == null
      ? '20'
      : _number(
          unit == WeightUnit.lb
              ? previous!.weightKg * 2.2046226218
              : previous!.weightKg,
        );

  String? get _repsPlaceholder =>
      previous == null ? '8' : previous!.reps.toString();

  Widget durationInput() => Row(
    children: [
      Expanded(
        child: TransmuteTextField(
          controller: draft.duration,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          hint: targetDurationSeconds == null
              ? null
              : draft.durationUnit
                    .fromSeconds(targetDurationSeconds!)
                    .toString(),
          suffixText: draft.durationUnit.label,
          kind: TransmuteFieldKind.ledger,
          semanticLabel: 'Set $number, duration in ${draft.durationUnit.label}',
          focusNode: draft.durationFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onLog(),
        ),
      ),
      PopupMenuButton<TimedDurationUnit>(
        tooltip: 'Duration unit',
        initialValue: draft.durationUnit,
        onSelected: onDurationUnitChanged,
        itemBuilder: (context) => TimedDurationUnit.values
            .map((unit) => PopupMenuItem(value: unit, child: Text(unit.label)))
            .toList(),
        icon: const Icon(Icons.unfold_more),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    Widget weightInput() => TransmuteTextField(
      controller: draft.weight,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      hint: _weightPlaceholder,
      suffixText: unit.name,
      kind: TransmuteFieldKind.ledger,
      semanticLabel: 'Set $number, Weight (${unit.name})',
      focusNode: draft.weightFocus,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => draft.repsFocus.requestFocus(),
    );
    Widget repsInput() => TransmuteTextField(
      controller: draft.reps,
      keyboardType: TextInputType.number,
      hint: _repsPlaceholder,
      suffixText: 'reps',
      kind: TransmuteFieldKind.ledger,
      semanticLabel: 'Set $number, Reps',
      focusNode: draft.repsFocus,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onLog(),
    );
    final logButton = SizedBox(
      width: compact ? 64 : 72,
      child: ElevatedButton(
        onPressed: disabled ? null : onLog,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(compact ? 64 : 72, 48),
          padding: EdgeInsets.zero,
        ),
        child: Semantics(
          liveRegion: isSubmitting,
          label: isSubmitting ? 'Saving set $number' : 'Log set $number',
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: isSubmitting ? 0 : 1,
                child: const Text('Log', maxLines: 1, softWrap: false),
              ),
              if (isSubmitting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SET ${number.toString().padLeft(2, '0')}  ·  PREVIOUS ${draft.isWarmup ? 'Warm-up' : _performanceLabel(previous, unit)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (isSubmitting) const Text('Saving…'),
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
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
                        Expanded(
                          child: trackingMode == ExerciseTrackingMode.timed
                              ? durationInput()
                              : weightInput(),
                        ),
                      ],
                    ),
                    if (trackingMode == ExerciseTrackingMode.reps)
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
                  Expanded(
                    child: trackingMode == ExerciseTrackingMode.timed
                        ? durationInput()
                        : weightInput(),
                  ),
                  if (trackingMode == ExerciseTrackingMode.reps) ...[
                    SizedBox(width: compact ? 10 : 16),
                    Expanded(child: repsInput()),
                  ],
                  SizedBox(width: compact ? 8 : 12),
                  logButton,
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              label: const Text('Warm-up'),
              selected: draft.isWarmup,
              onSelected: disabled ? null : onWarmupChanged,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const Divider(height: 8),
        ],
      ),
    );
  }
}

String _number(double value) =>
    value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

String _performanceLabel(PreviousPerformance? performance, WeightUnit unit) {
  if (performance == null) return '—';
  if (performance.durationSeconds != null) {
    return _formatTimedDuration(performance.durationSeconds);
  }
  return '${displayWeight(performance.weightKg, unit)} × ${performance.reps}';
}

String _formatTimedDuration(int? seconds) {
  if (seconds == null) return '—';
  final hours = seconds ~/ 3600;
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  if (hours > 0) {
    final remainingMinutes = (seconds % 3600) ~/ 60;
    return remainingMinutes == 0 && remaining == 0
        ? '$hours hr'
        : '$hours hr $remainingMinutes min${remaining == 0 ? '' : ' $remaining sec'}';
  }
  if (minutes == 0) return '$remaining sec';
  return remaining == 0 ? '$minutes min' : '$minutes min $remaining sec';
}

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

class _ExerciseDemoRail extends StatefulWidget {
  const _ExerciseDemoRail({required this.exercise});
  final SessionExercise exercise;

  @override
  State<_ExerciseDemoRail> createState() => _ExerciseDemoRailState();
}

class _ExerciseDemoRailState extends State<_ExerciseDemoRail> {
  var _expanded = false;

  @override
  void didUpdateWidget(covariant _ExerciseDemoRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) => TransmutePanel(
    child: _SessionExerciseDemo(
      name: widget.exercise.name,
      url: widget.exercise.demoUrl!,
      sourceName: widget.exercise.demoSourceName,
      expanded: _expanded,
      maxVideoHeight: 360,
      onToggle: () => setState(() => _expanded = !_expanded),
    ),
  );
}

class _SessionExerciseDemo extends StatelessWidget {
  const _SessionExerciseDemo({
    required this.name,
    required this.url,
    required this.expanded,
    required this.onToggle,
    this.maxVideoHeight,
    this.sourceName,
  });
  final String name;
  final String url;
  final String? sourceName;
  final bool expanded;
  final double? maxVideoHeight;
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
            ? ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxVideoHeight ?? double.infinity,
                ),
                child: _DirectExerciseVideo(
                  name: name,
                  url: url,
                  sourceName: sourceName,
                ),
              )
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
    _controller = exerciseVideoController(widget.url);
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
  var _autoOpened = false;
  var _clearingExpired = false;
  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!mounted) return;
    final deadline = widget.session.restEndsAt;
    if (deadline != null && !deadline.isAfter(DateTime.now().toUtc())) {
      if (_clearingExpired) return;
      _clearingExpired = true;
      setState(() {
        _open = false;
        _autoOpened = false;
      });
      try {
        await ref.read(activeSessionProvider.notifier).setRest(null);
      } catch (_) {
        _clearingExpired = false;
        _showRestError();
      }
      return;
    }
    setState(() {});
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
      _autoOpened = true;
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
    final compact = MediaQuery.sizeOf(context).width < 600;
    final expanded = _open && !(compact && _autoOpened);
    return AnimatedContainer(
      duration: DesignMotion.duration(context, DesignMotion.standard),
      curve: DesignMotion.curve,
      width: expanded ? (compact ? 190 : 224) : (compact ? 180 : 112),
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
      child: expanded
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
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Minimize rest timer',
                      onPressed: () => setState(() {
                        _open = false;
                        _autoOpened = false;
                      }),
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
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
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                          ),
                          onPressed: () => _start(duration),
                          child: Text(
                            duration == 60 ? '1m' : '${duration ~/ 60}m',
                            style: TextStyle(
                              color: palette.raised,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: 40,
                      height: 44,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 44,
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
                      width: 40,
                      height: 44,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 44,
                        ),
                        tooltip: 'Reset rest timer',
                        onPressed: deadline == null
                            ? null
                            : () async {
                                if (await _saveRest(null) && mounted) {
                                  setState(() {
                                    _open = false;
                                    _autoOpened = false;
                                  });
                                }
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
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip:
                        'Open rest timer${deadline == null ? '' : ', $label remaining'}',
                    onPressed: () => setState(() {
                      _open = true;
                      _autoOpened = false;
                    }),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.timer_outlined, color: palette.gold),
                  ),
                ),
                Expanded(
                  child: Text(
                    deadline == null ? 'Rest' : label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.raised,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip: deadline == null
                        ? 'Start 60 second rest'
                        : 'Restart 60 second rest',
                    onPressed: () => _start(60),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      deadline == null ? Icons.play_arrow : Icons.restart_alt,
                      color: palette.gold,
                    ),
                  ),
                ),
              ],
            ),
    );
  }


  Future<void> _start(int seconds) async {
    _clearingExpired = false;
    setState(() {
      _open = true;
      _autoOpened = false;
    });
    await _saveRest(DateTime.now().toUtc().add(Duration(seconds: seconds)));
  }

  Future<bool> _saveRest(DateTime? deadline) async {
    try {
      await ref.read(activeSessionProvider.notifier).setRest(deadline);
      return true;
    } catch (_) {
      _showRestError();
      return false;
    }
  }

  void _showRestError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rest timer could not be saved. Try again.'),
      ),
    );
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

class BarbellPlateCalculatorDialog extends StatefulWidget {
  const BarbellPlateCalculatorDialog({
    super.key,
    required this.initialWeight,
    required this.unit,
  });

  final double initialWeight;
  final WeightUnit unit;

  @override
  State<BarbellPlateCalculatorDialog> createState() =>
      _BarbellPlateCalculatorDialogState();
}

class _BarbellPlateCalculatorDialogState
    extends State<BarbellPlateCalculatorDialog> {
  late final TextEditingController _weight;
  double _barWeight = 20.0; // standard Olympic barbell in kg (or 45 lb)

  @override
  void initState() {
    super.initState();
    _barWeight = widget.unit == WeightUnit.lb ? 45.0 : 20.0;
    _weight = TextEditingController(
      text: widget.initialWeight > 0
          ? widget.initialWeight.toStringAsFixed(1)
          : (_barWeight * 2).toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  // Standard Olympic plate denominations
  List<double> get _availablePlates => widget.unit == WeightUnit.lb
      ? const [45.0, 35.0, 25.0, 10.0, 5.0, 2.5]
      : const [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

  Map<double, int> _calculatePlatesPerSide(double targetWeight) {
    var remPerSide = (targetWeight - _barWeight) / 2.0;
    if (remPerSide <= 0) return {};

    final plates = <double, int>{};
    for (final plate in _availablePlates) {
      if (remPerSide >= plate) {
        final count = (remPerSide / plate).floor();
        plates[plate] = count;
        remPerSide -= count * plate;
      }
    }
    return plates;
  }

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    final total = double.tryParse(_weight.text.trim()) ?? 0.0;
    final platesPerSide = _calculatePlatesPerSide(total);
    final unitLabel = widget.unit == WeightUnit.lb ? 'lb' : 'kg';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.fitness_center, color: palette.oxide),
          const SizedBox(width: 8),
          const Text('Barbell Plate Math'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Total Target Weight',
                      suffixText: unitLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Barbell weight:',
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
                const Spacer(),
                SegmentedButton<double>(
                  segments: [
                    ButtonSegment(
                      value: widget.unit == WeightUnit.lb ? 45.0 : 20.0,
                      label: Text(widget.unit == WeightUnit.lb ? '45 lb' : '20 kg'),
                    ),
                    ButtonSegment(
                      value: widget.unit == WeightUnit.lb ? 35.0 : 15.0,
                      label: Text(widget.unit == WeightUnit.lb ? '35 lb' : '15 kg'),
                    ),
                  ],
                  selected: {_barWeight},
                  onSelectionChanged: (val) => setState(() => _barWeight = val.first),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'PLATES PER SIDE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 8),
            if (total < _barWeight)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Total weight is less than the empty barbell (${_barWeight.toStringAsFixed(0)} $unitLabel).',
                  style: TextStyle(color: palette.muted),
                ),
              )
            else if (platesPerSide.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Empty bar only (${_barWeight.toStringAsFixed(0)} $unitLabel). No plates required.',
                  style: TextStyle(color: palette.steel, fontWeight: FontWeight.w600),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in platesPerSide.entries)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: palette.raised,
                        border: Border.all(color: palette.oxide),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.value}× ${entry.key.toStringAsFixed(entry.key == entry.key.roundToDouble() ? 0 : 2)} $unitLabel',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: palette.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
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
