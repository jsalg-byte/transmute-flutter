import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_shell.dart';

class PlanListScreen extends ConsumerWidget {
  const PlanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    final active = ref.watch(activeSessionProvider);
    return AppShell(
      title: 'Workout plans',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Workout plans',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _newPlan(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New plan'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          active.when(
            data: (session) => session == null
                ? const SizedBox()
                : Card(
                    child: ListTile(
                      leading: const Icon(Icons.play_circle_fill),
                      title: Text(
                        '${session.planName} · ${session.planDayName} is in progress',
                      ),
                      subtitle: const Text(
                        'One active workout is preserved for you.',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => context.go('/session'),
                        child: const Text('Resume'),
                      ),
                    ),
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: plans.when(
              data: (items) => _PlanList(items: items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _Error(
                message: 'Unable to load workout plans.',
                onRetry: () => ref.invalidate(plansProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _newPlan(BuildContext context, WidgetRef ref) async {
    final request = await showDialog<_PlanCreation>(
      context: context,
      builder: (_) => const _PlanCreationDialog(),
    );
    if (request == null) return;
    try {
      final plan = request.draft == null
          ? await ref
                .read(planRepositoryProvider)
                .createPlan(request.name!, description: request.description)
          : await ref
                .read(planRepositoryProvider)
                .importAiWorkoutPlan(request.draft!);
      ref.invalidate(plansProvider);
      if (context.mounted) context.go('/plans/${plan.id}');
    } on AppFailure catch (error) {
      if (context.mounted) _notice(context, error.message);
    }
  }
}

class _PlanCreation {
  const _PlanCreation.manual(this.name, this.description) : draft = null;
  const _PlanCreation.draft(this.draft) : name = null, description = null;
  final String? name;
  final String? description;
  final AiWorkoutPlanDraft? draft;
}

class _PlanCreationDialog extends ConsumerStatefulWidget {
  const _PlanCreationDialog();
  @override
  ConsumerState<_PlanCreationDialog> createState() =>
      _PlanCreationDialogState();
}

class _PlanCreationDialogState extends ConsumerState<_PlanCreationDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _prompt = TextEditingController();
  bool _assistant = false;
  bool _generating = false;
  String? _error;
  AiWorkoutPlanDraft? _draft;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_assistant ? 'Plan assistant' : 'New workout plan'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: _assistant
            ? _assistantContent(context)
            : _manualContent(context),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      if (!_assistant)
        ElevatedButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.length < 2) {
              setState(
                () => _error = 'Enter a plan name with at least 2 characters.',
              );
              return;
            }
            Navigator.pop(
              context,
              _PlanCreation.manual(name, _description.text.trim()),
            );
          },
          child: const Text('Create'),
        )
      else if (_draft != null)
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _PlanCreation.draft(_draft!)),
          child: const Text('Add this plan'),
        ),
    ],
  );

  Widget _manualContent(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextField(
        controller: _name,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Plan name'),
      ),
      TextField(
        controller: _description,
        decoration: const InputDecoration(labelText: 'Description (optional)'),
      ),
      const SizedBox(height: 16),
      const Text(
        'Describe your training goal, days, equipment, and limits. Review the generated plan before it is added.',
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _assistant = true;
            _error = null;
          }),
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Plan with AI'),
        ),
      ),
      if (_error != null) _DialogError(message: _error!),
    ],
  );

  Widget _assistantContent(BuildContext context) {
    if (_draft != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_draft!.name, style: Theme.of(context).textTheme.titleLarge),
          if (_draft!.description != null) Text(_draft!.description!),
          for (final day in _draft!.days) ...[
            const SizedBox(height: 12),
            Text(day.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            for (final exercise in day.exercises)
              Text(
                '${exercise.exerciseName} · ${exercise.targetSets} × ${exercise.targetReps ?? '—'}${exercise.targetWeightKg == null ? '' : ' at ${exercise.targetWeightKg} kg'}',
              ),
          ],
          TextButton(
            onPressed: () => setState(() => _draft = null),
            child: const Text('Start over'),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _prompt,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'What training do you want?',
            hintText:
                'Three days, dumbbells and a bench; build strength without aggravating my knee.',
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _generating ? null : _generate,
          child: Text(_generating ? 'Building plan…' : 'Generate plan'),
        ),
        TextButton(
          onPressed: _generating
              ? null
              : () => setState(() {
                  _assistant = false;
                  _error = null;
                }),
          child: const Text('Build manually'),
        ),
        if (_error != null) _DialogError(message: _error!),
      ],
    );
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final draft = await ref
          .read(planRepositoryProvider)
          .generateAiWorkoutDraft(_prompt.text.trim());
      if (mounted) setState(() => _draft = draft);
    } on AppFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

