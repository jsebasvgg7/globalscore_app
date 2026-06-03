// lib/features/albums/presentation/albums_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/albums_provider.dart';
import '../domain/albums_model.dart';
import 'pack_opening_modal.dart';

// ── Paleta idéntica a stats ──────────────────────────────
const _accent  = Color(0xFF2D0CFF);
const _accentL = Color(0xFF7B61FF);
const _gold    = Color(0xFFFFD600);
const _bg      = Color(0xFFF5F0E8);
const _card    = Color(0xFFEDE7DA);
const _border  = Color(0xFF1A1A2E);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF555550);
const _shadow  = Color(0x661A1A2E);

// Colores por tipo de carta
const _colorPlayer      = Color(0xFF5B4FD8);
const _colorTeam        = Color(0xFF1D9E75);
const _colorCompetition = Color(0xFFF59E0B);
const _colorEvent       = Color(0xFFE55B5B);

Color _typeColor(String type) => switch (type) {
      'player'      => _colorPlayer,
      'team'        => _colorTeam,
      'competition' => _colorCompetition,
      'event'       => _colorEvent,
      _             => _accent,
    };

String _typeLabel(String type) => switch (type) {
      'player'      => 'JUG',
      'team'        => 'EQU',
      'competition' => 'COPA',
      'event'       => 'EVT',
      _             => '?',
    };

// ════════════════════════════════════════════════════════════
//  PAGE
// ════════════════════════════════════════════════════════════
class AlbumsPage extends ConsumerWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);
    final tab         = ref.watch(albumsTabProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _TopBar(tab: tab, ref: ref),
          Expanded(
            child: albumsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
              ),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.red, fontSize: 11)),
                ),
              ),
              data: (model) => _AlbumsBody(model: model, tab: tab),
            ),
          ),
        ],
      ),
    );
  }
}

// ══ TOP BAR ══════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final String tab;
  final WidgetRef ref;
  const _TopBar({required this.tab, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 22, color: _gold),
          const SizedBox(width: 8),
          const Text(
            'GLOBALALBUMS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: _text,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              for (final t in [
                ('legendary', 'LEG'),
                ('stars', 'STARS'),
                ('cult', 'CULTO'),
              ])
                _TabPill(
                  label: t.$2,
                  active: tab == t.$1,
                  onTap: () => ref.read(albumsTabProvider.notifier).set(t.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(left: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _gold : _bg,
          border: Border.all(color: _border, width: 1),
          boxShadow: active
              ? [const BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: active ? _border : _text,
          ),
        ),
      ),
    );
  }
}

// ══ BODY ════════════════════════════════════════════════
class _AlbumsBody extends StatelessWidget {
  final AlbumsModel model;
  final String tab;
  const _AlbumsBody({required this.model, required this.tab});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PacksHero(packs: model.packs),
          const _Divider(),
          _SectionHeader(label: 'MIS ESTADÍSTICAS', color: _accent),
          _StatsStrip(model: model),
          const _Divider(),
          _SectionHeader(
            label: switch (tab) {
              'legendary' => 'ÁLBUMES LEGENDARIOS',
              'stars'     => 'COLECCIÓN ESTRELLAS',
              _           => 'ÁLBUMES DE CULTO',
            },
            color: _gold,
          ),
          _AlbumList(
            definitions: switch (tab) {
              'legendary' => model.legendaryAlbums,
              'stars'     => model.starsAlbums,
              _           => model.cultAlbums,
            },
            model: model,
          ),
          const _Divider(),
          _SectionHeader(label: 'COLECCIÓN RECIENTE', color: _accentL),
          _RecentCards(items: model.collection.take(12).toList()),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ══ PACKS HERO ══════════════════════════════════════════
class _PacksHero extends ConsumerWidget {
  final AlbumPacks? packs;
  const _PacksHero({required this.packs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = packs?.packsAvailable ?? 0;
    final boost     = packs?.boostActive == true;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        children: [
          _PackIcon(boostActive: boost),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SOBRES DISPONIBLES',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: _muted),
                ),
                const SizedBox(height: 4),
                Text(
                  '$available',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -3,
                    height: 1,
                    color: _accent,
                  ),
                ),
                if (boost) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _gold,
                      border: Border.all(color: _border, width: 1),
                      boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1))],
                    ),
                    child: Text(
                      '⚡ BOOST ACTIVO · ${packs!.boostPacksRemaining} restantes',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _border),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  _BoostProgress(packs: packs),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ← lanza el modal; el modal maneja toda la lógica de apertura
          _OpenButton(
            available: available,
            onTap: available > 0
                ? () => showPackOpeningModal(context, ref)
                : null,
          ),
        ],
      ),
    );
  }
}

