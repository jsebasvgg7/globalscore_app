import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show Ds;

class PackCard extends StatelessWidget {
  final int packsAvailable;
  final VoidCallback onOpen;

  const PackCard({
    super.key,
    required this.packsAvailable,
    required this.onOpen,
  });

  static const double _cardBodyHeight = 100.0;
  static const double _envelopeH = 95.0;
  static const double _envelopeW = 58.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Ds.bg,
        border: Border.fromBorderSide(BorderSide(color: Ds.border, width: 2)),
        boxShadow: [
          BoxShadow(color: Color(0xFFB0AAA0), offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ───────────────────────────────────
          Container(
            decoration: const BoxDecoration(
            ),
            child: Row(
              children: [
                Container(width: 5, height: 36, color: Ds.accent),
                const SizedBox(width: 10),
                const Text(
                  'SOBRES DISPONIBLES',
                  style: TextStyle(
                    fontFamily: Ds.font,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Ds.muted,
                  ),
                ),
                const SizedBox(width: 8),
                _CountBadge(count: packsAvailable),
              ],
            ),
          ),

          // ── Body — franja delgada con overflow de sobres ──
          SizedBox(
            height: _cardBodyHeight,
            child: ClipRect(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 10),
                  _PacksStack(
                    count: packsAvailable.clamp(0, 5),
                    envelopeW: _envelopeW,
                    envelopeH: _envelopeH,
                    visibleH: _cardBodyHeight,
                  ),

                  const SizedBox(width: 12),

                  // Texto + botón centrados verticalmente
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            packsAvailable > 0
                                ? 'Tienes $packsAvailable ${packsAvailable == 1 ? 'sobre listo' : 'sobres listos'} para abrir.'
                                : 'Sigue jugando para\nganar más sobres.',
                            style: const TextStyle(
                              fontFamily: Ds.font,
                              fontSize: 11,
                              color: Ds.ink,
                              height: 1.4,
                            ),
                          ),
                          if (packsAvailable > 0) ...[
                            const SizedBox(height: 10),
                            _OpenButton(onTap: onOpen),
                          ],
                        ],
                      ),
                    ),
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
class _PacksStack extends StatelessWidget {
  final int count;
  final double envelopeW;
  final double envelopeH;
  final double visibleH;

  const _PacksStack({
    required this.count,
    required this.envelopeW,
    required this.envelopeH,
    required this.visibleH,
  });

  static const double _dx = 11.0;
  static const double _dy = 7.0;
  static const _rotations = [-0.07, -0.04, -0.015, 0.01, 0.0];

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return SizedBox(
        width: envelopeW + 14,
        height: visibleH,
        child: const Center(
          child: Icon(Icons.inbox_outlined, size: 32, color: Ds.muted),
        ),
      );
    }

    final stackW = envelopeW + (count - 1) * _dx + 6;

    return SizedBox(
      width: stackW,
      height: visibleH,
      child: Stack(
        alignment: Alignment.bottomLeft,
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < count; i++)
            Positioned(
              left: (count - 1 - i) * _dx,
              bottom: -(envelopeH - visibleH) - 28 + (count - 1 - i) * _dy,
              child: Transform.rotate(
                angle: _rotations[i % _rotations.length],
                alignment: Alignment.bottomCenter,
                child: _EnvelopeCard(
                  width: envelopeW,
                  height: envelopeH,
                  isFront: i == count - 1,
                  layerIndex: i,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
class _EnvelopeCard extends StatelessWidget {
  final double width;
  final double height;
  final bool isFront;
  final int layerIndex;

  const _EnvelopeCard({
    required this.width,
    required this.height,
    required this.isFront,
    required this.layerIndex,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = isFront ? 1.0 : (0.50 + layerIndex * 0.13).clamp(0.0, 0.92);

    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _EnvelopePainter(isFront: isFront),
          child: Stack(
            children: [
              // Escudo central con glow
              Center(child: _ShieldGlow(isFront: isFront)),
              // Destello esquina
              Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white.withValues(alpha: isFront ? 0.40 : 0.15),
                  size: 7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  final bool isFront;
  const _EnvelopePainter({required this.isFront});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Sombra suave
    final shadowPaint = Paint()
      ..color = const Color(0xFF1E1B30).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.translate(3, 4), const Radius.circular(4)),
      shadowPaint,
    );

    // Fondo degradado navy
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isFront
            ? const [Color(0xFF3826C8), Color(0xFF1E1680), Color(0xFF0D0B3A)]
            : const [Color(0xFF2A1E9A), Color(0xFF140F5C), Color(0xFF0A0832)],
      ).createShader(rect);
    canvas.drawRRect(rrect, bgPaint);

    // Líneas diagonales
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: isFront ? 0.06 : 0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (double x = -size.height; x < size.width + size.height; x += 13) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * math.tan(math.pi / 4.2), size.height),
        linePaint,
      );
    }

    // Borde exterior
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF2D2A40)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Borde interior luminoso
    final inner = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(2)),
      Paint()
        ..color = const Color(0xFF7B6FFF).withValues(alpha: isFront ? 0.55 : 0.25)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Línea horizontal decorativa
    final hY = size.height * 0.27;
    canvas.drawLine(
      Offset(6, hY),
      Offset(size.width - 6, hY),
      Paint()
        ..color = Colors.white.withValues(alpha: isFront ? 0.09 : 0.04)
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) => old.isFront != isFront;
}

class _ShieldGlow extends StatelessWidget {
  final bool isFront;
  const _ShieldGlow({required this.isFront});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B4FD8).withValues(alpha: isFront ? 0.50 : 0.20),
                blurRadius: 16,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
        Icon(
          Icons.shield_outlined,
          color: Colors.white.withValues(alpha: isFront ? 0.80 : 0.40),
          size: isFront ? 36 : 32,
        ),
        Positioned(
          top: 6,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: isFront ? 0.55 : 0.20),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Badge contador ────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 24,
      decoration: BoxDecoration(
        color: count > 0 ? Ds.accent : Ds.bgCard,
        border: const Border.fromBorderSide(
          BorderSide(color: Ds.border, width: 1),
        ),
        boxShadow: const [
          BoxShadow(color: Ds.shadow3d, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: Ds.font,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: count > 0 ? Colors.white : Ds.muted,
        ),
      ),
    );
  }
}

// ── Botón ABRIR SOBRES ────────────────────────────────────
class _OpenButton extends StatefulWidget {
  final VoidCallback onTap;
  const _OpenButton({required this.onTap});
  @override
  State<_OpenButton> createState() => _OpenButtonState();
}

class _OpenButtonState extends State<_OpenButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: _pressed
            ? (Matrix4.identity()..translate(3.0, 3.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Ds.accent,
          border: const Border.fromBorderSide(
            BorderSide(color: Ds.border, width: 1),
          ),
          boxShadow: _pressed
              ? null
              : const [
                  BoxShadow(
                    color: Ds.shadow3d,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.white, size: 14),
            SizedBox(width: 7),
            Text(
              'ABRIR SOBRES',
              style: TextStyle(
                fontFamily: Ds.font,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}