class _DialogError extends StatelessWidget {
  const _DialogError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}

class _PlanList extends StatelessWidget {
  const _PlanList({required this.items});
  final List<WorkoutPlan> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty)
      return const Center(
        child: Text('Create a plan to start building your next session.'),
      );
    return LayoutBuilder(
      builder: (context, box) {
        final count = box.maxWidth >= 900
            ? 3
            : box.maxWidth >= 560
            ? 2
            : 1;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: items.length,
          itemBuilder: (_, index) {
            final plan = items[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        plan.description ??
                            'A repeatable training prescription.',
                      ),
                    ),
                    Text(
                      '${plan.days.length} training days · ${plan.exerciseCount} exercises',
                      style: const TextStyle(color: Color(0xff605D63)),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: () => context.go('/plans/${plan.id}'),
                        child: const Text('Open plan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});
  final String planId;
  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  String? _dayId;
  bool _editing = false;
  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planProvider(widget.planId));
    final active = ref.watch(activeSessionProvider).value;
    return AppShell(
      title: 'Plan details',
      child: plan.when(
        data: (value) {
          if (value.days.isNotEmpty &&
              !value.days.any((day) => day.id == _dayId))
            _dayId = value.days.first.id;
          final day = value.days
              .where((candidate) => candidate.id == _dayId)
              .cast<WorkoutPlanDay?>()
              .firstOrNull;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/plans'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('All plans'),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit plan',
                    onPressed: () => setState(() => _editing = !_editing),
                    icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
                  ),
                ],
              ),
              if (value.description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(value.description!),
                ),
              if (_editing) _PlanActions(plan: value, refresh: _refresh),
              const SizedBox(height: 12),
              if (value.days.isEmpty)
                Expanded(
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _addDay(value),
                      icon: const Icon(Icons.add),
                      label: const Text('Add first training day'),
                    ),
                  ),
                )
              else ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in value.days)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(item.name),
                            selected: item.id == _dayId,
                            onSelected: (_) => setState(() => _dayId = item.id),
                          ),
                        ),
                      if (_editing)
                        ActionChip(
                          avatar: const Icon(Icons.add),
                          label: const Text('Add day'),
                          onPressed: () => _addDay(value),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (day != null)
                  Expanded(
                    child: _DayEditor(
                      plan: value,
                      day: day,
                      editing: _editing,
                      active: active,
                      refresh: _refresh,
                      start: () => _start(value, day),
                    ),
                  ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _Error(message: 'This plan could not be found.', onRetry: _refresh),
      ),
    );
  }

  void _refresh() {
    ref.invalidate(plansProvider);
    ref.invalidate(planProvider(widget.planId));
  }

  Future<void> _addDay(WorkoutPlan plan) async {
    final name = await _textDialog(
      context,
      title: 'Add training day',
      label: 'Day name',
      action: 'Add',
    );
    if (name == null) return;
    try {
      final day = await ref.read(planRepositoryProvider).addDay(plan.id, name);
      setState(() => _dayId = day.id);
      _refresh();
    } on AppFailure catch (error) {
      if (mounted) _notice(context, error.message);
    }
  }

  Future<void> _start(WorkoutPlan plan, WorkoutPlanDay day) async {
    try {
      await ref.read(activeSessionProvider.notifier).start(plan.id, day.id);
      if (mounted) context.go('/session');
    } on AppFailure catch (error) {
      if (mounted) _notice(context, error.message);
    }
  }
}

