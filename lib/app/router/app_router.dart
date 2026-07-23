import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/listings/presentation/cubit/listing_details_cubit.dart';
import '../../features/listings/presentation/pages/listing_details_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shell/presentation/pages/home_shell.dart';
import '../di/injection.dart';
import 'app_routes.dart';

/// Builds the app router. Auth state drives redirects so unauthenticated users
/// never reach the shell, and authenticated users skip the auth flow.
///
/// Every route uses [MaterialPage] for native Material slide/fade transitions.
GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final status = authCubit.state.status;
      final loc = state.matchedLocation;
      final onSplash = loc == AppRoutes.splash;
      final onAuthFlow = loc == AppRoutes.welcome || loc == AppRoutes.auth;

      if (status == AuthStatus.unknown) {
        return onSplash ? null : AppRoutes.splash;
      }

      final loggedIn = status == AuthStatus.authenticated;
      if (!loggedIn) {
        return onAuthFlow ? null : AppRoutes.welcome;
      }
      if (onSplash || onAuthFlow) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, _) => const MaterialPage(child: SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (_, _) => const MaterialPage(child: WelcomePage()),
      ),
      GoRoute(
        path: AppRoutes.auth,
        pageBuilder: (_, state) =>
            MaterialPage(child: AuthPage(role: state.extra as UserRole?)),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (_, _) => const MaterialPage(child: HomeShell()),
      ),
      GoRoute(
        path: AppRoutes.listingDetails,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage(
            child: BlocProvider(
              create: (_) => sl<ListingDetailsCubit>()..load(id),
              child: const ListingDetailsPage(),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (_, _) =>
            const MaterialPage(child: NotificationsPage()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (_, _) => const MaterialPage(child: SettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (_, _) =>
            const MaterialPage(child: ProfilePage(showBack: true)),
      ),
    ],
  );
}

/// Bridges a Bloc [Stream] to a [Listenable] so GoRouter re-evaluates redirects
/// whenever auth state changes.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
