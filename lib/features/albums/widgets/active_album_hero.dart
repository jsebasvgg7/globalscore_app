import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;
import '../domain/albums_model.dart';

// Paleta por album_id (spine / accent / coverBg)
const Map<String, _AlbumMeta> _albumMeta = {
  'legendary_1': _AlbumMeta(
    spine: Color(0xFF5b4fd8), spineAlt: Color(0xFF3d34a5),
    accent: Color(0xFFa599d9), coverBg: Color(0xFF1a1726),
    shortLabel: 'LEG I', number: '01',
    rarityLabel: 'FUNDADORES', tag: 'TEMP 25·26',
  ),
  'legendary_2': _AlbumMeta(
    spine: Color(0xFF7c3aed), spineAlt: Color(0xFF5b1fbd),
    accent: Color(0xFFc4b5fd), coverBg: Color(0xFF160e2a),
    shortLabel: 'LEG II', number: '02',
    rarityLabel: 'LEYENDAS', tag: 'TEMP 25·26',
  ),
  'legendary_3': _AlbumMeta(
    spine: Color(0xFF1D9E75), spineAlt: Color(0xFF0d6e50),
    accent: Color(0xFF34d399), coverBg: Color(0xFF0a1f18),
    shortLabel: 'LEG III', number: '03',
    rarityLabel: 'ÉLITE', tag: 'TEMP 25·26',
  ),
  'legendary_4': _AlbumMeta(
    spine: Color(0xFFb45309), spineAlt: Color(0xFF7c3b00),
    accent: Color(0xFFf59e0b), coverBg: Color(0xFF1a1200),
    shortLabel: 'LEG IV', number: '04',
    rarityLabel: 'GOATS', tag: 'TEMP 25·26',
  ),
  'legendary_5': _AlbumMeta(
    spine: Color(0xFF9d174d), spineAlt: Color(0xFF6b1130),
    accent: Color(0xFFf472b6), coverBg: Color(0xFF1a0e15),
    shortLabel: 'LEG V', number: '05',
    rarityLabel: 'INMORTALES', tag: 'ENDGAME',
  ),
};

const _AlbumMeta _defaultMeta = _AlbumMeta(
  spine: Color(0xFF5b4fd8), spineAlt: Color(0xFF3d34a5),
  accent: Color(0xFFa599d9), coverBg: Color(0xFF1a1726),
  shortLabel: 'ALB', number: '01',
  rarityLabel: '', tag: '',
);

class _AlbumMeta {
  final Color spine, spineAlt, accent, coverBg;
  final String shortLabel, number, rarityLabel, tag;
  const _AlbumMeta({
    required this.spine, required this.spineAlt,
    required this.accent, required this.coverBg,
    required this.shortLabel, required this.number,
    required this.rarityLabel, required this.tag,
  });
}

