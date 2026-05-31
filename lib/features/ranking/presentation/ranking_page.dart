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
      body: Column(
        children: [
          _TabBar(
            activeTab: tab,
            onTab: (t) => ref.read(rankingTabProvider.notifier).setTab(t),
          ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TABS — estilo fiel al diseño original
// ─────────────────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final String activeTab;
  final void Function(String) onTab;

  const _TabBar({required this.activeTab, required this.onTab});

  static const _tabs = [
    ('global',     Icons.public_rounded,             'GLOBAL'),
    ('monthly',    Icons.calendar_month_rounded,     'MENSUAL'),
    ('halloffame', Icons.workspace_premium_rounded,  'S. FAMA'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(
          bottom: BorderSide(color: Color(0x14000000), width: 1),
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
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? _kAccent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 12,
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
                        letterSpacing: 0.6,
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
        SliverToBoxAdapter(
          child: RankingStatsRow(
            rankingType: tab,
            users: users,
            champions: champions,
          ),
        ),
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
        if (tab != 'halloffame' && sorted.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: RankingPodium(
              top3: sorted.take(3).toList(),
              rankingType: tab,
            ),
          ),
        ],
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
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = sorted[index];
                return RankingTableRow(
                  user: user,
                  pos: index + 1,
                  isMe: false,
                  rankingType: tab,
                );
              },
              childCount: sorted.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ],
    );
  }

  String _currentMonthLabel() {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }
}