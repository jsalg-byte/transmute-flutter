import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_shell.dart';

class SocialHubScreen extends ConsumerStatefulWidget {
  const SocialHubScreen({super.key});

  @override
  ConsumerState<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends ConsumerState<SocialHubScreen> {
  final _searchController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);

    return AppShell(
      title: 'Friends',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header Row with Title & Opt-in Privacy Settings button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Friends & Social', style: Theme.of(context).textTheme.displaySmall),
              ),
              IconButton(
                icon: const Icon(Icons.shield_outlined),
                tooltip: 'Privacy settings',
                onPressed: () => _showPrivacySettingsModal(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Share workouts, challenge your friends on the leaderboard, and compete in leagues.',
          ),
          const SizedBox(height: 16),

          // Reference [18]: Large prominent Leaderboards Action Card
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: () => context.go('/friends/leaderboards'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Friends Leaderboard',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'View monthly verified XP rankings among your accepted training partners.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reference [18]: Action Buttons: Invite Link & Direct Request
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showInviteLinkDialog(context),
                icon: const Icon(Icons.link_outlined),
                label: const Text('Invite Friends'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddFriendDialog(context),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add by Username'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Reference [18]: Search Filter for Friends List
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Search friends',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(_searchController.clear),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),

          // Friends Content (Incoming, Friends List or Honest Empty State)
          friendsAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
            error: (_, __) => Center(
              child: ElevatedButton(
                onPressed: () => ref.invalidate(friendsProvider),
                child: const Text('Retry loading friends'),
              ),
            ),
            data: (record) => _buildFriendsContent(record),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsContent(FriendsRecord record) {
    final query = _searchController.text.trim().toLowerCase();
    final incoming = record.incoming.where((r) => r.status == 'pending').toList();
    final accepted = [
      ...record.incoming,
      ...record.outgoing,
    ].where((r) => r.status == 'accepted').where((f) {
      if (query.isEmpty) return true;
      return f.username.toLowerCase().contains(query) ||
          (f.name != null && f.name!.toLowerCase().contains(query));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (incoming.isNotEmpty) ...[
          _sectionTitle('Incoming Requests (${incoming.length})'),
          const SizedBox(height: 8),
          ...incoming.map((req) => _RequestCard(
            request: req,
            busy: _saving,
            onAccept: () => _run(
              () => ref.read(friendsRepositoryProvider).accept(req.id),
              'Friend request accepted.',
            ),
            onReject: () => _run(
              () => ref.read(friendsRepositoryProvider).reject(req.id),
              'Friend request declined.',
            ),
          )),
          const SizedBox(height: 20),
        ],

        _sectionTitle('Accepted Friends (${accepted.length})'),
        const SizedBox(height: 8),
        if (accepted.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    query.isNotEmpty ? 'No friends match "$query"' : 'No friends yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    query.isNotEmpty
                        ? 'Try searching by a different name or username.'
                        : 'Generate a shareable invite link or send requests by username to start training together.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...accepted.map((friend) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  (friend.name?.isNotEmpty == true ? friend.name![0] : friend.username[0]).toUpperCase(),
                ),
              ),
              title: Text(friend.name ?? friend.username),
              subtitle: Text('@${friend.username}'),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'remove') {
                    _confirmRemoveFriend(friend);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove friend', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
    title.toUpperCase(),
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      letterSpacing: 1.1,
    ),
  );

  void _showAddFriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend by Username'),
        content: TextField(
          controller: _usernameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixText: '@',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final username = _usernameController.text.trim();
              Navigator.pop(context);
              if (username.length >= 3) {
                _run(
                  () => ref.read(friendsRepositoryProvider).sendRequest(username),
                  'Friend request sent to @$username',
                );
                _usernameController.clear();
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _showInviteLinkDialog(BuildContext context) async {
    try {
      final invite = await ref.read(friendsRepositoryProvider).createInvitation();
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Shareable Invite Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send this invite link to your training partners. Anyone with the link can connect with you on Transmute.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'https://transmute.mzootfb.xyz${invite.url}',
                        style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy link',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: 'https://transmute.mzootfb.xyz${invite.url}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invite link copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate invite link: $e')),
        );
      }
    }
  }

  void _showPrivacySettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _SocialPrivacyModal(),
    );
  }

  Future<void> _confirmRemoveFriend(FriendRequest friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${friend.name ?? friend.username}?'),
        content: const Text(
          'They will no longer be able to see your shared training activity or leaderboard entries.',
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
    if (confirmed == true) {
      await _run(
        () => ref.read(friendsRepositoryProvider).remove(friend.userId),
        'Friend removed.',
      );
    }
  }

  Future<void> _run(Future<void> Function() operation, String success) async {
    setState(() => _saving = true);
    try {
      await operation();
      ref.invalidate(friendsProvider);
      ref.invalidate(socialActivityFeedProvider);
      ref.invalidate(friendsLeaderboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SocialPrivacyModal extends ConsumerStatefulWidget {
  const _SocialPrivacyModal();

  @override
  ConsumerState<_SocialPrivacyModal> createState() => _SocialPrivacyModalState();
}

class _SocialPrivacyModalState extends ConsumerState<_SocialPrivacyModal> {
  bool? _socialActivityOptIn;
  bool? _leagueOptIn;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(socialPreferencesProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: prefsAsync.when(
        loading: () => const Center(heightFactor: 4, child: CircularProgressIndicator()),
        error: (_, __) => const Text('Could not load privacy settings.'),
        data: (prefs) {
          final currentSocial = _socialActivityOptIn ?? prefs.socialActivityOptIn;
          final currentLeague = _leagueOptIn ?? prefs.leagueOptIn;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Social & Privacy Controls',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage your visibility among accepted friends and competitive leagues.',
                style: TextStyle(fontSize: 13),
              ),
              const Divider(height: 24),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share Activity with Friends'),
                subtitle: const Text(
                  'Allow accepted friends to see your completed workouts and your name on the monthly friends leaderboard.',
                ),
                value: currentSocial,
                onChanged: _saving ? null : (val) => setState(() => _socialActivityOptIn = val),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Opt into Competitive Leagues'),
                subtitle: const Text(
                  'Participate in verified strength tier leagues once you have completed placement (10 ranked exercises across 5 muscle groups).',
                ),
                value: currentLeague,
                onChanged: _saving ? null : (val) => setState(() => _leagueOptIn = val),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : () => _save(prefs),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Privacy Preferences'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save(SocialPrivacyPreferences current) async {
    setState(() => _saving = true);
    try {
      await ref.read(friendsRepositoryProvider).updateSocialPreferences(
        socialActivityOptIn: _socialActivityOptIn,
        leagueOptIn: _leagueOptIn,
      );
      ref.invalidate(socialPreferencesProvider);
      ref.invalidate(socialActivityFeedProvider);
      ref.invalidate(friendsLeaderboardProvider);
      ref.invalidate(leagueStandingsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
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
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(
              (request.name?.isNotEmpty == true ? request.name![0] : request.username[0]).toUpperCase(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.name ?? request.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '@${request.username}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            tooltip: 'Accept',
            onPressed: busy ? null : onAccept,
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
            tooltip: 'Decline',
            onPressed: busy ? null : onReject,
          ),
        ],
      ),
    ),
  );
}
