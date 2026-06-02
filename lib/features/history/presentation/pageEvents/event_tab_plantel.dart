import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_events_shared.dart';

class EventTabPlantel extends StatelessWidget {
  final EventDetail detail;
  const EventTabPlantel({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final category = detail.event.eventCategory;

    // Eventos 'team' → usa squad (historical_event_squad)
    // Eventos 'player' → usa solo lineupA (equipo protagonista = team_a)
    if (category == 'team') {
      return _SquadPlantel(detail: detail);
    } else {
      return _LineupPlantel(detail: detail);
    }
  }
}

// ── Para eventos 'player': muestra lineupA (equipo del protagonista) ──
class _LineupPlantel extends StatelessWidget {
  final EventDetail detail;
  const _LineupPlantel({required this.detail});

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
    // Solo el equipo protagonista (team_a)
    final players = detail.lineupA;

    if (players.isEmpty) {
      return const Center(child: EvEmpty(message: 'Sin plantel registrado'));
    }

    final keyPlayers = players.where((p) => p.isProtagonist).toList();
    final rest = players.where((p) => !p.isProtagonist).toList();

    final teamName = detail.event.teamAName ??
        players.firstOrNull?.teamName ??
        'Equipo';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EvTabHeader(
            icon: Icons.people_outline,
            title: 'PLANTEL',
            subtitle: teamName,
          ),

          if (keyPlayers.isNotEmpty) ...[
            EvSectionLabel(label: 'JUGADORES CLAVE', color: kEvGold),
            ...keyPlayers.map((p) => _PlayerRow(
                  playerName: p.playerName,
                  shirtNumber: p.shirtNumber,
                  positionRole: p.positionRole,
                  teamName: p.teamName,
                  highlight: true,
                  posLabel: _posLabel,
                )),
          ],

          if (rest.isNotEmpty) ...[
            EvSectionLabel(
              label: keyPlayers.isNotEmpty ? 'RESTO DEL EQUIPO' : 'EQUIPO',
              color: kEvAccent,
            ),
            ...rest.map((p) => _PlayerRow(
                  playerName: p.playerName,
                  shirtNumber: p.shirtNumber,
                  positionRole: p.positionRole,
                  teamName: p.teamName,
                  highlight: false,
                  posLabel: _posLabel,
                )),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Para eventos 'team': muestra squad (historical_event_squad) ──
class _SquadPlantel extends StatelessWidget {
  final EventDetail detail;
  const _SquadPlantel({required this.detail});

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
    final squad = detail.squad;

    if (squad.isEmpty) {
      return const Center(child: EvEmpty(message: 'Sin plantel registrado'));
    }

    final keyPlayers = squad.where((p) => p.isKeyPlayer).toList();
    final rest = squad.where((p) => !p.isKeyPlayer).toList();

    final teamName = detail.event.team?.name ??
        detail.event.teamAName ??
        'Equipo protagonista';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EvTabHeader(
            icon: Icons.people_outline,
            title: 'PLANTEL',
            subtitle: teamName,
          ),

          if (keyPlayers.isNotEmpty) ...[
            EvSectionLabel(label: 'JUGADORES CLAVE', color: kEvGold),
            ...keyPlayers.map((p) => _PlayerRow(
                  playerName: p.playerName,
                  shirtNumber: p.shirtNumber,
                  positionRole: p.positionRole,
                  teamName: teamName,
                  highlight: true,
                  posLabel: _posLabel,
                )),
          ],

          if (rest.isNotEmpty) ...[
            EvSectionLabel(
              label: keyPlayers.isNotEmpty ? 'RESTO DEL PLANTEL' : 'PLANTEL',
              color: kEvAccent,
            ),
            ...rest.map((p) => _PlayerRow(
                  playerName: p.playerName,
                  shirtNumber: p.shirtNumber,
                  positionRole: p.positionRole,
                  teamName: teamName,
                  highlight: false,
                  posLabel: _posLabel,
                )),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Row unificado (acepta campos sueltos para reusar en ambos casos) ──
class _PlayerRow extends StatelessWidget {
  final String playerName;
  final int? shirtNumber;
  final String? positionRole;
  final String teamName;
  final bool highlight;
  final Map<String, String> posLabel;

  const _PlayerRow({
    required this.playerName,
    required this.shirtNumber,
    required this.positionRole,
    required this.teamName,
    required this.highlight,
    required this.posLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pos = posLabel[positionRole] ?? positionRole;
    final safeName = playerName.trim().isEmpty ? '—' : playerName;

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
          if (shirtNumber != null) ...[
            Container(
              width: 22,
              height: 22,
              color: highlight ? kEvGold : kEvDark.withOpacity(0.08),
              child: Center(
                child: Text(
                  '$shirtNumber',
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
          // Equipo mini-badge (solo si el nombre no es muy largo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            color: highlight
                ? kEvGold.withOpacity(0.2)
                : kEvBorderL.withOpacity(0.4),
            child: Text(
              teamName.length > 10
                  ? '${teamName.substring(0, 9)}…'
                  : teamName,
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
              safeName,
              style: evMono(
                size: 12,
                weight: highlight ? FontWeight.w800 : FontWeight.normal,
                color: kEvDark,
              ),
            ),
          ),
          if (pos != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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