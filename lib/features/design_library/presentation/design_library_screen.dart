import 'package:flutter/material.dart';

import '../../../core/domain/models.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/theme/transmute_palette.dart';

/// Debug-only, standalone catalog. All interactions use local sample state.
class DesignLibraryScreen extends StatefulWidget {
  const DesignLibraryScreen({super.key});

  @override
  State<DesignLibraryScreen> createState() => _DesignLibraryScreenState();
}

class _DesignLibraryScreenState extends State<DesignLibraryScreen> {
  DesignStyle _style = DesignStyle.ledger;
  ThemePalette _palette = ThemePalette.transmute;
  bool _dark = false;
  bool _saving = false;
  bool _saved = false;
  int _step = 0;
  final _weight = TextEditingController();
  final _reps = TextEditingController();
  String? _error;

  static const _movements = [
    'Barbell Overhead Press',
    'Dumbbell Posterior Delt Row',
    'Weight Plate Russian Twist',
  ];

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = double.tryParse(
      _weight.text.trim().isEmpty ? '70' : _weight.text,
    );
    final reps = int.tryParse(_reps.text.trim().isEmpty ? '8' : _reps.text);
    if (weight == null ||
        !weight.isFinite ||
        weight < 0 ||
        reps == null ||
        reps < 1) {
      setState(() => _error = 'Use a nonnegative weight and at least 1 rep.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: buildTransmuteTheme(
      ThemePreference(
        palette: _palette,
        brightness: _dark
            ? PreferenceBrightness.dark
            : PreferenceBrightness.light,
      ),
      style: _style,
    ),
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Design Library')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignSpace.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'The Building Blocks',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: DesignSpace.sm),
                    const Text(
                      'Shared components, one source of truth. Preview changes here before applying them to the app.',
                    ),
                    const SizedBox(height: DesignSpace.xl),
                    TransmutePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: DesignSpace.lg,
                            runSpacing: DesignSpace.lg,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 240,
                                child: DropdownButtonFormField<DesignStyle>(
                                  initialValue: _style,
                                  decoration: const InputDecoration(
                                    labelText: 'Component Style',
                                  ),
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                      value: DesignStyle.ledger,
                                      child: Text('Ledger · Current'),
                                    ),
                                    DropdownMenuItem(
                                      value: DesignStyle.soft,
                                      child: Text('Soft · Prototype'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null)
                                      setState(() => _style = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 240,
                                child: DropdownButtonFormField<ThemePalette>(
                                  initialValue: _palette,
                                  decoration: const InputDecoration(
                                    labelText: 'Color Palette',
                                  ),
                                  isExpanded: true,
                                  items: [
                                    for (final palette in ThemePalette.values)
                                      DropdownMenuItem(
                                        value: palette,
                                        child: Text(_paletteName(palette)),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null)
                                      setState(() => _palette = value);
                                  },
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Flexible(child: Text('Dark Mode')),
                                  const SizedBox(width: DesignSpace.sm),
                                  Switch(
                                    value: _dark,
                                    onChanged: (value) =>
                                        setState(() => _dark = value),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: DesignSpace.md),
                          const Text(
                            'Preview only. Your saved theme and workout data are unchanged.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignSpace.xl),
                    LayoutBuilder(
                      builder: (context, box) {
                        final width = box.maxWidth >= 840
                            ? (box.maxWidth - DesignSpace.xl) / 2
                            : box.maxWidth;
                        return Wrap(
                          spacing: DesignSpace.xl,
                          runSpacing: DesignSpace.xl,
                          children: [
                            SizedBox(
                              width: width,
                              child: _Section(
                                title: '01 · Containers',
                                detail:
                                    'TransmutePanel / shared insets, border, and surface',
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TransmutePanel(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Training Ledger',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                          const SizedBox(
                                            height: DesignSpace.sm,
                                          ),
                                          const Text(
                                            'A quiet surface for related content. Shape follows the component style; color follows the palette.',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: DesignSpace.sm),
                                    TransmutePanel(
                                      padding: EdgeInsets.zero,
                                      child: ListTile(
                                        leading: const Icon(Icons.history),
                                        title: const Text('Workout History'),
                                        subtitle: const Text(
                                          'Example navigation container',
                                        ),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                        ),
                                        onTap: () {},
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _Section(
                                title: '02 · Buttons',
                                detail:
                                    'TransmuteButton / primary, secondary, quiet, destructive',
                                child: TransmutePanel(
                                  child: Wrap(
                                    spacing: DesignSpace.sm,
                                    runSpacing: DesignSpace.sm,
                                    children: [
                                      TransmuteButton(
                                        label: 'Begin Session',
                                        icon: Icons.play_arrow,
                                        onPressed: () {},
                                      ),
                                      TransmuteButton(
                                        label: 'Secondary',
                                        kind: TransmuteButtonKind.secondary,
                                        onPressed: () {},
                                      ),
                                      TransmuteButton(
                                        label: 'Quiet Action',
                                        kind: TransmuteButtonKind.quiet,
                                        onPressed: () {},
                                      ),
                                      TransmuteButton(
                                        label: 'Discard',
                                        icon: Icons.delete_outline,
                                        kind: TransmuteButtonKind.destructive,
                                        onPressed: () {},
                                      ),
                                      const TransmuteButton(
                                        label: 'Disabled',
                                        onPressed: null,
                                      ),
                                      const TransmuteButton(
                                        label: 'Saving',
                                        loading: true,
                                        onPressed: null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: const _Section(
                                title: '03 · Input Fields',
                                detail:
                                    'TransmuteTextField / normal, error, disabled, ledger',
                                child: TransmutePanel(
                                  child: Column(
                                    children: [
                                      TransmuteTextField(
                                        label: 'Workout Name',
                                        hint: 'Upper Body',
                                      ),
                                      SizedBox(height: DesignSpace.lg),
                                      TransmuteTextField(
                                        label: 'Reps',
                                        hint: '0',
                                        error: 'Enter at least 1 rep.',
                                        keyboardType: TextInputType.number,
                                      ),
                                      SizedBox(height: DesignSpace.lg),
                                      TransmuteTextField(
                                        label: 'Read-Only Example',
                                        hint: 'Unavailable while saving',
                                        enabled: false,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _Section(
                                title: '04 · Movement Stepper',
                                detail:
                                    'TransmuteStepper / controlled selection, full movement name',
                                child: TransmutePanel(
                                  child: Column(
                                    children: [
                                      TransmuteStepper(
                                        title: _movements[_step],
                                        currentIndex: _step,
                                        stepCount: _movements.length,
                                        onPrevious: _step == 0
                                            ? null
                                            : () => setState(() => _step--),
                                        onNext: _step == _movements.length - 1
                                            ? null
                                            : () => setState(() => _step++),
                                        onStepSelected: (index) =>
                                            setState(() => _step = index),
                                      ),
                                      const SizedBox(height: DesignSpace.lg),
                                      Text(
                                        'Movement ${_step + 1} of ${_movements.length}',
                                      ),
                                      const SizedBox(height: DesignSpace.sm),
                                      TransmuteButton(
                                        label: 'Reset Stepper',
                                        kind: TransmuteButtonKind.quiet,
                                        onPressed: () =>
                                            setState(() => _step = 0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _Section(
                                title: '05 · Set Entry',
                                detail:
                                    'Composition / placeholders, validation, stable loading state',
                                child: TransmutePanel(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TransmuteTextField(
                                              controller: _weight,
                                              hint: '70 lb',
                                              semanticLabel:
                                                  'Preview Weight (lb)',
                                              enabled: !_saving,
                                              kind: TransmuteFieldKind.ledger,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: DesignSpace.lg),
                                          Expanded(
                                            child: TransmuteTextField(
                                              controller: _reps,
                                              hint: '8 reps',
                                              semanticLabel: 'Preview Reps',
                                              enabled: !_saving,
                                              kind: TransmuteFieldKind.ledger,
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: DesignSpace.lg),
                                      Wrap(
                                        spacing: DesignSpace.sm,
                                        runSpacing: DesignSpace.sm,
                                        children: [
                                          TransmuteButton(
                                            label: 'Log Set',
                                            loading: _saving,
                                            onPressed: _save,
                                          ),
                                          TransmuteButton(
                                            label: 'Other Log',
                                            onPressed: _saving ? null : () {},
                                            kind: TransmuteButtonKind.secondary,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: DesignSpace.sm),
                                      Semantics(
                                        liveRegion: true,
                                        child: Text(
                                          _error ??
                                              (_saved
                                                  ? 'Sample Set Saved · No data was uploaded.'
                                                  : 'Blank fields use the sample placeholders.'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _Section(
                                title: '06 · Foundations',
                                detail:
                                    'Semantic palette / spacing / typography',
                                child: _Foundations(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: DesignSpace.xxl),
                    const Text(
                      'Adopted in the app: movement navigation, set inputs, next/finish action, and history containers. More screens can migrate incrementally.',
                    ),
                    const SizedBox(height: DesignSpace.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.detail,
    required this.child,
  });
  final String title;
  final String detail;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: DesignSpace.xs),
      Text(detail, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: DesignSpace.md),
      child,
    ],
  );
}

class _Foundations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = TransmutePalette.of(context);
    return TransmutePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: DesignSpace.lg,
            runSpacing: DesignSpace.md,
            children: [
              for (final entry in {
                'Surface': palette.surface,
                'Raised': palette.raised,
                'Ink': palette.ink,
                'Accent': palette.oxide,
                'Gold': palette.gold,
                'Error': palette.rest,
              }.entries)
                Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: entry.value,
                        border: Border.all(color: palette.divider),
                      ),
                    ),
                    const SizedBox(height: DesignSpace.xs),
                    Text(entry.key),
                  ],
                ),
            ],
          ),
          const SizedBox(height: DesignSpace.xl),
          Text(
            'Spectral Headings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text('System body text keeps entries readable.'),
          const SizedBox(height: DesignSpace.lg),
          const Text(
            'Spacing: 4 / 8 / 12 / 16 / 24 / 32 dp\nControls: minimum 44 dp\nBorders: 1 dp',
          ),
        ],
      ),
    );
  }
}

String _paletteName(ThemePalette palette) => switch (palette) {
  ThemePalette.transmute => 'Transmute',
  ThemePalette.flameAlchemist => 'Flame Alchemist',
  ThemePalette.hawkeye => 'Hawkeye',
  ThemePalette.automailMechanic => 'Automail Mechanic',
  ThemePalette.avarice => 'Avarice',
  ThemePalette.scarredMan => 'Scarred Man',
  ThemePalette.armorBoundSoul => 'Armor Bound Soul',
};
