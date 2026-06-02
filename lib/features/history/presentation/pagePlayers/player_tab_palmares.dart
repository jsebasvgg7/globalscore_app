import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_players_shared.dart';

class PlayerTabPalmares extends StatelessWidget {
  final PlayerDetail detail;
  const PlayerTabPalmares({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final titles = detail.titles;

    // Agrupa por nombre de título para mostrar cantidad
    final Map<String, _TitleGroup> grouped = {};
    for (final t in titles) {
      final key = '${t.titleName}_${t.titleCategory}';
      if (grouped.containsKey(key)) {
        grouped[key] = grouped[key]!.addYear(t.year);
      } else {
        grouped[key] = _TitleGroup(
          title: t,
          years: t.year != null ? [t.year!] : [],
          totalQuantity: t.quantity,
        );
      }
    }

    final clubTitles = grouped.values
        .where((g) => g.title.titleCategory == 'club')
        .toList();
    final nationalTitles = grouped.values
        .where((g) => g.title.titleCategory == 'national')
        .toList();
    final individualTitles = grouped.values
        .where((g) => g.title.titleCategory == 'individual')
        .toList();

    final totalTrophies = titles.fold<int>(0, (sum, t) {
      if (t.titleCategory != 'individual') return sum + t.quantity;
      return sum;
    });

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          _PalmaresHeader(totalTrophies: totalTrophies),

          if (titles.isEmpty)
            const _Empty(message: 'Sin datos de palmarés')
          else ...[
            if (clubTitles.isNotEmpty) ...[
              _SectionLabel(
                label: 'CLUB',
                icon: Icons.shield_outlined,
                color: kHistAccent,
              ),
              _TitlesColumn(groups: clubTitles, accentColor: kHistAccent),
            ],
            if (nationalTitles.isNotEmpty) ...[
              _SectionLabel(
                label: 'SELECCIÓN',
                icon: Icons.public_outlined,
                color: kHistGreen,
              ),
              _TitlesColumn(groups: nationalTitles, accentColor: kHistGreen),
            ],
            if (individualTitles.isNotEmpty) ...[
              _SectionLabel(
                label: 'INDIVIDUAL',
                icon: Icons.person_outline_rounded,
                color: kHistGold,
              ),
              _TitlesColumn(groups: individualTitles, accentColor: kHistGold),
            ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Palmares header con total de trofeos ──────────────────────
class _PalmaresHeader extends StatelessWidget {
  final int totalTrophies;
  const _PalmaresHeader({required this.totalTrophies});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: kHistCard,
        border: Border(bottom: BorderSide(color: kHistBorder, width: 1.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: neoBox(bg: kHistDark, shadowX: 3, shadowY: 3),
            child: const Icon(Icons.emoji_events_outlined,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PALMARÉS',
                  style: monoStyle(
                      size: 16, weight: FontWeight.w900, letterSpacing: -0.3),
                ),
                Text(
                  '$totalTrophies títulos colectivos',
                  style: monoStyle(size: 10, color: kHistMuted),
                ),
              ],
            ),
          ),
          // Total badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kHistGold,
              border: Border.all(color: kHistBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: kHistDark.withOpacity(0.45),
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text(
              '$totalTrophies',
              style: monoStyle(
                size: 22, weight: FontWeight.w900, color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Columna de títulos ────────────────────────────────────────
class _TitlesColumn extends StatelessWidget {
  final List<_TitleGroup> groups;
  final Color accentColor;
  const _TitlesColumn({
    required this.groups,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: groups.map((g) => _TitleRow(
          group: g,
          accentColor: accentColor,
        )).toList(),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final _TitleGroup group;
  final Color accentColor;
  const _TitleRow({required this.group, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final yearsStr = group.years.isNotEmpty ? group.years.join(', ') : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: kHistBg,
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: BorderSide(color: kHistBorderL, width: 0.5),
          right: BorderSide(color: kHistBorderL, width: 0.5),
          bottom: BorderSide(color: kHistBorderL, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: kHistDark.withOpacity(0.15),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Trofeo icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 18,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),

          // Título + años
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.title.titleName.toUpperCase(),
                  style: monoStyle(
                      size: 12, weight: FontWeight.w900, letterSpacing: -0.2),
                ),
                if (yearsStr.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    yearsStr,
                    style: monoStyle(
                        size: 9, color: kHistMuted, weight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),

          // Contador
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor,
              border: Border.all(color: kHistBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: kHistDark.withOpacity(0.35),
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${group.totalQuantity}',
                style: monoStyle(
                  size: 12, weight: FontWeight.w900, color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: monoStyle(
              size: 9, weight: FontWeight.w800,
              letterSpacing: 1.2, color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(message, style: monoStyle(color: kHistMuted, size: 13)),
      ),
    );
  }
}

// ── Model helper ──────────────────────────────────────────────
class _TitleGroup {
  final PlayerTitleEntry title;
  final List<String> years;
  final int totalQuantity;

  const _TitleGroup({
    required this.title,
    required this.years,
    required this.totalQuantity,
  });

  _TitleGroup addYear(String? year) {
    return _TitleGroup(
      title: title,
      years: year != null ? [...years, year] : years,
      totalQuantity: totalQuantity + title.quantity,
    );
  }
}
