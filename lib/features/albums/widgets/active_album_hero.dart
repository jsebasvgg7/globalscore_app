import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show Ds;

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

    return Container(
      decoration: const BoxDecoration(
        color: Ds.bg,
        border: Border.fromBorderSide(BorderSide(color: Ds.border, width: 2)),
        boxShadow: [
          BoxShadow(color: Ds.shadow3d, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Columna izquierda ─────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Eyebrow — sin badge aquí
                      const Text(
                        'ÁLBUM ACTIVO',
                        style: TextStyle(
                          fontFamily: Ds.font, fontSize: 8,
                          fontWeight: FontWeight.w900, letterSpacing: 2.5,
                          color: Ds.muted,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Título
                      Text(
                        (name ?? '—').toUpperCase(),
                        style: const TextStyle(
                          fontFamily: Ds.font, fontSize: 18,
                          fontWeight: FontWeight.w900, letterSpacing: -0.5,
                          height: 1.05, color: Ds.ink,
                        ),
                      ),

                      if (description != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          description!,
                          style: const TextStyle(
                            fontFamily: Ds.font, fontSize: 9,
                            color: Ds.muted, height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _StatBox(value: '$filled', label: 'FIGURITAS'),
                          const SizedBox(width: 6),
                          _StatBox(
                            value: '${(pct * 100).round()}%',
                            label: 'COMPLETADO',
                            valueColor: m.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _EmbossProgressBar(pct: pct, color: m.accent),
                      const SizedBox(height: 6),

                      _FigChip(filled: filled, total: total, pct: pct, accent: m.accent),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ── Libro 3D — desplazado hacia abajo ────
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: _Book3D(meta: m, filled: filled, total: total, pct: pct),
                ),
              ],
            ),
          ),

          // ── Badge ACTIVO — esquina superior derecha ───
          Positioned(
            top: 0, right: 0,
            child: _ActiveBadge(completed: isCompleted),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  LIBRO 3D — reducido a 125×160
// ════════════════════════════════════════════════════════════
class _Book3D extends StatelessWidget {
  final _AlbumMeta meta;
  final int filled, total;
  final double pct;

  const _Book3D({
    required this.meta, required this.filled,
    required this.total, required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138, height: 168,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sombra volumétrica (2 capas)
          Positioned(
            left: 8, top: 8,
            child: Container(
              width: 118, height: 152,
              color: Ds.ink.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            left: 5, top: 5,
            child: Container(
              width: 118, height: 152,
              color: Ds.ink.withValues(alpha: 0.12),
            ),
          ),
          // Libro con perspectiva
          Positioned(
            left: 0, top: 0,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0008)
                ..rotateY(-0.18)
                ..rotateX(0.04),
              child: _BookFace(meta: meta, filled: filled, total: total, pct: pct),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookFace extends StatelessWidget {
  final _AlbumMeta meta;
  final int filled, total;
  final double pct;

  const _BookFace({
    required this.meta, required this.filled,
    required this.total, required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    const w = 118.0;
    const h = 152.0;
    const spineW = 16.0;

    return SizedBox(
      width: w, height: h,
      child: Stack(
        children: [
          // Páginas lado derecho
          for (int i = 4; i >= 0; i--)
            Positioned(
              right: i * 2.5, top: i * 0.8,
              child: Container(
                width: 12, height: h - 5,
                color: Color.lerp(
                  const Color(0xFFCCCBC6),
                  const Color(0xFFE8E4DC),
                  i / 4,
                )!,
              ),
            ),

          // Lomo
          Positioned(
            left: 0, top: 0,
            child: Container(
              width: spineW, height: h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    meta.spine.withValues(alpha: 0.95),
                    meta.spineAlt,
                    meta.spine.withValues(alpha: 0.6),
                  ],
                  stops: const [0, 0.55, 1],
                ),
                border: Border(
                  right: BorderSide(color: meta.spine.withValues(alpha: 0.3), width: 1),
                ),
              ),
              alignment: Alignment.center,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  meta.shortLabel,
                  style: const TextStyle(
                    fontFamily: Ds.font, fontSize: 6,
                    fontWeight: FontWeight.w900,
                    color: Colors.white70, letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),

          // Portada
          Positioned(
            left: spineW - 1, top: 0,
            child: Container(
              width: w - spineW + 1, height: h,
              decoration: BoxDecoration(
                color: meta.coverBg,
                border: Border.all(
                  color: meta.accent.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Stack(
                children: [
                  // Número
                  Positioned(
                    top: 7, left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      color: Colors.black45,
                      child: Text(
                        meta.number,
                        style: TextStyle(
                          fontFamily: Ds.font, fontSize: 9,
                          fontWeight: FontWeight.w900, color: meta.accent,
                        ),
                      ),
                    ),
                  ),
                  // Tag temporada
                  Positioned(
                    top: 7, right: 12,
                    child: Text(
                      meta.tag,
                      style: const TextStyle(
                        fontFamily: Ds.font, fontSize: 5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white38, letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  // Arte portada
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CoverArtPainter(accent: meta.accent),
                    ),
                  ),
                  // Label rareza
                  Positioned(
                    bottom: 24, left: 0, right: 0,
                    child: Text(
                      meta.rarityLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: Ds.font, fontSize: 9,
                        fontWeight: FontWeight.w900, letterSpacing: 2,
                        color: meta.accent,
                      ),
                    ),
                  ),
                  // Contador items
                  Positioned(
                    bottom: 14, left: 0, right: 0,
                    child: Text(
                      '$filled / $total ITEMS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: Ds.font, fontSize: 6.5,
                        color: meta.accent.withValues(alpha: 0.55),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Barra progreso inferior
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 5,
                      color: Colors.black54,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: meta.accent,
                            boxShadow: [
                              BoxShadow(
                                color: meta.accent.withValues(alpha: 0.6),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Broche
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

// ── Arte de portada ───────────────────────────────────────
class _CoverArtPainter extends CustomPainter {
  final Color accent;
  const _CoverArtPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;

    final glow = Paint()
      ..shader = RadialGradient(colors: [
        accent.withValues(alpha: 0.2),
        accent.withValues(alpha: 0.0),
      ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 50));
    canvas.drawCircle(Offset(cx, cy), 50, glow);

    for (final r in [38.0, 26.0, 16.0, 9.0]) {
      canvas.drawCircle(Offset(cx, cy), r,
        Paint()
          ..color = accent.withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9);
    }

    if (size.width < 10 || size.height < 10) return;

    final fill = Paint()
      ..color = accent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(cx, cy - 18)
      ..lineTo(cx + 14, cy - 10)
      ..lineTo(cx + 14, cy + 3)
      ..quadraticBezierTo(cx + 14, cy + 16, cx, cy + 22)
      ..quadraticBezierTo(cx - 14, cy + 16, cx - 14, cy + 3)
      ..lineTo(cx - 14, cy - 10)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    canvas.drawCircle(Offset(cx, cy + 3), 4,
      Paint()
        ..color = accent.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(Offset(cx, cy + 3), 2.4,
      Paint()..color = accent.withValues(alpha: 0.95));
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFF00C48C) : Ds.accent,
        boxShadow: const [
          BoxShadow(color: Ds.shadow3d, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      child: Text(
        completed ? 'COMPLETADO' : 'ACTIVO',
        style: const TextStyle(
          fontFamily: Ds.font, fontSize: 7,
          fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white,
        ),
      ),
    );
  }
}

// ── Stat box — más compacto ───────────────────────────────
class _StatBox extends StatelessWidget {
  final String value, label;
  final Color valueColor;
  const _StatBox({
    required this.value, required this.label,
    this.valueColor = Ds.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: const BoxDecoration(
        color: Ds.bg,
        border: Border.fromBorderSide(BorderSide(color: Ds.border, width: 1.5)),
        boxShadow: [
          BoxShadow(color: Ds.shadow3d, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(
            fontFamily: Ds.font, fontSize: 22,
            fontWeight: FontWeight.w900, letterSpacing: -1,
            height: 1, color: valueColor,
          )),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(
            fontFamily: Ds.font, fontSize: 6.5,
            fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Ds.muted,
          )),
        ],
      ),
    );
  }
}

// ── Barra embutida ────────────────────────────────────────
class _EmbossProgressBar extends StatelessWidget {
  final double pct;
  final Color color;
  const _EmbossProgressBar({required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (_, v, __) {
        return Container(
          height: 8,
          decoration: const BoxDecoration(
            color: Ds.bgCard,
            border: Border(
              top: BorderSide(color: Color(0xFF888070), width: 1.5),
              left: BorderSide(color: Color(0xFF888070), width: 1.5),
              bottom: BorderSide(color: Color(0xFFFFFFFF), width: 1),
              right: BorderSide(color: Color(0xFFFFFFFF), width: 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Row(
              children: [
                Flexible(
                  flex: (v * 1000).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                if (v < 1.0)
                  Flexible(
                    flex: ((1 - v) * 1000).round(),
                    child: const SizedBox(),
                  ),
              ],
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
    required this.filled, required this.total,
    required this.pct, required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Ds.bg,
        border: Border.fromBorderSide(BorderSide(color: Ds.border, width: 1.5)),
        boxShadow: [
          BoxShadow(color: Ds.shadow3d, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          Text('$filled / $total figuritas', style: const TextStyle(
            fontFamily: Ds.font, fontSize: 9,
            fontWeight: FontWeight.w700, color: Ds.ink,
          )),
          const Spacer(),
          Text('${(pct * 100).round()}%', style: TextStyle(
            fontFamily: Ds.font, fontSize: 9,
            fontWeight: FontWeight.w900, color: accent,
          )),
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
      width: 8,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 2, height: 16, color: color.withValues(alpha: 0.55)),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              border: Border.all(color: color, width: 1),
            ),
          ),
          Container(width: 2, height: 16, color: color.withValues(alpha: 0.55)),
        ],
      ),
    );
  }
}

abstract class _GoldCorners {
  static const _sz = 7.0;
  static List<Widget> get all => [
    _c(top: 3, left: 3), _c(top: 3, right: 3),
    _c(bottom: 3, left: 3), _c(bottom: 3, right: 3),
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