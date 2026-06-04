import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show Ds;

// ════════════════════════════════════════════════════════════
//  ACTIVE ALBUM HERO
//  3D neobrutalista: contenedor con borde negro + sombra offset,
//  libro 3D grande a la derecha con perspectiva/inclinación,
//  stat boxes con sombra, barra corta (solo columna izquierda)
// ════════════════════════════════════════════════════════════

const Map<String, _AlbumMeta> _meta = {
  'legendary_1': _AlbumMeta(
    spine: Color(0xFF5b4fd8), spineAlt: Color(0xFF3d34a5),
    accent: Color(0xFFa599d9), coverBg: Color(0xFF1a1726),
    shortLabel: 'LEG I', rarityLabel: 'FUNDADORES',
    tag: 'TEMP 25·26', number: '01',
  ),
  'legendary_2': _AlbumMeta(
    spine: Color(0xFF7c3aed), spineAlt: Color(0xFF5b1fbd),
    accent: Color(0xFFc4b5fd), coverBg: Color(0xFF160e2a),
    shortLabel: 'LEG II', rarityLabel: 'LEYENDAS',
    tag: 'TEMP 25·26', number: '02',
  ),
  'legendary_3': _AlbumMeta(
    spine: Color(0xFF1D9E75), spineAlt: Color(0xFF0d6e50),
    accent: Color(0xFF34d399), coverBg: Color(0xFF0a1f18),
    shortLabel: 'LEG III', rarityLabel: 'ÉLITE',
    tag: 'TEMPORADA 25+26', number: '03',
  ),
  'legendary_4': _AlbumMeta(
    spine: Color(0xFFb45309), spineAlt: Color(0xFF7c3b00),
    accent: Color(0xFFf59e0b), coverBg: Color(0xFF1a1200),
    shortLabel: 'LEG IV', rarityLabel: 'GOATS',
    tag: 'TEMP 25·26', number: '04',
  ),
  'legendary_5': _AlbumMeta(
    spine: Color(0xFF9d174d), spineAlt: Color(0xFF6b1130),
    accent: Color(0xFFf472b6), coverBg: Color(0xFF1a0e15),
    shortLabel: 'LEG V', rarityLabel: 'INMORTALES',
    tag: 'ENDGAME', number: '05',
  ),
};

const _AlbumMeta _def = _AlbumMeta(
  spine: Color(0xFF5b4fd8), spineAlt: Color(0xFF3d34a5),
  accent: Color(0xFFa599d9), coverBg: Color(0xFF1a1726),
  shortLabel: 'ALB', rarityLabel: '', tag: '', number: '01',
);

class _AlbumMeta {
  final Color spine, spineAlt, accent, coverBg;
  final String shortLabel, rarityLabel, tag, number;
  const _AlbumMeta({
    required this.spine, required this.spineAlt,
    required this.accent, required this.coverBg,
    required this.shortLabel, required this.rarityLabel,
    required this.tag, required this.number,
  });
}

class ActiveAlbumHero extends StatelessWidget {
  final String? albumId;
  final String? name;
  final String? description;
  final double pct;
  final int filled;
  final int total;
  final bool isCompleted;