class _PackIcon extends StatelessWidget {
  final bool boostActive;
  const _PackIcon({required this.boostActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 80,
      decoration: BoxDecoration(
        color: boostActive ? _gold : _accent,
        border: Border.all(color: _border, width: 1.5),
        boxShadow: const [BoxShadow(color: _shadow, offset: Offset(2, 2), blurRadius: 0)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          if (boostActive)
            const Positioned(
              top: 4,
              right: 4,
              child: Text('⚡', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _BoostProgress extends StatelessWidget {
  final AlbumPacks? packs;
  const _BoostProgress({required this.packs});

  @override
  Widget build(BuildContext context) {
    final progress = packs?.barProgress ?? 0;
    final threshold = packs?.barThreshold ?? 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BOOST EN $progress/$threshold sobres',
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _muted),
        ),
        const SizedBox(height: 3),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress / threshold),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (_, v, __) => Container(
            height: 6,
            decoration: BoxDecoration(border: Border.all(color: _border, width: 1)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: Container(color: _gold),
            ),
          ),
        ),
      ],
    );
  }
}

class _OpenButton extends StatelessWidget {
  final int available;
  final VoidCallback? onTap;
  const _OpenButton({required this.available, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = available > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? _accent : _muted,
          border: Border.all(color: _border, width: 1),
          boxShadow: enabled
              ? [const BoxShadow(color: _shadow, offset: Offset(2, 2), blurRadius: 0)]
              : [],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, color: Colors.white, size: 20),
            SizedBox(height: 2),
            Text(
              'ABRIR',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══ STATS STRIP 3 cols ═══════════════════════════════════
class _StatsStrip extends StatelessWidget {
  final AlbumsModel model;
  const _StatsStrip({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          _StatCell(
            label: 'ÚNICAS',
            value: '${model.totalUniqueCards}',
            color: _accent,
            borderRight: true,
          ),
          _StatCell(
            label: 'TOTAL COPIAS',
            value: '${model.totalCopies}',
            color: _text,
            borderRight: true,
          ),
          _StatCell(
            label: 'GOAT ★',
            value: '${model.goatCards}',
            color: _gold,
            borderRight: false,
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool borderRight;
  const _StatCell({required this.label, required this.value, required this.color, required this.borderRight});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: _bg,
          border: Border(
            right: borderRight ? const BorderSide(color: _border, width: 1) : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: _muted)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1, color: color)),
          ],
        ),
      ),
    );
  }
}

// ══ ALBUM LIST ═══════════════════════════════════════════
class _AlbumList extends StatelessWidget {
  final List<AlbumDefinition> definitions;
  final AlbumsModel model;
  const _AlbumList({required this.definitions, required this.model});

  @override
  Widget build(BuildContext context) {
    if (definitions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('Sin álbumes en esta categoría',
              style: TextStyle(fontSize: 12, color: _muted)),
        ),
      );
    }

    return Column(
      children: definitions
          .map((def) => _AlbumRow(def: def, progress: model.progressFor(def.id)))
          .toList(),
    );
  }
}

class _AlbumRow extends StatelessWidget {
  final AlbumDefinition def;
  final AlbumProgress? progress;
  const _AlbumRow({required this.def, this.progress});

