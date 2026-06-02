import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/match_sub_page.dart';

// ── Paleta ────────────────────────────────────────────────────
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFEAE7E1);
const _surface = Color(0xFFF5F2EC);
const _border  = Color(0xFF1A1A2E);   // negro duro neobrut
const _borderH = Color(0xFF1A1A2E);   // negro duro neobrut
const _accent  = Color(0xFF5B4FD8);
const _accentL = Color(0xFF8B7FC7);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF6B6580);
const _green   = Color(0xFF1D9E75);
const _red     = Color(0xFFE24B4A);
const _amber   = Color(0xFFF59E0B);
const _gold    = Color(0xFFC9A227);
const _silver  = Color(0xFF9CA3AF);
const _bronze  = Color(0xFFCD7C30);

// Sombras duras negras neobrutalistas (sin blur, como stats_page)
const _shadowColor = Color(0xFF1A1A2E);
const _shadow   = BoxShadow(color: _shadowColor, offset: Offset(3, 3), blurRadius: 0);
const _shadowSm = BoxShadow(color: _shadowColor, offset: Offset(2, 2), blurRadius: 0);
const _shadowLg = BoxShadow(color: _shadowColor, offset: Offset(5, 5), blurRadius: 0);

TextStyle _mono({Color color = _text, double size = 12, FontWeight weight = FontWeight.normal, double letterSpacing = 0}) =>
    GoogleFonts.dmMono(color: color, fontSize: size, fontWeight: weight, letterSpacing: letterSpacing);

// ── Durations ─────────────────────────────────────────────────
const _tFast   = Duration(milliseconds: 180);
const _tMed    = Duration(milliseconds: 340);
const _tSlow   = Duration(milliseconds: 520);

// ─────────────────────────────────────────────────────────────
//  WIDGET RAÍZ
// ─────────────────────────────────────────────────────────────
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {

  String _activeTab   = 'matches';
  String _bottomTab   = 'ranking';

  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _fadeSlide;

  late final AnimationController _tabCtrl;

  late final AnimationController _barCtrl;
  double _barTarget = 0;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeSlide = List.generate(5, (i) {
      final start = (i * 0.14).clamp(0.0, 0.6);
      final end   = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _tabCtrl = AnimationController(vsync: this, duration: _tMed, value: 1);

    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _entryCtrl.value = 1;
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _tabCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  void _switchTab(String tab) {
    if (tab == _activeTab) return;
    HapticFeedback.selectionClick();
    _tabCtrl.reverse().then((_) {
      if (mounted) setState(() => _activeTab = tab);
      _tabCtrl.forward();
    });
  }

  void _switchBottomTab(String tab) {
    if (tab == _bottomTab) return;
    HapticFeedback.selectionClick();
    setState(() => _bottomTab = tab);
  }

  void _animateBar(double target) {
    if ((target - _barTarget).abs() > 0.001) {
      _barTarget = target;
      _barCtrl.forward(from: 0);
    }
  }

  Future<void> _refresh() async => ref.invalidate(dashboardDataProvider);

  Widget _enter(int idx, Widget child) => AnimatedBuilder(
    animation: _fadeSlide[idx],
    builder: (_, __) => Opacity(
      opacity: _fadeSlide[idx].value,
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - _fadeSlide[idx].value)),
        child: child,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(dashboardDataProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: dashAsync.when(
          loading: () => const _AppSplash(),
          error: (e, _) => _ErrorPanel(error: '$e', onRetry: _refresh),
          data: (data) {
            final matches    = data['matches']  as List;
            final leagues    = data['leagues']  as List;
            final awards     = data['awards']   as List;
            final topUsers   = data['topUsers'] as List;
            final currentUser = userAsync.value;
            final userId     = currentUser?['id'] as String?;

            final pendingMatches = matches
                .where((m) => m['status'] != 'finished')
                .toList();

            final nextMatch = pendingMatches.isNotEmpty
                ? (List.from(pendingMatches)..sort((a, b) {
                    final da = DateTime.tryParse('${a['date']}T${a['time'] ?? '00:00'}') ?? DateTime(2099);
                    final db = DateTime.tryParse('${b['date']}T${b['time'] ?? '00:00'}') ?? DateTime(2099);
                    return da.compareTo(db);
                  })).first as Map<String, dynamic>
                : null;

            final savedCount = pendingMatches.where((m) {
              final preds = (m['predictions'] as List?) ?? [];
              return preds.any((p) => p['user_id'] == userId);
            }).length;
            final totalCount = pendingMatches.length;
            final barPct = totalCount > 0 ? savedCount / totalCount : 0.0;

            WidgetsBinding.instance.addPostFrameCallback((_) => _animateBar(barPct));

            final previewMatches = pendingMatches.take(4).toList();
            final previewLeagues = leagues.take(3).toList();
            final previewAwards  = awards.take(3).toList();

            return RefreshIndicator(
              onRefresh: _refresh,
              color: _accent,
              backgroundColor: _card,
              displacement: 20,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 0: Progress bar ──────────────────────
                    _enter(0, _ProgressBar(
                      saved: savedCount,
                      total: totalCount,
                      target: barPct,
                    )),

                    // ── 1: Next match banner ─────────────────
                    _enter(1, GestureDetector(
                      onTap: nextMatch != null
                          ? () => showMatchSubPage(context, ref,
                              jumpToMatchId: nextMatch['id'] as String?)
                          : null,
                      child: _NextMatchBanner(match: nextMatch),
                    )),

                    const SizedBox(height: 14),

                    // ── 2: Tab bar ───────────────────────────
                    _enter(2, Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _TabBar(
                        activeTab: _activeTab,
                        onTabChange: _switchTab,
                        counts: {
                          'matches': pendingMatches.length,
                          'leagues': leagues.length,
                          'awards':  awards.length,
                        },
                      ),
                    )),

                    const SizedBox(height: 8),

                    // ── 3: Mini cards ────────────────────────
                    _enter(3, FadeTransition(
                      opacity: _tabCtrl,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_activeTab == 'matches') ...[
                                if (previewMatches.isEmpty) ...[
                                  _EmptyMatchCard(),
                                  const SizedBox(width: 10),
                                  _MoreCard(onTap: () => showMatchSubPage(context, ref)),
                                ] else ...[
                                  ...previewMatches.asMap().entries.map((e) => Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: _AnimatedCard(
                                      delay: Duration(milliseconds: e.key * 60),
                                      child: _MiniMatchCard(match: e.value as Map<String, dynamic>, userId: userId),
                                    ),
                                  )),
                                  _MoreCard(onTap: () => showMatchSubPage(context, ref)),
                                ],
                              ],
                              if (_activeTab == 'leagues') ...[
                                if (previewLeagues.isEmpty)
                                  _EmptyCard(label: 'SIN\nLIGAS\nACTIVAS')
                                else ...[
                                  ...previewLeagues.asMap().entries.map((e) => Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: _AnimatedCard(
                                      delay: Duration(milliseconds: e.key * 60),
                                      child: _MiniLeagueCard(league: e.value as Map<String, dynamic>, userId: userId),
                                    ),
                                  )),
                                  _MoreCard(onTap: () => showLeagueSubPage(context, ref)),
                                ],
                              ],
                              if (_activeTab == 'awards') ...[
                                if (previewAwards.isEmpty)
                                  _EmptyCard(label: 'SIN\nPREMIOS\nACTIVOS')
                                else ...[
                                  ...previewAwards.asMap().entries.map((e) => Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: _AnimatedCard(
                                      delay: Duration(milliseconds: e.key * 60),
                                      child: _MiniAwardCard(award: e.value as Map<String, dynamic>, userId: userId),
                                    ),
                                  )),
                                  _MoreCard(onTap: () => showAwardSubPage(context, ref)),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    )),

                    // ── 4: Bottom panel ──────────────────────
                    _enter(4, Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Column(
                        children: [
                          _BottomTabBar(activeTab: _bottomTab, onTabChange: _switchBottomTab),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: _tMed,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim),
                                child: child,
                              ),
                            ),
                            child: _bottomTab == 'ranking'
                                ? _PodiumPanel(key: const ValueKey('ranking'), topUsers: topUsers, currentUser: currentUser)
                                : _StatsPanel(key: const ValueKey('stats'), user: currentUser),
                          ),
                        ],
                      ),
                    )),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ANIMATED CARD
