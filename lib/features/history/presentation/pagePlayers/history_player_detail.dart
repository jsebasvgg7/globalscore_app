import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import '../../data/history_service.dart';
import 'history_players_shared.dart';
import 'player_tab_resumen.dart';
import 'player_tab_trayectoria.dart';
import 'player_tab_equipos.dart';
import 'player_tab_palmares.dart';
import 'player_tab_historia.dart';

// ── Tab activa ────────────────────────────────────────────────
enum PlayerDetailTab { resumen, trayectoria, equipos, palmares, historia }

class _TabNotifier extends Notifier<PlayerDetailTab> {
  @override
  PlayerDetailTab build() => PlayerDetailTab.resumen;
  void set(PlayerDetailTab t) => state = t;
}

final playerDetailTabProvider =
    NotifierProvider<_TabNotifier, PlayerDetailTab>(_TabNotifier.new);

// ══════════════════════════════════════════════════════════════
//  SHELL
// ══════════════════════════════════════════════════════════════

class HistoryPlayerDetail extends ConsumerWidget {
  final HistoricalPlayer player;
  final VoidCallback onBack;

  const HistoryPlayerDetail({
    super.key,
    required this.player,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(playerDetailTabProvider);
    final detailAsync = ref.watch(playerDetailProvider(player.id));

    return Scaffold(
      backgroundColor: kHistBg,
      body: Column(
        children: [
          // ── Top bar ────────────────────────────────────────
          _DetailTopBar(player: player, onBack: onBack),

          // ── Content ────────────────────────────────────────
          Expanded(
            child: detailAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: kHistAccent),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: monoStyle(color: kHistMuted)),
              ),
              data: (detail) => _TabContent(tab: tab, detail: detail),
            ),
          ),

          // ── Bottom tab bar ─────────────────────────────────
          _DetailTabBar(
            current: tab,
            onTap: (t) => ref.read(playerDetailTabProvider.notifier).set(t),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ── Tab content switcher ──────────────────────────────────────
class _TabContent extends StatelessWidget {
  final PlayerDetailTab tab;
  final PlayerDetail detail;
  const _TabContent({required this.tab, required this.detail});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: switch (tab) {
        PlayerDetailTab.resumen =>
          PlayerTabResumen(key: const ValueKey('resumen'), detail: detail),
        PlayerDetailTab.trayectoria =>
          PlayerTabTrayectoria(key: const ValueKey('trayectoria'), detail: detail),
        PlayerDetailTab.equipos =>
          PlayerTabEquipos(key: const ValueKey('equipos'), detail: detail),
        PlayerDetailTab.palmares =>
          PlayerTabPalmares(key: const ValueKey('palmares'), detail: detail),
        PlayerDetailTab.historia =>
          PlayerTabHistoria(key: const ValueKey('historia'), detail: detail),
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TOP BAR — back + nombre + badge
// ══════════════════════════════════════════════════════════════

class _DetailTopBar extends StatelessWidget {
  final HistoricalPlayer player;
  final VoidCallback onBack;
  const _DetailTopBar({required this.player, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final sig = player.significanceLevel ?? 0;
    final isGoat = sig == 5;
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(12, topPad + 10, 12, 10),
      decoration: BoxDecoration(
        color: kHistBg,
        border: Border(bottom: BorderSide(color: kHistBorder, width: 1.5)),
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 34,
              height: 34,
              decoration: neoBox(shadowX: 2, shadowY: 2),
              child: const Icon(Icons.arrow_back, size: 16, color: kHistDark),
            ),
          ),
          const SizedBox(width: 12),

          // Breadcrumb
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'HISTÓRICO › LEYENDAS',
                      style: monoStyle(
                        size: 8,
                        color: kHistMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  player.name.toUpperCase(),
                  style: monoStyle(
                    size: 13,
                    weight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Badge GOAT / sig
          if (isGoat)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kHistGold,
                border: Border.all(color: kHistBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: kHistDark.withOpacity(0.4),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                'GOAT',
                style: monoStyle(
                  size: 9,
                  weight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.black,
                ),
              ),
            )
          else if (sig >= 2)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kHistAccent,
                border: Border.all(color: kHistBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: kHistDark.withOpacity(0.4),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                sig < sigLabel.length ? sigLabel[sig].toUpperCase() : '',
                style: monoStyle(
                  size: 9,
                  weight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  BOTTOM TAB BAR — 5 tabs neobrutalistas
// ══════════════════════════════════════════════════════════════

class _DetailTabBar extends StatelessWidget {
  final PlayerDetailTab current;
  final void Function(PlayerDetailTab) onTap;
  const _DetailTabBar({required this.current, required this.onTap});

  static const _tabs = [
    (PlayerDetailTab.resumen,     Icons.home_outlined,          'RESUMEN'),
    (PlayerDetailTab.trayectoria, Icons.timeline_outlined,       'TRAYECTO'),
    (PlayerDetailTab.equipos,     Icons.shield_outlined,         'EQUI & MOM'),
    (PlayerDetailTab.palmares,    Icons.emoji_events_outlined,   'PALMARÉS'),
    (PlayerDetailTab.historia,    Icons.auto_stories_outlined,   'HISTORIA'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kHistBg,
        border: Border(top: BorderSide(color: kHistBorder, width: 1.5)),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final (tabVal, icon, label) = tab;
          final isActive = current == tabVal;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(tabVal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? kHistAccent : Colors.transparent,
                  border: isActive
                      ? null
                      : Border(
                          right: BorderSide(
                            color: kHistBorder.withOpacity(0.15),
                            width: 0.5,
                          ),
                        ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isActive ? Colors.white : kHistMuted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: monoStyle(
                        size: 7,
                        weight: isActive ? FontWeight.w800 : FontWeight.w500,
                        color: isActive ? Colors.white : kHistMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
