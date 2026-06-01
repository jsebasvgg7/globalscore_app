import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import '../widgets/history_app_bar.dart';

// ── Paleta ────────────────────────────────────────────────────
const _kBg     = Color(0xFFF0EDE8);
const _kDark   = Color(0xFF1A1A2E);
const _kAccent = Color(0xFF5B4FD8);
const _kGold   = Color(0xFFF59E0B);
const _kGreen  = Color(0xFF1D9E75);
const _kMuted  = Color(0xFF88887D);
const _kBorder = Color(0xFFC4BFB8);
const _kCard   = Color(0xFFEBE7E1);

TextStyle _mono({
  Color color = _kDark,
  double size = 12,
  FontWeight weight = FontWeight.normal,
  double letterSpacing = 0,
}) =>
    GoogleFonts.dmMono(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      decoration: TextDecoration.none,
    );

// ── Helpers ───────────────────────────────────────────────────
const _positionLabel = {
  'Forward': 'Delantero',
  'Midfielder': 'Centrocampista',
  'Play-maker': 'Media Punta',
  'All-rounder': 'Todocampista',
  'Defender': 'Defensor',
  'Goalkeeper': 'Portero',
};

const _legacyLabel = {
  'Goal Scorer': 'Goleador',
  'Tactician': 'Táctico',
  'Innovator': 'Genio',
  'Leader': 'Líder',
  'Goalkeeper': 'Portero',
  'Technician': 'Técnico',
};

const _titleCatLabel = {
  'club': 'Club',
  'national': 'Selección',
  'individual': 'Individual',
};

const _titleCatColor = {
  'club': _kAccent,
  'national': _kGreen,
  'individual': _kGold,
};

const _sigLabel = ['', 'Activo', 'Notable', 'Icónico', 'Leyenda', 'GOAT'];

const _positions = [
  'Forward', 'Midfielder', 'Defender', 'Goalkeeper', 'All-rounder', 'Play-maker'
];

// ══════════════════════════════════════════════════════════════
//  PLAYERS PAGE — root
// ══════════════════════════════════════════════════════════════

class HistoryPlayersPage extends ConsumerStatefulWidget {
  const HistoryPlayersPage({super.key});

  @override
  ConsumerState<HistoryPlayersPage> createState() => _HistoryPlayersPageState();
}

class _HistoryPlayersPageState extends ConsumerState<HistoryPlayersPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedPlayerProvider);
    if (selected != null) return _PlayerDetailView(player: selected);
    return _PlayerListView(searchCtrl: _searchCtrl);
  }
}

// ══════════════════════════════════════════════════════════════
//  LIST VIEW — estilo imagen 1 (lista limpia con foto + info)
// ══════════════════════════════════════════════════════════════

class _PlayerListView extends ConsumerWidget {
  final TextEditingController searchCtrl;
  const _PlayerListView({required this.searchCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(filteredPlayersProvider);
    final allAsync    = ref.watch(historyPlayersProvider);
    final posFilter   = ref.watch(playerPositionFilterProvider);

    final totalCount = allAsync.whenOrNull(data: (l) => l.length) ?? 0;
    final goatCount  = allAsync.whenOrNull(
          data: (l) => l.where((p) => (p.significanceLevel ?? 0) == 5).length,
        ) ?? 0;
    final countriesCount = allAsync.whenOrNull(
          data: (l) => l.map((p) => p.country).whereType<String>().toSet().length,
        ) ?? 0;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // App Bar
          HistoryAppBar(
            title: 'JUGADORES',
            subtitle: 'Explora las leyendas que dejaron\nsu huella en la historia.',
            icon: Icons.person_outline_rounded,
            onBack: () => ref.read(historySectionProvider.notifier).goBack(),
          ),

          // Stats strip — 149 JUGADORES · 34 GOATS · 82 PAÍSES
          _StatsStrip(
            total: totalCount,
            goats: goatCount,
            countries: countriesCount,
          ),

          // Search + filter button
          _SearchBar(controller: searchCtrl),

          // Position filter tabs
          _PositionFilterRow(active: posFilter),

          // Results count
          playersAsync.whenOrNull(
            data: (players) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
              ),
              child: Row(
                children: [
                  Text(
                    'JUGADORES',
                    style: _mono(size: 9, weight: FontWeight.w700,
                        letterSpacing: 1.0, color: _kMuted),
                  ),
                  const Spacer(),
                  Text(
                    '${players.length}',
                    style: _mono(size: 9, weight: FontWeight.w700,
                        letterSpacing: 0.5, color: _kAccent),
                  ),
                ],
              ),
            ),
          ) ?? const SizedBox.shrink(),

