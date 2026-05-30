import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/match_card.dart';
import '../widgets/league_card.dart';
import '../widgets/award_card.dart';
import '../widgets/podium_widget.dart';
import '../services/dashboard_service.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomTab = 0; // 0: ranking, 1: stats

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(dashboardDataProvider);
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(dashboardDataProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: dashAsync.when(
          loading: () => const _DashboardSkeleton(),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Error: $e', style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
          data: (data) {
            final matches = data['matches'] as List;
            final leagues = data['leagues'] as List;
            final awards = data['awards'] as List;
            final topUsers = data['topUsers'] as List;
            final currentUser = userAsync.value;

            final pendingMatches = matches
                .where((m) => m['status'] == 'pending')
                .toList();
            final nextMatch = pendingMatches.isNotEmpty ? pendingMatches.first : null;

            return RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF00E5FF),
              backgroundColor: const Color(0xFF1A1A2E),
              child: CustomScrollView(
                slivers: [
                  // ── Header con próximo partido ──────────────
                  SliverToBoxAdapter(
                    child: _NextMatchBanner(match: nextMatch),
                  ),

                  // ── Tabs: Partidos / Ligas / Premios ────────
                  SliverToBoxAdapter(
                    child: _TabBar(controller: _tabController),
                  ),

                  // ── Contenido de tabs ────────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 320,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Partidos
                          _HorizontalScroll(
                            children: pendingMatches.isEmpty
                                ? [const _EmptyCard(label: 'Sin partidos pendientes')]
                                : pendingMatches.take(4).map((m) => MatchCard(
                                    match: m,
                                    onPredict: (matchId, home, away, adv) async {
                                      await DashboardService.upsertMatchPrediction(
                                        matchId: matchId,
                                        userId: currentUser!['id'],
                                        homeScore: home,
                                        awayScore: away,
                                        advancingTeam: adv,
                                      );
                                      _refresh();
                                    },
                                  )).toList(),
                          ),
                          // Ligas
                          _HorizontalScroll(
                            children: leagues.isEmpty
                                ? [const _EmptyCard(label: 'Sin ligas activas')]
                                : leagues.take(3).map((l) => LeagueCard(
                                    league: l,
                                    onPredict: (leagueId, champion, scorer, assist, mvp) async {
                                      await DashboardService.upsertLeaguePrediction(
                                        leagueId: leagueId,
                                        userId: currentUser!['id'],
                                        champion: champion,
                                        topScorer: scorer,
                                        topAssist: assist,
                                        mvp: mvp,
                                      );
                                      _refresh();
                                    },
                                  )).toList(),
                          ),
                          // Premios
                          _HorizontalScroll(
                            children: awards.isEmpty
                                ? [const _EmptyCard(label: 'Sin premios activos')]
                                : awards.take(3).map((a) => AwardCard(
                                    award: a,
                                    onPredict: (awardId, winner) async {
                                      await DashboardService.upsertAwardPrediction(
                                        awardId: awardId,
                                        userId: currentUser!['id'],
                                        predictedWinner: winner,
                                      );
                                      _refresh();
                                    },
                                  )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Sección inferior: Ranking / Stats ────────
                  SliverToBoxAdapter(
                    child: _BottomSection(
                      topUsers: topUsers,
                      currentUser: currentUser,
                      activeTab: _bottomTab,
                      onTabChange: (i) => setState(() => _bottomTab = i),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Next Match Banner ─────────────────────────────────────────
class _NextMatchBanner extends StatelessWidget {
  final Map<String, dynamic>? match;
  const _NextMatchBanner({this.match});

  @override
  Widget build(BuildContext context) {
    if (match == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF00E5FF), size: 20),
            SizedBox(width: 10),
            Text('Al día — sin partidos pendientes',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5B4FD8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRÓXIMO PARTIDO',
              style: TextStyle(
                  fontSize: 9,
                  color: Colors.white54,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TeamPill(name: match!['home_team'] ?? '—', logoUrl: match!['home_team_logo_url']),
              const Text('VS',
                  style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w800, fontSize: 13)),
              _TeamPill(name: match!['away_team'] ?? '—', logoUrl: match!['away_team_logo_url']),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.white60),
              const SizedBox(width: 4),
              Text(match!['time'] ?? '—',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Text(match!['date'] ?? '—',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamPill extends StatelessWidget {
  final String name;
  final String? logoUrl;
  const _TeamPill({required this.name, this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(logoUrl!, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, color: Colors.white38, size: 20)))
              : const Icon(Icons.sports_soccer, color: Colors.white38, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          name.substring(0, name.length.clamp(0, 8)).toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: controller,
        indicatorColor: const Color(0xFF00E5FF),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: const Color(0xFF00E5FF),
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        tabs: const [
          Tab(text: 'PARTIDOS'),
          Tab(text: 'LIGAS'),
          Tab(text: 'PREMIOS'),
        ],
      ),
    );
  }
}

// ── Horizontal Scroll ─────────────────────────────────────────
class _HorizontalScroll extends StatelessWidget {
  final List<Widget> children;
  const _HorizontalScroll({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, i) => children[i],
    );
  }
}

// ── Empty Card ────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final String label;
  const _EmptyCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ),
    );
  }
}

// ── Bottom Section ────────────────────────────────────────────
class _BottomSection extends StatelessWidget {
  final List topUsers;
  final Map<String, dynamic>? currentUser;
  final int activeTab;
  final ValueChanged<int> onTabChange;

  const _BottomSection({
    required this.topUsers,
    required this.currentUser,
    required this.activeTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Tab selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _BottomTab(label: 'Ranking', active: activeTab == 0, onTap: () => onTabChange(0)),
              const SizedBox(width: 8),
              _BottomTab(label: 'Stats', active: activeTab == 1, onTap: () => onTabChange(1)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (activeTab == 0) PodiumWidget(users: topUsers, currentUser: currentUser),
        if (activeTab == 1) _StatsPanel(user: currentUser),
      ],
    );
  }
}

class _BottomTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _BottomTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00E5FF).withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? const Color(0xFF00E5FF) : Colors.white12,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? const Color(0xFF00E5FF) : Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final Map<String, dynamic>? user;
  const _StatsPanel({this.user});

  @override
  Widget build(BuildContext context) {
    final u = user ?? {};
    final points = u['points'] ?? 0;
    final correct = u['correct'] ?? 0;
    final predictions = u['predictions'] ?? 0;
    final accuracy = predictions > 0 ? ((correct / predictions) * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatCell(value: '$points', label: 'Puntos', accent: true),
            _StatCell(value: '$correct', label: 'Aciertos'),
            _StatCell(value: '$accuracy%', label: 'Precisión', green: true),
            _StatCell(value: '$predictions', label: 'Predicciones'),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;
  final bool green;
  const _StatCell({required this.value, required this.label, this.accent = false, this.green = false});

  @override
  Widget build(BuildContext context) {
    final color = accent
        ? const Color(0xFF00E5FF)
        : green
            ? const Color(0xFF34D399)
            : Colors.white;

    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}

// ── Skeleton loading ──────────────────────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SkBox(height: 90, radius: 12),
          const SizedBox(height: 14),
          _SkBox(height: 40, radius: 10),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _SkBox(height: 260, radius: 12)),
            const SizedBox(width: 12),
            Expanded(child: _SkBox(height: 260, radius: 12)),
          ]),
        ],
      ),
    );
  }
}

class _SkBox extends StatelessWidget {
  final double height;
  final double radius;
  const _SkBox({required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}