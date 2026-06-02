import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_competitions_shared.dart';

class CompTabStandings extends StatelessWidget {
  final CompetitionDetail detail;
  const CompTabStandings({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final standings = detail.standings;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: kHistBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: kHistDark,
                    offset: Offset(3, 3),
                    blurRadius: 0)
              ],
            ),
            child: Column(
              children: [
                // Col headers
                Container(
                  color: const Color(0xFFE8E4DE),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  child: Row(children: [
                    SizedBox(
                        width: 28,
                        child: Text('#',
                            textAlign: TextAlign.center,
                            style: monoStyle(
                                size: 8,
                                color: kHistMuted,
                                weight: FontWeight.w700))),
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
                ...standings.map((row) => Container(
                      decoration: BoxDecoration(
                        color: row.isChampion
                            ? kHistGold.withOpacity(0.07)
                            : Colors.white,
                        border: const Border(
                            top: BorderSide(
                                color: kHistBorderL, width: 0.5)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(children: [
                        SizedBox(
                          width: 28,
                          child: row.isChampion
                              ? const Icon(Icons.star,
                                  size: 12, color: kHistGold)
                              : Text('${row.position}',
                                  textAlign: TextAlign.center,
                                  style: monoStyle(size: 10)),
                        ),
                        Expanded(
                          child: Row(children: [
                            Flexible(
                              child: Text(row.teamName,
                                  style: monoStyle(
                                      size: 11,
                                      weight: row.isChampion
                                          ? FontWeight.w700
                                          : FontWeight.normal),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (row.isChampion) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                color: kHistGold,
                                child: Text('CAM',
                                    style: monoStyle(
                                        color: Colors.black,
                                        size: 7,
                                        weight: FontWeight.w900,
                                        letterSpacing: 0.5)),
                              ),
                            ],
                          ]),
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
                                    weight: v == row.points &&
                                            row.isChampion
                                        ? FontWeight.w700
                                        : FontWeight.normal)),
                          ),
                      ]),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
