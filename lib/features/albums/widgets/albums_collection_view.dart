import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;
import '../domain/albums_model.dart';
import '../domain/albums_provider.dart';
import 'legendary_section.dart';
import 'stars_section.dart';
import 'cult_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Widget principal ──────────────────────────────────────
class AlbumsCollectionView extends ConsumerWidget {
  final AlbumsModel model;
  const AlbumsCollectionView({super.key, required this.model});

  int _legendaryCompleted() {
    return model.progressByAlbumId.values
        .where((p) => p.albumId.startsWith('legendary') && p.isCompleted)
        .length;
  }

  int _starsCompleted() {
    return model.progressByAlbumId.values
        .where((p) => p.albumId.startsWith('stars') && p.isCompleted)
        .length;
  }

  int _cultCompleted() {
    return model.progressByAlbumId.values
        .where((p) => p.albumId.startsWith('cult') && p.isCompleted)
        .length;
  }

  // allCards construido desde model.allCards (si existe) o desde collection
  List<AlbumCard> _allCards() {
    // Intenta usar model.allCards primero; si no existe, usa collection
    try {
      // ignore: return_of_invalid_type
      return (model as dynamic).allCards as List<AlbumCard>;
    } catch (_) {}
    return model.collection
        .where((c) => c.card != null)
        .map((c) => c.card!)
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Legendarios ──
          _CategoryRow(
            label: 'LEGENDARIOS',
            subtitle: '5 ÁLBUMES',
            accentColor: const Color(0xFFa599d9),
            spineColor: const Color(0xFF5b4fd8),
            coverBg: const Color(0xFF1a1726),
            albumCount: 5,
            completedCount: _legendaryCompleted(),
            onTap: () => _openCategorySheet(
              context: context,
              ref: ref,
              tab: 'legendary',
              model: model,
              allCards: _allCards(),
            ),
            coverChild: const _BoltPainterWidget(accent: Color(0xFF34d399)),
          ),

          const SizedBox(height: 10),

          // ── Estrellas ──
          _CategoryRow(
            label: 'ESTRELLAS',
            subtitle: '5 ÁLBUMES',
            accentColor: const Color(0xFFa599d9),
            spineColor: const Color(0xFF7c3aed),
            coverBg: const Color(0xFF160e2a),
            albumCount: 5,
            completedCount: _starsCompleted(),
            onTap: () => _openCategorySheet(
              context: context,
              ref: ref,
              tab: 'stars',
              model: model,
              allCards: _allCards(),
            ),
            coverChild: const _CrownPainterWidget(accent: Color(0xFFa599d9)),
          ),

          const SizedBox(height: 10),

          // ── Culto ──
          _CategoryRow(
            label: 'DE CULTO',
            subtitle: '3 ÁLBUMES',
            accentColor: const Color(0xFFf59e0b),
            spineColor: const Color(0xFFb45309),
            coverBg: const Color(0xFF1a1200),
            albumCount: 3,
            completedCount: _cultCompleted(),
            onTap: () => _openCategorySheet(
              context: context,
              ref: ref,
              tab: 'cult',
              model: model,
              allCards: _allCards(),
            ),
            coverChild: const _GlobePainterWidget(accent: Color(0xFFf59e0b)),
          ),
        ],
      ),
    );
  }

  void _openCategorySheet({
    required BuildContext context,
    required WidgetRef ref,
    required String tab,
    required AlbumsModel model,
    required List<AlbumCard> allCards,
  }) {
    ref.read(albumsTabProvider.notifier).set(tab);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(tab: tab, model: model, allCards: allCards),
    );
  }
}

// ── Bottom sheet con la sección expandida ─────────────────
class _CategorySheet extends StatelessWidget {
  final String tab;
  final AlbumsModel model;
  final List<AlbumCard> allCards;

  const _CategorySheet({
    required this.tab,
    required this.model,
    required this.allCards,
  });

  String get _title => switch (tab) {
        'legendary' => 'LEGENDARIOS',
        'stars' => 'ESTRELLAS',
        'cult' => 'DE CULTO',
        _ => '',
      };

