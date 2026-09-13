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
import '../features/fasting/presentation/fasting_screen.dart';
import '../features/goals/presentation/goals_screen.dart';
import '../features/not_found/presentation/not_found_screen.dart';
import '../features/nutrition/presentation/nutrition_screen.dart';
import '../features/planning/presentation/planning_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/workout_history/presentation/history_screens.dart';
import '../features/workout_plans/presentation/plan_screens.dart';
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
        final publicRoute =
            state.matchedLocation == '/' || state.matchedLocation == '/login';
        if (loading) return publicRoute ? null : '/';
        if (!loggedIn && !publicRoute) return '/';
        if (loggedIn && publicRoute) {
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
        GoRoute(path: '/', builder: (_, _) => const PreLoginOnboardingScreen()),
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
          path: '/exercises',
          builder: (_, _) => const ExerciseLibraryScreen(),
        ),
        GoRoute(path: '/nutrition', builder: (_, _) => const NutritionScreen()),
        GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
        GoRoute(path: '/fasting', builder: (_, _) => const FastingScreen()),
        GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
        GoRoute(path: '/planning', builder: (_, _) => const PlanningScreen()),
        GoRoute(path: '/arcana', builder: (_, _) => const ArcanaScreen()),
        GoRoute(
          path: '/friends',
          builder: (_, _) => const FriendsScreen(),
          routes: [
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
          path: '/plans',
          builder: (_, _) => const PlanListScreen(),
          routes: [
            GoRoute(
              path: ':planId',
              builder: (_, state) =>
                  PlanDetailScreen(planId: state.pathParameters['planId']!),
            ),
          ],
        ),
        GoRoute(
          path: '/session',
          builder: (_, _) => const ActiveSessionScreen(),
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
    return MaterialApp.router(
      title: 'Transmute',
      theme: useCuteTheme
          ? (useCuteColorBlindMode ? cuteColorBlindTheme : cuteTheme)
          : buildTransmuteTheme(preference),
      routerConfig: _router,
    );
  }
}

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
