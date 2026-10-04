import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/widgets/app_shell.dart';

/// Owner-only review and management surface for immutable routine links.
class RoutineShareReviewScreen extends ConsumerStatefulWidget {
  const RoutineShareReviewScreen({
    super.key,
    required this.planId,
    required this.dayId,
  });

  final String planId;
  final String dayId;

  @override
  ConsumerState<RoutineShareReviewScreen> createState() =>
      _RoutineShareReviewScreenState();
}

class _RoutineShareReviewScreenState
    extends ConsumerState<RoutineShareReviewScreen> {
  late Future<List<RoutineShare>> _shares;
  bool _publishing = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _shares = _readShares();
  }

  Future<List<RoutineShare>> _readShares() =>
      ref.read(planRepositoryProvider).listRoutineShares(widget.dayId);

  void _refresh() => setState(() {
    _actionError = null;
    _shares = _readShares();
  });

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() {
      _publishing = true;
      _actionError = null;
    });
    try {
      final share = await ref
          .read(planRepositoryProvider)
          .createRoutineShare(widget.dayId);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A link for ${share.snapshot.routineName} is ready.'),
        ),
      );
    } on AppFailure catch (error) {
      if (mounted) setState(() => _actionError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _actionError =
              'Could not publish this routine. Review the snapshot and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _revoke(RoutineShare share) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke this link?'),
        content: const Text(
          'People who open this link afterward will not be able to import the routine.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep link'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke link'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(planRepositoryProvider).revokeRoutineShare(share.token);
      if (mounted) {
        _refresh();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Routine link revoked.')));
      }
    } on AppFailure catch (error) {
      if (mounted) setState(() => _actionError = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planProvider(widget.planId));
    return AppShell(
      title: 'Share routine',
      child: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => TransmuteStatePanel(
          kind: TransmuteStateKind.error,
          title: 'Routine unavailable',
          message: 'Return to your folders and choose a saved routine.',
          action: TransmuteButton(
            label: 'Back to routines',
            onPressed: () => context.go('/plans'),
          ),
        ),
        data: (plan) {
          final day = plan.days
              .where((candidate) => candidate.id == widget.dayId)
              .cast<WorkoutPlanDay?>()
              .firstOrNull;
          if (day == null) {
            return TransmuteStatePanel(
              kind: TransmuteStateKind.error,
              title: 'Routine unavailable',
              message: 'This saved routine no longer exists in that folder.',
              action: TransmuteButton(
                label: 'Back to routines',
                onPressed: () => context.go('/plans/${plan.id}'),
              ),
            );
          }
          return FutureBuilder<List<RoutineShare>>(
            future: _shares,
            builder: (context, snapshot) => _ShareReviewBody(
              plan: plan,
              day: day,
              shares: snapshot.data ?? const [],
              loadingShares:
                  snapshot.connectionState == ConnectionState.waiting,
              readError: snapshot.hasError,
              actionError: _actionError,
              publishing: _publishing,
              onPublish: day.exercises.isEmpty ? null : _publish,
              onRetry: _refresh,
              onRevoke: _revoke,
            ),
          );
        },
      ),
    );
  }
}

class _ShareReviewBody extends StatelessWidget {
  const _ShareReviewBody({
    required this.plan,
    required this.day,
    required this.shares,
    required this.loadingShares,
    required this.readError,
    required this.actionError,
    required this.publishing,
    required this.onPublish,
    required this.onRetry,
    required this.onRevoke,
  });

  final WorkoutPlan plan;
  final WorkoutPlanDay day;
  final List<RoutineShare> shares;
  final bool loadingShares;
  final bool readError;
  final String? actionError;
  final bool publishing;
  final VoidCallback? onPublish;
  final VoidCallback onRetry;
  final ValueChanged<RoutineShare> onRevoke;

