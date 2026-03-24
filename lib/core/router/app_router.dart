import 'package:go_router/go_router.dart';
import 'package:la_facu/core/widgets/app_shell.dart';
import 'package:la_facu/features/dashboard/presentation/dashboard_screen.dart';
import 'package:la_facu/features/subjects/presentation/subjects_screen.dart';
import 'package:la_facu/features/schedule/presentation/schedule_screen.dart';
import 'package:la_facu/features/tasks/presentation/tasks_screen.dart';
import 'package:la_facu/features/onboarding/presentation/splash_screen.dart';
import 'package:la_facu/features/onboarding/presentation/onboarding_screen.dart';
import 'package:la_facu/features/onboarding/presentation/login_screen.dart';
import 'package:la_facu/features/settings/presentation/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/subjects',
          name: 'subjects',
          builder: (context, state) => const SubjectsScreen(),
        ),
        GoRoute(
          path: '/schedule',
          name: 'schedule',
          builder: (context, state) => const ScheduleScreen(),
        ),
        GoRoute(
          path: '/tasks',
          name: 'tasks',
          builder: (context, state) => const TasksScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
