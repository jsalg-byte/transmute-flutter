import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/domain/models.dart';
import '../features/active_session/presentation/active_session_screen.dart';
import '../features/account/presentation/account_screens.dart';
import '../features/arcana/presentation/arcana_screen.dart';
import '../features/authentication/presentation/login_screen.dart';
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
        final loggedIn = _auth.status == AuthStatus.signedIn;
        final loading = _auth.status == AuthStatus.loading;
        if (loading) return state.matchedLocation == '/login' ? null : '/login';
        if (!loggedIn && state.matchedLocation != '/login') return '/login';
        if (loggedIn && state.matchedLocation == '/login') {
          return _auth.freshRegistration ? '/welcome' : '/dashboard';
        }
        if (state.matchedLocation == '/')
          return loggedIn ? '/dashboard' : '/login';
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
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
    final palette = preference.palette;
    final brightness = preference.brightness;
    final isDark = brightness == PreferenceBrightness.dark;
    final surface = isDark ? const Color(0xff14131A) : const Color(0xffF4EBD8);
    final raised = isDark ? const Color(0xff201E29) : const Color(0xffFCF7EC);
    final ink = isDark ? const Color(0xffF4F0E6) : const Color(0xff171821);
    final muted = isDark ? const Color(0xffBDB7B2) : const Color(0xff605D63);
    final divider = isDark ? const Color(0xff413D50) : const Color(0xffD9CEB9);
    final colors = ColorScheme.fromSeed(
      seedColor: _paletteSeed(palette),
      brightness: isDark ? Brightness.dark : Brightness.light,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: divider,
    );
    return MaterialApp.router(
      title: 'Transmute',
      theme: ThemeData(
        colorScheme: colors,
        scaffoldBackgroundColor: colors.surface,
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: raised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: divider),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: raised,
          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            minimumSize: const Size(44, 44),
          ),
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      routerConfig: _router,
    );
  }
}

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

Color _paletteSeed(ThemePalette palette) => switch (palette) {
  ThemePalette.transmute => const Color(0xff6D4C41),
  ThemePalette.flameAlchemist => const Color(0xffB54334),
  ThemePalette.hawkeye => const Color(0xff556B8E),
  ThemePalette.automailMechanic => const Color(0xff3D7390),
  ThemePalette.avarice => const Color(0xff8A6B19),
  ThemePalette.scarredMan => const Color(0xff6B7650),
  ThemePalette.armorBoundSoul => const Color(0xff596E75),
};
