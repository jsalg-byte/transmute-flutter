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
  final _selectedGroups = <String>{};

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
                selectedGroups: _selectedGroups,
                onGroupToggled: (group) => setState(() {
                  if (!_selectedGroups.add(group))
                    _selectedGroups.remove(group);
                }),
                onGroupsCleared: () => setState(_selectedGroups.clear),
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
    required this.selectedGroups,
    required this.onGroupToggled,
    required this.onGroupsCleared,
  });
  final List<Exercise> exercises;
  final String query;
  final Set<String> selectedGroups;
  final ValueChanged<String> onGroupToggled;
  final VoidCallback onGroupsCleared;

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
    final activeGroups = selectedGroups.where(groups.contains).toSet();
    final visible = activeGroups.isEmpty
        ? matched
        : matched
              .where((exercise) => activeGroups.contains(exercise.muscleGroup))
              .toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _BodyMusclePicker(
            availableGroups: availableGroups,
            selectedGroups: activeGroups,
            onGroupToggled: onGroupToggled,
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
              groups: activeGroups,
              movementCount: visible.length,
              query: query,
              onClearGroups: activeGroups.isEmpty ? null : onGroupsCleared,
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
    required this.selectedGroups,
    required this.onGroupToggled,
  });
  final Set<String> availableGroups;
  final Set<String> selectedGroups;
  final ValueChanged<String> onGroupToggled;

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
              selectedGroups: selectedGroups,
              availableGroups: availableGroups,
              onGroupToggled: onGroupToggled,
            );
            final controls = _MuscleGroupControls(
              selectedGroups: selectedGroups,
              availableGroups: availableGroups,
              onGroupToggled: onGroupToggled,
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
                  'Tap one or more body groups to show their movements below.',
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
    required this.selectedGroups,
    required this.availableGroups,
    required this.onGroupToggled,
  });
  final Set<String> selectedGroups;
  final Set<String> availableGroups;
  final ValueChanged<String> onGroupToggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: selectedGroups.isEmpty
          ? 'Front and back muscle anatomy. Tap a body region to select it.'
          : '${selectedGroups.join(', ')} selected in the anatomy.',
      child: SizedBox(
        height: 260,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BodySide(
              asset: 'assets/transmute/muscle-front.svg',
              label: 'Front body',
              hotspots: const [
                _HotspotSpec('Shoulders', .16, .10),
                _HotspotSpec('Chest', .50, .25),
                _HotspotSpec('Arms', .14, .39),
                _HotspotSpec('Core', .50, .47),
                _HotspotSpec('Quads', .50, .67),
              ],
              availableGroups: availableGroups,
              selectedGroups: selectedGroups,
              onGroupToggled: onGroupToggled,
            ),
            const SizedBox(width: 8),
            _BodySide(
              asset: 'assets/transmute/muscle-back.svg',
              label: 'Back body',
              hotspots: const [
                _HotspotSpec('Shoulders', .50, .10),
                _HotspotSpec('Back', .50, .29),
                _HotspotSpec('Arms', .87, .39),
                _HotspotSpec('Hamstrings', .50, .67),
                _HotspotSpec('Calves', .50, .88),
              ],
              availableGroups: availableGroups,
              selectedGroups: selectedGroups,
              onGroupToggled: onGroupToggled,
            ),
          ],
        ),
      ),
    );
  }
}

class _BodySide extends StatelessWidget {
  const _BodySide({
    required this.asset,
    required this.label,
    required this.hotspots,
    required this.availableGroups,
    required this.selectedGroups,
    required this.onGroupToggled,
  });
  final String asset;
  final String label;
  final List<_HotspotSpec> hotspots;
  final Set<String> availableGroups;
  final Set<String> selectedGroups;
  final ValueChanged<String> onGroupToggled;

  static final _templates = <String, Future<String>>{
    'assets/transmute/muscle-front.svg': rootBundle.loadString(
      'assets/transmute/muscle-front.svg',
    ),
    'assets/transmute/muscle-back.svg': rootBundle.loadString(
      'assets/transmute/muscle-back.svg',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return SizedBox(
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
                  _colorAnatomy(snapshot.data!, selectedGroups, palette),
                  width: 126,
                  height: 260,
                );
              },
            ),
          ),
          for (final hotspot in hotspots)
            Positioned(
              left: hotspot.x * 126 - 24,
              top: hotspot.y * 260 - 24,
              child: _AnatomyRegionTapTarget(
                group: hotspot.group,
                selected: selectedGroups.contains(hotspot.group),
                enabled: availableGroups.contains(hotspot.group),
                onGroupToggled: onGroupToggled,
              ),
            ),
        ],
      ),
    );
  }
}

class _HotspotSpec {
  const _HotspotSpec(this.group, this.x, this.y);
  final String group;
  final double x;
  final double y;
}

