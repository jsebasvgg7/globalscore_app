import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../services/dashboard_service.dart';

// ── Colores brutalist ─────────────────────────────────────────
const _bg       = Color(0xFFF0EDE8);
const _card     = Color(0xFFEAE7E1);
const _surface  = Color(0xFFF5F2EC);
const _border   = Color(0xFFC8C3B8);
const _borderH  = Color(0xFFA8A49A);
const _accent   = Color(0xFF5B4FD8);
const _accentL  = Color(0xFF8B7FC7);
const _text     = Color(0xFF2A2535);
const _muted    = Color(0xFF9B95A8);
const _green    = Color(0xFF1D9E75);
const _red      = Color(0xFFE24B4A);
const _amber    = Color(0xFFF59E0B);
const _gold     = Color(0xFFC9A227);
const _silver   = Color(0xFF9CA3AF);
const _bronze   = Color(0xFFCD7C30);

// Sombra brutalist: offset duro sin blur
const _shadow = BoxShadow(color: Color(0xFFA8A49A), offset: Offset(3, 3), blurRadius: 0);
const _shadowSm = BoxShadow(color: Color(0xFFA8A49A), offset: Offset(2, 2), blurRadius: 0);
const _shadowLg = BoxShadow(color: Color(0xFFA8A49A), offset: Offset(4, 4), blurRadius: 0);

