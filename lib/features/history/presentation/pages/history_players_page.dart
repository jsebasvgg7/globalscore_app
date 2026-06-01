import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import '../widgets/history_app_bar.dart';

// ── Paleta (consistente con el resto de history) ──────────────
const _kBg     = Color(0xFFF0EDE8);
const _kDark   = Color(0xFF1A1A2E);
const _kAccent = Color(0xFF5B4FD8);
const _kGold   = Color(0xFFF59E0B);
const _kGreen  = Color(0xFF1D9E75);
const _kMuted  = Color(0xFF88887D);
const _kBorder = Color(0xFFC4BFB8);

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

const _positions = [
  'Forward', 'Midfielder', 'Defender', 'Goalkeeper', 'All-rounder', 'Play-maker'
];

// ══════════════════════════════════════════════════════════════
//  PLAYERS PAGE
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
//  LIST VIEW
// ══════════════════════════════════════════════════════════════

class _PlayerListView extends ConsumerWidget {
  final TextEditingController searchCtrl;
  const _PlayerListView({required this.searchCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(filteredPlayersProvider);
    final posFilter   = ref.watch(playerPositionFilterProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          HistoryAppBar(
            title: 'LEYENDAS',
            subtitle: 'Jugadores históricos del fútbol',
            icon: Icons.person_outline_rounded,
            onBack: () => ref.read(historySectionProvider.notifier).goBack(),
          ),

          // Search
          _SearchBar(controller: searchCtrl),

          // Position filter
          _PositionFilterRow(active: posFilter),

          // List
          Expanded(
            child: playersAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _kAccent)),
              error: (e, _) =>
                  Center(child: Text('Error: $e', style: _mono(color: _kMuted))),
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
                  itemBuilder: (_, i) => _PlayerCard(
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

// ── Search bar ────────────────────────────────────────────────
class _SearchBar extends ConsumerWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: _kBorder),
          color: Colors.white,
        ),
        child: TextField(
          controller: controller,
          style: _mono(size: 12),
          decoration: InputDecoration(
            hintText: 'Buscar jugador, país…',
            hintStyle: _mono(size: 12, color: _kMuted),
            prefixIcon:
                const Icon(Icons.search, size: 16, color: _kMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 14),
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
    );
  }
}

// ── Position filter ───────────────────────────────────────────
class _PositionFilterRow extends ConsumerWidget {
  final String active;
  const _PositionFilterRow({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // "TODOS" chip
          _FilterChip(
            label: 'TODOS',
            isActive: active.isEmpty,
            onTap: () =>
                ref.read(playerPositionFilterProvider.notifier).set(''),
          ),
          ..._positions.map((pos) => _FilterChip(
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color: isActive ? _kAccent : Colors.transparent,
        child: Center(
          child: Text(
            label,
            style: _mono(
              size: 9,
              weight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isActive ? Colors.white : _kMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PLAYER CARD (list item)
// ══════════════════════════════════════════════════════════════

class _PlayerCard extends StatelessWidget {
  final HistoricalPlayer player;
  final VoidCallback onTap;
  const _PlayerCard({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(player.imagePath);
    final sigLevel = _sigLevel(player);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: const BorderSide(color: _kBorder, width: 0.5),
            left: BorderSide(
              color: _sigColor(sigLevel),
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: _kBorder),
                color: _kAccent.withOpacity(0.06),
              ),
              child: imgUrl != null
                  ? Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _PlayerInitials(name: player.name),
                    )
                  : _PlayerInitials(name: player.name),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.name,
                          style: _mono(
                              size: 14, weight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StarsOrActive(level: sigLevel),
                    ],
                  ),
                  const SizedBox(height: 3),
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
                  if (player.impactSummary != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      player.impactSummary!,
                      style: _mono(
                          size: 10,
                          color: _kMuted,
                          letterSpacing: 0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const Icon(Icons.chevron_right, size: 16, color: _kMuted),
          ],
        ),
      ),
    );
  }
}

class _PlayerInitials extends StatelessWidget {
  final String name;
  const _PlayerInitials({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
    return Center(
      child: Text(initials,
          style: _mono(
              size: 14, weight: FontWeight.w800, color: _kAccent)),
    );
  }
}

// ── Significance helpers ──────────────────────────────────────
// En React se usa significance_level (1-5), en Flutter no tenemos ese campo
// en el modelo base. Usamos ballonDorWins como proxy de nivel.
// Nivel derivado: 0=sin datos, 1=activo, 2-5=estrellitas según ballon dor
int _sigLevel(HistoricalPlayer p) {
  if (p.ballonDorWins != null && p.ballonDorWins! >= 5) return 5;
  if (p.ballonDorWins != null && p.ballonDorWins! >= 3) return 4;
  if (p.ballonDorWins != null && p.ballonDorWins! >= 1) return 3;
  return 0; // sin datos
}

Color _sigColor(int level) {
  switch (level) {
    case 5: return _kGold;
    case 4: return _kAccent;
    case 3: return _kGreen;
    default: return _kBorder;
  }
}

class _StarsOrActive extends StatelessWidget {
  final int level;
  const _StarsOrActive({required this.level});

  @override
  Widget build(BuildContext context) {
    if (level == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < level;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 9,
          color: filled ? _kGold : _kBorder,
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DETAIL VIEW
// ══════════════════════════════════════════════════════════════

class _PlayerDetailView extends ConsumerWidget {
  final HistoricalPlayer player;
  const _PlayerDetailView({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imgUrl = getHistoricalImageUrl(player.imagePath);
    final sigLevel = _sigLevel(player);

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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero
                SliverToBoxAdapter(
                  child: _DetailHero(
                    player: player,
                    imgUrl: imgUrl,
                    sigLevel: sigLevel,
                  ),
                ),

                // Description
                if (player.description != null)
                  SliverToBoxAdapter(
                    child: _DetailSection(
                      label: 'HISTORIA',
                      child: Text(
                        player.description!,
                        style: _mono(size: 12, color: _kMuted),
                      ),
                    ),
                  ),

                // Legacy
                if (player.impactSummary != null)
                  SliverToBoxAdapter(
                    child: _DetailSection(
                      label: 'TRASCENDENCIA',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: _kAccent, width: 3),
                          ),
                          color: _kAccent.withOpacity(0.04),
                        ),
                        child: Text(
                          player.impactSummary!,
                          style: _mono(size: 13, color: _kDark),
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  final HistoricalPlayer player;
  final String? imgUrl;
  final int sigLevel;
  const _DetailHero({
    required this.player,
    required this.imgUrl,
    required this.sigLevel,
  });

  @override
  Widget build(BuildContext context) {
    final lifespan = player.birthYear != null
        ? '${player.birthYear}${player.deathYear != null ? ' – ${player.deathYear}' : ' – presente'}'
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Column(
        children: [
          // Image + GOAT chip
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: _kBorder),
                  color: _kAccent.withOpacity(0.06),
                ),
                child: imgUrl != null
                    ? Image.network(imgUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _PlayerInitials(name: player.name))
                    : _PlayerInitials(name: player.name),
              ),
              if (sigLevel == 5)
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
                          size: 8,
                          weight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.black),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            player.name,
            textAlign: TextAlign.center,
            style: _mono(size: 20, weight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          // Stars
          if (sigLevel > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Icon(
                i < sigLevel ? Icons.star : Icons.star_border,
                size: 14,
                color: i < sigLevel ? _kGold : _kBorder,
              )),
            ),
          const SizedBox(height: 10),

          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              if (player.country != null)
                _InfoChip(label: player.country!, icon: Icons.flag_outlined),
              if (player.position != null)
                _InfoChip(
                  label: _positionLabel[player.position!] ?? player.position!,
                  icon: Icons.sports_soccer_outlined,
                  color: _kAccent,
                ),
              if (lifespan != null)
                _InfoChip(
                    label: lifespan,
                    icon: Icons.access_time_rounded),
              if (player.ballonDorWins != null && player.ballonDorWins! > 0)
                _InfoChip(
                  label: '${player.ballonDorWins} Balón${player.ballonDorWins! > 1 ? "es" : ""} de Oro',
                  icon: Icons.emoji_events_outlined,
                  color: _kGold,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _InfoChip({
    required this.label,
    required this.icon,
    this.color = _kMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        color: color == _kMuted ? Colors.transparent : color.withOpacity(0.06),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 5),
          Text(label, style: _mono(size: 10, color: color == _kMuted ? _kDark : color)),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _DetailSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: _kBorder, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                    width: 3, height: 12, color: _kAccent),
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
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}