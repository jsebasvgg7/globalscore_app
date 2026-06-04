import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;
import '../domain/albums_model.dart';
import '../domain/albums_provider.dart';
import 'legendary_section.dart';
import 'stars_section.dart';
import 'cult_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ════════════════════════════════════════════════════════════
//  ALBUMS CAROUSEL
//  React equiv: AlbumsCarousel
//  Tabs legendary / stars / cult con flechas navegación
// ════════════════════════════════════════════════════════════

class AlbumsCarousel extends ConsumerWidget {
  final AlbumsModel model;

  const AlbumsCarousel({super.key, required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(albumsTabProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header con tabs + flechas
        _CarouselHeader(
          activeTab: activeTab,
          onTabChange: (tab) => ref.read(albumsTabProvider.notifier).set(tab),
        ),

        // Contenido según tab
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _TabContent(
            key: ValueKey(activeTab),
            activeTab: activeTab,
            model: model,
          ),
        ),
      ],
    );
  }
}

// ── Header con navegación tabs ────────────────────────────
class _CarouselHeader extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChange;

  const _CarouselHeader({
    required this.activeTab,
    required this.onTabChange,
  });

  static const _tabs = [
    ('legendary', 'Legendary'),
    ('stars', 'Stars'),
    ('cult', 'Cult'),
  ];

  int get _activeIdx => _tabs.indexWhere((t) => t.$1 == activeTab);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TUS ÁLBUMES',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: GsColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tabs.firstWhere((t) => t.$1 == activeTab).$2,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: GsColors.text,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),

          // Flechas
          Row(
            children: [
              _ArrowBtn(
                icon: Icons.chevron_left,
                enabled: _activeIdx > 0,
                onTap: () {
                  if (_activeIdx > 0) {
                    onTabChange(_tabs[_activeIdx - 1].$1);
                  }
                },
              ),
              const SizedBox(width: 4),
              _ArrowBtn(
                icon: Icons.chevron_right,
                enabled: _activeIdx < _tabs.length - 1,
                onTap: () {
                  if (_activeIdx < _tabs.length - 1) {
                    onTabChange(_tabs[_activeIdx + 1].$1);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ArrowBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? GsColors.card : GsColors.cream,
          border: Border.all(
            color: enabled
                ? GsColors.border.withValues(alpha: 0.3)
                : GsColors.border.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: enabled
              ? const [
                  BoxShadow(color: GsColors.shadow, offset: Offset(1, 1))
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? GsColors.text : GsColors.muted,
        ),
      ),
    );
  }
}

// ── Tab indicadores ───────────────────────────────────────
class _TabDots extends StatelessWidget {
  final String activeTab;

  const _TabDots({required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['legendary', 'stars', 'cult'].map((tab) {
        final isActive = tab == activeTab;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 6,
          height: 4,
          decoration: BoxDecoration(
            color: isActive ? GsColors.accent : GsColors.muted.withValues(alpha: 0.3),
          ),
        );
      }).toList(),
    );
  }
}

// ── Contenido por tab ─────────────────────────────────────
class _TabContent extends StatelessWidget {
  final String activeTab;
  final AlbumsModel model;

  const _TabContent({
    super.key,
    required this.activeTab,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),

        switch (activeTab) {
          'legendary' => LegendarySection(
              definitions: model.legendaryAlbums,
              progress: model.progressByAlbumId.values.toList(),
              collection: model.collection,
            ),
          'stars' => StarsSection(
              collection: model.collection,
              allCards: model.collection
                  .where((c) => c.card != null)
                  .map((c) => c.card!)
                  .toList(),
            ),
          'cult' => CultSection(
              definitions: model.cultAlbums,
              collection: model.collection,
              allCards: model.collection
                  .where((c) => c.card != null)
                  .map((c) => c.card!)
                  .toList(),
            ),
          _ => const SizedBox.shrink(),
        },

        const SizedBox(height: 12),

        // Dots indicador
        _TabDots(activeTab: activeTab),
        const SizedBox(height: 8),
      ],
    );
  }
}