  Color get _accent => switch (tab) {
        'legendary' => const Color(0xFFa599d9),
        'stars'     => const Color(0xFFa599d9),
        'cult'      => const Color(0xFFf59e0b),
        _           => GsColors.accent,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: GsColors.bg,
        border: Border(top: BorderSide(color: GsColors.border, width: 2)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: GsColors.borderSub,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: GsColors.bgCard,
              border: Border(
                bottom: BorderSide(color: GsColors.border, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Container(width: 4, color: _accent),
                const SizedBox(width: 12),
                Text(
                  _title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: _accent,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: GsColors.cream,
                      border: Border.all(color: GsColors.border, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: GsColors.shadow,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: GsColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Expanded(
            child: switch (tab) {
              'legendary' => LegendarySection(
                  definitions: model.legendaryAlbums,
                  progress: model.progressByAlbumId.values.toList(),
                  collection: model.collection,
                ),
              'stars' => StarsSection(
                  collection: model.collection,
                  allCards: allCards,
                ),
              'cult' => CultSection(
                  definitions: model.cultAlbums,
                  collection: model.collection,
                  allCards: allCards,
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FILA DE CATEGORÍA
// ═══════════════════════════════════════════════════════════
class _CategoryRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color accentColor;
  final Color spineColor;
  final Color coverBg;
  final int albumCount;
  final int completedCount;
  final VoidCallback onTap;
  final Widget coverChild;

  const _CategoryRow({
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.spineColor,
    required this.coverBg,
    required this.albumCount,
    required this.completedCount,
    required this.onTap,
    required this.coverChild,
  });

  double get _pct =>
      albumCount > 0 ? (completedCount / albumCount).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: GsColors.card,
        border: Border.all(color: GsColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: GsColors.shadow, offset: Offset(3, 3)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Portada del libro ──
            _BookCover(
              spine: spineColor,
              bg: coverBg,
              accent: accentColor,
              child: coverChild,
            ),

            // ── Info ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 0, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: GsColors.text,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AlbumStatusRow(
                      total: albumCount,
                      completed: completedCount,
                      accent: accentColor,
                    ),
                    const SizedBox(height: 8),
                    _ProgressBar(pct: _pct, accent: accentColor),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completedCount / $albumCount COMPLETADOS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: accentColor,
                          ),
                        ),
                        Text(
                          '${(_pct * 100).round()}%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Flecha ──
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: GsColors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: GsColors.cream,
                    border: Border.all(color: GsColors.border, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: GsColors.shadow, offset: Offset(2, 2)),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: GsColors.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PORTADA DEL LIBRO
// ═══════════════════════════════════════════════════════════
class _BookCover extends StatelessWidget {
  final Color spine;
  final Color bg;
  final Color accent;
  final Widget child;

  const _BookCover({
    required this.spine,
    required this.bg,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 114,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Páginas traseras (efecto pila)
          Positioned(
            top: 8, left: 10,
            child: Container(
              width: 72, height: 100,
              color: bg.withValues(alpha: 0.45),
            ),
          ),
          Positioned(
            top: 4, left: 6,
            child: Container(
              width: 72, height: 100,
              color: bg.withValues(alpha: 0.65),
            ),
          ),
          // Libro principal
          Positioned(
            top: 0, left: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lomo
                Container(
                  width: 9,
                  height: 106,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        spine.withValues(alpha: 0.7),
                        spine,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 20,
                        width: 2,
                        margin: const EdgeInsets.only(bottom: 6),
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ],
                  ),
                ),
                // Tapa
                Container(
                  width: 70,
                  height: 106,
                  color: bg,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withValues(alpha: 0.10),
                                Colors.transparent,
                                accent.withValues(alpha: 0.04),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(child: child),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          height: 3,
                          color: spine.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
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

// ═══════════════════════════════════════════════════════════
// CHECKBOXES DE ESTADO
// ═══════════════════════════════════════════════════════════
class _AlbumStatusRow extends StatelessWidget {
  final int total;
  final int completed;
  final Color accent;

  const _AlbumStatusRow({
    required this.total,
    required this.completed,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final done = i < completed;
        return Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(
            color: done ? accent : GsColors.cream,
            border: Border.all(
              color: done ? accent : GsColors.border,
              width: 1.5,
            ),
            boxShadow: done
                ? const [BoxShadow(color: GsColors.shadow, offset: Offset(1, 1))]
                : null,
          ),
          child: Icon(
            done ? Icons.check : Icons.lock_outline,
            size: 13,
            color: done ? Colors.white : GsColors.muted,
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BARRA DE PROGRESO
// ═══════════════════════════════════════════════════════════
class _ProgressBar extends StatelessWidget {
  final double pct;
  final Color accent;

  const _ProgressBar({required this.pct, required this.accent});

  @override
  Widget build(BuildContext context) {
    // No usamos LayoutBuilder — es incompatible con IntrinsicHeight
    return SizedBox(
      height: 6,
      child: LinearProgressIndicator(
        value: pct,
        backgroundColor: GsColors.cream,
        valueColor: AlwaysStoppedAnimation<Color>(accent),
        minHeight: 6,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// COVER PAINTERS
// ═══════════════════════════════════════════════════════════

// ── Rayo (Legendarios) ────────────────────────────────────
class _BoltPainterWidget extends StatelessWidget {
  final Color accent;
  const _BoltPainterWidget({required this.accent});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BoltPainter(accent: accent));
}

class _BoltPainter extends CustomPainter {
  final Color accent;
  const _BoltPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: 0.20), accent.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 32));
    canvas.drawCircle(Offset(cx, cy), 32, glowPaint);

    final ringPaint = Paint()
      ..color = accent.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final r in [26.0, 18.0]) {
      canvas.drawCircle(Offset(cx, cy), r, ringPaint);
    }

    final fill = Paint()
      ..color = accent.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(cx + 7, cy - 22)
      ..lineTo(cx - 5, cy - 2)
      ..lineTo(cx + 4, cy - 2)
      ..lineTo(cx - 7, cy + 22)
      ..lineTo(cx + 5, cy + 2)
      ..lineTo(cx - 4, cy + 2)
      ..close();

    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_BoltPainter old) => old.accent != accent;
}

// ── Corona (Estrellas) ────────────────────────────────────
class _CrownPainterWidget extends StatelessWidget {
  final Color accent;
  const _CrownPainterWidget({required this.accent});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _CrownPainter(accent: accent));
}

class _CrownPainter extends CustomPainter {
  final Color accent;
  const _CrownPainter({required this.accent});

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    const pts = 5;
    final path = Path();
    for (int i = 0; i < pts * 2; i++) {
      final angle = (i / (pts * 2)) * 2 * math.pi - math.pi / 2;
      final r = i.isEven ? size : size * 0.45;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 32));
    canvas.drawCircle(Offset(cx, cy), 32, glowPaint);

    final hexPaint = Paint()
      ..color = accent.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final hexStroke = Paint()
      ..color = accent.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * math.pi - math.pi / 6;
      final x = cx + 22 * math.cos(angle);
      final y = cy + 22 * math.sin(angle);
      if (i == 0) hexPath.moveTo(x, y);
      else hexPath.lineTo(x, y);
    }
    hexPath.close();
    canvas.drawPath(hexPath, hexPaint);
    canvas.drawPath(hexPath, hexStroke);

    final crownFill = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final crownStroke = Paint()
      ..color = accent.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;

    final crown = Path()
      ..moveTo(cx - 14, cy + 8)
      ..lineTo(cx - 14, cy - 10)
      ..lineTo(cx - 7, cy - 2)
      ..lineTo(cx, cy - 14)
      ..lineTo(cx + 7, cy - 2)
      ..lineTo(cx + 14, cy - 10)
      ..lineTo(cx + 14, cy + 8)
      ..close();

    canvas.drawPath(crown, crownFill);
    canvas.drawPath(crown, crownStroke);

    final dotPaint = Paint()
      ..color = accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 14, cy - 10), 2.2, dotPaint);
    canvas.drawCircle(Offset(cx, cy - 14), 2.2, dotPaint);
    canvas.drawCircle(Offset(cx + 14, cy - 10), 2.2, dotPaint);

    _drawStar(canvas, Offset(cx, cy + 1), 4.5,
        Paint()..color = accent.withValues(alpha: 0.75));
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.accent != accent;
}

// ── Globo/Red (De Culto) ──────────────────────────────────
class _GlobePainterWidget extends StatelessWidget {
  final Color accent;
  const _GlobePainterWidget({required this.accent});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GlobePainter(accent: accent));
}

class _GlobePainter extends CustomPainter {
  final Color accent;
  const _GlobePainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 20.0;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: 0.20), accent.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 32));
    canvas.drawCircle(Offset(cx, cy), 32, glowPaint);

    final fill = Paint()
      ..color = accent.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset(cx, cy), r, fill);
    canvas.drawCircle(Offset(cx, cy), r, stroke);

    final thinStroke = Paint()
      ..color = accent.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), thinStroke);
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), thinStroke);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 0.9, height: r * 2),
      thinStroke,
    );

    for (final offset in [-8.0, 8.0]) {
      final halfW = math.sqrt(r * r - offset * offset);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + offset),
          width: halfW * 1.9,
          height: 5,
        ),
        thinStroke,
      );
    }

    final shieldFill = Paint()
      ..color = accent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final shieldStroke = Paint()
      ..color = accent.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final shield = Path()
      ..moveTo(cx, cy - 11)
      ..lineTo(cx + 8, cy - 6)
      ..lineTo(cx + 8, cy + 2)
      ..quadraticBezierTo(cx + 8, cy + 10, cx, cy + 14)
      ..quadraticBezierTo(cx - 8, cy + 10, cx - 8, cy + 2)
      ..lineTo(cx - 8, cy - 6)
      ..close();

    canvas.drawPath(shield, shieldFill);
    canvas.drawPath(shield, shieldStroke);
  }

  @override
  bool shouldRepaint(_GlobePainter old) => old.accent != accent;
}