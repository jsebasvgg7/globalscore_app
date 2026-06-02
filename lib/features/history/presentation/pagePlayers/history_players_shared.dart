import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';

// ─── Paleta neobrutalista ────────────────────────────────────
const kHistBg      = Color(0xFFF0EDE8);
const kHistDark    = Color(0xFF1A1A2E);
const kHistAccent  = Color(0xFF5B4FD8);
const kHistGold    = Color(0xFFF59E0B);
const kHistGreen   = Color(0xFF1D9E75);
const kHistMuted   = Color(0xFF88887D);
const kHistBorder  = Color(0xFF1A1A2E);
const kHistBorderL = Color(0xFFC4BFB8);
const kHistCard    = Color(0xFFEBE7E1);

// ─── Decoraciones ───────────────────────────────────────────
BoxDecoration neoBox({
  Color bg = kHistBg,
  Color border = kHistBorder,
  double shadowX = 3,
  double shadowY = 3,
  Color? shadowColor,
}) =>
    BoxDecoration(
      color: bg,
      border: Border.all(color: border, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: shadowColor ?? kHistDark.withOpacity(0.55),
          offset: Offset(shadowX, shadowY),
          blurRadius: 0,
        ),
      ],
    );

// ─── Tipografía ──────────────────────────────────────────────
TextStyle monoStyle({
  Color color = kHistDark,
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

// ─── Labels ──────────────────────────────────────────────────
const positionLabel = {
  'Forward': 'Delantero',
  'Midfielder': 'Mediocampista',
  'Play-maker': 'Mediocampista',
  'All-rounder': 'Todocampista',
  'Defender': 'Defensor',
  'Goalkeeper': 'Portero',
};

const legacyLabel = {
  'Goal Scorer': 'Goleador',
  'Tactician': 'Táctico',
  'Innovator': 'Genio',
  'Leader': 'Líder',
  'Goalkeeper': 'Portero',
  'Technician': 'Técnico',
};

const sigLabel = ['', 'Activo', 'Notable', 'Icónico', 'Leyenda', 'GOAT'];

// ─── Número decorativo ───────────────────────────────────────
String playerNumber(HistoricalPlayer p) {
  final hash = p.id.hashCode.abs() % 99 + 1;
  return hash.toString();
}

// ══════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ══════════════════════════════════════════════════════════════

/// Iniciales fallback cuando no hay imagen
class CardInitials extends StatelessWidget {
  final String name;
  const CardInitials({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
    return Center(
      child: Text(
        initials,
        style: monoStyle(
          size: 36,
          weight: FontWeight.w900,
          color: kHistAccent.withOpacity(0.3),
        ),
      ),
    );
  }
}

/// Estrellas de significancia
class PlayerStars extends StatelessWidget {
  final int level;
  final double size;
  const PlayerStars({super.key, required this.level, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < level;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: filled ? kHistGold : kHistBorderL,
        );
      }),
    );
  }
}

/// Chip de metadato
class PlayerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const PlayerChip({
    super.key,
    required this.label,
    required this.icon,
    this.color = kHistMuted,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault = color == kHistMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDefault ? kHistBorderL : color.withOpacity(0.3),
        ),
        color: isDefault ? Colors.transparent : color.withOpacity(0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: monoStyle(size: 9, color: isDefault ? kHistDark : color),
          ),
        ],
      ),
    );
  }
}

/// Dot grid decorativo
class DotGrid extends StatelessWidget {
  final int cols;
  final int rows;
  const DotGrid({super.key, required this.cols, required this.rows});

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
    final paint = Paint()..color = kHistBorder.withOpacity(0.18);
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

// ══════════════════════════════════════════════════════════════
//  PLAYER CARD — grid 2x2
// ══════════════════════════════════════════════════════════════

class PlayerCard extends StatelessWidget {
  final HistoricalPlayer player;
  final VoidCallback onTap;
  const PlayerCard({super.key, required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(player.imagePath);
    final sig = player.significanceLevel ?? 0;
    final isGoat = sig == 5;
    final posLabel = positionLabel[player.position] ?? player.position ?? '';
    final trophyCount = sig.clamp(0, 5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: neoBox(shadowX: 4, shadowY: 4),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Foto ────────────────────────────────────────
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: kHistAccent.withOpacity(0.12),
                    child: imgUrl != null
                        ? Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                CardInitials(name: player.name),
                            loadingBuilder: (_, child, p) =>
                                p == null ? child : CardInitials(name: player.name),
                          )
                        : CardInitials(name: player.name),
                  ),
                  if (isGoat)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        color: kHistGold,
                        child: Text(
                          'GOAT',
                          style: monoStyle(
                            size: 8,
                            weight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      color: kHistDark.withOpacity(0.85),
                      child: Text(
                        '#${playerNumber(player)}',
                        style: monoStyle(
                          size: 8,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 24,
                      height: 24,
                      color: kHistDark.withOpacity(0.6),
                      child: const Icon(Icons.more_horiz,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      player.name.toUpperCase(),
                      style: monoStyle(
                        size: 11,
                        weight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Column(
                      children: [
                        if (player.country != null)
                          Text(
                            player.country!.toUpperCase(),
                            style: monoStyle(
                              size: 8,
                              weight: FontWeight.w700,
                              color: kHistAccent,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        if (posLabel.isNotEmpty)
                          Text(
                            posLabel.toUpperCase(),
                            style: monoStyle(
                              size: 8,
                              weight: FontWeight.w600,
                              color: kHistMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                    if (trophyCount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          trophyCount,
                          (_) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1.5),
                            child: Icon(Icons.emoji_events_outlined,
                                size: 11, color: kHistGold),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 11),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
