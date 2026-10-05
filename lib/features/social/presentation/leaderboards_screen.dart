import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/widgets/app_shell.dart';

class LeaderboardsScreen extends ConsumerStatefulWidget {
  const LeaderboardsScreen({super.key});

  @override
  ConsumerState<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends ConsumerState<LeaderboardsScreen> {
  String? _selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(friendsLeaderboardProvider(_selectedPeriod));
    final theme = Theme.of(context);

    return AppShell(
      title: 'Leaderboard',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Monthly Leaderboard', style: theme.textTheme.displaySmall),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Verified XP earned from confirmed workouts among accepted friends during the active month.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),

          leaderboardAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => TransmuteStatePanel(
              kind: TransmuteStateKind.error,
              title: 'Leaderboard unavailable',
              message: 'Could not load monthly standings: $err',
              action: TransmuteButton(
                label: 'Retry',
                onPressed: () => ref.invalidate(friendsLeaderboardProvider(_selectedPeriod)),
              ),
            ),
            data: (data) => _buildLeaderboardContent(context, data),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent(BuildContext context, LeaderboardResponse data) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta Card: Period, Cohort & Tie Rule
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Period: ${data.period}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${data.entries.length} ${data.entries.length == 1 ? 'participant' : 'participants'}',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tie Rule: ${data.tieRule}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (data.entries.isEmpty)
          const TransmuteStatePanel(
            kind: TransmuteStateKind.empty,
            title: 'No friend activity this month',
            message: 'Complete confirmed workouts with your friends to populate the monthly standings.',
          )
        else
          ...data.entries.map((entry) {
            final isTop3 = entry.rank <= 3;
            final isCurrentUser = entry.isCurrentUser;

            Color? rankColor;
            if (entry.rank == 1) rankColor = const Color(0xFFFFD700);
            else if (entry.rank == 2) rankColor = const Color(0xFFC0C0C0);
            else if (entry.rank == 3) rankColor = const Color(0xFFCD7F32);

            return Card(
              color: isCurrentUser
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : null,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isCurrentUser
                    ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isTop3 ? rankColor?.withValues(alpha: 0.2) : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${entry.rank}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isTop3 ? rankColor : null,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name ?? entry.username,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '@${entry.username} · ${entry.qualifiedSessions} ${entry.qualifiedSessions == 1 ? 'workout' : 'workouts'}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  '${entry.xp} XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
