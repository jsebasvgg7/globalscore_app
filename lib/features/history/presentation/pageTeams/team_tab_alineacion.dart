import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_teams_shared.dart';

const _kFormationDefaults = <String, List<_DefaultPos>>{
  '4-3-3': [
    _DefaultPos(1,  'GK',  50, 88),
    _DefaultPos(2,  'RB',  20, 70),
    _DefaultPos(6,  'CB',  40, 70),
    _DefaultPos(4,  'CB',  60, 70),
    _DefaultPos(3,  'LB',  80, 70),
    _DefaultPos(5,  'CDM', 50, 52),
    _DefaultPos(10, 'CM',  30, 52),
    _DefaultPos(8,  'CM',  70, 52),
    _DefaultPos(9,  'ST',  50, 20),
    _DefaultPos(7,  'LW',  20, 20),
    _DefaultPos(11, 'RW',  80, 20),
  ],
  '4-4-2': [
    _DefaultPos(1,  'GK',  50, 88),
    _DefaultPos(2,  'RB',  20, 70),
    _DefaultPos(3,  'CB',  38, 70),
    _DefaultPos(4,  'CB',  62, 70),
    _DefaultPos(5,  'LB',  80, 70),
    _DefaultPos(6,  'RM',  20, 46),
    _DefaultPos(7,  'CM',  38, 46),
    _DefaultPos(8,  'CM',  62, 46),
    _DefaultPos(9,  'LM',  80, 46),
    _DefaultPos(10, 'ST',  38, 18),
    _DefaultPos(11, 'ST',  62, 18),
  ],
  '3-5-2': [
    _DefaultPos(1,  'GK',  50, 88),
    _DefaultPos(2,  'CB',  25, 70),
    _DefaultPos(3,  'CB',  50, 70),
    _DefaultPos(4,  'CB',  75, 70),
    _DefaultPos(5,  'RM',  15, 50),
    _DefaultPos(6,  'CM',  35, 50),
    _DefaultPos(7,  'CDM', 50, 50),
    _DefaultPos(8,  'CM',  65, 50),
    _DefaultPos(9,  'LM',  85, 50),
    _DefaultPos(10, 'ST',  35, 18),
    _DefaultPos(11, 'ST',  65, 18),
  ],
  '4-2-3-1': [
    _DefaultPos(1,  'GK',  50, 88),
    _DefaultPos(2,  'RB',  20, 70),
    _DefaultPos(3,  'CB',  40, 70),
    _DefaultPos(4,  'CB',  60, 70),
    _DefaultPos(5,  'LB',  80, 70),
    _DefaultPos(6,  'CDM', 38, 56),
    _DefaultPos(7,  'CDM', 62, 56),
    _DefaultPos(8,  'RW',  20, 36),
    _DefaultPos(9,  'CAM', 50, 36),
    _DefaultPos(10, 'LW',  80, 36),
    _DefaultPos(11, 'ST',  50, 16),
  ],
  // Formaciones adicionales (fallback genérico si no hay posDB)
  '5-3-2': [
    _DefaultPos(1,  'GK',  50, 88),
    _DefaultPos(2,  'CB',  15, 70),
    _DefaultPos(3,  'CB',  32, 70),
    _DefaultPos(4,  'CB',  50, 70),
    _DefaultPos(5,  'CB',  68, 70),
    _DefaultPos(6,  'CB',  85, 70),
    _DefaultPos(7,  'CM',  28, 48),
    _DefaultPos(8,  'CM',  50, 48),
    _DefaultPos(9,  'CM',  72, 48),
    _DefaultPos(10, 'ST',  35, 18),
    _DefaultPos(11, 'ST',  65, 18),
  ],
  '3-4-3': [
    _DefaultPos(1,  'GK',  50, 88),
    _DefaultPos(2,  'CB',  25, 70),
    _DefaultPos(3,  'CB',  50, 70),
    _DefaultPos(4,  'CB',  75, 70),
    _DefaultPos(5,  'RM',  15, 48),
    _DefaultPos(6,  'CM',  38, 48),
    _DefaultPos(7,  'CM',  62, 48),
    _DefaultPos(8,  'LM',  85, 48),
    _DefaultPos(9,  'LW',  20, 20),
    _DefaultPos(10, 'ST',  50, 20),
    _DefaultPos(11, 'RW',  80, 20),
  ],
};

class _DefaultPos {
  final int shirtNumber;
  final String role;
  final double posX;
  final double posY;
  const _DefaultPos(this.shirtNumber, this.role, this.posX, this.posY);
}

