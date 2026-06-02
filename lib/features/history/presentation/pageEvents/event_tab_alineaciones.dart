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
          EvTabHeader(
            icon: Icons.groups_outlined,
            title: 'ALINEACIONES',
            subtitle: 'Jugadores del enfrentamiento',
          ),

          if (hasScore)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: EvScoreBlock(event: event),
            ),

          const SizedBox(height: 16),

          // ── Encabezados de equipo ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: kEvDark,
                    child: Text(
                      teamAName.toUpperCase(),
                      style: evMono(
                        size: 10,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(width: 1, color: kEvBorderL),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: kEvDark,
                    child: Text(
                      teamBName.toUpperCase(),
                      style: evMono(
                        size: 10,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Filas de jugadores (espejo) ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MirroredLineup(teamA: teamA, teamB: teamB),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Renderiza ambas listas en paralelo fila a fila (modo espejo).
class _MirroredLineup extends StatelessWidget {
  final List<EventLineup> teamA;
  final List<EventLineup> teamB;

  const _MirroredLineup({required this.teamA, required this.teamB});

  @override
  Widget build(BuildContext context) {
    final maxRows = teamA.length > teamB.length ? teamA.length : teamB.length;

    return Column(
      children: List.generate(maxRows, (i) {
        final a = i < teamA.length ? teamA[i] : null;
        final b = i < teamB.length ? teamB[i] : null;
        final isLast = i == maxRows - 1;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: isLast
                  ? BorderSide.none
                  : BorderSide(color: kEvBorderL, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Equipo A — número a la izquierda, nombre a la derecha
              Expanded(
                child: a != null
                    ? _RowA(player: a)
                    : const SizedBox(height: 38),
              ),
              Container(width: 1, color: kEvBorderL),
              // Equipo B — nombre a la izquierda, número a la derecha (espejo)
              Expanded(
                child: b != null
                    ? _RowB(player: b)
                    : const SizedBox(height: 38),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Fila Equipo A: [★] [num] nombre [pos] ────────────────────
class _RowA extends StatelessWidget {
  final EventLineup player;
  const _RowA({required this.player});

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
        border: isProto
            ? const Border(left: BorderSide(color: kEvAccent, width: 3))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        children: [
          if (isProto) ...[
            const Icon(Icons.star, size: 9, color: kEvAccent),
            const SizedBox(width: 3),
          ],
          if (player.shirtNumber != null) ...[
            _ShirtNum(num: player.shirtNumber!, isProto: isProto),
            const SizedBox(width: 5),
          ],
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
          if (pos != null) ...[
            const SizedBox(width: 4),
            _PosTag(pos: pos, isProto: isProto),
          ],
        ],
      ),
    );
  }
}

// ── Fila Equipo B (espejo): [pos] nombre [num] [★] ───────────
class _RowB extends StatelessWidget {
  final EventLineup player;
  const _RowB({required this.player});

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
        border: isProto
            ? const Border(right: BorderSide(color: kEvAccent, width: 3))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (pos != null) ...[
            _PosTag(pos: pos, isProto: isProto),
            const SizedBox(width: 4),
          ],
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
          if (player.shirtNumber != null) ...[
            const SizedBox(width: 5),
            _ShirtNum(num: player.shirtNumber!, isProto: isProto),
          ],
          if (isProto) ...[
            const SizedBox(width: 3),
            const Icon(Icons.star, size: 9, color: kEvAccent),
          ],
        ],
      ),
    );
  }
}

String _lastName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '—';
  final parts = trimmed.split(' ');
  return parts.length > 1 ? parts.last : trimmed;
}

class _ShirtNum extends StatelessWidget {
  final int num;
  final bool isProto;
  const _ShirtNum({required this.num, required this.isProto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
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