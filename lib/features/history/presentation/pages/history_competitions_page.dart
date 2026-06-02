import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import '../widgets/history_app_bar.dart';
import '../widgets/knockout_bracket_widget.dart';

const _kAccent = Color(0xFF5B4FD8);
const _kBg = Color(0xFFF0EDE8);
const _kDark = Color(0xFF1A1A2E);
const _kMuted = Color(0xFF88887D);
const _kBorder = Color(0xFFC4BFB8);
const _kGold = Color(0xFFF59E0B);

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

// ── Type helpers ──────────────────────────────────────────────
const _typeLabel = {
  'International': 'Internacional',
  'Continental': 'Continental',
  'Domestic': 'Nacional',
};
const _typeColor = {
  'International': Color(0xFF3B82F6),
  'Continental': Color(0xFF8B5CF6),
  'Domestic': Color(0xFF1D9E75),
};
const _formatLabel = {
  'groups_knockout': 'Grupos + Elim.',
  'league_only': 'Liga',
  'knockout_only': 'Eliminatorias',
};

// ══════════════════════════════════════════════════════════════
//  COMPETITIONS PAGE
// ══════════════════════════════════════════════════════════════

class HistoryCompetitionsPage extends ConsumerStatefulWidget {
  const HistoryCompetitionsPage({super.key});

  @override
  ConsumerState<HistoryCompetitionsPage> createState() =>
      _HistoryCompetitionsPageState();
}

class _HistoryCompetitionsPageState
    extends ConsumerState<HistoryCompetitionsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedCompetitionProvider);

    // If a competition is selected, show detail view
    if (selected != null) {
      return _CompetitionDetailView(competition: selected);
    }

    return _CompetitionListView(searchCtrl: _searchCtrl);
  }
}

// ══════════════════════════════════════════════════════════════
//  LIST VIEW
// ══════════════════════════════════════════════════════════════

