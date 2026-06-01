import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/history_models.dart';

const _kAccent = Color(0xFF5B4FD8);
const _kBg = Color(0xFFF0EDE8);
const _kDark = Color(0xFF1A1A2E);
const _kMuted = Color(0xFF88887D);
const _kBorder = Color(0xFFC4BFB8);
const _kGold = Color(0xFFF59E0B);

TextStyle _mono({
  Color color = _kDark,
  double size = 12,
  FontWeight weight = FontWeight.normal,
}) =>
    GoogleFonts.dmMono(
      color: color,
      fontSize: size,
      fontWeight: weight,
      decoration: TextDecoration.none,
    );

const _roundOrder = [
  'Octavos',
  'Cuartos',
  'Semifinal',
  'Tercero',
  'Final',
];

// ══════════════════════════════════════════════════════════════
//  KNOCKOUT BRACKET — horizontal scroll, stacked match cards
// ══════════════════════════════════════════════════════════════

class KnockoutBracketWidget extends StatelessWidget {
  final List<KnockoutMatch> matches;
  const KnockoutBracketWidget({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text('Sin partidos registrados', style: _mono(color: _kMuted))),
      );
    }

    // Group by round preserving order
    final Map<String, List<KnockoutMatch>> byRound = {};
    for (final m in matches) {
      byRound.putIfAbsent(m.round, () => []).add(m);
    }

    // Sort rounds
    final rounds = _roundOrder.where(byRound.containsKey).toList();
    // Add any unknown rounds
    for (final r in byRound.keys) {
      if (!rounds.contains(r)) rounds.add(r);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rounds.asMap().entries.map((e) {
          final round = e.value;
          final isFinal = round == 'Final';
          final roundMatches = byRound[round]!
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Round label
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  color: isFinal ? _kGold : _kDark,
                  child: Text(
                    round.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: _mono(color: Colors.white, size: 9, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                ...roundMatches.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MatchCard(match: m, isFinal: isFinal),
                    )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final KnockoutMatch match;
  final bool isFinal;
  const _MatchCard({required this.match, this.isFinal = false});

  @override
  Widget build(BuildContext context) {
    final winColor = isFinal ? _kGold : _kAccent;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isFinal ? _kGold : _kBorder),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Team A
          _TeamRow(
            name: match.teamA,
            score: match.scoreA,
            isWinner: match.winnerIsA,
            winColor: winColor,
          ),
          Container(height: 0.5, color: _kBorder),
          // Team B
          _TeamRow(
            name: match.teamB,
            score: match.scoreB,
            isWinner: match.winnerIsB,
            winColor: winColor,
          ),
          // Penalties
          if (match.hasPenalties)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              color: const Color(0xFFE8E4DE),
              child: Text(
                'Penales: ${match.penaltiesA ?? '?'} – ${match.penaltiesB ?? '?'}',
                style: _mono(size: 8, color: _kMuted),
              ),
            ),
          // Notes
          if (match.notes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(
                match.notes!,
                style: _mono(size: 8, color: _kMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String name;
  final int? score;
  final bool isWinner;
  final Color winColor;

  const _TeamRow({
    required this.name,
    this.score,
    required this.isWinner,
    required this.winColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: isWinner ? winColor.withOpacity(0.06) : Colors.transparent,
        border: isWinner
            ? Border(left: BorderSide(color: winColor, width: 2))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: _mono(
                size: 11,
                weight: isWinner ? FontWeight.w700 : FontWeight.normal,
                color: isWinner ? _kDark : _kMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            score != null ? '$score' : '–',
            style: _mono(
              size: 13,
              weight: FontWeight.w800,
              color: isWinner ? winColor : _kMuted,
            ),
          ),
        ],
      ),
    );
  }
}
