import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/profile_providers.dart';
import '../domain/profile_models.dart';
import '../presentation/widgets/profile_hero_banner.dart';
import '../presentation/tabs/overview_tab.dart';
import '../presentation/tabs/achievements_tab.dart';
import '../presentation/tabs/championships_tab.dart';
import '../presentation/tabs/history_tab.dart';
import '../presentation/tabs/edit_tab.dart';

/// Página de perfil propio.
/// Tabs: Overview · Historia · Logros · Campeonatos · Editar
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Índice de "Editar" hardcodeado como tab 4
  static const _tabCount = 5;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _onTabNavigation(String route) {
    switch (route) {
      case 'achievements':
        _tabs.animateTo(2);
      case 'championships':
        _tabs.animateTo(3);
      default:
        context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(ownProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('No se pudo cargar el perfil')),
          );
        }
        return _ProfileScaffold(
          profile: profile,
          tabs: _tabs,
          onNavigation: _onTabNavigation,
        );
      },
    );
  }
}

class _ProfileScaffold extends StatelessWidget {
  final UserProfile profile;
  final TabController tabs;
  final void Function(String) onNavigation;

  const _ProfileScaffold({
    required this.profile,
    required this.tabs,
    required this.onNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── App bar transparente sobre el banner ──
          SliverAppBar(
            expandedHeight: 0,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: innerBoxIsScrolled ? 1 : 0,
            title: Text(
              profile.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Editar perfil',
                onPressed: () => tabs.animateTo(4),
              ),
            ],
          ),

          // ── Banner + identity + stats bar ─────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                ProfileHeroBanner(profile: profile, isOwner: true),
                ProfileIdentityRow(
                  profile: profile,
                  isOwner: true,
                  onTap: null,
                ),
                ProfileStatsBar(profile: profile),
              ],
            ),
          ),

          // ── Tab bar sticky ────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: const Color(0xFF60519B),
                indicatorWeight: 3,
                labelColor: const Color(0xFF60519B),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontSize: 0, // ocultamos texto, solo iconos en mobile
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.home_outlined, size: 22)),
                  Tab(icon: Icon(Icons.history, size: 22)),
                  Tab(icon: Icon(Icons.emoji_events_outlined, size: 22)),
                  Tab(icon: Icon(Icons.military_tech_outlined, size: 22)),
                  Tab(icon: Icon(Icons.edit_outlined, size: 22)),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: tabs,
          children: [
            // 0 — Overview
            OverviewTab(
              profile: profile,
              isOwner: true,
              onNavigate: onNavigation,
            ),
            // 1 — Historia
            HistoryTab(userId: profile.id),
            // 2 — Logros
            AchievementsTab(userId: profile.id),
            // 3 — Campeonatos
            ChampionshipsTab(userId: profile.id),
            // 4 — Editar
            EditTab(
              profile: profile,
              onSaved: () => tabs.animateTo(0),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SliverPersistentHeaderDelegate para TabBar ──
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) =>
      tabBar != old.tabBar;
}