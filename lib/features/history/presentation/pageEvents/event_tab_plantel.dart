import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_events_shared.dart';

class EventTabPlantel extends StatelessWidget {
  final EventDetail detail;
  const EventTabPlantel({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final category = detail.event.eventCategory;

    if (category == 'team') {
      return _SquadPlantel(detail: detail);
    } else {
      return _LineupPlantel(detail: detail);
    }
  }
}

// ── Eventos 'player': muestra el equipo donde juega el protagonista ──
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
    // Detectar en qué side está el protagonista
    final protagonistInA = detail.lineupA.any((p) => p.isProtagonist);
    final players = protagonistInA ? detail.lineupA : detail.lineupB;

    // Fallback: si ninguno tiene protagonista, usar lineupA
    final resolvedPlayers = players.isNotEmpty
        ? players
        : detail.lineupA.isNotEmpty
            ? detail.lineupA
            : detail.lineupB;

    if (resolvedPlayers.isEmpty) {
      return const Center(child: EvEmpty(message: 'Sin plantel registrado'));
    }

    final teamName = protagonistInA
        ? (detail.event.teamAName ?? resolvedPlayers.firstOrNull?.teamName ?? 'Equipo')
        : (detail.event.teamBName ?? resolvedPlayers.firstOrNull?.teamName ?? 'Equipo');

    final protagonist = resolvedPlayers.where((p) => p.isProtagonist).toList();
    final rest = resolvedPlayers.where((p) => !p.isProtagonist).toList();

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

          if (protagonist.isNotEmpty) ...[
            EvSectionLabel(label: 'PROTAGONISTA', color: kEvAccent),
            ...protagonist.map((p) => _PlayerRow(
                  playerName: p.playerName,
                  shirtNumber: p.shirtNumber,
                  positionRole: p.positionRole,
                  teamName: teamName,
                  highlight: true,
                  highlightColor: kEvAccent,
                  posLabel: _posLabel,
                )),
          ],

          if (rest.isNotEmpty) ...[
            EvSectionLabel(label: 'EQUIPO', color: kEvMuted),
            ...rest.map((p) => _PlayerRow(
                  playerName: p.playerName,
                  shirtNumber: p.shirtNumber,
                  positionRole: p.positionRole,
                  teamName: teamName,
                  highlight: false,
                  highlightColor: kEvAccent,
                  posLabel: _posLabel,
                )),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Eventos 'team': muestra el squad del equipo protagonista ──
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
                  highlightColor: kEvGold,
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
                  highlightColor: kEvGold,
                  posLabel: _posLabel,
                )),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Row compartido ────────────────────────────────────────────
class _PlayerRow extends StatelessWidget {
  final String playerName;
  final int? shirtNumber;
  final String? positionRole;
  final String teamName;
  final bool highlight;
  final Color highlightColor;
  final Map<String, String> posLabel;

  const _PlayerRow({
    required this.playerName,
    required this.shirtNumber,
    required this.positionRole,
    required this.teamName,
    required this.highlight,
    required this.highlightColor,
    required this.posLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pos = posLabel[positionRole] ?? positionRole;
    final safeName = playerName.trim().isEmpty ? '—' : playerName;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: highlight ? highlightColor.withOpacity(0.06) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: kEvBorderL, width: 0.5),
          left: highlight
              ? BorderSide(color: highlightColor, width: 3)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (highlight) ...[
            Icon(Icons.star, size: 10, color: highlightColor),
            const SizedBox(width: 6),
          ],
          if (shirtNumber != null) ...[
            Container(
              width: 22,
              height: 22,
              color: highlight ? highlightColor : kEvDark.withOpacity(0.08),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            color: highlight
                ? highlightColor.withOpacity(0.2)
                : kEvBorderL.withOpacity(0.4),
            child: Text(
              teamName.length > 10 ? '${teamName.substring(0, 9)}…' : teamName,
              style: evMono(
                size: 7,
                weight: FontWeight.w700,
                color: highlight ? highlightColor : kEvMuted,
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
                  ? highlightColor.withOpacity(0.15)
                  : kEvBorderL.withOpacity(0.5),
              child: Text(
                pos,
                style: evMono(
                  size: 7,
                  weight: FontWeight.w800,
                  color: highlight ? highlightColor : kEvMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}