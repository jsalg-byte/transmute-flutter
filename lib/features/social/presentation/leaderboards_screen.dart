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
        TransmutePanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Period: ${data.period}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '${data.entries.length} ${data.entries.length == 1 ? 'participant' : 'participants'}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
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
            if (entry.rank == 1) {
              rankColor = const Color(0xFFFFD700);
            } else if (entry.rank == 2) {
              rankColor = const Color(0xFFC0C0C0);
            } else if (entry.rank == 3) {
              rankColor = const Color(0xFFCD7F32);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TransmutePanel(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
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
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                          Text(
                            '@${entry.username} · ${entry.qualifiedSessions} ${entry.qualifiedSessions == 1 ? 'workout' : 'workouts'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${entry.xp} XP',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
