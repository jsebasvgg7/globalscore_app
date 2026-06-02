import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';

// ─── Paleta (misma que players) ──────────────────────────────
const kEvBg      = Color(0xFFF0EDE8);
const kEvDark    = Color(0xFF1A1A2E);
const kEvAccent  = Color(0xFF5B4FD8);
const kEvGold    = Color(0xFFF59E0B);
const kEvGreen   = Color(0xFF1D9E75);
const kEvMuted   = Color(0xFF88887D);
const kEvBorder  = Color(0xFF1A1A2E);
const kEvBorderL = Color(0xFFC4BFB8);
const kEvCard    = Color(0xFFEBE7E1);
const kEvPurple  = Color(0xFF8B5CF6);
const kEvBlue    = Color(0xFF3B82F6);
const kEvRed     = Color(0xFFEF4444);

// ─── Mapas ───────────────────────────────────────────────────
const kCatColor = {
  'player': kEvPurple,
  'team':   kEvBlue,
};

const kCatLabel = {
  'player': 'Jugador',
  'team':   'Equipo',
};

const kEventTypeColor = {
  'Championship':            kEvGold,
  'Historic Match':          kEvBlue,
  'Legendary Performance':   kEvPurple,
  'Era Defining':            kEvRed,
  'Record':                  kEvGreen,
};

const kEventTypeLabel = {
  'Championship':            'Campeonato',
  'Historic Match':          'Partido Histórico',
  'Legendary Performance':   'Actuación Legendaria',
  'Era Defining':            'Definió una Era',
  'Record':                  'Récord',
};

// ─── Tipografía ──────────────────────────────────────────────
TextStyle evMono({
  Color color = kEvDark,
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

// ─── Decoraciones ────────────────────────────────────────────
BoxDecoration evNeoBox({
  Color bg = kEvBg,
  Color border = kEvBorder,
  double shadowX = 3,
  double shadowY = 3,
  Color? shadowColor,
}) =>
    BoxDecoration(
      color: bg,
      border: Border.all(color: border, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: shadowColor ?? kEvDark.withOpacity(0.55),
          offset: Offset(shadowX, shadowY),
          blurRadius: 0,
        ),
      ],
    );

// ─── Color helpers ───────────────────────────────────────────
Color catColor(String? cat) => kCatColor[cat] ?? kEvAccent;
Color typeColor(String? type) => kEventTypeColor[type] ?? kEvMuted;

// ─── Dot grid decorativo ─────────────────────────────────────
class EvDotGrid extends StatelessWidget {
  final int cols;
  final int rows;
  const EvDotGrid({super.key, required this.cols, required this.rows});

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
    final paint = Paint()..color = kEvBorder.withOpacity(0.18);
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

// ─── Badge de categoría ──────────────────────────────────────
class EvCatBadge extends StatelessWidget {
  final String category;
  const EvCatBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final color = catColor(category);
    final label = (kCatLabel[category] ?? category).toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      color: color,
      child: Text(label,
          style: evMono(
              color: Colors.white, size: 7, weight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }
}

// ─── Badge de tipo de evento ─────────────────────────────────
class EvTypeBadge extends StatelessWidget {
  final String type;
  const EvTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = typeColor(type);
    final label = kEventTypeLabel[type] ?? type;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      color: color.withOpacity(0.15),
      child: Text(label,
          style: evMono(size: 7, color: color, weight: FontWeight.w700)),
    );
  }
}

// ─── Score block ─────────────────────────────────────────────
class EvScoreBlock extends StatelessWidget {
  final HistoricalEvent event;
  const EvScoreBlock({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: kEvDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              event.teamAName ?? '?',
              textAlign: TextAlign.end,
              style: evMono(color: Colors.white, size: 13, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${event.scoreA} – ${event.scoreB}',
            style: evMono(color: Colors.white, size: 22, weight: FontWeight.w900),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              event.teamBName ?? '?',
              style: evMono(color: Colors.white, size: 13, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Protagonista mini (imagen o iniciales + nombre) ─────────
class EvProtagonistMini extends StatelessWidget {
  final HistoricalEvent event;
  const EvProtagonistMini({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final isPlayer = event.eventCategory == 'player';
    final name     = isPlayer ? event.player?.name : event.team?.name;
    final imgPath  = isPlayer ? event.player?.imagePath : event.team?.imagePath;
    final color    = catColor(event.eventCategory);
    if (name == null) return const SizedBox.shrink();

    final imgUrl = getHistoricalImageUrl(imgPath);
    final initials = name.split(' ').take(2).map((w) => w[0]).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.35), width: 1),
            ),
            clipBehavior: Clip.hardEdge,
            child: imgUrl != null
                ? Image.network(imgUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                          child: Text(initials,
                              style: evMono(size: 12, weight: FontWeight.w900, color: color)),
                        ))
                : Center(
                    child: Text(initials,
                        style: evMono(size: 12, weight: FontWeight.w900, color: color))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: evMono(size: 11, weight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
                if (!isPlayer && event.team?.country != null)
                  Text(event.team!.country!,
                      style: evMono(size: 9, color: kEvMuted)),
                if (isPlayer && event.player?.country != null)
                  Text(event.player!.country!,
                      style: evMono(size: 9, color: kEvMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header de tab (mismo estilo que players) ─────────────────
class EvTabHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EvTabHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: kEvCard,
        border: Border(bottom: BorderSide(color: kEvBorder, width: 1.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: evNeoBox(bg: kEvDark, shadowX: 3, shadowY: 3),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: evMono(size: 16, weight: FontWeight.w900, letterSpacing: -0.3)),
                Text(subtitle, style: evMono(size: 10, color: kEvMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────
class EvSectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const EvSectionLabel({super.key, required this.label, this.color = kEvAccent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: color,
              border: Border.all(color: kEvBorder, width: 1),
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: evMono(
                  size: 9, weight: FontWeight.w800,
                  letterSpacing: 1.2, color: color)),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────
class EvEmpty extends StatelessWidget {
  final String message;
  const EvEmpty({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(message, style: evMono(color: kEvMuted, size: 13)),
      ),
    );
  }
}
