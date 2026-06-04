import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show Ds;

// ════════════════════════════════════════════════════════════
//  PACK CARD — v2 neobrutalista
//  • Contenedor con borde 2px + sombra offset 4,4
//  • Header con franja acento izquierda
//  • Sobres cortados a la izquierda (Overflow visible, salen del borde)
//  • Texto + botón en columna derecha
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
      decoration: const BoxDecoration(
        color: Ds.bg,
        border: Border.fromBorderSide(BorderSide(color: Ds.border, width: 2)),
        boxShadow: [
          BoxShadow(color: Ds.shadow3d, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Ds.border, width: 1.5)),
            ),
            child: Row(
              children: [
                Container(width: 5, height: 38, color: Ds.accent),
                const SizedBox(width: 10),
                const Text(
                  'SOBRES DISPONIBLES',
                  style: TextStyle(
                    fontFamily: Ds.font, fontSize: 9,
                    fontWeight: FontWeight.w900, letterSpacing: 2, color: Ds.muted,
                  ),
                ),
                const SizedBox(width: 8),
                _CountBadge(count: packsAvailable),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sobres cortados a la izquierda
                _PacksPanel(count: packsAvailable.clamp(0, 5)),

                // Separador vertical
                Container(width: 1.5, color: Ds.border),

                // Texto + botón
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          packsAvailable > 0
                              ? 'Tienes $packsAvailable ${packsAvailable == 1 ? 'sobre listo' : 'sobres listos'} para abrir.'
                              : 'Sigue jugando para ganar más sobres.',
                          style: const TextStyle(
                            fontFamily: Ds.font, fontSize: 11,
                            color: Ds.ink, height: 1.4,
                          ),
                        ),

                        if (packsAvailable > 0)
                          _OpenButton(onTap: onOpen),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Panel de sobres — cortados a la izquierda ─────────────
// Los sobres se apilan y el panel tiene ancho fijo, el overflow
// hace que parezcan salir del borde izquierdo
class _PacksPanel extends StatelessWidget {
  final int count;
  const _PacksPanel({required this.count});

  static const _colors = [
    Ds.accent,
    Color(0xFF1A0CA8),
    Color(0xFF4A3AFF),
    Color(0xFF7B61FF),
    Color(0xFF9B83FF),
  ];

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Container(
        width: 90,
        color: Ds.bgCard,
        child: const Center(
          child: Icon(Icons.inbox_outlined, size: 32, color: Ds.muted),
        ),
      );
    }

    // Ancho fijo del panel — los sobres se "recortan" en el borde izquierdo
    return SizedBox(
      width: 90,
      child: ClipRect(
        child: Stack(
          children: [
            // Fondo panel ligeramente más oscuro
            Positioned.fill(child: Container(color: Ds.bgCard)),

            // Sobres apilados — desplazados hacia izq para que se corten
            for (int i = 0; i < count; i++)
              Positioned(
                left: -10 + i * 12.0,
                top: 10 + (count - 1 - i) * 2.5,
                child: _Envelope3D(color: _colors[i % _colors.length]),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sobre con relieve 3D ──────────────────────────────────
class _Envelope3D extends StatelessWidget {
  final Color color;
  const _Envelope3D({required this.color});

  @override
  Widget build(BuildContext context) {
    // Color más oscuro para sombra lateral del sobre
    final darkColor = Color.fromARGB(
      255,
      (color.red * 0.4).round(),
      (color.green * 0.4).round(),
      (color.blue * 0.4).round(),
    );

    return SizedBox(
      width: 62, height: 80,
      child: Stack(
        children: [
          // Sombra lateral derecha del sobre (efecto volumen)
          Positioned(
            right: 0, top: 3,
            child: Container(width: 5, height: 74, color: darkColor),
          ),

          // Cuerpo del sobre
          Positioned(
            left: 0, right: 5, top: 0, bottom: 3,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                border: const Border.fromBorderSide(
                  BorderSide(color: Ds.border, width: 1),
                ),
              ),
              child: Stack(
                children: [
                  // Flap superior con triángulo
                  CustomPaint(
                    size: const Size(57, 22),
                    painter: _FlapPainter(
                      color: Color.fromARGB(
                        255,
                        (color.red * 0.55).round(),
                        (color.green * 0.55).round(),
                        (color.blue * 0.55).round(),
                      ),
                    ),
                  ),
                  // Línea separadora
                  Positioned(
                    top: 22, left: 0, right: 0,
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  // Icono central
                  const Align(
                    alignment: Alignment(0, 0.5),
                    child: Icon(Icons.auto_awesome,
                      color: Colors.white24, size: 18),
                  ),
                ],
              ),
            ),
          ),

          // Sombra inferior
          Positioned(
            left: 0, right: 5, bottom: 0,
            child: Container(height: 4, color: darkColor),
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
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, 6)
        ..lineTo(size.width / 2, 18)
        ..lineTo(0, 6)
        ..close(),
      Paint()..color = color,
    );
  }
  @override
  bool shouldRepaint(_FlapPainter o) => o.color != color;
}

// ── Badge contador con relieve ────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30, height: 24,
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
          fontFamily: Ds.font, fontSize: 11,
          fontWeight: FontWeight.w900,
          color: count > 0 ? Colors.white : Ds.muted,
        ),
      ),
    );
  }
}

// ── Botón ABRIR SOBRES con sombra 3D ─────────────────────
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
                    color: Ds.shadow3d, offset: Offset(3, 3), blurRadius: 0),
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
                fontFamily: Ds.font, fontSize: 11,
                fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}