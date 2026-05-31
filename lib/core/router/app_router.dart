import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/ranking/presentation/ranking_page.dart';
import '../../features/stats/presentation/stats_page.dart';
import '../../features/albums/presentation/albums_page.dart';
import '../../features/albums/presentation/album_detail_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/public_profile_page.dart';
import '../../shared/layout/scaffold_with_nav_bar.dart';
import 'router_notifier.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login',    builder: (c, s) => const LoginPage()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          // 0 — Dashboard (trofeo central)
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (c, s) => const DashboardPage()),
          ]),
          // 1 — Ranking
          StatefulShellBranch(routes: [
            GoRoute(path: '/ranking', builder: (c, s) => const RankingPage()),
          ]),
          // 2 — Albums / Historia
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/albums',
              builder: (c, s) => const AlbumsPage(),
              routes: [
                GoRoute(
                  path: ':albumId',
                  builder: (c, s) =>
                      AlbumDetailPage(albumId: s.pathParameters['albumId']!),
                ),
              ],
            ),
          ]),
          // 3 — Stats  ← NUEVO
         StatefulShellBranch(routes: [
          GoRoute(
            path: '/stats',
            builder: (c, s) => const StatsPage(),
          ),
        ]),
          // 4 — Perfil
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (c, s) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: ':userId',
                  builder: (c, s) =>
                      PublicProfilePage(userId: s.pathParameters['userId']!),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});