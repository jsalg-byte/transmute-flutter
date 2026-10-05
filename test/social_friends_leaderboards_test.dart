import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transmute_flutter/core/data/mock_repositories.dart';
import 'package:transmute_flutter/features/ranks/presentation/rank_overview_screens.dart';
import 'package:transmute_flutter/features/social/presentation/leaderboards_screen.dart';
import 'package:transmute_flutter/features/social/presentation/social_hub_screen.dart';

void main() {
  group('MockFriendsRepository Slice 15 features', () {
    late MockStore store;
    late MockFriendsRepository repo;

    setUp(() {
      store = MockStore();
      repo = MockFriendsRepository(store);
    });

    test('getSocialPreferences and updateSocialPreferences work correctly', () async {
      final initial = await repo.getSocialPreferences();
      expect(initial.socialActivityOptIn, isFalse);
      expect(initial.leagueOptIn, isFalse);

      final updated = await repo.updateSocialPreferences(
        socialActivityOptIn: true,
        leagueOptIn: true,
      );
      expect(updated.socialActivityOptIn, isTrue);
      expect(updated.leagueOptIn, isTrue);

      final fetched = await repo.getSocialPreferences();
      expect(fetched.socialActivityOptIn, isTrue);
      expect(fetched.leagueOptIn, isTrue);
    });

    test('getActivityFeed returns authorized friend activities', () async {
      await repo.updateSocialPreferences(socialActivityOptIn: true);
      final feed = await repo.getActivityFeed(limit: 10);
      expect(feed.activity, isNotEmpty);
      expect(feed.activity.first.username, 'alchemist');
      expect(feed.activity.first.routineName, isNotNull);
      expect(feed.nextCursor, isNull);
    });

    test('createInvitation and resolveInvitation handle invite tokens', () async {
      final invite = await repo.createInvitation();
      expect(invite.token, isNotEmpty);
      expect(invite.url, contains(invite.token));

      final resolved = await repo.resolveInvitation(invite.token);
      expect(resolved.username, 'alchemist');
      expect(resolved.inviterId, isNotEmpty);
    });

    test('getFriendsLeaderboard returns ranked participants and tie rule', () async {
      final response = await repo.getFriendsLeaderboard();
      expect(response.entries, isNotEmpty);
      expect(response.entries.first.rank, 1);
      expect(response.entries.first.xp, greaterThanOrEqualTo(response.entries.last.xp));
      expect(response.period, isNotEmpty);
      expect(response.currentUserEntry, isNotNull);
    });

    test('getLeagueStandings reflects opt-in and eligibility requirements', () async {
      // Initially opted-out
      final standings = await repo.getLeagueStandings();
      expect(standings.isEligible, isTrue);
      expect(standings.isOptedIn, isFalse);
      expect(standings.eligibleExerciseCount, greaterThanOrEqualTo(10));

      // Opt in
      await repo.updateSocialPreferences(leagueOptIn: true);
      final optedInStandings = await repo.getLeagueStandings();
      expect(optedInStandings.isOptedIn, isTrue);
    });
  });

  group('SocialHubScreen widget tests', () {
    testWidgets('renders leaderboards card, search input, and privacy settings modal', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: '/friends',
        routes: [
          GoRoute(path: '/friends', builder: (_, _) => const SocialHubScreen()),
          GoRoute(path: '/friends/leaderboards', builder: (_, _) => const LeaderboardsScreen()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and leaderboard banner
      expect(find.text('Friends & Social'), findsOneWidget);
      expect(find.text('Monthly Friends Leaderboard'), findsOneWidget);
      expect(find.text('View monthly verified XP rankings among your accepted training partners.'), findsOneWidget);

      // Check actions: Invite Friends and Privacy Settings
      expect(find.text('Invite Friends'), findsOneWidget);
      expect(find.byTooltip('Privacy settings'), findsOneWidget);

      // Open Privacy Settings Modal
      await tester.tap(find.byTooltip('Privacy settings'));
      await tester.pumpAndSettle();

      expect(find.text('Social & Privacy Controls'), findsOneWidget);
      expect(find.text('Share Activity with Friends'), findsOneWidget);
      expect(find.text('Opt into Competitive Leagues'), findsOneWidget);

      // Save/Close modal
      await tester.tap(find.text('Save Privacy Preferences'));
      await tester.pumpAndSettle();
      expect(find.text('Social & Privacy Controls'), findsNothing);

      // Tap Invite Button to open invite dialog
      await tester.tap(find.text('Invite Friends'));
      await tester.pumpAndSettle();

      expect(find.text('Shareable Invite Link'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    });
  });

  group('LeaderboardsScreen widget tests', () {
    testWidgets('renders monthly leaderboards rankings and tie rule banner', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: '/friends/leaderboards',
        routes: [
          GoRoute(path: '/friends/leaderboards', builder: (_, _) => const LeaderboardsScreen()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monthly Leaderboard'), findsOneWidget);
      expect(find.textContaining('Tie Rule:'), findsOneWidget);

      // Check user rankings rendered
      expect(find.text('Lead Alchemist'), findsWidgets);
      expect(find.text('YOU'), findsOneWidget);
    });
  });

  group('RankLeaguesScreen widget tests', () {
    testWidgets('displays placement progression and standings when opted in', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: '/ranks/leagues',
        routes: [
          GoRoute(path: '/ranks/leagues', builder: (_, _) => const RankLeaguesScreen()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rank Leagues'), findsOneWidget);
      // Check placement eligible state and opt-in prompt
      expect(find.text('Placement Complete!'), findsOneWidget);
      expect(find.text('Opt In to Leagues'), findsOneWidget);

      // Tap Opt In to Leagues
      await tester.tap(find.text('Opt In to Leagues'));
      await tester.pumpAndSettle();

      // Now opted in
      expect(find.text('Leave League'), findsOneWidget);
      expect(find.text('Lead Alchemist'), findsWidgets);
    });
  });
}
