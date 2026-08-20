import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../shared/theme/transmute_palette.dart';
import '../../../shared/widgets/app_shell.dart';

/// Body-led exercise discovery. The muscle groups are display groupings over
/// the documented [Exercise.muscleGroup] metadata; no catalog fields or
/// exercise records are modified here.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _query = TextEditingController();
  String? _selectedGroup;

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
          Text(
            'Exercise library',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a muscle group to find movements and their available demonstrations.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Search exercises',
              hintText: 'Search by movement name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _query.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: results.when(
              loading: () => const _LibraryLoading(),
              error: (_, __) => _LibraryError(
                onRetry: () =>
                    ref.invalidate(exerciseSearchProvider(_query.text)),
              ),
              data: (exercises) => _LibraryContent(
                exercises: exercises,
                query: _query.text.trim(),
                selectedGroup: _selectedGroup,
                onGroupSelected: (group) =>
                    setState(() => _selectedGroup = group),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({
    required this.exercises,
    required this.query,
    required this.selectedGroup,
    required this.onGroupSelected,
  });
  final List<Exercise> exercises;
  final String query;
  final String? selectedGroup;
  final ValueChanged<String?> onGroupSelected;

  @override
  Widget build(BuildContext context) {
    final matched = exercises
        .where(
          (exercise) =>
              query.isEmpty ||
              exercise.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    final availableGroups = _knownGroups
        .where(
          (group) => matched.any((exercise) => exercise.muscleGroup == group),
        )
        .toSet();
    final groups = [
      ..._knownGroups.where(availableGroups.contains),
      ...matched
          .map((exercise) => exercise.muscleGroup)
          .whereType<String>()
          .where((group) => !_knownGroups.contains(group))
          .toSet()
          .toList()
        ..sort(),
    ];
    final activeGroup = selectedGroup != null && groups.contains(selectedGroup)
        ? selectedGroup
        : null;
    final visible = activeGroup == null
        ? matched
        : matched
              .where((exercise) => exercise.muscleGroup == activeGroup)
              .toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _BodyMusclePicker(
            availableGroups: availableGroups,
            selectedGroup: activeGroup,
            onSelected: onGroupSelected,
          ),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: 24)),
        if (matched.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: _EmptySearch(),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: _ResultsHeading(
              group: activeGroup,
              movementCount: visible.length,
              query: query,
              onClearGroup: activeGroup == null
                  ? null
                  : () => onGroupSelected(null),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 8)),
          SliverList.separated(
            itemCount: visible.length,
            itemBuilder: (context, index) => _ExerciseAccordion(
              key: ValueKey(visible[index].id),
              exercise: visible[index],
            ),
            separatorBuilder: (_, _) => const SizedBox(height: 8),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ],
    );
  }
}

class _BodyMusclePicker extends StatelessWidget {
  const _BodyMusclePicker({
    required this.availableGroups,
    required this.selectedGroup,
    required this.onSelected,
  });
  final Set<String> availableGroups;
  final String? selectedGroup;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final anatomy = _Anatomy(
              selectedGroup: selectedGroup,
              availableGroups: availableGroups,
              onSelected: onSelected,
            );
            final controls = _MuscleGroupControls(
              selectedGroup: selectedGroup,
              availableGroups: availableGroups,
              onSelected: onSelected,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Start with the body',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a highlighted group to show its movements below.',
                  style: TextStyle(color: palette.muted),
                ),
                const SizedBox(height: 16),
                if (compact) ...[
                  Center(child: anatomy),
                  const SizedBox(height: 16),
                  controls,
                ] else
                  Row(
                    children: [
                      Expanded(child: Center(child: anatomy)),
                      const SizedBox(width: 24),
                      Expanded(child: controls),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Anatomy extends StatelessWidget {
  const _Anatomy({
    required this.selectedGroup,
    required this.availableGroups,
    required this.onSelected,
  });
  final String? selectedGroup;
  final Set<String> availableGroups;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return Semantics(
      label: selectedGroup == null
          ? 'Front and back muscle anatomy. Choose a muscle group below.'
          : '$selectedGroup selected in the anatomy.',
      child: SizedBox(
        height: 260,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BodySide(
              asset: 'assets/transmute/muscle-front.svg',
              label: 'Front body',
              color: _anatomyColor(palette),
              hotspots: const [
                _HotspotSpec('Shoulders', .16, .10),
                _HotspotSpec('Chest', .50, .25),
                _HotspotSpec('Arms', .14, .39),
                _HotspotSpec('Core', .50, .47),
                _HotspotSpec('Quads', .50, .67),
              ],
              availableGroups: availableGroups,
              selectedGroup: selectedGroup,
              onSelected: onSelected,
            ),
            const SizedBox(width: 8),
            _BodySide(
              asset: 'assets/transmute/muscle-back.svg',
              label: 'Back body',
              color: _anatomyColor(palette),
              hotspots: const [
                _HotspotSpec('Shoulders', .50, .10),
                _HotspotSpec('Back', .50, .29),
                _HotspotSpec('Arms', .87, .39),
                _HotspotSpec('Hamstrings', .50, .67),
                _HotspotSpec('Calves', .50, .88),
              ],
              availableGroups: availableGroups,
              selectedGroup: selectedGroup,
              onSelected: onSelected,
            ),
          ],
        ),
      ),
    );
  }

