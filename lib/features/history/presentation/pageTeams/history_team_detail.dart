import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import '../../data/history_service.dart';
import 'history_teams_shared.dart';
import 'team_tab_resumen.dart';
import 'team_tab_alineacion.dart';
import 'team_tab_palmares.dart';

// ─── Provider local para TeamDetail ──────────────────────────
// Reutiliza teamDetailProvider del service (a añadir si no existe)
final _teamDetailProvider =
    FutureProvider.family<TeamDetail, String>((ref, id) {
  return ref.watch(historyServiceProvider).fetchTeamDetail(id);
});

// ══════════════════════════════════════════════════════════════
//  TEAM DETAIL PAGE
// ══════════════════════════════════════════════════════════════

class HistoryTeamDetail extends ConsumerStatefulWidget {
  final HistoricalTeam team;
  final VoidCallback onBack;

  const HistoryTeamDetail({
    super.key,
    required this.team,
    required this.onBack,
  });

  @override
  ConsumerState<HistoryTeamDetail> createState() => _HistoryTeamDetailState();
}

class _HistoryTeamDetailState extends ConsumerState<HistoryTeamDetail>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (Icons.dashboard_outlined,   'RESUMEN'),
    (Icons.sports_soccer,        'ALINEACIÓN'),
    (Icons.emoji_events_outlined,'PALMARÉS'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = parseHexColor(widget.team.primaryColor);
    final detailAsync = ref.watch(_teamDetailProvider(widget.team.id));

    return Scaffold(
      backgroundColor: kTeamBg,
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────
          _TeamAppBar(
            team: widget.team,
            primaryColor: primaryColor,
            onBack: widget.onBack,
          ),

          // ── Tab Bar ──────────────────────────────────────────
          _TeamTabBar(
            controller: _tabController,
            tabs: _tabs,
            teamColor: primaryColor,
          ),

          // ── Contenido ────────────────────────────────────────
          Expanded(
            child: detailAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
                    const SizedBox(height: 14),
                    Text(
                      'Cargando datos del equipo…',
                      style: teamMono(size: 12, color: kTeamMuted),
                    ),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 36, color: kTeamRed),
                    const SizedBox(height: 12),
                    Text('Error: $e', style: teamMono(size: 12, color: kTeamRed)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => ref.refresh(_teamDetailProvider(widget.team.id)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: teamNeoBox(),
                        child: Text(
                          'REINTENTAR',
                          style: teamMono(size: 11, weight: FontWeight.w700, color: kTeamAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (detail) => TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  TeamTabResumen(detail: detail),
                  TeamTabAlineacion(detail: detail),
                  TeamTabPalmares(detail: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  APP BAR con acento de color del equipo
// ══════════════════════════════════════════════════════════════

class _TeamAppBar extends StatelessWidget {
  final HistoricalTeam team;
  final Color primaryColor;
  final VoidCallback onBack;

  const _TeamAppBar({
    required this.team,
    required this.primaryColor,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kTeamBg,
        border: Border(
          bottom: BorderSide(color: kTeamBorder, width: 1.5),
          top: BorderSide(color: primaryColor, width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: kTeamBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: kTeamDark.withOpacity(0.4),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
                color: kTeamBg,
              ),
              child: const Icon(Icons.arrow_back, size: 16, color: kTeamDark),
            ),
          ),
          const SizedBox(width: 12),

          // Logo pequeño
          Container(
            width: 36,
            height: 36,
            color: primaryColor.withOpacity(0.1),
            padding: const EdgeInsets.all(4),
            child: TeamLogo(
              imagePath: team.imagePath,
              teamName: team.name,
              size: 28,
              teamColor: primaryColor,
            ),
          ),
          const SizedBox(width: 10),

          // Nombre + país
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name.toUpperCase(),
                  style: teamMono(
                    size: 13,
                    weight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (team.country != null || team.era != null)
                  Text(
                    [team.country, team.era]
                        .where((s) => s != null)
                        .join(' · '),
                    style: teamMono(size: 9, color: kTeamMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Titles badge
          if (team.titlesCount != null && team.titlesCount! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kTeamGold,
                border: Border.all(color: kTeamBorder, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, size: 11, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    '${team.titlesCount}',
                    style: teamMono(
                      size: 11,
                      weight: FontWeight.w900,
                      color: Colors.white,
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

// ══════════════════════════════════════════════════════════════
//  TAB BAR
// ══════════════════════════════════════════════════════════════

class _TeamTabBar extends StatelessWidget {
  final TabController controller;
  final List<(IconData, String)> tabs;
  final Color teamColor;

  const _TeamTabBar({
    required this.controller,
    required this.tabs,
    required this.teamColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kTeamBg,
        border: Border(bottom: BorderSide(color: kTeamBorder, width: 1.5)),
      ),
      child: TabBar(
        controller: controller,
        indicatorColor: teamColor,
        indicatorWeight: 2.5,
        labelPadding: EdgeInsets.zero,
        tabs: tabs.asMap().entries.map((e) {
          final isActive = controller.index == e.key;
          final (icon, label) = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? teamColor : kTeamMuted,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: teamMono(
                    size: 8,
                    weight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isActive ? teamColor : kTeamMuted,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
