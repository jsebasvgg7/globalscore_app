import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import '../../../../../shared/layout/scaffold_with_nav_bar.dart'
    show hideTopBarProvider, hideBottomNavProvider;
import '../../data/history_service.dart';
import 'history_players_shared.dart';
import 'history_player_detail.dart';

// ── Providers de filtro locales ───────────────────────────────
final playerLegacyFilterProvider =
    NotifierProvider<_StringNotifier, String>(_StringNotifier.new);
final playerSigFilterProvider =
    NotifierProvider<_IntNotifier, int>(_IntNotifier.new);

class _StringNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

class _IntNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int v) => state = v;
}

// ══════════════════════════════════════════════════════════════
//  ROOT
// ══════════════════════════════════════════════════════════════

class HistoryPlayersPage extends ConsumerStatefulWidget {
  const HistoryPlayersPage({super.key});

  @override
  ConsumerState<HistoryPlayersPage> createState() => _HistoryPlayersPageState();
}

class _HistoryPlayersPageState extends ConsumerState<HistoryPlayersPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hideTopBarProvider.notifier).hide();
      ref.read(hideBottomNavProvider.notifier).hide();
      // Reset tab al entrar
      ref.read(playerDetailTabProvider.notifier).set(PlayerDetailTab.resumen);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleBack() {
    ref.read(hideTopBarProvider.notifier).show();
    ref.read(hideBottomNavProvider.notifier).show();
    ref.read(historySectionProvider.notifier).goBack();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedPlayerProvider);

    if (selected != null) {
      return HistoryPlayerDetail(
        player: selected,
        onBack: () => ref.read(selectedPlayerProvider.notifier).select(null),
      );
    }

    return _PlayerListView(searchCtrl: _searchCtrl, onBack: _handleBack);
  }
}

// ══════════════════════════════════════════════════════════════
//  LIST VIEW
// ══════════════════════════════════════════════════════════════

