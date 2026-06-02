import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import 'history_competitions_shared.dart';
import 'comp_tab_info.dart';
import 'comp_tab_grupos.dart';
import 'comp_tab_standings.dart';
import 'comp_tab_knockout.dart';

// ── Tab activa ────────────────────────────────────────────────
enum CompDetailTab { info, grupos, standings, knockout }

class _CompTabNotifier extends Notifier<CompDetailTab> {
  @override
  CompDetailTab build() => CompDetailTab.info;
  void set(CompDetailTab t) => state = t;
}

final compDetailTabProvider =
    NotifierProvider<_CompTabNotifier, CompDetailTab>(_CompTabNotifier.new);

// ══════════════════════════════════════════════════════════════
//  SHELL
// ══════════════════════════════════════════════════════════════

class HistoryCompetitionDetail extends ConsumerWidget {
  final HistoricalCompetition competition;
  final VoidCallback onBack;

  const HistoryCompetitionDetail({
    super.key,
    required this.competition,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab      = ref.watch(compDetailTabProvider);
    final detailAsync =
        ref.watch(competitionDetailProvider(competition.id));

    return Scaffold(
      backgroundColor: kHistBg,
      body: Column(
        children: [
          // ── Top bar ────────────────────────────────────────
          _CompDetailTopBar(
              competition: competition, onBack: onBack),

          // ── Content ───────────────────────────────────────
          Expanded(
            child: detailAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: kHistAccent)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: monoStyle(color: kHistMuted))),
              data: (detail) {
                // Auto-reset tab to info when entering
                return _TabContent(tab: tab, detail: detail);
              },
            ),
          ),

          // ── Bottom tab bar ─────────────────────────────────
          detailAsync.whenOrNull(
                data: (detail) => _CompDetailTabBar(
                  current: tab,
                  detail: detail,
                  onTap: (t) =>
                      ref.read(compDetailTabProvider.notifier).set(t),
                ),
              ) ??
              const SizedBox.shrink(),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ── Tab content switcher ──────────────────────────────────────
class _TabContent extends StatelessWidget {
  final CompDetailTab tab;
  final CompetitionDetail detail;
  const _TabContent({required this.tab, required this.detail});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: switch (tab) {
        CompDetailTab.info =>
          CompTabInfo(key: const ValueKey('info'), detail: detail),
        CompDetailTab.grupos =>
          CompTabGrupos(key: const ValueKey('grupos'), detail: detail),
        CompDetailTab.standings =>
          CompTabStandings(
              key: const ValueKey('standings'), detail: detail),
        CompDetailTab.knockout =>
          CompTabKnockout(
              key: const ValueKey('knockout'), detail: detail),
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TOP BAR
// ══════════════════════════════════════════════════════════════

class _CompDetailTopBar extends StatelessWidget {
  final HistoricalCompetition competition;
  final VoidCallback onBack;
  const _CompDetailTopBar(
      {required this.competition, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final tc = compTypeColor(competition.type);
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(12, topPad + 10, 12, 10),
      decoration: const BoxDecoration(
        color: kHistBg,
        border:
            Border(bottom: BorderSide(color: kHistBorder, width: 1.5)),
      ),
      child: Row(children: [
        // Back
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 34,
            height: 34,
            decoration: neoBox(shadowX: 2, shadowY: 2),
            child: const Icon(Icons.arrow_back,
                size: 16, color: kHistDark),
          ),
        ),
        const SizedBox(width: 12),

        // Name + breadcrumb
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HISTÓRICO › COMPETICIONES',
                  style: monoStyle(
                      size: 8,
                      color: kHistMuted,
                      letterSpacing: 0.8)),
              Text(competition.name.toUpperCase(),
                  style: monoStyle(
                      size: 13, weight: FontWeight.w900,
                      letterSpacing: -0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),

        // Type badge
        if (competition.type != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tc,
              border: Border.all(color: kHistBorder, width: 1),
              boxShadow: [
                BoxShadow(
                    color: kHistDark.withOpacity(0.4),
                    offset: const Offset(2, 2),
                    blurRadius: 0)
              ],
            ),
            child: Text(
              compTypeLabels[competition.type!] ?? competition.type!,
              style: monoStyle(
                  size: 8,
                  weight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Colors.white),
            ),
          ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  BOTTOM TAB BAR — tabs dinámicos según datos disponibles
// ══════════════════════════════════════════════════════════════

class _CompDetailTabBar extends StatelessWidget {
  final CompDetailTab current;
  final CompetitionDetail detail;
  final void Function(CompDetailTab) onTap;
  const _CompDetailTabBar(
      {required this.current,
      required this.detail,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Construir tabs dinámicamente
    final tabs = <(CompDetailTab, IconData, String)>[
      (CompDetailTab.info, Icons.info_outline, 'INFO'),
      if (detail.groups.isNotEmpty)
        (CompDetailTab.grupos, Icons.grid_view_outlined, 'GRUPOS'),
      if (detail.standings.isNotEmpty && detail.groups.isEmpty)
        (CompDetailTab.standings, Icons.table_rows_outlined, 'TABLA'),
      if (detail.knockout.isNotEmpty)
        (CompDetailTab.knockout, Icons.account_tree_outlined, 'LLAVE'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: kHistBg,
        border:
            Border(top: BorderSide(color: kHistBorder, width: 1.5)),
      ),
      child: Row(
        children: tabs.map((tab) {
          final (tabVal, icon, label) = tab;
          final isActive = current == tabVal;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(tabVal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isActive ? kHistAccent : Colors.transparent,
                  border: isActive
                      ? null
                      : Border(
                          right: BorderSide(
                              color: kHistBorderL.withOpacity(0.15),
                              width: 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 18,
                        color: isActive ? Colors.white : kHistMuted),
                    const SizedBox(height: 3),
                    Text(label,
                        style: monoStyle(
                            size: 7,
                            weight: isActive
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isActive
                                ? Colors.white
                                : kHistMuted,
                            letterSpacing: 0.4)),
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
