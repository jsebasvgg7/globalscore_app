import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/ranking_service.dart';

// ── Paleta Neobrutalismo ───────────────────────────────────────────────────────
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFEAE7E1);
const _border  = Color(0xFF1A1A2E);
const _accent  = Color(0xFF5B4FD8);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF6B6580);
const _gold    = Color(0xFFC9A227);
const _green   = Color(0xFF1D9E75);

const _shadowColor = Color(0x661A1A2E);
const _shadowSm = BoxShadow(color: _shadowColor, offset: Offset(1, 1), blurRadius: 0);

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

class RankingStatsRow extends StatelessWidget {
  final String rankingType;
  final List<RankingUser> users;
  final List<HofChampion> champions;

  const RankingStatsRow({
    super.key,
    required this.rankingType,
    required this.users,
    required this.champions,
  });

  @override
  Widget build(BuildContext context) {
    if (rankingType == 'halloffame') {
      return _HofStats(champions: champions);
    }
    return _RankStats(users: users, rankingType: rankingType);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RANKING STATS
// ─────────────────────────────────────────────────────────────────────────────
class _RankStats extends StatelessWidget {
  final List<RankingUser> users;
  final String rankingType;

  const _RankStats({required this.users, required this.rankingType});

  @override
  Widget build(BuildContext context) {
    final sorted = [...users]
      ..sort((a, b) =>
          b.rankPoints(rankingType).compareTo(a.rankPoints(rankingType)));
    final participated =
        users.where((u) => u.rankPredictions(rankingType) > 0).length;
    final leader = sorted.isNotEmpty ? sorted.first : null;

    return Container(
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                value: '${users.length}',
                label: 'REGISTRADOS',
                accentColor: _accent,
              ),
            ),
            Container(width: 1, color: _border),
            Expanded(
              child: _StatCell(
                value: '$participated',
                label: 'PARTICIPANTES',
                accentColor: _green,
              ),
            ),
            if (leader != null) ...[
              Container(width: 1, color: _border),
              Expanded(
                child: _LeaderCell(leader: leader, rankingType: rankingType),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HALL OF FAME STATS
// ─────────────────────────────────────────────────────────────────────────────
class _HofStats extends StatelessWidget {
  final List<HofChampion> champions;
  const _HofStats({required this.champions});

  @override
  Widget build(BuildContext context) {
    final totalCrowns =
        champions.fold<int>(0, (s, c) => s + c.monthlyChampionships);
    final leader = champions.isNotEmpty ? champions.first : null;

    return Container(
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                value: '${champions.length}',
                label: 'CAMPEONES',
                accentColor: _gold,
              ),
            ),
            Container(width: 1, color: _border),
            Expanded(
              child: _StatCell(
                value: '$totalCrowns',
                label: 'CORONAS',
                icon: Icons.workspace_premium_rounded,
                accentColor: _gold,
              ),
            ),
            if (leader != null) ...[
              Container(width: 1, color: _border),
              Expanded(
                child: _HofLeaderCell(leader: leader),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CELL — con barra de color en el top (como HeroBlock del dashboard)
// ─────────────────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color accentColor;
  final IconData? icon;

  const _StatCell({
    required this.value,
    required this.label,
    required this.accentColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de color en el top
        Container(height: 3, color: accentColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: _mono(
                      size: 36,
                      weight: FontWeight.w800,
                      letterSpacing: -1.5,
                      color: accentColor,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Icon(icon, size: 14, color: accentColor),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(width: 8, height: 2, color: accentColor),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      style: _mono(
                        size: 7,
                        weight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: _muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEADER CELL — neobrutalista con pill sólida
// ─────────────────────────────────────────────────────────────────────────────
class _LeaderCell extends StatelessWidget {
  final RankingUser leader;
  final String rankingType;

  const _LeaderCell({required this.leader, required this.rankingType});

  @override
  Widget build(BuildContext context) {
    final pts = leader.rankPoints(rankingType);
    return Column(
      children: [
        // Barra dorada top
        Container(height: 3, color: _gold),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pill "LÍDER"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: _gold,
                  boxShadow: [_shadowSm],
                ),
                child: Text(
                  'LÍDER',
                  style: _mono(color: Colors.white, size: 7, weight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                leader.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _mono(size: 13, weight: FontWeight.w800, color: _gold),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '$pts',
                    style: _mono(size: 18, weight: FontWeight.w900, color: _text),
                  ),
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'pts',
                      style: _mono(size: 9, weight: FontWeight.w600, color: _muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOF LEADER CELL
// ─────────────────────────────────────────────────────────────────────────────
class _HofLeaderCell extends StatelessWidget {
  final HofChampion leader;
  const _HofLeaderCell({required this.leader});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 3, color: _gold),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: _gold,
                  boxShadow: [_shadowSm],
                ),
                child: Text(
                  'DOMINADOR',
                  style: _mono(color: Colors.white, size: 7, weight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                leader.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _mono(size: 13, weight: FontWeight.w800, color: _gold),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 16, color: _gold),
                  const SizedBox(width: 4),
                  Text(
                    '${leader.monthlyChampionships}',
                    style: _mono(size: 18, weight: FontWeight.w900, color: _text),
                  ),
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'coronas',
                      style: _mono(size: 9, weight: FontWeight.w600, color: _muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}