// ─────────────────────────────────────────────────────────────
class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _AnimatedCard({required this.child, this.delay = Duration.zero});
  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _tSlow);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, child) => Opacity(
      opacity: _anim.value,
      child: Transform.translate(offset: Offset(14 * (1 - _anim.value), 0), child: child),
    ),
    child: widget.child,
  );
}

// ─────────────────────────────────────────────────────────────
//  PRESSABLE
// ─────────────────────────────────────────────────────────────
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, this.onTap});
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _press;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _tFast);
    _press = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_)  { if (widget.onTap != null) _ctrl.forward(); },
    onTapUp:   (_)  { _ctrl.reverse(); widget.onTap?.call(); HapticFeedback.lightImpact(); },
    onTapCancel: () { _ctrl.reverse(); },
    child: AnimatedBuilder(
      animation: _press,
      builder: (_, child) => Transform.translate(
        offset: Offset(_press.value * 2, _press.value * 2),
        child: child,
      ),
      child: widget.child,
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  ERROR PANEL
// ─────────────────────────────────────────────────────────────
class _ErrorPanel extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorPanel({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: _card, border: Border.all(color: _border, width: 2), boxShadow: const [_shadowLg]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('ERROR', style: _mono(color: _red, size: 10, weight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 10),
          Text(error, style: _mono(color: _muted, size: 11)),
          const SizedBox(height: 16),
          _Pressable(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(color: _accent, boxShadow: [_shadowSm]),
              child: Text('REINTENTAR', style: _mono(color: Colors.white, size: 11, weight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  PROGRESS BAR — con decoraciones neobrutalistas mejoradas
// ─────────────────────────────────────────────────────────────
class _ProgressBar extends StatefulWidget {
  final int saved;
  final int total;
  final double target;
  const _ProgressBar({required this.saved, required this.total, required this.target});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  @override
  Widget build(BuildContext context) {
    final isComplete = widget.saved == widget.total && widget.total > 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      decoration: BoxDecoration(
        color: isComplete ? _accent.withOpacity(0.06) : _card,
        border: Border.all(color: _border, width: 2),
        boxShadow: const [_shadow],
      ),
      child: Column(children: [
        // ── Top stripe neobrutalista ──
        Container(
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accent, _accentL, _accent],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                // Bloque decorativo izquierdo
                Container(
                  width: 4,
                  height: 26,
                  color: _accent,
                  margin: const EdgeInsets.only(right: 10),
                ),
                Text('PREDIC.', style: _mono(color: _muted, size: 10, weight: FontWeight.w700, letterSpacing: 2)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accent,
                    boxShadow: const [_shadowSm],
                  ),
                  child: Text('[${widget.saved}/${widget.total}]',
                      style: _mono(color: Colors.white, size: 11, weight: FontWeight.w700)),
                ),
              ]),
              Row(children: [
                if (isComplete) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.1),
                      border: Border.all(color: _green, width: 1.5),
                    ),
                    child: Text('✓ COMPLETO', style: _mono(color: _green, size: 7, weight: FontWeight.w800, letterSpacing: 1)),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: _surface,
                    border: Border.all(color: _border, width: 2),
                    boxShadow: const [_shadowSm],
                  ),
                  child: const Icon(Icons.book_outlined, color: _accent, size: 16),
                ),
              ]),
            ]),
            const SizedBox(height: 10),
            // Track con marcadores de tick
            Stack(children: [
              Container(height: 8, color: _border),
              TweenAnimationBuilder<double>(
                key: ValueKey(widget.target),
                tween: Tween(begin: 0, end: widget.target.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: _accent,
                      boxShadow: [BoxShadow(color: _accent.withOpacity(0.4), offset: const Offset(0, 2), blurRadius: 4)],
                    ),
                  ),
                ),
              ),
              // Marcadores de cuartos
              ...List.generate(3, (i) {
                final pos = (i + 1) / 4;
                return Align(
                  alignment: Alignment(pos * 2 - 1, 0),
                  child: Container(width: 1.5, height: 8, color: _bg.withOpacity(0.6)),
                );
              }),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NEXT MATCH BANNER — con más decoración neobrutalista
// ─────────────────────────────────────────────────────────────
class _NextMatchBanner extends StatelessWidget {
  final Map<String, dynamic>? match;
  const _NextMatchBanner({this.match});

  @override
  Widget build(BuildContext context) {
    if (match == null) return _buildEmpty();
    return _buildMatch(match!);
  }

  Widget _buildEmpty() => Container(
    margin: const EdgeInsets.fromLTRB(18, 13, 18, 0),
    decoration: BoxDecoration(
      color: _card,
      border: const Border(
        top: BorderSide(color: _accent, width: 3),
        left: BorderSide(color: _border, width: 2),
        right: BorderSide(color: _border, width: 2),
        bottom: BorderSide(color: _border, width: 2),
      ),
      boxShadow: const [_shadowLg],
    ),
    child: Row(children: [
      Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(color: _bg, border: Border(right: BorderSide(color: _border, width: 2))),
        child: Column(children: [
          Text('0', style: _mono(color: _borderH, size: 44, weight: FontWeight.w700, letterSpacing: -3)),
          const SizedBox(height: 6),
          Column(children: [
            Container(height: 1.5, width: 40, color: _borderH),
            const SizedBox(height: 3),
            Container(height: 1.5, width: 26, color: _accent),
            const SizedBox(height: 3),
            Container(height: 1.5, width: 16, color: _borderH),
          ]),
        ]),
      ),
      Expanded(child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('// PRÓXIMO PARTIDO', style: _mono(color: _accent, size: 7, weight: FontWeight.w700, letterSpacing: 2.2)),
          const SizedBox(height: 6),
          Text('SIN\nPARTIDOS', style: _mono(color: _text, size: 22, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(width: 32, height: 2, color: _accent),
          const SizedBox(height: 5),
          Text('TEMPORADA AL DÍA', style: _mono(color: _muted, size: 7, weight: FontWeight.w700, letterSpacing: 1.8)),
        ]),
      )),
    ]),
  );

  Widget _buildMatch(Map<String, dynamic> m) => Container(
    margin: const EdgeInsets.fromLTRB(18, 13, 18, 0),
    decoration: BoxDecoration(
      color: _card,
      border: const Border(
        top: BorderSide(color: _accent, width: 3),
        left: BorderSide(color: _border, width: 2),
        right: BorderSide(color: _border, width: 2),
        bottom: BorderSide(color: _border, width: 2),
      ),
      boxShadow: const [_shadowLg],
    ),
    child: Column(children: [
      // Header con más detalles
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: const BoxDecoration(
          color: _bg,
          border: Border(bottom: BorderSide(color: _border, width: 1.5)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            // Dot indicator
            Container(width: 6, height: 6, color: _accent, margin: const EdgeInsets.only(right: 6)),
            Text('PRÓXIMO PARTIDO · ${(m['league'] ?? '').toString().toUpperCase()}',
                style: _mono(color: _muted, size: 7, letterSpacing: 1.8)),
          ]),
          Row(children: [
            Text(m['date'] ?? '—', style: _mono(color: _muted, size: 7, letterSpacing: 1.2)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                border: Border.all(color: _accent, width: 1),
              ),
              child: const Icon(Icons.arrow_forward_ios, size: 8, color: _accent),
            ),
          ]),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Row(children: [
          Expanded(child: _NmTeam(name: m['home_team'] ?? '—', logoUrl: m['home_team_logo_url'])),
          SizedBox(width: 90, child: Column(children: [
            Text('VS', style: _mono(color: _muted, size: 7, letterSpacing: 3.2)),
            const SizedBox(height: 2),
            Text(m['time'] ?? '—', style: _mono(color: _text, size: 24, weight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            // Badge de liga con borde neobrutalista
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _accent,
                boxShadow: const [_shadowSm],
              ),
              child: Text(
                (m['league'] ?? 'LIGA').toString().toUpperCase().substring(
                    0, ((m['league'] ?? 'LIGA').toString().length).clamp(0, 8)),
                style: _mono(color: Colors.white, size: 7, weight: FontWeight.w800, letterSpacing: 1.2),
              ),
            ),
          ])),
          Expanded(child: _NmTeam(name: m['away_team'] ?? '—', logoUrl: m['away_team_logo_url'])),
        ]),
      ),
    ]),
  );
}

