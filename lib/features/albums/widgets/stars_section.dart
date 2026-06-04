import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;
import '../domain/albums_model.dart';
import 'album_book_card.dart';
import 'album_panel_modal.dart';

const Map<int, _StarMeta> _starMeta = {
  1: _StarMeta(
    level: 1,
    label: 'Actuales Relevantes',
    shortLabel: 'EST I',
    tag: 'NIVEL 1',
    number: '01',
    spine: Color(0xFFe55b5b), spineAlt: Color(0xFFb83b3b),
    accent: Color(0xFFf87171), coverBg: Color(0xFF1a0f0f),
    rarityLabel: 'ACTUAL',
  ),
  2: _StarMeta(
    level: 2,
    label: 'Momentos Puntuales',
    shortLabel: 'EST II',
    tag: 'NIVEL 2',
    number: '02',
    spine: Color(0xFF5b4fd8), spineAlt: Color(0xFF3d34a5),
    accent: Color(0xFFa599d9), coverBg: Color(0xFF0f0d1a),
    rarityLabel: 'MOMENTO',
  ),
  3: _StarMeta(
    level: 3,
    label: 'Culto y Distinción',
    shortLabel: 'EST III',
    tag: 'NIVEL 3',
    number: '03',
    spine: Color(0xFF1D9E75), spineAlt: Color(0xFF0d6e50),
    accent: Color(0xFF34d399), coverBg: Color(0xFF0a1f18),
    rarityLabel: 'CULTO',
  ),
  4: _StarMeta(
    level: 4,
    label: 'Leyendas',
    shortLabel: 'EST IV',
    tag: 'NIVEL 4',
    number: '04',
    spine: Color(0xFF7c3aed), spineAlt: Color(0xFF5b21b6),
    accent: Color(0xFFc4b5fd), coverBg: Color(0xFF160e2a),
    rarityLabel: 'LEYENDA',
  ),
  5: _StarMeta(
    level: 5,
    label: 'GOAT',
    shortLabel: 'GOAT',
    tag: 'ESPECIAL',
    number: '✦',
    spine: Color(0xFFb45309), spineAlt: Color(0xFF7c3b00),
    accent: Color(0xFFf59e0b), coverBg: Color(0xFF1a1200),
    rarityLabel: 'GOAT',
    golden: true,
  ),
};

class _StarMeta {
  final int level;
  final String label, shortLabel, tag, number, rarityLabel;
  final Color spine, spineAlt, accent, coverBg;
  final bool golden;

  const _StarMeta({
    required this.level,
    required this.label,
    required this.shortLabel,
    required this.tag,
    required this.number,
    required this.rarityLabel,
    required this.spine,
    required this.spineAlt,
    required this.accent,
    required this.coverBg,
    this.golden = false,
  });
}

// ── Widget público ────────────────────────────────────────
class StarsSection extends StatelessWidget {
  final List<AlbumCollectionItem> collection;
  final List<AlbumCard> allCards;

  const StarsSection({
    super.key,
    required this.collection,
    required this.allCards,
  });

  List<AlbumCollectionItem> _ownedByLevel(int level) {
    return collection
        .where((c) =>
            c.card?.cardType == 'player' &&
            c.card?.significanceLevel == level)
        .toList();
  }

  int _totalByLevel(int level) {
    return allCards
        .where((c) => c.cardType == 'player' && c.significanceLevel == level)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [1, 2, 3, 4, 5].map((level) {
          final meta = _starMeta[level]!;
          final owned = _ownedByLevel(level);
          final total = _totalByLevel(level);
          final pct = total > 0 ? (owned.length / total).clamp(0.0, 1.0) : 0.0;
          final completed = total > 0 && owned.length >= total;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _StarBookWithPanel(
              meta: meta,
              owned: owned,
              allCards: allCards,
              total: total,
              pct: pct,
              completed: completed,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Libro + panel ─────────────────────────────────────────
class _StarBookWithPanel extends StatelessWidget {
  final _StarMeta meta;
  final List<AlbumCollectionItem> owned;
  final List<AlbumCard> allCards;
  final int total;
  final double pct;
  final bool completed;

  const _StarBookWithPanel({
    required this.meta,
    required this.owned,
    required this.allCards,
    required this.total,
    required this.pct,
    required this.completed,
  });

  List<({String slotType, AlbumCollectionItem? item})> _buildSlots() {
    return List.generate(total > 0 ? total : 10, (i) {
      final item = i < owned.length ? owned[i] : null;
      return (slotType: 'general', item: item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlbumBookCard(
      albumId: 'stars_${meta.level}',
      shortLabel: meta.shortLabel,
      number: meta.number,
      tag: meta.tag,
      spine: meta.spine,
      spineAlt: meta.spineAlt,
      accent: meta.accent,
      coverBg: meta.coverBg,
      filled: owned.length,
      total: total > 0 ? total : 0,
      pct: pct,
      locked: false,
      completed: completed,
      coverIllustration: _StarCoverArt(level: meta.level, accent: meta.accent),
      onTap: () => showAlbumPanel(
        context: context,
        albumId: 'stars_${meta.level}',
        name: meta.label,
        shortLabel: meta.shortLabel,
        tag: meta.tag,
        spine: meta.spine,
        accent: meta.accent,
        coverBg: meta.coverBg,
        filled: owned.length,
        slots: total > 0 ? total : 10,
        pct: pct,
        collection: owned,
        allSlots: _buildSlots(),
      ),
    );
  }
}

// ── Arte de portada por nivel (CustomPaint) ───────────────
class _StarCoverArt extends StatelessWidget {
  final int level;
  final Color accent;
  const _StarCoverArt({required this.level, required this.accent});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarArtPainter(level: level, accent: accent),
    );
  }
}

class _StarArtPainter extends CustomPainter {
  final int level;
  final Color accent;
  const _StarArtPainter({required this.level, required this.accent});

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    const points = 5;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (i / (points * 2)) * 2 * math.pi - math.pi / 2;
      final r = i.isEven ? size : size * 0.45;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 5;

    // Círculos decorativos
    final ringPaint = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (final r in [28.0, 20.0, 13.0]) {
      canvas.drawCircle(Offset(cx, cy), r, ringPaint);
    }

    // Estrellas
    final starPaint = Paint()
      ..color = accent.withValues(alpha: level == 5 ? 0.9 : 0.65)
      ..style = PaintingStyle.fill;

    final count = level.clamp(1, 5);
    final orbitR = count == 1 ? 0.0 : 18.0;

    for (int i = 0; i < count; i++) {
      final angle = count == 1
          ? -math.pi / 2
          : (i / count) * 2 * math.pi - math.pi / 2;
      final sx = cx + orbitR * math.cos(angle);
      final sy = cy + orbitR * math.sin(angle);
      _drawStar(canvas, Offset(sx, sy), count == 1 ? 12.0 : 7.0, starPaint);
    }
  }

  @override
  bool shouldRepaint(_StarArtPainter old) =>
      old.level != level || old.accent != accent;
}
