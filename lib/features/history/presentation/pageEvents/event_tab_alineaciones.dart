import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_events_shared.dart';

class EventTabAlineaciones extends StatelessWidget {
  final EventDetail detail;
  const EventTabAlineaciones({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final event = detail.event;
    final teamA = detail.lineupA;
    final teamB = detail.lineupB;
    final teamAName = event.teamAName ?? teamA.firstOrNull?.teamName ?? 'Equipo A';
    final teamBName = event.teamBName ?? teamB.firstOrNull?.teamName ?? 'Equipo B';
    final hasScore = event.scoreA != null && event.scoreB != null;

    if (teamA.isEmpty && teamB.isEmpty) {
      return const Center(
        child: EvEmpty(message: 'Sin alineaciones registradas'),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────
          EvTabHeader(
            icon: Icons.groups_outlined,
            title: 'ALINEACIONES',
            subtitle: 'Jugadores del enfrentamiento',
          ),

          // ── Marcador ─────────────────────────────────────────
          if (hasScore)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: EvScoreBlock(event: event),
            ),

          const SizedBox(height: 16),

          // ── Columnas duelo ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _LineupColumn(players: teamA, teamName: teamAName, right: false)),
                Container(width: 1, color: kEvBorderL),
                Expanded(child: _LineupColumn(players: teamB, teamName: teamBName, right: true)),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _LineupColumn extends StatelessWidget {
  final List<EventLineup> players;
  final String teamName;
  final bool right;

  const _LineupColumn({
    required this.players,
    required this.teamName,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Nombre del equipo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          color: kEvDark,
          child: Text(
            teamName.toUpperCase(),
            style: evMono(
              size: 10,
              weight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: right ? TextAlign.end : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Filas de jugadores
        ...players.map((p) => _LineupRow(player: p, right: right)),
      ],
    );
  }
}

class _LineupRow extends StatelessWidget {
  final EventLineup player;
  final bool right;

  const _LineupRow({required this.player, required this.right});

  static const _posLabel = {
    'GK': 'POR', 'CB': 'DEF', 'LB': 'DEF', 'RB': 'DEF',
    'CDM': 'MED', 'CM': 'MED', 'CAM': 'MED',
    'LM': 'MED', 'RM': 'MED', 'LW': 'EXT', 'RW': 'EXT',
    'ST': 'DEL', 'SS': 'DEL',
  };

  @override
  Widget build(BuildContext context) {
    final isProto = player.isProtagonist;
    final pos = _posLabel[player.positionRole] ?? player.positionRole;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: isProto ? kEvAccent.withOpacity(0.08) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: kEvBorderL, width: 0.5),
          left: (!right && isProto)
              ? const BorderSide(color: kEvAccent, width: 3)
              : BorderSide.none,
          right: (right && isProto)
              ? const BorderSide(color: kEvAccent, width: 3)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        mainAxisAlignment:
            right ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: right
            ? [
                if (pos != null)
                  _PosTag(pos: pos, isProto: isProto),
                const SizedBox(width: 5),
                if (player.shirtNumber != null)
                  _ShirtNum(num: player.shirtNumber!, isProto: isProto),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _lastName(player.playerName),
                    style: evMono(
                      size: 11,
                      weight: isProto ? FontWeight.w800 : FontWeight.normal,
                      color: isProto ? kEvAccent : kEvDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
                if (isProto) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 9, color: kEvAccent),
                ],
              ]
            : [
                if (isProto) ...[
                  const Icon(Icons.star, size: 9, color: kEvAccent),
                  const SizedBox(width: 4),
                ],
                if (player.shirtNumber != null)
                  _ShirtNum(num: player.shirtNumber!, isProto: isProto),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _lastName(player.playerName),
                    style: evMono(
                      size: 11,
                      weight: isProto ? FontWeight.w800 : FontWeight.normal,
                      color: isProto ? kEvAccent : kEvDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 5),
                if (pos != null) _PosTag(pos: pos, isProto: isProto),
              ],
      ),
    );
  }

  String _lastName(String name) {
    final parts = name.trim().split(' ');
    return parts.length > 1 ? parts.last : name;
  }
}

class _ShirtNum extends StatelessWidget {
  final int num;
  final bool isProto;
  const _ShirtNum({required this.num, required this.isProto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20, height: 20,
      color: isProto ? kEvAccent : kEvDark.withOpacity(0.1),
      child: Center(
        child: Text(
          '$num',
          style: evMono(
            size: 9,
            weight: FontWeight.w900,
            color: isProto ? Colors.white : kEvMuted,
          ),
        ),
      ),
    );
  }
}

class _PosTag extends StatelessWidget {
  final String pos;
  final bool isProto;
  const _PosTag({required this.pos, required this.isProto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: isProto
          ? kEvAccent.withOpacity(0.15)
          : kEvBorderL.withOpacity(0.5),
      child: Text(
        pos,
        style: evMono(
          size: 7,
          weight: FontWeight.w800,
          color: isProto ? kEvAccent : kEvMuted,
        ),
      ),
    );
  }
}