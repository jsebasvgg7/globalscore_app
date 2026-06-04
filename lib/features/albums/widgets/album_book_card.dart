import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;

// ════════════════════════════════════════════════════════════
//  ALBUM BOOK CARD — diseño 3D con lomo, páginas y sombra
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
  final Widget? coverIllustration;

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
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Book3D(w: widget),
            const SizedBox(height: 10),
            _ProgressBlock(w: widget),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  LIBRO 3D
// ════════════════════════════════════════════════════════════
class _Book3D extends StatelessWidget {
  final AlbumBookCard w;
  const _Book3D({required this.w});

  static const double _bookH    = 160.0;
  static const double _coverW   = 96.0;
  static const double _spineW   = 18.0;
  static const double _pagesW   = 10.0; // grosor visible de hojas
  static const double _shadowOff = 6.0;

  @override
  Widget build(BuildContext context) {
    final totalW = _spineW + _coverW + _pagesW + _shadowOff;

    return SizedBox(
      width: totalW,
      height: _bookH + _shadowOff,
      child: Stack(
        children: [

          // ── Sombra debajo del libro ───────────────────
          Positioned(
            left: _spineW + _shadowOff,
            top: _shadowOff,
            child: Container(
              width: _coverW,
              height: _bookH,
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.35),
            ),
          ),

          // ── Páginas al lado derecho (pila de hojas) ───
          // Capas múltiples para efecto de grosor real
          for (int i = 5; i >= 0; i--)
            Positioned(
              left: _spineW + _coverW - 2 + i * 1.6,
              top: i * 0.6,
              child: Container(
                width: 6,
                height: _bookH - i * 0.6,
                decoration: BoxDecoration(
                  color: _pageColor(i),
                  border: i == 0
                      ? Border(
                          right: BorderSide(
                            color: const Color(0xFFB0A898).withValues(alpha: 0.6),
                            width: 0.5,
                          ),
                        )
                      : null,
                ),
              ),
            ),

          // ── Lomo del libro ────────────────────────────
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: _spineW,
              height: _bookH,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  colors: [
                    w.spineAlt.withValues(alpha: 0.7),
                    w.spine,
                    w.spine.withValues(alpha: 0.85),
                    w.spineAlt.withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Marca de ribete superior
                  Container(
                    height: 3,
                    margin: const EdgeInsets.only(top: 6, left: 3, right: 3),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  // Texto del lomo rotado
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      w.shortLabel,
                      style: const TextStyle(
                        fontFamily: GsColors.fontMono,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  // Ribete inferior + detalle dorado
                  Column(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(
                            color: const Color(0xFFD4A820).withValues(alpha: 0.7),
                            width: 1,
                          ),
                        ),
                      ),
                      Container(
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 6, left: 3, right: 3),
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Portada principal ─────────────────────────
          Positioned(
            left: _spineW,
            top: 0,
            child: Container(
              width: _coverW,
              height: _bookH,
              decoration: BoxDecoration(
                color: w.coverBg,
                border: Border.all(
                  color: w.spine.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Gradiente de textura sobre portada
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            w.accent.withValues(alpha: 0.08),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Arte central (ilustración o arte bloqueado)
                  Positioned.fill(
                    top: 20,
                    bottom: 16,
                    child: w.locked
                        ? _LockedArt(accent: w.accent)
                        : (w.coverIllustration ?? _GenericArt(accent: w.accent)),
                  ),

                  // Tag temporada (top-left)
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        w.tag,
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

                  // Número (top-right)
                  Positioned(
                    top: 6, right: 8,
                    child: Text(
                      w.number,
                      style: TextStyle(
                        fontFamily: GsColors.fontMono,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: w.accent.withValues(alpha: 0.7),
                      ),
                    ),
                  ),

                  // Badge estado (ACTIVO / DONE)
                  if (!w.locked)
                    Positioned(
                      top: 20, left: 6,
                      child: _StatusBadge(completed: w.completed),
                    ),

                  // Esquinas doradas decorativas
                  ..._GoldCorners.all,

                  // Barra de progreso en la parte inferior
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Línea divisoria
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        Container(
                          height: 5,
                          color: Colors.black.withValues(alpha: 0.4),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: w.pct.clamp(0.0, 1.0),
                            child: Container(color: w.accent),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Broche lateral derecho
                  Positioned(
                    right: 0, top: 0, bottom: 0,
                    child: _Clasp(color: w.accent),
                  ),
                ],
              ),
            ),
          ),

          // ── Reflejo/highlight en el lomo (luz lateral) ─
          Positioned(
            left: _spineW - 3,
            top: 0,
            child: Container(
              width: 3,
              height: _bookH,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Color de cada capa de páginas
  Color _pageColor(int layer) {
    final base = const Color(0xFFE8E3D8);
    final dark = const Color(0xFFB8B2AA);
    final t = layer / 5.0;
    return Color.lerp(base, dark, t)!.withValues(alpha: 0.9 - layer * 0.05);
  }
}

// ── Arte genérico ─────────────────────────────────────────
class _GenericArt extends StatelessWidget {
  final Color accent;
  const _GenericArt({required this.accent});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GenericArtPainter(accent: accent));
}

class _GenericArtPainter extends CustomPainter {
  final Color accent;
  const _GenericArtPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 36));
    canvas.drawCircle(Offset(cx, cy), 36, glow);

    final ring = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final r in [30.0, 22.0, 14.0]) {
      canvas.drawCircle(Offset(cx, cy), r, ring);
    }

    final shieldFill = Paint()
      ..color = accent.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    final shieldStroke = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(cx, cy - 16)
      ..lineTo(cx + 12, cy - 9)
      ..lineTo(cx + 12, cy + 2)
      ..quadraticBezierTo(cx + 12, cy + 14, cx, cy + 20)
      ..quadraticBezierTo(cx - 12, cy + 14, cx - 12, cy + 2)
      ..lineTo(cx - 12, cy - 9)
      ..close();

    canvas.drawPath(path, shieldFill);
    canvas.drawPath(path, shieldStroke);
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
        Icon(
          Icons.lock_outline,
          size: 32,
          color: Colors.white.withValues(alpha: 0.18),
        ),
        const SizedBox(height: 6),
        Text(
          'BLOQUEADO',
          style: TextStyle(
            fontFamily: GsColors.fontMono,
            fontSize: 6,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.18),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ── Bloque de progreso debajo del libro ───────────────────
class _ProgressBlock extends StatelessWidget {
  final AlbumBookCard w;
  const _ProgressBlock({required this.w});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            w.shortLabel,
            style: TextStyle(
              fontFamily: GsColors.fontMono,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: w.accent,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 5,
                color: GsColors.border.withValues(alpha: 0.15),
              ),
              FractionallySizedBox(
                widthFactor: w.pct.clamp(0.0, 1.0),
                child: Container(height: 5, color: w.accent),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${w.filled} / ${w.total}',
            style: TextStyle(
              fontFamily: GsColors.fontMono,
              fontSize: 7,
              color: GsColors.muted,
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
          Container(
              width: 2, height: 18,
              color: color.withValues(alpha: 0.35)),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              border: Border.all(
                color: color.withValues(alpha: 0.7),
                width: 0.8,
              ),
            ),
          ),
          Container(
              width: 2, height: 18,
              color: color.withValues(alpha: 0.35)),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool completed;
  const _StatusBadge({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: completed
          ? const Color(0xFF00C48C).withValues(alpha: 0.9)
          : GsColors.gold.withValues(alpha: 0.9),
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
  static const _size = 8.0;

  static List<Widget> get all => [
        _corner(top: 4,    left: 4),
        _corner(top: 4,    right: 4),
        _corner(bottom: 4, left: 4),
        _corner(bottom: 4, right: 4),
      ];

  static Widget _corner({
    double? top, double? bottom, double? left, double? right,
  }) =>
      Positioned(
        top: top, bottom: bottom, left: left, right: right,
        child: SizedBox(
          width: _size, height: _size,
          child: CustomPaint(
            painter: _CornerPainter(top: top != null, left: left != null),
          ),
        ),
      );
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  const _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A820)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;

    canvas.drawLine(Offset(x, y), Offset(x + (left ? size.width : -size.width), y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + (top ? size.height : -size.height)), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}