  @override
  Widget build(BuildContext context) {
    final active = shares.where((share) => share.isActive).toList();
    final snapshot = RoutineShareSnapshot(
      routineName: day.name,
      folderName: plan.name,
      exercises: day.exercises
          .map(
            (entry) => RoutineShareExercise(
              exerciseId: entry.exercise.id,
              name: entry.exercise.name,
              category: entry.exercise.category,
              muscleGroup: entry.exercise.muscleGroup,
              targetSets: entry.targetSets,
              targetReps: entry.targetReps,
              trackingMode: entry.trackingMode,
              targetDurationSeconds: entry.targetDurationSeconds,
              targetWeightKg: entry.targetWeightKg,
            ),
          )
          .toList(),
    );
    return ListView(
      children: [
        TextButton.icon(
          onPressed: () => context.go('/plans/${plan.id}?dayId=${day.id}'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to routine'),
        ),
        Text(
          'Share ${day.name}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: DesignSpace.sm),
        Text(
          'Publish a read-only prescription snapshot. It never includes workout history, personal goals, or active-session data.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: DesignSpace.xl),
        _RoutineSnapshotCard(snapshot: snapshot, heading: 'Snapshot preview'),
        const SizedBox(height: DesignSpace.lg),
        if (day.exercises.isEmpty)
          const TransmuteStatePanel(
            kind: TransmuteStateKind.empty,
            title: 'Add an exercise before sharing',
            message:
                'An importable routine needs at least one saved prescription.',
          )
        else
          TransmuteButton(
            label: 'Publish new link',
            icon: Icons.ios_share_outlined,
            loading: publishing,
            onPressed: onPublish,
          ),
        if (actionError != null) ...[
          const SizedBox(height: DesignSpace.md),
          Semantics(
            liveRegion: true,
            child: Text(
              actionError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        const SizedBox(height: DesignSpace.xxl),
        Text('Published links', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: DesignSpace.sm),
        if (loadingShares)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(DesignSpace.lg),
              child: CircularProgressIndicator(),
            ),
          )
        else if (readError)
          TransmuteStatePanel(
            kind: TransmuteStateKind.error,
            title: 'Could not load published links',
            message:
                'Your routine is unchanged. Try again to manage its links.',
            action: TransmuteButton(label: 'Retry', onPressed: onRetry),
          )
        else if (active.isEmpty)
          const TransmuteStatePanel(
            kind: TransmuteStateKind.empty,
            title: 'No active links',
            message: 'Publish a link when this routine is ready to share.',
          )
        else
          ...shares.map(
            (share) => Padding(
              padding: const EdgeInsets.only(bottom: DesignSpace.md),
              child: _ShareStatusCard(share: share, onRevoke: onRevoke),
            ),
          ),
      ],
    );
  }
}

class RoutineSharePreviewScreen extends ConsumerStatefulWidget {
  const RoutineSharePreviewScreen({super.key, required this.token});
  final String token;

  @override
  ConsumerState<RoutineSharePreviewScreen> createState() =>
      _RoutineSharePreviewScreenState();
}

class _RoutineSharePreviewScreenState
    extends ConsumerState<RoutineSharePreviewScreen> {
  late Future<RoutineShareSnapshot> _share;

  @override
  void initState() {
    super.initState();
    _share = _read();
  }

  Future<RoutineShareSnapshot> _read() =>
      ref.read(planRepositoryProvider).getRoutineShare(widget.token);

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Shared routine',
    child: FutureBuilder<RoutineShareSnapshot>(
      future: _share,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final failure = snapshot.error;
          final (title, message) = switch (failure) {
            AppFailure(code: 'routine_share_revoked') => (
              'This link was revoked',
              'The owner has stopped new imports from this routine link.',
            ),
            AppFailure(code: 'routine_share_expired') => (
              'This link has expired',
              'Ask the owner to publish a fresh routine link.',
            ),
            _ => (
              'Routine link unavailable',
              'Check the link and your connection, then try again.',
            ),
          };
          return TransmuteStatePanel(
            kind: TransmuteStateKind.error,
            title: title,
            message: message,
            action: TransmuteButton(
              label: 'Retry',
              onPressed: () => setState(() => _share = _read()),
            ),
          );
        }
        return _SharedRoutineBody(
          snapshot: snapshot.data!,
          token: widget.token,
        );
      },
    ),
  );
}

class _SharedRoutineBody extends ConsumerWidget {
  const _SharedRoutineBody({required this.snapshot, required this.token});
  final RoutineShareSnapshot snapshot;
  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    children: [
      const Text(
        'SHARED ROUTINE',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
      const SizedBox(height: DesignSpace.sm),
      Text(
        snapshot.routineName,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      if (snapshot.ownerName != null || snapshot.ownerUsername != null)
        Padding(
          padding: const EdgeInsets.only(top: DesignSpace.xs),
          child: Text(
            'Published by ${snapshot.ownerName ?? '@${snapshot.ownerUsername}'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      const SizedBox(height: DesignSpace.xl),
      _RoutineSnapshotCard(snapshot: snapshot, heading: 'Routine preview'),
      const SizedBox(height: DesignSpace.lg),
      TransmuteButton(
        label: 'Import into my routines',
        icon: Icons.download_outlined,
        onPressed: () => _import(context, ref),
      ),
      const SizedBox(height: DesignSpace.md),
      Text(
        'Import creates your own editable copy. Future changes by the publisher do not change it.',
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    ],
  );

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final plans = await ref.read(planRepositoryProvider).listPlans();
    if (!context.mounted) return;
    final imported = await showDialog<_RoutineImportLocation>(
      context: context,
      builder: (_) => _RoutineImportDialog(
        plans: plans,
        initialName: snapshot.routineName,
        onImport: (planId, name, newFolderName) async {
          final repository = ref.read(planRepositoryProvider);
          final targetPlanId = newFolderName == null
              ? planId!
              : (await repository.createPlan(newFolderName)).id;
          final day = await repository.importRoutineShare(
            token,
            planId: targetPlanId,
            name: name,
          );
          return _RoutineImportLocation(targetPlanId, day.id);
        },
      ),
    );
    if (imported != null && context.mounted) {
      ref.invalidate(plansProvider);
      context.go('/plans/${imported.planId}?dayId=${imported.dayId}');
    }
  }
}

class _RoutineSnapshotCard extends StatelessWidget {
  const _RoutineSnapshotCard({required this.snapshot, required this.heading});
  final RoutineShareSnapshot snapshot;
  final String heading;

  @override
  Widget build(BuildContext context) => TransmutePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: DesignSpace.xs),
        Text(
          '${snapshot.totalSets} sets · ${snapshot.exercises.length} exercises · ${snapshot.folderName}',
        ),
        const Divider(height: DesignSpace.xl),
        for (final pair in snapshot.exercises.indexed) ...[
          Text(
            '${pair.$1 + 1}. ${pair.$2.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            _exerciseTarget(pair.$2),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (pair.$1 < snapshot.exercises.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: DesignSpace.sm),
              child: Divider(height: 1),
            ),
        ],
      ],
    ),
  );
}

