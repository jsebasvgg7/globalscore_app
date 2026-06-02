import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/history_providers.dart';
import '../../domain/history_models.dart';
import '../../data/history_service.dart';
import 'history_teams_shared.dart';
import 'history_team_detail.dart';

// ══════════════════════════════════════════════════════════════
//  HISTORY TEAMS PAGE (reemplaza history_teams_page.dart)
// ══════════════════════════════════════════════════════════════

class HistoryTeamsPage extends ConsumerStatefulWidget {
  const HistoryTeamsPage({super.key});

  @override
  ConsumerState<HistoryTeamsPage> createState() => _HistoryTeamsPageState();
}

class _HistoryTeamsPageState extends ConsumerState<HistoryTeamsPage> {
  HistoricalTeam? _selected;

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return HistoryTeamDetail(
        team: _selected!,
        onBack: () => setState(() => _selected = null),
      );
    }
    return _TeamsListView(
      onSelect: (t) => setState(() => _selected = t),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LISTA DE EQUIPOS
// ══════════════════════════════════════════════════════════════

class _TeamsListView extends ConsumerStatefulWidget {
  final void Function(HistoricalTeam) onSelect;

  const _TeamsListView({required this.onSelect});

  @override
  ConsumerState<_TeamsListView> createState() => _TeamsListViewState();
}

class _TeamsListViewState extends ConsumerState<_TeamsListView> {
  final _searchCtrl = TextEditingController();
  bool _isSpinning = false;
  HistoricalTeam? _spinResult;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _spin(List<HistoricalTeam> teams) async {
    if (_isSpinning || teams.isEmpty) return;
    setState(() { _isSpinning = true; _spinResult = null; });

    // Animación de ruleta: cambia rapidamente y luego elige
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      setState(() {
        _spinResult = teams[(teams.indexOf(_spinResult ?? teams.first) + 1) % teams.length];
      });
    }
    // Elegir aleatoriamente
    final picked = (teams..shuffle()).first;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() { _isSpinning = false; _spinResult = picked; });
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) widget.onSelect(picked);
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(filteredTeamsProvider);
    final allTeamsAsync = ref.watch(historyTeamsProvider);

    return Scaffold(
      backgroundColor: kTeamBg,
      body: Column(
        children: [
          // ── Header editorial ─────────────────────────────────
          _TeamsHeader(
            teamsAsync: allTeamsAsync,
            isSpinning: _isSpinning,
            spinResult: _spinResult,
            onSpin: () {
              allTeamsAsync.whenData((teams) => _spin(teams));
            },
            onBack: () =>
                ref.read(historySectionProvider.notifier).goBack(),
          ),

          // ── Barra de búsqueda ─────────────────────────────────
          _TeamsSearchBar(controller: _searchCtrl),

          // ── Resultados ────────────────────────────────────────
          _ResultsBar(async: teamsAsync),

          // ── Lista ─────────────────────────────────────────────
          Expanded(
            child: teamsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: kTeamAccent),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: teamMono(color: kTeamRed)),
              ),
              data: (teams) {
                if (teams.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 40, color: kTeamBorderL),
                        const SizedBox(height: 12),
                        Text(
                          'Sin equipos',
                          style: teamMono(size: 14, color: kTeamMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prueba con otro término de búsqueda',
                          style: teamMono(size: 11, color: kTeamMuted),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: teams.length,
                  itemBuilder: (_, i) => _TeamCard(
                    team: teams[i],
                    onTap: () => widget.onSelect(teams[i]),
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

// ══════════════════════════════════════════════════════════════
//  HEADER EDITORIAL
// ══════════════════════════════════════════════════════════════

class _TeamsHeader extends StatelessWidget {
  final AsyncValue<List<HistoricalTeam>> teamsAsync;
  final bool isSpinning;
  final HistoricalTeam? spinResult;
  final VoidCallback onSpin;
  final VoidCallback onBack;

  const _TeamsHeader({
    required this.teamsAsync,
    required this.isSpinning,
    required this.spinResult,
    required this.onSpin,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final count = teamsAsync.valueOrNull?.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: kTeamBg,
        border: Border(bottom: BorderSide(color: kTeamBorder, width: 1.5)),
      ),
      child: Stack(
        children: [
          // Dot grid decorativo
          Positioned(
            right: 0,
            top: 0,
            child: Opacity(
              opacity: 0.12,
              child: TeamDotGrid(cols: 7, rows: 5),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + breadcrumb
                Row(
                  children: [
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: teamNeoBox(shadowX: 2, shadowY: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back, size: 11, color: kTeamDark),
                            const SizedBox(width: 5),
                            Text(
                              'HISTÓRICO',
                              style: teamMono(size: 8, weight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: kTeamAccent,
                      child: Text(
                        'EQUIPOS',
                        style: teamMono(
                          size: 8,
                          color: Colors.white,
                          weight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Título
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'EQUI',
                      style: teamMono(
                        size: 38,
                        weight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'POS',
                      style: teamMono(
                        size: 38,
                        weight: FontWeight.w900,
                        letterSpacing: -1,
                        color: kTeamAccent,
                      ),
                    ),
                  ],
                ),

                Text(
                  'Equipos que definieron una era',
                  style: teamMono(size: 11, color: kTeamMuted),
                ),
                const SizedBox(height: 14),

                // Spinner (igual que players)
                if (!isSpinning && spinResult == null)
                  GestureDetector(
                    onTap: onSpin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: kTeamAccent, width: 1.5),
                        color: kTeamAccent.withOpacity(0.06),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shuffle_rounded, size: 13, color: kTeamAccent),
                          const SizedBox(width: 7),
                          Text(
                            'EQUIPO ALEATORIO',
                            style: teamMono(
                              size: 10,
                              weight: FontWeight.w700,
                              color: kTeamAccent,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Resultado del spinner
                if (spinResult != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: kTeamAccent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: kTeamDark.withOpacity(0.4),
                          offset: const Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                      color: kTeamBg,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          color: parseHexColor(spinResult!.primaryColor).withOpacity(0.15),
                          child: TeamLogo(
                            imagePath: spinResult!.imagePath,
                            teamName: spinResult!.name,
                            size: 36,
                            teamColor: parseHexColor(spinResult!.primaryColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            spinResult!.name,
                            style: teamMono(size: 13, weight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSpinning)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: kTeamAccent,
                              strokeWidth: 2,
                            ),
                          ),
                      ],
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
//  SEARCH BAR
// ══════════════════════════════════════════════════════════════

class _TeamsSearchBar extends ConsumerWidget {
  final TextEditingController controller;

  const _TeamsSearchBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kTeamBorderL, width: 0.5)),
        color: kTeamCard,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: kTeamBorder, width: 1.5),
                color: kTeamBg,
                boxShadow: [
                  BoxShadow(
                    color: kTeamDark.withOpacity(0.2),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                style: teamMono(size: 13),
                onChanged: (v) =>
                    ref.read(teamSearchProvider.notifier).set(v),
                decoration: InputDecoration(
                  hintText: 'Buscar equipo…',
                  hintStyle: teamMono(size: 12, color: kTeamMuted),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 17,
                    color: kTeamMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            controller.clear();
                            ref.read(teamSearchProvider.notifier).set('');
                          },
                          child: const Icon(
                            Icons.close,
                            size: 15,
                            color: kTeamMuted,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  RESULTS BAR
// ══════════════════════════════════════════════════════════════

class _ResultsBar extends StatelessWidget {
  final AsyncValue<List<HistoricalTeam>> async;

  const _ResultsBar({required this.async});

  @override
  Widget build(BuildContext context) {
    final count = async.valueOrNull?.length ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kTeamBorderL, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            '$count EQUIPO${count != 1 ? 'S' : ''} ENCONTRADO${count != 1 ? 'S' : ''}',
            style: teamMono(
              size: 9,
              color: kTeamMuted,
              weight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TEAM CARD
// ══════════════════════════════════════════════════════════════

class _TeamCard extends StatelessWidget {
  final HistoricalTeam team;
  final VoidCallback onTap;

  const _TeamCard({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = parseHexColor(team.primaryColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kTeamBg,
          border: Border(
            bottom: BorderSide(color: kTeamBorderL, width: 0.5),
            left: BorderSide(color: primaryColor, width: 4),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Logo
            Container(
              width: 52,
              height: 52,
              color: primaryColor.withOpacity(0.08),
              padding: const EdgeInsets.all(6),
              child: TeamLogo(
                imagePath: team.imagePath,
                teamName: team.name,
                size: 40,
                teamColor: primaryColor,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          team.name,
                          style: teamMono(size: 14, weight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (team.country != null)
                        _CardTag(
                          label: team.country!,
                          icon: Icons.flag_outlined,
                          color: kTeamMuted,
                        ),
                      if (team.era != null)
                        _CardTag(
                          label: team.era!,
                          icon: Icons.schedule_outlined,
                          color: primaryColor,
                        ),
                      if (team.titlesCount != null && team.titlesCount! > 0)
                        _CardTag(
                          label: '${team.titlesCount} títulos',
                          icon: Icons.emoji_events_outlined,
                          color: kTeamGold,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            const Icon(Icons.chevron_right, size: 18, color: kTeamBorderL),
          ],
        ),
      ),
    );
  }
}

class _CardTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _CardTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: color),
        const SizedBox(width: 3),
        Text(label, style: teamMono(size: 10, color: color)),
      ],
    );
  }
}