class _PlanActions extends ConsumerWidget {
  const _PlanActions({required this.plan, required this.refresh});
  final WorkoutPlan plan;
  final VoidCallback refresh;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final name = await _textDialog(
                context,
                title: 'Rename plan',
                label: 'Plan name',
                initial: plan.name,
                action: 'Save',
              );
              if (name == null) return;
              try {
                await ref
                    .read(planRepositoryProvider)
                    .renamePlan(plan.id, name);
                refresh();
              } on AppFailure catch (error) {
                if (context.mounted) _notice(context, error.message);
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Rename'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final yes = await _confirm(
                context,
                'Delete this plan?',
                'Completed workout evidence stays intact. An active plan cannot be deleted.',
              );
              if (!yes) return;
              try {
                await ref.read(planRepositoryProvider).deletePlan(plan.id);
                ref.invalidate(plansProvider);
                if (context.mounted) context.go('/plans');
              } on AppFailure catch (error) {
                if (context.mounted) _notice(context, error.message);
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    ),
  );
}

class _DayEditor extends ConsumerWidget {
  const _DayEditor({
    required this.plan,
    required this.day,
    required this.editing,
    required this.active,
    required this.refresh,
    required this.start,
  });
  final WorkoutPlan plan;
  final WorkoutPlanDay day;
  final bool editing;
  final WorkoutSession? active;
  final VoidCallback refresh;
  final Future<void> Function() start;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              day.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (editing)
            IconButton(
              tooltip: 'Rename day',
              onPressed: () => _renameDay(context, ref),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (editing)
            IconButton(
              tooltip: 'Delete day',
              onPressed: () => _deleteDay(context, ref),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      const SizedBox(height: 8),
      if (day.exercises.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No exercises yet. Add movements from the library to form this day.',
            ),
          ),
        ),
      ...day.exercises.map(
        (entry) => _PrescriptionCard(
          plan: plan,
          day: day,
          entry: entry,
          editing: editing,
          refresh: refresh,
        ),
      ),
      if (editing)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton.icon(
            onPressed: () => _addExercise(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add exercise from library'),
          ),
        ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: active == null ? start : () => context.go('/session'),
          icon: Icon(active == null ? Icons.play_arrow : Icons.fitness_center),
          label: Text(active == null ? 'Start ${day.name}' : 'Resume workout'),
        ),
      ),
    ],
  );
  Future<void> _renameDay(BuildContext context, WidgetRef ref) async {
    final name = await _textDialog(
      context,
      title: 'Rename training day',
      label: 'Day name',
      initial: day.name,
      action: 'Save',
    );
    if (name == null) return;
    try {
      await ref.read(planRepositoryProvider).renameDay(plan.id, day.id, name);
      refresh();
    } on AppFailure catch (error) {
      if (context.mounted) _notice(context, error.message);
    }
  }

  Future<void> _deleteDay(BuildContext context, WidgetRef ref) async {
    if (!await _confirm(
      context,
      'Delete ${day.name}?',
      'This removes its prescriptions from the plan.',
    ))
      return;
    try {
      await ref.read(planRepositoryProvider).deleteDay(plan.id, day.id);
      refresh();
    } on AppFailure catch (error) {
      if (context.mounted) _notice(context, error.message);
    }
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final selection = await showDialog<_ExerciseSelection>(
      context: context,
      builder: (_) => const _ExercisePicker(),
    );
    if (selection == null) return;
    try {
      if (selection.exercise != null) {
        await ref
            .read(planRepositoryProvider)
            .addExerciseToDay(plan.id, day.id, selection.exercise!.id);
      } else {
        await ref
            .read(planRepositoryProvider)
            .importCalistreeExerciseToDay(
              plan.id,
              day.id,
              selection.catalog!.slug,
            );
      }
      refresh();
    } on AppFailure catch (error) {
      if (context.mounted) _notice(context, error.message);
    }
  }
}