  Color _anatomyColor(TransmutePalette palette) =>
      selectedGroup == null ? palette.oxide : palette.gold;
}

class _BodySide extends StatelessWidget {
  const _BodySide({
    required this.asset,
    required this.label,
    required this.color,
    required this.hotspots,
    required this.availableGroups,
    required this.selectedGroup,
    required this.onSelected,
  });
  final String asset;
  final String label;
  final Color color;
  final List<_HotspotSpec> hotspots;
  final Set<String> availableGroups;
  final String? selectedGroup;
  final ValueChanged<String?> onSelected;

  static final _templates = <String, Future<String>>{
    'assets/transmute/muscle-front.svg': rootBundle.loadString(
      'assets/transmute/muscle-front.svg',
    ),
    'assets/transmute/muscle-back.svg': rootBundle.loadString(
      'assets/transmute/muscle-back.svg',
    ),
  };

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 126,
    height: 260,
    child: Stack(
      children: [
        Semantics(
          label: label,
          child: FutureBuilder<String>(
            future: _templates[asset],
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.expand();
              return SvgPicture.string(
                _tintAnatomy(snapshot.data!, color),
                width: 126,
                height: 260,
              );
            },
          ),
        ),
        for (final hotspot in hotspots)
          Positioned(
            left: hotspot.x * 126 - 21,
            top: hotspot.y * 260 - 16,
            child: _AnatomyHotspot(
              group: hotspot.group,
              active: selectedGroup == hotspot.group,
              enabled: availableGroups.contains(hotspot.group),
              onSelected: onSelected,
            ),
          ),
      ],
    ),
  );
}

class _HotspotSpec {
  const _HotspotSpec(this.group, this.x, this.y);
  final String group;
  final double x;
  final double y;
}

class _AnatomyHotspot extends StatelessWidget {
  const _AnatomyHotspot({
    required this.group,
    required this.active,
    required this.enabled,
    required this.onSelected,
  });
  final String group;
  final bool active;
  final bool enabled;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: active,
    label: 'Show $group exercises',
    hint: enabled ? null : 'No exercises in this group',
    child: Tooltip(
      message: enabled ? group : 'No $group exercises',
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: enabled ? () => onSelected(active ? null : group) : null,
          radius: 22,
          child: Container(
            width: 42,
            height: 32,
            decoration: BoxDecoration(
              color: active
                  ? TransmutePalette.of(context).gold.withValues(alpha: .90)
                  : enabled
                  ? TransmutePalette.of(context).raised.withValues(alpha: .75)
                  : Colors.transparent,
              border: Border.all(
                color: active
                    ? TransmutePalette.of(context).ink
                    : enabled
                    ? TransmutePalette.of(context).oxide
                    : Colors.transparent,
              ),
            ),
            child: enabled
                ? Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: TransmutePalette.of(context).ink,
                  )
                : null,
          ),
        ),
      ),
    ),
  );
}

class _MuscleGroupControls extends StatelessWidget {
  const _MuscleGroupControls({
    required this.selectedGroup,
    required this.availableGroups,
    required this.onSelected,
  });
  final String? selectedGroup;
  final Set<String> availableGroups;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Muscle group selection',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final group in _knownGroups)
          ChoiceChip(
            label: Text(group),
            selected: selectedGroup == group,
            onSelected: availableGroups.contains(group)
                ? (selected) => onSelected(selected ? group : null)
                : null,
            tooltip: availableGroups.contains(group)
                ? 'Show $group exercises'
                : 'No $group exercises in this library',
          ),
      ],
    ),
  );
}

