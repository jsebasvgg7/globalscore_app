import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;

// ════════════════════════════════════════════════════════════
//  ALBUM BOOK CARD
//  Tarjeta libro clickeable — usada en legendary, stars, cult
// ════════════════════════════════════════════════════════════

class AlbumBookCard extends StatefulWidget {
  final String albumId;
  final String shortLabel;
  final String number;
  final String tag;
  final Color spine;
  final Color spineAlt;
  final Color accent;
  final Color coverBg;
  final int filled;
  final int total;
  final double pct;
  final bool locked;
  final bool completed;
  final VoidCallback? onTap;
  final Widget? coverIllustration; // SVG o CustomPaint personalizado

  const AlbumBookCard({
    super.key,
    required this.albumId,
    required this.shortLabel,
    required this.number,
    required this.tag,
    required this.spine,
    required this.spineAlt,
    required this.accent,
    required this.coverBg,
    required this.filled,
    required this.total,
    required this.pct,
    this.locked = false,
    this.completed = false,
    this.onTap,
    this.coverIllustration,
  });

  @override
  State<AlbumBookCard> createState() => _AlbumBookCardState();
}

class _AlbumBookCardState extends State<AlbumBookCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.locked) widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed && !widget.locked
            ? (Matrix4.identity()..translate(2.0, 2.0))
            : Matrix4.identity(),
        width: 110,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Libro ────────────────────────────────────
            _BookBody(widget: widget),

            const SizedBox(height: 8),

            // ── Barra de progreso ─────────────────────
            _ProgressBlock(widget: widget),
          ],
        ),
      ),
    );
  }
}

// ── Cuerpo del libro ──────────────────────────────────────
class _BookBody extends StatelessWidget {
  final AlbumBookCard widget;
  const _BookBody({required this.widget});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          // Sombra base
          Positioned(
            left: 6, top: 6,
            child: Container(
              width: 103, height: 144,
              color: GsColors.border.withValues(alpha: 0.3),
            ),
          ),

          // Páginas laterales (efecto profundidad)
          for (int i = 2; i >= 0; i--)
            Positioned(
              right: i * 2.5, top: i * 1.0,
              child: Container(
                width: 12, height: 140,
                color: const Color(0xFFD4CFC8).withValues(alpha: 0.5 - i * 0.12),
              ),
            ),

