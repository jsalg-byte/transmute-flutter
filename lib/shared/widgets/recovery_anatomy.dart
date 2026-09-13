import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/domain/recovery.dart';
import '../design_system/cute_theme.dart';

/// Renders the same anatomical paths used by the Expo client. The asset files
/// retain named placeholders so readiness can color individual muscle regions.
class RecoveryAnatomy extends StatelessWidget {
  const RecoveryAnatomy({super.key, required this.groups, this.templateLoader});

  final List<RecoveryGroup> groups;
  @visibleForTesting
  final Future<List<String>>? templateLoader;

  static final Future<List<String>> _templates = Future.wait([
    rootBundle.loadString('assets/transmute/muscle-front.svg'),
    rootBundle.loadString('assets/transmute/muscle-back.svg'),
  ]);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<String>>(
    future: templateLoader ?? _templates,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SizedBox(width: 176, height: 224);
      }
      final colorBlindSafe =
          Theme.of(context).extension<CuteCustomStyles>()?.colorBlindSafe ??
          false;
      final colors = _regionColors(groups, colorBlindSafe: colorBlindSafe);
      return Semantics(
        label:
            '${groups.map((group) => '${group.name}: ${_stageLabel(group.stage)}').join(', ')}. '
            'Legend: Rest under 24 hours, Recover 24 to 48 hours, Ready after 48 hours.',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 224,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BodySvg(
                    svg: _applyColors(
                      snapshot.data![0],
                      colors,
                      fallback: recoveryStageColor(
                        RecoveryStage.ready,
                        colorBlindSafe: colorBlindSafe,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _BodySvg(
                    svg: _applyColors(
                      snapshot.data![1],
                      colors,
                      fallback: recoveryStageColor(
                        RecoveryStage.ready,
                        colorBlindSafe: colorBlindSafe,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _RecoveryLegend(colorBlindSafe: colorBlindSafe),
          ],
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

Map<String, Color> _regionColors(
  List<RecoveryGroup> groups, {
  required bool colorBlindSafe,
}) {
  final byName = {for (final group in groups) group.name: group.stage};
  Color colorFor(String name) => recoveryStageColor(
    byName[name] ?? RecoveryStage.ready,
    colorBlindSafe: colorBlindSafe,
  );
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

/// Colors represent an ordered recovery scale. In red-green-safe mode, the
/// scale is dark violet → blue → pale blue; labels and icon shapes in the
/// legend provide a second, non-color way to read every state.
Color recoveryStageColor(RecoveryStage stage, {required bool colorBlindSafe}) =>
    switch ((stage, colorBlindSafe)) {
      (RecoveryStage.needsRest, false) => const Color(0xffD94F57),
      (RecoveryStage.recovering, false) => const Color(0xff8A69C4),
      (RecoveryStage.ready, false) => const Color(0xff4E8DCA),
      (RecoveryStage.needsRest, true) => const Color(0xff56408A),
      (RecoveryStage.recovering, true) => const Color(0xff3E77B6),
      (RecoveryStage.ready, true) => const Color(0xffA6C9E2),
    };

String _applyColors(
  String template,
  Map<String, Color> colors, {
  required Color fallback,
}) {
  const regions = [
    'abs',
    'adductors',
    'ankles',
    'biceps',
    'calves',
    'chest',
    'deltoids',
    'feet',
    'forearm',
    'gluteal',
    'hair',
    'hamstring',
    'hands',
    'head',
    'knees',
    'lower-back',
    'neck',
    'obliques',
    'quadriceps',
    'tibialis',
    'trapezius',
    'triceps',
    'upper-back',
  ];
  var svg = template;
  for (final region in regions) {
    final color = colors[region] ?? fallback;
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

class _RecoveryLegend extends StatelessWidget {
  const _RecoveryLegend({required this.colorBlindSafe});
  final bool colorBlindSafe;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 10,
    runSpacing: 6,
    children: [
      _RecoveryLegendItem(
        icon: Icons.pause_circle_filled,
        color: recoveryStageColor(
          RecoveryStage.needsRest,
          colorBlindSafe: colorBlindSafe,
        ),
        label: 'Rest · <24h',
      ),
      _RecoveryLegendItem(
        icon: Icons.timelapse,
        color: recoveryStageColor(
          RecoveryStage.recovering,
          colorBlindSafe: colorBlindSafe,
        ),
        label: 'Recover · 24–48h',
      ),
      _RecoveryLegendItem(
        icon: Icons.check_circle_outline,
        color: recoveryStageColor(
          RecoveryStage.ready,
          colorBlindSafe: colorBlindSafe,
        ),
        label: 'Ready · 48h+',
      ),
    ],
  );
}

class _RecoveryLegendItem extends StatelessWidget {
  const _RecoveryLegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

String _stageLabel(RecoveryStage stage) => switch (stage) {
  RecoveryStage.needsRest => 'needs rest',
  RecoveryStage.recovering => 'recovering',
  RecoveryStage.ready => 'ready to train',
};