class _AnatomyRegionTapTarget extends StatelessWidget {
  const _AnatomyRegionTapTarget({
    required this.group,
    required this.selected,
    required this.enabled,
    required this.onGroupToggled,
  });
  final String group;
  final bool selected;
  final bool enabled;
  final ValueChanged<String> onGroupToggled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${selected ? 'Deselect' : 'Select'} $group muscle group',
    hint: enabled ? null : 'No exercises in this group',
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: enabled ? () => onGroupToggled(group) : null,
      child: const SizedBox(width: 48, height: 48),
    ),
  );
}

class _MuscleGroupControls extends StatelessWidget {
  const _MuscleGroupControls({
    required this.selectedGroups,
    required this.availableGroups,
    required this.onGroupToggled,
  });
  final Set<String> selectedGroups;
  final Set<String> availableGroups;
  final ValueChanged<String> onGroupToggled;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Muscle group selection',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final group in _knownGroups)
          FilterChip(
            label: Text(group),
            selected: selectedGroups.contains(group),
            onSelected: availableGroups.contains(group)
                ? (_) => onGroupToggled(group)
                : null,
            tooltip: availableGroups.contains(group)
                ? 'Toggle $group exercises'
                : 'No $group exercises in this library',
          ),
      ],
    ),
  );
}

class _ResultsHeading extends StatelessWidget {
  const _ResultsHeading({
    required this.groups,
    required this.movementCount,
    required this.query,
    this.onClearGroups,
  });
  final Set<String> groups;
  final int movementCount;
  final String query;
  final VoidCallback? onClearGroups;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groups.isEmpty
                  ? 'All movements'
                  : groups.length == 1
                  ? '${groups.single} movements'
                  : 'Selected movements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '$movementCount ${movementCount == 1 ? 'movement' : 'movements'}${query.isEmpty ? '' : ' matching “$query”'}',
            ),
          ],
        ),
      ),
      if (onClearGroups != null)
        TextButton.icon(
          onPressed: onClearGroups,
          icon: const Icon(Icons.clear),
          label: const Text('Clear selection'),
        ),
    ],
  );
}

class _ExerciseAccordion extends StatefulWidget {
  const _ExerciseAccordion({super.key, required this.exercise});
  final Exercise exercise;

  @override
  State<_ExerciseAccordion> createState() => _ExerciseAccordionState();
}

class _ExerciseAccordionState extends State<_ExerciseAccordion> {
  var _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        onExpansionChanged: (expanded) => setState(() {
          _isExpanded = expanded;
        }),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          widget.exercise.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${_categoryLabel(widget.exercise.category)} · ${widget.exercise.muscleGroup ?? 'Muscle group not specified'}',
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
          if (widget.exercise.demoUrl == null)
            const _DemoUnavailable()
          else
            _ExerciseDemo(
              name: widget.exercise.name,
              url: widget.exercise.demoUrl!,
              sourceName: widget.exercise.demoSourceName,
              autoPlay: _isExpanded,
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
  const _ExerciseDemo({
    required this.name,
    required this.url,
    required this.autoPlay,
    this.sourceName,
  });
  final String name;
  final String url;
  final bool autoPlay;
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
      if (widget.autoPlay) await controller.play();
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
  void didUpdateWidget(covariant _ExerciseDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoPlay == widget.autoPlay) return;
    final controller = _controller;
    if (controller == null) return;
    if (widget.autoPlay) {
      controller.play();
    } else {
      controller.pause();
    }
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
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(controller),
            Positioned(
              left: 8,
              bottom: 8,
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, _) => Material(
                  color: Colors.black.withValues(alpha: .58),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: value.isPlaying
                        ? 'Pause demonstration'
                        : 'Play demonstration',
                    color: Colors.white,
                    onPressed: () {
                      value.isPlaying ? controller.pause() : controller.play();
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

const _groupRegions = <String, Set<String>>{
  'Chest': {'chest'},
  'Back': {'upper-back', 'lower-back', 'trapezius'},
  'Shoulders': {'deltoids', 'trapezius'},
  'Arms': {'biceps', 'triceps', 'forearm'},
  'Core': {'abs', 'obliques'},
  'Quads': {'quadriceps', 'adductors'},
  'Hamstrings': {'hamstring', 'gluteal'},
  'Calves': {'calves', 'tibialis'},
};

String _colorAnatomy(
  String svg,
  Set<String> selectedGroups,
  TransmutePalette palette,
) {
  final selectedRegions = selectedGroups.expand(
    (group) => _groupRegions[group] ?? const <String>{},
  );
  final selected = selectedRegions.toSet();
  final neutral = _hex(palette.divider.withValues(alpha: .62));
  final red = _hex(palette.rest);

  return svg.replaceAllMapped(RegExp(r'\{\{([^}]+)}}'), (match) {
    final token = match.group(1)!;
    final region = token.endsWith('Stroke')
        ? token.substring(0, token.length - 'Stroke'.length)
        : token;
    return selected.contains(region) ? red : neutral;
  });
}

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).substring(2)}';