class _NmTeam extends StatelessWidget {
  final String name;
  final String? logoUrl;
  const _NmTeam({required this.name, this.logoUrl});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _bg,
        border: Border.all(color: _border, width: 2),
        boxShadow: const [_shadowSm],
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null
          ? Image.network(logoUrl!, fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Center(child: Text('⚽', style: TextStyle(fontSize: 22))))
          : const Center(child: Text('⚽', style: TextStyle(fontSize: 22))),
    ),
    const SizedBox(height: 6),
    Text(
      (name.length > 8 ? name.substring(0, 8) : name).toUpperCase(),
      textAlign: TextAlign.center,
      style: _mono(color: _text, size: 11, weight: FontWeight.w700, letterSpacing: 0.8),
    ),
  ]);
}

// ─────────────────────────────────────────────────────────────
//  TAB BAR — con indicador animado mejorado
// ─────────────────────────────────────────────────────────────
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
        border: Border(bottom: BorderSide(color: _border, width: 2)),
      ),
      child: Row(
        children: tabs.map((t) {
          final id = t['id']!;
          final isActive = activeTab == id;
          return GestureDetector(
            onTap: () => onTabChange(id),
            child: AnimatedContainer(
              duration: _tMed,
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 22),
              padding: const EdgeInsets.only(bottom: 9),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: isActive ? _accent : Colors.transparent,
                  width: 2.5,
                )),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedDefaultTextStyle(
                  duration: _tMed,
                  curve: Curves.easeOutCubic,
                  style: _mono(
                    color: isActive ? _text : _muted,
                    size: isActive ? 20 : 13,
                    weight: FontWeight.w700,
                  ),
                  child: Text(t['label']!),
                ),
                AnimatedDefaultTextStyle(
                  duration: _tMed,
                  style: _mono(color: isActive ? _accent : _muted, size: 7, letterSpacing: 1.2),
                  child: Text('${counts[id] ?? 0} items'),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MINI MATCH CARD — con detalles neobrutalistas extra
// ─────────────────────────────────────────────────────────────
class _MiniMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final String? userId;
  const _MiniMatchCard({required this.match, this.userId});

  Color get _ac {
    if (match['status'] == 'live') return _amber;
    if (_pred != null) return _green;
    final dl = match['deadline'];
    if (dl != null && DateTime.now().isAfter(DateTime.parse(dl))) return _red;
    return _accent;
  }

  Map? get _pred {
    final preds = (match['predictions'] as List?) ?? [];
    try { return preds.firstWhere((p) => p['user_id'] == userId) as Map; } catch (_) { return null; }
  }

  String get _pill {
    if (match['status'] == 'live') return 'VIVO';
    if (_pred != null) return 'GUARD.';
    final dl = match['deadline'];
    if (dl != null && DateTime.now().isAfter(DateTime.parse(dl))) return 'CERR.';
    return 'PEND.';
  }

  @override
  Widget build(BuildContext context) {
    final m = match; final pred = _pred; final ac = _ac;
    return Container(
      width: 164,
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border, width: 2),
        boxShadow: const [_shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top accent bar con gradiente
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [ac, ac.withOpacity(0.5)]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: _bg,
                      border: Border.all(color: _border, width: 1.5),
                      boxShadow: const [_shadowSm],
                    ),
                    child: m['league_logo_url'] != null
                        ? Image.network(m['league_logo_url'], fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Center(child: Text('🏆', style: TextStyle(fontSize: 9))))
                        : const Center(child: Text('🏆', style: TextStyle(fontSize: 9))),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    ((m['league'] ?? 'LIGA').toString()).substring(0, ((m['league'] ?? 'LIGA').toString().length).clamp(0, 6)).toUpperCase(),
                    style: _mono(color: _muted, size: 7, letterSpacing: 1.2),
                  ),
                ]),
                // Pill con borde sólido neobrutalista
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ac,
                    boxShadow: const [_shadowSm],
                  ),
                  child: Text(_pill, style: _mono(color: Colors.white, size: 7, weight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 10),
              _MiniTeamRow(name: m['home_team'] ?? '—', logoUrl: m['home_team_logo_url'], score: pred?['home_score'], hasPred: pred != null, ac: ac),
              Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(vertical: 1)),
              _MiniTeamRow(name: m['away_team'] ?? '—', logoUrl: m['away_team_logo_url'], score: pred?['away_score'], hasPred: pred != null, ac: ac),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.only(top: 7),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: _border))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    const Icon(Icons.access_time, size: 9, color: _muted),
                    const SizedBox(width: 3),
                    Text(m['time'] ?? '—', style: _mono(color: _muted, size: 7)),
                  ]),
                  Text(m['date'] ?? '—', style: _mono(color: _muted, size: 7)),
                ]),
              ),
              const SizedBox(height: 9),
            ]),
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
  final Color ac;
  const _MiniTeamRow({required this.name, this.logoUrl, this.score, required this.hasPred, required this.ac});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 20, height: 20,
          child: logoUrl != null
              ? Image.network(logoUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Text('⚽', style: TextStyle(fontSize: 15)))
              : const Text('⚽', style: TextStyle(fontSize: 15))),
      const SizedBox(width: 7),
      Expanded(child: Text(
        (name.length > 8 ? name.substring(0, 8) : name).toUpperCase(),
        style: _mono(color: _text, size: 10, weight: FontWeight.w700),
        overflow: TextOverflow.ellipsis,
      )),
      // Score box con color de acento sólido
      AnimatedContainer(
        duration: _tMed,
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: hasPred ? ac : _bg,
          border: Border.all(color: hasPred ? ac : _border, width: 2),
          boxShadow: hasPred ? const [_shadowSm] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          hasPred ? '${score ?? '—'}' : '—',
          style: _mono(color: hasPred ? Colors.white : _muted, size: hasPred ? 12 : 10, weight: FontWeight.w700),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  MINI LEAGUE CARD
// ─────────────────────────────────────────────────────────────
class _MiniLeagueCard extends StatelessWidget {
  final Map<String, dynamic> league; final String? userId;
  const _MiniLeagueCard({required this.league, this.userId});

  Map? get _pred {
    final preds = (league['league_predictions'] as List?) ?? [];
    try { return preds.firstWhere((p) => p['user_id'] == userId) as Map; } catch (_) { return null; }
  }

  Color get _ac {
    if (league['status'] == 'finished') return _red;
    if (_pred != null) return _green;
    final dl = league['deadline'];
    if (dl != null && DateTime.now().isAfter(DateTime.parse(dl))) return _red;
    return _accent;
  }

  @override
  Widget build(BuildContext context) {
    final l = league; final pred = _pred; final champion = pred?['predicted_champion'] as String?; final ac = _ac;
    return Container(
      width: 236,
      decoration: BoxDecoration(color: _card, border: Border.all(color: _border, width: 2), boxShadow: const [_shadow]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 3, color: ac),
          Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(color: _bg, border: Border.all(color: _border, width: 1.5), boxShadow: const [_shadowSm]),
                child: l['logo_url'] != null
                    ? Image.network(l['logo_url'], fit: BoxFit.contain, errorBuilder: (_, _, _) => Center(child: Text(l['logo'] ?? '🏆', style: const TextStyle(fontSize: 9))))
                    : Center(child: Text(l['logo'] ?? '🏆', style: const TextStyle(fontSize: 9))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((l['name'] ?? 'LIGA').toString().toUpperCase(), style: _mono(color: _text, size: 9, weight: FontWeight.w700, letterSpacing: 1), overflow: TextOverflow.ellipsis),
                Text(l['season'] ?? '—', style: _mono(color: _muted, size: 7, letterSpacing: 1)),
              ])),
              // Status pill sólido
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ac,
                  border: Border.all(color: _border, width: 1.5),
                  boxShadow: const [_shadowSm],
                ),
                child: Text(
                  pred != null ? 'GUARD.' : 'PEND.',
                  style: _mono(color: Colors.white, size: 7, weight: FontWeight.w800),
                ),
              ),
            ]),
            Container(height: 1.5, color: _border, margin: const EdgeInsets.symmetric(vertical: 10)),
            Text('CAMPEÓN', style: _mono(color: _muted, size: 6, weight: FontWeight.w700, letterSpacing: 2)),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: _tMed,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: champion != null ? ac.withOpacity(0.08) : _bg,
                border: Border(
                  left: BorderSide(color: champion != null ? ac : _border, width: champion != null ? 3 : 2),
                  top: BorderSide(color: _border, width: 1.5),
                  right: BorderSide(color: _border, width: 1.5),
                  bottom: BorderSide(color: _border, width: 1.5),
                ),
              ),
              child: Text(
                champion ?? 'Escribe el equipo...',
                style: _mono(color: champion != null ? ac : _muted, size: 9, weight: champion != null ? FontWeight.w700 : FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ])),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MINI AWARD CARD
