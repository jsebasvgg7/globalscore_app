import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_competitions_shared.dart';

class CompTabGrupos extends StatelessWidget {
  final CompetitionDetail detail;
  const CompTabGrupos({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<CompetitionGroup>> byGroup = {};
    for (final row in detail.groups) {
      byGroup.putIfAbsent(row.groupName, () => []).add(row);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          ...byGroup.entries
              .map((e) => _GroupTable(name: e.key, rows: e.value)),
          const SizedBox(height: 10),
          // Legend
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kHistBorderL),
            ),
            child: Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                    'Clasificado · PJ=Partidos · DG=Diferencia de goles',
                    style: monoStyle(size: 9, color: kHistMuted)),
              ),
            ]),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _GroupTable extends StatelessWidget {
  final String name;
  final List<CompetitionGroup> rows;
  const _GroupTable({required this.name, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border.all(color: kHistBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: kHistDark, offset: Offset(3, 3), blurRadius: 0)
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: kHistAccent,
            child: Text('GRUPO $name',
                style: monoStyle(
                    color: Colors.white,
                    size: 10,
                    weight: FontWeight.w900,
                    letterSpacing: 1.4)),
          ),
          // Col headers
          Container(
            color: const Color(0xFFE8E4DE),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(children: [
              const SizedBox(width: 22),
              Expanded(
                  child: Text('EQUIPO',
                      style: monoStyle(
                          size: 8,
                          color: kHistMuted,
                          weight: FontWeight.w700))),
              for (final h in [
                'PJ', 'G', 'E', 'P', 'GF', 'GC', 'DG', 'PTS'
              ])
                SizedBox(
                    width: 26,
                    child: Text(h,
                        textAlign: TextAlign.center,
                        style: monoStyle(
                            size: 8,
                            color: kHistMuted,
                            weight: FontWeight.w700))),
            ]),
          ),
          // Rows
          ...rows.asMap().entries.map((e) {
            final i   = e.key;
            final row = e.value;
            final adv = i < 2;
            return Container(
              decoration: BoxDecoration(
                color: adv
                    ? const Color(0xFF10B981).withOpacity(0.05)
                    : Colors.white,
                border: const Border(
                    top: BorderSide(color: kHistBorderL, width: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 7),
              child: Row(children: [
                SizedBox(
                  width: 22,
                  child: adv
                      ? Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle))
                      : Text('${row.position ?? i + 1}',
                          textAlign: TextAlign.center,
                          style: monoStyle(
                              size: 10, color: kHistMuted)),
                ),
                Expanded(
                  child: Text(row.teamName,
                      style: monoStyle(
                          size: 11,
                          weight: adv
                              ? FontWeight.w700
                              : FontWeight.normal),
                      overflow: TextOverflow.ellipsis),
                ),
                for (final v in [
                  row.played, row.wins, row.draws, row.losses,
                  row.goalsFor, row.goalsAgainst,
                  row.goalDiff, row.points,
                ])
                  SizedBox(
                    width: 26,
                    child: Text('$v',
                        textAlign: TextAlign.center,
                        style: monoStyle(
                            size: 11,
                            weight: v == row.points
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: v == row.points && adv
                                ? kHistAccent
                                : kHistDark)),
                  ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
