import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ranking_providers.dart';
import 'widgets/ranking_podium.dart';
import 'widgets/ranking_table_row.dart';
import 'widgets/ranking_stats_row.dart';
import 'widgets/hof_carousel.dart';
import '../data/ranking_service.dart';

const _kAccent = Color(0xFF5B4FD8);
const _kBg = Color(0xFFF0EDE8);

class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(rankingTabProvider);
    final usersAsync = ref.watch(rankingUsersProvider);
    final championsAsync = ref.watch(hofChampionsProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _Header(),

            // ── Tabs ────────────────────────────────────────────
            _TabBar(
              activeTab: tab,
              onTab: (t) => ref.read(rankingTabProvider.notifier).setTab(t),
            ),

            // ── Content ─────────────────────────────────────────
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _kAccent),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error cargando ranking\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF888880), fontFamily: 'DMMono'),
                  ),
                ),
                data: (users) {
                  final sorted = [...users]
                    ..sort((a, b) =>
                        b.rankPoints(tab).compareTo(a.rankPoints(tab)));

                  return championsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (champions) => _RankingContent(
                      tab: tab,
                      users: users,
                      sorted: sorted,
                      champions: champions,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.08), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Ranking',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              fontFamily: 'DMMono',
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFC9A227), size: 22),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TABS
// ─────────────────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final String activeTab;
  final void Function(String) onTab;

  const _TabBar({required this.activeTab, required this.onTab});

  static const _tabs = [
    ('global', Icons.public_rounded, 'GLOBAL'),
    ('monthly', Icons.calendar_month_rounded, 'MENSUAL'),
    ('halloffame', Icons.workspace_premium_rounded, 'S. FAMA'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.08), width: 0.5),
        ),
      ),
      child: Row(
        children: _tabs.map((t) {
          final (key, icon, label) = t;
          final isActive = activeTab == key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTab(key),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? _kAccent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: isActive
                          ? _kAccent
                          : const Color(0xFF888880),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isActive
                            ? _kAccent
                            : const Color(0xFF888880),
                        fontFamily: 'DMMono',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT
// ─────────────────────────────────────────────────────────────────────────────
class _RankingContent extends ConsumerWidget {
  final String tab;
  final List<RankingUser> users;
  final List<RankingUser> sorted;
  final List<HofChampion> champions;

  const _RankingContent({
    required this.tab,
    required this.users,
    required this.sorted,
    required this.champions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Stats row ──
        SliverToBoxAdapter(
          child: RankingStatsRow(
            rankingType: tab,
            users: users,
            champions: champions,
          ),
        ),

        // ── Hall of Fame ──
        if (tab == 'halloffame') ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 32),
              child: HofCarousel(
                champions: champions,
                onSelect: (userId) {
                  // TODO: navigate to PublicProfilePage(userId)
                },
              ),
            ),
          ),
        ],

        // ── Podio ──
        if (tab != 'halloffame' && sorted.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: RankingPodium(
              top3: sorted.take(3).toList(),
              rankingType: tab,
            ),
          ),
        ],

        // ── Tabla header ──
        if (tab != 'halloffame') ...[
          SliverToBoxAdapter(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E4DE),
                border: Border(
                  top: BorderSide(
                      color: Colors.black.withOpacity(0.07), width: 0.5),
                  bottom: BorderSide(
                      color: Colors.black.withOpacity(0.07), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CLASIFICACIÓN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: Color(0xFF888880),
                      fontFamily: 'DMMono',
                    ),
                  ),
                  Text(
                    tab == 'monthly' ? _currentMonthLabel() : 'GLOBAL',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Color(0xFF5B4FD8),
                      fontFamily: 'DMMono',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Rows ──
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = sorted[index];
                return RankingTableRow(
                  user: user,
                  pos: index + 1,
                  isMe: false, // TODO: compare with current user id
                  rankingType: tab,
                );
              },
              childCount: sorted.length,
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ],
    );
  }

  String _currentMonthLabel() {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final now = DateTime.now();
    return '${months[now.month - 1].toUpperCase()} ${now.year}';
  }
}