  @override
  Widget build(BuildContext context) {
    final unique     = progress?.uniqueCards ?? 0;
    final required   = def.requiredUniquePlayers ?? 0;
    final pct        = required > 0 ? (unique / required).clamp(0.0, 1.0) : 0.0;
    final completed  = progress?.isCompleted == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFF5F0D0) : _bg,
        border: const Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          // Badge tipo álbum
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _albumColor(def.albumType),
              border: Border.all(color: _border, width: 1),
              boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1))],
            ),
            alignment: Alignment.center,
            child: Text(
              _albumIcon(def.albumType),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(def.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: _text)),
                    ),
                    if (completed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _gold,
                          border: Border.all(color: _border, width: 1),
                        ),
                        child: const Text('✓',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _border)),
                      ),
                  ],
                ),
                if (def.description != null) ...[
                  const SizedBox(height: 2),
                  Text(def.description!,
                      style: const TextStyle(fontSize: 10, color: _muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: pct),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOut,
                        builder: (_, v, __) => Container(
                          height: 6,
                          decoration: BoxDecoration(border: Border.all(color: _border, width: 1)),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: v,
                            child: Container(color: _albumColor(def.albumType)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      required > 0 ? '$unique/$required' : '-',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: _text),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _albumColor(String type) => switch (type) {
        'legendary' => _gold,
        'stars'     => _accent,
        _           => _accentL,
      };

  String _albumIcon(String type) => switch (type) {
        'legendary' => '👑',
        'stars'     => '⭐',
        _           => '🎭',
      };
}

// ══ RECENT CARDS GRID ════════════════════════════════════
class _RecentCards extends StatelessWidget {
  final List<AlbumCollectionItem> items;
  const _RecentCards({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('Aún no tienes cartas',
              style: TextStyle(fontSize: 12, color: _muted)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.72,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _MiniCard(item: items[i]),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final AlbumCollectionItem item;
  const _MiniCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final card   = item.card;
    final type   = card?.cardType ?? 'player';
    final stars  = card?.significanceLevel ?? 1;
    final isGoat = card?.isGoat == true;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(
          color: _frameColor(item.frameLevel),
          width: isGoat ? 2 : 1,
        ),
        boxShadow: isGoat
            ? [BoxShadow(color: _gold.withValues(alpha: 0.5), offset: const Offset(0, 0), blurRadius: 8)]
            : [const BoxShadow(color: _shadow, offset: Offset(1, 1))],
      ),
      child: Stack(
        children: [
          // Gradiente de tipo
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _typeColor(type).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Imagen o placeholder
          if (card?.imagePath != null)
            Positioned.fill(
              child: Image.network(
                card!.imagePath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _CardPlaceholder(type: type),
              ),
            )
          else
            _CardPlaceholder(type: type),

          // Info overlay bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              color: _border.withValues(alpha: 0.75),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card?.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _typeLabel(type),
                        style: TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.w900,
                          color: _typeColor(type),
                        ),
                      ),
                      const Spacer(),
                      _StarDots(level: stars),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Badge de copias duplicadas
          if (item.isDuplicate)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                color: _border,
                child: Text(
                  'x${item.copies}',
                  style: const TextStyle(
                      fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),

          // Halo GOAT
          if (isGoat)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: _gold,
                child: const Text('GOAT',
                    style: TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: _border)),
              ),
            ),
        ],
      ),
    );
  }

  Color _frameColor(String level) => switch (level) {
        'silver'    => const Color(0xFFB0B0B0),
        'gold'      => _gold,
        'legendary' => const Color(0xFFBF5AF2),
        _           => _border,
      };
}

class _CardPlaceholder extends StatelessWidget {
  final String type;
  const _CardPlaceholder({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: _typeColor(type).withValues(alpha: 0.1),
      child: Icon(
        switch (type) {
          'player'      => Icons.person,
          'team'        => Icons.shield,
          'competition' => Icons.emoji_events,
          _             => Icons.history_edu,
        },
        color: _typeColor(type).withValues(alpha: 0.5),
        size: 28,
      ),
    );
  }
}

class _StarDots extends StatelessWidget {
  final int level;
  const _StarDots({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            color: i < level ? _gold : _muted.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ══ HELPERS ═════════════════════════════════════════════
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: _border);
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: _text)),
        ],
      ),
    );
  }
}