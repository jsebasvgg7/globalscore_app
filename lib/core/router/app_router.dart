import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/notes/presentation/notes_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/ranking/presentation/ranking_page.dart';
import '../../features/stats/presentation/stats_page.dart';
import '../../features/albums/presentation/albums_page.dart';
import '../../features/albums/presentation/album_detail_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/public_profile_page.dart';
import '../../features/profile/presentation/pages/achievements_page.dart';
import '../../features/profile/presentation/pages/championships_page.dart';
import '../../features/profile/presentation/pages/history_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/history/presentation/history_page.dart' as hist;
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
          // 0 — Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardPage(),
            ),
          ]),
          // 1 — Ranking
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ranking',
              builder: (_, __) => const RankingPage(),
            ),
          ]),
          // 2 — Albums
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/albums',
              builder: (_, __) => const AlbumsPage(),
              routes: [
                GoRoute(
                  path: ':albumId',
                  builder: (_, s) =>
                      AlbumDetailPage(albumId: s.pathParameters['albumId']!),
                ),
              ],
            ),
          ]),
          // 3 — Stats
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/stats',
              builder: (_, __) => const StatsPage(),
            ),
          ]),
          // 4 — History
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/history',
              builder: (_, __) => const hist.HistoryPage(),
            ),
          ]),
          // 5 — Perfil propio
          StatefulShellBranch(routes: [  // branchIndex = 5
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: 'achievements',
                  builder: (_, __) => const AchievementsPage(),
                ),
                GoRoute(
                  path: 'championships',
                  builder: (_, __) => const ChampionshipsPage(),
                ),
                GoRoute(
                  path: 'history',
                  builder: (_, __) => const PredictionHistoryPage(),
                ),
                GoRoute(
                  path: 'edit',
                  builder: (_, __) => const EditProfilePage(),
                ),
              ],
            ),
          ]),
        ],
      ),

      GoRoute(
        path: '/profile/:userId',
        builder: (_, state) => PublicProfilePage(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/notes',
        builder: (_, __) => const NotesPage(),
      ),
      // Admin — fuera del shell, sin nav bar
      // GoRoute(
      //   path: '/admin',
      //   builder: (_, __) => const AdminPage(),
      // ),
    ],
  );
});