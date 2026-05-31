import 'package:flutter/material.dart';
import '../../data/ranking_service.dart';

const _kGold = Color(0xFFC9A227);

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
// Stats Global / Mensual
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
        border: Border(
          bottom: BorderSide(color: Color(0x14000000), width: 0.5),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Registrados
            Expanded(
              child: _StatCell(
                value: '${users.length}',
                label: 'REGISTRADOS',
              ),
            ),
            const VerticalDivider(width: 0.5, color: Color(0x14000000)),
            // Participantes
            Expanded(
              child: _StatCell(
                value: '$participated',
                label: 'PARTICIPANTES',
              ),
            ),
            // Líder
            if (leader != null) ...[
              const VerticalDivider(width: 0.5, color: Color(0x14000000)),
              Expanded(
                child: _LeaderCell(
                  leader: leader,
                  rankingType: rankingType,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Hall of Fame
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
        border: Border(
          bottom: BorderSide(color: Color(0x14000000), width: 0.5),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                value: '${champions.length}',
                label: 'CAMPEONES',
              ),
            ),
            const VerticalDivider(width: 0.5, color: Color(0x14000000)),
            Expanded(
              child: _StatCell(
                value: '$totalCrowns',
                label: 'CORONAS',
              ),
            ),
            if (leader != null) ...[
              const VerticalDivider(width: 0.5, color: Color(0x14000000)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        leader.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kGold,
                          fontFamily: 'DMMono',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium_rounded,
                              size: 12, color: _kGold),
                          const SizedBox(width: 3),
                          Text(
                            '${leader.monthlyChampionships}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kGold,
                              fontFamily: 'DMMono',
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'DOMINADOR',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Color(0xFFB0AAA0),
                          fontFamily: 'DMMono',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Celda de estadística — número grande + etiqueta centrados
// ─────────────────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String value;
  final String label;

  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              fontFamily: 'DMMono',
              letterSpacing: -1.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            // Usa FittedBox para que nunca corte el texto
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Color(0xFFB0AAA0),
              fontFamily: 'DMMono',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Celda del líder — centrada
// ─────────────────────────────────────────────────────────────────────────────
class _LeaderCell extends StatelessWidget {
  final RankingUser leader;
  final String rankingType;

  const _LeaderCell({required this.leader, required this.rankingType});

  @override
  Widget build(BuildContext context) {
    final pts = leader.rankPoints(rankingType);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            leader.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kGold,
              fontFamily: 'DMMono',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$pts pts',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kGold,
              fontFamily: 'DMMono',
            ),
          ),
          const Text(
            'LÍDER',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Color(0xFFB0AAA0),
              fontFamily: 'DMMono',
            ),
          ),
        ],
      ),
    );
  }
}