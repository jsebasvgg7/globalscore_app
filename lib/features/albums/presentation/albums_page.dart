import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/albums_provider.dart';
import '../domain/albums_model.dart';
import '../widgets/active_album_hero.dart';
import '../widgets/boost_progress_bar.dart';
import '../widgets/pack_card.dart';
import '../widgets/albums_carousel.dart';
import '../widgets/pack_opening_modal.dart';

// ════════════════════════════════════════════════════════════
//  DESIGN TOKENS — neobrutalista crema + morado + sombras
// ════════════════════════════════════════════════════════════
abstract class Ds {
  static const Color bg        = Color(0xFFF5F2EC);
  static const Color bgSection = Color(0xFFEFEBE3);
  static const Color bgCard    = Color(0xFFE8E3D8);

  static const Color ink       = Color(0xFF0D0D1A);
  static const Color border    = Color(0xFF0D0D1A);
  static const Color borderSub = Color(0xFFCBC6BA);
  static const Color muted     = Color(0xFF777068);

  static const Color accent    = Color(0xFF5B4FD8);
  static const Color accentDim = Color(0xFF4A40C0);
  static const Color gold      = Color(0xFFFFD600);

  // Sombra offset neobrutalista — negra pura
  static const Color shadow3d  = Color(0xFF0D0D1A);

  static const String font = 'DM Mono';
}

// ════════════════════════════════════════════════════════════
//  ALBUMS PAGE
// ════════════════════════════════════════════════════════════
class AlbumsPage extends ConsumerWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);
    return albumsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Ds.accent, strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: Colors.red, fontSize: 11)),
      ),
      data: (model) => _AlbumsBody(model: model),
    );
  }
}

class _AlbumsBody extends ConsumerWidget {
  final AlbumsModel model;
  const _AlbumsBody({required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlbum = model.legendaryAlbums
            .where((d) => model.progressFor(d.id)?.isCompleted != true)
            .firstOrNull ??
        model.legendaryAlbums.firstOrNull;

    final prog     = activeAlbum != null ? model.progressFor(activeAlbum.id) : null;
    final unique   = prog?.uniqueCards ?? 0;
    final required = activeAlbum?.requiredUniquePlayers ?? 30;
    final pct      = required > 0 ? (unique / required).clamp(0.0, 1.0) : 0.0;

    return Container(
      color: Ds.bg,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1 — Tabs
            const _TabsBar(),

            const SizedBox(height: 14),

            // 2 — Hero álbum activo
            if (activeAlbum != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ActiveAlbumHero(
                  albumId:     activeAlbum.id,
                  name:        activeAlbum.name,
                  description: activeAlbum.description,
                  pct:         pct,
                  filled:      unique,
                  total:       required,
                  isCompleted: prog?.isCompleted ?? false,
                ),
              ),

            const SizedBox(height: 14),

            // 3 — Progreso de sobres
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: BoostProgressBar(
                boostActive:         model.packs?.boostActive ?? false,
                boostPacksRemaining: model.packs?.boostPacksRemaining ?? 0,
                totalPacksOpened:    model.packs?.totalPacksOpened ?? 0,
              ),
            ),

            const SizedBox(height: 14),

            // 4 — Sobres disponibles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: PackCard(
                packsAvailable: model.packs?.packsAvailable ?? 0,
                onOpen: () => showPackOpeningModal(context, ref),
              ),
            ),

            const SizedBox(height: 14),

            // 5 — Carrusel colecciones
            AlbumsCarousel(model: model),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TABS BAR — relieve neobrutalista
// ════════════════════════════════════════════════════════════
class _TabsBar extends StatelessWidget {
  const _TabsBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Ds.bg,
        border: Border(
          bottom: BorderSide(color: Ds.border, width: 2),
        ),
        // Sombra hacia abajo — separa el tab bar del contenido
        boxShadow: [
          BoxShadow(color: Ds.shadow3d, offset: Offset(0, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          _Tab(icon: Icons.grid_view,         label: 'RESUMEN',   active: true),
          _Tab(icon: Icons.menu_book_outlined, label: 'COLECCIÓN', active: false, soon: true),
          _Tab(icon: Icons.mail_outline,       label: 'SOBRES',    active: false, soon: true),
          _Tab(icon: Icons.star_outline,       label: 'MISIONES',  active: false, soon: true),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool soon;

  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    this.soon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: active ? Ds.accent : Colors.transparent,
        // Tab activo: borde inferior con color propio (anula borde global)
        border: active
            ? const Border(
                bottom: BorderSide(color: Ds.accent, width: 2),
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: active ? Colors.white : Ds.muted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: Ds.font,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: active ? Colors.white : Ds.muted,
                ),
              ),
            ],
          ),
          if (soon)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: Ds.borderSub, width: 0.8),
              ),
              child: const Text(
                'PRONTO',
                style: TextStyle(
                  fontFamily: Ds.font, fontSize: 6,
                  fontWeight: FontWeight.w700, color: Ds.muted, letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Alias GsColors para compatibilidad con otros widgets ──
abstract class GsColors {
  static const Color cream   = Ds.bgCard;
  static const Color card    = Ds.bgSection;
  static const Color border  = Ds.border;
  static const Color text    = Ds.ink;
  static const Color accent  = Ds.accent;
  static const Color gold    = Ds.gold;
  static const Color muted   = Ds.muted;
  static const Color shadow  = Color(0x881A1A2E);
  static const String fontMono = Ds.font;
}