// ─── Etiquetas de posición (igual que React) ──────────────────────────────────
const _kPosLabel = <String, String>{
  'GK': 'Portero',
  'CB': 'Defensa Central',
  'LB': 'Lateral Izq.',
  'RB': 'Lateral Der.',
  'CDM': 'Med. Def.',
  'CM': 'Centrocampista',
  'CAM': 'Med. Ofensivo',
  'LM': 'Mediapunta Izq.',
  'RM': 'Mediapunta Der.',
  'LW': 'Extremo Izq.',
  'RW': 'Extremo Der.',
  'ST': 'Delantero Centro',
  'SS': 'Segundo Delantero',
};

// ─── Dimensiones del SVG del campo (idénticas al React) ──────────────────────
//  viewBox="0 0 300 420"
//  Área jugable: x 12..288 (276px), y 12..408 (396px)
//  pos_x 0-100 → x = 12 + (pos_x/100)*276
//  pos_y 0-100 → y = 12 + (pos_y/100)*396
//  Luego normalizar: nx = x/300, ny = y/420
const double _svgW = 300;
const double _svgH = 420;
const double _playX = 12;    // margen inicio x
const double _playY = 12;    // margen inicio y
const double _playW = 276;   // 300 - 12 - 12
const double _playH = 396;   // 420 - 12 - 12

/// Convierte pos_x, pos_y (0-100) al offset normalizado [0,1] del canvas,
/// usando el MISMO cálculo que el componente React RetroField.
Offset _posToOffset(double posX, double posY) {
  final cx = _playX + (posX / 100) * _playW;
  final cy = _playY + (posY / 100) * _playH;
  return Offset(cx / _svgW, cy / _svgH);
}

// ══════════════════════════════════════════════════════════════
//  TAB ALINEACIÓN
// ══════════════════════════════════════════════════════════════

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
            Text('Sin alineación registrada', style: teamMono(size: 14, color: kTeamMuted)),
          ],
        ),
      );
    }

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
          _AlineacionHeader(
            team: widget.detail.team,
            teamColor: primaryColor,
            starterCount: starters.length,
          ),
          _TacticalPitch(
            starters: starters,
            formation: team.formation,
            teamColor: primaryColor,
            selectedPlayer: selected,
            onPlayerTap: (player) {
              final idx = lineup.indexOf(player);
              setState(() {
                _selectedIndex = _selectedIndex == idx ? null : idx;
              });
            },
          ),
          if (selected != null)
            _PlayerDetailCard(player: selected, teamColor: primaryColor),
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
//  CANCHA TÁCTICA
// ══════════════════════════════════════════════════════════════

class _TacticalPitch extends StatelessWidget {
  final List<TeamLineup> starters;
  final String? formation;
  final Color teamColor;
  final TeamLineup? selectedPlayer;
  final void Function(TeamLineup) onPlayerTap;

  const _TacticalPitch({
    required this.starters,
    required this.formation,
    required this.teamColor,
    required this.selectedPlayer,
    required this.onPlayerTap,
  });

Offset _offsetFor(TeamLineup p, int index) {
  if (p.posX != null && p.posY != null) {
    return _posToOffset(p.posX!, p.posY!);
  }

  final defaults = _kFormationDefaults[formation ?? '4-3-3'];
  if (defaults != null && index < defaults.length) {
    return _posToOffset(defaults[index].posX, defaults[index].posY);
  }

  // ── 3. Fallback genérico ─────────────────────────────────────────────────
  final col = index % 3;
  final row = index ~/ 3;
  return _posToOffset(20.0 + col * 30.0, 20.0 + row * 20.0);
}

