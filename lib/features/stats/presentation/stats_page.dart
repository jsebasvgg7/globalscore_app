import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';
import '../domain/stats_model.dart';

// ── Paleta Neobrutalismo Retro
const _accent    = Color(0xFF2D0CFF);   // azul eléctrico
const _accentL   = Color(0xFF7B61FF);   // lavanda
const _exact     = Color(0xFFFF3C00);   // naranja quemado retro
const _correct   = Color(0xFF00C48C);   // verde menta
const _wrong     = Color(0xFFFF9500);   // ámbar
const _gold      = Color(0xFFFFD600);   // amarillo neón
const _bg        = Color(0xFFF5F0E8);   // crema off-white
const _card      = Color(0xFFEDE7DA);   // crema oscura
const _border    = Color(0xFF1A1A2E);   // negro profundo (bordes duros)
const _text      = Color(0xFF1A1A2E);
const _muted     = Color(0xFF555550);
// sombra dura neobrut
const _shadow    = Color(0xFF1A1A2E);

String _fmt(int n) {
  // Equivalente a toLocaleString('es-ES')
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final timeRange = ref.watch(statsTimeRangeProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _TopBar(timeRange: timeRange, ref: ref),
          Expanded(
            child: statsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
              ),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error: $e\n\n$st',
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ),
              ),
              data: (stats) => stats.totalPredictions == 0
                  ? _EmptyState(timeRange: timeRange)
                  : _StatsBody(stats: stats),
            ),
          ),
        ],
      ),
    );
  }
}

// ══ TOP BAR con pills de rango ══════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final String timeRange;
  final WidgetRef ref;
  const _TopBar({required this.timeRange, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 2)),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 22, color: _accent),
          const SizedBox(width: 8),
          const Text(
            'ESTADÍSTICAS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: _text,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              for (final r in [
                ('all', 'TODO'),
                ('month', 'MES'),
                ('week', 'SEMANA'),
              ])
                _RangePill(
                  label: r.$2,
                  active: timeRange == r.$1,
                  onTap: () => ref.read(statsTimeRangeProvider.notifier).set(r.$1)
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _RangePill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(left: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _accent : _bg,
          border: Border.all(color: _border, width: 2),
          boxShadow: active
              ? [const BoxShadow(color: _shadow, offset: Offset(3, 3), blurRadius: 0)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: active ? Colors.white : _text,
          ),
        ),
      ),
    );
  }
}

// ══ EMPTY STATE ══════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final String timeRange;
  const _EmptyState({required this.timeRange});

  String get _label => switch (timeRange) {
    'month' => 'este mes',
    'week'  => 'esta semana',
    _       => 'este período',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _bg,
                border: Border.all(color: _border, width: 3),
                boxShadow: const [BoxShadow(color: _shadow, offset: Offset(5, 5), blurRadius: 0)],
              ),
              child: const Icon(Icons.sports_soccer, size: 36, color: _accent),
            ),
            const SizedBox(height: 20),
            Text(
              'SIN PARTIDOS $_label'.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: _text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los partidos de este período aún no han sido jugados o no tienes predicciones finalizadas.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ══ BODY SCROLLABLE ══════════════════════════════════════════════════════
class _StatsBody extends StatelessWidget {
  final StatsModel stats;
  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroGrid(stats: stats),
          _SectionDivider(),
          _SectionHeader(label: 'DESGLOSE DE RESULTADOS', color: _accent),
          _ResultsDesglose(stats: stats),
          if (stats.leagueStats.isNotEmpty) ...[
            _SectionDivider(),
            _SectionHeader(label: 'RENDIMIENTO POR LIGA', color: _gold),
            _LeagueTable(leagues: stats.leagueStats),
          ],
          _SectionDivider(),
          _SectionHeader(label: 'RENDIMIENTO POR DÍA', color: _accentL),
          _DayBars(days: stats.dayStats),
          _SectionDivider(),
          _SectionHeader(label: 'DISTRIBUCIÓN DE PUNTOS', color: _accent),
          _PointsDistribution(stats: stats),
          _SectionDivider(),
          _SectionHeader(label: 'PRONÓSTICOS ESPECIALES', color: _gold),
          _ForecastGrid(stats: stats),
          _StreakCard(stats: stats),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ══ HERO 2×2 ═══════════════════════════════════════════════════════════
class _HeroGrid extends StatelessWidget {
  final StatsModel stats;
  const _HeroGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border, width: 2)),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.4,
        padding: EdgeInsets.zero,
        children: [
          _HeroBlock(
            icon: Icons.adjust,
            iconColor: _accent,
            label: 'PRECISIÓN',
            value: '${stats.accuracy}%',
            valueColor: _accent,
            sub: '${_fmt(stats.totalPredictions)} finalizadas',
            borderRight: true,
            borderBottom: true,
          ),
          _HeroBlock(
            icon: Icons.star_outline,
            iconColor: _exact,
            label: 'EXACTOS',
            value: _fmt(stats.exact),
            valueColor: _exact,
            sub: '${stats.exactAccuracy}% exactitud',
            borderRight: false,
            borderBottom: true,
          ),
          _HeroBlock(
            icon: Icons.check_circle_outline,
            iconColor: _correct,
            label: 'CORRECTOS',
            value: _fmt(stats.correctResult),
            valueColor: _correct,
            sub: '+3 pts c/u',
            borderRight: true,
            borderBottom: false,
          ),
          _HeroBlock(
            icon: Icons.bolt,
            iconColor: _gold,
            label: 'PUNTOS',
            value: _fmt(stats.totalPoints),
            valueColor: _gold,
            sub: 'de partidos',
            borderRight: false,
            borderBottom: false,
          ),
        ],
      ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final String sub;
  final bool borderRight;
  final bool borderBottom;

  const _HeroBlock({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.sub,
    required this.borderRight,
    required this.borderBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(
          right: borderRight ? const BorderSide(color: _border, width: 2) : BorderSide.none,
          bottom: borderBottom ? const BorderSide(color: _border, width: 2) : BorderSide.none,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: _muted)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      height: 1,
                      color: valueColor)),
              const SizedBox(height: 4),
              Text(sub,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _muted)),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor,
                border: Border.all(color: _border, width: 2),
                boxShadow: const [BoxShadow(color: _shadow, offset: Offset(3, 3), blurRadius: 0)],
              ),
              child: Icon(icon, size: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ══ HELPERS ═══════════════════════════════════════════════════════════
class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 2, thickness: 2, color: _border);
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _card,
        border: const Border(bottom: BorderSide(color: _border, width: 2)),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: _text)),
        ],
      ),
    );
  }
}