class _ShareStatusCard extends StatelessWidget {
  const _ShareStatusCard({required this.share, required this.onRevoke});
  final RoutineShare share;
  final ValueChanged<RoutineShare> onRevoke;

  @override
  Widget build(BuildContext context) {
    final active = share.isActive;
    final status = switch (share.status) {
      RoutineShareStatus.active =>
        'Active until ${_shortDate(share.expiresAt)}',
      RoutineShareStatus.revoked => 'Revoked',
      RoutineShareStatus.expired => 'Expired ${_shortDate(share.expiresAt)}',
    };
    return TransmutePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(active ? Icons.link : Icons.link_off, size: 20),
              const SizedBox(width: DesignSpace.sm),
              Expanded(
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSpace.sm),
          SelectableText(_shareUrl(share.token), maxLines: 2),
          const SizedBox(height: DesignSpace.md),
          Wrap(
            spacing: DesignSpace.sm,
            runSpacing: DesignSpace.sm,
            children: [
              if (active)
                TransmuteButton(
                  label: 'Copy link',
                  kind: TransmuteButtonKind.secondary,
                  icon: Icons.copy_outlined,
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _shareUrl(share.token)),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Routine link copied.')),
                      );
                    }
                  },
                ),
              if (active)
                TransmuteButton(
                  label: 'Revoke',
                  kind: TransmuteButtonKind.destructive,
                  icon: Icons.link_off,
                  onPressed: () => onRevoke(share),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineImportLocation {
  const _RoutineImportLocation(this.planId, this.dayId);
  final String planId;
  final String dayId;
}

class _RoutineImportDialog extends StatefulWidget {
  const _RoutineImportDialog({
    required this.plans,
    required this.initialName,
    required this.onImport,
  });
  final List<WorkoutPlan> plans;
  final String initialName;
  final Future<_RoutineImportLocation> Function(
    String? planId,
    String name,
    String? newFolderName,
  )
  onImport;

  @override
  State<_RoutineImportDialog> createState() => _RoutineImportDialogState();
}

class _RoutineImportDialogState extends State<_RoutineImportDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  late final TextEditingController _folder = TextEditingController(
    text: 'My Routines',
  );
  String? _planId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _planId = widget.plans.isEmpty ? null : widget.plans.first.id;
  }

  @override
  void dispose() {
    _name.dispose();
    _folder.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final newFolder = widget.plans.isEmpty ? _folder.text.trim() : null;
    if (name.length < 2 || name.length > 32) {
      setState(() => _error = 'Use 2–32 characters for the routine name.');
      return;
    }
    if (newFolder != null && (newFolder.length < 2 || newFolder.length > 80)) {
      setState(() => _error = 'Use 2–80 characters for the folder name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final location = await widget.onImport(_planId, name, newFolder);
      if (mounted) Navigator.pop(context, location);
    } on AppFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Could not import the routine. Your choices are still here.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Import routine'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            maxLength: 32,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Your routine name'),
          ),
          const SizedBox(height: DesignSpace.sm),
          if (widget.plans.isEmpty)
            TextField(
              controller: _folder,
              maxLength: 80,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(labelText: 'New folder name'),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _planId,
              decoration: const InputDecoration(labelText: 'Save in folder'),
              items: [
                for (final plan in widget.plans)
                  DropdownMenuItem(
                    value: plan.id,
                    child: Text(plan.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _planId = value),
            ),
          if (_error != null) ...[
            const SizedBox(height: DesignSpace.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TransmuteButton(
        label: 'Import routine',
        loading: _saving,
        onPressed: _saving ? null : _save,
      ),
    ],
  );
}

String _exerciseTarget(RoutineShareExercise exercise) {
  if (exercise.trackingMode == ExerciseTrackingMode.timed) {
    final seconds = exercise.targetDurationSeconds ?? 0;
    final duration = seconds >= 60
        ? '${(seconds / 60).toStringAsFixed(seconds % 60 == 0 ? 0 : 1)} min'
        : '$seconds sec';
    return '${exercise.targetSets} sets · $duration';
  }
  final weight = exercise.targetWeightKg == null
      ? ''
      : ' · ${exercise.targetWeightKg!.toStringAsFixed(1)} kg';
  return '${exercise.targetSets} × ${exercise.targetReps} reps$weight';
}

String _shareUrl(String token) => Uri.base
    .replace(path: '/routine-shares/$token', query: null, fragment: null)
    .toString();

String _shortDate(DateTime value) =>
    '${value.month}/${value.day}/${value.year}';
