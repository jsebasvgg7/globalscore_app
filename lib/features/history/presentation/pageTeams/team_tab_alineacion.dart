import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_teams_shared.dart';

class TeamTabAlineacion extends StatefulWidget {
  final TeamDetail detail;

  const TeamTabAlineacion({super.key, required this.detail});

  @override
  State<TeamTabAlineacion> createState() => _TeamTabAlineacionState();
}

class _TeamTabAlineacionState extends State<TeamTabAlineacion> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final lineup = widget.detail.lineup;
    final team = widget.detail.team;
    final primaryColor = parseHexColor(team.primaryColor);

    if (lineup.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_outlined, size: 40, color: kTeamBorderL),
            const SizedBox(height: 12),
            Text(
              'Sin alineación registrada',
              style: teamMono(size: 14, color: kTeamMuted),
            ),
          ],
        ),
      );
    }

    // Separar titulares (shirt_number <= 11 o role contains 'Starter') del resto
    final starters = lineup
        .where((p) => (p.shirtNumber ?? 99) <= 11)
        .toList()
      ..sort((a, b) => (a.shirtNumber ?? 99).compareTo(b.shirtNumber ?? 99));
    final bench = lineup
        .where((p) => (p.shirtNumber ?? 99) > 11)
        .toList()
      ..sort((a, b) => (a.shirtNumber ?? 99).compareTo(b.shirtNumber ?? 99));

    final selected = _selectedIndex != null ? lineup[_selectedIndex!] : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cancha táctica ────────────────────────────────────
          _TacticalPitch(
            starters: starters,
            teamColor: primaryColor,
            selectedPlayer: selected,
            onPlayerTap: (player) {
              final idx = lineup.indexOf(player);
              setState(() {
                _selectedIndex = _selectedIndex == idx ? null : idx;
              });
            },
          ),

          // ── Info del jugador seleccionado ─────────────────────
          if (selected != null)
            _PlayerDetailCard(player: selected, teamColor: primaryColor),

          // ── Lista completa ────────────────────────────────────
          const TeamSectionLabel(label: 'PLANTILLA COMPLETA', icon: Icons.group_outlined),
          _PlayerList(
            starters: starters,
            bench: bench,
            teamColor: primaryColor,
            selectedPlayer: selected,
            onTap: (player) {
              final idx = lineup.indexOf(player);
              setState(() {
                _selectedIndex = _selectedIndex == idx ? null : idx;
              });
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  CANCHA TÁCTICA — CustomPainter
// ══════════════════════════════════════════════════════════════

class _TacticalPitch extends StatelessWidget {
  final List<TeamLineup> starters;
  final Color teamColor;
  final TeamLineup? selectedPlayer;
  final void Function(TeamLineup) onPlayerTap;

  const _TacticalPitch({
    required this.starters,
    required this.teamColor,
    required this.selectedPlayer,
    required this.onPlayerTap,
  });

  /// Retorna posición normalizada [0,1] en la cancha según posición/número
  Offset _positionFor(TeamLineup p, int index, int total) {
    final pos = (p.positionRole ?? '').toLowerCase();
    final num = p.shirtNumber ?? (index + 1);

    // GK — siempre abajo
    if (num == 1 || pos.contains('goal')) {
      return const Offset(0.5, 0.88);
    }
    // Defenders (2-5) — fila baja
    if (pos.contains('defend') || pos.contains('back') || (num >= 2 && num <= 5)) {
      const defs = [0.2, 0.4, 0.6, 0.8];
      final defIndex = (num - 2).clamp(0, 3);
      return Offset(defs[defIndex], 0.68);
    }
    // Midfielders (6-8) — fila media
    if (pos.contains('mid') || pos.contains('pivot') || (num >= 6 && num <= 8)) {
      const mids = [0.25, 0.5, 0.75];
      final midIndex = (num - 6).clamp(0, 2);
      return Offset(mids[midIndex], 0.45);
    }
    // Wingers
    if (pos.contains('wing')) {
      return num <= 9 ? const Offset(0.15, 0.25) : const Offset(0.85, 0.25);
    }
    // Forwards (9-11)
    if (pos.contains('forward') || pos.contains('striker') || pos.contains('attack') || (num >= 9 && num <= 11)) {
      const fwds = [0.25, 0.5, 0.75];
      final fwdIndex = (num - 9).clamp(0, 2);
      return Offset(fwds[fwdIndex], 0.22);
    }
    // Fallback distribuido
    return Offset((index % 3 + 1) * 0.25, 0.3 + (index ~/ 3) * 0.2);
  }

  @override
  Widget build(BuildContext context) {
    const pitchH = 340.0;

    return Container(
      margin: const EdgeInsets.all(16),
      height: pitchH,
      decoration: BoxDecoration(
        border: Border.all(color: kTeamBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: kTeamDark.withOpacity(0.45),
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                // Cancha dibujada
                CustomPaint(
                  size: Size(w, h),
                  painter: _PitchPainter(teamColor: teamColor),
                ),

                // Jugadores
                ...starters.asMap().entries.map((e) {
                  final pos = _positionFor(e.value, e.key, starters.length);
                  final x = pos.dx * w;
                  final y = pos.dy * h;
                  final isSelected = selectedPlayer == e.value;

                  return Positioned(
                    left: x - 22,
                    top: y - 22,
                    child: GestureDetector(
                      onTap: () => onPlayerTap(e.value),
                      child: _PitchPlayer(
                        player: e.value,
                        teamColor: teamColor,
                        isSelected: isSelected,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Dibuja el césped y las líneas del campo de fútbol
class _PitchPainter extends CustomPainter {
  final Color teamColor;

  const _PitchPainter({required this.teamColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Fondo — césped en franjas alternadas ──────────────────
    final stripePaint = Paint();
    const stripes = 8;
    final stripeW = w / stripes;
    for (int i = 0; i < stripes; i++) {
      stripePaint.color = i.isEven
          ? const Color(0xFF1A6B35)
          : const Color(0xFF1D7A3E);
      canvas.drawRect(Rect.fromLTWH(i * stripeW, 0, stripeW, h), stripePaint);
    }

    // ── Líneas del campo ──────────────────────────────────────
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Borde exterior
    canvas.drawRect(
      Rect.fromLTWH(4, 4, w - 8, h - 8),
      linePaint,
    );

    // Línea central
    canvas.drawLine(Offset(4, h / 2), Offset(w - 4, h / 2), linePaint);

    // Círculo central
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.12, linePaint);
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      2.5,
      Paint()..color = Colors.white.withOpacity(0.7),
    );

    // Área grande atacante (arriba)
    final boxW = w * 0.52;
    final boxH = h * 0.14;
    canvas.drawRect(
      Rect.fromLTWH((w - boxW) / 2, 4, boxW, boxH),
      linePaint,
    );

    // Área chica atacante (arriba)
    final smallW = w * 0.26;
    final smallH = h * 0.07;
    canvas.drawRect(
      Rect.fromLTWH((w - smallW) / 2, 4, smallW, smallH),
      linePaint,
    );

    // Área grande defensiva (abajo)
    canvas.drawRect(
      Rect.fromLTWH((w - boxW) / 2, h - 4 - boxH, boxW, boxH),
      linePaint,
    );

    // Área chica defensiva (abajo)
    canvas.drawRect(
      Rect.fromLTWH((w - smallW) / 2, h - 4 - smallH, smallW, smallH),
      linePaint,
    );

    // Penales (puntos)
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.7);
    canvas.drawCircle(Offset(w / 2, h * 0.22), 2.5, dotPaint);
    canvas.drawCircle(Offset(w / 2, h * 0.78), 2.5, dotPaint);

    // Semicírculo área arriba
    final arcRect = Rect.fromCenter(
      center: Offset(w / 2, h * 0.14),
      width: h * 0.2,
      height: h * 0.2,
    );
    canvas.drawArc(arcRect, math.pi, math.pi, false, linePaint);

    // Semicírculo área abajo
    final arcRectB = Rect.fromCenter(
      center: Offset(w / 2, h * 0.86),
      width: h * 0.2,
      height: h * 0.2,
    );
    canvas.drawArc(arcRectB, 0, math.pi, false, linePaint);

    // Porterías (línea gruesa)
    final goalPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final goalW = w * 0.15;
    canvas.drawLine(
      Offset((w - goalW) / 2, 4),
      Offset((w + goalW) / 2, 4),
      goalPaint,
    );
    canvas.drawLine(
      Offset((w - goalW) / 2, h - 4),
      Offset((w + goalW) / 2, h - 4),
      goalPaint,
    );
  }

  @override
  bool shouldRepaint(_PitchPainter old) => old.teamColor != teamColor;
}

/// Token de jugador en la cancha
class _PitchPlayer extends StatelessWidget {
  final TeamLineup player;
  final Color teamColor;
  final bool isSelected;

  const _PitchPlayer({
    required this.player,
    required this.teamColor,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final num = player.shirtNumber;
    final isGK = num == 1 ||
        (player.positionRole ?? '').toLowerCase().contains('goal');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 44,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Círculo del jugador
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGK
                  ? const Color(0xFFF59E0B)
                  : (isSelected ? Colors.white : teamColor),
              border: Border.all(
                color: isSelected ? kTeamDark : Colors.white.withOpacity(0.8),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: kTeamDark.withOpacity(0.6),
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                num != null ? '$num' : '?',
                style: teamMono(
                  size: 12,
                  weight: FontWeight.w900,
                  color: isSelected
                      ? teamColor
                      : (isGK ? kTeamDark : Colors.white),
                ),
              ),
            ),
          ),
          // Nombre corto
          const SizedBox(height: 2),
          Container(
            constraints: const BoxConstraints(maxWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            color: kTeamDark.withOpacity(0.72),
            child: Text(
              _shortName(player.playerName),
              style: teamMono(
                size: 7,
                color: Colors.white,
                weight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _shortName(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) return name.substring(0, name.length.clamp(0, 8));
    return parts.last.substring(0, parts.last.length.clamp(0, 9));
  }
}

// ══════════════════════════════════════════════════════════════
//  CARD DETALLE JUGADOR SELECCIONADO
// ══════════════════════════════════════════════════════════════

class _PlayerDetailCard extends StatelessWidget {
  final TeamLineup player;
  final Color teamColor;

  const _PlayerDetailCard({required this.player, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    final pos = positionAbbr[player.positionRole] ?? player.positionRole ?? '—';
    final isGK = (player.shirtNumber ?? 99) == 1 ||
        (player.positionRole ?? '').toLowerCase().contains('goal');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: teamNeoBox(
        bg: kTeamDark,
        shadowX: 3,
        shadowY: 3,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Número grande
          Container(
            width: 56,
            height: 56,
            color: isGK ? kTeamGold : teamColor,
            child: Center(
              child: Text(
                player.shirtNumber != null ? '${player.shirtNumber}' : '?',
                style: teamMono(
                  size: 26,
                  weight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.playerName,
                  style: teamMono(
                    size: 15,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    _InfoTag(label: pos, color: teamColor),
                    if (player.teamSide != null)
                      _InfoTag(label: player.teamSide!, color: kTeamMuted),
                    if (isGK) _InfoTag(label: 'PORTERO', color: kTeamGold),
                  ],
                ),
                if (player.notes != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    player.notes!,
                    style: teamMono(size: 10, color: Colors.white54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      color: color.withOpacity(0.2),
      child: Text(
        label.toUpperCase(),
        style: teamMono(size: 8, weight: FontWeight.w800, color: color),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LISTA DE JUGADORES
// ══════════════════════════════════════════════════════════════

class _PlayerList extends StatelessWidget {
  final List<TeamLineup> starters;
  final List<TeamLineup> bench;
  final Color teamColor;
  final TeamLineup? selectedPlayer;
  final void Function(TeamLineup) onTap;

  const _PlayerList({
    required this.starters,
    required this.bench,
    required this.teamColor,
    required this.selectedPlayer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Titulares
        if (starters.isNotEmpty) ...[
          _ListSubheader(label: 'TITULARES', count: starters.length),
          ...starters.map((p) => _PlayerRow(
                player: p,
                teamColor: teamColor,
                isSelected: selectedPlayer == p,
                onTap: () => onTap(p),
              )),
        ],
        // Suplentes/reservas
        if (bench.isNotEmpty) ...[
          _ListSubheader(label: 'SUPLENTES', count: bench.length),
          ...bench.map((p) => _PlayerRow(
                player: p,
                teamColor: teamColor,
                isSelected: selectedPlayer == p,
                onTap: () => onTap(p),
              )),
        ],
      ],
    );
  }
}

class _ListSubheader extends StatelessWidget {
  final String label;
  final int count;

  const _ListSubheader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kTeamBorderL, width: 0.5)),
        color: kTeamCard,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: teamMono(
              size: 9,
              weight: FontWeight.w700,
              letterSpacing: 1.2,
              color: kTeamMuted,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            color: kTeamAccent,
            child: Text(
              '$count',
              style: teamMono(size: 8, color: Colors.white, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final TeamLineup player;
  final Color teamColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlayerRow({
    required this.player,
    required this.teamColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pos = positionAbbr[player.positionRole] ?? player.positionRole ?? '—';
    final isGK = (player.shirtNumber ?? 99) == 1 ||
        (player.positionRole ?? '').toLowerCase().contains('goal');
    final rowColor = isGK ? kTeamGold : teamColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? kTeamDark : kTeamBg,
          border: Border(
            bottom: BorderSide(color: kTeamBorderL, width: 0.5),
            left: isSelected
                ? BorderSide(color: teamColor, width: 3)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Número de camiseta
            Container(
              width: 32,
              height: 32,
              color: isSelected ? rowColor : rowColor.withOpacity(0.12),
              child: Center(
                child: Text(
                  player.shirtNumber != null ? '${player.shirtNumber}' : '?',
                  style: teamMono(
                    size: 13,
                    weight: FontWeight.w900,
                    color: isSelected ? Colors.white : rowColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nombre
            Expanded(
              child: Text(
                player.playerName,
                style: teamMono(
                  size: 13,
                  weight: FontWeight.w700,
                  color: isSelected ? Colors.white : kTeamDark,
                ),
              ),
            ),

            // Posición
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              color: isSelected
                  ? teamColor.withOpacity(0.3)
                  : kTeamBorderL.withOpacity(0.5),
              child: Text(
                pos.toUpperCase(),
                style: teamMono(
                  size: 8,
                  weight: FontWeight.w800,
                  color: isSelected ? teamColor : kTeamMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
