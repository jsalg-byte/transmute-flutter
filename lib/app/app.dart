import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/active_session/presentation/active_session_screen.dart';
import '../features/account/presentation/account_screens.dart';
import '../features/arcana/presentation/arcana_screen.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/pre_login_onboarding_screen.dart';
import '../features/authentication/presentation/welcome_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/exercise_library/presentation/exercise_library_screen.dart';
import '../features/feature_hubs/presentation/feature_hub_screens.dart';
import '../features/fasting/presentation/fasting_screen.dart';
import '../features/goals/presentation/goals_screen.dart';
import '../features/not_found/presentation/not_found_screen.dart';
import '../features/nutrition/presentation/nutrition_screen.dart';
import '../features/nutrition/presentation/recipe_screens.dart';
import '../features/planning/presentation/planning_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/ranks/presentation/ranks_screens.dart';
import '../features/ranks/presentation/rank_overview_screens.dart';
import '../features/social/presentation/social_hub_screen.dart';
import '../features/social/presentation/leaderboards_screen.dart';
import '../features/workout_history/presentation/history_screens.dart';
import '../features/workout_history/presentation/training_calendar_screen.dart';
import '../features/workout_plans/presentation/plan_screens.dart';
import '../features/workout_plans/presentation/routine_share_screens.dart';
import '../shared/design_system/design_system.dart';
import '../features/design_library/presentation/design_library_screen.dart';

class TransmuteApp extends ConsumerStatefulWidget {
  const TransmuteApp({super.key});

  @override
  ConsumerState<TransmuteApp> createState() => _TransmuteAppState();
}

class _TransmuteAppState extends ConsumerState<TransmuteApp> {
  final _routerRefresh = _RouterRefresh();
  late final GoRouter _router;
  late final ProviderSubscription<AuthState> _authSubscription;
  AuthState _auth = const AuthState(AuthStatus.loading);

