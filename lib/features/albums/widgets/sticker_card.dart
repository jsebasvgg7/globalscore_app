import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;
import '../domain/albums_model.dart';

// ════════════════════════════════════════════════════════════
//  STICKER CARD
//  Carta individual usada en album_panel_modal, stars y cult
// ════════════════════════════════════════════════════════════

class StickerCard extends StatelessWidget {
  final int index;
  final AlbumCard? card;
  final AlbumCollectionItem? collectionItem;
  final Color accent;
  final String slotType; // 'req5' | 'req4' | 'req3' | 'req2' | 'general'

  const StickerCard({
    super.key,
    required this.index,
    this.card,
    this.collectionItem,
    required this.accent,
    this.slotType = 'general',
  });

  bool get _isReqSlot => slotType != 'general';
  bool get _isFilled => collectionItem != null;
  bool get _isGoat => card?.isGoat == true;

  int get _reqStars => switch (slotType) {
        'req5' => 5,
        'req4' => 4,
        'req3' => 3,
        'req2' => 2,
        _ => 0,
      };

  String get _num => (index + 1).toString().padLeft(3, '0');

  @override
  Widget build(BuildContext context) {
    if (_isFilled) return _FilledSticker(this);
    return _EmptySticker(this);
  }
}

// ── Carta con contenido ───────────────────────────────────
class _FilledSticker extends StatelessWidget {
  final StickerCard w;
  const _FilledSticker(this.w);

  @override
  Widget build(BuildContext context) {
    final stars = w.card?.significanceLevel ?? 0;
    final copies = w.collectionItem?.copies ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A14),
        border: Border.all(
          color: w._isGoat
              ? GsColors.gold
              : w.accent.withValues(alpha: 0.5),
          width: w._isGoat ? 1.8 : 1.2,
        ),
        boxShadow: w._isGoat
            ? [
                BoxShadow(
                  color: GsColors.gold.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Fondo gradiente del accent
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    w.accent.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              // Banda top
              Container(
                height: 3,
                color: w.accent,
              ),

              // Header: número + copias
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Row(
                  children: [
                    Text(
                      w._num,
                      style: TextStyle(
                        fontFamily: GsColors.fontMono,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: w.accent.withValues(alpha: 0.7),
                      ),
                    ),
                    const Spacer(),
                    if (copies > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 1),
                        color: w.accent.withValues(alpha: 0.2),
                        child: Text(
                          '×$copies',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            color: w.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Avatar zone
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _AvatarZone(
                    imagePath: w.card?.imagePath,
                    name: w.card?.name ?? '',
                    accent: w.accent,
                    isGoat: w._isGoat,
                  ),
                ),
              ),

              // Estrellas
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: _Stars(filled: stars, accent: w.accent),
              ),

              // Nombre
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                child: Text(
                  w.card?.name ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),

          // Foil shimmer overlay
          const Positioned.fill(
            child: _FoilOverlay(),
          ),
        ],
      ),
    );
  }
}

// ── Carta vacía ───────────────────────────────────────────
class _EmptySticker extends StatelessWidget {
  final StickerCard w;
  const _EmptySticker(this.w);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080810),
        border: Border.all(
          color: w._isReqSlot
              ? w.accent.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Row(
              children: [
                Text(
                  w._num,
                  style: const TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Colors.white24,
                  ),
                ),
              ],
            ),
          ),

          // Silueta
          Expanded(
            child: Center(
              child: _SilhouetteIcon(accent: w.accent),
            ),
          ),

          // Stars requeridas (si es slot req)
          if (w._isReqSlot && w._reqStars > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: _Stars(filled: 0, total: w._reqStars, accent: w.accent),
            ),

          // Nombre vacío
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(
              '???',
              style: TextStyle(
                fontFamily: GsColors.fontMono,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.15),
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar con imagen o iniciales ─────────────────────────
class _AvatarZone extends StatelessWidget {
  final String? imagePath;
  final String name;
  final Color accent;
  final bool isGoat;

  const _AvatarZone({
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
        // Anillo exterior
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isGoat ? GsColors.gold : accent.withValues(alpha: 0.6),
              width: isGoat ? 1.5 : 1,
            ),
          ),
        ),

        // Imagen o iniciales
        ClipOval(
          child: Container(
            width: 42,
            height: 42,
            color: accent.withValues(alpha: 0.1),
            child: imagePath != null
                ? Image.network(
                    imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _InitialsBox(
                      text: _initials(),
                      accent: accent,
                    ),
                  )
                : _InitialsBox(text: _initials(), accent: accent),
          ),
        ),

        // Halo GOAT
        if (isGoat)
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: GsColors.gold.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
          ),
      ],
    );
  }
}

class _InitialsBox extends StatelessWidget {
  final String text;
  final Color accent;
  const _InitialsBox({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text.isEmpty ? '?' : text,
        style: TextStyle(
          fontFamily: GsColors.fontMono,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: accent.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

// ── Silueta vacía ─────────────────────────────────────────
class _SilhouetteIcon extends StatelessWidget {
  final Color accent;
  const _SilhouetteIcon({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.22,
      child: Icon(
        Icons.person,
        size: 36,
        color: accent,
      ),
    );
  }
}

// ── Estrellas ─────────────────────────────────────────────
class _Stars extends StatelessWidget {
  final int filled;
  final int total;
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
        return Text(
          '★',
          style: TextStyle(
            fontSize: 8,
            color: i < filled
                ? (filled >= 5 ? GsColors.gold : accent)
                : Colors.white.withValues(alpha: 0.15),
          ),
        );
      }),
    );
  }
}

// ── Foil shimmer overlay ──────────────────────────────────
class _FoilOverlay extends StatelessWidget {
  const _FoilOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.04),
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.4, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}
