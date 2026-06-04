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

  // ── Contadores por categoría ──────────────────────────
  int _legendaryCompleted() => model.progressByAlbumId.values
      .where((p) => p.albumId.startsWith('legendary') && p.isCompleted)
      .length;

  int _starsCompleted() => model.progressByAlbumId.values
      .where((p) => p.albumId.startsWith('stars') && p.isCompleted)
      .length;

  int _cultCompleted() => model.progressByAlbumId.values
      .where((p) => p.albumId.startsWith('cult') && p.isCompleted)
      .length;

  // ── Stats globales para el header ─────────────────────
  int _totalFiguritas() => model.collection.fold(0, (s, c) => s + c.copies);

  int _totalCompleted() =>
      _legendaryCompleted() + _starsCompleted() + _cultCompleted();

  double _globalProgress() {
    const total = 5 + 5 + 3; // 13 álbumes
    final completed = _totalCompleted();
    return completed / total;
  }

  List<AlbumCard> _allCards() {
    try {
      return (model as dynamic).allCards as List<AlbumCard>;
    } catch (_) {}
    return model.collection
        .where((c) => c.card != null)
        .map((c) => c.card!)
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalCompleted = _totalCompleted();
    final figuritas      = _totalFiguritas();
    final globalPct      = _globalProgress();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header "TU COLECCIÓN" con stats ──────────────
        _CollectionHeader(
          figuritas:      figuritas,
          globalPct:      globalPct,
          completedCount: totalCompleted,
        ),

        const SizedBox(height: 14),

        // ── Título sección ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(width: 3, height: 14, color: GsColors.accent),
              const SizedBox(width: 8),
              const Text(
                'TUS COLECCIONES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: GsColors.text,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Filas de categoría ────────────────────────────
        _CategoryRow(
          label:          'LEGENDARIOS',
          subtitle:       '5 ÁLBUMES',
          accentColor:    const Color(0xFFa599d9),
          spineColor:     const Color(0xFF5b4fd8),
          coverBg:        const Color(0xFF1a1726),
          albumCount:     5,
          completedCount: _legendaryCompleted(),
          coverChild:     const _BoltPainterWidget(accent: Color(0xFF34d399)),
          onTap: () => _openCategorySheet(
            context: context, ref: ref,
            tab: 'legendary', model: model, allCards: _allCards(),
          ),
        ),

        const SizedBox(height: 10),

        _CategoryRow(
          label:          'ESTRELLAS',
          subtitle:       '5 ÁLBUMES',
          accentColor:    const Color(0xFFa599d9),
          spineColor:     const Color(0xFF7c3aed),
          coverBg:        const Color(0xFF160e2a),
          albumCount:     5,
          completedCount: _starsCompleted(),
          coverChild:     const _CrownPainterWidget(accent: Color(0xFFa599d9)),
          onTap: () => _openCategorySheet(
            context: context, ref: ref,
            tab: 'stars', model: model, allCards: _allCards(),
          ),
        ),

        const SizedBox(height: 10),

        _CategoryRow(
          label:          'DE CULTO',
          subtitle:       '3 ÁLBUMES',
          accentColor:    const Color(0xFFf59e0b),
          spineColor:     const Color(0xFFb45309),
          coverBg:        const Color(0xFF1a1200),
          albumCount:     3,
          completedCount: _cultCompleted(),
          coverChild:     const _GlobePainterWidget(accent: Color(0xFFf59e0b)),
          onTap: () => _openCategorySheet(
            context: context, ref: ref,
            tab: 'cult', model: model, allCards: _allCards(),
          ),
        ),

        const SizedBox(height: 8),
      ],
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

// ═══════════════════════════════════════════════════════════
//  HEADER — "TU COLECCIÓN" — replica imagen 2
//  Layout: título + VER TODO / fila horizontal 4 stats / barra
// ═══════════════════════════════════════════════════════════
class _CollectionHeader extends StatelessWidget {
  final int    figuritas;
  final double globalPct;
  final int    completedCount;

  const _CollectionHeader({
    required this.figuritas,
    required this.globalPct,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final pctInt      = (globalPct * 100).round();
    final activeCount = 13 - completedCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: GsColors.bg,
        border: Border.all(color: GsColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: GsColors.shadow, offset: Offset(3, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Fila título ───────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Text(
              'TU COLECCIÓN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: GsColors.text,
              ),
            ),
          ),

          // ── Fila de 4 stats horizontales ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // STAT 1 — Álbumes activos (bloque bordeado propio)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: GsColors.bgCard,
                          border: Border.all(
                              color: GsColors.borderSub, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$activeCount',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: GsColors.accent,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'ÁLBUMES\nACTIVOS',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                                color: GsColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Separador
                  Container(width: 1, color: GsColors.borderSub),

                  // STAT 2 — Figuritas (ícono en cuadro bordeado accent)
                  Expanded(
                    child: _HorizStat(
                      iconWidget: _BorderedIcon(
                        icon:        Icons.star,
                        borderColor: GsColors.accent,
                        iconColor:   GsColors.accent,
                      ),
                      value: '$figuritas',
                      label: 'FIGURITAS\nCONSEGUIDAS',
                    ),
                  ),

                  // Separador
                  Container(width: 1, color: GsColors.borderSub),

                  // STAT 3 — Progreso global (ícono check verde bordeado)
                  Expanded(
                    child: _HorizStat(
                      iconWidget: _BorderedIcon(
                        icon:        Icons.check,
                        borderColor: const Color(0xFF22C55E),
                        iconColor:   const Color(0xFF22C55E),
                        filled:      true,
                        fillColor:   const Color(0xFF22C55E),
                        filledIconColor: Colors.white,
                      ),
                      value: '$pctInt%',
                      label: 'PROGRESO\nGLOBAL',
                    ),
                  ),

                  // Separador
                  Container(width: 1, color: GsColors.borderSub),

                  // STAT 4 — Completados (estrella naranja bordeada)
                  Expanded(
                    child: _HorizStat(
                      iconWidget: _BorderedIcon(
                        icon:        Icons.star_border,
                        borderColor: const Color(0xFFf59e0b),
                        iconColor:   const Color(0xFFf59e0b),
                      ),
                      value: '$completedCount',
                      label: 'COMPLETADOS',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Barra de progreso + % ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: LinearProgressIndicator(
              value: globalPct,
              backgroundColor: GsColors.bgSection,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(GsColors.accent),
              minHeight: 7,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$pctInt%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: GsColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat horizontal (ícono arriba + valor + label) ────────
class _HorizStat extends StatelessWidget {
  final Widget iconWidget;
  final String value;
  final String label;

  const _HorizStat({
    required this.iconWidget,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: GsColors.text,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: GsColors.muted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ícono en cuadro con borde de color (o relleno) ────────
class _BorderedIcon extends StatelessWidget {
  final IconData icon;
  final Color    borderColor;
  final Color    iconColor;
  final bool     filled;
  final Color?   fillColor;
  final Color?   filledIconColor;

  const _BorderedIcon({
    required this.icon,
    required this.borderColor,
    required this.iconColor,
    this.filled         = false,
    this.fillColor,
    this.filledIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: filled ? fillColor : Colors.transparent,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Icon(
        icon,
        size: 14,
        color: filled ? (filledIconColor ?? Colors.white) : iconColor,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BOTTOM SHEET CON SECCIÓN EXPANDIDA
// ═══════════════════════════════════════════════════════════
class _CategorySheet extends StatelessWidget {
  final String       tab;
  final AlbumsModel  model;
  final List<AlbumCard> allCards;

  const _CategorySheet({
    required this.tab,
    required this.model,
    required this.allCards,
  });

  String get _title => switch (tab) {
        'legendary' => 'LEGENDARIOS',
        'stars'     => 'ESTRELLAS',
        'cult'      => 'DE CULTO',
        _           => '',
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
                        BoxShadow(color: GsColors.shadow, offset: Offset(2, 2)),
                      ],
                    ),
                    child: const Icon(Icons.close, size: 14, color: GsColors.text),
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
                  progress:    model.progressByAlbumId.values.toList(),
                  collection:  model.collection,
                ),
              'stars' => StarsSection(
                  collection: model.collection,
                  allCards:   allCards,
                ),
              'cult' => CultSection(
                  definitions: model.cultAlbums,
                  collection:  model.collection,
                  allCards:    allCards,
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
//  FILA DE CATEGORÍA — rediseñada
// ═══════════════════════════════════════════════════════════
class _CategoryRow extends StatefulWidget {
  final String   label;
  final String   subtitle;
  final Color    accentColor;
  final Color    spineColor;
  final Color    coverBg;
  final int      albumCount;
  final int      completedCount;
  final Widget   coverChild;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.spineColor,
    required this.coverBg,
    required this.albumCount,
    required this.completedCount,
    required this.coverChild,
    required this.onTap,
  });

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _pressed = false;

  double get _pct => widget.albumCount > 0
      ? (widget.completedCount / widget.albumCount).clamp(0.0, 1.0)
      : 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? (Matrix4.identity()..translate(3.0, 3.0))
            : Matrix4.identity(),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: GsColors.bg,
          border: Border.all(color: GsColors.border, width: 1.5),
          boxShadow: _pressed
              ? []
              : const [
                  BoxShadow(color: GsColors.shadow, offset: Offset(3, 3)),
                ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Portada del libro ──────────────────────
              _BookCover(
                spine:  widget.spineColor,
                bg:     widget.coverBg,
                accent: widget.accentColor,
                child:  widget.coverChild,
              ),

              // ── Info central ──────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 0, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Categoría label en color
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: widget.accentColor,
                        ),
                      ),
                      const SizedBox(height: 1),

                      // Subtítulo grande bold
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: GsColors.text,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Checkboxes de estado
                      _AlbumStatusRow(
                        total:     widget.albumCount,
                        completed: widget.completedCount,
                        accent:    widget.accentColor,
                      ),

                      const SizedBox(height: 8),

                      // Barra de progreso
                      _ProgressBar(pct: _pct, accent: widget.accentColor),

                      const SizedBox(height: 5),

                      // Texto "X / Y COMPLETADOS — XX%"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${widget.completedCount} / ${widget.albumCount} COMPLETADOS',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: widget.accentColor,
                            ),
                          ),
                          Text(
                            '${(_pct * 100).round()}%',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: widget.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Flecha ────────────────────────────────
              Container(
                width: 44,
                alignment: Alignment.center,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: GsColors.cream,
                    border: Border.all(color: GsColors.border, width: 1.5),
                    boxShadow: _pressed
                        ? []
                        : const [
                            BoxShadow(
                                color: GsColors.shadow,
                                offset: Offset(2, 2)),
                          ],
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: GsColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PORTADA DEL LIBRO — con padding vertical para no pegar al borde
// ═══════════════════════════════════════════════════════════
class _BookCover extends StatelessWidget {
  final Color  spine;
  final Color  bg;
  final Color  accent;
  final Widget child;

  const _BookCover({
    required this.spine,
    required this.bg,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Espacio arriba/abajo para que el libro flote dentro del card
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: SizedBox(
        width: 86,
        height: 120,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Páginas traseras (efecto pila)
            Positioned(
              top: 7, left: 10,
              child: Container(
                width: 70, height: 112,
                color: bg.withValues(alpha: 0.55),
              ),
            ),
            Positioned(
              top: 3, left: 5,
              child: Container(
                width: 70, height: 112,
                color: bg.withValues(alpha: 0.75),
              ),
            ),

            // Libro principal
            Positioned(
              top: 0, left: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lomo
                  Container(
                    width: 10,
                    height: 120,
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
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ],
                    ),
                  ),
                  // Tapa
                  Container(
                    width: 70,
                    height: 120,
                    color: bg,
                    child: Stack(
                      children: [
                        // Gradiente sutil
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.withValues(alpha: 0.08),
                                  Colors.transparent,
                                  accent.withValues(alpha: 0.04),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Arte de portada
                        Positioned.fill(child: child),
                        // Borde inferior accent
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            height: 3,
                            color: spine.withValues(alpha: 0.7),
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CHECKBOXES DE ESTADO
// ═══════════════════════════════════════════════════════════
class _AlbumStatusRow extends StatelessWidget {
  final int   total;
  final int   completed;
  final Color accent;

  const _AlbumStatusRow({
    required this.total,
    required this.completed,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // Tamaño adaptativo: max 5 álbumes × (24px + 4px margin) = 140px — cabe en ~161px
    return Row(
      children: List.generate(total, (i) {
        final done = i < completed;
        return Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: done ? accent : GsColors.cream,
            border: Border.all(
              color: done ? accent : GsColors.border,
              width: 1.5,
            ),
            boxShadow: done
                ? [BoxShadow(color: accent.withValues(alpha: 0.25), offset: const Offset(1, 1))]
                : null,
          ),
          child: Icon(
            done ? Icons.check : Icons.lock_outline,
            size: 12,
            color: done ? Colors.white : GsColors.muted,
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BARRA DE PROGRESO
// ═══════════════════════════════════════════════════════════
class _ProgressBar extends StatelessWidget {
  final double pct;
  final Color  accent;

  const _ProgressBar({required this.pct, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 7,
      child: LinearProgressIndicator(
        value: pct,
        backgroundColor: GsColors.bgSection,
        valueColor: AlwaysStoppedAnimation<Color>(accent),
        minHeight: 7,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  COVER PAINTERS (sin cambios, reutilizados)
// ═══════════════════════════════════════════════════════════

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
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 34));
    canvas.drawCircle(Offset(cx, cy), 34, glowPaint);

    final ringPaint = Paint()
      ..color = accent.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final r in [28.0, 20.0]) {
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
  }

  @override
  bool shouldRepaint(_BoltPainter old) => old.accent != accent;
}

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
      ..lineTo(cx - 7,  cy - 2)
      ..lineTo(cx,      cy - 14)
      ..lineTo(cx + 7,  cy - 2)
      ..lineTo(cx + 14, cy - 10)
      ..lineTo(cx + 14, cy + 8)
      ..close();

    canvas.drawPath(crown, crownFill);
    canvas.drawPath(crown, crownStroke);

    final dotPaint = Paint()
      ..color = accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 14, cy - 10), 2.2, dotPaint);
    canvas.drawCircle(Offset(cx,      cy - 14), 2.2, dotPaint);
    canvas.drawCircle(Offset(cx + 14, cy - 10), 2.2, dotPaint);
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.accent != accent;
}

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
    const r = 22.0;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: 0.20), accent.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 34));
    canvas.drawCircle(Offset(cx, cy), 34, glowPaint);

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

    for (final offset in [-9.0, 9.0]) {
      final halfW = math.sqrt(r * r - offset * offset);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + offset),
            width: halfW * 1.9,
            height: 5.5),
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
      ..moveTo(cx, cy - 12)
      ..lineTo(cx + 9,  cy - 7)
      ..lineTo(cx + 9,  cy + 2)
      ..quadraticBezierTo(cx + 9, cy + 11, cx, cy + 15)
      ..quadraticBezierTo(cx - 9, cy + 11, cx - 9, cy + 2)
      ..lineTo(cx - 9, cy - 7)
      ..close();

    canvas.drawPath(shield, shieldFill);
    canvas.drawPath(shield, shieldStroke);
  }

  @override
  bool shouldRepaint(_GlobePainter old) => old.accent != accent;
}