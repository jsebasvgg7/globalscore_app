import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_events_shared.dart';

const _koOrder = ['Octavos', 'Cuartos', 'Semifinal', 'Tercero', 'Final'];

class EventTabTabla extends StatelessWidget {
  final EventDetail detail;
  const EventTabTabla({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final knockout = detail.knockout;
    final standings = detail.standings;

    // Si no hay nada en absoluto
    if (knockout.isEmpty && standings.isEmpty) {
      return const Center(
        child: EvEmpty(message: 'Sin datos de campaña registrados'),
      );
    }

    final Map<String, List<KnockoutMatch>> byRound = {};
    for (final m in knockout) {
      byRound.putIfAbsent(m.round, () => []).add(m);
    }
    final rounds = _koOrder.where(byRound.containsKey).toList();
    for (final r in byRound.keys) {
      if (!rounds.contains(r)) rounds.add(r);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EvTabHeader(
            icon: Icons.table_chart_outlined,
            title: 'LA CAMPAÑA',
            subtitle: 'Recorrido del equipo protagonista',
          ),

          // ── Tabla de posiciones (si existe) ──────────────────
          if (standings.isNotEmpty) ...[
            EvSectionLabel(label: 'TABLA DE POSICIONES', color: kEvAccent),
            _StandingsTable(standings: standings),
          ],

          // ── Partidos decisivos (knockout) ─────────────────────
          if (rounds.isNotEmpty) ...[
            EvSectionLabel(label: 'PARTIDOS DECISIVOS', color: kEvGold),
            ...rounds.map((r) => _RoundBlock(round: r, matches: byRound[r]!)),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Tabla de posiciones ───────────────────────────────────────
class _StandingsTable extends StatelessWidget {
  final List<EventStanding> standings;
  const _StandingsTable({required this.standings});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        border: Border.all(color: kEvBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: kEvDark.withOpacity(0.35),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Container(
            color: kEvDark,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text('#',
                      style: evMono(size: 8, weight: FontWeight.w700, color: Colors.white54)),
                ),
                Expanded(
                  child: Text('EQUIPO',
                      style: evMono(size: 8, weight: FontWeight.w700, color: Colors.white54)),
                ),
                ...['PJ', 'G', 'E', 'P', 'GF', 'GC', 'DG', 'PTS'].map(
                  (h) => SizedBox(
                    width: 26,
                    child: Text(h,
                        textAlign: TextAlign.center,
                        style: evMono(size: 7, weight: FontWeight.w700, color: Colors.white54)),
                  ),
                ),
              ],
            ),
          ),
          // Data rows (ordenados por posición ascendente)
          ...(() {
            final sorted = [...standings]..sort((a, b) => a.position.compareTo(b.position));
            return sorted.asMap().entries.map((e) {
              final s = e.value;
              final isLast = e.key == sorted.length - 1;
              return _StandingRow(standing: s, showBorder: !isLast);
            });
          })(),
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final EventStanding standing;
  final bool showBorder;
  const _StandingRow({required this.standing, required this.showBorder});

  @override
  Widget build(BuildContext context) {
    final isChamp = standing.isChampion;

    return Container(
      decoration: BoxDecoration(
        color: isChamp ? kEvGold.withOpacity(0.08) : kEvBg,
        border: Border(
          bottom: showBorder
              ? BorderSide(color: kEvBorderL, width: 0.5)
              : BorderSide.none,
          left: isChamp
              ? const BorderSide(color: kEvGold, width: 3)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Row(
              children: [
                if (isChamp)
                  const Icon(Icons.emoji_events, size: 10, color: kEvGold)
                else
                  Text(
                    '${standing.position}',
                    style: evMono(size: 10, weight: FontWeight.w700, color: kEvMuted),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              standing.teamName,
              style: evMono(
                size: 11,
                weight: isChamp ? FontWeight.w800 : FontWeight.normal,
                color: isChamp ? kEvDark : kEvDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...[
            standing.played,
            standing.wins,
            standing.draws,
            standing.losses,
            standing.goalsFor,
            standing.goalsAgainst,
            standing.goalDiff,
            standing.points,
          ].map(
            (v) => SizedBox(
              width: 26,
              child: Text(
                '$v',
                textAlign: TextAlign.center,
                style: evMono(
                  size: 10,
                  weight: isChamp ? FontWeight.w700 : FontWeight.normal,
                  color: isChamp ? kEvGold : kEvMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Round block (knockout) ────────────────────────────────────
class _RoundBlock extends StatelessWidget {
  final String round;
  final List<KnockoutMatch> matches;

  const _RoundBlock({required this.round, required this.matches});

  Color _color() {
    switch (round) {
      case 'Final':     return kEvGold;
      case 'Semifinal': return kEvPurple;
      case 'Tercero':   return kEvBlue;
      default:          return const Color(0xFFD2D2C7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: c,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (round == 'Final') ...[
                const Icon(Icons.emoji_events, size: 11, color: Colors.white),
                const SizedBox(width: 5),
              ],
              Text(
                round.toUpperCase(),
                style: evMono(
                    size: 9, weight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          decoration: BoxDecoration(
            border: Border.all(color: kEvBorder, width: 1.5),
          ),
          child: Column(
            children: matches.asMap().entries.map((e) {
              final isLast = e.key == matches.length - 1;
              return _MatchRow(match: e.value, roundColor: c, showBorder: !isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MatchRow extends StatelessWidget {
  final KnockoutMatch match;
  final Color roundColor;
  final bool showBorder;

  const _MatchRow({
    required this.match,
    required this.roundColor,
    required this.showBorder,
  });

  @override
  Widget build(BuildContext context) {
    final winA = match.winnerIsA;
    final winB = match.winnerIsB;

    return Container(
      decoration: BoxDecoration(
        color: match.isDecisive ? roundColor.withOpacity(0.06) : kEvBg,
        border: showBorder
            ? Border(bottom: BorderSide(color: kEvBorderL, width: 0.5))
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    match.teamA,
                    style: evMono(
                      size: 12,
                      weight: winA ? FontWeight.w900 : FontWeight.normal,
                      color: winA ? kEvDark : kEvMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: kEvDark,
                  child: Text(
                    match.scoreA != null && match.scoreB != null
                        ? '${match.scoreA} – ${match.scoreB}'
                        : '– – –',
                    style: evMono(size: 14, weight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.teamB,
                    style: evMono(
                      size: 12,
                      weight: winB ? FontWeight.w900 : FontWeight.normal,
                      color: winB ? kEvDark : kEvMuted,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (match.notes != null && match.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              color: kEvCard,
              child: Text(
                match.notes!,
                style: evMono(size: 9, color: kEvMuted),
                textAlign: TextAlign.center,
              ),
            ),
          if (match.aggA != null && match.aggB != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              color: kEvDark.withOpacity(0.05),
              child: Center(
                child: Text(
                  'Global: ${match.aggA} – ${match.aggB}',
                  style: evMono(size: 8, weight: FontWeight.w700, color: kEvMuted),
                ),
              ),
            ),
          if (match.hasPenalties)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              color: kEvAccent.withOpacity(0.06),
              child: Center(
                child: Text(
                  'Penales: ${match.penaltiesA ?? '?'} – ${match.penaltiesB ?? '?'}',
                  style: evMono(size: 8, weight: FontWeight.w700, color: kEvAccent),
                ),
              ),
            ),
          if (match.isDecisive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: roundColor.withOpacity(0.12),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 9, color: roundColor),
                    const SizedBox(width: 4),
                    Text(
                      'PARTIDO DECISIVO',
                      style: evMono(
                          size: 8, weight: FontWeight.w800, color: roundColor, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}