          // List
          Expanded(
            child: playersAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _kAccent)),
              error: (e, _) => Center(
                  child: Text('Error: $e', style: _mono(color: _kMuted))),
              data: (players) {
                if (players.isEmpty) {
                  return Center(
                    child: Text('Sin resultados',
                        style: _mono(color: _kMuted)),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: players.length,
                  itemBuilder: (_, i) => _PlayerListRow(
                    player: players[i],
                    onTap: () => ref
                        .read(selectedPlayerProvider.notifier)
                        .select(players[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats strip (3 cajas) ─────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final int total;
  final int goats;
  final int countries;
  const _StatsStrip({
    required this.total,
    required this.goats,
    required this.countries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          _StatCell(
            icon: Icons.person_outline_rounded,
            iconBg: _kAccent,
            value: '$total',
            label: 'JUGADORES',
            bordered: true,
          ),
          _StatCell(
            icon: Icons.star_border_rounded,
            iconBg: _kGold,
            value: '$goats',
            label: 'GOATS',
            bordered: true,
          ),
          _StatCell(
            icon: Icons.public_outlined,
            iconBg: _kGreen,
            value: '$countries',
            label: 'PAÍSES',
            bordered: false,
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String value;
  final String label;
  final bool bordered;
  const _StatCell({
    required this.icon,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.bordered,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: bordered
              ? const Border(right: BorderSide(color: _kBorder, width: 0.5))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg.withOpacity(0.12),
                border: Border.all(color: iconBg.withOpacity(0.3)),
              ),
              child: Icon(icon, size: 15, color: iconBg),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: _mono(
                        size: 18, weight: FontWeight.w900, color: _kDark)),
                Text(label,
                    style: _mono(
                        size: 7,
                        weight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: _kMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────
class _SearchBar extends ConsumerWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: _kBorder),
                color: Colors.white,
              ),
              child: TextField(
                controller: controller,
                style: _mono(size: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar jugador...',
                  hintStyle: _mono(size: 12, color: _kMuted),
                  prefixIcon:
                      const Icon(Icons.search, size: 15, color: _kMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 13),
                          onPressed: () {
                            controller.clear();
                            ref.read(playerSearchProvider.notifier).set('');
                          },
                        )
                      : null,
                ),
                onChanged: (v) =>
                    ref.read(playerSearchProvider.notifier).set(v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filtros button (placeholder, mismo estilo que la imagen)
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: _kBorder),
              color: _kBg,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune_rounded, size: 13, color: _kMuted),
                const SizedBox(width: 6),
                Text('FILTROS',
                    style: _mono(
                        size: 9,
                        weight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: _kMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Position filter tabs ──────────────────────────────────────
class _PositionFilterRow extends ConsumerWidget {
  final String active;
  const _PositionFilterRow({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _TabChip(
            label: 'TODOS',
            isActive: active.isEmpty,
            onTap: () =>
                ref.read(playerPositionFilterProvider.notifier).set(''),
          ),
          ..._positions.map((pos) => _TabChip(
                label: (_positionLabel[pos] ?? pos).toUpperCase(),
                isActive: active == pos,
                onTap: () =>
                    ref.read(playerPositionFilterProvider.notifier).set(pos),
              )),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? _kAccent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: _mono(
            size: 9,
            weight: FontWeight.w700,
            letterSpacing: 0.6,
            color: isActive ? _kAccent : _kMuted,
          ),
        ),
      ),
    );
  }
}

// ── Player list row (estilo imagen 1) ─────────────────────────
class _PlayerListRow extends StatelessWidget {
  final HistoricalPlayer player;
  final VoidCallback onTap;
  const _PlayerListRow({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(player.imagePath);
    final sig = player.significanceLevel ?? 0;
    final isGoat = sig == 5;
    final isActive = sig == 1;

    final lifespan = player.birthYear != null
        ? '${player.birthYear} - ${player.deathYear?.toString() ?? 'Presente'}'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _kBorder, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Imagen con badge GOAT
            Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  color: _kAccent.withOpacity(0.07),
                  child: imgUrl != null
                      ? Image.network(imgUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _Initials(name: player.name, size: 72))
                      : _Initials(name: player.name, size: 72),
                ),
                // Número / número de camiseta
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    color: _kDark.withOpacity(0.7),
                    child: Text(
                      '#${_playerNumber(player)}',
                      style: _mono(
                          size: 8,
                          weight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
                if (isGoat)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      color: _kGold,
                      child: Text(
                        'GOAT',
                        style: _mono(
                            size: 7,
                            weight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.black),
                      ),
                    ),
                  ),
              ],
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + badge GOAT inline
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: _mono(
                                size: 14, weight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isGoat) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            color: _kGold,
                            child: Text(
                              'GOAT',
                              style: _mono(
                                  size: 7,
                                  weight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Colors.black),
                            ),
                          ),
                        ] else if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: _kGreen.withOpacity(0.4)),
                              color: _kGreen.withOpacity(0.08),
                            ),
                            child: Text(
                              'ACTIVO',
                              style: _mono(
                                  size: 7,
                                  weight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: _kGreen),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 3),

                    // País · Posición
                    Row(
                      children: [
                        if (player.country != null) ...[
                          Text(player.country!,
                              style: _mono(size: 10, color: _kMuted)),
                          if (player.position != null)
                            Text(' · ',
                                style: _mono(size: 10, color: _kBorder)),
                        ],
                        if (player.position != null)
                          Text(
                            _positionLabel[player.position!] ??
                                player.position!,
                            style: _mono(size: 10, color: _kMuted),
                          ),
                      ],
                    ),

                    // Años de vida
                    if (lifespan != null) ...[
                      const SizedBox(height: 2),
                      Text(lifespan,
                          style: _mono(size: 9, color: _kMuted)),
                    ],
                  ],
                ),
              ),
            ),

            // Estrellas + chevron
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (sig >= 2) _Stars(level: sig, size: 9),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right,
                      size: 16, color: _kMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Número decorativo basado en el índice del jugador
String _playerNumber(HistoricalPlayer p) {
  // Usamos los últimos 2 dígitos del hash del ID como número
  final hash = p.id.hashCode.abs() % 99 + 1;
  return hash.toString();
}

// ── Stars widget ──────────────────────────────────────────────
class _Stars extends StatelessWidget {
  final int level;
  final double size;
  const _Stars({required this.level, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < level;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: filled ? _kGold : _kBorder,
        );
      }),
    );
  }
}