class _PlayerListView extends ConsumerWidget {
  final TextEditingController searchCtrl;
  final VoidCallback onBack;
  const _PlayerListView({required this.searchCtrl, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(filteredPlayersProvider);
    final allAsync    = ref.watch(historyPlayersProvider);
    final legacyFilter = ref.watch(playerLegacyFilterProvider);
    final sigFilter    = ref.watch(playerSigFilterProvider);

    final totalCount = allAsync.whenOrNull(data: (l) => l.length) ?? 0;
    final goatCount  = allAsync.whenOrNull(
          data: (l) => l.where((p) => (p.significanceLevel ?? 0) == 5).length,
        ) ?? 0;
    final countriesCount = allAsync.whenOrNull(
          data: (l) =>
              l.map((p) => p.country).whereType<String>().toSet().length,
        ) ?? 0;

    final filteredAsync = playersAsync.whenData((players) {
      var list = players;
      if (legacyFilter.isNotEmpty) {
        list = list.where((p) => p.legacyType == legacyFilter).toList();
      }
      if (sigFilter > 0) {
        list = list.where((p) => (p.significanceLevel ?? 0) == sigFilter).toList();
      }
      return list;
    });

    return Scaffold(
      backgroundColor: kHistBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),

          _PlayersHeader(onBack: onBack),

          _StatsStrip(
            total: totalCount,
            goats: goatCount,
            countries: countriesCount,
          ),

          _SearchBar(controller: searchCtrl),

          filteredAsync.whenOrNull(
            data: (players) => _CounterRow(count: players.length),
          ) ?? const SizedBox.shrink(),

          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: kHistAccent)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: monoStyle(color: kHistMuted))),
              data: (players) {
                if (players.isEmpty) {
                  return Center(
                    child: Text('Sin resultados',
                        style: monoStyle(color: kHistMuted)),
                  );
                }
                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: players.length,
                  itemBuilder: (_, i) => PlayerCard(
                    player: players[i],
                    onTap: () {
                      ref
                          .read(selectedPlayerProvider.notifier)
                          .select(players[i]);
                      ref
                          .read(playerDetailTabProvider.notifier)
                          .set(PlayerDetailTab.resumen);
                    },
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

// ── Counter row ───────────────────────────────────────────────
class _CounterRow extends StatelessWidget {
  final int count;
  const _CounterRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kHistBorder, width: 1.5)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 12, color: kHistAccent),
          const SizedBox(width: 8),
          Text(
            'JUGADORES',
            style: monoStyle(
                size: 9, weight: FontWeight.w700,
                letterSpacing: 1.2, color: kHistMuted),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kHistAccent,
              border: Border.all(color: kHistBorder, width: 1),
            ),
            child: Text(
              '$count ENCONTRADOS',
              style: monoStyle(
                  size: 8, weight: FontWeight.w800,
                  letterSpacing: 0.5, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────
class _PlayersHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _PlayersHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: kHistBg,
        border: Border(bottom: BorderSide(color: kHistBorder, width: 1.5)),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 0, top: 0,
            child: DotGrid(cols: 5, rows: 4),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kHistAccent,
                      border: Border.all(color: kHistBorder, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: kHistDark.withOpacity(0.45),
                          offset: const Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'HISTÓRICO',
                      style: monoStyle(
                        color: Colors.white, size: 8,
                        weight: FontWeight.w800, letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('›',
                      style: monoStyle(
                          size: 12, weight: FontWeight.w700, color: kHistMuted)),
                  const SizedBox(width: 6),
                  Text(
                    'JUGADORES',
                    style: monoStyle(
                      size: 9, weight: FontWeight.w600,
                      color: kHistMuted, letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 5, height: 44,
                    decoration: BoxDecoration(
                      color: kHistAccent,
                      border: Border.all(color: kHistBorder, width: 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JUGADORES',
                          style: monoStyle(
                            size: 28, weight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                        Text(
                          'Explora las leyendas del fútbol.',
                          style: monoStyle(size: 11, color: kHistMuted),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                            color: kHistBorder.withOpacity(0.35), width: 1),
                      ),
                      child: Icon(Icons.arrow_back, size: 15,
                          color: kHistDark.withOpacity(0.45)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats strip ───────────────────────────────────────────────
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: neoBox(shadowX: 4, shadowY: 4),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(
              icon: Icons.person_outline_rounded,
              iconBg: kHistAccent,
              value: '$total',
              label: 'JUGADORES',
              bordered: true,
            ),
            _StatCell(
              icon: Icons.star_border_rounded,
              iconBg: kHistGold,
              value: '$goats',
              label: 'GOATS',
              bordered: true,
            ),
            _StatCell(
              icon: Icons.public_outlined,
              iconBg: kHistGreen,
              value: '$countries',
              label: 'PAÍSES',
              bordered: false,
            ),
          ],
        ),
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
              ? Border(right: BorderSide(color: kHistBorder, width: 1.5))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                border: Border.all(color: kHistBorder, width: 1),
              ),
              child: Icon(icon, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: monoStyle(
                        size: 18, weight: FontWeight.w900, color: kHistAccent)),
                Text(label,
                    style: monoStyle(
                        size: 7, weight: FontWeight.w700,
                        letterSpacing: 0.8, color: kHistMuted)),
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
    final legacyFilter = ref.watch(playerLegacyFilterProvider);
    final sigFilter    = ref.watch(playerSigFilterProvider);
    final hasFilters   = legacyFilter.isNotEmpty || sigFilter > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kHistBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: kHistDark.withOpacity(0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                style: monoStyle(size: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar jugador...',
                  hintStyle: monoStyle(size: 12, color: kHistMuted),
                  prefixIcon: const Icon(Icons.search, size: 16, color: kHistMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
          // Botón filtros 1:1 (sin texto)
          GestureDetector(
            onTap: () => _showFilterSheet(context, ref, legacyFilter, sigFilter),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasFilters ? kHistAccent : kHistBg,
                border: Border.all(
                  color: hasFilters ? kHistAccent : kHistBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kHistDark.withOpacity(0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.tune_rounded, size: 16,
                      color: hasFilters ? Colors.white : kHistDark),
                  if (hasFilters)
                    Positioned(
                      top: 7, right: 7,
                      child: Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón modo aleatorio 1:1
          _RandomButton(ref: ref),
        ],
      ),
    );
  }

  void _showFilterSheet(
    BuildContext context,
    WidgetRef ref,
    String currentLegacy,
    int currentSig,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        initialLegacy: currentLegacy,
        initialSig: currentSig,
        onApply: (legacy, sig) {
          ref.read(playerLegacyFilterProvider.notifier).set(legacy);
          ref.read(playerSigFilterProvider.notifier).set(sig);
        },
        onClear: () {
          ref.read(playerLegacyFilterProvider.notifier).set('');
          ref.read(playerSigFilterProvider.notifier).set(0);
        },
      ),
    );
  }
}

// ── Random button ─────────────────────────────────────────────
class _RandomButton extends StatelessWidget {
  final WidgetRef ref;
  const _RandomButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final players = ref
            .read(filteredPlayersProvider)
            .whenOrNull(data: (l) => l);
        if (players == null || players.isEmpty) return;
        showDialog(
          context: context,
          barrierColor: kHistDark.withOpacity(0.7),
          builder: (_) => _RandomPlayerModal(
            players: players,
            onSelect: (player) {
              ref.read(selectedPlayerProvider.notifier).select(player);
              ref
                  .read(playerDetailTabProvider.notifier)
                  .set(PlayerDetailTab.resumen);
            },
          ),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kHistDark,
          border: Border.all(color: kHistBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: kHistAccent.withOpacity(0.5),
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Icon(
          Icons.person_search_outlined,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Random player modal ───────────────────────────────────────
class _RandomPlayerModal extends StatefulWidget {
  final List<HistoricalPlayer> players;
  final void Function(HistoricalPlayer) onSelect;
  const _RandomPlayerModal({
    required this.players,
    required this.onSelect,
  });

  @override
  State<_RandomPlayerModal> createState() => _RandomPlayerModalState();
}

class _RandomPlayerModalState extends State<_RandomPlayerModal> {
  HistoricalPlayer? _displayed;
  HistoricalPlayer? _winner;
  bool _spinning = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _spin();
  }

  void _spin() {
    if (widget.players.isEmpty) return;
    final rng = DateTime.now().millisecondsSinceEpoch;
    final picked = widget.players[rng % widget.players.length];
    setState(() {
      _winner = picked;
      _spinning = true;
      _revealed = false;
      _displayed = null;
    });

    int i = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return false;
      setState(() => _displayed = widget.players[i % widget.players.length]);
      i++;
      return i < 35;
    }).then((_) {
      if (!mounted) return;
      setState(() {
        _displayed = _winner;
        _spinning = false;
        _revealed = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: kHistBg,
            border: Border.all(color: kHistBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: kHistDark.withOpacity(0.6),
                offset: const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
                color: kHistDark,
                child: Row(
                  children: [
                    const Icon(Icons.person_search_outlined,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'MODO ALEATORIO',
                      style: monoStyle(
                        size: 11,
                        weight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white54),
                    ),
                  ],
                ),
              ),

              // ── Ruleta ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Slot animado
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 60),
                      child: _displayed == null
                          ? Container(
                              key: const ValueKey('empty'),
                              width: double.infinity,
                              height: 80,
                              decoration: BoxDecoration(
                                color: kHistAccent.withOpacity(0.08),
                                border: Border.all(
                                    color: kHistBorderL, width: 1.5),
                              ),
                              child: const Icon(Icons.person_outline,
                                  size: 36, color: kHistBorderL),
                            )
                          : _PlayerSlot(
                              key: ValueKey(_displayed!.id),
                              player: _displayed!,
                              revealed: _revealed,
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Estado / botones
                    if (_spinning)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              width: 6, height: 6, color: kHistAccent),
                          const SizedBox(width: 6),
                          Text(
                            'BUSCANDO...',
                            style: monoStyle(
                              size: 9,
                              weight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: kHistAccent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                              width: 6, height: 6, color: kHistAccent),
                        ],
                      )
                    else if (_revealed && _winner != null) ...[
                      // Botón VER JUGADOR
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelect(_winner!);
                        },
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: kHistAccent,
                            border: Border.all(
                                color: kHistBorder, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: kHistDark.withOpacity(0.4),
                                offset: const Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'VER JUGADOR →',
                              style: monoStyle(
                                size: 11,
                                weight: FontWeight.w900,
                                letterSpacing: 1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Botón OTRO
                      GestureDetector(
                        onTap: _spin,
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: kHistBorder, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              'OTRO →',
                              style: monoStyle(
                                size: 10,
                                weight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: kHistDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Player slot (ruleta item) ─────────────────────────────────
class _PlayerSlot extends StatelessWidget {
  final HistoricalPlayer player;
  final bool revealed;
  const _PlayerSlot({
    super.key,
    required this.player,
    required this.revealed,
  });

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(player.imagePath);
    final sig = player.significanceLevel ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: revealed ? kHistCard : kHistBg,
        border: Border(
          left: BorderSide(
            color: revealed ? kHistAccent : kHistBorderL,
            width: revealed ? 4 : 1,
          ),
          top: BorderSide(color: kHistBorderL, width: 0.5),
          right: BorderSide(color: kHistBorderL, width: 0.5),
          bottom: BorderSide(color: kHistBorderL, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Foto
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kHistAccent.withOpacity(0.1),
              border: Border.all(color: kHistBorderL, width: 1),
            ),
            clipBehavior: Clip.hardEdge,
            child: imgUrl != null
                ? Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        CardInitials(name: player.name),
                  )
                : CardInitials(name: player.name),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name.toUpperCase(),
                  style: monoStyle(
                    size: 12,
                    weight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (player.country != null)
                  Text(
                    player.country!,
                    style: monoStyle(
                      size: 9,
                      color: kHistAccent,
                      weight: FontWeight.w700,
                    ),
                  ),
                if (sig == 5)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    color: kHistGold,
                    child: Text(
                      'GOAT',
                      style: monoStyle(
                        size: 7,
                        weight: FontWeight.w900,
                        color: Colors.black,
                      ),
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

// ── Filter sheet (sin cambios respecto al original) ───────────
class _FilterSheet extends StatefulWidget {
  final String initialLegacy;
  final int initialSig;
  final void Function(String legacy, int sig) onApply;
  final VoidCallback onClear;
  const _FilterSheet({
    required this.initialLegacy,
    required this.initialSig,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _legacy;
  late int    _sig;

  static const _legacyOptions = [
    ('Goal Scorer', 'Goleador'),
    ('Tactician',   'Táctico'),
    ('Innovator',   'Genio'),
    ('Leader',      'Líder'),
    ('Goalkeeper',  'Portero'),
    ('Technician',  'Técnico'),
  ];

  static const _sigOptions = [
    (5, 'GOAT'),
    (4, 'Leyenda'),
    (3, 'Icónico'),
    (2, 'Notable'),
    (1, 'Activo'),
  ];

  @override
  void initState() {
    super.initState();
    _legacy = widget.initialLegacy;
    _sig    = widget.initialSig;
  }

  @override
  Widget build(BuildContext context) {
    final hasActive = _legacy.isNotEmpty || _sig > 0;
    return Container(
      decoration: BoxDecoration(
        color: kHistBg,
        border: Border(top: BorderSide(color: kHistBorder, width: 2)),
        boxShadow: [
          BoxShadow(
            color: kHistDark.withOpacity(0.25),
            offset: const Offset(0, -4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36, height: 3,
              decoration: BoxDecoration(
                color: kHistBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                Text('FILTRAR',
                    style: monoStyle(
                        size: 13, weight: FontWeight.w900, letterSpacing: 1)),
                const Spacer(),
                if (hasActive)
                  GestureDetector(
                    onTap: () {
                      widget.onClear();
                      Navigator.pop(context);
                    },
                    child: Text('Limpiar todo',
                        style: monoStyle(
                            size: 10, color: kHistMuted,
                            weight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LEGADO',
                    style: monoStyle(
                        size: 9, weight: FontWeight.w700,
                        letterSpacing: 1, color: kHistMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _legacyOptions.map((opt) {
                    final isActive = _legacy == opt.$1;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _legacy = isActive ? '' : opt.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? kHistAccent : Colors.transparent,
                          border: Border.all(
                            color: isActive ? kHistAccent : kHistBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          opt.$2,
                          style: monoStyle(
                            size: 10, weight: FontWeight.w700,
                            color: isActive ? Colors.white : kHistDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NIVEL',
                    style: monoStyle(
                        size: 9, weight: FontWeight.w700,
                        letterSpacing: 1, color: kHistMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _sigOptions.map((opt) {
                    final isActive = _sig == opt.$1;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _sig = isActive ? 0 : opt.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? kHistGold : Colors.transparent,
                          border: Border.all(
                            color: isActive ? kHistGold : kHistBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          opt.$2,
                          style: monoStyle(
                            size: 10, weight: FontWeight.w700,
                            color: isActive ? Colors.black : kHistDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: GestureDetector(
              onTap: () {
                widget.onApply(_legacy, _sig);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: kHistDark,
                  border: Border.all(color: kHistBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: kHistAccent.withOpacity(0.4),
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'APLICAR FILTROS',
                    style: monoStyle(
                      size: 11, weight: FontWeight.w900,
                      letterSpacing: 1.2, color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}