  @override
  Widget build(BuildContext context) {
    // El campo usa un viewBox 300:420 — ratio 5:7
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: kTeamBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: kTeamDark.withValues(alpha: 0.45),
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: _svgW / _svgH, // 300/420 ≈ 0.714
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                // Campo dibujado
                CustomPaint(
                  size: Size(w, h),
                  painter: _PitchPainter(teamColor: teamColor),
                ),

                // Jugadores posicionados
                ...starters.asMap().entries.map((e) {
                  final norm = _offsetFor(e.value, e.key);
                  // El token mide 44×52; centramos el ancla en el centro
                  const tokenW = 44.0;
                  const tokenH = 52.0;
                  final left = norm.dx * w - tokenW / 2;
                  final top  = norm.dy * h - tokenH / 2;

                  return Positioned(
                    left: left.clamp(0, w - tokenW),
                    top:  top.clamp(0, h - tokenH),
                    child: GestureDetector(
                      onTap: () => onPlayerTap(e.value),
                      child: _PitchPlayer(
                        player: e.value,
                        teamColor: teamColor,
                        isSelected: selectedPlayer == e.value,
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

// ──────────────────────────────────────────────────────────────
//  Painter del campo (versión mejorada, proporción SVG 300×420)
// ──────────────────────────────────────────────────────────────
class _PitchPainter extends CustomPainter {
  final Color teamColor;
  const _PitchPainter({required this.teamColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Escala relativa al viewBox 300×420
    final sx = w / _svgW;
    final sy = h / _svgH;

    // ── Franjas de césped ──────────────────────────────────────
    final paint = Paint();
    const stripeH = 30.0;
    int stripeCount = (_svgH / stripeH).ceil();
    for (int i = 0; i < stripeCount; i++) {
      paint.color = i.isEven ? const Color(0xFF2d7a2d) : const Color(0xFF267226);
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeH * sy, w, stripeH * sy),
        paint,
      );
    }

    // ── Líneas del campo ──────────────────────────────────────
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    void rect(double x, double y, double rw, double rh) =>
        canvas.drawRect(Rect.fromLTWH(x * sx, y * sy, rw * sx, rh * sy), line);

    void circle(double cx, double cy, double r) =>
        canvas.drawCircle(Offset(cx * sx, cy * sy), r * math.min(sx, sy), line);

    void dot(double cx, double cy, double r) {
      canvas.drawCircle(
        Offset(cx * sx, cy * sy),
        r * math.min(sx, sy),
        Paint()..color = Colors.white.withValues(alpha: 0.80),
      );
    }

    // Borde exterior
    rect(12, 12, 276, 396);
    // Línea central
    canvas.drawLine(Offset(12 * sx, 210 * sy), Offset(288 * sx, 210 * sy), line);
    // Círculo central
    circle(150, 210, 42);
    dot(150, 210, 2.5);

    // Área grande arriba (y=12..70)
    rect(72, 12, 156, 58);
    // Área pequeña arriba
    rect(108, 12, 84, 26);
    dot(150, 56, 2);
    // Arco área arriba
    canvas.drawArc(
      Rect.fromCenter(center: Offset(150 * sx, 70 * sy), width: 88 * sx, height: 88 * sy),
      math.pi, math.pi, false, line..color = Colors.white.withValues(alpha: 0.65),
    );
    line.color = Colors.white.withValues(alpha: 0.70);

    // Área grande abajo (y=350..408)
    rect(72, 350, 156, 58);
    // Área pequeña abajo
    rect(108, 382, 84, 26);
    dot(150, 364, 2);
    // Arco área abajo
    canvas.drawArc(
      Rect.fromCenter(center: Offset(150 * sx, 350 * sy), width: 88 * sx, height: 88 * sy),
      0, math.pi, false, line..color = Colors.white.withValues(alpha: 0.65),
    );
    line.color = Colors.white.withValues(alpha: 0.70);

    // Porterías
    final goal = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    rect(120, 6, 60, 10);
    canvas.drawRect(Rect.fromLTWH(120 * sx, 404 * sy, 60 * sx, 10 * sy), goal);

    // Banderines (círculos esquinas)
    final flag = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final corner in [
      Offset(12 * sx, 12 * sy),
      Offset(288 * sx, 12 * sy),
      Offset(12 * sx, 408 * sy),
      Offset(288 * sx, 408 * sy),
    ]) {
      canvas.drawCircle(corner, 3 * math.min(sx, sy), flag);
    }
  }

  @override
  bool shouldRepaint(_PitchPainter old) => old.teamColor != teamColor;
}

// ──────────────────────────────────────────────────────────────
//  Token de jugador en el campo
// ──────────────────────────────────────────────────────────────
class _PitchPlayer extends StatelessWidget {
  final TeamLineup player;
  final Color teamColor;
  final bool isSelected;

  const _PitchPlayer({
    required this.player,
    required this.teamColor,
    required this.isSelected,
  });

  bool get _isGK =>
      player.shirtNumber == 1 ||
      (player.positionRole ?? '').toUpperCase() == 'GK';

  @override
  Widget build(BuildContext context) {
    final num = player.shirtNumber;
    final circleColor = _isGK
        ? const Color(0xFFF59E0B)
        : (isSelected ? Colors.white : teamColor);
    final textColor = _isGK
        ? kTeamDark
        : (isSelected ? teamColor : Colors.white);

    return SizedBox(
      width: 44,
      height: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              border: Border.all(
                color: isSelected ? kTeamDark : Colors.white.withValues(alpha: 0.8),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: kTeamDark.withValues(alpha: 0.6), offset: const Offset(2, 2), blurRadius: 0)]
                  : null,
            ),
            child: Center(
              child: Text(
                num != null ? '$num' : '?',
                style: teamMono(size: 12, weight: FontWeight.w900, color: textColor),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            constraints: const BoxConstraints(maxWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            color: kTeamDark.withValues(alpha: 0.72),
            child: Text(
              _shortName(player.playerName),
              style: teamMono(size: 7, color: Colors.white, weight: FontWeight.w700),
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
    final parts = name.trim().split(' ');
    if (parts.length == 1) return name.substring(0, name.length.clamp(0, 9));
    // Apellido (última palabra)
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
    final role = player.positionRole ?? '';
    final posLabel = _kPosLabel[role] ?? (role.isNotEmpty ? role : '—');
    final isGK = player.shirtNumber == 1 ||
        role.toUpperCase() == 'GK';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: teamNeoBox(bg: kTeamDark, shadowX: 3, shadowY: 3),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            color: isGK ? kTeamGold : teamColor,
            child: Center(
              child: Text(
                player.shirtNumber != null ? '${player.shirtNumber}' : '?',
                style: teamMono(size: 26, weight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.playerName,
                    style: teamMono(size: 15, weight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    _InfoTag(label: posLabel, color: teamColor),
                    if (isGK) _InfoTag(label: 'PORTERO', color: kTeamGold),
                  ],
                ),
                if (player.notes != null) ...[
                  const SizedBox(height: 6),
                  Text(player.notes!,
                      style: teamMono(size: 10, color: Colors.white54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
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
      color: color.withValues(alpha: 0.2),
      child: Text(label.toUpperCase(),
          style: teamMono(size: 8, weight: FontWeight.w800, color: color)),
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
        if (starters.isNotEmpty) ...[
          _ListSubheader(label: 'TITULARES', count: starters.length),
          ...starters.map((p) => _PlayerRow(
                player: p,
                teamColor: teamColor,
                isSelected: selectedPlayer == p,
                onTap: () => onTap(p),
              )),
        ],
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
          Text(label,
              style: teamMono(size: 9, weight: FontWeight.w700, letterSpacing: 1.2, color: kTeamMuted)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            color: kTeamAccent,
            child: Text('$count',
                style: teamMono(size: 8, color: Colors.white, weight: FontWeight.w800)),
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
    final role = player.positionRole ?? '';
    final posLabel = _kPosLabel[role] ?? role;
    final isGK = player.shirtNumber == 1 || role.toUpperCase() == 'GK';
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
            Container(
              width: 32,
              height: 32,
              color: isSelected ? rowColor : rowColor.withValues(alpha: 0.12),
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
            Expanded(
              child: Text(player.playerName,
                  style: teamMono(
                    size: 13,
                    weight: FontWeight.w700,
                    color: isSelected ? Colors.white : kTeamDark,
                  )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              color: isSelected
                  ? teamColor.withValues(alpha: 0.3)
                  : kTeamBorderL.withValues(alpha: 0.5),
              child: Text(
                posLabel.toUpperCase(),
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

// ══════════════════════════════════════════════════════════════
//  HEADER ALINEACIÓN
// ══════════════════════════════════════════════════════════════

class _AlineacionHeader extends StatelessWidget {
  final dynamic team;
  final Color teamColor;
  final int starterCount;

  const _AlineacionHeader({
    required this.team,
    required this.teamColor,
    required this.starterCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kTeamDark,
        border: Border(bottom: BorderSide(color: kTeamBorder, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            color: teamColor,
            child: const Icon(Icons.sports_soccer, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ALINEACIÓN',
                    style: teamMono(size: 16, weight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3)),
                const SizedBox(height: 3),
                Text('Toca un jugador para ver su detalle',
                    style: teamMono(size: 9, color: kTeamMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: teamColor.withValues(alpha: 0.5)),
              color: teamColor.withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group_outlined, size: 10, color: teamColor),
                const SizedBox(width: 5),
                Text('$starterCount',
                    style: teamMono(size: 13, weight: FontWeight.w900, color: teamColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}