// ══ DESGLOSE ═══════════════════════════════════════════════════════════
class _ResultsDesglose extends StatelessWidget {
  final StatsModel stats;
  const _ResultsDesglose({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalPredictions;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          _ResultBar(
            count: stats.exact,
            pts: '+${_fmt(stats.exact * 5)} pts',
            ptsColor: _exact,
            label: 'EXACTOS',
            pct: total > 0 ? ((stats.exact / total) * 100).round() : 0,
            barColor: _exact,
            total: total,
          ),
          const SizedBox(height: 14),
          _ResultBar(
            count: stats.correctResult,
            pts: '+${_fmt(stats.correctResult * 3)} pts',
            ptsColor: _correct,
            label: 'CORRECTOS',
            pct: total > 0 ? ((stats.correctResult / total) * 100).round() : 0,
            barColor: _correct,
            total: total,
          ),
          const SizedBox(height: 14),
          _ResultBar(
            count: stats.wrong,
            pts: '0 pts',
            ptsColor: _wrong,
            label: 'INCORRECTOS',
            pct: total > 0 ? ((stats.wrong / total) * 100).round() : 0,
            barColor: _wrong,
            total: total,
          ),
        ],
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  final int count;
  final String pts;
  final Color ptsColor;
  final String label;
  final int pct;
  final Color barColor;
  final int total;

  const _ResultBar({
    required this.count,
    required this.pts,
    required this.ptsColor,
    required this.label,
    required this.pct,
    required this.barColor,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_fmt(count),
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1, color: barColor)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ptsColor,
                border: Border.all(color: _border, width: 1.5),
                boxShadow: const [BoxShadow(color: _shadow, offset: Offset(2, 2), blurRadius: 0)],
              ),
              child: Text(pts, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const Spacer(),
            Text('$pct%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _text)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: _muted)),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct / 100),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, v, _) => Container(
            height: 8,
            decoration: BoxDecoration(border: Border.all(color: _border, width: 1.5)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: Container(color: barColor),
            ),
          ),
        ),
      ],
    );
  }
}

// ══ TABLA DE LIGAS ═══════════════════════════════════════════════════
class _LeagueTable extends StatelessWidget {
  final List<LeagueStat> leagues;
  const _LeagueTable({required this.leagues});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Thead
        Container(
          height: 36,
          color: _card,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const SizedBox(width: 28),
              const Expanded(child: Text('Liga', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: _muted))),
              const SizedBox(width: 48, child: Text('Pts', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _muted))),
              const SizedBox(width: 100, child: Text('Precisión', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _muted))),
            ],
          ),
        ),
        ...leagues.asMap().entries.map((e) => _LeagueRow(league: e.value, rank: e.key + 1)),
      ],
    );
  }
}

class _LeagueRow extends StatelessWidget {
  final LeagueStat league;
  final int rank;
  const _LeagueRow({required this.league, required this.rank});

