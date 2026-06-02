import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_teams_shared.dart';

class TeamTabResumen extends StatelessWidget {
  final TeamDetail detail;

  const TeamTabResumen({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final team = detail.team;
    final primaryColor = parseHexColor(team.primaryColor);
    final secondaryColor = parseHexColor(team.secondaryColor, fallback: kTeamDark);
    final titlesCount = detail.titles.length;
    final playersCount = detail.lineup.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero visual con gradiente ─────────────────────────
          _TeamHero(
            team: team,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
          ),

          // ── Stats rápidas ─────────────────────────────────────
          _QuickStats(
            titlesCount: titlesCount,
            playersCount: playersCount,
            team: team,
            primaryColor: primaryColor,
          ),

          // ── Escudo + descripción ──────────────────────────────
          if (team.description != null) ...[
            const TeamSectionLabel(label: 'HISTORIA DEL CLUB', icon: Icons.history_edu_outlined),
            _DescriptionBlock(description: team.description!),
          ],

          // ── Legacy / tipo ─────────────────────────────────────
          _LegacyBlock(team: team, primaryColor: primaryColor),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HERO
// ══════════════════════════════════════════════════════════════

class _TeamHero extends StatelessWidget {
  final HistoricalTeam team;
  final Color primaryColor;
  final Color secondaryColor;

  const _TeamHero({
    required this.team,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kTeamDark,
        border: Border(bottom: BorderSide(color: kTeamBorder, width: 1.5)),
      ),
      child: Stack(
        children: [
          // Franja de color primario del equipo (izquierda)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(color: primaryColor),
          ),

          // Franja secundaria
          Positioned(
            left: 6,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: secondaryColor.withOpacity(0.6)),
          ),

          // Dot grid decorativo esquina derecha
          Positioned(
            right: 0,
            top: 0,
            child: Opacity(
              opacity: 0.08,
              child: TeamDotGrid(cols: 8, rows: 6),
            ),
          ),

          // Contenido principal
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 16, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo grande
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: TeamLogo(
                    imagePath: team.imagePath,
                    teamName: team.name,
                    size: 90,
                    teamColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 18),

                // Info principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo badge
                      if (team.legacyType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          color: primaryColor,
                          child: Text(
                            (legacyTypeLabel[team.legacyType] ?? team.legacyType!).toUpperCase(),
                            style: teamMono(
                              color: Colors.white,
                              size: 8,
                              weight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Nombre
                      Text(
                        team.name.toUpperCase(),
                        style: teamMono(
                          color: Colors.white,
                          size: 20,
                          weight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // País + era
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (team.country != null)
                            _HeroChip(
                              label: team.country!,
                              icon: Icons.flag_outlined,
                              color: Colors.white54,
                            ),
                          if (team.era != null)
                            _HeroChip(
                              label: team.era!,
                              icon: Icons.schedule_outlined,
                              color: primaryColor.withOpacity(0.9),
                            ),
                          if (team.titlesCount != null)
                            _HeroChip(
                              label: '${team.titlesCount} títulos',
                              icon: Icons.emoji_events_outlined,
                              color: kTeamGold,
                            ),
                        ],
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

class _HeroChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _HeroChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: color),
        const SizedBox(width: 4),
        Text(label, style: teamMono(size: 10, color: color)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  QUICK STATS
// ══════════════════════════════════════════════════════════════

class _QuickStats extends StatelessWidget {
  final int titlesCount;
  final int playersCount;
  final HistoricalTeam team;
  final Color primaryColor;

  const _QuickStats({
    required this.titlesCount,
    required this.playersCount,
    required this.team,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, Color)>[
      ('$titlesCount', 'TÍTULOS', kTeamGold),
      ('$playersCount', 'JUGADORES', primaryColor),
      if (team.country != null) (team.country!, 'PAÍS', kTeamGreen),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: teamNeoBox(shadowX: 4, shadowY: 4),
      child: IntrinsicHeight(
        child: Row(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            final (val, label, color) = e.value;
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(right: BorderSide(color: kTeamBorder, width: 1.5)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                child: TeamStatBox(value: val, label: label, color: color),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DESCRIPCIÓN
// ══════════════════════════════════════════════════════════════

class _DescriptionBlock extends StatelessWidget {
  final String description;

  const _DescriptionBlock({required this.description});

  @override
  Widget build(BuildContext context) {
    final paragraphs = description.split('\n').where((p) => p.trim().isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: kTeamBorderL),
        color: kTeamCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs.asMap().entries.map((e) {
          return Padding(
            padding: EdgeInsets.only(bottom: e.key < paragraphs.length - 1 ? 10 : 0),
            child: Text(
              e.value.trim(),
              style: teamMono(size: 13, color: kTeamDark),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LEGACY BLOCK
// ══════════════════════════════════════════════════════════════

class _LegacyBlock extends StatelessWidget {
  final HistoricalTeam team;
  final Color primaryColor;

  const _LegacyBlock({required this.team, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    if (team.legacyType == null && team.eraDominance == null && team.activeYears == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TeamSectionLabel(label: 'IDENTIDAD DEL EQUIPO', icon: Icons.shield_outlined),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          decoration: teamNeoBox(bg: kTeamDark, shadowX: 3, shadowY: 3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (team.legacyType != null)
                  _IdentityItem(
                    label: 'TIPO',
                    value: legacyTypeLabel[team.legacyType] ?? team.legacyType!,
                    icon: Icons.category_outlined,
                    color: primaryColor,
                  ),
                if (team.eraDominance != null)
                  _IdentityItem(
                    label: 'ERA DE DOMINIO',
                    value: team.eraDominance!,
                    icon: Icons.schedule_outlined,
                    color: kTeamGold,
                  ),
                if (team.activeYears != null)
                  _IdentityItem(
                    label: 'AÑOS ACTIVOS',
                    value: team.activeYears!,
                    icon: Icons.calendar_today_outlined,
                    color: kTeamGreen,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _IdentityItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.4)),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 9, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: teamMono(size: 8, color: color, weight: FontWeight.w700, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: teamMono(size: 13, color: Colors.white, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
