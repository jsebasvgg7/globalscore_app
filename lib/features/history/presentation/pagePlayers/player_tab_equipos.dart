import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_players_shared.dart';

class PlayerTabEquipos extends StatelessWidget {
  final PlayerDetail detail;
  const PlayerTabEquipos({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final career = detail.career;
    final titles = detail.titles
        .where((t) => t.titleCategory == 'club')
        .toList();

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // ── Header ──────────────────────────────────────────
          _TabHeader(
            icon: Icons.shield_outlined,
            title: 'EQUIPOS',
            subtitle: '${career.length} clubes en su carrera',
          ),

          if (career.isEmpty)
            const _Empty(message: 'Sin datos de equipos')
          else ...[
            // ── Grid de equipos ──────────────────────────────
            _SectionLabel(label: 'CLUBES'),
            _TeamsGrid(entries: career),

            // ── Momentos históricos (títulos de club) ────────
            if (titles.isNotEmpty) ...[
              _SectionLabel(label: 'MOMENTOS HISTÓRICOS', color: kHistGold),
              _MomentsList(titles: titles),
            ],
          ],

          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }
}

// ── Teams grid 2 col ──────────────────────────────────────────
class _TeamsGrid extends StatelessWidget {
  final List<PlayerCareerEntry> entries;
  const _TeamsGrid({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Pares de items para grid 2x cols
    final rows = <List<PlayerCareerEntry>>[];
    for (int i = 0; i < entries.length; i += 2) {
      rows.add([
        entries[i],
        if (i + 1 < entries.length) entries[i + 1],
      ]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: _TeamCard(entry: row[0])),
                const SizedBox(width: 10),
                row.length > 1
                    ? Expanded(child: _TeamCard(entry: row[1]))
                    : const Expanded(child: SizedBox()),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final PlayerCareerEntry entry;
  const _TeamCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: neoBox(shadowX: 3, shadowY: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono de escudo placeholder
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kHistAccent.withOpacity(0.1),
              border: Border.all(color: kHistBorderL, width: 1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 18,
              color: kHistAccent,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            entry.teamName.toUpperCase(),
            style: monoStyle(
                size: 11, weight: FontWeight.w900, letterSpacing: -0.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          Text(
            '${entry.startYear ?? '?'} – ${entry.endYear ?? '?'}',
            style: monoStyle(
                size: 9, color: kHistAccent, weight: FontWeight.w700),
          ),

          if (entry.roleNote != null) ...[
            const SizedBox(height: 2),
            Text(
              entry.roleNote!,
              style: monoStyle(size: 8, color: kHistMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Mini stats si existen
          if (entry.goals > 0 || entry.appearances > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (entry.appearances > 0) ...[
                  Text(
                    '${entry.appearances}',
                    style: monoStyle(
                        size: 11, weight: FontWeight.w900, color: kHistDark),
                  ),
                  const SizedBox(width: 2),
                  Text('PJ',
                      style: monoStyle(size: 7, color: kHistMuted)),
                  const SizedBox(width: 8),
                ],
                if (entry.goals > 0) ...[
                  Text(
                    '${entry.goals}',
                    style: monoStyle(
                        size: 11, weight: FontWeight.w900, color: kHistAccent),
                  ),
                  const SizedBox(width: 2),
                  Text('G',
                      style: monoStyle(size: 7, color: kHistMuted)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Momentos históricos (títulos de club en cards horizontales) ──
class _MomentsList extends StatelessWidget {
  final List<PlayerTitleEntry> titles;
  const _MomentsList({required this.titles});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scroll horizontal con las 3 primeras
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: titles.take(6).length,
            itemBuilder: (_, i) => _MomentCard(title: titles[i]),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _MomentCard extends StatelessWidget {
  final PlayerTitleEntry title;
  const _MomentCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      decoration: neoBox(bg: kHistDark, shadowX: 3, shadowY: 3),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year badge
          if (title.year != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              color: kHistAccent,
              child: Text(
                title.year!,
                style: monoStyle(
                    size: 8, weight: FontWeight.w900, color: Colors.white),
              ),
            ),
          const Spacer(),

          Text(
            title.titleName.toUpperCase(),
            style: monoStyle(
              size: 9, weight: FontWeight.w900,
              color: Colors.white, letterSpacing: -0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          if (title.teamName != null)
            Text(
              title.teamName!,
              style: monoStyle(size: 8, color: Colors.white60),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────
class _TabHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TabHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

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
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: monoStyle(
                      size: 16, weight: FontWeight.w900, letterSpacing: -0.3)),
              Text(subtitle, style: monoStyle(size: 10, color: kHistMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, this.color = kHistAccent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: kHistBorder, width: 1),
            ),
          ),
          const SizedBox(width: 8),
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
