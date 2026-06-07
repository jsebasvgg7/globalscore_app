import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/notes/presentation/notes_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/ranking/presentation/ranking_page.dart';
import '../../features/stats/presentation/stats_page.dart';
import '../../features/albums/presentation/albums_page.dart';
import '../../features/albums/presentation/album_detail_page.dart';
import '../../features/albums/presentation/pack_opening_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/public_profile_page.dart';
import '../../features/profile/presentation/pages/achievements_page.dart';
import '../../features/profile/presentation/pages/championships_page.dart';
import '../../features/profile/presentation/pages/history_page.dart';
import '../../features/worldcup/presentation/worldcup_page.dart';
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
      GoRoute(path: '/login',    builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          // 0 — Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const DashboardPage(),
            ),
          ]),
          // 1 — Ranking
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ranking',
              builder: (_, _) => const RankingPage(),
            ),
          ]),
          // 2 — Albums
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/albums',
              builder: (_, _) => const AlbumsPage(),
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
              builder: (_, _) => const StatsPage(),
            ),
          ]),
          // 4 — History
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/history',
              builder: (_, _) => const hist.HistoryPage(),
            ),
          ]),
          // 5 — Perfil propio
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: 'achievements',
                  builder: (_, _) => const AchievementsPage(),
                ),
                GoRoute(
                  path: 'championships',
                  builder: (_, _) => const ChampionshipsPage(),
                ),
                GoRoute(
                  path: 'history',
                  builder: (_, _) => const PredictionHistoryPage(),
                ),
                GoRoute(
                  path: 'edit',
                  builder: (_, _) => const EditProfilePage(),
                ),
              ],
            ),
          ]),
        ],
      ),

      // ── Pack Opening — fuera del shell, sin nav bar ─────────
      // Se accede con context.push('/pack-opening') desde AlbumsPage.
      // Al hacer pop() vuelve a /albums y PackOpeningPage llama
      // refresh() una sola vez sobre albumsProvider.
      GoRoute(
        path: '/pack-opening',
        builder: (_, _) => const PackOpeningPage(),
      ),

      GoRoute(
        path: '/profile/:userId',
        builder: (_, state) => PublicProfilePage(
          userId: state.pathParameters['userId']!,
        ),
      ),

      GoRoute(
        path: '/notes',
        builder: (_, _) => const NotesPage(),
      ),

      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsPage(),
      ),

      GoRoute(
        path: '/worldcup',
        builder: (_, _) => const WorldCupPage(),
      ),

      // Admin — fuera del shell, sin nav bar
      // GoRoute(
      //   path: '/admin',
      //   builder: (_, _) => const AdminPage(),
      // ),
    ],
  );
});