// ── Initials fallback ─────────────────────────────────────────
class _Initials extends StatelessWidget {
  final String name;
  final double size;
  const _Initials({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          initials,
          style: _mono(
              size: size * 0.27,
              weight: FontWeight.w800,
              color: _kAccent),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DETAIL VIEW — completo con carrera, nacional, títulos
// ══════════════════════════════════════════════════════════════

class _PlayerDetailView extends ConsumerWidget {
  final HistoricalPlayer player;
  const _PlayerDetailView({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(playerDetailProvider(player.id));

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          HistoryAppBar(
            title: player.name.toUpperCase(),
            subtitle: player.country ?? '',
            icon: Icons.person_outline_rounded,
            onBack: () =>
                ref.read(selectedPlayerProvider.notifier).select(null),
          ),
          Expanded(
            child: detailAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _kAccent)),
              error: (e, _) => Center(
                  child: Text('Error: $e', style: _mono(color: _kMuted))),
              data: (detail) => _DetailBody(detail: detail),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final PlayerDetail detail;
  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    final p = detail.player;
    final sig = p.significanceLevel ?? 0;
    final isGoat = sig == 5;
    final isActive = sig == 1;
    final imgUrl = getHistoricalImageUrl(p.imagePath);

    final lifespan = p.birthYear != null
        ? '${p.birthYear}${p.deathYear != null ? ' – ${p.deathYear}' : ' – Presente'}'
        : null;

    // Totales carrera
    int totalGoals = 0, totalAssists = 0, totalApps = 0;
    for (final c in detail.career) {
      totalGoals += c.goals;
      totalAssists += c.assists;
      totalApps += c.appearances;
    }
    for (final n in detail.national) {
      totalGoals += n.goals;
    }

    int totalCaps = 0, nationalGoals = 0;
    for (final n in detail.national) {
      totalCaps += n.caps;
      nationalGoals += n.goals;
    }

    int titlesCount = 0;
    for (final t in detail.titles) {
      if (t.titleCategory != 'individual') titlesCount += t.quantity;
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _kBorder)),
              color: _kCard,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        border: Border.all(color: _kBorder),
                        color: _kAccent.withOpacity(0.06),
                      ),
                      child: imgUrl != null
                          ? Image.network(imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _Initials(name: p.name, size: 88))
                          : _Initials(name: p.name, size: 88),
                    ),
                    if (isGoat)
                      Positioned(
                        bottom: -1,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: _kGold,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            'GOAT',
                            textAlign: TextAlign.center,
                            style: _mono(
                                size: 7,
                                weight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: Colors.black),
                          ),
                        ),
                      ),
                    if (isActive)
                      Positioned(
                        bottom: -1,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: _kGreen,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            'EN ACTIVO',
                            textAlign: TextAlign.center,
                            style: _mono(
                                size: 7,
                                weight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: _mono(
                              size: 18, weight: FontWeight.w900)),
                      const SizedBox(height: 8),

                      // Estrellas + nivel
                      if (sig >= 2)
                        Row(
                          children: [
                            _Stars(level: sig, size: 11),
                            const SizedBox(width: 6),
                            Text(
                              sig < _sigLabel.length
                                  ? _sigLabel[sig]
                                  : '',
                              style: _mono(
                                  size: 9,
                                  color: sig == 5 ? _kGold : _kMuted,
                                  weight: FontWeight.w700,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      const SizedBox(height: 10),

                      // Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          if (p.country != null)
                            _Chip(label: p.country!,
                                icon: Icons.flag_outlined),
                          if (p.position != null)
                            _Chip(
                              label: _positionLabel[p.position!] ??
                                  p.position!,
                              icon: Icons.sports_soccer_outlined,
                              color: _kAccent,
                            ),
                          if (lifespan != null)
                            _Chip(
                                label: lifespan,
                                icon: Icons.access_time_rounded),
                          if ((p.ballonDorCount ?? 0) > 0)
                            _Chip(
                              label:
                                  '${p.ballonDorCount} Balón${p.ballonDorCount! > 1 ? "es" : ""} de Oro',
                              icon: Icons.emoji_events_outlined,
                              color: _kGold,
                            ),
                          if (p.legacyType != null)
                            _Chip(
                              label: _legacyLabel[p.legacyType!] ??
                                  p.legacyType!,
                              icon: Icons.auto_awesome_outlined,
                              color: _kAccent,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Stats strip ────────────────────────────────────────
        if (detail.career.isNotEmpty || detail.national.isNotEmpty || titlesCount > 0)
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    if (detail.career.isNotEmpty) ...[
                      _StatCell2(value: '${detail.career.length}', label: 'CLUBES'),
                      _StatCell2(value: '$totalGoals', label: 'GOLES', bordered: true),
                      if (totalAssists > 0)
                        _StatCell2(value: '$totalAssists', label: 'ASIST.', bordered: true),
                    ],
                    if (detail.national.isNotEmpty) ...[
                      _StatCell2(
                          value: '$totalCaps',
                          label: 'INT\'L PART.',
                          color: _kGreen,
                          bordered: detail.career.isNotEmpty),
                      _StatCell2(
                          value: '$nationalGoals',
                          label: 'INT\'L GOLES',
                          color: _kGreen,
                          bordered: true),
                    ],
                    if (titlesCount > 0)
                      _StatCell2(
                          value: '$titlesCount',
                          label: 'TÍTULOS',
                          color: _kGold,
                          bordered: detail.career.isNotEmpty ||
                              detail.national.isNotEmpty),
                  ],
                ),
              ),
            ),
          ),

        // ── Trascendencia ──────────────────────────────────────
        if (p.impactSummary != null)
          SliverToBoxAdapter(
            child: _Section(
              label: 'TRASCENDENCIA',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border:
                      Border(left: BorderSide(color: _kAccent, width: 3)),
                  color: _kAccent.withOpacity(0.04),
                ),
                child: Text(p.impactSummary!,
                    style: _mono(size: 13, color: _kDark)),
              ),
            ),
          ),

        // ── Historia ────────────────────────────────────────────
        if (p.description != null)
          SliverToBoxAdapter(
            child: _Section(
              label: 'HISTORIA',
              child: Text(p.description!,
                  style: _mono(size: 12, color: _kMuted,
                      letterSpacing: 0)),
            ),
          ),

        // ── Trayectoria en clubes ───────────────────────────────
        if (detail.career.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              label: 'TRAYECTORIA EN CLUBES',
              child: _CareerTable(rows: detail.career),
            ),
          ),

        // ── Selección nacional ──────────────────────────────────
        if (detail.national.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              label: 'SELECCIÓN NACIONAL',
              child: _NationalTable(rows: detail.national),
            ),
          ),

        // ── Palmarés ────────────────────────────────────────────
        if (detail.titles.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              label: 'PALMARÉS',
              child: _TitlesList(titles: detail.titles),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

// ── Stat cell para detalle ────────────────────────────────────
class _StatCell2 extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool bordered;
  const _StatCell2({
    required this.value,
    required this.label,
    this.color = _kDark,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: bordered
              ? const Border(left: BorderSide(color: _kBorder, width: 0.5))
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: _mono(
                    size: 22, weight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: _mono(
                    size: 7,
                    weight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _kMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────
class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 12, color: _kAccent),
              const SizedBox(width: 7),
              Text(
                label,
                style: _mono(
                    size: 9,
                    weight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: _kMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Chip({
    required this.label,
    required this.icon,
    this.color = _kMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
            color: color == _kMuted
                ? _kBorder
                : color.withOpacity(0.3)),
        color: color == _kMuted
            ? Colors.transparent
            : color.withOpacity(0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: _mono(
                  size: 9,
                  color: color == _kMuted ? _kDark : color)),
        ],
      ),
    );
  }
}

// ── Career table ──────────────────────────────────────────────
class _CareerTable extends StatelessWidget {
  final List<PlayerCareerEntry> rows;
  const _CareerTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const BoxDecoration(
            color: _kCard,
            border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                  flex: 3,
                  child: Text('CLUB',
                      style: _mono(
                          size: 8,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _kMuted))),
              Expanded(
                  flex: 2,
                  child: Text('PERÍODO',
                      style: _mono(
                          size: 8,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _kMuted))),
              SizedBox(
                  width: 36,
                  child: Text('PJ',
                      textAlign: TextAlign.center,
                      style: _mono(
                          size: 8,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _kMuted))),
              SizedBox(
                  width: 36,
                  child: Text('G',
                      textAlign: TextAlign.center,
                      style: _mono(
                          size: 8,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _kMuted))),
              SizedBox(
                  width: 36,
                  child: Text('A',
                      textAlign: TextAlign.center,
                      style: _mono(
                          size: 8,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _kMuted))),
            ],
          ),
        ),
        ...rows.map((r) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: _kBorder, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.teamName,
                            style: _mono(
                                size: 12, weight: FontWeight.w700)),
                        if (r.teamCountry != null)
                          Text(r.teamCountry!,
                              style: _mono(size: 9, color: _kMuted)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${r.startYear ?? '?'} – ${r.endYear ?? '?'}',
                      style: _mono(
                          size: 10, color: _kAccent),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      r.appearances > 0 ? '${r.appearances}' : '—',
                      textAlign: TextAlign.center,
                      style: _mono(
                          size: 11, weight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      r.goals > 0 ? '${r.goals}' : '—',
                      textAlign: TextAlign.center,
                      style: _mono(
                          size: 11, weight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      r.assists > 0 ? '${r.assists}' : '—',
                      textAlign: TextAlign.center,
                      style: _mono(
                          size: 11, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ── National table ────────────────────────────────────────────
class _NationalTable extends StatelessWidget {
  final List<PlayerNationalEntry> rows;
  const _NationalTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const BoxDecoration(
            color: _kCard,
            border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                  flex: 3,
                  child: Text('SELECCIÓN',
                      style: _mono(
                          size: 8,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _kMuted))),
              Expanded(
                  flex: 2,
                  child: Text('PERÍODO',
                      style: _mono(
                          size: 8,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _kMuted))),
              SizedBox(
                  width: 36,
                  child: Text('PJ',
                      textAlign: TextAlign.center,
                      style: _mono(
                          size: 8,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _kMuted))),
              SizedBox(
                  width: 36,
                  child: Text('G',
                      textAlign: TextAlign.center,
                      style: _mono(
                          size: 8,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _kMuted))),
            ],
          ),
        ),
        ...rows.map((r) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: _kBorder, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(r.country,
                        style: _mono(
                            size: 12, weight: FontWeight.w700)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${r.startYear ?? '?'} – ${r.endYear ?? '?'}',
                      style: _mono(size: 10, color: _kGreen),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      r.caps > 0 ? '${r.caps}' : '—',
                      textAlign: TextAlign.center,
                      style: _mono(
                          size: 11, weight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      r.goals > 0 ? '${r.goals}' : '—',
                      textAlign: TextAlign.center,
                      style: _mono(
                          size: 11, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ── Titles list ───────────────────────────────────────────────
class _TitlesList extends StatelessWidget {
  final List<PlayerTitleEntry> titles;
  const _TitlesList({required this.titles});

  @override
  Widget build(BuildContext context) {
    // Agrupar por categoría
    final Map<String, List<PlayerTitleEntry>> grouped = {};
    for (final t in titles) {
      grouped.putIfAbsent(t.titleCategory, () => []).add(t);
    }

    final order = ['club', 'national', 'individual'];

    return Column(
      children: order.where((c) => grouped.containsKey(c)).map((cat) {
        final catTitles = grouped[cat]!;
        final catColor = _titleCatColor[cat] ?? _kAccent;
        final catLabel = _titleCatLabel[cat] ?? cat;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categoría label
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: catColor,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    catLabel.toUpperCase(),
                    style: _mono(
                        size: 9,
                        weight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: catColor),
                  ),
                ],
              ),
            ),
            ...catTitles.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: catColor, width: 2),
                      bottom: const BorderSide(
                          color: _kBorder, width: 0.5),
                    ),
                    color: _kBg,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 11, color: catColor.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t.titleName,
                            style: _mono(
                                size: 12, weight: FontWeight.w700)),
                      ),
                      if (t.teamName != null) ...[
                        const SizedBox(width: 6),
                        Text(t.teamName!,
                            style: _mono(
                                size: 9, color: _kMuted)),
                      ],
                      if (t.year != null) ...[
                        const SizedBox(width: 8),
                        Text(t.year!,
                            style: _mono(
                                size: 10,
                                weight: FontWeight.w700,
                                color: catColor)),
                      ],
                      if (t.quantity > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _kGold.withOpacity(0.1),
                            border: Border.all(
                                color: _kGold.withOpacity(0.3)),
                          ),
                          child: Text('×${t.quantity}',
                              style: _mono(
                                  size: 9,
                                  weight: FontWeight.w800,
                                  color: _kGold)),
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        );
      }).toList(),
    );
  }
}