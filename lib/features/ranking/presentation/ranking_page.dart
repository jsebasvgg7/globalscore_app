import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/ranking_providers.dart';
import '../widgets/ranking_podium.dart';
import '../widgets/ranking_table_row.dart';
import '../widgets/ranking_stats_row.dart';
import '../widgets/hof_carousel.dart';
import '../data/ranking_service.dart';

// ── Paleta Neobrutalismo ───────────────────────────────────────────────────────
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFEAE7E1);
const _border  = Color(0xFF1A1A2E);
const _accent  = Color(0xFF5B4FD8);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF6B6580);
const _gold    = Color(0xFFC9A227);
const _shadowColor = Color(0x661A1A2E);
const _shadow   = BoxShadow(color: _shadowColor, offset: Offset(1, 1), blurRadius: 0);
const _shadowLg = BoxShadow(color: _shadowColor, offset: Offset(1, 1), blurRadius: 0);

TextStyle _mono({
  Color color = _text,
  double size = 12,
  FontWeight weight = FontWeight.normal,
  double letterSpacing = 0,
}) =>
    GoogleFonts.dmMono(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing);

class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab            = ref.watch(rankingTabProvider);
    final usersAsync     = ref.watch(rankingUsersProvider);
    final championsAsync = ref.watch(hofChampionsProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _TabBar(
            activeTab: tab,
            onTab: (t) => ref.read(rankingTabProvider.notifier).setTab(t),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _card,
                      border: Border.all(color: _border, width: 1),
                      boxShadow: const [_shadowLg],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Container(width: 4, height: 20, color: const Color(0xFFE24B4A)),
                        const SizedBox(width: 8),
                        Text('ERROR',
                            style: _mono(
                                color: const Color(0xFFE24B4A),
                                size: 10,
                                weight: FontWeight.w900,
                                letterSpacing: 2)),
                      ]),
                      const SizedBox(height: 10),
                      Text('Error cargando ranking\n$e',
                          textAlign: TextAlign.center,
                          style: _mono(color: _muted, size: 11)),
                    ]),
                  ),
                ),
              ),
              data: (users) {
                final sorted = [...users]
                  ..sort((a, b) =>
                      b.rankPoints(tab).compareTo(a.rankPoints(tab)));
                return championsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error:   (_, __) => const SizedBox.shrink(),
                  data:    (champions) => _RankingContent(
                    tab:       tab,
                    users:     users,
                    sorted:    sorted,
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
// TAB BAR — compacto: solo icono + nombre, sin subtítulo, sin exceso de padding
// ─────────────────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final String activeTab;
  final void Function(String) onTab;

  const _TabBar({required this.activeTab, required this.onTab});

  static const _tabs = [
    ('global',     Icons.public_rounded,            'GLOBAL'),
    ('monthly',    Icons.calendar_month_rounded,    'MENSUAL'),
    ('halloffame', Icons.workspace_premium_rounded, 'S. FAMA'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
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
                // ↓ padding vertical reducido: 8 top, 8 bottom
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? _accent.withOpacity(0.06) : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? _accent : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono en caja cuadrada cuando activo
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width:  isActive ? 26 : 22,
                      height: isActive ? 26 : 22,
                      decoration: isActive
                          ? BoxDecoration(
                              color: _accent,
                              boxShadow: const [
                                BoxShadow(
                                    color: _shadowColor, offset: Offset(1, 1),
                                    blurRadius: 0)
                              ],
                            )
                          : null,
                      alignment: Alignment.center,
                      child: Icon(icon,
                          size: 12,
                          color: isActive ? Colors.white : _muted),
                    ),
                    const SizedBox(height: 4),
                    // Solo el nombre — sin subtítulo
                    Text(
                      label,
                      style: _mono(
                        size: 9,
                        weight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isActive ? _accent : _muted,
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
        // Stats row
        SliverToBoxAdapter(
          child: RankingStatsRow(
            rankingType: tab,
            users:       users,
            champions:   champions,
          ),
        ),

        // Hall of Fame
        if (tab == 'halloffame') ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 32),
              child: HofCarousel(
                champions: champions,
                onSelect:  (userId) {},
              ),
            ),
          ),
        ],

        // Podio
        if (tab != 'halloffame' && sorted.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: RankingPodium(
              top3:        sorted.take(3).toList(),
              rankingType: tab,
            ),
          ),
        ],

        // Cabecera tabla
        if (tab != 'halloffame') ...[
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _card,
                border: Border(
                  top:    BorderSide(color: _border.withOpacity(0.5), width: 0.5),
                  bottom: const BorderSide(color: _border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(width: 4, height: 16, color: _accent),
                  const SizedBox(width: 8),
                  Text(
                    'CLASIFICACIÓN',
                    style: _mono(
                        size: 10,
                        weight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: _text),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: const BoxDecoration(
                      color: _accent,
                      boxShadow: [
                        BoxShadow(
                            color: _shadowColor, offset: Offset(1, 1),
                            blurRadius: 0)
                      ],
                    ),
                    child: Text(
                      tab == 'monthly' ? _currentMonthLabel() : 'GLOBAL',
                      style: _mono(
                          color: Colors.white,
                          size: 8,
                          weight: FontWeight.w800,
                          letterSpacing: 1.2),
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
                  user:        user,
                  pos:         index + 1,
                  isMe:        false,
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