  const ActiveAlbumHero({
    super.key,
    this.albumId,
    this.name,
    this.description,
    required this.pct,
    required this.filled,
    required this.total,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final m = _meta[albumId] ?? _def;

    // Contenedor principal con borde negro y sombra offset 3D
    return Container(
      decoration: BoxDecoration(
        color: Ds.bg,
        border: Border.all(color: Ds.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Ds.shadow3d,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Fila superior: eyebrow + badge ───────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                const Text(
                  'ÁLBUM ACTIVO',
                  style: TextStyle(
                    fontFamily: Ds.font,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Ds.muted,
                  ),
                ),
                const Spacer(),
                _ActiveBadge(completed: isCompleted),
              ],
            ),
          ),

          // ── Fila central: info izquierda + libro derecho
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 0, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna izquierda — ocupa ~55% del ancho
                Expanded(
                  flex: 55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        (name ?? '—').toUpperCase(),
                        style: const TextStyle(
                          fontFamily: Ds.font,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.05,
                          color: Ds.ink,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          description!,
                          style: const TextStyle(
                            fontFamily: Ds.font,
                            fontSize: 10,
                            color: Ds.muted,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Stat boxes — con sombra 3D
                      Row(
                        children: [
                          _StatBox(
                            value: '$filled',
                            label: 'FIGURITAS',
                          ),
                          const SizedBox(width: 8),
                          _StatBox(
                            value: '${(pct * 100).round()}%',
                            label: 'COMPLETADO',
                            valueColor: m.accent,
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Barra de progreso (solo bajo la columna izquierda)
                      _ProgressBar(pct: pct, color: m.accent),
                      const SizedBox(height: 8),

                      // Chip figuritas
                      _FigChip(
                        filled: filled,
                        total: total,
                        pct: pct,
                        accent: m.accent,
                      ),
                    ],
                  ),
                ),

                // Columna derecha — libro 3D grande con perspectiva
                Expanded(
                  flex: 45,
                  child: _Book3DPerspective(
                    meta: m,
                    filled: filled,
                    total: total,
                    pct: pct,
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

// ════════════════════════════════════════════════════════════
//  LIBRO 3D CON PERSPECTIVA — efecto inclinación real
//  Usa Transform con perspectiva para simular libro abierto
//  en ángulo, igual que imagen 2
// ════════════════════════════════════════════════════════════
class _Book3DPerspective extends StatelessWidget {
  final _AlbumMeta meta;
  final int filled, total;
  final double pct;

  const _Book3DPerspective({
    required this.meta,
    required this.filled,
    required this.total,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sombra del libro (offset abajo-derecha)
          Positioned(
            left: 14, top: 14,
            child: Container(
              width: 140, height: 175,
              color: Ds.ink.withValues(alpha: 0.35),
            ),
          ),

          // Libro con Transform perspectiva — inclinado
          Positioned(
            left: 0, top: 0,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)   // perspectiva
                ..rotateY(-0.22)           // inclinación eje Y
                ..rotateX(0.06),           // leve inclinación eje X
              child: _BookBody(
                meta: meta,
                filled: filled,
                total: total,
                pct: pct,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookBody extends StatelessWidget {
  final _AlbumMeta meta;
  final int filled, total;
  final double pct;

  const _BookBody({
    required this.meta,
    required this.filled,
    required this.total,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    const bookW = 138.0;
    const bookH = 174.0;
    const spineW = 18.0;

    return SizedBox(
      width: bookW,
      height: bookH,
      child: Stack(
        children: [
          // ── Páginas apiladas (profundidad) ────────────
          for (int i = 3; i >= 0; i--)
            Positioned(
              right: i * 3.0, top: i * 1.5,
              child: Container(
                width: 14, height: bookH - 4,
                color: Color.lerp(
                  const Color(0xFFD4CFC8),
                  const Color(0xFFBBB5AD),
                  i / 3,
                )!.withValues(alpha: 0.7),
              ),
            ),

          // ── Lomo (spine) ──────────────────────────────
          Positioned(
            left: 0, top: 0,
            child: Container(
              width: spineW, height: bookH,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    meta.spine,
                    meta.spineAlt,
                    meta.spine.withValues(alpha: 0.7),
                  ],
                  stops: const [0, 0.6, 1],
                ),
              ),
              alignment: Alignment.center,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  meta.shortLabel,
                  style: const TextStyle(
                    fontFamily: Ds.font,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),

          // ── Portada principal ─────────────────────────
          Positioned(
            left: spineW - 1, top: 0,
            child: Container(
              width: bookW - spineW + 1,
              height: bookH,
              decoration: BoxDecoration(
                color: meta.coverBg,
                border: Border.all(
                  color: meta.accent.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Número álbum top-left
                  Positioned(
                    top: 7, left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      color: Colors.black38,
                      child: Text(
                        meta.number,
                        style: TextStyle(
                          fontFamily: Ds.font,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: meta.accent,
                        ),
                      ),
                    ),
                  ),

                  // Tag temporada top-right
                  Positioned(
                    top: 7, right: 14,
                    child: Text(
                      meta.tag,
                      style: const TextStyle(
                        fontFamily: Ds.font,
                        fontSize: 5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Arte central con glow
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CoverArtPainter(accent: meta.accent),
                    ),
                  ),

                  // Label rareza
                  Positioned(
                    bottom: 28, left: 0, right: 0,
                    child: Text(
                      meta.rarityLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: Ds.font,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: meta.accent,
                      ),
                    ),
                  ),

                  // Contador items
                  Positioned(
                    bottom: 16, left: 0, right: 0,
                    child: Text(
                      '$filled / $total ITEMS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: Ds.font,
                        fontSize: 7,
                        color: meta.accent.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Barra inferior
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 5,
                      color: Colors.black38,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: Container(
                            color: meta.accent.withValues(alpha: 0.9)),
                      ),
                    ),
                  ),

                  // Broche lateral derecho
                  Positioned(
                    right: 0, top: 0, bottom: 0,
                    child: _Clasp(color: meta.accent),
                  ),

                  // Esquinas doradas
                  ..._GoldCorners.all,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Arte de portada con glow radial ──────────────────────
class _CoverArtPainter extends CustomPainter {
  final Color accent;
  const _CoverArtPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;

    // Glow radial
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.18),
          accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 55));
    canvas.drawCircle(Offset(cx, cy), 55, glow);

    // Círculos concéntricos
    for (final r in [40.0, 28.0, 18.0, 10.0]) {
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = accent.withValues(alpha: 0.13)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Escudo central
    final fill = Paint()
      ..color = accent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(cx, cy - 20)
      ..lineTo(cx + 15, cy - 12)
      ..lineTo(cx + 15, cy + 3)
      ..quadraticBezierTo(cx + 15, cy + 18, cx, cy + 26)
      ..quadraticBezierTo(cx - 15, cy + 18, cx - 15, cy + 3)
      ..lineTo(cx - 15, cy - 12)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    // Punto central brillante
    canvas.drawCircle(
      Offset(cx, cy + 3),
      4,
      Paint()
        ..color = accent.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(Offset(cx, cy + 3), 2.5,
        Paint()..color = accent.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(_CoverArtPainter o) => o.accent != accent;
}

// ── Badge ACTIVO ──────────────────────────────────────────
class _ActiveBadge extends StatelessWidget {
  final bool completed;
  const _ActiveBadge({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFF00C48C) : Ds.gold,
        boxShadow: const [
          BoxShadow(color: Ds.shadow3d, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      child: Text(
        completed ? 'COMPLETADO' : 'ACTIVO',
        style: const TextStyle(
          fontFamily: Ds.font,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Ds.ink,
        ),
      ),
    );
  }
}

// ── Stat box con sombra 3D ────────────────────────────────
class _StatBox extends StatelessWidget {
  final String value, label;
  final Color valueColor;
  const _StatBox({
    required this.value,
    required this.label,
    this.valueColor = Ds.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      decoration: BoxDecoration(
        color: Ds.bg,
        border: Border.all(color: Ds.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Ds.shadow3d,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: Ds.font,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              height: 1,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontFamily: Ds.font,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Ds.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barra de progreso ─────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double pct;
  final Color color;
  const _ProgressBar({required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (_, v, __) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            // Relieve: borde oscuro arriba/izq, claro abajo/der
            border: Border(
              top: BorderSide(color: Ds.ink.withValues(alpha: 0.3), width: 1),
              left: BorderSide(color: Ds.ink.withValues(alpha: 0.3), width: 1),
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1),
            ),
            color: Ds.bgCard,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Chip figuritas ────────────────────────────────────────
class _FigChip extends StatelessWidget {
  final int filled, total;
  final double pct;
  final Color accent;
  const _FigChip({
    required this.filled,
    required this.total,
    required this.pct,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Ds.bg,
        border: Border.all(color: Ds.border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Ds.shadow3d, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          Text(
            '$filled / $total figuritas',
            style: const TextStyle(
              fontFamily: Ds.font,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Ds.ink,
            ),
          ),
          const Spacer(),
          Text(
            '${(pct * 100).round()}%',
            style: TextStyle(
              fontFamily: Ds.font,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Broche ────────────────────────────────────────────────
class _Clasp extends StatelessWidget {
  final Color color;
  const _Clasp({required this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 9,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 3, height: 18, color: color.withValues(alpha: 0.5)),
          Container(
            width: 9, height: 9,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              border: Border.all(color: color, width: 1),
            ),
          ),
          Container(width: 3, height: 18, color: color.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

abstract class _GoldCorners {
  static const _sz = 7.0;
  static List<Widget> get all => [
    _c(top: 4, left: 4), _c(top: 4, right: 4),
    _c(bottom: 4, left: 4), _c(bottom: 4, right: 4),
  ];
  static Widget _c({double? top, double? bottom, double? left, double? right}) =>
      Positioned(
        top: top, bottom: bottom, left: left, right: right,
        child: SizedBox(
          width: _sz, height: _sz,
          child: CustomPaint(painter: _CP(top: top != null, left: left != null)),
        ),
      );
}

class _CP extends CustomPainter {
  final bool top, left;
  const _CP({required this.top, required this.left});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFD4A820)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    canvas.drawLine(Offset(x, y), Offset(x + (left ? size.width : -size.width), y), p);
    canvas.drawLine(Offset(x, y), Offset(x, y + (top ? size.height : -size.height)), p);
  }
  @override
  bool shouldRepaint(_CP o) => false;
}