TextStyle _mono() => GoogleFonts.dmMono();
// ─────────────────────────────────────────────────────────────
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _activeTab = 'matches';
  String _bottomTab = 'ranking';

  Future<void> _refresh() async {
    ref.invalidate(dashboardDataProvider);
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(dashboardDataProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: dashAsync.when(
          loading: () => const _BrutalistSkeleton(),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    border: Border.all(color: _borderH, width: 1.5),
                    boxShadow: const [_shadowLg],
                  ),
                  child: Column(
                    children: [
                      Text('ERROR', style: _mono().copyWith(color: _red, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text('$e', style: _mono().copyWith(color: _muted, fontSize: 11)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _refresh,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: _accent,
                            boxShadow: const [_shadowSm],
                          ),
                          child: Text('REINTENTAR', style: _mono().copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          data: (data) {
            final matches   = data['matches']  as List;
            final leagues   = data['leagues']  as List;
            final awards    = data['awards']   as List;
            final topUsers  = data['topUsers'] as List;
            final currentUser = userAsync.value;

            // Partidos de hoy o pendientes
            final today = DateTime.now();
            final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
            final pendingMatches = matches
                .where((m) => m['status'] == 'pending' || m['date'] == todayStr)
                .toList();

            final nextMatch = pendingMatches.isNotEmpty
                ? (pendingMatches..sort((a, b) {
                    final da = DateTime.tryParse('${a['date']}T${a['time'] ?? '00:00'}') ?? DateTime(2099);
                    final db = DateTime.tryParse('${b['date']}T${b['time'] ?? '00:00'}') ?? DateTime(2099);
                    return da.compareTo(db);
                  })).first
                : null;

            // Predicciones guardadas vs total pendientes
            final userId = currentUser?['id'] as String?;
            final savedCount = pendingMatches.where((m) {
              final preds = (m['predictions'] as List?) ?? [];
              return preds.any((p) => p['user_id'] == userId);
            }).length;
            final totalCount = pendingMatches.length;

            // Previews
            final previewMatches = pendingMatches.take(4).toList();
            final previewLeagues = leagues.take(3).toList();
            final previewAwards  = awards.take(3).toList();

            return RefreshIndicator(
              onRefresh: _refresh,
              color: _accent,
              backgroundColor: _card,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Progress bar ──────────────────────────
                    _ProgressBar(saved: savedCount, total: totalCount),

                    // ── Próximo partido banner ────────────────
                    _NextMatchBanner(match: nextMatch),

                    // ── Tabs + horizontal scroll ──────────────
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _TabBar(
                        activeTab: _activeTab,
                        onTabChange: (t) => setState(() => _activeTab = t),
                        counts: {
                          'matches': pendingMatches.length,
                          'leagues': leagues.length,
                          'awards':  awards.length,
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                        children: [
                          if (_activeTab == 'matches') ...[
                            if (previewMatches.isEmpty)
                              _EmptyMatchCard()
                            else ...[
                              ...previewMatches.map((m) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: _MiniMatchCard(match: m, userId: userId),
                              )),
                              _MoreCard(),
                            ],
                          ],
                          if (_activeTab == 'leagues') ...[
                            if (previewLeagues.isEmpty)
                              _EmptyCard(label: 'SIN\nLIGAS\nACTIVAS')
                            else ...[
                              ...previewLeagues.map((l) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: _MiniLeagueCard(league: l, userId: userId),
                              )),
                              _MoreCard(),
                            ],
                          ],
                          if (_activeTab == 'awards') ...[
                            if (previewAwards.isEmpty)
                              _EmptyCard(label: 'SIN\nPREMIOS\nACTIVOS')
                            else ...[
                              ...previewAwards.map((a) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: _MiniAwardCard(award: a, userId: userId),
                              )),
                              _MoreCard(),
                            ],
                          ],
                        ],
                      ),
                    ),

                    // ── Bottom: Ranking / Stats ───────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: _BottomTabBar(
                        activeTab: _bottomTab,
                        onTabChange: (t) => setState(() => _bottomTab = t),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_bottomTab == 'ranking')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _PodiumPanel(topUsers: topUsers, currentUser: currentUser),
                      ),
                    if (_bottomTab == 'stats')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _StatsPanel(user: currentUser),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Progress Bar ──────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int saved;
  final int total;
  const _ProgressBar({required this.saved, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (saved / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _borderH, width: 1.5),
        boxShadow: const [_shadow],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('PREDIC.', style: _mono().copyWith(color: _muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: _accent, width: 1.5),
                      color: _accent.withValues(alpha: 0.08),
                      boxShadow: const [_shadowSm],
                    ),
                    child: Text('[$saved/$total]', style: _mono().copyWith(color: _accent, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _surface,
                  border: Border.all(color: _borderH, width: 1.5),
                  boxShadow: const [_shadowSm],
                ),
                child: const Icon(Icons.book_outlined, color: _accent, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: _bg,
              border: Border.all(color: _borderH, width: 1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(color: _accent),
            ),
          ),
        ],
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
        margin: const EdgeInsets.fromLTRB(18, 13, 18, 0),
        decoration: BoxDecoration(
          color: _card,
          border: Border(
            top: const BorderSide(color: _accent, width: 3),
            left: const BorderSide(color: _borderH, width: 1.5),
            right: const BorderSide(color: _borderH, width: 1.5),
            bottom: const BorderSide(color: _borderH, width: 1.5),
          ),
          boxShadow: const [_shadowLg],
        ),
        child: Row(
          children: [
            Container(
              width: 78,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: _bg,
                border: Border(right: BorderSide(color: _borderH, width: 1.5)),
              ),
              child: Column(
                children: [
                  Text('0', style: _mono().copyWith(color: _borderH, fontSize: 44, fontWeight: FontWeight.w700, letterSpacing: -3)),
                  const SizedBox(height: 6),
                  Column(
                    children: [
                      Container(height: 1.5, width: 40, color: _borderH),
                      const SizedBox(height: 3),
                      Container(height: 1.5, width: 26, color: _accent),
                      const SizedBox(height: 3),
                      Container(height: 1.5, width: 16, color: _borderH),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('// PRÓXIMO PARTIDO', style: _mono().copyWith(color: _accent, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 2.2)),
                    const SizedBox(height: 6),
                    Text('SIN\nPARTIDOS', style: _mono().copyWith(color: _text, fontSize: 22, fontWeight: FontWeight.w700, height: 1.05)),
                    const SizedBox(height: 6),
                    Container(width: 32, height: 2, color: _accent),
                    const SizedBox(height: 5),
                    Text('TEMPORADA AL DÍA', style: _mono().copyWith(color: _muted, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 1.8)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final m = match!;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 13, 18, 0),
      decoration: BoxDecoration(
        color: _card,
        border: Border(
          top: const BorderSide(color: _accent, width: 3),
          left: const BorderSide(color: _borderH, width: 1.5),
          right: const BorderSide(color: _borderH, width: 1.5),
          bottom: const BorderSide(color: _borderH, width: 1.5),
        ),
        boxShadow: const [_shadowLg],
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: const BoxDecoration(
              color: _bg,
              border: Border(bottom: BorderSide(color: _borderH, width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PRÓXIMO PARTIDO · ${(m['league'] ?? '').toString().toUpperCase()}',
                    style: _mono().copyWith(color: _muted, fontSize: 7, letterSpacing: 1.8)),
                Text(m['date'] ?? '—', style: _mono().copyWith(color: _muted, fontSize: 7, letterSpacing: 1.2)),
              ],
            ),
          ),
          // Teams
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              children: [
                Expanded(child: _NmTeam(name: m['home_team'] ?? '—', logoUrl: m['home_team_logo_url'])),
                SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      Text('VS', style: _mono().copyWith(color: _muted, fontSize: 7, letterSpacing: 3.2)),
                      const SizedBox(height: 2),
                      Text(m['time'] ?? '—', style: _mono().copyWith(color: _text, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                    ],
                  ),
                ),
                Expanded(child: _NmTeam(name: m['away_team'] ?? '—', logoUrl: m['away_team_logo_url'])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NmTeam extends StatelessWidget {
  final String name;
  final String? logoUrl;
  const _NmTeam({required this.name, this.logoUrl});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: logoUrl != null
              ? Image.network(logoUrl!, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('⚽', style: TextStyle(fontSize: 28)))
              : const Text('⚽', style: TextStyle(fontSize: 28)),
        ),
        const SizedBox(height: 6),
        Text(
          (name.length > 8 ? name.substring(0, 8) : name).toUpperCase(),
          textAlign: TextAlign.center,
          style: _mono().copyWith(color: _text, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
      ],
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChange;
  final Map<String, int> counts;
  const _TabBar({required this.activeTab, required this.onTabChange, required this.counts});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'id': 'matches', 'label': 'Partidos'},
      {'id': 'leagues', 'label': 'Ligas'},
      {'id': 'awards',  'label': 'Premios'},
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderH, width: 1.5)),
      ),
      child: Row(
        children: tabs.map((t) {
          final id = t['id']!;
          final isActive = activeTab == id;
          return GestureDetector(
            onTap: () => onTabChange(id),
            child: Container(
              margin: const EdgeInsets.only(right: 22),
              padding: const EdgeInsets.only(bottom: 9),
              decoration: isActive
                  ? const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _accent, width: 2.5)),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['label']!,
                    style: _mono().copyWith(
                      color: isActive ? _text : _muted,
                      fontSize: isActive ? 20 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${counts[id] ?? 0} items',
                    style: _mono().copyWith(
                      color: isActive ? _accent : _muted,
                      fontSize: 7,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Mini Match Card ───────────────────────────────────────────
class _MiniMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final String? userId;
  const _MiniMatchCard({required this.match, this.userId});

  Color get _accentColor {
    if (match['status'] == 'live') return _amber;
    final hasPred = _myPred != null;
    if (hasPred) return _green;
    final deadline = match['deadline'];
    if (deadline != null && DateTime.now().isAfter(DateTime.parse(deadline))) return _red;
    return _accent;
  }

  Map? get _myPred {
    final preds = (match['predictions'] as List?) ?? [];
    try { return preds.firstWhere((p) => p['user_id'] == userId) as Map; }
    catch (_) { return null; }
  }

  String get _pillLabel {
    if (match['status'] == 'live') return 'VIVO';
    if (_myPred != null) return 'GUARD.';
    final deadline = match['deadline'];
    if (deadline != null && DateTime.now().isAfter(DateTime.parse(deadline))) return 'CERR.';
    return 'PEND.';
  }

  @override
  Widget build(BuildContext context) {
    final m = match;
    final pred = _myPred;
    final ac = _accentColor;

    return Container(
      width: 164,
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _borderH, width: 1.5),
        boxShadow: const [_shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent top bar
          Container(height: 3, color: ac),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: _bg, border: Border.all(color: _borderH, width: 1.5),
                          boxShadow: const [_shadowSm],
                        ),
                        child: m['league_logo_url'] != null
                            ? Image.network(m['league_logo_url'], fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Text('🏆', style: TextStyle(fontSize: 9)))
                            : const Center(child: Text('🏆', style: TextStyle(fontSize: 9))),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        ((m['league'] ?? 'LIGA').toString()).substring(0, (m['league'] ?? 'LIGA').toString().length.clamp(0, 6)).toUpperCase(),
                        style: _mono().copyWith(color: _muted, fontSize: 7, letterSpacing: 1.2),
                      ),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ac.withValues(alpha: 0.1),
                        border: Border.all(color: ac, width: 1.5),
                        boxShadow: const [_shadowSm],
                      ),
                      child: Text(_pillLabel, style: _mono().copyWith(color: ac, fontSize: 7, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Home team
                _MiniTeamRow(
                  name: m['home_team'] ?? '—',
                  logoUrl: m['home_team_logo_url'],
                  score: pred?['home_score'],
                  hasPred: pred != null,
                ),
                Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(vertical: 1)),
                // Away team
                _MiniTeamRow(
                  name: m['away_team'] ?? '—',
                  logoUrl: m['away_team_logo_url'],
                  score: pred?['away_score'],
                  hasPred: pred != null,
                ),
                const SizedBox(height: 8),
                // Footer
                Container(
                  padding: const EdgeInsets.only(top: 7),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: _border))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.access_time, size: 9, color: _muted),
                        const SizedBox(width: 3),
                        Text(m['time'] ?? '—', style: _mono().copyWith(color: _muted, fontSize: 7)),
                      ]),
                      Text(m['date'] ?? '—', style: _mono().copyWith(color: _muted, fontSize: 7)),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTeamRow extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final dynamic score;
  final bool hasPred;
  const _MiniTeamRow({required this.name, this.logoUrl, this.score, required this.hasPred});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 20, height: 20,
            child: logoUrl != null
                ? Image.network(logoUrl!, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text('⚽', style: TextStyle(fontSize: 15)))
                : const Text('⚽', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              (name.length > 8 ? name.substring(0, 8) : name).toUpperCase(),
              style: _mono().copyWith(color: _text, fontSize: 10, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: hasPred ? _accent.withValues(alpha: 0.1) : _bg,
              border: Border.all(color: hasPred ? _accent : _borderH, width: 1.5),
              boxShadow: const [_shadowSm],
            ),
            alignment: Alignment.center,
            child: Text(
              hasPred ? '${score ?? '—'}' : '—',
              style: _mono().copyWith(
                color: hasPred ? _accent : _muted,
                fontSize: hasPred ? 12 : 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini League Card ──────────────────────────────────────────
class _MiniLeagueCard extends StatelessWidget {
  final Map<String, dynamic> league;
  final String? userId;
  const _MiniLeagueCard({required this.league, this.userId});

  Map? get _myPred {
    final preds = (league['league_predictions'] as List?) ?? [];
    try { return preds.firstWhere((p) => p['user_id'] == userId) as Map; } catch (_) { return null; }
  }

  Color get _ac {
    if (league['status'] == 'finished') return _red;
    final pred = _myPred;
    if (pred != null) return _green;
    final deadline = league['deadline'];
    if (deadline != null && DateTime.now().isAfter(DateTime.parse(deadline))) return _red;
    return _accent;
  }

  @override
  Widget build(BuildContext context) {
    final l = league;
    final pred = _myPred;
    final champion = pred?['predicted_champion'] as String?;
    final ac = _ac;

    return Container(
      width: 236,
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _borderH, width: 1.5),
        boxShadow: const [_shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, color: ac),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(color: _bg, border: Border.all(color: _borderH, width: 1.5), boxShadow: const [_shadowSm]),
                      child: const Center(child: Text('🏆', style: TextStyle(fontSize: 9))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text((l['name'] ?? 'LIGA').toString().toUpperCase(),
                            style: _mono().copyWith(color: _text, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
                            overflow: TextOverflow.ellipsis),
                        Text(l['season'] ?? '—', style: _mono().copyWith(color: _muted, fontSize: 7, letterSpacing: 1)),
                      ]),
                    ),
                    Container(
                      width: 7, height: 7,
                      color: ac,
                      margin: const EdgeInsets.only(left: 8),
                    ),
                  ],
                ),
                Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(vertical: 10)),
                Text('CAMPEÓN', style: _mono().copyWith(color: _muted, fontSize: 6, fontWeight: FontWeight.w700, letterSpacing: 2)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  decoration: BoxDecoration(
                    color: champion != null ? _accent.withValues(alpha: 0.08) : _bg,
                    border: Border(
                      left: BorderSide(color: champion != null ? _accent : _borderH, width: champion != null ? 2.5 : 1.5),
                      top: BorderSide(color: _borderH, width: 1.5),
                      right: BorderSide(color: _borderH, width: 1.5),
                      bottom: BorderSide(color: _borderH, width: 1.5),
                    ),
                  ),
                  child: Text(
                    champion ?? 'Escribe el equipo...',
                    style: _mono().copyWith(
                      color: champion != null ? _accent : _muted,
                      fontSize: 9,
                      fontWeight: champion != null ? FontWeight.w700 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Award Card ───────────────────────────────────────────
class _MiniAwardCard extends StatelessWidget {
  final Map<String, dynamic> award;
  final String? userId;
  const _MiniAwardCard({required this.award, this.userId});

  Map? get _myPred {
    final preds = (award['award_predictions'] as List?) ?? [];
    try { return preds.firstWhere((p) => p['user_id'] == userId) as Map; } catch (_) { return null; }
  }

  Color get _ac {
    if (award['status'] == 'finished') return _red;
    final pred = _myPred;
    if (pred != null) return _green;
    final deadline = award['deadline'];
    if (deadline != null && DateTime.now().isAfter(DateTime.parse(deadline))) return _red;
    return _accent;
  }

  @override
  Widget build(BuildContext context) {
    final a = award;
    final pred = _myPred;
    final winner = pred?['predicted_winner'] as String?;
    final ac = _ac;

    return Container(
      width: 216,
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _borderH, width: 1.5),
        boxShadow: const [_shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, color: ac),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(color: _bg, border: Border.all(color: _borderH, width: 1.5), boxShadow: const [_shadowSm]),
                      child: Center(child: Text(a['logo'] ?? '🏅', style: const TextStyle(fontSize: 9))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text((a['name'] ?? 'PREMIO').toString().toUpperCase(),
                            style: _mono().copyWith(color: _text, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
                            overflow: TextOverflow.ellipsis),
                        Text(a['season'] ?? '—', style: _mono().copyWith(color: _muted, fontSize: 7, letterSpacing: 1)),
                      ]),
                    ),
                    Container(width: 7, height: 7, color: ac, margin: const EdgeInsets.only(left: 8)),
                  ],
                ),
                Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(vertical: 10)),
                Text('TU PREDICCIÓN', style: _mono().copyWith(color: _muted, fontSize: 6, fontWeight: FontWeight.w700, letterSpacing: 2)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  decoration: BoxDecoration(
                    color: winner != null ? _accent.withValues(alpha: 0.08) : _bg,
                    border: Border(
                      left: BorderSide(color: winner != null ? _accent : _borderH, width: winner != null ? 2.5 : 1.5),
                      top: BorderSide(color: _borderH, width: 1.5),
                      right: BorderSide(color: _borderH, width: 1.5),
                      bottom: BorderSide(color: _borderH, width: 1.5),
                    ),
                  ),
                  child: Text(
                    winner ?? 'Ingresa el nombre...',
                    style: _mono().copyWith(
                      color: winner != null ? _accent : _muted,
                      fontSize: 9,
                      fontWeight: winner != null ? FontWeight.w700 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── More Card ─────────────────────────────────────────────────
class _MoreCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: _card,
        border: Border(
          top: const BorderSide(color: _accent, width: 2.5),
          left: const BorderSide(color: _borderH, width: 1.5),
          right: const BorderSide(color: _borderH, width: 1.5),
          bottom: const BorderSide(color: _borderH, width: 1.5),
        ),
        boxShadow: const [_shadow],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('»', style: _mono().copyWith(color: _accent, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('TODOS', style: _mono().copyWith(color: _accent, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
        ],
      ),
    );
  }
}

// ── Empty Cards ───────────────────────────────────────────────
class _EmptyMatchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      decoration: BoxDecoration(
        color: _card,
        border: Border(
          top: const BorderSide(color: _accent, width: 2.5),
          left: const BorderSide(color: _borderH, width: 1.5),
          right: const BorderSide(color: _borderH, width: 1.5),
          bottom: const BorderSide(color: _borderH, width: 1.5),
        ),
        boxShadow: const [_shadow],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('00', style: _mono().copyWith(color: _borderH, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -1)),
          Container(width: 22, height: 1.5, color: _accent, margin: const EdgeInsets.symmetric(vertical: 5)),
          Text('SIN\nPARTIDOS\nPEND.', textAlign: TextAlign.center,
              style: _mono().copyWith(color: _muted, fontSize: 6, fontWeight: FontWeight.w700, letterSpacing: 1.4, height: 1.6)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String label;
  const _EmptyCard({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _borderH, width: 1.5),
        boxShadow: const [_shadow],
      ),
      child: Center(
        child: Text(label, textAlign: TextAlign.center,
            style: _mono().copyWith(color: _muted, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 1.4, height: 1.6)),
      ),
    );
  }
}

// ── Bottom Tab Bar ────────────────────────────────────────────
class _BottomTabBar extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChange;
  const _BottomTabBar({required this.activeTab, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'id': 'ranking', 'label': 'Ranking', 'count': '3 items'},
      {'id': 'stats',   'label': 'Stats',   'count': '4 items'},
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderH, width: 1.5)),
      ),
      child: Row(
        children: tabs.map((t) {
          final id = t['id']!;
          final isActive = activeTab == id;
          return GestureDetector(
            onTap: () => onTabChange(id),
            child: Container(
              margin: const EdgeInsets.only(right: 22),
              padding: const EdgeInsets.only(bottom: 9),
              decoration: isActive
                  ? const BoxDecoration(border: Border(bottom: BorderSide(color: _accent, width: 2.5)))
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['label']!,
                    style: _mono().copyWith(
                      color: isActive ? _text : _muted,
                      fontSize: isActive ? 20 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    t['count']!,
                    style: _mono().copyWith(
                      color: isActive ? _accent : _muted,
                      fontSize: 7, letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Podium Panel ──────────────────────────────────────────────
class _PodiumPanel extends StatelessWidget {
  final List topUsers;
  final Map<String, dynamic>? currentUser;
  const _PodiumPanel({required this.topUsers, this.currentUser});

  @override
  Widget build(BuildContext context) {
    if (topUsers.length < 3) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _card, border: Border.all(color: _borderH, width: 1.5), boxShadow: const [_shadow]),
        child: Center(child: Text('SIN DATOS DE RANKING', style: _mono().copyWith(color: _muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2))),
      );
    }

    final visual = [topUsers[1], topUsers[0], topUsers[2]];
    final cols   = ['2nd', '1st', '3rd'];
    final medals = ['PLATA', 'ORO', 'BRONCE'];
    final avSizes  = [42.0, 52.0, 38.0];
    final stepH    = [28.0, 40.0, 16.0];
    final avColors = [_accentL, _accent, _accentL];
    final borderCs = [_silver, _gold, _bronze];
    final stepCs   = [
      Color(0xFF9CA3AF).withValues(alpha: 0.1),
      Color(0xFFC9A227).withValues(alpha: 0.1),
      Color(0xFFCD7C30).withValues(alpha: 0.1),
    ];
    final stepBorderCs = [_silver, _gold, _bronze];
    final ptCs = [_silver, _gold, _bronze];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _borderH, width: 1.5),
        boxShadow: const [_shadowLg],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 5, height: 5, color: _accent),
              const SizedBox(width: 8),
              Text('RANKING GLOBAL', style: _mono().copyWith(color: _muted, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 2.2)),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: _border)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final u = visual[i] as Map<String, dynamic>;
              final isMe = u['id'] == currentUser?['id'];
              final name = (u['name'] ?? '—').toString();
              final pts = u['points'] ?? 0;
              final av = u['avatar_url'] as String?;
              final sz = avSizes[i];

              return Expanded(
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: sz, height: sz,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: avColors[i],
                        border: Border.all(color: borderCs[i], width: i == 1 ? 2 : 1.5),
                        boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(i == 1 ? 3 : 2, i == 1 ? 3 : 2))],
                      ),
                      child: av != null
                          ? Image.network(av, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(child: Text(name[0].toUpperCase(),
                                  style: TextStyle(color: Colors.white, fontSize: sz * 0.32, fontWeight: FontWeight.w800))))
                          : Center(child: Text(name[0].toUpperCase(),
                              style: TextStyle(color: Colors.white, fontSize: sz * 0.32, fontWeight: FontWeight.w800))),
                    ),
                    const SizedBox(height: 4),
                    Text((name.length > 8 ? name.substring(0, 8) : name).toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: _mono().copyWith(color: _text, fontSize: 7, fontWeight: FontWeight.w700)),
                    if (isMe)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          border: Border.all(color: _accent, width: 1.5),
                          color: _accent.withValues(alpha: 0.08),
                          boxShadow: [const BoxShadow(color: Color(0x4D5B4FD8), offset: Offset(1, 1))],
                        ),
                        child: Text('TÚ', style: _mono().copyWith(color: _accent, fontSize: 6, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                    Text('$pts', style: _mono().copyWith(color: ptCs[i], fontSize: 10, fontWeight: FontWeight.w700)),
                    Text(medals[i], style: _mono().copyWith(color: ptCs[i], fontSize: 6, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                    const SizedBox(height: 4),
                    // Pedestal
                    Container(
                      width: double.infinity,
                      height: stepH[i],
                      decoration: BoxDecoration(
                        color: stepCs[i],
                        border: Border(top: BorderSide(color: stepBorderCs[i], width: 2)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Stats Panel ───────────────────────────────────────────────
class _StatsPanel extends StatelessWidget {
  final Map<String, dynamic>? user;
  const _StatsPanel({this.user});

  @override
  Widget build(BuildContext context) {
    final u = user ?? {};
    final points      = u['points']      ?? 0;
    final correct     = u['correct']     ?? 0;
    final predictions = u['predictions'] ?? 0;
    final accuracy    = predictions > 0 ? ((correct / predictions) * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _borderH, width: 1.5),
        boxShadow: const [_shadowLg],
      ),
      child: Column(
        children: [
          _StatRow(value: '$points', unit: 'pts', label: 'Puntos', accent: true),
          Container(height: 1, color: _border),
          _StatRow(value: '$correct', label: 'Aciertos'),
          Container(height: 1, color: _border),
          _StatRowBar(value: '$accuracy', unit: '%', label: 'Precisión', pct: accuracy / 100),
          Container(height: 1, color: _border),
          _StatRow(value: '$predictions', label: 'Predicciones'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String value;
  final String? unit;
  final String label;
  final bool accent;
  const _StatRow({required this.value, required this.label, this.unit, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _mono().copyWith(color: _muted, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
          Row(children: [
            Text(value, style: _mono().copyWith(color: accent ? _accent : _text, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -1.5)),
            if (unit != null)
              Text(unit!, style: _mono().copyWith(color: _muted, fontSize: 8, letterSpacing: 0)),
          ]),
        ],
      ),
    );
  }
}

class _StatRowBar extends StatelessWidget {
  final String value;
  final String? unit;
  final String label;
  final double pct;
  const _StatRowBar({required this.value, required this.label, this.unit, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: _mono().copyWith(color: _muted, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
              Row(children: [
                Text(value, style: _mono().copyWith(color: _green, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -1.5)),
                if (unit != null) Text(unit!, style: _mono().copyWith(color: _muted, fontSize: 8)),
              ]),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            decoration: BoxDecoration(color: _bg, border: Border.all(color: _borderH, width: 1)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(color: _accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────
class _BrutalistSkeleton extends StatelessWidget {
  const _BrutalistSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _SkBox(height: 70),
          const SizedBox(height: 13),
          _SkBox(height: 120),
          const SizedBox(height: 14),
          _SkBox(height: 36),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _SkBox(height: 160)),
            const SizedBox(width: 10),
            Expanded(child: _SkBox(height: 160)),
          ]),
        ],
      ),
    );
  }
}

class _SkBox extends StatelessWidget {
  final double height;
  const _SkBox({required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border, width: 1.5),
        boxShadow: const [_shadow],
      ),
    );
  }
}