class _PrescriptionCard extends ConsumerWidget {
  const _PrescriptionCard({
    required this.plan,
    required this.day,
    required this.entry,
    required this.editing,
    required this.refresh,
  });
  final WorkoutPlan plan;
  final WorkoutPlanDay day;
  final PlanExercise entry;
  final bool editing;
  final VoidCallback refresh;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: ListTile(
      onTap: () =>
          _showExerciseDetail(context, ref, entry.exercise, onSaved: refresh),
      title: Text(entry.exercise.name),
      subtitle: Text(
        '${entry.exercise.muscleGroup ?? entry.exercise.category} · ${entry.targetSets} × ${entry.targetReps}${entry.targetWeightKg == null ? '' : ' at ${displayWeight(entry.targetWeightKg!, WeightUnit.lb)}'}${entry.previousPerformance == null ? '' : '\nPrevious: ${displayWeight(entry.previousPerformance!.weightKg, WeightUnit.lb)} × ${entry.previousPerformance!.reps}'}',
      ),
      trailing: editing
          ? Wrap(
              children: [
                IconButton(
                  tooltip: 'Edit prescription',
                  icon: const Icon(Icons.tune),
                  onPressed: () => _edit(context, ref),
                ),
                IconButton(
                  tooltip: 'Remove from day',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () async {
                    try {
                      await ref
                          .read(planRepositoryProvider)
                          .removeExerciseFromDay(plan.id, day.id, entry.id);
                      refresh();
                    } on AppFailure catch (error) {
                      if (context.mounted) _notice(context, error.message);
                    }
                  },
                ),
              ],
            )
          : const Icon(Icons.info_outline),
    ),
  );
  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await _prescriptionDialog(context, entry);
    if (result == null) return;
    try {
      await ref
          .read(planRepositoryProvider)
          .updatePrescription(
            plan.id,
            day.id,
            entry.id,
            targetSets: result.sets,
            targetReps: result.reps,
            targetWeightKg: result.weight,
          );
      refresh();
    } on AppFailure catch (error) {
      if (context.mounted) _notice(context, error.message);
    }
  }
}

class _ExercisePicker extends ConsumerStatefulWidget {
  const _ExercisePicker();
  @override
  ConsumerState<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExerciseSelection {
  const _ExerciseSelection.exercise(this.exercise) : catalog = null;
  const _ExerciseSelection.catalog(this.catalog) : exercise = null;
  final Exercise? exercise;
  final CatalogExercise? catalog;
}

class _ExercisePickerState extends ConsumerState<_ExercisePicker> {
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
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _query,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Search exercises'),
            ),
            const SizedBox(height: 8),
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
                        trailing: IconButton(
                          tooltip: 'Exercise details',
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showExerciseDetail(
                            context,
                            ref,
                            item,
                            onSaved: () => ref.invalidate(
                              exerciseSearchProvider(_query.text),
                            ),
                          ),
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          _ExerciseSelection.exercise(item),
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
                              _ExerciseSelection.catalog(item),
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
                error: (_, _) =>
                    const Center(child: Text('Library unavailable.')),
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

Future<void> _showExerciseDetail(
  BuildContext context,
  WidgetRef ref,
  Exercise exercise, {
  VoidCallback? onSaved,
}) async {
  final url = exercise.demoUrl;
  final action = await showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(exercise.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.muscleGroup ?? 'Muscle group not specified'),
          const SizedBox(height: 6),
          Text('Category: ${exercise.category}'),
          const SizedBox(height: 16),
          Text(
            url == null
                ? 'No demonstration is available for this movement.'
                : 'Demonstration available${exercise.demoSourceName == null ? '' : ' from ${exercise.demoSourceName}'}.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, 'close'),
          child: const Text('Close'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.pop(dialog, 'edit'),
          icon: const Icon(Icons.edit_outlined),
          label: Text(url == null ? 'Attach demo' : 'Replace demo'),
        ),
        if (url != null)
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialog, 'watch'),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Watch demonstration'),
          ),
      ],
    ),
  );
  if (action == 'edit') {
    final demo = await _demoDialog(context, exercise);
    if (demo == null || !context.mounted) return;
    try {
      await ref
          .read(planRepositoryProvider)
          .updateExerciseDemo(
            exercise.id,
            demoUrl: demo.url,
            sourceName: demo.sourceName,
          );
      onSaved?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise demonstration saved.')),
        );
      }
    } on AppFailure catch (error) {
      if (context.mounted) _notice(context, error.message);
    }
    return;
  }
  if (action != 'watch' || url == null || !context.mounted) return;
  final launched = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The exercise demonstration could not be opened.'),
      ),
    );
  }
}

