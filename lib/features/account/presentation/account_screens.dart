import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/domain/repositories.dart';
import '../../../core/providers.dart';
import '../../../shared/theme/transmute_palette.dart';
import '../../../shared/widgets/app_shell.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});
  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _username = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(friendsProvider);
    return AppShell(
      title: 'Friends',
      child: record.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(friendsProvider),
            child: const Text('Retry friends'),
          ),
        ),
        data: _content,
      ),
    );
  }

  Widget _content(FriendsRecord record) {
    final incoming = record.incoming
        .where((request) => request.status == 'pending')
        .toList();
    final outgoing = record.outgoing
        .where((request) => request.status == 'pending')
        .toList();
    final friends = [
      ...record.incoming,
      ...record.outgoing,
    ].where((request) => request.status == 'accepted').toList();
    return ListView(
      children: [
        Text('Friend', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        const Text(
          'Send requests by username. Accepted friends can see workout sessions only.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _username,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      labelText: 'Friend username',
                      prefixText: '@',
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _send,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Send request'),
                ),
              ],
            ),
          ),
        ),
        _section(
          'Incoming requests',
          incoming.isEmpty
              ? const _EmptyCard('No incoming requests')
              : Column(
                  children: incoming
                      .map(
                        (request) => _RequestCard(
                          request: request,
                          busy: _saving,
                          onAccept: () => _run(
                            () => ref
                                .read(friendsRepositoryProvider)
                                .accept(request.id),
                            'Friend request accepted.',
                          ),
                          onReject: () => _run(
                            () => ref
                                .read(friendsRepositoryProvider)
                                .reject(request.id),
                            'Friend request declined.',
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        _section(
          'Friends',
          friends.isEmpty
              ? const _EmptyCard('No friends yet')
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 760 ? 2 : 1;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 10) / columns;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: friends
                          .map(
                            (friend) => SizedBox(
                              width: width,
                              child: Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person_outline),
                                  ),
                                  title: Text(friend.name ?? friend.username),
                                  subtitle: Text('@${friend.username}'),
                                  trailing: TextButton(
                                    onPressed: _saving
                                        ? null
                                        : () => _remove(friend),
                                    child: const Text('Remove'),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
        ),
        _section(
          'Friends’ workout activity',
          record.activity.isEmpty
              ? const _EmptyCard(
                  'No friend activity yet',
                  detail: 'Accepted friends share workout sessions only.',
                )
              : Column(
                  children: record.activity
                      .map(
                        (session) => Card(
                          child: ListTile(
                            onTap: () =>
                                context.go('/friends/sessions/${session.id}'),
                            leading: const Icon(Icons.fitness_center),
                            title: Text(session.name ?? session.username),
                            subtitle: Text(
                              '@${session.username} · ${session.routineName ?? 'Workout plan'} / ${session.dayName ?? 'Day'}\n${session.status} · ${session.setCount} sets · ${_date(session.startedAt)}',
                            ),
                            isThreeLine: true,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        _section(
          'Sent requests',
          outgoing.isEmpty
              ? const _EmptyCard('No pending sent requests')
              : Column(
                  children: outgoing
                      .map(
                        (request) => Card(
                          child: ListTile(
                            title: Text(request.name ?? request.username),
                            subtitle: Text('@${request.username} · Pending'),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _section(String label, Widget content) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    ),
  );
  Future<void> _send() => _run(() async {
    final username = _username.text.trim();
    if (username.length < 3)
      throw const AppFailure(
        'invalid_username',
        'Enter a username with at least 3 characters.',
      );
    await ref.read(friendsRepositoryProvider).sendRequest(username);
    _username.clear();
  }, 'Friend request sent.');
  Future<void> _remove(FriendRequest friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${friend.name ?? friend.username}?'),
        content: const Text(
          'They will no longer be able to view your shared workout records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true)
      await _run(
        () => ref.read(friendsRepositoryProvider).remove(friend.userId),
        'Friend removed.',
      );
  }

  Future<void> _run(Future<void> Function() operation, String success) async {
    setState(() => _saving = true);
    try {
      await operation();
      ref.invalidate(friendsProvider);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
    } on AppFailure catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesProvider);
    final plans = ref.watch(plansProvider);
    return AppShell(
      title: 'Preferences',
      child: preferences.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(preferencesProvider),
            child: const Text('Retry preferences'),
          ),
        ),
        data: (value) => ListView(
          children: [
            Text(
              'Your preferences',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Set the terms of the record. Saved changes take effect across this account.',
            ),
            const SizedBox(height: 16),
            _weightCard(value),
            const SizedBox(height: 12),
            _activePlanCard(value, plans),
            const SizedBox(height: 12),
            _themeCard(value),
          ],
        ),
      ),
    );
  }

  Widget _weightCard(UserPreferences preferences) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weight unit', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SegmentedButton<WeightUnit>(
            segments: const [
              ButtonSegment(value: WeightUnit.lb, label: Text('lbs')),
              ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
            ],
            selected: {preferences.weightUnit},
            onSelectionChanged: _saving
                ? null
                : (value) => _setWeight(value.first),
          ),
        ],
      ),
    ),
  );
  Widget _activePlanCard(
    UserPreferences preferences,
    AsyncValue<List<WorkoutPlan>> plans,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active workout plan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text('Today uses this plan’s first scheduled workout day.'),
          const SizedBox(height: 10),
          plans.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text(
              'Plans are unavailable. Retry from Plans before selecting one.',
            ),
            data: (items) => DropdownButtonFormField<String?>(
              initialValue:
                  items.any((plan) => plan.id == preferences.activePlanId)
                  ? preferences.activePlanId
                  : null,
              decoration: const InputDecoration(labelText: 'Plan'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No active plan'),
                ),
                ...items.map(
                  (plan) => DropdownMenuItem<String?>(
                    value: plan.id,
                    child: Text(plan.name),
                  ),
                ),
              ],
              onChanged: _saving ? null : _setActivePlan,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _themeCard(UserPreferences _) {
    final selected = ref.watch(effectiveThemePreferenceProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Color theme', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Choose a palette and light or dark mode. Both are saved to your account.',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720
                    ? 3
                    : constraints.maxWidth >= 450
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - 8 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ThemePalette.values
                      .map(
                        (palette) => SizedBox(
                          width: width,
                          child: _PaletteChoice(
                            palette: palette,
                            brightness: selected.brightness,
                            selected: selected.palette == palette,
                            onTap: _saving
                                ? null
                                : () => _setTheme(
                                    ThemePreference(
                                      palette: palette,
                                      brightness: selected.brightness,
                                    ),
                                  ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<PreferenceBrightness>(
              segments: const [
                ButtonSegment(
                  value: PreferenceBrightness.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: PreferenceBrightness.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {selected.brightness},
              onSelectionChanged: _saving
                  ? null
                  : (value) => _setTheme(
                      ThemePreference(
                        palette: selected.palette,
                        brightness: value.first,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setWeight(WeightUnit unit) => _run(() async {
    await ref.read(preferencesRepositoryProvider).setWeightUnit(unit);
    ref.read(authControllerProvider.notifier).setWeightUnit(unit);
  }, 'Weight unit saved.');
  Future<void> _setActivePlan(String? id) => _run(
    () => ref.read(preferencesRepositoryProvider).setActivePlan(id),
    'Active workout plan saved.',
  );
  Future<void> _setTheme(ThemePreference preference) {
    final prior = ref.read(effectiveThemePreferenceProvider);
    ref.read(themeOverrideProvider.notifier).set(preference);
    return _run(() async {
      try {
        await ref.read(preferencesRepositoryProvider).setTheme(preference);
      } catch (_) {
        ref.read(themeOverrideProvider.notifier).set(prior);
        rethrow;
      }
    }, 'Theme preference saved.');
  }

  Future<void> _run(Future<void> Function() operation, String success) async {
    setState(() => _saving = true);
    try {
      await operation();
      ref.invalidate(preferencesProvider);
      ref.invalidate(themePreferenceProvider);
      ref.invalidate(dailyOverviewProvider);
      ref.invalidate(dailyRecommendationProvider);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
    } on AppFailure catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PaletteChoice extends StatelessWidget {
  const _PaletteChoice({
    required this.palette,
    required this.brightness,
    required this.selected,
    required this.onTap,
  });

  final ThemePalette palette;
  final PreferenceBrightness brightness;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TransmutePalette.forPalette(palette, brightness);
    final outline = selected
        ? Theme.of(context).colorScheme.primary
        : TransmutePalette.of(context).divider;
    return Semantics(
      button: true,
      selected: selected,
      label: '${_paletteLabel(palette)} color theme',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: outline, width: selected ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PalettePreview(
                        label: brightness == PreferenceBrightness.light
                            ? 'Light palette'
                            : 'Dark palette',
                        tokens: tokens,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _paletteLabel(palette),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  const _PalettePreview({required this.label, required this.tokens});

  final String label;
  final TransmutePalette tokens;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: TransmutePalette.of(context).muted,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          for (final color in [
            tokens.surface,
            tokens.ink,
            tokens.oxide,
            tokens.gold,
          ])
            Expanded(
              child: Container(
                height: 20,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: tokens.divider),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });
  final FriendRequest request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(request.name ?? request.username),
      subtitle: Text('@${request.username}'),
      trailing: Wrap(
        spacing: 4,
        children: [
          TextButton(
            onPressed: busy ? null : onReject,
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: busy ? null : onAccept,
            child: const Text('Accept'),
          ),
        ],
      ),
    ),
  );
}

class SharedSessionScreen extends ConsumerWidget {
  const SharedSessionScreen({super.key, required this.sessionId});
  final String sessionId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(sharedSessionProvider(sessionId));
    return AppShell(
      title: 'Shared workout',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(sharedSessionProvider(sessionId)),
            child: const Text('Retry shared workout'),
          ),
        ),
        data: (session) {
          final groups = <String, List<SharedWorkoutSet>>{};
          for (final set in session.sets) {
            groups.putIfAbsent(set.exerciseName, () => []).add(set);
          }
          return ListView(
            children: [
              Text(
                'Private workout record',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${session.routineName ?? 'Workout plan'} · ${session.dayName ?? 'Session'}',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Logged by ${session.ownerName ?? session.ownerUsername} · ${_date(session.startedAt)}',
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text(session.status.toUpperCase()),
                  subtitle: Text(
                    '${session.sets.length} ${session.sets.length == 1 ? 'set' : 'sets'} recorded',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'MOVEMENTS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              if (groups.isEmpty) const _EmptyCard('No sets were recorded.'),
              ...groups.entries.map(
                (entry) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        ...entry.value.map(
                          (set) => Text(
                            '#${set.order} · ${set.reps} reps${set.weight == null ? '' : ' · ${set.weight} ${session.weightUnit == WeightUnit.kg ? 'kg' : 'lbs'}'}${set.isWarmup ? ' · warm-up' : ''}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.title, {this.detail});
  final String title;
  final String? detail;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(title),
      subtitle: detail == null ? null : Text(detail!),
    ),
  );
}

String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';
String _paletteLabel(ThemePalette value) => switch (value) {
  ThemePalette.transmute => 'Transmute',
  ThemePalette.flameAlchemist => 'Flame Alchemist',
  ThemePalette.hawkeye => 'Hawkeye',
  ThemePalette.automailMechanic => 'Automail Mechanic',
  ThemePalette.avarice => 'Avarice',
  ThemePalette.scarredMan => 'Scarred Man',
  ThemePalette.armorBoundSoul => 'Armor-Bound Soul',
};
