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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Ds.bg,
        border: Border.all(color: Ds.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                const Text(
                  'SOBRES DISPONIBLES',
                  style: TextStyle(
                    fontFamily: Ds.font,
                    fontSize: 8,
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

          Container(height: 1, color: Ds.border),

          // ── Body: sobres + texto ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Row(
              children: [
                _PackStack(count: packsAvailable.clamp(0, 4)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    packsAvailable > 0
                        ? 'Tienes $packsAvailable ${packsAvailable == 1 ? 'sobre listo' : 'sobres listos'} para abrir.'
                        : 'Sigue jugando para ganar más sobres.',
                    style: const TextStyle(
                      fontFamily: Ds.font,
                      fontSize: 11,
                      color: Ds.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Botón abrir ───────────────────────────────
          if (packsAvailable > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: _OpenButton(onTap: onOpen),
            ),
        ],
      ),
    );
  }
}

// ── Badge contador — boceto: cuadrado con borde ───────────
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 24,
      decoration: BoxDecoration(
        color: Ds.bg,
        border: Border.all(color: Ds.border, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: Ds.font,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: count > 0 ? Ds.accent : Ds.muted,
        ),
      ),
    );
  }
}

// ── Stack de sobres ───────────────────────────────────────
// Boceto: sobres apilados morados, efecto profundidad
class _PackStack extends StatelessWidget {
  final int count;
  const _PackStack({required this.count});

  static const _colors = [
    Ds.accent,
    Color(0xFF1A0CA8),
    Color(0xFF4A3AFF),
    Color(0xFF7B61FF),
  ];

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Container(
        width: 60, height: 76,
        decoration: BoxDecoration(
          color: Ds.bgCard,
          border: Border.all(color: Ds.border, width: 1),
        ),
        child: const Icon(Icons.inbox_outlined, size: 28, color: Ds.muted),
      );
    }

    return SizedBox(
      width: 60 + (count - 1) * 7.0,
      height: 76,
      child: Stack(
        children: [
          for (int i = count - 1; i >= 0; i--)
            Positioned(
              left: i * 7.0,
              top: (count - 1 - i) * 2.5,
              child: _Envelope(color: _colors[i % _colors.length]),
            ),
        ],
      ),
    );
  }
}

class _Envelope extends StatelessWidget {
  final Color color;
  const _Envelope({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58, height: 72,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Ds.border, width: 1),
      ),
      child: Stack(
        children: [
          // Flap superior
          CustomPaint(
            size: const Size(58, 20),
            painter: _FlapP(
              color: Color.fromARGB(
                255,
                (color.red * 0.55).round(),
                (color.green * 0.55).round(),
                (color.blue * 0.55).round(),
              ),
            ),
          ),
          // Icono central
          Align(
            alignment: const Alignment(0, 0.4),
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withValues(alpha: 0.25),
              size: 20,
            ),
          ),
          // Línea separadora
          Positioned(
            top: 20, left: 0, right: 0,
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlapP extends CustomPainter {
  final Color color;
  const _FlapP({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, 5)
        ..lineTo(size.width / 2, 17)
        ..lineTo(0, 5)
        ..close(),
      Paint()..color = color,
    );
  }
  @override
  bool shouldRepaint(_FlapP o) => o.color != color;
}

// ── Botón abrir — boceto: morado ancho, icono + texto ─────
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
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 80),
        opacity: _pressed ? 0.85 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: Ds.accent,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined,
                  color: Colors.white, size: 15),
              SizedBox(width: 8),
              Text(
                'ABRIR SOBRES',
                style: TextStyle(
                  fontFamily: Ds.font,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}