  @override
  void initState() {
    super.initState();
    _auth = ref.read(authControllerProvider);
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: _routerRefresh,
      redirect: (context, state) {
        if (kDebugMode && state.matchedLocation == '/design-library')
          return null;
        final loggedIn = _auth.status == AuthStatus.signedIn;
        final loading = _auth.status == AuthStatus.loading;
        final shareRoute = state.matchedLocation.startsWith('/routine-shares/');
        final publicRoute =
            state.matchedLocation == '/' ||
            state.matchedLocation == '/login' ||
            shareRoute;
        // Keep a protected deep link intact while secure storage and `/v1/me`
        // restore the session. Return null while loading to avoid exposing public
        // routes or churning the browser history before auth state resolves.
        if (loading) {
          return null;
        }
        if (!loggedIn && shareRoute) {
          return '/login?next=${Uri.encodeComponent(state.uri.toString())}';
        }
        if (!loggedIn && !publicRoute) return '/';
        if (loggedIn && publicRoute) {
          final next = state.uri.queryParameters['next'];
          if (_isSafeInternalNext(next)) return next!;
          return _auth.freshRegistration ? '/welcome' : '/dashboard';
        }
        return null;
      },
      routes: [
        if (kDebugMode)
          GoRoute(
            path: '/design-library',
            builder: (_, _) => const DesignLibraryScreen(),
          ),
        GoRoute(path: '/', builder: (_, _) => const PreLoginEntryRoute()),
        GoRoute(
          path: '/login',
          builder: (_, state) => LoginScreen(
            initiallyRegistering:
                state.uri.queryParameters['mode'] == 'register',
          ),
        ),
        GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
        GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
        GoRoute(
          path: '/ranks',
          builder: (_, _) => const OverallRanksScreen(),
          routes: [
            GoRoute(
              path: 'bodygraph',
              builder: (_, _) => const RankBodygraphScreen(),
            ),
            GoRoute(
              path: 'leagues',
              builder: (_, _) => const RankLeaguesScreen(),
            ),
            GoRoute(
              path: 'analysis',
              builder: (_, _) => const RankAnalysisScreen(),
            ),
            GoRoute(
              path: 'gallery',
              builder: (_, _) => const RanksScreen(),
              routes: [
                GoRoute(
                  path: ':exerciseId',
                  builder: (_, state) => RankDetailScreen(
                    exerciseId: state.pathParameters['exerciseId']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'calculator',
              builder: (_, _) => const RankCalculatorScreen(),
            ),
          ],
        ),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileHubScreen()),
        GoRoute(
          path: '/exercises',
          builder: (_, _) => const ExerciseLibraryScreen(),
        ),
        GoRoute(path: '/nutrition', builder: (_, _) => const NutritionScreen()),
        GoRoute(path: '/recipes', builder: (_, _) => const RecipeDiscoveryScreen()),
        GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
        GoRoute(path: '/fasting', builder: (_, _) => const FastingScreen()),
        GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
        GoRoute(path: '/planning', builder: (_, _) => const PlanningScreen()),
        GoRoute(path: '/arcana', builder: (_, _) => const ArcanaScreen()),
        GoRoute(
          path: '/friends',
          builder: (_, _) => const SocialHubScreen(),
          routes: [
            GoRoute(
              path: 'leaderboards',
              builder: (_, _) => const LeaderboardsScreen(),
            ),
            GoRoute(
              path: 'sessions/:sessionId',
              builder: (_, state) => SharedSessionScreen(
                sessionId: state.pathParameters['sessionId']!,
              ),
            ),
          ],
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: '/routine-shares/:token',
          builder: (_, state) =>
              RoutineSharePreviewScreen(token: state.pathParameters['token']!),
        ),
        GoRoute(
          path: '/plans',
          builder: (_, _) => const PlanListScreen(),
          routes: [
            GoRoute(
              path: ':planId',
              builder: (_, state) => PlanDetailScreen(
                planId: state.pathParameters['planId']!,
                initialDayId: state.uri.queryParameters['dayId'],
              ),
              routes: [
                GoRoute(
                  path: 'share/:dayId',
                  builder: (_, state) => RoutineShareReviewScreen(
                    planId: state.pathParameters['planId']!,
                    dayId: state.pathParameters['dayId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/session',
          builder: (_, _) => const ActiveSessionScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (_, _) => const TrainingCalendarScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (_, _) => const HistoryScreen(),
          routes: [
            GoRoute(
              path: ':sessionId',
              builder: (_, state) => CompletedSessionScreen(
                sessionId: state.pathParameters['sessionId']!,
              ),
              routes: [
                GoRoute(
                  path: 'share',
                  builder: (_, state) => WorkoutShareScreen(
                    sessionId: state.pathParameters['sessionId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      errorBuilder: (_, state) => NotFoundScreen(path: state.uri.path),
    );
    _authSubscription = ref.listenManual<AuthState>(authControllerProvider, (
      _,
      next,
    ) {
      _auth = next;
      _routerRefresh.refresh();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _authSubscription.close();
    _router.dispose();
    _routerRefresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preference = ref.watch(effectiveThemePreferenceProvider);
    final useCuteTheme =
        ref.watch(cuteThemeEnabledProvider).asData?.value ?? false;
    final useCuteColorBlindMode =
        ref.watch(cuteColorBlindModeProvider).asData?.value ?? false;
    final auth = ref.watch(authControllerProvider);
    return MaterialApp.router(
      title: 'Transmute',
      theme: useCuteTheme
          ? (useCuteColorBlindMode ? cuteColorBlindTheme : cuteTheme)
          : buildTransmuteTheme(preference),
      routerConfig: _router,
      builder: (context, child) {
        // In debug mode or if routing to /design-library, allow the child through.
        // For general routes, if auth is still resolving, keep the root splash visible
        // so guest onboarding never flashes before an authenticated session resolves.
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

bool _isSafeInternalNext(String? route) =>
    route != null && route.startsWith('/') && !route.startsWith('//');

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
