import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_teams_shared.dart';

class TeamTabPalmares extends StatelessWidget {
  final TeamDetail detail;

  const TeamTabPalmares({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final titles = detail.titles;
    final team = detail.team;
    final primaryColor = parseHexColor(team.primaryColor);

    if (titles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 40, color: kTeamBorderL),
            const SizedBox(height: 12),
            Text(
              'Sin títulos registrados',
              style: teamMono(size: 14, color: kTeamMuted),
            ),
          ],
        ),
      );
    }

    // Agrupar por categoría
    final Map<String, List<TeamTitle>> byCategory = {};
    for (final t in titles) {
      final cat = t.category ?? 'Otros';
      byCategory.putIfAbsent(cat, () => []).add(t);
    }

    // Orden de categorías
    const catOrder = ['Liga', 'Copa', 'Europa', 'Continental', 'Mundial', 'Otros'];
    final sortedCats = catOrder.where(byCategory.containsKey).toList();
    for (final c in byCategory.keys) {
      if (!sortedCats.contains(c)) sortedCats.add(c);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner total de títulos ───────────────────────────
          _TitlesBanner(
            total: titles.length,
            teamColor: primaryColor,
            teamName: team.name,
          ),

          // ── Trofeos por categoría ─────────────────────────────
          ...sortedCats.map((cat) => _CategorySection(
                category: cat,
                titles: byCategory[cat]!,
                teamColor: primaryColor,
              )),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  BANNER TOTAL
// ══════════════════════════════════════════════════════════════

class _TitlesBanner extends StatelessWidget {
  final int total;
  final Color teamColor;
  final String teamName;

  const _TitlesBanner({
    required this.total,
    required this.teamColor,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: teamNeoBox(bg: kTeamDark, shadowX: 4, shadowY: 4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icono trofeo grande
            Container(
              width: 64,
              height: 64,
              color: kTeamGold,
              child: const Center(
                child: Icon(Icons.emoji_events, size: 34, color: Colors.white),
              ),
            ),
            const SizedBox(width: 18),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PALMARÉS',
                    style: teamMono(
                      size: 9,
                      color: kTeamMuted,
                      weight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$total',
                        style: teamMono(
                          size: 42,
                          weight: FontWeight.w900,
                          color: kTeamGold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TÍTULO${total != 1 ? 'S' : ''}',
                        style: teamMono(
                          size: 12,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    teamName.toUpperCase(),
                    style: teamMono(size: 10, color: teamColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SECCIÓN POR CATEGORÍA
// ══════════════════════════════════════════════════════════════

class _CategorySection extends StatelessWidget {
  final String category;
  final List<TeamTitle> titles;
  final Color teamColor;

  const _CategorySection({
    required this.category,
    required this.titles,
    required this.teamColor,
  });

  Color _catColor() {
    switch (category.toLowerCase()) {
      case 'liga': return teamColor;
      case 'copa': return kTeamGreen;
      case 'europa': return const Color(0xFF3B82F6);
      case 'continental': return const Color(0xFF8B5CF6);
      case 'mundial': return kTeamGold;
      default: return kTeamMuted;
    }
  }

  IconData _catIcon() {
    switch (category.toLowerCase()) {
      case 'liga': return Icons.shield_outlined;
      case 'copa': return Icons.sports_soccer_outlined;
      case 'europa': return Icons.public_outlined;
      case 'continental': return Icons.language_outlined;
      case 'mundial': return Icons.emoji_events;
      default: return Icons.workspace_premium_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor();
    final catIcon = _catIcon();

    // Agrupar por nombre de competición
    final Map<String, List<TeamTitle>> byComp = {};
    for (final t in titles) {
      final comp = t.titleName ?? 'Sin nombre';
      byComp.putIfAbsent(comp, () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de categoría
        Container(
          margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          decoration: BoxDecoration(
            color: catColor,
            border: Border.all(color: kTeamBorder, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(catIcon, size: 14, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                category.toUpperCase(),
                style: teamMono(
                  size: 10,
                  weight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.black26,
                child: Text(
                  '${titles.length}',
                  style: teamMono(
                    size: 10,
                    weight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Competiciones de esta categoría
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          decoration: BoxDecoration(
            border: Border.all(color: kTeamBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: kTeamDark.withOpacity(0.4),
                offset: const Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: byComp.entries.map((e) {
              final years = e.value
                  .map((t) => t.year?.toString() ?? '?')
                  .where((y) => y != '?')
                  .toList()
                ..sort();

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: e.key != byComp.keys.last
                        ? BorderSide(color: kTeamBorderL, width: 0.5)
                        : BorderSide.none,
                  ),
                  color: kTeamBg,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trofeo count
                    Container(
                      width: 40,
                      height: 40,
                      color: catColor.withOpacity(0.12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(catIcon, size: 14, color: catColor),
                          Text(
                            '×${e.value.length}',
                            style: teamMono(
                              size: 9,
                              weight: FontWeight.w800,
                              color: catColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info competición
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: teamMono(size: 13, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          if (years.isNotEmpty)
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: years.map((y) => _YearBadge(
                                    year: y,
                                    color: catColor,
                                  )).toList(),
                            )
                          else
                            Text(
                              'Año no registrado',
                              style: teamMono(size: 10, color: kTeamMuted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _YearBadge extends StatelessWidget {
  final String year;
  final Color color;

  const _YearBadge({required this.year, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        color: color.withOpacity(0.08),
      ),
      child: Text(
        year,
        style: teamMono(size: 10, weight: FontWeight.w700, color: color),
      ),
    );
  }
}
