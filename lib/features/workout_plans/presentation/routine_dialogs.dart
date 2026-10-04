import 'package:flutter/material.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';

Future<T?> showRoutineNameDialog<T>({
  required BuildContext context,
  required String title,
  required String label,
  required Future<T> Function(String name) onSave,
  String? initial,
  int maxLength = 32,
}) => showDialog<T>(
  context: context,
  builder: (_) => _RoutineNameDialog<T>(
    title: title,
    label: label,
    initial: initial,
    maxLength: maxLength,
    onSave: onSave,
  ),
);

class _RoutineNameDialog<T> extends StatefulWidget {
  const _RoutineNameDialog({
    required this.title,
    required this.label,
    required this.initial,
    required this.maxLength,
    required this.onSave,
  });

  final String title;
  final String label;
  final String? initial;
  final int maxLength;
  final Future<T> Function(String name) onSave;

  @override
  State<_RoutineNameDialog<T>> createState() => _RoutineNameDialogState<T>();
}

class _RoutineNameDialogState<T> extends State<_RoutineNameDialog<T>> {
  late final _name = TextEditingController(text: widget.initial);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.length < 2 || name.length > widget.maxLength) {
      setState(() => _error = 'Use 2–${widget.maxLength} characters.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.onSave(name);
      if (mounted) Navigator.of(context).pop(saved);
    } on AppFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'Could not save. Your name is still here; try again.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: widget.maxLength,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(labelText: widget.label),
        ),
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving…' : 'Save'),
      ),
    ],
  );
}

class RoutineLocation {
  const RoutineLocation(this.planId, this.dayId);
  final String planId;
  final String dayId;
}

Future<RoutineLocation?> showCreateRoutineDialog({
  required BuildContext context,
  required PlanRepository repository,
  required List<WorkoutPlan> folders,
  String? initialFolderId,
}) => showDialog<RoutineLocation>(
  context: context,
  builder: (_) => _CreateRoutineDialog(
    repository: repository,
    folders: folders,
    initialFolderId: initialFolderId,
  ),
);

class _CreateRoutineDialog extends StatefulWidget {
  const _CreateRoutineDialog({
    required this.repository,
    required this.folders,
    required this.initialFolderId,
  });

  final PlanRepository repository;
  final List<WorkoutPlan> folders;
  final String? initialFolderId;

  @override
  State<_CreateRoutineDialog> createState() => _CreateRoutineDialogState();
}

class _CreateRoutineDialogState extends State<_CreateRoutineDialog> {
  final _name = TextEditingController();
  String? _folderId;
  String? _createdDefaultFolderId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _folderId =
        widget.initialFolderId ??
        (widget.folders.isEmpty ? null : widget.folders.first.id);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.length < 2 || name.length > 32) {
      setState(() => _error = 'Use 2–32 characters for the routine name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      var planId = _folderId ?? _createdDefaultFolderId;
      if (planId == null) {
        final folder = await widget.repository.createPlan('My Routines');
        planId = folder.id;
        _createdDefaultFolderId = planId;
      }
      final day = await widget.repository.addDay(planId, name);
      if (mounted) Navigator.of(context).pop(RoutineLocation(planId, day.id));
    } on AppFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Could not create the routine. Your name is still here; try again.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New routine'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.folders.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'A My Routines folder will be created for this routine.',
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _folderId,
            decoration: const InputDecoration(labelText: 'Folder'),
            items: [
              for (final folder in widget.folders)
                DropdownMenuItem(
                  value: folder.id,
                  child: Text(folder.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _folderId = value),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: 32,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: const InputDecoration(labelText: 'Routine name'),
        ),
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Creating…' : 'Create routine'),
      ),
    ],
  );
}
