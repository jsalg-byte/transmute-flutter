import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/domain/recovery.dart';

/// Renders the same anatomical paths used by the Expo client. The asset files
/// retain named placeholders so readiness can color individual muscle regions.
class RecoveryAnatomy extends StatelessWidget {
  const RecoveryAnatomy({super.key, required this.groups});

  final List<RecoveryGroup> groups;

  static final Future<List<String>> _templates = Future.wait([
    rootBundle.loadString('assets/transmute/muscle-front.svg'),
    rootBundle.loadString('assets/transmute/muscle-back.svg'),
  ]);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<String>>(
    future: _templates,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SizedBox(width: 176, height: 224);
      }
      final colors = _regionColors(groups);
      return Semantics(
        label: groups
            .map((group) => '${group.name}: ${_stageLabel(group.stage)}')
            .join(', '),
        child: SizedBox(
          height: 224,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BodySvg(svg: _applyColors(snapshot.data![0], colors)),
              const SizedBox(width: 4),
              _BodySvg(svg: _applyColors(snapshot.data![1], colors)),
            ],
          ),
        ),
      );
    },
  );
}

class _BodySvg extends StatelessWidget {
  const _BodySvg({required this.svg});
  final String svg;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(svg, width: 112, height: 224);
}

Map<String, Color> _regionColors(List<RecoveryGroup> groups) {
  final byName = {for (final group in groups) group.name: group.stage};
  Color colorFor(String name) => switch (byName[name] ?? RecoveryStage.ready) {
    RecoveryStage.needsRest => const Color(0xffD94F57),
    RecoveryStage.recovering => const Color(0xff8A69C4),
    RecoveryStage.ready => const Color(0xff4E8DCA),
  };
  final map = <String, Color>{};
  void setAll(List<String> regions, String group) {
    for (final region in regions) map[region] = colorFor(group);
  }

  setAll(['chest'], 'Chest');
  setAll(['deltoids', 'trapezius'], 'Shoulders');
  setAll(['biceps', 'triceps', 'forearm'], 'Arms');
  setAll(['upper-back', 'lower-back', 'trapezius'], 'Back');
  setAll(['abs', 'obliques'], 'Core');
  setAll([
    'adductors',
    'calves',
    'gluteal',
    'hamstring',
    'quadriceps',
    'tibialis',
  ], 'Legs');
  return map;
}

String _applyColors(String template, Map<String, Color> colors) {
  const regions = [
    'abs',
    'adductors',
    'biceps',
    'calves',
    'chest',
    'deltoids',
    'forearm',
    'gluteal',
    'hamstring',
    'lower-back',
    'obliques',
    'quadriceps',
    'tibialis',
    'trapezius',
    'triceps',
    'upper-back',
  ];
  var svg = template;
  for (final region in regions) {
    final color = colors[region] ?? const Color(0xff4E8DCA);
    final fill = '#${color.toARGB32().toRadixString(16).substring(2)}';
    final stroke =
        '#${color.withValues(alpha: .76).toARGB32().toRadixString(16).substring(2)}';
    svg = svg
        .replaceAll('{{$region}}', fill)
        .replaceAll(
          '{{$region'
          'Stroke}}',
          stroke,
        );
  }
  return svg;
}

String _stageLabel(RecoveryStage stage) => switch (stage) {
  RecoveryStage.needsRest => 'needs rest',
  RecoveryStage.recovering => 'recovering',
  RecoveryStage.ready => 'ready to train',
};
