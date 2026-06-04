import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;

// ════════════════════════════════════════════════════════════
//  PACK CARD
//  React equiv: Pack3D
//  Sobre apilado + descripción + botón abrir
// ════════════════════════════════════════════════════════════
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
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GsColors.card,
        border: Border.all(color: GsColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: GsColors.shadow, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'SOBRES DISPONIBLES',
                style: TextStyle(
                  fontFamily: GsColors.fontMono,
                  fontSize: 9, fontWeight: FontWeight.w900,
                  letterSpacing: 2, color: GsColors.muted,
                ),
              ),
              const SizedBox(width: 8),
              _CountBadge(count: packsAvailable),
            ],
          ),
          const SizedBox(height: 14),

          // Sobre + texto
          Row(
            children: [
              _PackStack(count: packsAvailable.clamp(0, 4)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  packsAvailable > 0
                      ? 'Tienes $packsAvailable ${packsAvailable == 1 ? 'sobre listo' : 'sobres listos'} para abrir.'
                      : 'Sigue jugando para ganar más sobres.',
                  style: const TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 11, color: GsColors.text,
                  ),
                ),
              ),
            ],
          ),

          if (packsAvailable > 0) ...[
            const SizedBox(height: 14),
            _OpenButton(onTap: onOpen),
          ],
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: count > 0 ? GsColors.accent : GsColors.card,
        border: Border.all(color: GsColors.border, width: 1),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: GsColors.fontMono,
          fontSize: 9, fontWeight: FontWeight.w900,
          color: count > 0 ? Colors.white : GsColors.muted,
        ),
      ),
    );
  }
}

// ── Stack de sobres ───────────────────────────────────────
class _PackStack extends StatelessWidget {
  final int count;
  const _PackStack({required this.count});

  static const _colors = [
    GsColors.accent,
    Color(0xFF1A0CA8),
    Color(0xFF4A3AFF),
    Color(0xFF7B61FF),
  ];

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Container(
        width: 56, height: 70,
        decoration: BoxDecoration(
          color: GsColors.card,
          border: Border.all(
            color: GsColors.border.withValues(alpha: 0.2), width: 1,
          ),
        ),
        child: const Icon(Icons.inbox_outlined, size: 24, color: GsColors.muted),
      );
    }

    return SizedBox(
      width: 56 + (count - 1) * 6.0,
      height: 72,
      child: Stack(
        children: [
          for (int i = count - 1; i >= 0; i--)
            Positioned(
              left: i * 6.0,
              top: (count - 1 - i) * 2.0,
              child: _PackEnvelope(color: _colors[i % _colors.length]),
            ),
        ],
      ),
    );
  }
}

class _PackEnvelope extends StatelessWidget {
  final Color color;
  const _PackEnvelope({required this.color});

  @override
  Widget build(BuildContext context) {
    final spineColor = Color.fromARGB(
      255,
      (color.red * 0.6).round(),
      (color.green * 0.6).round(),
      (color.blue * 0.6).round(),
    );

    return Container(
      width: 54, height: 68,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: GsColors.border, width: 1),
        boxShadow: const [
          BoxShadow(color: GsColors.shadow, offset: Offset(1, 1)),
        ],
      ),
      child: Stack(
        children: [
          // Flap
          CustomPaint(
            size: const Size(54, 18),
            painter: _FlapPainter(color: spineColor),
          ),
          // Logo
          Align(
            alignment: const Alignment(0, 0.3),
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withValues(alpha: 0.3),
              size: 18,
            ),
          ),
          // Línea horizontal separadora
          Positioned(
            top: 18, left: 0, right: 0,
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlapPainter extends CustomPainter {
  final Color color;
  const _FlapPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, 4)
      ..lineTo(size.width / 2, 15)
      ..lineTo(0, 4)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FlapPainter old) => old.color != color;
}

// ── Botón abrir ───────────────────────────────────────────
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
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? (Matrix4.identity()..translate(3.0, 3.0))
            : Matrix4.identity(),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: GsColors.accent,
          border: Border.all(color: GsColors.border, width: 1.5),
          boxShadow: _pressed
              ? null
              : const [BoxShadow(color: GsColors.shadow, offset: Offset(3, 3))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'ABRIR SOBRES',
              style: TextStyle(
                fontFamily: GsColors.fontMono,
                fontSize: 12, fontWeight: FontWeight.w900,
                letterSpacing: 2, color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
