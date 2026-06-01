import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/profile_providers.dart';
import '../domain/profile_models.dart';
import '../presentation/widgets/profile_hero_banner.dart';
import '../presentation/tabs/overview_tab.dart';
import '../presentation/tabs/achievements_tab.dart';
import '../presentation/tabs/championships_tab.dart';
import '../presentation/tabs/history_tab.dart';

/// Perfil público — para ver el perfil de otro usuario.
/// Solo muestra Overview, Historia, Logros y Campeonatos (sin Editar).
class PublicProfilePage extends ConsumerStatefulWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  ConsumerState<PublicProfilePage> createState() =>
      _PublicProfilePageState();
}

class _PublicProfilePageState extends ConsumerState<PublicProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync =
        ref.watch(publicProfileProvider(widget.userId));

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Usuario no encontrado')),
          );
        }
        return _PublicScaffold(
          profile: profile,
          tabs: _tabs,
        );
      },
    );
  }
}

class _PublicScaffold extends StatelessWidget {
  final UserProfile profile;
  final TabController tabs;

  const _PublicScaffold({required this.profile, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: innerBoxIsScrolled ? 1 : 0,
            title: Text(
              profile.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                ProfileHeroBanner(profile: profile, isOwner: false),
                ProfileIdentityRow(
                  profile: profile,
                  isOwner: false,
                ),
                ProfileStatsBar(profile: profile),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: tabs,
                indicatorColor: const Color(0xFF60519B),
                indicatorWeight: 3,
                labelColor: const Color(0xFF60519B),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.home_outlined, size: 22)),
                  Tab(icon: Icon(Icons.history, size: 22)),
                  Tab(icon: Icon(Icons.emoji_events_outlined, size: 22)),
                  Tab(icon: Icon(Icons.military_tech_outlined, size: 22)),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: tabs,
          children: [
            OverviewTab(
              profile: profile,
              isOwner: false,
              onNavigate: (_) {},
            ),
            HistoryTab(userId: profile.id),
            AchievementsTab(userId: profile.id),
            ChampionshipsTab(userId: profile.id),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => tabBar != old.tabBar;
}