class _CompetitionListView extends ConsumerWidget {
  final TextEditingController searchCtrl;
  const _CompetitionListView({required this.searchCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compsAsync = ref.watch(filteredCompetitionsProvider);
    final typeFilter = ref.watch(competitionTypeFilterProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          HistoryAppBar(
            title: 'COMPETICIONES',
            subtitle: 'Torneos y campeonatos históricos',
            icon: Icons.emoji_events_outlined,
            onBack: () => ref.read(historySectionProvider.notifier).goBack(),
          ),

          // Search + filter
          _SearchBar(controller: searchCtrl),
          _TypeFilterRow(active: typeFilter),

          // List
          Expanded(
            child: compsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _kAccent)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (comps) {
                if (comps.isEmpty) {
                  return Center(
                    child: Text('Sin resultados', style: _mono(color: _kMuted)),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: comps.length,
                  itemBuilder: (_, i) => _CompetitionCard(
                    comp: comps[i],
                    onTap: () => ref.read(selectedCompetitionProvider.notifier).select(comps[i]),
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
      child: Row(
        children: [
          Expanded(
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
                  hintText: 'Buscar torneo…',
                  hintStyle: _mono(size: 12, color: _kMuted),
                  prefixIcon: const Icon(Icons.search, size: 16, color: _kMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            controller.clear();
                             ref.read(competitionSearchProvider.notifier).set('');
                          },
                        )
                      : null,
                ),
                onChanged: (v) =>
               ref.read(competitionSearchProvider.notifier).set(v)
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeFilterRow extends ConsumerWidget {
  final String active;
  const _TypeFilterRow({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ['', 'International', 'Continental', 'Domestic'];

    return Container(
      height: 36,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: types.map((t) {
          final label = t.isEmpty ? 'TODOS' : (_typeLabel[t] ?? t).toUpperCase();
          final isActive = active == t;
          return GestureDetector(
            onTap: () =>
             ref.read(competitionTypeFilterProvider.notifier).set(t),
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
        }).toList(),
      ),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final HistoricalCompetition comp;
  final VoidCallback onTap;
  const _CompetitionCard({required this.comp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(comp.imagePath);
    final typeColor = _typeColor[comp.type] ?? _kAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: const BorderSide(color: _kBorder, width: 0.5),
            left: BorderSide(color: typeColor, width: 3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Logo
            Container(
              width: 48,
              height: 48,
              color: _kBorder,
              child: imgUrl != null
                  ? Image.network(imgUrl, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.emoji_events, size: 24, color: typeColor))
                  : Icon(Icons.emoji_events, size: 24, color: typeColor),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (comp.type != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          color: typeColor,
                          child: Text(
                            (_typeLabel[comp.type!] ?? comp.type!).toUpperCase(),
                            style: _mono(color: Colors.white, size: 7, weight: FontWeight.w700, letterSpacing: 0.8),
                          ),
                        ),
                      const SizedBox(width: 6),
                      if (comp.format != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          color: _kBorder,
                          child: Text(
                            _formatLabel[comp.format!] ?? comp.format!,
                            style: _mono(size: 7, color: _kMuted),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comp.name, style: _mono(size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (comp.year != null) ...[
                        Text('${comp.year}', style: _mono(size: 10, color: _kMuted)),
                        if (comp.winnerDisplay != '—')
                          Text(' · ', style: _mono(size: 10, color: _kMuted)),
                      ],
                      if (comp.winnerDisplay != '—')
                        Flexible(
                          child: Text(
                            comp.winnerDisplay,
                            style: _mono(size: 10, color: _kGold, weight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: _kMuted),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DETAIL VIEW
// ══════════════════════════════════════════════════════════════

class _CompetitionDetailView extends ConsumerWidget {
  final HistoricalCompetition competition;
  const _CompetitionDetailView({required this.competition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(competitionDetailProvider(competition.id));

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          HistoryAppBar(
            title: competition.name.toUpperCase(),
            subtitle: competition.year != null ? '${competition.year}' : '',
            icon: Icons.emoji_events_outlined,
            onBack: () =>
                 ref.read(selectedCompetitionProvider.notifier).select(null)
          ),
          Expanded(
            child: detailAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _kAccent)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (detail) => _CompetitionDetailContent(detail: detail),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionDetailContent extends StatelessWidget {
  final CompetitionDetail detail;
  const _CompetitionDetailContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    final comp = detail.competition;
    final hasGroups = detail.groups.isNotEmpty;
    final hasStandings = detail.standings.isNotEmpty;
    final hasKnockout = detail.knockout.isNotEmpty;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Competition info header
        SliverToBoxAdapter(child: _DetailHeader(comp: comp)),

        // Groups
        if (hasGroups) ...[
          SliverToBoxAdapter(child: _SectionLabel(label: 'FASE DE GRUPOS')),
          SliverToBoxAdapter(child: _GroupsSection(groups: detail.groups)),
        ],

        // League table
        if (hasStandings && !hasGroups) ...[
          SliverToBoxAdapter(child: _SectionLabel(label: 'CLASIFICACIÓN')),
          SliverToBoxAdapter(child: _LeagueTable(standings: detail.standings)),
        ],

        // Knockout bracket
        if (hasKnockout) ...[
          SliverToBoxAdapter(child: _SectionLabel(label: 'LLAVE ELIMINATORIA')),
          SliverToBoxAdapter(
            child: KnockoutBracketWidget(matches: detail.knockout),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final HistoricalCompetition comp;
  const _DetailHeader({required this.comp});

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(comp.imagePath);
    final typeColor = _typeColor[comp.type] ?? _kAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            width: 72,
            height: 72,
            color: _kBorder,
            child: imgUrl != null
                ? Image.network(imgUrl, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.emoji_events, size: 36, color: typeColor))
                : Icon(Icons.emoji_events, size: 36, color: typeColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comp.name, style: _mono(size: 16, weight: FontWeight.w800)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (comp.type != null)
                      _Chip(label: _typeLabel[comp.type!] ?? comp.type!, color: typeColor),
                    if (comp.year != null)
                      _Chip(label: '${comp.year}', color: _kMuted),
                    if (comp.country != null)
                      _Chip(label: comp.country!, color: _kMuted),
                    if (comp.numTeams != null)
                      _Chip(label: '${comp.numTeams} equipos', color: _kMuted),
                  ],
                ),
                const SizedBox(height: 8),
                if (comp.winnerDisplay != '—')
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, size: 12, color: _kGold),
                      const SizedBox(width: 4),
                      Text('Campeón: ', style: _mono(size: 10, color: _kMuted)),
                      Text(comp.winnerDisplay,
                          style: _mono(size: 10, color: _kGold, weight: FontWeight.w700)),
                    ],
                  ),
                if (comp.description != null) ...[
                  const SizedBox(height: 8),
                  Text(comp.description!, style: _mono(size: 11, color: _kMuted), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: color.withOpacity(0.12),
      child: Text(label, style: _mono(size: 9, color: color, weight: FontWeight.w700)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFE8E4DE),
      child: Text(
        label,
        style: _mono(size: 9, weight: FontWeight.w700, letterSpacing: 1.4, color: _kMuted),
      ),
    );
  }
}

class _GroupsSection extends StatelessWidget {
  final List<CompetitionGroup> groups;
  const _GroupsSection({required this.groups});

  @override
  Widget build(BuildContext context) {
    // Group by group_name
    final Map<String, List<CompetitionGroup>> byGroup = {};
    for (final row in groups) {
      byGroup.putIfAbsent(row.groupName, () => []).add(row);
    }

    return Column(
      children: byGroup.entries.map((e) {
        return _GroupTable(name: e.key, rows: e.value);
      }).toList(),
    );
  }
}

class _GroupTable extends StatelessWidget {
  final String name;
  final List<CompetitionGroup> rows;
  const _GroupTable({required this.name, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(border: Border.all(color: _kBorder)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: _kAccent,
            child: Text('GRUPO $name',
                style: _mono(color: Colors.white, size: 9, weight: FontWeight.w800, letterSpacing: 1)),
          ),
          // Header row
          Container(
            color: const Color(0xFFE8E4DE),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                Expanded(child: Text('EQUIPO', style: _mono(size: 8, color: _kMuted, weight: FontWeight.w700))),
                for (final h in ['PJ', 'G', 'E', 'P', 'GF', 'GC', 'DG', 'PTS'])
                  SizedBox(width: 28, child: Text(h, textAlign: TextAlign.center, style: _mono(size: 8, color: _kMuted, weight: FontWeight.w700))),
              ],
            ),
          ),
          ...rows.map((row) => Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _kBorder, width: 0.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(row.teamName, style: _mono(size: 11, weight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    for (final v in [
                      row.played, row.wins, row.draws, row.losses,
                      row.goalsFor, row.goalsAgainst,
                      row.goalDiff, row.points
                    ])
                      SizedBox(
                        width: 28,
                        child: Text(
                          v > 0 ? '$v' : (v < 0 ? '$v' : '0'),
                          textAlign: TextAlign.center,
                          style: _mono(size: 11),
                        ),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _LeagueTable extends StatelessWidget {
  final List<CompetitionStanding> standings;
  const _LeagueTable({required this.standings});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: _kBorder)),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFE8E4DE),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 28, child: Text('#', textAlign: TextAlign.center, style: _mono(size: 8, color: _kMuted, weight: FontWeight.w700))),
                Expanded(child: Text('EQUIPO', style: _mono(size: 8, color: _kMuted, weight: FontWeight.w700))),
                for (final h in ['PJ', 'G', 'E', 'P', 'GF', 'GC', 'DG', 'PTS'])
                  SizedBox(width: 28, child: Text(h, textAlign: TextAlign.center, style: _mono(size: 8, color: _kMuted, weight: FontWeight.w700))),
              ],
            ),
          ),
          ...standings.map((row) => Container(
                decoration: BoxDecoration(
                  color: row.isChampion ? _kGold.withOpacity(0.06) : Colors.transparent,
                  border: const Border(top: BorderSide(color: _kBorder, width: 0.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: row.isChampion
                          ? const Icon(Icons.star, size: 12, color: _kGold)
                          : Text('${row.position}', textAlign: TextAlign.center, style: _mono(size: 11)),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(row.teamName, style: _mono(size: 11, weight: row.isChampion ? FontWeight.w700 : FontWeight.normal), overflow: TextOverflow.ellipsis),
                          ),
                          if (row.isChampion) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              color: _kGold,
                              child: Text('CAM', style: _mono(color: Colors.white, size: 7, weight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    for (final v in [
                      row.played, row.wins, row.draws, row.losses,
                      row.goalsFor, row.goalsAgainst,
                      row.goalDiff, row.points
                    ])
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$v',
                          textAlign: TextAlign.center,
                          style: _mono(size: 11, weight: v == row.points && row.isChampion ? FontWeight.w700 : FontWeight.normal),
                        ),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
