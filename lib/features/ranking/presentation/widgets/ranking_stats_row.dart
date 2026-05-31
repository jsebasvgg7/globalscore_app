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
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.08), width: 0.5),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatBlock(
              value: '${users.length}',
              label: 'REGISTRADOS',
            ),
            VerticalDivider(
                width: 0.5, color: Colors.black.withOpacity(0.08)),
            _StatBlock(
              value: '$participated',
              label: 'PARTICIPANTES',
            ),
            if (leader != null) ...[
              VerticalDivider(
                  width: 0.5, color: Colors.black.withOpacity(0.08)),
              _LeaderBlock(leader: leader, rankingType: rankingType),
            ],
          ],
        ),
      ),
    );
  }
}

class _HofStats extends StatelessWidget {
  final List<HofChampion> champions;
  const _HofStats({required this.champions});

  @override
  Widget build(BuildContext context) {
    final totalCrowns =
        champions.fold<int>(0, (s, c) => s + c.monthlyChampionships);
    final leader = champions.isNotEmpty ? champions.first : null;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.08), width: 0.5),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatBlock(value: '${champions.length}', label: 'CAMPEONES'),
            VerticalDivider(
                width: 0.5, color: Colors.black.withOpacity(0.08)),
            _StatBlock(value: '$totalCrowns', label: 'CORONAS'),
            if (leader != null) ...[
              VerticalDivider(
                  width: 0.5, color: Colors.black.withOpacity(0.08)),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        leader.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kGold,
                          fontFamily: 'DMMono',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${leader.monthlyChampionships} 👑',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kGold,
                              fontFamily: 'DMMono',
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'DOMINADOR',
                        style: TextStyle(
                          fontSize: 9,
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

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;

  const _StatBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 36,
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
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFFB0AAA0),
                fontFamily: 'DMMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderBlock extends StatelessWidget {
  final RankingUser leader;
  final String rankingType;

  const _LeaderBlock({required this.leader, required this.rankingType});

  @override
  Widget build(BuildContext context) {
    final pts = leader.rankPoints(rankingType);
    return Expanded(
      flex: 2,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              leader.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kGold,
                fontFamily: 'DMMono',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$pts pts',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kGold,
                fontFamily: 'DMMono',
              ),
            ),
            const Text(
              'LÍDER',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFFB0AAA0),
                fontFamily: 'DMMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}