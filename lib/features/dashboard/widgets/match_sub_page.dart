import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../services/dashboard_service.dart';

// ── Colores (mismo sistema brutalist del dashboard) ───────────
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFEAE7E1);
const _surface = Color(0xFFF5F2EC);
const _border  = Color(0xFFC8C3B8);
const _borderH = Color(0xFFA8A49A);
const _accent  = Color(0xFF5B4FD8);
const _text    = Color(0xFF2A2535);
const _muted   = Color(0xFF9B95A8);
const _green   = Color(0xFF1D9E75);
const _red     = Color(0xFFE24B4A);
const _amber   = Color(0xFFF59E0B);

const _shadow   = BoxShadow(color: Color(0x55A8A49A), offset: Offset(3, 3), blurRadius: 0);
const _shadowSm = BoxShadow(color: Color(0x55A8A49A), offset: Offset(2, 2), blurRadius: 0);

TextStyle _mono({
  Color color = _text,
  double size = 12,
  FontWeight weight = FontWeight.normal,
  double letterSpacing = 0,
  double height = 1.4,
}) =>
    GoogleFonts.dmMono(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      decoration: TextDecoration.none,
    );

// ─────────────────────────────────────────────────────────────
//  ENTRY POINT — función global para abrir el sheet
// ─────────────────────────────────────────────────────────────
void showMatchSubPage(BuildContext context, WidgetRef ref, {String? jumpToMatchId}) {
  final container = ProviderScope.containerOf(context);
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, __, ___) => UncontrolledProviderScope(
        container: container,
        child: _MatchSubPageSheet(jumpToMatchId: jumpToMatchId),
      ),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 280),
    ),
  );
}

void showLeagueSubPage(BuildContext context, WidgetRef ref) {
  final container = ProviderScope.containerOf(context);
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, __, ___) => UncontrolledProviderScope(
        container: container,
        child: const _LeagueSubPageSheet(),
      ),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 280),
    ),
  );
}

void showAwardSubPage(BuildContext context, WidgetRef ref) {
  final container = ProviderScope.containerOf(context);
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, __, ___) => UncontrolledProviderScope(
        container: container,
        child: const _AwardSubPageSheet(),
      ),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 280),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  SHEET BASE — wrapper con handle y header brutalist
// ─────────────────────────────────────────────────────────────
class _BrutalistSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _BrutalistSheet({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Material(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 10),
            decoration: const BoxDecoration(
              color: _card,
              border: Border(
                top: BorderSide(color: _accent, width: 4),
                bottom: BorderSide(color: _borderH, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                // Botón atrás — sin contenedor
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.arrow_back, color: _muted, size: 18),
                  ),
                ),
                // Título centrado
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: _mono(color: _text, size: 14, weight: FontWeight.w700, letterSpacing: 1.2),
                  ),
                ),
                // Botón cerrar — sin contenedor
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: _muted, size: 18),
                  ),
                ),
              ],
            ),
          ),
          // ── Content ──
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MATCH SUB PAGE
// ─────────────────────────────────────────────────────────────
class _MatchSubPageSheet extends ConsumerStatefulWidget {
  final String? jumpToMatchId;
  const _MatchSubPageSheet({this.jumpToMatchId});

  @override
  ConsumerState<_MatchSubPageSheet> createState() => _MatchSubPageSheetState();
}