  Color get badgeColor {
    if (rank == 1) return const Color(0xFF5B4FD8);
    if (rank == 2) return const Color(0xFF8B7FC7);
    if (rank == 3) return const Color(0xFFA599D9);
    return _border;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: badgeColor,
              border: Border.all(color: _border, width: 2),
              boxShadow: const [BoxShadow(color: _shadow, offset: Offset(2, 2), blurRadius: 0)],
            ),
            alignment: Alignment.center,
            child: Text('$rank',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(league.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _text),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 48,
            child: Text(_fmt(league.points),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _text)),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(right: 8),
                    color: _border,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: league.accuracy / 100,
                      child: Container(color: _accent),
                    ),
                  ),
                ),
                Text('${league.accuracy}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══ BARRAS POR DÍA ═══════════════════════════════════════════════════
class _DayBars extends StatelessWidget {
  final List<DayStat> days;
  const _DayBars({required this.days});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox(height: 60);
    return LayoutBuilder(
      builder: (context, constraints) {
        const hPadding = 32.0;
        final available = constraints.maxWidth - hPadding;
        final naturalColWidth = available / days.length;
        final colWidth = naturalColWidth.clamp(36.0, 80.0);
        final needsScroll = colWidth * days.length > available;

        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: days
              .map((d) => SizedBox(
                    width: colWidth,
                    child: _DayColumn(day: d, colWidth: colWidth),
                  ))
              .toList(),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: needsScroll
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: row,
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: row,
                ),
        );
      },
    );
  }
}

class _DayColumn extends StatelessWidget {
  final DayStat day;
  final double colWidth;
  const _DayColumn({required this.day, required this.colWidth});

  @override
  Widget build(BuildContext context) {
    final barWidth = (colWidth - 12).clamp(20.0, 56.0);
    return Column(
      children: [
        Text('${day.accuracy}%',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _muted)),
        const SizedBox(height: 4),
        SizedBox(
          width: barWidth,
          height: 60,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: day.accuracy / 100),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (_, v, __) => Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: barWidth,
                  height: 60 * (v == 0 ? 0.04 : v),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: day.opacity),
                    border: Border.all(color: _border, width: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(day.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: _muted)),
        Text('${day.correct}/${day.total}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8, color: _muted)),
      ],
    );
  }
}

// ══ DISTRIBUCIÓN DE PUNTOS ═══════════════════════════════════════════
class _PointsDistribution extends StatelessWidget {
  final StatsModel stats;
  const _PointsDistribution({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          _DistRow(label: 'PARTIDOS', value: stats.pointsFromMatches, pct: stats.pctMatches, color: _accent),
          const SizedBox(height: 10),
          _DistRow(label: 'LIGAS', value: stats.pointsFromLeagues, pct: stats.pctLeagues, color: _exact),
          const SizedBox(height: 10),
          _DistRow(label: 'PREMIOS', value: stats.pointsFromAwards, pct: stats.pctAwards, color: _correct),
        ],
      ),
    );
  }
}

class _DistRow extends StatelessWidget {
  final String label;
  final int value;
  final int pct;
  final Color color;
  const _DistRow({required this.label, required this.value, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: _muted)),
            const Spacer(),
            Text(_fmt(value), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
          ],
        ),
        const SizedBox(height: 5),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct / 100),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, v, _) => Container(
            height: 8,
            decoration: BoxDecoration(border: Border.all(color: _border, width: 1.5)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: Container(color: color),
            ),
          ),
        ),
      ],
    );
  }
}

// ══ FORECAST GRID 2×2 ════════════════════════════════════════════════
class _ForecastGrid extends StatelessWidget {
  final StatsModel stats;
  const _ForecastGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
        children: [
          _ForecastItem(value: _fmt(stats.leaguePredictions), label: 'LIGAS PRED.'),
          _ForecastItem(value: _fmt(stats.awardPredictions), label: 'PREMIOS PRED.'),
          _ForecastItem(value: _fmt(stats.pointsFromLeagues), label: 'PTS LIGAS', valueColor: _exact),
          _ForecastItem(value: _fmt(stats.pointsFromAwards), label: 'PTS PREMIOS', valueColor: _exact),
        ],
      ),
    );
  }
}

class _ForecastItem extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  const _ForecastItem({required this.value, required this.label, this.valueColor = _text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border, width: 2),
        boxShadow: const [BoxShadow(color: _shadow, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1, color: valueColor)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: _muted)),
        ],
      ),
    );
  }
}

// ══ STREAK CARD ═══════════════════════════════════════════════════════
class _StreakCard extends StatelessWidget {
  final StatsModel stats;
  const _StreakCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: _gold,
        border: Border.all(color: _border, width: 3),
        boxShadow: const [BoxShadow(color: _shadow, offset: Offset(6, 6), blurRadius: 0)],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RACHA ACTUAL',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: _text)),
          const SizedBox(height: 4),
          Text(_fmt(stats.currentStreak),
              style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, letterSpacing: -3, height: 1, color: _text)),
          const SizedBox(height: 4),
          const Text('predicciones seguidas correctas',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 10),
          Container(height: 2, color: _border),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Récord personal',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _text)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent,
                  border: Border.all(color: _border, width: 2),
                  boxShadow: const [BoxShadow(color: _shadow, offset: Offset(3, 3), blurRadius: 0)],
                ),
                child: Text(_fmt(stats.bestStreak),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}