          // Lomo
          Positioned(
            left: 0, top: 0,
            child: Container(
              width: 14, height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [widget.spine, widget.spineAlt],
                ),
              ),
              alignment: Alignment.center,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  widget.shortLabel,
                  style: const TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Colors.white70,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Portada
          Positioned(
            left: 12, top: 0,
            child: Container(
              width: 98, height: 140,
              decoration: BoxDecoration(
                color: widget.coverBg,
                border: Border.all(color: GsColors.border, width: 1.5),
              ),
              child: Stack(
                children: [
                  // Tag temporada
                  Positioned(
                    top: 7, left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      color: GsColors.border.withValues(alpha: 0.6),
                      child: Text(
                        widget.tag,
                        style: const TextStyle(
                          fontFamily: GsColors.fontMono,
                          fontSize: 5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Número top-right
                  Positioned(
                    top: 7, right: 14,
                    child: Text(
                      widget.number,
                      style: TextStyle(
                        fontFamily: GsColors.fontMono,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: widget.accent.withValues(alpha: 0.6),
                      ),
                    ),
                  ),

                  // Arte de la portada (ilustración personalizada o genérica)
                  Positioned.fill(
                    child: widget.locked
                        ? _LockedArt(accent: widget.accent)
                        : widget.coverIllustration ??
                            _GenericArt(accent: widget.accent),
                  ),

                  // Barra progreso inferior
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 4,
                      color: Colors.black38,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: widget.pct.clamp(0.0, 1.0),
                        child: Container(
                            color: widget.accent.withValues(alpha: 0.8)),
                      ),
                    ),
                  ),

                  // Broche lateral
                  Positioned(
                    right: 0, top: 0, bottom: 0,
                    child: _Clasp(color: widget.accent),
                  ),

                  // Esquinas doradas
                  ..._GoldCorners.all,

                  // Badge ACTIVO o COMPLETADO
                  if (widget.completed || (!widget.locked && !widget.completed))
                    Positioned(
                      top: 24, left: 7,
                      child: _StatusBadge(
                          completed: widget.completed, locked: widget.locked),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Arte genérico (escudo + círculos) ─────────────────────
class _GenericArt extends StatelessWidget {
  final Color accent;
  const _GenericArt({required this.accent});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GenericArtPainter(accent: accent),
    );
  }
}

class _GenericArtPainter extends CustomPainter {
  final Color accent;
  const _GenericArtPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 8;
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final r in [28.0, 20.0, 13.0]) {
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    final shieldFill = Paint()
      ..color = accent.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    final shieldStroke = Paint()
      ..color = accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(cx, cy - 14)
      ..lineTo(cx + 10, cy - 8)
      ..lineTo(cx + 10, cy + 2)
      ..quadraticBezierTo(cx + 10, cy + 12, cx, cy + 18)
      ..quadraticBezierTo(cx - 10, cy + 12, cx - 10, cy + 2)
      ..lineTo(cx - 10, cy - 8)
      ..close();

    canvas.drawPath(path, shieldFill);
    canvas.drawPath(path, shieldStroke);

    canvas.drawCircle(
      Offset(cx, cy + 2),
      2.5,
      Paint()..color = accent.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_GenericArtPainter old) => old.accent != accent;
}

// ── Arte bloqueado ────────────────────────────────────────
class _LockedArt extends StatelessWidget {
  final Color accent;
  const _LockedArt({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Icon(
          Icons.lock_outline,
          size: 28,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 6),
        Text(
          'BLOQUEADO',
          style: TextStyle(
            fontFamily: GsColors.fontMono,
            fontSize: 6,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.2),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ── Bloque de progreso inferior ───────────────────────────
class _ProgressBlock extends StatelessWidget {
  final AlbumBookCard widget;
  const _ProgressBlock({required this.widget});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta
          Text(
            widget.shortLabel,
            style: TextStyle(
              fontFamily: GsColors.fontMono,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: widget.accent,
            ),
          ),
          const SizedBox(height: 3),
          // Barra
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                  color: GsColors.border.withValues(alpha: 0.2), width: 0.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.pct.clamp(0.0, 1.0),
              child: Container(color: widget.accent),
            ),
          ),
          const SizedBox(height: 3),
          // Contador
          Text(
            '${widget.filled} / ${widget.total}',
            style: TextStyle(
              fontFamily: GsColors.fontMono,
              fontSize: 7,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Broche lateral ────────────────────────────────────────
class _Clasp extends StatelessWidget {
  final Color color;
  const _Clasp({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 3, height: 14, color: color.withValues(alpha: 0.4)),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              border: Border.all(color: color, width: 0.8),
            ),
          ),
          Container(width: 3, height: 14, color: color.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool completed;
  final bool locked;
  const _StatusBadge({required this.completed, required this.locked});

  @override
  Widget build(BuildContext context) {
    if (locked) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: completed
          ? const Color(0xFF00C48C).withValues(alpha: 0.85)
          : GsColors.gold.withValues(alpha: 0.85),
      child: Text(
        completed ? 'DONE' : 'ACTIVO',
        style: const TextStyle(
          fontFamily: GsColors.fontMono,
          fontSize: 5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// ── Esquinas doradas ──────────────────────────────────────
abstract class _GoldCorners {
  static const _size = 7.0;

  static List<Widget> get all => [
        _corner(top: 4, left: 4),
        _corner(top: 4, right: 4),
        _corner(bottom: 4, left: 4),
        _corner(bottom: 4, right: 4),
      ];

  static Widget _corner({
    double? top, double? bottom, double? left, double? right,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: SizedBox(
        width: _size, height: _size,
        child: CustomPaint(
          painter: _CornerPainter(top: top != null, left: left != null),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  const _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A820)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
