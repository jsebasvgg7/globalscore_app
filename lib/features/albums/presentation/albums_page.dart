import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/albums_provider.dart';
import '../domain/albums_model.dart';
import '../widgets/active_album_hero.dart';
import '../widgets/boost_progress_bar.dart';
import '../widgets/pack_card.dart';
import '../widgets/albums_collection_view.dart';
import '../widgets/pack_opening_modal.dart';

// ════════════════════════════════════════════════════════════
//  DESIGN TOKENS — neobrutalista crema + morado + sombras
// ════════════════════════════════════════════════════════════
abstract class Ds {
  static const Color bg        = Color(0xFFF5F2EC);
  static const Color bgSection = Color(0xFFEFEBE3);
  static const Color bgCard    = Color(0xFFE8E3D8);
  static const Color ink       = Color(0xFF1C1A2E);
  static const Color border    = Color(0xFF2D2A40);
  static const Color borderSub = Color(0xFFCBC6BA);
  static const Color muted     = Color(0xFF7A7268);
  static const Color accent    = Color(0xFF5B4FD8);
  static const Color accentDim = Color(0xFF4A40C0);
  static const Color gold      = Color(0xFFFFD600);
  static const Color shadow3d  = Color.fromARGB(255, 48, 45, 65);

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

class _AlbumsBody extends ConsumerStatefulWidget {
  final AlbumsModel model;
  const _AlbumsBody({required this.model});

  @override
  ConsumerState<_AlbumsBody> createState() => _AlbumsBodyState();
}

class _AlbumsBodyState extends ConsumerState<_AlbumsBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _kResumen   = 0;
  static const _kColeccion = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;

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
      child: Column(
        children: [
          _TabsBar(
            controller: _tabController,
            onColeccionTap: () => _tabController.animateTo(_kColeccion),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Tab 0: RESUMEN
                _ResumenTab(
                  model:        model,
                  activeAlbum:  activeAlbum,
                  prog:         prog,
                  pct:          pct,
                  unique:       unique,
                  required:     required,
                  onVerColeccion: () => _tabController.animateTo(_kColeccion),
                ),
                // Tab 1: COLECCIÓN
                _ColeccionTab(model: model),
                // Tab 2: SOBRES (próximamente)
                const _ComingSoon(label: 'SOBRES'),
                // Tab 3: MISIONES (próximamente)
                const _ComingSoon(label: 'MISIONES'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TAB RESUMEN
// ════════════════════════════════════════════════════════════
class _ResumenTab extends StatelessWidget {
  final AlbumsModel      model;
  final AlbumDefinition? activeAlbum;
  final AlbumProgress?   prog;
  final double           pct;
  final int              unique;
  final int              required;
  final VoidCallback     onVerColeccion;

  const _ResumenTab({
    required this.model,
    required this.activeAlbum,
    required this.prog,
    required this.pct,
    required this.unique,
    required this.required,
    required this.onVerColeccion,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),

          if (activeAlbum != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ActiveAlbumHero(
                albumId:     activeAlbum!.id,
                name:        activeAlbum!.name,
                description: activeAlbum!.description,
                pct:         pct,
                filled:      unique,
                total:       required,
                isCompleted: prog?.isCompleted ?? false,
              ),
            ),

          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: BoostProgressBar(
              boostActive:         model.packs?.boostActive ?? false,
              boostPacksRemaining: model.packs?.boostPacksRemaining ?? 0,
              totalPacksOpened:    model.packs?.totalPacksOpened ?? 0,
            ),
          ),

          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: PackCard(
              packsAvailable: model.packs?.packsAvailable ?? 0,
              onOpen: () => showPackOpeningModal(context, context as dynamic),
            ),
          ),

          const SizedBox(height: 14),

          // Acceso rápido a colección
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GestureDetector(
              onTap: onVerColeccion,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Ds.bgCard,
                  border: Border.all(color: Ds.border, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFB0AAA0), offset: Offset(3, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 16, color: Ds.accent),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'VER TUS COLECCIONES',
                        style: TextStyle(
                          fontFamily: Ds.font,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Ds.ink,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: Ds.muted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TAB COLECCIÓN
// ════════════════════════════════════════════════════════════
class _ColeccionTab extends StatelessWidget {
  final AlbumsModel model;
  const _ColeccionTab({required this.model});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          // AlbumsCollectionView incluye header "TU COLECCIÓN" + stats
          // + sección "TUS COLECCIONES" con las 3 categorías
          AlbumsCollectionView(model: model),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  COMING SOON
// ════════════════════════════════════════════════════════════
class _ComingSoon extends StatelessWidget {
  final String label;
  const _ComingSoon({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Ds.bgCard,
              border: Border.all(color: Ds.borderSub, width: 1),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: Ds.font,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Ds.muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'PRÓXIMAMENTE',
            style: TextStyle(
              fontFamily: Ds.font,
              fontSize: 8,
              color: Ds.muted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TABS BAR
// ════════════════════════════════════════════════════════════
class _TabsBar extends StatelessWidget {
  final TabController controller;
  final VoidCallback  onColeccionTap;

  const _TabsBar({required this.controller, required this.onColeccionTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      decoration: BoxDecoration(
        color: Ds.bg,
        border: Border.all(color: Ds.border, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFFB0AAA0), offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Tab(
                index:      0,
                controller: controller,
                icon:       Icons.grid_view_rounded,
                label:      'INICIO',
              ),
            ),
            Container(width: 1.5, color: Ds.border),
            Expanded(
              child: _Tab(
                index:      1,
                controller: controller,
                icon:       Icons.menu_book_outlined,
                label:      'COLECCIÓN',
              ),
            ),
            Container(width: 1, color: Ds.borderSub),
            Expanded(
              child: _Tab(
                index:      2,
                controller: controller,
                icon:       Icons.mail_outline,
                label:      'SOBRES',
                soon:       true,
              ),
            ),
            Container(width: 1, color: Ds.borderSub),
            Expanded(
              child: _Tab(
                index:      3,
                controller: controller,
                icon:       Icons.star_outline,
                label:      'MISIONES',
                soon:       true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final int           index;
  final TabController controller;
  final IconData      icon;
  final String        label;
  final bool          soon;

  const _Tab({
    required this.index,
    required this.controller,
    required this.icon,
    required this.label,
    this.soon = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final active = controller.index == index;
        return GestureDetector(
          onTap: () => controller.animateTo(index),
          child: Container(
            color: active ? Ds.accent : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 10,
                        color: active ? Colors.white : Ds.muted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: Ds.font,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                          color: active ? Colors.white : Ds.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (soon) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      border: Border.all(color: Ds.borderSub, width: 0.8),
                    ),
                    child: const Text(
                      'PRONTO',
                      style: TextStyle(
                        fontFamily: Ds.font,
                        fontSize: 5.5,
                        fontWeight: FontWeight.w700,
                        color: Ds.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ALIAS GsColors — compatibilidad con otros widgets
// ════════════════════════════════════════════════════════════
abstract class GsColors {
  static const Color cream     = Ds.bgCard;
  static const Color card      = Ds.bgSection;
  static const Color bg        = Ds.bg;
  static const Color bgCard    = Ds.bgCard;
  static const Color bgSection = Ds.bgSection;
  static const Color border    = Ds.border;
  static const Color borderSub = Ds.borderSub;
  static const Color text      = Ds.ink;
  static const Color accent    = Ds.accent;
  static const Color gold      = Ds.gold;
  static const Color muted     = Ds.muted;
  static const Color shadow    = Color(0x881A1A2E);
  static const String fontMono = Ds.font;
}