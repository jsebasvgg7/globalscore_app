import 'package:flutter/material.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';
import 'history_events_shared.dart';

class EventTabPlantel extends StatelessWidget {
  final EventDetail detail;
  const EventTabPlantel({super.key, required this.detail});

  static const _posLabel = {
    'GK': 'POR',
    'CB': 'DEF', 'LB': 'DEF', 'RB': 'DEF',
    'CDM': 'MED', 'CM': 'MED', 'CAM': 'MED',
    'LM': 'MED', 'RM': 'MED',
    'LW': 'EXT', 'RW': 'EXT',
    'ST': 'DEL', 'SS': 'DEL',
  };

  @override
  Widget build(BuildContext context) {
    final lineupA = detail.lineupA;
    final lineupB = detail.lineupB;
    final allPlayers = [...lineupA, ...lineupB];

    if (allPlayers.isEmpty) {
      return const Center(child: EvEmpty(message: 'Sin plantel registrado'));
    }

    final keyPlayers = allPlayers.where((p) => p.isProtagonist).toList();
    final rest = allPlayers.where((p) => !p.isProtagonist).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EvTabHeader(
            icon: Icons.people_outline,
            title: 'PLANTEL',
            subtitle: 'Jugadores estelares del evento',
          ),

          if (keyPlayers.isNotEmpty) ...[
            EvSectionLabel(label: 'JUGADORES CLAVE', color: kEvGold),
            ...keyPlayers
                .map((p) => _PlayerRow(player: p, highlight: true)),
          ],

          if (rest.isNotEmpty) ...[
            EvSectionLabel(
              label:
                  keyPlayers.isNotEmpty ? 'RESTO DEL PLANTEL' : 'PLANTEL',
              color: kEvAccent,
            ),
            ...rest.map((p) => _PlayerRow(player: p, highlight: false)),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final EventLineup player;
  final bool highlight;

  const _PlayerRow({required this.player, required this.highlight});

  static const _posLabel = {
    'GK': 'POR',
    'CB': 'DEF', 'LB': 'DEF', 'RB': 'DEF',
    'CDM': 'MED', 'CM': 'MED', 'CAM': 'MED',
    'LM': 'MED', 'RM': 'MED',
    'LW': 'EXT', 'RW': 'EXT',
    'ST': 'DEL', 'SS': 'DEL',
  };

  @override
  Widget build(BuildContext context) {
    final pos = _posLabel[player.positionRole] ?? player.positionRole;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: highlight ? kEvGold.withOpacity(0.06) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: kEvBorderL, width: 0.5),
          left: highlight
              ? const BorderSide(color: kEvGold, width: 3)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (highlight) ...[
            const Icon(Icons.star, size: 10, color: kEvGold),
            const SizedBox(width: 6),
          ],
          if (player.shirtNumber != null) ...[
            Container(
              width: 22,
              height: 22,
              color: highlight ? kEvGold : kEvDark.withOpacity(0.08),
              child: Center(
                child: Text(
                  '${player.shirtNumber}',
                  style: evMono(
                    size: 9,
                    weight: FontWeight.w900,
                    color: highlight ? Colors.white : kEvMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Equipo mini-badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            color: highlight
                ? kEvGold.withOpacity(0.2)
                : kEvBorderL.withOpacity(0.4),
            child: Text(
              player.teamName.length > 10
                  ? '${player.teamName.substring(0, 9)}…'
                  : player.teamName,
              style: evMono(
                size: 7,
                weight: FontWeight.w700,
                color: highlight ? kEvGold : kEvMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.playerName,
              style: evMono(
                size: 12,
                weight: highlight ? FontWeight.w800 : FontWeight.normal,
                color: kEvDark,
              ),
            ),
          ),
          if (pos != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              color: highlight
                  ? kEvGold.withOpacity(0.15)
                  : kEvBorderL.withOpacity(0.5),
              child: Text(
                pos,
                style: evMono(
                  size: 7,
                  weight: FontWeight.w800,
                  color: highlight ? kEvGold : kEvMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}