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

  int _legendaryCompleted() => model.progressByAlbumId.values
      .where((p) => p.albumId.startsWith('legendary') && p.isCompleted)
      .length;

  int _starsCompleted() => model.progressByAlbumId.values
      .where((p) => p.albumId.startsWith('stars') && p.isCompleted)
      .length;

  int _cultCompleted() => model.progressByAlbumId.values
      .where((p) => p.albumId.startsWith('cult') && p.isCompleted)
      .length;

  int _totalFiguritas() => model.collection.fold(0, (s, c) => s + c.copies);

  int _totalCompleted() =>
      _legendaryCompleted() + _starsCompleted() + _cultCompleted();

  double _globalProgress() {
    const total = 5 + 5 + 3;
    return _totalCompleted() / total;
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
        // ── Header "TU COLECCIÓN" ─────────────────────
        _CollectionHeader(
          figuritas:      figuritas,
          globalPct:      globalPct,
          completedCount: totalCompleted,
        ),

        const SizedBox(height: 16),

        // ── Título "TUS COLECCIONES" ──────────────────
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

        // ── Filas de categoría ────────────────────────
        _CategoryRow(
          label:          'LEGENDARIOS',
          subtitle:       '5 ÁLBUMES',
          accentColor:    const Color(0xFF34d399),
          spineColor:     const Color(0xFF1D9E75),
          coverBg:        const Color(0xFF0d1f18),
          albumCount:     5,
          completedCount: _legendaryCompleted(),
          coverChild:     const _BoltPainterWidget(accent: Color(0xFF34d399)),
          badgeColor:     const Color(0xFF34d399),
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
          spineColor:     const Color(0xFF5b4fd8),
          coverBg:        const Color(0xFF100e1f),
          albumCount:     5,
          completedCount: _starsCompleted(),
          coverChild:     const _CrownPainterWidget(accent: Color(0xFFa599d9)),
          badgeColor:     const Color(0xFF7c3aed),
          onTap: () => _openCategorySheet(
            context: context, ref: ref,
            tab: 'stars', model: model, allCards: _allCards(),
          ),
        ),

        const SizedBox(height: 10),

        _CategoryRow(
          label:          'DE CULTO',
          subtitle:       '4 ÁLBUMES',
          accentColor:    const Color(0xFFf59e0b),
          spineColor:     const Color(0xFFb45309),
          coverBg:        const Color(0xFF1a1100),
          albumCount:     4,
          completedCount: _cultCompleted(),
          coverChild:     const _GlobePainterWidget(accent: Color(0xFFf59e0b)),
          badgeColor:     const Color(0xFFf59e0b),
          onTap: () => _openCategorySheet(
            context: context, ref: ref,
            tab: 'cult', model: model, allCards: _allCards(),
          ),
        ),

        const SizedBox(height: 10),
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

          // ── Fila título + VER TODO ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 0),
            child: Row(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Fila única de 4 stats ───────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── STAT 1: Álbumes activos ────────────
                  // Contenedor propio con relieve (borde + sombra offset)
                  Container(
                    width: 72,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: GsColors.bg,
                      border: Border.all(color: GsColors.borderSub, width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: GsColors.shadow,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$activeCount',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: GsColors.accent,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'ÁLBUMES\nACTIVOS',
                          style: TextStyle(
                            fontFamily: GsColors.fontMono,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            color: GsColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ── STATS 2-3-4: los 3 en un solo contenedor con relieve ──
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: GsColors.bg,
                        border: Border.all(color: GsColors.borderSub, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: GsColors.shadow,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            // Figuritas
                            Expanded(
                              child: _CompactStat(
                                iconWidget: _BoxedIcon(
                                  icon: Icons.star,
                                  color: GsColors.accent,
                                  borderColor: GsColors.accent,
                                ),
                                value: '$figuritas',
                                label: 'FIGURITAS\nCONSEGUIDAS',
                              ),
                            ),

                            // Divisor interno
                            Container(width: 0.8, color: GsColors.borderSub),

                            // Progreso global
                            Expanded(
                              child: _CompactStat(
                                iconWidget: _BoxedIcon(
                                  icon: Icons.check,
                                  color: Colors.white,
                                  borderColor: const Color(0xFF22C55E),
                                  filled: true,
                                  fillColor: const Color(0xFF22C55E),
                                ),
                                value: '$pctInt%',
                                label: 'PROGRESO\nGLOBAL',
                              ),
                            ),

                            // Divisor interno
                            Container(width: 0.8, color: GsColors.borderSub),

                            // Completados
                            Expanded(
                              child: _CompactStat(
                                iconWidget: _BoxedIcon(
                                  icon: Icons.star_border,
                                  color: const Color(0xFFf59e0b),
                                  borderColor: const Color(0xFFf59e0b),
                                ),
                                value: '$completedCount',
                                label: 'COMPLETADOS',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Barra de progreso global ────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              children: [
                Container(height: 7, color: GsColors.bgSection),
                FractionallySizedBox(
                  widthFactor: globalPct,
                  child: Container(
                    height: 7,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [GsColors.accent, Color(0xFF7c6fef)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── % alineado a la derecha ─────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 3, 12, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$pctInt%',
                style: const TextStyle(
                  fontFamily: GsColors.fontMono,
                  fontSize: 9.5,
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

// Celda compacta — ícono + valor grande + label pequeño
class _CompactStat extends StatelessWidget {
  final Widget iconWidget;
  final String value, label;
  const _CompactStat({required this.iconWidget, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: GsColors.text,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: GsColors.fontMono,
              fontSize: 6.5,
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

// Ícono en caja con borde de color
class _BoxedIcon extends StatelessWidget {
  final IconData icon;
  final Color color, borderColor;
  final bool filled;
  final Color? fillColor;

  const _BoxedIcon({
    required this.icon,
    required this.color,
    required this.borderColor,
    this.filled = false,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: filled ? fillColor : Colors.transparent,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Icon(icon, size: 13, color: color),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FILA DE CATEGORÍA — libro premium a la izquierda
// ═══════════════════════════════════════════════════════════
class _CategoryRow extends StatefulWidget {
  final String     label, subtitle;
  final Color      accentColor, spineColor, coverBg, badgeColor;
  final int        albumCount, completedCount;
  final Widget     coverChild;
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
    required this.badgeColor,
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
              : const [BoxShadow(color: GsColors.shadow, offset: Offset(3, 3))],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Libro 3D compacto ──────────────────
              _CompactBook(
                spine:      widget.spineColor,
                bg:         widget.coverBg,
                accent:     widget.accentColor,
                badgeColor: widget.badgeColor,
                child:      widget.coverChild,
              ),

              // ── Info central ──────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: GsColors.fontMono,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: widget.accentColor,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                      _AlbumStatusRow(
                        total:     widget.albumCount,
                        completed: widget.completedCount,
                        accent:    widget.accentColor,
                      ),
                      const SizedBox(height: 8),
                      _ProgressBar(pct: _pct, accent: widget.accentColor),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${widget.completedCount} / ${widget.albumCount} COMPLETADOS',
                            style: TextStyle(
                              fontFamily: GsColors.fontMono,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: widget.accentColor,
                            ),
                          ),
                          Text(
                            '${(_pct * 100).round()}%',
                            style: TextStyle(
                              fontFamily: GsColors.fontMono,
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

              // ── Flecha ────────────────────────────
              Container(
                width: 44,
                alignment: Alignment.center,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: GsColors.cream,
                    border: Border.all(color: GsColors.border, width: 1.5),
                    boxShadow: _pressed ? [] : const [
                      BoxShadow(color: GsColors.shadow, offset: Offset(2, 2)),
                    ],
                  ),
                  child: const Icon(Icons.chevron_right, size: 18, color: GsColors.text),
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
//  LIBRO COMPACTO 3D — para las filas de categoría
//  Incluye: pila de libros (3 capas), lomo grabado, portada
// ═══════════════════════════════════════════════════════════
class _CompactBook extends StatelessWidget {
  final Color  spine, bg, accent, badgeColor;
  final Widget child;

  const _CompactBook({
    required this.spine,
    required this.bg,
    required this.accent,
    required this.badgeColor,
    required this.child,
  });

  static const double _bw = 68.0;  // ancho portada
  static const double _bh = 110.0; // alto portada
  static const double _sw = 12.0;  // ancho lomo

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: SizedBox(
        width: _sw + _bw + 14,
        height: _bh + 10,
        child: Stack(
          children: [
            // ── Libros apilados detrás (efecto pila) ──
            // Libro más atrás (más claro, más desplazado)
            Positioned(
              left: _sw + 10,
              top: 10,
              child: Container(
                width: _bw,
                height: _bh,
                color: bg.withValues(alpha: 0.4),
              ),
            ),
            // Libro medio
            Positioned(
              left: _sw + 5,
              top: 5,
              child: Stack(
                children: [
                  Container(
                    width: _bw,
                    height: _bh,
                    color: bg.withValues(alpha: 0.65),
                  ),
                  // Lomo del libro medio
                  Positioned(
                    left: -_sw, top: 0,
                    child: Container(
                      width: _sw - 2,
                      height: _bh,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            spine.withValues(alpha: 0.4),
                            spine.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Libro principal (frente) ───────────────
            Positioned(
              left: 0, top: 0,
              child: _buildMainBook(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainBook() {
    return SizedBox(
      width: _sw + _bw,
      height: _bh,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LOMO
          SizedBox(
            width: _sw,
            child: Stack(
              children: [
                // Gradiente lomo
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0.0, 0.3, 0.7, 1.0],
                        colors: [
                          spine.withValues(alpha: 0.5),
                          spine,
                          spine.withValues(alpha: 0.85),
                          spine.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),
                // Líneas de grabado
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SpineLinesCompact(),
                  ),
                ),
                // Línea dorada superior
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(height: 2, color: const Color(0xFFD4A820).withValues(alpha: 0.6)),
                ),
                // Línea dorada inferior
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(height: 2, color: const Color(0xFFD4A820).withValues(alpha: 0.6)),
                ),
                // Highlight reflejo
                Positioned(
                  right: 0, top: 0, bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PORTADA
          Expanded(
            child: Stack(
              children: [
                // Base de portada
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      border: Border(
                        top:    BorderSide(color: spine.withValues(alpha: 0.3), width: 0.5),
                        right:  BorderSide(color: spine.withValues(alpha: 0.3), width: 0.5),
                        bottom: BorderSide(color: spine.withValues(alpha: 0.7), width: 2),
                      ),
                    ),
                  ),
                ),

                // Textura/glow de portada
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CoverGlowCompact(accent: accent),
                  ),
                ),

                // Arte de la categoría
                Positioned.fill(
                  top: 12, bottom: 8, left: 4, right: 4,
                  child: child,
                ),

                // Franja de color en la parte inferior (identidad)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          spine.withValues(alpha: 0.8),
                          spine,
                          spine.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),

                // Esquinas doradas
                ..._buildCorners(),

                // Viñeta
                Positioned.fill(
                  child: CustomPaint(painter: _VignetteCompact()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 7.0;
    const color = Color(0xFFD4A820);
    const alpha = 0.55;

    Widget corner({double? t, double? b, double? l, double? r}) =>
        Positioned(
          top: t, bottom: b, left: l, right: r,
          child: CustomPaint(
            size: const Size(size, size),
            painter: _CornerPaint(
              top: t != null, left: l != null,
              color: color.withValues(alpha: alpha),
            ),
          ),
        );

    return [
      corner(t: 3, l: 3),
      corner(t: 3, r: 3),
      corner(b: 3, l: 3),
      corner(b: 3, r: 3),
    ];
  }
}

class _SpineLinesCompact extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (double y = 10; y < size.height - 10; y += 5) {
      canvas.drawLine(Offset(1, y), Offset(size.width - 1, y), p);
    }
  }
  @override
  bool shouldRepaint(_SpineLinesCompact old) => false;
}

class _CoverGlowCompact extends CustomPainter {
  final Color accent;
  const _CoverGlowCompact({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 0.75,
        colors: [accent.withValues(alpha: 0.15), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Líneas diagonales sutiles
    final lp = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.7;
    for (double x = -size.height; x < size.width + size.height; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
    }
  }

  @override
  bool shouldRepaint(_CoverGlowCompact old) => old.accent != accent;
}

class _VignetteCompact extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.2)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p);
  }
  @override
  bool shouldRepaint(_VignetteCompact old) => false;
}

class _CornerPaint extends CustomPainter {
  final bool top, left;
  final Color color;
  const _CornerPaint({required this.top, required this.left, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final x = left ? 0.0 : size.width;
    final y = top  ? 0.0 : size.height;
    canvas.drawLine(Offset(x, y), Offset(x + (left ? size.width : -size.width), y), p);
    canvas.drawLine(Offset(x, y), Offset(x, y + (top ? size.height : -size.height)), p);
  }
  @override
  bool shouldRepaint(_CornerPaint old) => false;
}

// ═══════════════════════════════════════════════════════════
//  CHECKBOXES DE ESTADO — fieles a la referencia
// ═══════════════════════════════════════════════════════════
class _AlbumStatusRow extends StatelessWidget {
  final int total, completed;
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
          width: 24, height: 24,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: done ? accent : GsColors.cream,
            border: Border.all(
              color: done ? accent : GsColors.border,
              width: 1.5,
            ),
            boxShadow: done
                ? [BoxShadow(color: accent.withValues(alpha: 0.3), offset: const Offset(1, 1))]
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
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: GsColors.bgSection)),
          FractionallySizedBox(
            widthFactor: pct.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.8), accent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BOTTOM SHEET REDISEÑADO — panel tipo colección por categoría
// ═══════════════════════════════════════════════════════════

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
        'stars'     => 'ESTRELLAS',
        'cult'      => 'DE CULTO',
        _           => '',
      };

  String get _subtitle => switch (tab) {
        'legendary' => '5 álbumes · Temp 25-26',
        'stars'     => '5 álbumes · Por nivel de rareza',
        'cult'      => '3 álbumes · Equipos, Copas y Eventos',
        _           => '',
      };

  Color get _accent => switch (tab) {
        'legendary' => const Color(0xFF5b4fd8),
        'stars'     => const Color(0xFFa599d9),
        'cult'      => const Color(0xFFf59e0b),
        _           => GsColors.accent,
      };

  Color get _accentLight => switch (tab) {
        'legendary' => const Color(0xFFa599d9),
        'stars'     => const Color(0xFFc4b5fd),
        'cult'      => const Color(0xFFfbbf24),
        _           => GsColors.accent,
      };

  int get _totalAlbums => switch (tab) {
        'legendary' => 5,
        'stars'     => 5,
        'cult'      => 3,
        _           => 0,
      };

  int _completedAlbums() {
    final prefix = switch (tab) {
      'legendary' => 'legendary',
      'stars'     => 'stars',
      'cult'      => 'cult',
      _           => '',
    };
    return model.progressByAlbumId.values
        .where((p) => p.albumId.startsWith(prefix) && p.isCompleted)
        .length;
  }

  int _figuritas() {
    final types = switch (tab) {
      'legendary' => {'player'},
      'stars'     => {'player'},
      'cult'      => {'team', 'competition', 'event'},
      _           => <String>{},
    };
    return model.collection
        .where((c) => types.contains(c.card?.cardType))
        .fold(0, (s, c) => s + c.copies);
  }

  double _pct() {
    final completed = _completedAlbums();
    final total = _totalAlbums;
    return total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completedAlbums();
    final figuritas = _figuritas();
    final pct       = _pct();
    final pctInt    = (pct * 100).round();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: GsColors.bg,
        border: Border(top: BorderSide(color: _accent, width: 3)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: GsColors.borderSub,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          _SheetHeader(
            title:    _title,
            subtitle: _subtitle,
            accent:   _accent,
            onClose:  () => Navigator.of(context).pop(),
          ),

          _SheetStatsPanel(
            accent:      _accent,
            accentLight: _accentLight,
            completed:   completed,
            total:       _totalAlbums,
            figuritas:   figuritas,
            pct:         pct,
            pctInt:      pctInt,
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(width: 3, height: 12, color: _accent),
                const SizedBox(width: 8),
                Text(
                  'TUS ÁLBUMES',
                  style: TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: _accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 1, color: GsColors.borderSub)),
                const SizedBox(width: 8),
                Text(
                  '$completed / $_totalAlbums',
                  style: TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: _accentLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

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

          _SheetFooter(
            accent:    _accent,
            completed: completed,
            total:     _totalAlbums,
            onClose:   () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────
class _SheetHeader extends StatelessWidget {
  final String title, subtitle;
  final Color accent;
  final VoidCallback onClose;

  const _SheetHeader({
    required this.title, required this.subtitle,
    required this.accent, required this.onClose,
  });

  IconData get _icon => switch (title) {
        'LEGENDARIOS' => Icons.auto_awesome,
        'ESTRELLAS'   => Icons.star,
        'DE CULTO'    => Icons.public,
        _             => Icons.collections_bookmark,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: GsColors.bg,
        border: Border(bottom: BorderSide(color: GsColors.border, width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícono neobrutalista con fondo accent
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: accent,
              border: Border.all(color: GsColors.border, width: 1.5),
              boxShadow: const [BoxShadow(color: GsColors.shadow, offset: Offset(3, 3))],
            ),
            child: Icon(_icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: GsColors.text,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 9,
                    color: GsColors.muted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: GsColors.bg,
                border: Border.all(color: GsColors.border, width: 1.5),
                boxShadow: const [BoxShadow(color: GsColors.shadow, offset: Offset(2, 2))],
              ),
              child: const Icon(Icons.close, size: 14, color: GsColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats panel ───────────────────────────────────────────
class _SheetStatsPanel extends StatelessWidget {
  final Color accent, accentLight;
  final int completed, total, figuritas, pctInt;
  final double pct;

  const _SheetStatsPanel({
    required this.accent, required this.accentLight,
    required this.completed, required this.total,
    required this.figuritas, required this.pct, required this.pctInt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 3 columnas simétricas ──────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // STAT 1 — álbumes completados
                _StatCard(
                  icon: Icons.auto_awesome,
                  iconBg: accent,
                  iconColor: Colors.white,
                  value: '$completed',
                  label: 'ÁLBUMES\nCOMPLETADOS',
                  accent: accent,
                  highlighted: true,
                ),
                const SizedBox(width: 6),
                // STAT 2 — figuritas
                _StatCard(
                  icon: Icons.style,
                  iconBg: accentLight.withValues(alpha: 0.18),
                  iconColor: accentLight,
                  value: '$figuritas',
                  label: 'FIGURITAS\nCONSEGUIDAS',
                  accent: accent,
                ),
                const SizedBox(width: 6),
                // STAT 3 — progreso %
                _StatCard(
                  icon: Icons.check,
                  iconBg: const Color(0xFF22C55E),
                  iconColor: Colors.white,
                  value: '$pctInt%',
                  label: 'PROGRESO\nGLOBAL',
                  accent: accent,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Barra de progreso con contexto claro ────────
          Container(
            decoration: BoxDecoration(
              color: GsColors.bgSection,
              border: Border.all(color: GsColors.border, width: 1.5),
              boxShadow: const [BoxShadow(color: GsColors.shadow, offset: Offset(3, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Etiqueta superior
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 4),
                  child: Row(
                    children: [
                      Container(width: 3, height: 10, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'PROGRESO DE LA COLECCIÓN',
                        style: TextStyle(
                          fontFamily: GsColors.fontMono,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: accent,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$completed / $total álbumes',
                        style: const TextStyle(
                          fontFamily: GsColors.fontMono,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          color: GsColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Barra
                Stack(
                  children: [
                    Container(height: 12, color: GsColors.bgCard),
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0.0, 1.0),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [accent, accentLight]),
                        ),
                      ),
                    ),
                    // % flotando dentro de la barra
                    if (pct > 0.12)
                      Positioned(
                        left: 8, top: 0, bottom: 0,
                        child: Center(
                          child: Text(
                            '$pctInt%',
                            style: const TextStyle(
                              fontFamily: GsColors.fontMono,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Marcadores de hitos
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 7),
                  child: Row(
                    children: List.generate(total + 1, (i) {
                      final milePct = i / total;
                      final reached = pct >= milePct;
                      return Expanded(
                        child: i == 0
                            ? const SizedBox.shrink()
                            : Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: reached
                                          ? accent.withValues(alpha: 0.3)
                                          : GsColors.borderSub,
                                    ),
                                  ),
                                  Container(
                                    width: 5, height: 5,
                                    decoration: BoxDecoration(
                                      color: reached ? accent : GsColors.bgCard,
                                      border: Border.all(
                                        color: reached ? accent : GsColors.borderSub,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      );
                    }),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String value, label;
  final Color accent;
  final bool highlighted;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.accent,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: highlighted ? accent : GsColors.bg,
          border: Border.all(
            color: highlighted ? accent : GsColors.borderSub,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(color: GsColors.shadow, offset: Offset(2, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono en caja
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: iconBg,
                border: Border.all(
                  color: highlighted
                      ? Colors.white.withValues(alpha: 0.4)
                      : accent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 12, color: iconColor),
            ),
            const SizedBox(height: 6),
            // Valor
            Text(
              value,
              style: TextStyle(
                fontFamily: GsColors.fontMono,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: highlighted ? Colors.white : GsColors.text,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            // Label
            Text(
              label,
              style: TextStyle(
                fontFamily: GsColors.fontMono,
                fontSize: 6.5,
                fontWeight: FontWeight.w700,
                color: highlighted
                    ? Colors.white.withValues(alpha: 0.75)
                    : GsColors.muted,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor, borderColor;
  final bool filled;
  final Color? fillColor;
  final String value, label;

  const _StatCell({
    required this.icon, required this.iconColor,
    required this.borderColor, required this.filled,
    this.fillColor, required this.value, required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: filled ? fillColor : Colors.transparent,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Icon(icon, size: 12, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: GsColors.fontMono,
              fontSize: 20, fontWeight: FontWeight.w900,
              color: GsColors.text, height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: GsColors.fontMono,
              fontSize: 6.5, fontWeight: FontWeight.w600,
              color: GsColors.muted, height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────
class _SheetFooter extends StatelessWidget {
  final Color accent;
  final int completed, total;
  final VoidCallback onClose;

  const _SheetFooter({
    required this.accent, required this.completed,
    required this.total, required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: GsColors.bgCard,
        border: const Border(top: BorderSide(color: GsColors.border, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Pips de progreso
          Row(
            children: List.generate(total, (i) {
              final done = i < completed;
              return Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: done ? accent : GsColors.bgSection,
                  border: Border.all(
                    color: done ? accent : GsColors.borderSub,
                    width: 1,
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: GsColors.bg,
                border: Border.all(color: GsColors.border, width: 1.5),
                boxShadow: const [BoxShadow(color: GsColors.shadow, offset: Offset(2, 2))],
              ),
              child: const Text(
                'CERRAR',
                style: TextStyle(
                  fontFamily: GsColors.fontMono,
                  fontSize: 9, fontWeight: FontWeight.w900,
                  color: GsColors.text, letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════
//  COVER PAINTERS — igual que antes
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

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: 0.25), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 32));
    canvas.drawCircle(Offset(cx, cy), 32, glow);

    final ring = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final r in [26.0, 18.0]) {
      canvas.drawCircle(Offset(cx, cy), r, ring);
    }

    final fill = Paint()
      ..color = accent.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(cx + 6, cy - 20)
      ..lineTo(cx - 4, cy - 2)
      ..lineTo(cx + 3, cy - 2)
      ..lineTo(cx - 6, cy + 20)
      ..lineTo(cx + 4, cy + 2)
      ..lineTo(cx - 3, cy + 2)
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

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: 0.2), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 30));
    canvas.drawCircle(Offset(cx, cy), 30, glow);

    // Hexágono
    final hexFill = Paint()..color = accent.withValues(alpha: 0.10)..style = PaintingStyle.fill;
    final hexStroke = Paint()..color = accent.withValues(alpha: 0.30)..style = PaintingStyle.stroke..strokeWidth = 0.8;
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * 2 * math.pi - math.pi / 6;
      final x = cx + 20 * math.cos(a);
      final y = cy + 20 * math.sin(a);
      if (i == 0) hexPath.moveTo(x, y); else hexPath.lineTo(x, y);
    }
    hexPath.close();
    canvas.drawPath(hexPath, hexFill);
    canvas.drawPath(hexPath, hexStroke);

    // Corona
    final cFill   = Paint()..color = accent.withValues(alpha: 0.12)..style = PaintingStyle.fill;
    final cStroke = Paint()..color = accent.withValues(alpha: 0.72)..style = PaintingStyle.stroke..strokeWidth = 1.2..strokeJoin = StrokeJoin.round;

    final crown = Path()
      ..moveTo(cx - 12, cy + 7)
      ..lineTo(cx - 12, cy - 8)
      ..lineTo(cx - 5,  cy - 1)
      ..lineTo(cx,      cy - 12)
      ..lineTo(cx + 5,  cy - 1)
      ..lineTo(cx + 12, cy - 8)
      ..lineTo(cx + 12, cy + 7)
      ..close();
    canvas.drawPath(crown, cFill);
    canvas.drawPath(crown, cStroke);

    final dotP = Paint()..color = accent.withValues(alpha: 0.9)..style = PaintingStyle.fill;
    for (final pt in [Offset(cx - 12, cy - 8), Offset(cx, cy - 12), Offset(cx + 12, cy - 8)]) {
      canvas.drawCircle(pt, 2.0, dotP);
    }
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
    const r = 20.0;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: 0.22), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 32));
    canvas.drawCircle(Offset(cx, cy), 32, glow);

    final fill   = Paint()..color = accent.withValues(alpha: 0.10)..style = PaintingStyle.fill;
    final stroke = Paint()..color = accent.withValues(alpha: 0.62)..style = PaintingStyle.stroke..strokeWidth = 1.0;

    canvas.drawCircle(Offset(cx, cy), r, fill);
    canvas.drawCircle(Offset(cx, cy), r, stroke);

    final thin = Paint()..color = accent.withValues(alpha: 0.28)..style = PaintingStyle.stroke..strokeWidth = 0.7;
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), thin);
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), thin);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 0.9, height: r * 2), thin);

    for (final off in [-8.0, 8.0]) {
      final hw = math.sqrt(r * r - off * off);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + off), width: hw * 1.9, height: 5.0), thin,
      );
    }

    // Escudo
    final sFill   = Paint()..color = accent.withValues(alpha: 0.14)..style = PaintingStyle.fill;
    final sStroke = Paint()..color = accent.withValues(alpha: 0.72)..style = PaintingStyle.stroke..strokeWidth = 1.1;
    final shield = Path()
      ..moveTo(cx, cy - 11)
      ..lineTo(cx + 8,  cy - 6)
      ..lineTo(cx + 8,  cy + 2)
      ..quadraticBezierTo(cx + 8, cy + 10, cx, cy + 14)
      ..quadraticBezierTo(cx - 8, cy + 10, cx - 8, cy + 2)
      ..lineTo(cx - 8, cy - 6)
      ..close();
    canvas.drawPath(shield, sFill);
    canvas.drawPath(shield, sStroke);
  }

  @override
  bool shouldRepaint(_GlobePainter old) => old.accent != accent;
}