// ── Widget público ────────────────────────────────────────
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
    final meta = _albumMeta[albumId] ?? _defaultMeta;

    return Container(
      color: GsColors.cream,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Eyebrow + badge
          Row(
            children: [
              const Text(
                'ÁLBUM ACTIVO',
                style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w900,
                  letterSpacing: 1.5, color: GsColors.muted,
                ),
              ),
              const Spacer(),
              _StatusBadge(completed: isCompleted),
            ],
          ),
          const SizedBox(height: 14),

          // Info + libro 3D
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (name ?? '—').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900,
                        letterSpacing: -0.3, height: 1.1, color: GsColors.text,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: const TextStyle(fontSize: 11, color: GsColors.muted),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Stats: figuritas + % completado
                    Row(
                      children: [
                        _StatBox(value: '$filled', label: 'FIGURITAS'),
                        const SizedBox(width: 8),
                        _StatBox(
                          value: '${(pct * 100).round()}%',
                          label: 'COMPLETADO',
                          valueColor: meta.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Libro 3D
              _Book3D(meta: meta, filled: filled, total: total, pct: pct),
            ],
          ),

          const SizedBox(height: 16),
          // Barra de progreso
          _ProgressBar(pct: pct, color: meta.accent),
          const SizedBox(height: 8),
          // Contador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Chip(label: '$filled / $total figuritas'),
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: meta.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Libro 3D ──────────────────────────────────────────────
class _Book3D extends StatelessWidget {
  final _AlbumMeta meta;
  final int filled, total;
  final double pct;

  const _Book3D({
    required this.meta,
    required this.filled,
    required this.total,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 116,
      child: Stack(
        children: [
          // Sombra
          Positioned(
            left: 6, top: 6,
            child: Container(
              width: 84, height: 108,
              color: GsColors.border.withValues(alpha: 0.07),
            ),
          ),
          // Páginas apiladas (efecto de profundidad)
          for (int i = 2; i >= 0; i--)
            Positioned(
              right: i * 2.0, top: i * 1.0,
              child: Container(
                width: 10, height: 104,
                color: const Color(0xFFD4CFC8).withValues(alpha: 0.6 - i * 0.15),
              ),
            ),
          // Lomo
          Positioned(
            left: 0, top: 0,
            child: Container(
              width: 12, height: 104,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [meta.spine, meta.spineAlt],
                ),
              ),
              alignment: Alignment.center,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  meta.shortLabel,
                  style: const TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 6, fontWeight: FontWeight.w900,
                    color: Colors.white70, letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
          // Portada
          Positioned(
            left: 10, top: 0,
            child: Container(
              width: 82, height: 104,
              decoration: BoxDecoration(
                color: meta.coverBg,
                border: Border.all(color: GsColors.border, width: 1.5),
              ),
              child: Stack(
                children: [
                  // Tag temporada
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      color: GsColors.border.withValues(alpha: 0.4),
                      child: Text(
                        meta.tag,
                        style: const TextStyle(
                          fontFamily: GsColors.fontMono,
                          fontSize: 4.5, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Arte central: círculos + escudo
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BookArtPainter(accent: meta.accent),
                    ),
                  ),
                  // Label rareza + contador
                  Positioned(
                    bottom: 18, left: 0, right: 0,
                    child: Column(
                      children: [
                        Text(
                          meta.rarityLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: GsColors.fontMono,
                            fontSize: 6, fontWeight: FontWeight.w900,
                            letterSpacing: 1.5, color: meta.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$filled / $total',
                          style: TextStyle(
                            fontSize: 7,
                            color: meta.accent.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Barra progreso inferior
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 4,
                      color: Colors.black26,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: Container(color: meta.accent.withValues(alpha: 0.7)),
                      ),
                    ),
                  ),
                  // Broche lateral
                  Positioned(
                    right: 0, top: 0, bottom: 0,
                    child: _BookClasp(color: meta.accent),
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

class _BookArtPainter extends CustomPainter {
  final Color accent;
  const _BookArtPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 4;
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final r in [32.0, 22.0, 14.0]) {
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    // Escudo
    final shieldPaint = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final shieldStroke = Paint()
      ..color = accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(cx, cy - 16)
      ..lineTo(cx + 12, cy - 10)
      ..lineTo(cx + 12, cy + 2)
      ..quadraticBezierTo(cx + 12, cy + 14, cx, cy + 20)
      ..quadraticBezierTo(cx - 12, cy + 14, cx - 12, cy + 2)
      ..lineTo(cx - 12, cy - 10)
      ..close();

    canvas.drawPath(path, shieldPaint);
    canvas.drawPath(path, shieldStroke);

    // Punto central
    canvas.drawCircle(
      Offset(cx, cy + 2),
      3,
      Paint()..color = accent.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(_BookArtPainter old) => old.accent != accent;
}

// ── Broche del libro ──────────────────────────────────────
class _BookClasp extends StatelessWidget {
  final Color color;
  const _BookClasp({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 3, height: 16, color: color.withValues(alpha: 0.5)),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              border: Border.all(color: color, width: 0.8),
            ),
          ),
          Container(width: 3, height: 16, color: color.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

// ── Esquinas doradas ──────────────────────────────────────
abstract class _GoldCorners {
  static const Color _gold = Color(0xFFD4A820);
  static const _size = 6.0;
  static const _thick = 1.0;

  static List<Widget> get all => [
    _corner(top: 3, left: 3),
    _corner(top: 3, right: 3),
    _corner(bottom: 3, left: 3),
    _corner(bottom: 3, right: 3),
  ];

  static Widget _corner({
    double? top, double? bottom, double? left, double? right,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: SizedBox(
        width: _size, height: _size,
        child: CustomPaint(
          painter: _CornerPainter(
            top: top != null, left: left != null,
          ),
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
      ..strokeWidth = _GoldCorners._thick
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

// ── Stat box ──────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String value, label;
  final Color valueColor;
  const _StatBox({
    required this.value, required this.label,
    this.valueColor = GsColors.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        color: GsColors.card,
        border: Border.all(color: GsColors.border, width: 1),
        boxShadow: const [
          BoxShadow(color: GsColors.shadow, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: GsColors.fontMono,
              fontSize: 26, fontWeight: FontWeight.w900,
              letterSpacing: -1, height: 1, color: valueColor,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8, fontWeight: FontWeight.w700,
              letterSpacing: 0.5, color: GsColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress bar animada ──────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double pct;
  final Color color;
  const _ProgressBar({required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (_, v, __) => Container(
        height: 10,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E0D0),
          border: Border.all(color: GsColors.border.withValues(alpha: 0.2), width: 1),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v,
            child: Container(color: color),
          ),
        ),
      ),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: GsColors.card,
        border: Border.all(color: GsColors.border, width: 1),
        boxShadow: const [
          BoxShadow(color: GsColors.shadow, offset: Offset(1, 1)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: GsColors.fontMono,
          fontSize: 10, fontWeight: FontWeight.w700, color: GsColors.text,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFF00C48C) : GsColors.gold,
        border: Border.all(color: GsColors.border, width: 1),
        boxShadow: const [
          BoxShadow(color: GsColors.shadow, offset: Offset(1, 1)),
        ],
      ),
      child: Text(
        completed ? 'COMPLETADO' : 'ACTIVO',
        style: const TextStyle(
          fontFamily: GsColors.fontMono,
          fontSize: 8, fontWeight: FontWeight.w900,
          letterSpacing: 1, color: GsColors.border,
        ),
      ),
    );
  }
}
