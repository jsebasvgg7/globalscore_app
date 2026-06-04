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
//  ALBUMS PAGE — maniquí puro, solo orquesta widgets
// ════════════════════════════════════════════════════════════
class AlbumsPage extends ConsumerWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);

    return albumsAsync.when(
      loading: () => const _AlbumsLoading(),
      error: (e, _) => _AlbumsError(message: e.toString()),
      data: (model) => _AlbumsBody(model: model),
    );
  }
}

// ── Loading state ─────────────────────────────────────────
class _AlbumsLoading extends StatelessWidget {
  const _AlbumsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: GsColors.accent,
        strokeWidth: 2,
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────
class _AlbumsError extends StatelessWidget {
  final String message;
  const _AlbumsError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Error: $message',
          style: const TextStyle(color: Colors.red, fontSize: 11),
        ),
      ),
    );
  }
}

// ── Body principal ────────────────────────────────────────
class _AlbumsBody extends ConsumerWidget {
  final AlbumsModel model;
  const _AlbumsBody({required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Álbum legendario activo (primero no completado)
    final activeAlbum = model.legendaryAlbums
            .where((d) => model.progressFor(d.id)?.isCompleted != true)
            .firstOrNull ??
        model.legendaryAlbums.firstOrNull;

    final prog = activeAlbum != null ? model.progressFor(activeAlbum.id) : null;
    final unique = prog?.uniqueCards ?? 0;
    final required = activeAlbum?.requiredUniquePlayers ?? 30;
    final pct = required > 0 ? (unique / required).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Widget 1: Álbum activo (libro 3D + stats + progreso) ──
          if (activeAlbum != null)
            ActiveAlbumHero(
              albumId: activeAlbum.id,
              name: activeAlbum.name,
              description: activeAlbum.description,
              pct: pct,
              filled: unique,
              total: required,
              isCompleted: prog?.isCompleted ?? false,
            ),

          // ── Widget 2: Track de progreso de sobres + boost ──────
          BoostProgressBar(
            boostActive: model.packs?.boostActive ?? false,
            boostPacksRemaining: model.packs?.boostPacksRemaining ?? 0,
            totalPacksOpened: model.packs?.totalPacksOpened ?? 0,
          ),

          const _SectionDivider(),

          // ── Widget 3: Sobre 3D + botón abrir ──────────────────
          PackCard(
            packsAvailable: model.packs?.packsAvailable ?? 0,
            onOpen: () => showPackOpeningModal(context, ref),
          ),

          const _SectionDivider(),

          // ── Widget 4: Carrusel legendary / stars / cult ────────
          AlbumsCarousel(model: model),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: GsColors.border.withValues(alpha: 0.12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  COLORES COMPARTIDOS (importados por todos los widgets)
// ════════════════════════════════════════════════════════════
abstract class GsColors {
  static const Color cream  = Color(0xFFF0EDE8);
  static const Color card   = Color(0xFFEDE7DA);
  static const Color border = Color(0xFF1A1A2E);
  static const Color accent = Color(0xFF5B4FD8);
  static const Color gold   = Color(0xFFFFD600);
  static const Color muted  = Color(0xFF88887D);
  static const Color text   = Color(0xFF1A1A2E);
  static const Color shadow = Color(0x661A1A2E);
  static const String fontMono = 'DM Mono';
}