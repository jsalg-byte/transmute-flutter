import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
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

class _SessionBody extends ConsumerWidget {
  const _SessionBody({required this.session});
  final WorkoutSession session;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = session.exercises
        .expand((exercise) => exercise.sets)
        .where((set) => set.pending)
        .length;
    final cards = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: session.exercises.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ExerciseCard(exercise: session.exercises[i]),
    );
    final sidebar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RestTimer(session: session),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _chooseExercise(context, ref, session),
          icon: const Icon(Icons.add),
          label: const Text('Add exercise'),
        ),
        const SizedBox(height: 8),
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
    return LayoutBuilder(
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.planName,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Started ${_time(session.startedAt)} · ${session.workingSetCount} working sets',
          ),
          if (pendingCount > 0) ...[
            const SizedBox(height: 12),
            _PendingSyncBanner(pendingCount: pendingCount),
          ],
          const SizedBox(height: 16),
          if (box.maxWidth >= 1024)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: SingleChildScrollView(child: cards)),
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
                children: [cards, const SizedBox(height: 16), sidebar],
              ),
            ),
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
}

class _ExerciseCard extends ConsumerStatefulWidget {
  const _ExerciseCard({required this.exercise});
  final SessionExercise exercise;
  @override
  ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
  final _weight = TextEditingController();
  final _reps = TextEditingController();
  String? _error;
  bool _saving = false;
  bool _warmup = false;
  bool _demoExpanded = false;
  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit =
        ref.watch(authControllerProvider).user?.weightUnit ?? WeightUnit.kg;
    final exercise = widget.exercise;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              const SizedBox(height: 8),
              _SessionExerciseDemo(
                name: exercise.name,
                url: exercise.demoUrl!,
                sourceName: exercise.demoSourceName,
                expanded: _demoExpanded,
                onToggle: () => setState(() => _demoExpanded = !_demoExpanded),
              ),
            ],
            if (exercise.previousPerformance != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Previous: ${displayWeight(exercise.previousPerformance!.weightKg, unit)} × ${exercise.previousPerformance!.reps}',
                  style: const TextStyle(color: Color(0xff605D63)),
                ),
              ),
            const SizedBox(height: 10),
            ...exercise.sets.map(
              (set) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  child: Text('${set.setOrder}'),
                ),
                title: Text(
                  '${displayWeight(set.weightKg, unit)} × ${set.reps}',
                ),
                subtitle: set.pending
                    ? Text(
                        set.isWarmup
                            ? 'Warm-up · saved on this device, waiting to sync'
                            : 'Saved on this device, waiting to sync',
                      )
                    : set.isWarmup
                    ? const Text('Warm-up set')
                    : null,
                trailing: set.pending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
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
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Weight (${unit.name})',
                      errorText: _error,
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Warm-up'),
                  selected: _warmup,
                  onSelected: _saving
                      ? null
                      : (value) => setState(() => _warmup = value),
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _reps,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _saving ? null : _add,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Complete set'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add() async {
    final weight = double.tryParse(_weight.text);
    final reps = int.tryParse(_reps.text);
    if (weight == null ||
        weight < 0 ||
        weight > 1000 ||
        reps == null ||
        reps < 1 ||
        reps > 100) {
      setState(() => _error = 'Enter valid weight and 1–100 reps.');
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
            isWarmup: _warmup,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${submission.personalRecord!.kind == PersonalRecordKind.estimatedOneRepMax ? 'Estimated 1RM' : 'Rep'} personal record: ${submission.personalRecord!.exerciseName}',
            ),
          ),
        );
      }
      _weight.clear();
      _reps.clear();
      setState(() => _warmup = false);
    } on AppFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit(LoggedSet set, WeightUnit unit) async {
    final weight = TextEditingController(
      text: (unit == WeightUnit.lb ? set.weightKg * 2.2046226218 : set.weightKg)
          .toStringAsFixed(1),
    );
    final reps = TextEditingController(text: '${set.reps}');
    var isWarmup = set.isWarmup;
    final values = await showDialog<({double weight, int reps, bool isWarmup})>(
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
            StatefulBuilder(
              builder: (context, update) => CheckboxListTile(
                value: isWarmup,
                contentPadding: EdgeInsets.zero,
                title: const Text('Warm-up set'),
                onChanged: (value) => update(() => isWarmup = value ?? false),
              ),
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
                Navigator.pop(dialog, (weight: w, reps: r, isWarmup: isWarmup));
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
            isWarmup: values.isWarmup,
          );
    } on AppFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }
}

class _PendingSyncBanner extends ConsumerWidget {
  const _PendingSyncBanner({required this.pendingCount});
  final int pendingCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$pendingCount ${pendingCount == 1 ? 'set is' : 'sets are'} saved on this device and waiting to sync.',
            ),
          ),
          TextButton(
            onPressed: () async {
              final report = await ref
                  .read(activeSessionProvider.notifier)
                  .syncPending();
              if (context.mounted) {
                final message = report.synced.isNotEmpty
                    ? '${report.synced.length} pending ${report.synced.length == 1 ? 'set' : 'sets'} synced.'
                    : 'Still offline or the workout needs attention before these sets can sync.';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
            child: const Text('Sync now'),
          ),
        ],
      ),
    ),
  );
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
  Widget build(BuildContext context) {
    final deadline = widget.session.restEndsAt;
    final seconds = deadline == null
        ? 0
        : deadline.difference(DateTime.now().toUtc()).inSeconds.clamp(0, 600);
    final label =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REST TIMER',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final duration in [60, 90, 120])
                  OutlinedButton(
                    onPressed: () => ref
                        .read(activeSessionProvider.notifier)
                        .setRest(
                          DateTime.now().toUtc().add(
                            Duration(seconds: duration),
                          ),
                        ),
                    child: Text(
                      '${duration ~/ 60}:${(duration % 60).toString().padLeft(2, '0')}',
                    ),
                  ),
                OutlinedButton(onPressed: _custom, child: const Text('Custom')),
                TextButton(
                  onPressed: deadline == null
                      ? null
                      : () => ref
                            .read(activeSessionProvider.notifier)
                            .setRest(null),
                  child: const Text('Pause / reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
    if (seconds != null)
      await ref
          .read(activeSessionProvider.notifier)
          .setRest(DateTime.now().toUtc().add(Duration(seconds: seconds)));
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
