import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';

// ─── Paleta neobrutalista (igual que players) ─────────────────
const kTeamBg      = Color(0xFFF0EDE8);
const kTeamDark    = Color(0xFF1A1A2E);
const kTeamAccent  = Color(0xFF5B4FD8);
const kTeamGold    = Color(0xFFF59E0B);
const kTeamGreen   = Color(0xFF1D9E75);
const kTeamRed     = Color(0xFFE53E3E);
const kTeamMuted   = Color(0xFF88887D);
const kTeamBorder  = Color(0xFF1A1A2E);
const kTeamBorderL = Color(0xFFC4BFB8);
const kTeamCard    = Color(0xFFEBE7E1);

// ─── Decoraciones ────────────────────────────────────────────
BoxDecoration teamNeoBox({
  Color bg = kTeamBg,
  Color border = kTeamBorder,
  double shadowX = 3,
  double shadowY = 3,
  Color? shadowColor,
}) =>
    BoxDecoration(
      color: bg,
      border: Border.all(color: border, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: shadowColor ?? kTeamDark.withOpacity(0.55),
          offset: Offset(shadowX, shadowY),
          blurRadius: 0,
        ),
      ],
    );

// ─── Tipografía ───────────────────────────────────────────────
TextStyle teamMono({
  Color color = kTeamDark,
  double size = 12,
  FontWeight weight = FontWeight.normal,
  double letterSpacing = 0,
}) =>
    GoogleFonts.dmMono(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      decoration: TextDecoration.none,
    );

// ─── Labels ───────────────────────────────────────────────────
const legacyTypeLabel = {
  'Club':        'Club',
  'National':    'Selección',
  'Mixed':       'Mixto',
};

const legacyLabel = {
  'Dominant':    'Dominante',
  'Iconic':      'Icónico',
  'Historic':    'Histórico',
  'Legendary':   'Legendario',
  'Revolutionary': 'Revolucionario',
};

// ─── Posiciones de campo ──────────────────────────────────────
const positionAbbr = {
  'Goalkeeper':  'POR',
  'Defender':    'DEF',
  'Midfielder':  'MED',
  'Forward':     'DEL',
  'Winger':      'EXT',
  'Striker':     'DEL',
  'Sweeper':     'LIB',
};

// ─── Parsear color hex ───────────────────────────────────────
Color parseHexColor(String? hex, {Color fallback = kTeamAccent}) {
  if (hex == null) return fallback;
  try {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {
    return fallback;
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════

/// Logo del equipo con fallback al escudo icon
class TeamLogo extends StatelessWidget {
  final String? imagePath;
  final String teamName;
  final double size;
  final Color? teamColor;

  const TeamLogo({
    super.key,
    required this.imagePath,
    required this.teamName,
    required this.size,
    this.teamColor,
  });

  @override
  Widget build(BuildContext context) {
    final url = getHistoricalImageUrl(imagePath);
    final color = teamColor ?? kTeamAccent;
    if (url != null) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(color),
        loadingBuilder: (_, child, p) =>
            p == null ? child : _fallback(color),
      );
    }
    return _fallback(color);
  }

  Widget _fallback(Color color) => Icon(
        Icons.shield_outlined,
        size: size * 0.65,
        color: color.withOpacity(0.6),
      );
}

/// Dot grid decorativo
class TeamDotGrid extends StatelessWidget {
  final int cols;
  final int rows;
  const TeamDotGrid({super.key, required this.cols, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cols * 14.0,
      height: rows * 14.0,
      child: CustomPaint(painter: _DotPainter(cols: cols, rows: rows)),
    );
  }
}

class _DotPainter extends CustomPainter {
  final int cols;
  final int rows;
  _DotPainter({required this.cols, required this.rows});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = kTeamBorder.withOpacity(0.18);
    const step = 14.0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(Offset(c * step + 7, r * step + 7), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Chip de metadato reutilizable
class TeamMetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const TeamMetaChip({
    super.key,
    required this.label,
    required this.icon,
    this.color = kTeamMuted,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault = color == kTeamMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDefault ? kTeamBorderL : color.withOpacity(0.35),
        ),
        color: isDefault ? Colors.transparent : color.withOpacity(0.07),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 4),
          Text(label, style: teamMono(size: 9, color: isDefault ? kTeamDark : color)),
        ],
      ),
    );
  }
}

/// Etiqueta de sección
class TeamSectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;

  const TeamSectionLabel({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: kTeamAccent),
          const SizedBox(width: 8),
          if (icon != null) ...[
            Icon(icon, size: 11, color: kTeamMuted),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: teamMono(
              size: 10,
              weight: FontWeight.w700,
              letterSpacing: 1.4,
              color: kTeamMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat box: número grande + etiqueta
class TeamStatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const TeamStatBox({
    super.key,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: teamMono(
            size: 22,
            weight: FontWeight.w900,
            color: color ?? kTeamAccent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: teamMono(size: 8, color: kTeamMuted, letterSpacing: 0.8),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