// ─────────────────────────────────────────────────────────────
class _MiniAwardCard extends StatelessWidget {
  final Map<String, dynamic> award; final String? userId;
  const _MiniAwardCard({required this.award, this.userId});

  Map? get _pred {
    final preds = (award['award_predictions'] as List?) ?? [];
    try { return preds.firstWhere((p) => p['user_id'] == userId) as Map; } catch (_) { return null; }
  }

  Color get _ac {
    if (award['status'] == 'finished') return _red;
    if (_pred != null) return _green;
    final dl = award['deadline'];
    if (dl != null && DateTime.now().isAfter(DateTime.parse(dl))) return _red;
    return _accent;
  }

  @override
  Widget build(BuildContext context) {
    final a = award; final pred = _pred; final winner = pred?['predicted_winner'] as String?; final ac = _ac;
    return Container(
      width: 216,
      decoration: BoxDecoration(color: _card, border: Border.all(color: _border, width: 2), boxShadow: const [_shadow]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 3, color: ac),
        Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(color: _bg, border: Border.all(color: _border, width: 1.5), boxShadow: const [_shadowSm]),
              child: a['logo_url'] != null
                  ? Image.network(a['logo_url'], fit: BoxFit.contain, errorBuilder: (_, _, _) => Center(child: Text(a['logo'] ?? '🏅', style: const TextStyle(fontSize: 9))))
                  : Center(child: Text(a['logo'] ?? '🏅', style: const TextStyle(fontSize: 9))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((a['name'] ?? 'PREMIO').toString().toUpperCase(), style: _mono(color: _text, size: 9, weight: FontWeight.w700, letterSpacing: 1), overflow: TextOverflow.ellipsis),
              Text(a['season'] ?? '—', style: _mono(color: _muted, size: 7, letterSpacing: 1)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ac,
                border: Border.all(color: _border, width: 1.5),
                boxShadow: const [_shadowSm],
              ),
              child: Text(
                pred != null ? 'GUARD.' : 'PEND.',
                style: _mono(color: Colors.white, size: 7, weight: FontWeight.w800),
              ),
            ),
          ]),
          Container(height: 1.5, color: _border, margin: const EdgeInsets.symmetric(vertical: 10)),
          Text('TU PREDICCIÓN', style: _mono(color: _muted, size: 6, weight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: _tMed,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: winner != null ? ac.withOpacity(0.08) : _bg,
              border: Border(
                left: BorderSide(color: winner != null ? ac : _border, width: winner != null ? 3 : 2),
                top: BorderSide(color: _border, width: 1.5),
                right: BorderSide(color: _border, width: 1.5),
                bottom: BorderSide(color: _border, width: 1.5),
              ),
            ),
            child: Text(
              winner ?? 'Ingresa el nombre...',
              style: _mono(color: winner != null ? ac : _muted, size: 9, weight: winner != null ? FontWeight.w700 : FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MORE CARD
// ─────────────────────────────────────────────────────────────
class _MoreCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _MoreCard({this.onTap});

  @override
  Widget build(BuildContext context) => _Pressable(
    onTap: onTap,
    child: Container(
      width: 56,
      decoration: BoxDecoration(
        color: _card,
        border: const Border(
          top: BorderSide(color: _accent, width: 3),
          left: BorderSide(color: _border, width: 2),
          right: BorderSide(color: _border, width: 2),
          bottom: BorderSide(color: _border, width: 2),
        ),
        boxShadow: const [_shadow],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('»', style: _mono(color: _accent, size: 18, weight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text('TODOS', style: _mono(color: _accent, size: 7, weight: FontWeight.w700, letterSpacing: 1.4)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  EMPTY CARDS
// ─────────────────────────────────────────────────────────────
class _EmptyMatchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 160,
    height: 55,
    decoration: BoxDecoration(
      color: _card,
      border: const Border(top: BorderSide(color: _accent, width: 3), left: BorderSide(color: _border, width: 2), right: BorderSide(color: _border, width: 2), bottom: BorderSide(color: _border, width: 2)),
      boxShadow: const [_shadow],
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('00', style: _mono(color: _borderH, size: 48, weight: FontWeight.w700, letterSpacing: -1)),
      Container(width: 20, height: 1.5, color: _accent, margin: const EdgeInsets.symmetric(vertical: 5)),
      Text('SIN\nPARTIDOS\nPEND.', textAlign: TextAlign.center, style: _mono(color: _muted, size: 10, weight: FontWeight.w700, letterSpacing: 1.4)),
    ]),
  );
}

class _EmptyCard extends StatelessWidget {
  final String label;
  const _EmptyCard({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    width: 138,
    decoration: BoxDecoration(color: _card, border: Border.all(color: _border, width: 2), boxShadow: const [_shadow]),
    child: Center(child: Text(label, textAlign: TextAlign.center, style: _mono(color: _muted, size: 7, weight: FontWeight.w700, letterSpacing: 1.4))),
  );
}

// ─────────────────────────────────────────────────────────────
//  BOTTOM TAB BAR
// ─────────────────────────────────────────────────────────────
class _BottomTabBar extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChange;
  const _BottomTabBar({required this.activeTab, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final tabs = [{'id': 'ranking', 'label': 'Ranking', 'count': '3 items'}, {'id': 'stats', 'label': 'Stats', 'count': '4 items'}];
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 2))),
      child: Row(children: tabs.map((t) {
        final id = t['id']!; final isActive = activeTab == id;
        return GestureDetector(
          onTap: () => onTabChange(id),
          child: AnimatedContainer(
            duration: _tMed,
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 22),
            padding: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? _accent : Colors.transparent, width: 2.5))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedDefaultTextStyle(
                duration: _tMed,
                style: _mono(color: isActive ? _text : _muted, size: isActive ? 20 : 13, weight: FontWeight.w700),
                child: Text(t['label']!),
              ),
              AnimatedDefaultTextStyle(
                duration: _tMed,
                style: _mono(color: isActive ? _accent : _muted, size: 7, letterSpacing: 1.2),
                child: Text(t['count']!),
              ),
            ]),
          ),
        );
      }).toList()),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PODIUM PANEL — con números de posición en cajas sólidas
// ─────────────────────────────────────────────────────────────
class _PodiumPanel extends StatefulWidget {
  final List topUsers;
  final Map<String, dynamic>? currentUser;
  const _PodiumPanel({super.key, required this.topUsers, this.currentUser});
  @override
  State<_PodiumPanel> createState() => _PodiumPanelState();
}

class _PodiumPanelState extends State<_PodiumPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _anims = List.generate(3, (i) => CurvedAnimation(
      parent: _ctrl,
      curve: Interval(i * 0.15, i * 0.15 + 0.6, curve: Curves.easeOutBack),
    ));
    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.topUsers.length < 3) return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _card, border: Border.all(color: _border, width: 2), boxShadow: const [_shadow]),
      child: Center(child: Text('SIN DATOS DE RANKING', style: _mono(color: _muted, size: 9, weight: FontWeight.w700, letterSpacing: 2))),
    );

    final visual    = [widget.topUsers[1], widget.topUsers[0], widget.topUsers[2]];
    // Posición real: [2, 1, 3]
    final positions = [2, 1, 3];
    final avSizes   = [42.0, 52.0, 38.0];
    final stepH     = [28.0, 40.0, 16.0];
    final avColors  = [_accentL, _accent, _accentL];
    final borderCs  = [_silver, _gold, _bronze];
    final stepCs    = [_silver.withOpacity(0.1), _gold.withOpacity(0.1), _bronze.withOpacity(0.1)];
    final ptCs      = [_silver, _gold, _bronze];
    // Colores de caja de posición
    final posBgCs   = [_silver, _amber, _bronze];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _borderH, width: 1.5),
        boxShadow: const [_shadowLg],
      ),
      child: Column(children: [
        // Header decorativo
        Row(children: [
          Container(width: 5, height: 5, color: _accent),
          const SizedBox(width: 8),
          Text('RANKING GLOBAL', style: _mono(color: _muted, size: 7, weight: FontWeight.w700, letterSpacing: 2.2)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: _border)),
          const SizedBox(width: 8),
          Container(width: 5, height: 5, color: _border),
        ]),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            final u    = visual[i] as Map<String, dynamic>;
            final isMe = u['id'] == widget.currentUser?['id'];
            final name = (u['name'] ?? '—').toString();
            final pts  = u['points'] ?? 0;
            final av   = u['avatar_url'] as String?;
            final sz   = avSizes[i];
            final pos  = positions[i];

            return Expanded(
              child: AnimatedBuilder(
                animation: _anims[i],
                builder: (_, child) => Opacity(
                  opacity: _anims[i].value.clamp(0.0, 1.0),
                  child: Transform.translate(offset: Offset(0, 20 * (1 - _anims[i].value.clamp(0.0, 1.0))), child: child),
                ),
                child: Column(children: [
                  // Número de posición — caja sólida neobrutalista
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: posBgCs[i],
                      border: Border.all(color: _border, width: 2),
                      boxShadow: const [_shadowSm],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$pos',
                      style: _mono(color: Colors.white, size: 10, weight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Avatar
                  Container(
                    width: sz, height: sz,
                    decoration: BoxDecoration(
                      color: avColors[i],
                      border: Border.all(color: _border, width: i == 1 ? 3 : 2),
                      boxShadow: [BoxShadow(color: _shadowColor, offset: Offset(i == 1 ? 4 : 3, i == 1 ? 4 : 3), blurRadius: 0)],
                    ),
                    child: av != null
                        ? Image.network(av, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(child: Text(name[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: sz * 0.32, fontWeight: FontWeight.w800))))
                        : Center(child: Text(name[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: sz * 0.32, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(height: 4),
                  Text((name.length > 8 ? name.substring(0, 8) : name).toUpperCase(), overflow: TextOverflow.ellipsis, style: _mono(color: _text, size: 7, weight: FontWeight.w700)),
                  if (isMe) Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: _accent,
                      border: Border.all(color: _border, width: 1.5),
                      boxShadow: const [_shadowSm],
                    ),
                    child: Text('TÚ', style: _mono(color: Colors.white, size: 6, weight: FontWeight.w800, letterSpacing: 1)),
                  ),
                  Text('$pts', style: _mono(color: ptCs[i], size: 10, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: stepH[i],
                    decoration: BoxDecoration(
                      color: stepCs[i],
                      border: Border(
                        top: BorderSide(color: borderCs[i], width: 2),
                        left: BorderSide(color: borderCs[i].withOpacity(0.3), width: 1),
                        right: BorderSide(color: borderCs[i].withOpacity(0.3), width: 1),
                      ),
                    ),
                  ),
                ]),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STATS PANEL — grid 2×2
// ─────────────────────────────────────────────────────────────
class _StatsPanel extends StatelessWidget {
  final Map<String, dynamic>? user;
  const _StatsPanel({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final u           = user ?? {};
    final points      = u['points']      ?? 0;
    final correct     = u['correct']     ?? 0;
    final predictions = u['predictions'] ?? 0;
    final accuracy    = predictions > 0 ? ((correct / predictions) * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border, width: 2),
        boxShadow: const [_shadowLg],
      ),
      child: Column(children: [
        // Borde superior de acento
        Container(height: 3, color: _accent),
        IntrinsicHeight(
          child: Row(children: [
            Expanded(child: _StatCell(value: '$points', unit: 'pts', label: 'PUNTOS', accent: true)),
            Container(width: 2, color: _border),
            Expanded(child: _StatCell(value: '$correct', label: 'ACIERTOS')),
          ]),
        ),
        Container(height: 2, color: _border),
        IntrinsicHeight(
          child: Row(children: [
            Expanded(child: _StatCellBar(value: '$accuracy', unit: '%', label: 'PRECISIÓN', pct: accuracy / 100)),
            Container(width: 2, color: _border),
            Expanded(child: _StatCell(value: '$predictions', label: 'PREDICCIONES')),
          ]),
        ),
      ]),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value, label;
  final String? unit;
  final bool accent;
  const _StatCell({required this.value, required this.label, this.unit, this.accent = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AnimatedSwitcher(
              duration: _tSlow,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: Text(value, key: ValueKey(value),
                style: _mono(color: accent ? _accent : _text, size: 32, weight: FontWeight.w700, letterSpacing: -1.5)),
            ),
            if (unit != null) Text(unit!, style: _mono(color: _muted, size: 9)),
          ],
        ),
        const SizedBox(height: 4),
        // Línea decorativa bajo el label
        Row(children: [
          Container(width: 8, height: 2, color: accent ? _accent : _border),
          const SizedBox(width: 5),
          Text(label, style: _mono(color: _muted, size: 7, weight: FontWeight.w700, letterSpacing: 1.6)),
        ]),
      ],
    ),
  );
}

class _StatCellBar extends StatelessWidget {
  final String value, label;
  final String? unit;
  final double pct;
  const _StatCellBar({required this.value, required this.label, this.unit, required this.pct});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AnimatedSwitcher(
              duration: _tSlow,
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: Text(value, key: ValueKey(value),
                style: _mono(color: _green, size: 32, weight: FontWeight.w700, letterSpacing: -1.5)),
            ),
            if (unit != null) Text(unit!, style: _mono(color: _muted, size: 9)),
          ],
        ),
        const SizedBox(height: 4),
        Row(children: [
          Container(width: 8, height: 2, color: _green),
          const SizedBox(width: 5),
          Text(label, style: _mono(color: _muted, size: 7, weight: FontWeight.w700, letterSpacing: 1.6)),
        ]),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Container(
            height: 4,
            decoration: BoxDecoration(
              color: _bg,
              border: Border.all(color: _borderH, width: 1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  color: _accent,
                  boxShadow: [BoxShadow(color: _accent.withOpacity(0.4), offset: const Offset(0, 1), blurRadius: 2)],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  SPLASH DE CARGA
// ─────────────────────────────────────────────────────────────
class _AppSplash extends StatefulWidget {
  const _AppSplash();
  @override
  State<_AppSplash> createState() => _AppSplashState();
}

class _AppSplashState extends State<_AppSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        color: _bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _accent,
                  border: Border.all(color: _text, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _text.withOpacity(0.25 + _pulse.value * 0.15),
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'GLOBALSCORE',
                style: _mono(
                  size: 18,
                  weight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Color.lerp(_text, _accent, _pulse.value * 0.4)!,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'cargando...',
                style: _mono(size: 9, color: _muted, letterSpacing: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  child: LinearProgressIndicator(
                    backgroundColor: _border,
                    color: _accent,
                    minHeight: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SKELETON
// ─────────────────────────────────────────────────────────────
class _BrutalistSkeleton extends StatefulWidget {
  const _BrutalistSkeleton();
  @override
  State<_BrutalistSkeleton> createState() => _BrutalistSkeletonState();
}

class _BrutalistSkeletonState extends State<_BrutalistSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _shimmer,
    builder: (_, __) {
      final alpha = 0.5 + _shimmer.value * 0.5;
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          _SkBox(height: 70, alpha: alpha),
          const SizedBox(height: 13),
          _SkBox(height: 120, alpha: alpha),
          const SizedBox(height: 14),
          _SkBox(height: 36, alpha: alpha),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _SkBox(height: 160, alpha: alpha)),
            const SizedBox(width: 10),
            Expanded(child: _SkBox(height: 160, alpha: alpha * 0.85)),
          ]),
        ]),
      );
    },
  );
}

class _SkBox extends StatelessWidget {
  final double height; final double alpha;
  const _SkBox({required this.height, this.alpha = 1});
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Color.lerp(_card, _surface, alpha),
      border: Border.all(color: _border, width: 1.5),
      boxShadow: const [_shadow],
    ),
  );
}