Future<({String url, String? sourceName})?> _demoDialog(
  BuildContext context,
  Exercise exercise,
) async {
  final url = TextEditingController(text: exercise.demoUrl);
  final source = TextEditingController(text: exercise.demoSourceName);
  final form = GlobalKey<FormState>();
  final result = await showDialog<({String url, String? sourceName})>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(
        exercise.demoUrl == null
            ? 'Attach demonstration'
            : 'Replace demonstration',
      ),
      content: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Public demo URL'),
              validator: (value) {
                final parsed = Uri.tryParse(value?.trim() ?? '');
                if (parsed == null ||
                    !(parsed.scheme == 'http' || parsed.scheme == 'https') ||
                    parsed.host.isEmpty) {
                  return 'Enter a public http(s) URL.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: source,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Source name (optional)',
              ),
              validator: (value) =>
                  value != null &&
                      value.trim().isNotEmpty &&
                      value.trim().length < 2
                  ? 'Use at least 2 characters.'
                  : null,
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
            if (!(form.currentState?.validate() ?? false)) return;
            Navigator.pop(dialog, (
              url: url.text.trim(),
              sourceName: source.text.trim().isEmpty
                  ? null
                  : source.text.trim(),
            ));
          },
          child: const Text('Save demo'),
        ),
      ],
    ),
  );
  url.dispose();
  source.dispose();
  return result;
}

Future<String?> _textDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String action,
  String? initial,
}) async {
  final controller = TextEditingController(text: initial);
  final value = await showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) Navigator.pop(dialog, value);
          },
          child: Text(action),
        ),
      ],
    ),
  );
  controller.dispose();
  return value;
}

Future<bool> _confirm(BuildContext context, String title, String body) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ??
    false;
void _notice(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));
Future<({int sets, int reps, double? weight})?> _prescriptionDialog(
  BuildContext context,
  PlanExercise entry,
) async {
  final sets = TextEditingController(text: '${entry.targetSets}');
  final reps = TextEditingController(text: '${entry.targetReps}');
  final weight = TextEditingController(
    text: entry.targetWeightKg?.toString() ?? '',
  );
  final result = await showDialog<({int sets, int reps, double? weight})>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text('Edit ${entry.exercise.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: sets,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Sets'),
          ),
          TextField(
            controller: reps,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Target reps'),
          ),
          TextField(
            controller: weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Target weight (kg, optional)',
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
            final s = int.tryParse(sets.text);
            final r = int.tryParse(reps.text);
            final w = weight.text.trim().isEmpty
                ? null
                : double.tryParse(weight.text);
            if (s != null && r != null && (w == null || w >= 0))
              Navigator.pop(dialog, (sets: s, reps: r, weight: w));
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  sets.dispose();
  reps.dispose();
  weight.dispose();
  return result;
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    ),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
