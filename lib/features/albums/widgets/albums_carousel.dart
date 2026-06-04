// albums_collection_view.dart
import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;
import '../domain/albums_model.dart';
import '../domain/albums_provider.dart';
import 'legendary_section.dart';
import 'stars_section.dart';
import 'cult_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlbumsCollectionView extends ConsumerWidget {
  final AlbumsModel model;
  const AlbumsCollectionView({super.key, required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryRow(
          label: 'LEGENDARIOS',
          subtitle: '5 ÁLBUMES',
          accentColor: const Color(0xFFa599d9),
          spineColor: const Color(0xFF5b4fd8),
          coverBg: const Color(0xFF1a1726),
          albumCount: 5,
          completedCount: model.progressByAlbumId.values
              .where((p) => p.albumId.startsWith('legendary') && p.isCompleted)
              .length,
          onTap: () => ref.read(albumsTabProvider.notifier).set('legendary'),
          coverChild: _LegendaryCover(),
        ),
        const SizedBox(height: 10),
        _CategoryRow(
          label: 'ESTRELLAS',
          subtitle: '5 ÁLBUMES',
          accentColor: const Color(0xFFa599d9),
          spineColor: const Color(0xFF7c3aed),
          coverBg: const Color(0xFF160e2a),
          albumCount: 5,
          completedCount: model.progressByAlbumId.values
              .where((p) => p.albumId.startsWith('stars') && p.isCompleted)
              .length,
          onTap: () => ref.read(albumsTabProvider.notifier).set('stars'),
          coverChild: _StarsCover(),
        ),
        const SizedBox(height: 10),
        _CategoryRow(
          label: 'DE CULTO',
          subtitle: '3 ÁLBUMES',
          accentColor: const Color(0xFFf59e0b),
          spineColor: const Color(0xFFb45309),
          coverBg: const Color(0xFF1a1200),
          albumCount: 3,
          completedCount: model.progressByAlbumId.values
              .where((p) => p.albumId.startsWith('cult') && p.isCompleted)
              .length,
          onTap: () => ref.read(albumsTabProvider.notifier).set('cult'),
          coverChild: _CultCover(),
        ),
      ],
    );
  }
}

// ── Fila de categoría ─────────────────────────────────────
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

  double get _pct => albumCount > 0 ? (completedCount / albumCount).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: GsColors.card,
        border: Border.all(color: GsColors.border, width: 1),
        boxShadow: const [
          BoxShadow(color: GsColors.shadow, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
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
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etiqueta categoría
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Título grande
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: GsColors.text,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Mini checkboxes
                  _AlbumStatusRow(
                    total: albumCount,
                    completed: completedCount,
                    accent: accentColor,
                  ),
                  const SizedBox(height: 8),
                  // Barra de progreso
                  _ProgressBar(pct: _pct, accent: accentColor),
                  const SizedBox(height: 4),
                  // Texto progreso
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedCount / $albumCount COMPLETADOS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
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
              width: 36,
              height: double.infinity,
              alignment: Alignment.center,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GsColors.cream,
                border: Border.all(color: GsColors.border, width: 1),
                boxShadow: const [
                  BoxShadow(color: GsColors.shadow, offset: Offset(2, 2)),
                ],
              ),
              child: const Icon(Icons.chevron_right, size: 20, color: GsColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Portada del libro con lomo ────────────────────────────
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
      width: 90,
      height: 110,
      child: Stack(
        children: [
          // Sombra de páginas (capas detrás)
          Positioned(
            top: 6, left: 8,
            child: Container(width: 78, height: 98,
              color: bg.withValues(alpha: 0.5)),
          ),
          Positioned(
            top: 3, left: 5,
            child: Container(width: 78, height: 98,
              color: bg.withValues(alpha: 0.7)),
          ),
          // Libro principal
          Positioned(
            top: 0, left: 2,
            child: Row(
              children: [
                // Lomo
                Container(
                  width: 8,
                  height: 104,
                  color: spine,
                ),
                // Tapa
                Container(
                  width: 70,
                  height: 104,
                  color: bg,
                  child: Stack(
                    children: [
                      // Gradiente overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Arte central
                      Center(child: SizedBox(width: 60, height: 80, child: child)),
                      // Etiqueta lomo inferior
                      Positioned(
                        bottom: 6, right: 6,
                        child: Container(
                          width: 4,
                          height: 30,
                          color: spine.withValues(alpha: 0.4),
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

// ── Checkboxes de estado ──────────────────────────────────
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
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: done ? accent : GsColors.cream,
            border: Border.all(
              color: done ? accent : GsColors.border,
              width: 1.5,
            ),
            boxShadow: done
                ? [BoxShadow(color: GsColors.shadow, offset: const Offset(1, 1))]
                : null,
          ),
          child: Icon(
            done ? Icons.check : Icons.lock_outline,
            size: 14,
            color: done ? Colors.white : GsColors.muted,
          ),
        );
      }),
    );
  }
}

// ── Barra de progreso ─────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double pct;
  final Color accent;

  const _ProgressBar({required this.pct, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(color: GsColors.cream),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: pct,
        child: Container(color: accent),
      ),
    );
  }
}

// ── Covers de portada (reusan los CustomPainters existentes) ─
class _LegendaryCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BoltPainter(accent: const Color(0xFF34d399)));
  }
}

class _StarsCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CrownPainter(accent: const Color(0xFFa599d9)));
  }
}

class _CultCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GlobePainter(accent: const Color(0xFFf59e0b)));
  }
}