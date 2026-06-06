import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show Ds, GsColors;
import '../domain/albums_model.dart';

// ════════════════════════════════════════════════════════════
//  STICKER CARD — LIGHT NEOBRUTALISTA
//  (API y lógica interna 100% intactas)
// ════════════════════════════════════════════════════════════
class StickerCard extends StatelessWidget {
  final int                index;
  final AlbumCard?         card;
  final AlbumCollectionItem? collectionItem;
  final Color              accent;
  final String             slotType; // 'req5'|'req4'|'req3'|'req2'|'general'

  const StickerCard({
    super.key,
    required this.index,
    this.card,
    this.collectionItem,
    required this.accent,
    this.slotType = 'general',
  });

  // ── helpers (sin cambios) ─────────────────────────────────
  bool get _isReqSlot => slotType != 'general';
  bool get _isFilled  => collectionItem != null;
  bool get _isGoat    => card?.isGoat == true;

  bool get _isNew {
    if (collectionItem == null) return false;
    final last = DateTime.tryParse(collectionItem!.lastObtainedAt);
    if (last == null) return false;
    return DateTime.now().difference(last).inHours < 48;
  }

  int get _reqStars => switch (slotType) {
        'req5' => 5,
        'req4' => 4,
        'req3' => 3,
        'req2' => 2,
        _      => 0,
      };

  String get _num => (index + 1).toString().padLeft(3, '0');

  @override
  Widget build(BuildContext context) {
    if (_isFilled) return _FilledCard(w: this);
    if (_isReqSlot) return _SecretCard(w: this);
    return _EmptyCard(w: this);
  }
}

// ════════════════════════════════════════════════════════════
//  CARTA OBTENIDA
// ════════════════════════════════════════════════════════════
class _FilledCard extends StatelessWidget {
  final StickerCard w;
  const _FilledCard({required this.w});

