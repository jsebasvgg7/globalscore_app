import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;
import '../domain/albums_model.dart';
import 'album_book_card.dart';
import 'album_panel_modal.dart';

const Map<String, _CultMeta> _cultMeta = {
  'cult_teams': _CultMeta(
    id: 'cult_teams',
    label: 'Equipos Históricos',
    shortLabel: 'EQUIPOS',
    tag: 'CULTO · EQUIPOS',
    number: '01',
    cardType: 'team',
    icon: Icons.shield_outlined,
    spine: Color(0xFF5b4fd8), spineAlt: Color(0xFF3d34a5),
    accent: Color(0xFFa599d9), coverBg: Color(0xFF0f0d1a),
    rarityLabel: 'HISTÓRICO',
  ),
  'cult_competitions': _CultMeta(
    id: 'cult_competitions',
    label: 'Competiciones Históricas',
    shortLabel: 'COPAS',
    tag: 'CULTO · COPAS',
    number: '02',
    cardType: 'competition',
    icon: Icons.emoji_events_outlined,
    spine: Color(0xFFf59e0b), spineAlt: Color(0xFFb45309),
    accent: Color(0xFFf59e0b), coverBg: Color(0xFF1a1200),
    rarityLabel: 'LEGENDARIO',
  ),
  'cult_events': _CultMeta(
    id: 'cult_events',
    label: 'Eventos Históricos',
    shortLabel: 'EVENTOS',
    tag: 'CULTO · MOMENTOS',
    number: '03',
    cardType: 'event',
    icon: Icons.bolt_outlined,
    spine: Color(0xFF1D9E75), spineAlt: Color(0xFF0d6e50),
    accent: Color(0xFF34d399), coverBg: Color(0xFF0a1f18),
    rarityLabel: 'ÉPICO',
  ),
};

const _kCultOrder = ['cult_teams', 'cult_competitions', 'cult_events'];

class _CultMeta {
  final String id, label, shortLabel, tag, number, cardType, rarityLabel;
  final IconData icon;
  final Color spine, spineAlt, accent, coverBg;

  const _CultMeta({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.tag,
    required this.number,
    required this.cardType,
    required this.icon,
    required this.rarityLabel,
    required this.spine,
    required this.spineAlt,
    required this.accent,
    required this.coverBg,
  });
}

// ── Widget público ────────────────────────────────────────
class CultSection extends StatelessWidget {
  final List<AlbumDefinition> definitions;
  final List<AlbumCollectionItem> collection;
  final List<AlbumCard> allCards;

  const CultSection({
    super.key,
    required this.definitions,
    required this.collection,
    required this.allCards,
  });

  List<AlbumCollectionItem> _ownedByType(String cardType) {
    return collection
        .where((c) => c.card?.cardType == cardType)
        .toList();
  }

  int _totalByType(String cardType) {
    return allCards.where((c) => c.cardType == cardType).length;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _kCultOrder.map((id) {
          final meta = _cultMeta[id];
          if (meta == null) return const SizedBox.shrink();

          final owned = _ownedByType(meta.cardType);
          final total = _totalByType(meta.cardType);
          final pct = total > 0 ? (owned.length / total).clamp(0.0, 1.0) : 0.0;
          final completed = total > 0 && owned.length >= total;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CultBookWithPanel(
              meta: meta,
              owned: owned,
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
class _CultBookWithPanel extends StatelessWidget {
  final _CultMeta meta;
  final List<AlbumCollectionItem> owned;
  final int total;
  final double pct;
  final bool completed;

  const _CultBookWithPanel({
    required this.meta,
    required this.owned,
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
      albumId: meta.id,
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
      coverIllustration: _CultCoverArt(meta: meta),
      onTap: () => showAlbumPanel(
        context: context,
        albumId: meta.id,
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

// ── Arte de portada Cult ──────────────────────────────────
class _CultCoverArt extends StatelessWidget {
  final _CultMeta meta;
  const _CultCoverArt({required this.meta});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CultArtPainter(meta: meta),
    );
  }
}

class _CultArtPainter extends CustomPainter {
  final _CultMeta meta;
  const _CultArtPainter({required this.meta});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 5;
    final accent = meta.accent;

    // Fondo glow radial
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.15),
          accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 36));
    canvas.drawCircle(Offset(cx, cy), 36, glowPaint);

    if (meta.id == 'cult_teams') {
      _drawShield(canvas, Offset(cx, cy), accent);
    } else if (meta.id == 'cult_competitions') {
      _drawTrophy(canvas, Offset(cx, cy), accent);
    } else {
      _drawBolt(canvas, Offset(cx, cy), accent);
    }
  }

  void _drawShield(Canvas canvas, Offset c, Color accent) {
    final fill = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(c.dx, c.dy - 18)
      ..lineTo(c.dx + 14, c.dy - 10)
      ..lineTo(c.dx + 14, c.dy + 4)
      ..quadraticBezierTo(c.dx + 14, c.dy + 16, c.dx, c.dy + 22)
      ..quadraticBezierTo(c.dx - 14, c.dy + 16, c.dx - 14, c.dy + 4)
      ..lineTo(c.dx - 14, c.dy - 10)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    // Cruz
    final cross = Paint()
      ..color = accent.withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    canvas.drawLine(
        Offset(c.dx, c.dy - 14), Offset(c.dx, c.dy + 16), cross);
    canvas.drawLine(
        Offset(c.dx - 12, c.dy), Offset(c.dx + 12, c.dy), cross);
  }

  void _drawTrophy(Canvas canvas, Offset c, Color accent) {
    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(c.dx - 12, c.dy - 14)
      ..lineTo(c.dx + 12, c.dy - 14)
      ..lineTo(c.dx + 12, c.dy - 2)
      ..quadraticBezierTo(c.dx + 12, c.dy + 10, c.dx, c.dy + 16)
      ..quadraticBezierTo(c.dx - 12, c.dy + 10, c.dx - 12, c.dy - 2)
      ..close();

    canvas.drawPath(path, stroke);

    // Asas
    canvas.drawArc(
      Rect.fromCenter(center: Offset(c.dx - 14, c.dy - 6), width: 8, height: 12),
      math.pi / 2, math.pi, false, stroke);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(c.dx + 14, c.dy - 6), width: 8, height: 12),
      -math.pi / 2, math.pi, false, stroke);

    // Base
    canvas.drawLine(Offset(c.dx, c.dy + 16), Offset(c.dx, c.dy + 22), stroke);
    canvas.drawLine(Offset(c.dx - 10, c.dy + 22), Offset(c.dx + 10, c.dy + 22), stroke);

    // Estrella interna
    _drawStar(canvas, c, 5.0,
        Paint()..color = accent.withValues(alpha: 0.7));
  }

  void _drawBolt(Canvas canvas, Offset c, Color accent) {
    final fill = Paint()
      ..color = accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(c.dx + 6, c.dy - 20)
      ..lineTo(c.dx - 4, c.dy - 2)
      ..lineTo(c.dx + 3, c.dy - 2)
      ..lineTo(c.dx - 6, c.dy + 20)
      ..lineTo(c.dx + 4, c.dy + 2)
      ..lineTo(c.dx - 3, c.dy + 2)
      ..close();

    canvas.drawPath(path, fill);
  }

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
  bool shouldRepaint(_CultArtPainter old) => old.meta.id != meta.id;
}
