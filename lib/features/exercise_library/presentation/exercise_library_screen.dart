import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_shell.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});
  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _query = TextEditingController();
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(exerciseSearchProvider(_query.text));
    return AppShell(
      title: 'Exercise library',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Exercise library',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Search your exercise library',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(exerciseSearchProvider(_query.text)),
                  child: const Text('Retry library'),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const Center(
                      child: Text(
                        'No exercises yet. Create a movement to use it in a plan.',
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, box) {
                        final columns = box.maxWidth >= 900
                            ? 3
                            : box.maxWidth >= 560
                            ? 2
                            : 1;
                        return GridView.builder(
                          itemCount: items.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: columns == 1 ? 2.8 : 1.5,
                              ),
                          itemBuilder: (_, index) =>
                              _ExerciseTile(exercise: items[index]),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    final name = TextEditingController();
    final muscle = TextEditingController();
    var category = 'strength';
    final result =
        await showDialog<({String name, String category, String? muscle})>(
          context: context,
          builder: (dialog) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
              title: const Text('Create exercise'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Exercise name',
                      ),
                    ),
                    TextField(
                      controller: muscle,
                      decoration: const InputDecoration(
                        labelText: 'Muscle group (optional)',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        DropdownMenuItem(
                          value: 'strength',
                          child: Text('Strength'),
                        ),
                        DropdownMenuItem(
                          value: 'cardio',
                          child: Text('Cardio'),
                        ),
                        DropdownMenuItem(
                          value: 'mobility',
                          child: Text('Mobility'),
                        ),
                      ],
                      onChanged: (value) => update(() => category = value!),
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
                    final value = name.text.trim();
                    if (value.length < 2) return;
                    Navigator.pop(dialog, (
                      name: value,
                      category: category,
                      muscle: muscle.text.trim().isEmpty
                          ? null
                          : muscle.text.trim(),
                    ));
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        );
    name.dispose();
    muscle.dispose();
    if (result == null) return;
    try {
      await ref
          .read(planRepositoryProvider)
          .createExercise(
            name: result.name,
            category: result.category,
            muscleGroup: result.muscle,
          );
      ref.invalidate(exerciseSearchProvider(_query.text));
    } on AppFailure catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise});
  final Exercise exercise;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(exercise.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${exercise.category} · ${exercise.muscleGroup ?? 'Muscle group not specified'}',
              ),
              const SizedBox(height: 12),
              if (exercise.demoUrl == null)
                const Text('No demonstration is available for this movement.')
              else
                _LibraryDemo(
                  name: exercise.name,
                  url: exercise.demoUrl!,
                  sourceName: exercise.demoSourceName,
                ),
            ],
          ),
          actions: [
            if (exercise.demoUrl != null)
              TextButton(
                onPressed: () async {
                  final opened = await launchUrl(
                    Uri.parse(exercise.demoUrl!),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('The demonstration could not be opened.'),
                      ),
                    );
                },
                child: const Text('Open demonstration'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              '${exercise.category} · ${exercise.muscleGroup ?? 'Unspecified'}',
            ),
            const Spacer(),
            Text(
              exercise.demoUrl == null
                  ? 'Demo unavailable'
                  : 'Demonstration available',
            ),
          ],
        ),
      ),
    ),
  );
}

class _LibraryDemo extends StatefulWidget {
  const _LibraryDemo({required this.name, required this.url, this.sourceName});
  final String name;
  final String url;
  final String? sourceName;
  @override
  State<_LibraryDemo> createState() => _LibraryDemoState();
}

class _LibraryDemoState extends State<_LibraryDemo> {
  VideoPlayerController? _controller;
  String? _error;
  bool get _directVideo {
    final uri = Uri.tryParse(widget.url);
    return uri != null &&
        (uri.path.toLowerCase().endsWith('.mp4') ||
            uri.host.toLowerCase().endsWith('firebasestorage.googleapis.com'));
  }

  @override
  void initState() {
    super.initState();
    if (_directVideo) _load();
  }

  Future<void> _load() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.setLooping(true);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted)
        setState(() => _error = 'The demonstration could not be loaded.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_directVideo) {
      return Text(
        'Demonstration available${widget.sourceName == null ? '.' : ' from ${widget.sourceName}.'}',
      );
    }
    if (_error != null) return Text(_error!);
    final controller = _controller;
    if (controller == null)
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    return Semantics(
      label: '${widget.name} movement demonstration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          IconButton(
            tooltip: controller.value.isPlaying ? 'Pause demo' : 'Play demo',
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () => setState(() {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
            }),
          ),
        ],
      ),
    );
  }
}