// ── Categorías de liga (mismo sistema que React) ──────────────
const _leagueCats = [
  {'id': 'all',          'name': 'Todos',        'icon': '🌍', 'leagues': <String>[]},
  {'id': 'europe',       'name': 'Europa',       'icon': '🏆', 'leagues': ['Champions League', 'Europa League', 'Conference League']},
  {'id': 'england',      'name': 'Inglaterra',   'icon': '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'leagues': ['Premier League', 'Championship', 'FA Cup', 'EFL Cup']},
  {'id': 'spain',        'name': 'España',       'icon': '🇪🇸', 'leagues': ['La Liga', 'Copa del Rey', 'Supercopa']},
  {'id': 'italy',        'name': 'Italia',       'icon': '🇮🇹', 'leagues': ['Serie A', 'Coppa Italia', 'Supercoppa']},
  {'id': 'germany',      'name': 'Alemania',     'icon': '🇩🇪', 'leagues': ['Bundesliga', 'DFB Pokal']},
  {'id': 'france',       'name': 'Francia',      'icon': '🇫🇷', 'leagues': ['Ligue 1', 'Coupe de France', 'Coupe de la Ligue']},
  {'id': 'southamerica', 'name': 'Sudamérica',   'icon': '🌎', 'leagues': ['Copa Libertadores', 'Copa Sudamericana', 'FIFA']},
];

class _MatchSubPageSheetState extends ConsumerState<_MatchSubPageSheet> {
  // true = más próximos primero, false = más lejanos primero
  bool _nearestFirst = true;
  bool _showFilter   = false;
  String _leagueCat  = 'all';

  // Etiqueta legible para un string de fecha ISO "yyyy-MM-dd"
  String _dateLabel(String? dateStr) {
    if (dateStr == null) return 'SIN FECHA';
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today    = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final day      = DateTime(d.year, d.month, d.day);
      if (day == today)    return 'HOY';
      if (day == tomorrow) return 'MAÑANA';
      // Día de semana abreviado
      const days = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
      return '${days[d.weekday - 1]} ${d.day}/${d.month}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(dashboardDataProvider);
    final userAsync = ref.watch(currentUserProvider);
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH,
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(
          left: BorderSide(color: _borderH, width: 1.5),
          right: BorderSide(color: _borderH, width: 1.5),
        ),
      ),
      child: dashAsync.when(
        loading: () => Column(children: [
          _buildTopBar(0),
          const Expanded(child: Center(child: _SheetLoader())),
        ]),
        error: (e, _) => Column(children: [
          _buildTopBar(0),
          Expanded(child: Center(child: Text('Error: $e', style: _mono(color: _red, size: 11)))),
        ]),
        data: (data) {
          final matches = data['matches'] as List;
          final userId = userAsync.value?['id'] as String?;

          // Solo partidos NO finalizados, filtrados y ordenados
          var active = matches
              .where((m) => m['status'] != 'finished')
              .toList();

          // Filtrar por categoría de liga
          if (_leagueCat != 'all') {
            final cat = _leagueCats.firstWhere((c) => c['id'] == _leagueCat, orElse: () => _leagueCats[0]);
            final leagues = cat['leagues'] as List<String>;
            if (leagues.isNotEmpty) {
              active = active.where((m) {
                final league = (m['league'] ?? m['league_name'] ?? '').toString().toLowerCase();
                return leagues.any((l) => league.contains(l.toLowerCase()));
              }).toList();
            }
          }

          active.sort((a, b) {
              final da = DateTime.tryParse('${a['date']}T${a['time'] ?? '00:00'}') ?? DateTime(2099);
              final db = DateTime.tryParse('${b['date']}T${b['time'] ?? '00:00'}') ?? DateTime(2099);
              return _nearestFirst ? da.compareTo(db) : db.compareTo(da);
            });

          // Construir lista de items: cada item es un match o un separador de fecha
          final items = <dynamic>[];
          String? lastDate;
          for (final m in active) {
            final d = m['date'] as String?;
            if (d != lastDate) {
              items.add(_DateSeparator(label: _dateLabel(d)));
              lastDate = d;
            }
            items.add(m);
          }

          return Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(active.length),
                  _buildSortBar(),
                  Expanded(
                    child: active.isEmpty
                        ? _EmptyState(label: 'Sin partidos\npendientes')
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final item = items[i];
                              if (item is _DateSeparator) return item;
                              final m = Map<String, dynamic>.from(item as Map);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _MatchPredictionCard(
                                  match: m,
                                  userId: userId,
                                  onPredict: (matchId, home, away, adv) async {
                                    if (userId == null) return;
                                    await DashboardService.upsertMatchPrediction(
                                      matchId: matchId,
                                      userId: userId,
                                      homeScore: home,
                                      awayScore: away,
                                      advancingTeam: adv,
                                    );
                                    ref.invalidate(dashboardDataProvider);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              // ── FILTER OVERLAY ──
              if (_showFilter) _buildFilterOverlay(),
            ],
          );
        },
      ),
    );
  }

  // ── Header: safe area + "PARTIDOS [N]" + filtro ──
  Widget _buildTopBar(int count) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 10),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(
          top: BorderSide(color: _accent, width: 4),
          bottom: BorderSide(color: _borderH, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // Botón atrás — sin contenedor
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.arrow_back, color: _muted, size: 18),
            ),
          ),
          // Título + badge centrados
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'PARTIDOS',
                  style: _mono(color: _text, size: 14, weight: FontWeight.w700, letterSpacing: 1.2),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    border: Border.all(color: _accent, width: 1.5),
                  ),
                  child: Text(
                    '$count',
                    style: _mono(color: _accent, size: 11, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          // Botón filtro — sin contenedor
          GestureDetector(
            onTap: () => setState(() => _showFilter = true),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.tune,
                color: _leagueCat != 'all' ? _accent : _muted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sort bar: centrado con icono en el medio ──
  Widget _buildSortBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SortBtn(
                label: 'MÁS PRÓXIMOS',
                active: _nearestFirst,
                onTap: () { if (!_nearestFirst) setState(() => _nearestFirst = true); },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.swap_vert, color: _muted, size: 16),
              ),
              _SortBtn(
                label: 'MÁS LEJANOS',
                active: !_nearestFirst,
                onTap: () { if (_nearestFirst) setState(() => _nearestFirst = false); },
              ),
            ],
          ),
          if (_leagueCat != 'all') ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _leagueCat = 'all'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.08),
                  border: Border.all(color: _accent, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (_leagueCats.firstWhere((c) => c['id'] == _leagueCat)['icon'] as String),
                      style: const TextStyle(fontSize: 11, decoration: TextDecoration.none),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      (_leagueCats.firstWhere((c) => c['id'] == _leagueCat)['name'] as String).toUpperCase(),
                      style: _mono(color: _accent, size: 8, weight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.close, size: 10, color: _accent),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Panel lateral de filtro ──
  Widget _buildFilterOverlay() {
    final topPad = MediaQuery.of(context).padding.top;
    return GestureDetector(
      onTap: () => setState(() => _showFilter = false),
      child: Container(
        color: const Color(0x720A0814),
        child: Row(
          children: [
            Expanded(child: GestureDetector(onTap: () => setState(() => _showFilter = false))),
            // Panel derecho
            Container(
              width: 264,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: _bg,
                border: Border(
                  left: BorderSide(color: _borderH, width: 1.5),
                  top: BorderSide(color: _accent, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del panel
                  Container(
                    padding: EdgeInsets.fromLTRB(16, topPad + 16, 16, 14),
                    decoration: const BoxDecoration(
                      color: _card,
                      border: Border(bottom: BorderSide(color: _borderH, width: 1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 14, color: _accent),
                        const SizedBox(width: 7),
                        Text('FILTRAR LIGA',
                          style: _mono(color: _text, size: 9, weight: FontWeight.w700, letterSpacing: 1.4)),
                        const Spacer(),
                        if (_leagueCat != 'all')
                          GestureDetector(
                            onTap: () => setState(() { _leagueCat = 'all'; _showFilter = false; }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: _borderH, width: 1.5),
                              ),
                              child: Text('RESET',
                                style: _mono(color: _accent, size: 8, weight: FontWeight.w700, letterSpacing: 1)),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _showFilter = false),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              border: Border.all(color: _borderH, width: 1.5),
                            ),
                            child: const Icon(Icons.close, size: 14, color: _muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Lista de categorías
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(10),
                      children: _leagueCats.map((cat) {
                        final isActive = _leagueCat == cat['id'];
                        return GestureDetector(
                          onTap: () => setState(() { _leagueCat = cat['id'] as String; _showFilter = false; }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isActive ? _text : _card,
                              border: Border.all(
                                color: isActive ? _text : _borderH,
                                width: 1.5,
                              ),
                              boxShadow: isActive ? const [_shadowSm] : null,
                            ),
                            child: Row(
                              children: [
                                Text(cat['icon'] as String, style: const TextStyle(fontSize: 16, decoration: TextDecoration.none)),
                                const SizedBox(width: 12),
                                Text(
                                  cat['name'] as String,
                                  style: _mono(
                                    color: isActive ? _bg : _text,
                                    size: 12,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Botón de ordenación estilo brutalista
class _SortBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SortBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? _accent : _card,
        border: Border.all(color: active ? _accent : _borderH, width: 1.5),
        boxShadow: active ? const [_shadowSm] : null,
      ),
      child: Text(
        label,
        style: _mono(
          color: active ? Colors.white : _muted,
          size: 9,
          weight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    ),
  );
}

// Separador de fecha entre grupos de partidos
class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(child: Container(height: 1, color: _border)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _borderH, width: 1.5),
          ),
          child: Text(
            label,
            style: _mono(color: _muted, size: 8, weight: FontWeight.w700, letterSpacing: 1.6),
          ),
        ),
        Expanded(child: Container(height: 1, color: _border)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  LEAGUE SUB PAGE
// ─────────────────────────────────────────────────────────────
class _LeagueSubPageSheet extends ConsumerWidget {
  const _LeagueSubPageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardDataProvider);
    final userAsync = ref.watch(currentUserProvider);

    return _BrutalistSheet(
      title: 'LIGAS',
      subtitle: 'DASHBOARD',
      child: dashAsync.when(
        loading: () => const Center(child: _SheetLoader()),
        error: (e, _) => Center(child: Text('Error: $e', style: _mono(color: _red, size: 11))),
        data: (data) {
          final leagues = data['leagues'] as List;
          final userId = userAsync.value?['id'] as String?;

          return leagues.isEmpty
              ? _EmptyState(label: 'Sin ligas activas')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  itemCount: leagues.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final l = Map<String, dynamic>.from(leagues[i] as Map);
                    return _LeaguePredictionCard(
                      league: l,
                      userId: userId,
                      onPredict: (leagueId, champion, scorer, assist, mvp) async {
                        if (userId == null) return;
                        await DashboardService.upsertLeaguePrediction(
                          leagueId: leagueId,
                          userId: userId,
                          champion: champion,
                          topScorer: scorer,
                          topAssist: assist,
                          mvp: mvp,
                        );
                        ref.invalidate(dashboardDataProvider);
                      },
                    );
                  },
                );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AWARD SUB PAGE
// ─────────────────────────────────────────────────────────────
class _AwardSubPageSheet extends ConsumerWidget {
  const _AwardSubPageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardDataProvider);
    final userAsync = ref.watch(currentUserProvider);

    return _BrutalistSheet(
      title: 'PREMIOS',
      subtitle: 'DASHBOARD',
      child: dashAsync.when(
        loading: () => const Center(child: _SheetLoader()),
        error: (e, _) => Center(child: Text('Error: $e', style: _mono(color: _red, size: 11))),
        data: (data) {
          final awards = data['awards'] as List;
          final userId = userAsync.value?['id'] as String?;

          return awards.isEmpty
              ? _EmptyState(label: 'Sin premios activos')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  itemCount: awards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final a = Map<String, dynamic>.from(awards[i] as Map);
                    return _AwardPredictionCard(
                      award: a,
                      userId: userId,
                      onPredict: (awardId, winner) async {
                        if (userId == null) return;
                        await DashboardService.upsertAwardPrediction(
                          awardId: awardId,
                          userId: userId,
                          predictedWinner: winner,
                        );
                        ref.invalidate(dashboardDataProvider);
                      },
                    );
                  },
                );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MATCH PREDICTION CARD (tarjeta completa con +/- inline)
// ─────────────────────────────────────────────────────────────
class _MatchPredictionCard extends StatefulWidget {
  final Map<String, dynamic> match;
  final String? userId;
  final Future<void> Function(String, int, int, String?) onPredict;

  const _MatchPredictionCard({
    required this.match,
    this.userId,
    required this.onPredict,
  });

  @override
  State<_MatchPredictionCard> createState() => _MatchPredictionCardState();
}

class _MatchPredictionCardState extends State<_MatchPredictionCard> {
  late int _home;
  late int _away;
  String? _advancing;
  bool _saving = false;
  bool _saved = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final pred = _myPred;
    _home = pred?['home_score'] as int? ?? 0;
    _away = pred?['away_score'] as int? ?? 0;
    _advancing = pred?['predicted_advancing_team'] as String?;
    _saved = pred != null;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Map? get _myPred {
    final preds = (widget.match['predictions'] as List?) ?? [];
    try {
      return preds.firstWhere((p) => (p as Map)['user_id'] == widget.userId) as Map;
    } catch (_) {
      return null;
    }
  }

  bool get _isDisabled {
    final status = widget.match['status'];
    if (status != 'pending' && status != 'live') return true;
    final deadline = widget.match['deadline'];
    if (deadline == null) return false;
    return DateTime.now().isAfter(DateTime.parse(deadline as String));
  }

  bool get _isKnockout => widget.match['is_knockout'] == true;
  bool get _isLive => widget.match['status'] == 'live';

  Color get _accentColor {
    if (_isLive) return _amber;
    if (_saved || _myPred != null) return _green;
    final deadline = widget.match['deadline'];
    if (deadline != null && DateTime.now().isAfter(DateTime.parse(deadline as String))) return _red;
    return _accent;
  }

  String get _pillLabel {
    if (_isLive) return '● VIVO';
    if (_saving) return 'GUARD...';
    if (_saved) return '✓ GUARD.';
    if (_myPred != null) return '✓ GUARD.';
    if (_isDisabled) return 'CERRADO';
    return 'PENDIENTE';
  }

  Future<void> _save() async {
    if (_isDisabled || _saving) return;
    HapticFeedback.lightImpact();
    setState(() { _saving = true; _saved = false; });
    try {
      await widget.onPredict(
        widget.match['id'] as String,
        _home,
        _away,
        _advancing,
      );
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) setState(() => _saved = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _triggerAutoSave() {
    if (_isDisabled) return;
    _debounce?.cancel();
    setState(() { _saved = false; }); // feedback inmediato: vuelve a "sin guardar"
    _debounce = Timer(const Duration(milliseconds: 600), _save);
  }

  void _inc(bool isHome) {
    if (_isDisabled) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (isHome) { if (_home < 20) _home++; }
      else        { if (_away < 20) _away++; }
    });
    _triggerAutoSave();
  }

  void _dec(bool isHome) {
    if (_isDisabled) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (isHome) { if (_home > 0) _home--; }
      else        { if (_away > 0) _away--; }
    });
    _triggerAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final ac = _accentColor;

    final isSavedNow = _saved || _myPred != null;

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _borderH, width: 1.5),
        boxShadow: const [_shadow],
      ),
      child: Column(
        children: [
          // ── Borde superior coloreado ──
          Container(height: 3, color: ac),

          // ── Header: logo liga + nombre + KO badge + pill ──
          Container(
            padding: const EdgeInsets.fromLTRB(13, 9, 13, 9),
            color: _card,
            child: Row(
              children: [
                // Logo liga cuadrado
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: _bg,
                    border: Border.all(color: _borderH, width: 1.5),
                  ),
                  child: m['league_logo_url'] != null
                      ? Image.network(
                          m['league_logo_url'] as String,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, _, _) => const Center(
                              child: Text('🏆', style: TextStyle(fontSize: 10, decoration: TextDecoration.none))),
                        )
                      : const Center(child: Text('🏆', style: TextStyle(fontSize: 10, decoration: TextDecoration.none))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (m['league_name'] ?? m['league'] ?? 'LIGA').toString().toUpperCase(),
                    style: _mono(color: _muted, size: 8, weight: FontWeight.w700, letterSpacing: 1.2),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isKnockout) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(color: _red, width: 1)),
                    child: Text('KO', style: _mono(color: _red, size: 7, weight: FontWeight.w800, letterSpacing: 1)),
                  ),
                  const SizedBox(width: 6),
                ],
                _StatusPill(label: _pillLabel, color: ac),
              ],
            ),
          ),

          // ── HOME team row ──
          _TeamScoreRow(
            name: m['home_team'] as String? ?? '—',
            logoUrl: m['home_team_logo_url'] as String?,
            score: _home,
            isDisabled: _isDisabled,
            isAdvancing: _advancing == 'home',
            isKnockout: _isKnockout,
            isSaved: isSavedNow,
            onInc: () => _inc(true),
            onDec: () => _dec(true),
            onAdvTap: () {
              if (!_isKnockout || _isDisabled) return;
              setState(() => _advancing = _advancing == 'home' ? null : 'home');
              _triggerAutoSave();
            },
          ),

          // ── VS con líneas laterales ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                Expanded(child: Container(height: 1, color: _border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    _isKnockout && !_isDisabled ? '⚔' : 'VS',
                    style: _mono(color: _borderH, size: 9, weight: FontWeight.w700, letterSpacing: 2),
                  ),
                ),
                Expanded(child: Container(height: 1, color: _border)),
              ],
            ),
          ),

          // ── AWAY team row ──
          _TeamScoreRow(
            name: m['away_team'] as String? ?? '—',
            logoUrl: m['away_team_logo_url'] as String?,
            score: _away,
            isDisabled: _isDisabled,
            isAdvancing: _advancing == 'away',
            isKnockout: _isKnockout,
            isSaved: isSavedNow,
            onInc: () => _inc(false),
            onDec: () => _dec(false),
            onAdvTap: () {
              if (!_isKnockout || _isDisabled) return;
              setState(() => _advancing = _advancing == 'away' ? null : 'away');
              _triggerAutoSave();
            },
          ),

          // ── Footer: hora | fecha | estado auto-guardado ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: const BoxDecoration(
              color: _card,
              border: Border(top: BorderSide(color: _border, width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 10, color: _muted),
                const SizedBox(width: 4),
                Text(m['time'] as String? ?? '—', style: _mono(color: _muted, size: 9)),
                Container(width: 1, height: 10, margin: const EdgeInsets.symmetric(horizontal: 10), color: _border),
                const Icon(Icons.calendar_today_outlined, size: 10, color: _muted),
                const SizedBox(width: 4),
                Text(m['date'] as String? ?? '—', style: _mono(color: _muted, size: 9)),
                const Spacer(),
                // Indicador de estado compacto
                if (_isDisabled)
                  Text(
                    _isLive ? '● EN VIVO' : 'CERRADO',
                    style: _mono(color: _isLive ? _amber : _muted, size: 8, weight: FontWeight.w700, letterSpacing: 1.2),
                  )
                else if (_saving)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 8, height: 8,
                      child: CircularProgressIndicator(color: _accent, strokeWidth: 1.5),
                    ),
                    const SizedBox(width: 5),
                    Text('GUARDANDO', style: _mono(color: _accent, size: 7, weight: FontWeight.w700, letterSpacing: 1)),
                  ])
                else if (isSavedNow)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check, size: 9, color: _green),
                    const SizedBox(width: 4),
                    Text('GUARDADO', style: _mono(color: _green, size: 7, weight: FontWeight.w700, letterSpacing: 1)),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LEAGUE PREDICTION CARD
// ─────────────────────────────────────────────────────────────
class _LeaguePredictionCard extends StatefulWidget {
  final Map<String, dynamic> league;
  final String? userId;
  final Future<void> Function(String, String, String, String, String) onPredict;

  const _LeaguePredictionCard({
    required this.league,
    this.userId,
    required this.onPredict,
  });

  @override
  State<_LeaguePredictionCard> createState() => _LeaguePredictionCardState();
}

class _LeaguePredictionCardState extends State<_LeaguePredictionCard> {
  late TextEditingController _champion;
  late TextEditingController _scorer;
  late TextEditingController _assist;
  late TextEditingController _mvp;
  bool _saving = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    final pred = _myPred;
    _champion = TextEditingController(text: pred?['predicted_champion'] as String? ?? '');
    _scorer   = TextEditingController(text: pred?['predicted_top_scorer'] as String? ?? '');
    _assist   = TextEditingController(text: pred?['predicted_top_assist'] as String? ?? '');
    _mvp      = TextEditingController(text: pred?['predicted_mvp'] as String? ?? '');
    // Si ya tiene predicción, mostrar expandido
    _expanded = pred != null || widget.league['status'] == 'active';
  }

  @override
  void dispose() {
    _champion.dispose(); _scorer.dispose(); _assist.dispose(); _mvp.dispose();
    super.dispose();
  }

  Map? get _myPred {
    final preds = (widget.league['league_predictions'] as List?) ?? [];
    try {
      return preds.firstWhere((p) => (p as Map)['user_id'] == widget.userId) as Map;
    } catch (_) { return null; }
  }

  bool get _isDisabled {
    if (widget.league['status'] == 'finished') return true;
    final deadline = widget.league['deadline'];
    if (deadline == null) return false;
    return DateTime.now().isAfter(DateTime.parse(deadline as String));
  }

  Color get _ac {
    if (widget.league['status'] == 'finished') return _red;
    if (_myPred != null) return _green;
    if (_isDisabled) return _red;
    return _accent;
  }

  Future<void> _save() async {
    if (_champion.text.trim().isEmpty || _scorer.text.trim().isEmpty ||
        _assist.text.trim().isEmpty || _mvp.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _saving = true);
    try {
      await widget.onPredict(
        widget.league['id'] as String,
        _champion.text.trim(),
        _scorer.text.trim(),
        _assist.text.trim(),
        _mvp.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.league;
    final pred = _myPred;
    final ac = _ac;
    final isFinished = l['status'] == 'finished';

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _borderH, width: 1.5),
        boxShadow: const [_shadow],
      ),
      child: Column(
        children: [
          // Header con barra lateral de color — tappable para expandir
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 4, color: ac),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      color: _card,
                      child: Row(
                        children: [
                          _LogoBox(url: l['logo_url'] as String?, fallback: l['logo'] as String? ?? '🏆', size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (l['name'] ?? '—').toString().toUpperCase(),
                                  style: _mono(color: _text, size: 11, weight: FontWeight.w700, letterSpacing: 0.8),
                                ),
                                const SizedBox(height: 2),
                                Text(l['season'] as String? ?? '—', style: _mono(color: _muted, size: 8, letterSpacing: 1)),
                              ],
                            ),
                          ),
                          _StatusPill(
                            label: isFinished ? 'FINALIZADO' : _isDisabled ? 'EXPIRADO' : pred != null ? '✓ GUARD.' : 'PENDIENTE',
                            color: ac,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: _muted,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body expandible
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  // Campeón
                  _BrutalistField(
                    label: 'CAMPEÓN',
                    controller: _champion,
                    disabled: _isDisabled,
                    hint: 'Escribe el equipo...',
                    result: isFinished ? l['champion'] as String? : null,
                    correct: isFinished && l['champion'] != null &&
                        _champion.text.toLowerCase() == (l['champion'] as String).toLowerCase(),
                  ),
                  const SizedBox(height: 8),
                  // Goleador + Asistidor en fila
                  Row(
                    children: [
                      Expanded(
                        child: _BrutalistField(
                          label: 'GOLEADOR',
                          controller: _scorer,
                          disabled: _isDisabled,
                          hint: 'Jugador...',
                          result: isFinished ? l['top_scorer'] as String? : null,
                          correct: isFinished && l['top_scorer'] != null &&
                              _scorer.text.toLowerCase() == (l['top_scorer'] as String).toLowerCase(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BrutalistField(
                          label: 'ASISTIDOR',
                          controller: _assist,
                          disabled: _isDisabled,
                          hint: 'Jugador...',
                          result: isFinished ? l['top_assist'] as String? : null,
                          correct: isFinished && l['top_assist'] != null &&
                              _assist.text.toLowerCase() == (l['top_assist'] as String).toLowerCase(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // MVP
                  _BrutalistField(
                    label: 'MVP',
                    controller: _mvp,
                    disabled: _isDisabled,
                    hint: 'Jugador...',
                    result: isFinished ? l['mvp_player'] as String? : null,
                    correct: isFinished && l['mvp_player'] != null &&
                        _mvp.text.toLowerCase() == (l['mvp_player'] as String).toLowerCase(),
                  ),
                  // Footer
                  if (!_isDisabled) ...[
                    const SizedBox(height: 12),
                    _SaveButton(
                      onTap: _save,
                      saving: _saving,
                      isUpdate: pred != null,
                    ),
                  ],
                  if (isFinished && pred != null) ...[
                    const SizedBox(height: 10),
                    _PointsBadge(points: pred['points_earned'] as int? ?? 0),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AWARD PREDICTION CARD
// ─────────────────────────────────────────────────────────────
class _AwardPredictionCard extends StatefulWidget {
  final Map<String, dynamic> award;
  final String? userId;
  final Future<void> Function(String, String) onPredict;

  const _AwardPredictionCard({
    required this.award,
    this.userId,
    required this.onPredict,
  });

  @override
  State<_AwardPredictionCard> createState() => _AwardPredictionCardState();
}

class _AwardPredictionCardState extends State<_AwardPredictionCard> {
  late TextEditingController _winner;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pred = _myPred;
    _winner = TextEditingController(text: pred?['predicted_winner'] as String? ?? '');
  }

  @override
  void dispose() { _winner.dispose(); super.dispose(); }

  Map? get _myPred {
    final preds = (widget.award['award_predictions'] as List?) ?? [];
    try {
      return preds.firstWhere((p) => (p as Map)['user_id'] == widget.userId) as Map;
    } catch (_) { return null; }
  }

  bool get _isDisabled {
    if (widget.award['status'] == 'finished') return true;
    final deadline = widget.award['deadline'];
    if (deadline == null) return false;
    return DateTime.now().isAfter(DateTime.parse(deadline as String));
  }

  Color get _ac {
    if (widget.award['status'] == 'finished') return _red;
    if (_myPred != null) return _green;
    if (_isDisabled) return _red;
    return _accent;
  }

  Future<void> _save() async {
    if (_winner.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _saving = true);
    try {
      await widget.onPredict(widget.award['id'] as String, _winner.text.trim());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.award;
    final pred = _myPred;
    final ac = _ac;
    final isFinished = a['status'] == 'finished';

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _borderH, width: 1.5),
        boxShadow: const [_shadow],
      ),
      child: Column(
        children: [
          // Header con barra lateral de color
          IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 4, color: ac),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    color: _card,
                    child: Row(
                      children: [
                        _LogoBox(url: a['logo_url'] as String?, fallback: a['logo'] as String? ?? '🏅', size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (a['name'] ?? '—').toString().toUpperCase(),
                                style: _mono(color: _text, size: 11, weight: FontWeight.w700, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${a['category'] ?? ''} · ${a['season'] ?? '—'}',
                                style: _mono(color: _muted, size: 8, letterSpacing: 0.8),
                              ),
                            ],
                          ),
                        ),
                        _StatusPill(
                          label: isFinished ? 'FINALIZADO' : _isDisabled ? 'EXPIRADO' : pred != null ? '✓ GUARD.' : 'PENDIENTE',
                          color: ac,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                _BrutalistField(
                  label: 'TU PREDICCIÓN DEL GANADOR',
                  controller: _winner,
                  disabled: _isDisabled,
                  hint: 'Nombre del ganador...',
                  result: isFinished ? a['winner'] as String? : null,
                  correct: isFinished && a['winner'] != null &&
                      _winner.text.toLowerCase() == (a['winner'] as String).toLowerCase(),
                ),
                // Categoría tag
                if (a['category'] != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _bg,
                        border: Border.all(color: _borderH, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_border, size: 11, color: _muted),
                          const SizedBox(width: 5),
                          Text(
                            (a['category'] as String).toUpperCase(),
                            style: _mono(color: _muted, size: 8, weight: FontWeight.w700, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_isDisabled && !isFinished) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 11, color: _red),
                      const SizedBox(width: 5),
                      Text('Plazo expirado', style: _mono(color: _red, size: 9, weight: FontWeight.w700)),
                    ],
                  ),
                ],
                if (!_isDisabled) ...[
                  const SizedBox(height: 12),
                  _SaveButton(onTap: _save, saving: _saving, isUpdate: pred != null),
                ],
                if (isFinished && pred != null) ...[
                  const SizedBox(height: 10),
                  _PointsBadge(points: pred['points_earned'] as int? ?? 0),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TEAM SCORE ROW — escudo circular + score accent + keycap
// ─────────────────────────────────────────────────────────────
class _TeamScoreRow extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final int score;
  final bool isDisabled;
  final bool isAdvancing;
  final bool isKnockout;
  final bool isSaved;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onAdvTap;

  const _TeamScoreRow({
    required this.name,
    this.logoUrl,
    required this.score,
    required this.isDisabled,
    required this.isAdvancing,
    required this.isKnockout,
    required this.isSaved,
    required this.onInc,
    required this.onDec,
    required this.onAdvTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      color: isAdvancing ? _accent.withValues(alpha: 0.04) : _bg,
      child: Row(
        children: [
          // Logo equipo — CIRCULAR, tappable si es KO
          GestureDetector(
            onTap: isKnockout ? onAdvTap : null,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _card,
                    border: Border.all(
                      color: isAdvancing ? _accent : _borderH,
                      width: isAdvancing ? 2 : 1.5,
                    ),
                    boxShadow: isAdvancing ? const [_shadowSm] : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: logoUrl != null
                      ? Image.network(
                          logoUrl!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, _, _) => const Center(
                              child: Text('⚽', style: TextStyle(fontSize: 18, decoration: TextDecoration.none))))
                      : const Center(child: Text('⚽', style: TextStyle(fontSize: 18, decoration: TextDecoration.none))),
                ),
                if (isKnockout && isAdvancing)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 14, height: 14,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 9, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Nombre del equipo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: _mono(color: _text, size: 11, weight: FontWeight.w700, letterSpacing: 0.3),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isKnockout && isAdvancing)
                  Text(
                    '✓ AVANZA',
                    style: _mono(color: _accent, size: 7, weight: FontWeight.w800, letterSpacing: 1.4),
                  ),
              ],
            ),
          ),
          // Controles score: − | score | +
          Row(
            children: [
              _ScoreBtn(
                symbol: '−',
                onTap: (!isDisabled && score > 0) ? onDec : null,
                isAccent: false,
              ),
              const SizedBox(width: 4),
              // Score display — accent cuando guardado
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSaved ? _accent.withValues(alpha: 0.08) : _surface,
                  border: Border.all(
                    color: isSaved ? _accent : _borderH,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '$score',
                  style: _mono(
                    color: isSaved ? _accent : (score > 0 ? _accent : _muted),
                    size: 18,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _ScoreBtn(
                symbol: '+',
                onTap: !isDisabled ? onInc : null,
                isAccent: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBtn extends StatefulWidget {
  final String symbol;
  final VoidCallback? onTap;
  final bool isAccent;

  const _ScoreBtn({required this.symbol, this.onTap, this.isAccent = false});

  @override
  State<_ScoreBtn> createState() => _ScoreBtnState();
}

class _ScoreBtnState extends State<_ScoreBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.onTap != null;
    final faceColor = !active
        ? _bg
        : widget.isAccent ? _accent : _card;
    final shadowColor = !active
        ? _border
        : widget.isAccent
            ? const Color(0xFF3D35A0)
            : const Color(0xFF8A8680);

    return GestureDetector(
      onTapDown: (_) {
        if (!active) return;
        HapticFeedback.selectionClick();
        setState(() => _pressed = true);
        widget.onTap?.call();
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        width: 36,
        height: 40,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Base / sombra de la tecla
            Positioned(
              bottom: 0,
              left: 1,
              right: 1,
              child: Container(
                height: _pressed ? 2 : 5,
                decoration: BoxDecoration(
                  color: shadowColor,
                  border: Border.all(
                    color: active
                        ? (widget.isAccent ? const Color(0xFF3D35A0) : _borderH)
                        : _border,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Face de la tecla
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              top: _pressed ? 4 : 0,
              left: 0,
              right: 0,
              child: Container(
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: faceColor,
                  border: Border.all(
                    color: active
                        ? (widget.isAccent ? _accent : _borderH)
                        : _border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  widget.symbol,
                  style: _mono(
                    color: active
                        ? (widget.isAccent ? Colors.white : _text)
                        : _border,
                    size: 18,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BRUTALIST FIELD (input de texto estilo brutalist)
// ─────────────────────────────────────────────────────────────
class _BrutalistField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool disabled;
  final String hint;
  final String? result; // resultado real si está finalizado
  final bool correct;

  const _BrutalistField({
    required this.label,
    required this.controller,
    required this.disabled,
    required this.hint,
    this.result,
    this.correct = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _mono(color: _muted, size: 7, weight: FontWeight.w700, letterSpacing: 2)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: disabled ? _bg : _surface,
            border: Border.all(color: _border, width: 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Barra izquierda de acento (como en screenshot)
                Container(
                  width: 3,
                  color: controller.text.isNotEmpty ? _accent : _borderH,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !disabled,
                    style: _mono(
                      color: controller.text.isNotEmpty ? _accent : _text,
                      size: 12,
                      weight: controller.text.isNotEmpty ? FontWeight.w700 : FontWeight.normal,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: _mono(color: _muted, size: 11),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Resultado real si está finalizado
        if (result != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel_outlined,
                size: 11,
                color: correct ? _green : _red,
              ),
              const SizedBox(width: 4),
              Text(
                result!,
                style: _mono(color: correct ? _green : _muted, size: 9, weight: FontWeight.w700),
              ),
              if (correct) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  color: _green.withValues(alpha: 0.1),
                  child: Text('✓ CORRECTO', style: _mono(color: _green, size: 7, weight: FontWeight.w700, letterSpacing: 1.2)),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────
class _LogoBox extends StatelessWidget {
  final String? url;
  final String fallback;
  final double size;

  const _LogoBox({this.url, required this.fallback, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _borderH, width: 1.5),
        boxShadow: const [_shadowSm],
      ),
      child: url != null
          ? Image.network(url!, fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Center(
                  child: Text(fallback, style: TextStyle(fontSize: size * 0.45, decoration: TextDecoration.none))))
          : Center(child: Text(fallback, style: TextStyle(fontSize: size * 0.45, decoration: TextDecoration.none))),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 1.5),
        boxShadow: const [_shadowSm],
      ),
      child: Text(label, style: _mono(color: color, size: 7, weight: FontWeight.w800, letterSpacing: 0.8)),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool saving;
  final bool isUpdate;

  const _SaveButton({required this.onTap, required this.saving, required this.isUpdate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: saving ? _muted : _accent,
          boxShadow: const [_shadow],
        ),
        child: Text(
          saving ? 'GUARDANDO...' : (isUpdate ? '✓ ACTUALIZAR PREDICCIÓN' : 'GUARDAR PREDICCIÓN'),
          style: _mono(color: Colors.white, size: 11, weight: FontWeight.w800, letterSpacing: 1.4),
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    final hasPoints = points > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasPoints ? _green.withValues(alpha: 0.08) : _bg,
        border: Border.all(color: hasPoints ? _green : _border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasPoints ? Icons.star : Icons.star_border,
            size: 13,
            color: hasPoints ? _green : _muted,
          ),
          const SizedBox(width: 6),
          Text(
            hasPoints ? '+$points PTS OBTENIDOS' : 'SIN PUNTOS ESTA VEZ',
            style: _mono(
              color: hasPoints ? _green : _muted,
              size: 9,
              weight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _card,
              border: Border.all(color: _borderH, width: 1.5),
              boxShadow: const [_shadow],
            ),
            child: const Icon(Icons.inbox_outlined, color: _muted, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: _mono(color: _muted, size: 11, weight: FontWeight.w700, letterSpacing: 1.2, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SheetLoader extends StatelessWidget {
  const _SheetLoader();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _borderH, width: 1.5),
            boxShadow: const [_shadow],
          ),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
          ),
        ),
        const SizedBox(height: 10),
        Text('CARGANDO...', style: _mono(color: _muted, size: 8, weight: FontWeight.w700, letterSpacing: 2)),
      ],
    );
  }
}