class _ResultsHeading extends StatelessWidget {
  const _ResultsHeading({
    required this.group,
    required this.movementCount,
    required this.query,
    this.onClearGroup,
  });
  final String? group;
  final int movementCount;
  final String query;
  final VoidCallback? onClearGroup;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group == null ? 'All movements' : '$group movements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '$movementCount ${movementCount == 1 ? 'movement' : 'movements'}${query.isEmpty ? '' : ' matching “$query”'}',
            ),
          ],
        ),
      ),
      if (onClearGroup != null)
        TextButton.icon(
          onPressed: onClearGroup,
          icon: const Icon(Icons.clear),
          label: const Text('All groups'),
        ),
    ],
  );
}

class _ExerciseAccordion extends StatelessWidget {
  const _ExerciseAccordion({super.key, required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          exercise.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${_categoryLabel(exercise.category)} · ${exercise.muscleGroup ?? 'Muscle group not specified'}',
        ),
        iconColor: palette.oxide,
        collapsedIconColor: palette.muted,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Demonstration',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (exercise.demoUrl == null)
            const _DemoUnavailable()
          else
            _ExerciseDemo(
              name: exercise.name,
              url: exercise.demoUrl!,
              sourceName: exercise.demoSourceName,
            ),
        ],
      ),
    );
  }
}

class _DemoUnavailable extends StatelessWidget {
  const _DemoUnavailable();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: TransmutePalette.of(context).divider),
      ),
      child: const Row(
        children: [
          Icon(Icons.videocam_off_outlined),
          SizedBox(width: 12),
          Expanded(
            child: Text('No demonstration is available for this movement yet.'),
          ),
        ],
      ),
    ),
  );
}

class _ExerciseDemo extends StatefulWidget {
  const _ExerciseDemo({required this.name, required this.url, this.sourceName});
  final String name;
  final String url;
  final String? sourceName;

  @override
  State<_ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<_ExerciseDemo> {
  VideoPlayerController? _controller;
  String? _error;

  bool get _isDirectVideo {
    final uri = Uri.tryParse(widget.url);
    return uri != null &&
        (uri.path.toLowerCase().endsWith('.mp4') ||
            uri.host.toLowerCase().endsWith('firebasestorage.googleapis.com'));
  }

  @override
  void initState() {
    super.initState();
    if (_isDirectVideo) _loadVideo();
  }

  Future<void> _loadVideo() async {
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
      if (mounted) {
        setState(() => _error = 'The demonstration could not be loaded.');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDirectVideo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DemoMessage(
            icon: Icons.open_in_new,
            message:
                'A demonstration is available${widget.sourceName == null ? '.' : ' from ${widget.sourceName}.'}',
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _openDemo,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open demonstration'),
          ),
        ],
      );
    }
    if (_error != null)
      return _DemoMessage(icon: Icons.error_outline, message: _error!);
    final controller = _controller;
    if (controller == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Semantics(
      label: '${widget.name} demonstration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => setState(() {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
            }),
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            label: Text(
              controller.value.isPlaying
                  ? 'Pause demonstration'
                  : 'Play demonstration',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDemo() async {
    final opened = await launchUrl(
      Uri.parse(widget.url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      setState(() => _error = 'The demonstration could not be opened.');
    }
  }
}

class _DemoMessage extends StatelessWidget {
  const _DemoMessage({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: TransmutePalette.of(context).divider),
    ),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_outlined, size: 36),
              const SizedBox(height: 16),
              Text(
                'No matching exercises',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Try another movement name, or clear the search to browse by muscle group.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LibraryLoading extends StatelessWidget {
  const _LibraryLoading();

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: 4,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (_, _) => Card(
      child: const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    ),
  );
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 36),
              const SizedBox(height: 16),
              Text(
                'The library could not load',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your exercise library has not been changed. Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

const _knownGroups = <String>[
  'Chest',
  'Back',
  'Shoulders',
  'Arms',
  'Core',
  'Quads',
  'Hamstrings',
  'Calves',
];

String _categoryLabel(String category) => switch (category) {
  'strength' => 'Strength',
  'cardio' => 'Cardio',
  'mobility' => 'Mobility',
  _ => category,
};

String _tintAnatomy(String svg, Color color) {
  final hex = '#${color.toARGB32().toRadixString(16).substring(2)}';
  return svg.replaceAll(RegExp(r'\{\{[^}]+}}'), hex);
}
