import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/models.dart';
import '../../core/domain/repositories.dart';
import '../../core/providers.dart';
import '../design_system/design_system.dart';
import '../theme/transmute_palette.dart';

/// The same canonical workout action on Today and Workout. Optional history
/// only selects the recommended day; it never decides whether Start is safe.
class WorkoutLaunchCard extends ConsumerStatefulWidget {
  const WorkoutLaunchCard({super.key});

  @override
  ConsumerState<WorkoutLaunchCard> createState() => _WorkoutLaunchCardState();
}

class _WorkoutLaunchCardState extends ConsumerState<WorkoutLaunchCard> {
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeSessionProvider);
    final entry = ref.watch(workoutEntryProvider);
    final recommendation = ref.watch(nextWorkoutRecommendationProvider);
    final palette = TransmutePalette.of(context);
    final activeSession = active.asData?.value;
    final data = entry.asData?.value;
    final next = recommendation.asData?.value;
    final selectedPlan = data?.activePlan;

    String eyebrow;
    String title;
    String detail;
    String? meta;
    String action;
    VoidCallback? onAction;
    bool showChooseDay = false;

    if (activeSession != null) {
      eyebrow = 'IN PROGRESS';
      title = activeSession.planDayName;
      detail = activeSession.planName;
      meta = '${activeSession.workingSetCount} working sets logged';
      action = 'Resume Workout';
      onAction = () => context.go('/session');
    } else if (active.isLoading) {
      eyebrow = 'CHECKING SESSION';
      title = 'Checking your workout';
      detail = 'Start will be available after we check for an active session.';
      meta = null;
      action = 'Checking…';
      onAction = null;
    } else if (active.hasError) {
      eyebrow = 'SESSION UNAVAILABLE';
      title = 'Could not check your workout';
      detail = 'Retry before starting another session.';
      meta = null;
      action = 'Retry session check';
      onAction = () => ref.read(activeSessionProvider.notifier).refresh();
    } else if (entry.isLoading) {
      eyebrow = 'YOUR TRAINING';
      title = 'Loading your plans';
      detail = 'Your next workout will appear here.';
      meta = null;
      action = 'Loading…';
      onAction = null;
    } else if (entry.hasError) {
      eyebrow = 'PLANS UNAVAILABLE';
      title = 'Could not load your plans';
      detail = 'Retry to choose a saved workout.';
      meta = null;
      action = 'Retry plans';
      onAction = () => ref.invalidate(workoutEntryProvider);
    } else if (data == null || data.plans.isEmpty) {
      eyebrow = 'READY TO BEGIN';
      title = 'Create your first routine';
      detail = 'Build a training day and it will appear here.';
      meta = null;
      action = 'Create a plan';
      onAction = () => context.go('/plans');
    } else if (selectedPlan == null) {
      eyebrow = 'CHOOSE A PLAN';
      title = 'Set an active plan';
      detail = 'Choose the routine you want to train next.';
      meta =
          '${data.plans.length} saved ${data.plans.length == 1 ? 'plan' : 'plans'}';
      action = 'Browse plans';
      onAction = () => context.go('/plans');
    } else if (selectedPlan.days.isEmpty) {
      eyebrow = 'ADD A TRAINING DAY';
      title = selectedPlan.name;
      detail = 'This plan needs a day before you can start.';
      meta = null;
      action = 'Open plan';
      onAction = () => context.go('/plans/${selectedPlan.id}');
    } else if (recommendation.isLoading ||
        recommendation.hasError ||
        next == null) {
      eyebrow = 'CHOOSE A TRAINING DAY';
      title = selectedPlan.name;
      detail = recommendation.hasError
          ? 'Your training history is unavailable. Choose a saved day to start.'
          : 'Choose a saved day while we check what is next.';
      meta =
          '${selectedPlan.days.length} saved ${selectedPlan.days.length == 1 ? 'day' : 'days'}';
      action = 'Choose day';
      onAction = () => _chooseDay(selectedPlan, null);
    } else {
      eyebrow = 'UP NEXT · ${next.plan.name.toUpperCase()}';
      title = next.day.name;
      detail = next.plan.name;
      final sets = next.day.exercises.fold<int>(
        0,
        (total, exercise) => total + exercise.targetSets,
      );
      meta =
          '$sets planned sets · ${next.day.exercises.length} ${next.day.exercises.length == 1 ? 'exercise' : 'exercises'}';
      action = 'Start Workout';
      onAction = () => _start(next.plan, next.day);
      showChooseDay = true;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      color: palette.raised,
      shape: DesignTokens.of(context).shape(palette.divider),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(palette.raised, palette.oxide, 0.20)!,
              palette.raised,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.fitness_center, size: 18, color: palette.oxide),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      eyebrow,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  if (active.isLoading || entry.isLoading)
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ExcludeSemantics(
                    child: Opacity(
                      opacity: 0.25,
                      child: SvgPicture.asset(
                        'assets/transmute/ouroboros.svg',
                        width: 58,
                        height: 58,
                        colorFilter: ColorFilter.mode(
                          palette.oxide,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (meta != null) ...[
                const SizedBox(height: 14),
                Text(
                  meta,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TransmuteButton(
                    label: action,
                    icon: activeSession != null
                        ? Icons.play_arrow
                        : Icons.arrow_forward,
                    loading: _starting,
                    onPressed: _starting ? null : onAction,
                  ),
                  if (showChooseDay && !_starting && selectedPlan != null)
                    TextButton(
                      onPressed: () => _chooseDay(selectedPlan, next?.day.id),
                      child: const Text('Choose another day'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseDay(WorkoutPlan plan, String? recommendedDayId) async {
    final choice = await showModalBottomSheet<WorkoutPlanDay>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Choose a training day',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(plan.name, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                for (final day in plan.days)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(day.name),
                    subtitle: Text(
                      '${day.exercises.fold<int>(0, (sum, exercise) => sum + exercise.targetSets)} sets · ${day.exercises.length} exercises${day.id == recommendedDayId ? ' · Up next' : ''}',
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Navigator.of(sheetContext).pop(day),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.go('/plans');
                  },
                  child: const Text('Browse all plans'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (choice != null && mounted) await _start(plan, choice);
  }

  Future<void> _start(WorkoutPlan plan, WorkoutPlanDay day) async {
    if (_starting) return;
    setState(() => _starting = true);
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
      if (mounted) setState(() => _starting = false);
    }
  }
}