  @override
  Widget build(BuildContext context) {
    final stars  = w.card?.significanceLevel ?? 0;
    final copies = w.collectionItem?.copies ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: w._isGoat ? Ds.gold : Ds.borderSub,
          width: w._isGoat ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: w._isGoat
                ? Ds.gold.withValues(alpha: 0.25)
                : const Color(0xFFB0AAA0),
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Franja de color
          Container(
            height: 3,
            color: w._isGoat ? Ds.gold : w.accent,
          ),

          // Header: número / NUEVO + checkmark
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 3, 4, 0),
            child: Row(
              children: [
                if (!w._isNew)
                  Text(
                    w._num,
                    style: TextStyle(
                      fontFamily: GsColors.fontMono,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      color: w.accent.withValues(alpha: 0.8),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    color: w.accent,
                    child: const Text(
                      'NUEVO',
                      style: TextStyle(
                        fontFamily: GsColors.fontMono,
                        fontSize: 5.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                const Spacer(),
                // Badge ✓
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: w._isGoat ? Ds.gold : w.accent,
                  ),
                  child: const Icon(Icons.check, size: 9, color: Colors.white),
                ),
              ],
            ),
          ),

          // Avatar circular
          Expanded(
            child: Center(
              child: _AvatarCircle(
                imagePath: w.card?.imagePath,
                name:      w.card?.name ?? '',
                accent:    w.accent,
                isGoat:    w._isGoat,
              ),
            ),
          ),

          // Nombre
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 0, 3, 2),
            child: Text(
              (w.card?.name ?? '').toUpperCase(),
              maxLines: 2,
              overflow:  TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily:  GsColors.fontMono,
                fontSize:    7,
                fontWeight:  FontWeight.w900,
                color:       Ds.ink,
                height:      1.2,
                letterSpacing: 0.2,
              ),
            ),
          ),

          // Estrellas
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _Stars(filled: stars, accent: w.accent),
          ),

          // Badge de copias extra
          if (copies > 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              color: w.accent.withValues(alpha: 0.1),
              child: Text(
                '×$copies',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GsColors.fontMono,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: w.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CARTA SECRETA / SLOT REQUERIDO VACÍO
// ════════════════════════════════════════════════════════════
class _SecretCard extends StatelessWidget {
  final StickerCard w;
  const _SecretCard({required this.w});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: w.accent.withValues(alpha: 0.45),
      ),
      child: Container(
        color: w.accent.withValues(alpha: 0.04),
        child: Column(
          children: [
            // Franja tenue
            Container(height: 3, color: w.accent.withValues(alpha: 0.25)),

            // Número
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 3, 4, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  w._num,
                  style: TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: w.accent.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),

            // Icono de candado
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: w.accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: w.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'LEYENDA\nSECRETA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: GsColors.fontMono,
                        fontSize: 6.5,
                        fontWeight: FontWeight.w700,
                        color: w.accent.withValues(alpha: 0.5),
                        letterSpacing: 0.3,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Estrellas vacías (indica rareza requerida)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: _Stars(
                filled: 0,
                total:  w._reqStars > 0 ? w._reqStars : 5,
                accent: w.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CARTA VACÍA GENÉRICA
// ════════════════════════════════════════════════════════════
class _EmptyCard extends StatelessWidget {
  final StickerCard w;
  const _EmptyCard({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Ds.bgCard,
        border: Border.all(color: Ds.borderSub, width: 1),
      ),
      child: Column(
        children: [
          Container(height: 3, color: Ds.borderSub),

          Padding(
            padding: const EdgeInsets.fromLTRB(4, 3, 4, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                w._num,
                style: const TextStyle(
                  fontFamily: GsColors.fontMono,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: Ds.muted,
                ),
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: Icon(
                Icons.person_outline,
                size: 28,
                color: Ds.muted.withValues(alpha: 0.3),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(3, 0, 3, 2),
            child: const Text(
              '???',
              style: TextStyle(
                fontFamily:  GsColors.fontMono,
                fontSize:    7,
                fontWeight:  FontWeight.w900,
                color:       Ds.muted,
                letterSpacing: 2,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: _Stars(filled: 0, accent: Ds.borderSub),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  AVATAR CIRCULAR
// ════════════════════════════════════════════════════════════
class _AvatarCircle extends StatelessWidget {
  final String? imagePath;
  final String  name;
  final Color   accent;
  final bool    isGoat;

  const _AvatarCircle({
    required this.imagePath,
    required this.name,
    required this.accent,
    required this.isGoat,
  });

  String _initials() {
    final parts = name.split(' ');
    return parts.take(2).map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo GOAT exterior
        if (isGoat)
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Ds.gold.withValues(alpha: 0.45),
                width: 2,
              ),
            ),
          ),

        // Anillo principal
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isGoat ? Ds.gold : accent.withValues(alpha: 0.5),
              width: isGoat ? 2 : 1.2,
            ),
          ),
        ),

        // Imagen o iniciales
        ClipOval(
          child: Container(
            width: 36, height: 36,
            color: accent.withValues(alpha: 0.08),
            child: imagePath != null
                ? Image.network(
                    imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _Initials(
                      text:   _initials(),
                      accent: accent,
                    ),
                  )
                : _Initials(text: _initials(), accent: accent),
          ),
        ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  final Color  accent;
  const _Initials({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text.isEmpty ? '?' : text,
        style: TextStyle(
          fontFamily:  GsColors.fontMono,
          fontSize:    12,
          fontWeight:  FontWeight.w900,
          color:       accent,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ESTRELLAS
// ════════════════════════════════════════════════════════════
class _Stars extends StatelessWidget {
  final int   filled;
  final int   total;
  final Color accent;

  const _Stars({
    required this.filled,
    this.total = 5,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final on = i < filled;
        return Text(
          '★',
          style: TextStyle(
            fontSize: 8,
            color: on
                ? (filled >= 5 ? Ds.gold : accent)
                : Ds.borderSub,
          ),
        );
      }),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  DASHED BORDER PAINTER (para cartas secretas)
// ════════════════════════════════════════════════════════════
class _DashedBorderPainter extends CustomPainter {
  final Color  color;
  final double strokeWidth;
  final double dashLen;
  final double gapLen;

  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.4,
    this.dashLen     = 4.0,
    this.gapLen      = 3.0,
  });

  void _dash(Canvas canvas, Paint paint, Offset a, Offset b) {
    final dx  = b.dx - a.dx;
    final dy  = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final nx  = dx / len;
    final ny  = dy / len;
    double d  = 0;
    bool draw = true;

    while (d < len) {
      final seg = draw ? dashLen : gapLen;
      final end = math.min(d + seg, len);
      if (draw) {
        canvas.drawLine(
          Offset(a.dx + nx * d,   a.dy + ny * d),
          Offset(a.dx + nx * end, a.dy + ny * end),
          paint,
        );
      }
      d    = end;
      draw = !draw;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color
      ..strokeWidth = strokeWidth
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    _dash(canvas, paint, Offset.zero,                Offset(size.width, 0));
    _dash(canvas, paint, Offset(size.width, 0),      Offset(size.width, size.height));
    _dash(canvas, paint, Offset(size.width, size.height), Offset(0, size.height));
    _dash(canvas, paint, Offset(0, size.height),     Offset.zero);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}