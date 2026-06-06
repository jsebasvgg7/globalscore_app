import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/profile_providers.dart';
import '../domain/profile_models.dart';
import '../presentation/widgets/profile_hero_banner.dart';
import '../presentation/tabs/overview_tab.dart';
import '../presentation/tabs/achievements_tab.dart';
import '../presentation/tabs/championships_tab.dart';
import '../presentation/tabs/history_tab.dart';

// ── Paleta Neobrutalismo ──────────────────────────────────────────────
const _bg     = Color(0xFFF0EDE8);
const _card   = Color(0xFFEAE7E1);
const _border = Color(0xFF1A1A2E);
const _accent = Color(0xFF5B4FD8);
const _text   = Color(0xFF1A1A2E);
const _muted  = Color(0xFF6B6580);

const _shadowColor = Color(0x661A1A2E);
const _shadowSm    = BoxShadow(
  color: _shadowColor, offset: Offset(1, 1), blurRadius: 0);

/// Perfil público — para ver el perfil de otro usuario.
/// Solo muestra Overview, Historia, Logros y Campeonatos (sin Editar).
class PublicProfilePage extends ConsumerStatefulWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  ConsumerState<PublicProfilePage> createState() => _PublicProfilePageState();
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
    final profileAsync = ref.watch(publicProfileProvider(widget.userId));

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _bg,
        appBar: _NeoAppBar(title: 'ERROR'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                border: Border.all(color: _border, width: 1),
                boxShadow: const [_shadowSm],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Container(width: 4, height: 20, color: Color(0xFFE24B4A)),
                  const SizedBox(width: 8),
                  const Text(
                    'ERROR',
                    style: TextStyle(
                      fontFamily: 'DM Mono',
                      color: Color(0xFFE24B4A),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  'Error cargando perfil\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DM Mono',
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            backgroundColor: _bg,
            appBar: _NeoAppBar(title: 'PERFIL'),
            body: const Center(
              child: Text(
                'USUARIO NO ENCONTRADO',
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          );
        }
        return _PublicScaffold(profile: profile, tabs: _tabs);
      },
    );
  }
}

// ─── AppBar neobrutalista ─────────────────────
class _NeoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _NeoAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _card,
                border: Border.all(color: _border, width: 1),
                boxShadow: const [_shadowSm],
              ),
              child: const Icon(Icons.arrow_back, color: _text, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 3, height: 14, color: _accent),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: _text,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
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
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Sliver AppBar neobrutalista ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _NeoSliverAppBar(
              title: profile.name,
              isScrolled: innerBoxIsScrolled,
            ),
          ),
          // ── Banner + identity + stats ──
          SliverToBoxAdapter(
            child: Column(
              children: [
                ProfileHeroBanner(profile: profile, isOwner: false),
                ProfileIdentityRow(profile: profile, isOwner: false),
                ProfileStatsBar(profile: profile),
              ],
            ),
          ),
          // ── Tab bar neobrutalista ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _NeoTabBarDelegate(tabs),
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

// ─── SliverPersistentHeader para AppBar ──────
class _NeoSliverAppBar extends SliverPersistentHeaderDelegate {
  final String title;
  final bool isScrolled;

  const _NeoSliverAppBar({required this.title, required this.isScrolled});

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _card,
                border: Border.all(color: _border, width: 1),
                boxShadow: const [_shadowSm],
              ),
              child: const Icon(Icons.arrow_back, color: _text, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 3, height: 14, color: _accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _text,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Badge PERFIL PÚBLICO
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _card,
              border: Border.all(color: _border, width: 1),
              boxShadow: const [_shadowSm],
            ),
            child: const Text(
              'PERFIL PÚBLICO',
              style: TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 7,
                fontWeight: FontWeight.w900,
                color: _muted,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _NeoSliverAppBar old) =>
      title != old.title || isScrolled != old.isScrolled;
}

// ─── Tab bar neobrutalista ────────────────────
class _NeoTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;

  static const _tabs = [
    (Icons.home_outlined,            'RESUMEN'),
    (Icons.history,                  'HISTORIAL'),
    (Icons.emoji_events_outlined,    'LOGROS'),
    (Icons.military_tech_outlined,   'COPAS'),
  ];

  const _NeoTabBarDelegate(this.controller);

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          height: 50,
          decoration: const BoxDecoration(
            color: _bg,
            border: Border(
              top:    BorderSide(color: _border, width: 1),
              bottom: BorderSide(color: _border, width: 1),
            ),
          ),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final (icon, label) = _tabs[i];
              final isActive = controller.index == i;

              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.animateTo(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _accent.withOpacity(0.06)
                          : Colors.transparent,
                      border: Border(
                        right: i < _tabs.length - 1
                            ? const BorderSide(color: _border, width: 1)
                            : BorderSide.none,
                        bottom: BorderSide(
                          color: isActive ? _accent : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: isActive ? 26 : 22,
                          height: isActive ? 26 : 22,
                          decoration: isActive
                              ? BoxDecoration(
                                  color: _accent,
                                  boxShadow: const [_shadowSm],
                                )
                              : null,
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            size: 12,
                            color: isActive ? Colors.white : _muted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'DM Mono',
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isActive ? _accent : _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(covariant _NeoTabBarDelegate old) =>
      controller != old.controller;
}