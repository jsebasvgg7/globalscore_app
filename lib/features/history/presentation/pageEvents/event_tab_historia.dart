import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_events_shared.dart';

class EventTabHistoria extends StatelessWidget {
  final EventDetail detail;
  const EventTabHistoria({super.key, required this.detail});

  static const _koOrder = [
    'Octavos', 'Cuartos', 'Semifinal', 'Tercero', 'Final'
  ];

  @override
  Widget build(BuildContext context) {
    final knockout = detail.knockout;

    if (knockout.isEmpty) {
      return const Center(child: EvEmpty(message: 'Sin datos de historia registrados'));
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
            icon: Icons.history_edu_outlined,
            title: 'HISTORIA',
            subtitle: 'Partidos decisivos del evento',
          ),
          EvSectionLabel(label: 'PARTIDOS DECISIVOS', color: kEvAccent),
          ...rounds.map((r) => _KoRoundBlock(
                round: r,
                matches: byRound[r]!,
              )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _KoRoundBlock extends StatelessWidget {
  final String round;
  final List<KnockoutMatch> matches;

  const _KoRoundBlock({required this.round, required this.matches});

  Color _roundColor() {
    switch (round) {
      case 'Final':     return kEvGold;
      case 'Semifinal': return kEvPurple;
      case 'Tercero':   return kEvBlue;
      default:          return kEvMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rColor = _roundColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: rColor,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (round == 'Final')
                const Icon(Icons.emoji_events, size: 11, color: Colors.white),
              if (round == 'Final') const SizedBox(width: 5),
              Text(
                round.toUpperCase(),
                style: evMono(
                  size: 9,
                  weight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          decoration: BoxDecoration(
            border: Border.all(color: kEvBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: kEvDark.withValues(alpha: 0.35),
                offset: const Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: matches.asMap().entries.map((e) {
              final isLast = e.key == matches.length - 1;
              return _KoMatchRow(
                match: e.value,
                roundColor: rColor,
                showBorder: !isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _KoMatchRow extends StatelessWidget {
  final KnockoutMatch match;
  final Color roundColor;
  final bool showBorder;

  const _KoMatchRow({
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
        // ── usa isDecisive (camelCase Dart) ──────────────────
        color: match.isDecisive
            ? roundColor.withValues(alpha: 0.06)
            : kEvBg,
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
                // Equipo A
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

                // Marcador central
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: kEvDark,
                  child: Text(
                    match.scoreA != null && match.scoreB != null
                        ? '${match.scoreA} – ${match.scoreB}'
                        : '– – –',
                    style: evMono(
                      size: 14,
                      weight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Equipo B
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

          // Chip "Decisivo"
          if (match.isDecisive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: roundColor.withValues(alpha: 0.12),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 9, color: roundColor),
                    const SizedBox(width: 4),
                    Text(
                      'PARTIDO DECISIVO',
                      style: evMono(
                        size: 8,
                        weight: FontWeight.w800,
                        color: roundColor,
                        letterSpacing: 0.8,
                      ),
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