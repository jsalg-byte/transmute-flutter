import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';

class QuickAddWorkoutDialog extends ConsumerStatefulWidget {
  const QuickAddWorkoutDialog({super.key});

  @override
  ConsumerState<QuickAddWorkoutDialog> createState() =>
      _QuickAddWorkoutDialogState();
}

class _QuickAddWorkoutDialogState extends ConsumerState<QuickAddWorkoutDialog> {
  final _search = TextEditingController();
  final _weight = TextEditingController();
  final _reps = TextEditingController();
  final _duration = TextEditingController();
  Exercise? _selected;
  bool _saving = false;

  @override
  void dispose() {
    _search.dispose();
    _weight.dispose();
    _reps.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exerciseSearchProvider(_search.text));
    final unit =
        ref.watch(authControllerProvider).user?.weightUnit ?? WeightUnit.lb;
    final cardio = _selected?.category == 'cardio';
    return AlertDialog(
      title: const Text('Quick Add Workout'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  labelText: 'Choose an exercise',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              exercises.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Exercise library unavailable.'),
                data: (items) => SizedBox(
                  height: 180,
                  child: ListView.builder(
                    itemCount: items.take(30).length,
                    itemBuilder: (_, index) {
                      final exercise = items[index];
                      return ListTile(
                        dense: true,
                        title: Text(exercise.name),
                        subtitle: Text(
                          exercise.category == 'cardio'
                              ? 'Duration-based'
                              : 'Weight × reps',
                        ),
                        selected: _selected?.id == exercise.id,
                        onTap: () => setState(() => _selected = exercise),
                      );
                    },
                  ),
                ),
              ),
              if (_selected != null) ...[
                const SizedBox(height: 12),
                Text(
                  _selected!.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (cardio)
                  TextField(
                    controller: _duration,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                    ),
                  )
                else ...[
                  TextField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Weight (${unit.name})',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reps,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _save(unit, cardio),
          child: Semantics(
            liveRegion: _saving,
            label: _saving ? 'Saving workout' : 'Save workout',
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: _saving ? 0 : 1,
                  child: const Text('Save Workout'),
                ),
                if (_saving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(WeightUnit unit, bool cardio) async {
    if (_selected == null) return;
    final weight = double.tryParse(_weight.text.trim());
    final reps = int.tryParse(_reps.text.trim());
    final minutes = int.tryParse(_duration.text.trim());
    if (cardio
        ? minutes == null || minutes <= 0
        : reps == null || reps <= 0 || weight == null || weight < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid workout values.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(quickAddRepositoryProvider)
          .create(
            exerciseId: _selected!.id,
            weightUnit: unit,
            weightKg: cardio ? null : toKg(weight!, unit),
            reps: cardio ? null : reps,
            durationSeconds: cardio ? minutes! * 60 : null,
          );
      ref.invalidate(historyProvider);
      ref.invalidate(recentRecordProvider);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Workout added to your record.')),
        );
      }
    } on AppFailure catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}
