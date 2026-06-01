import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import '../history_players_shared.dart';

class PlayerTabTrayectoria extends StatelessWidget {
  final PlayerDetail detail;
  const PlayerTabTrayectoria({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final career = detail.career;
    final national = detail.national;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          _TabHeader(
            icon: Icons.timeline_outlined,
            title: 'TRAYECTORIA',
            subtitle: '${career.length} clubes · ${national.length} selecciones',
          ),

          if (career.isEmpty && national.isEmpty)
            _Empty(message: 'Sin datos de trayectoria')
          else ...[
            // ── Timeline de clubes ───────────────────────────
            if (career.isNotEmpty) ...[
              _SectionLabel(label: 'CLUBES', color: kHistAccent),
              _CareerTimeline(entries: career),
            ],

            // ── Selección nacional ───────────────────────────
            if (national.isNotEmpty) ...[
              _SectionLabel(label: 'SELECCIÓN NACIONAL', color: kHistGreen),
              _NationalTimeline(entries: national),
            ],
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Header del tab ────────────────────────────────────────────
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
              Text(
                title,
                style: monoStyle(
                    size: 16, weight: FontWeight.w900, letterSpacing: -0.3),
              ),
              Text(
                subtitle,
                style: monoStyle(size: 10, color: kHistMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

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

// ── Timeline de clubes ────────────────────────────────────────
class _CareerTimeline extends StatelessWidget {
  final List<PlayerCareerEntry> entries;
  const _CareerTimeline({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          final isLast = i == entries.length - 1;
          return _TimelineItem(
            year: entry.startYear,
            isLast: isLast,
            accentColor: kHistAccent,
            child: _ClubCard(entry: entry),
          );
        }).toList(),
      ),
    );
  }
}

// ── Timeline de selección ─────────────────────────────────────
class _NationalTimeline extends StatelessWidget {
  final List<PlayerNationalEntry> entries;
  const _NationalTimeline({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          final isLast = i == entries.length - 1;
          return _TimelineItem(
            year: entry.startYear,
            isLast: isLast,
            accentColor: kHistGreen,
            child: _NationalCard(entry: entry),
          );
        }).toList(),
      ),
    );
  }
}

// ── Timeline item wrapper ─────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  final int? year;
  final bool isLast;
  final Color accentColor;
  final Widget child;
  const _TimelineItem({
    required this.year,
    required this.isLast,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Año + línea vertical
          SizedBox(
            width: 52,
            child: Column(
              children: [
                // Año badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor,
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
                    year != null ? '$year' : '?',
                    style: monoStyle(
                      size: 9, weight: FontWeight.w900,
                      color: Colors.white, letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Línea conectora
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: accentColor.withOpacity(0.3),
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Club card ─────────────────────────────────────────────────
class _ClubCard extends StatelessWidget {
  final PlayerCareerEntry entry;
  const _ClubCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: neoBox(shadowX: 3, shadowY: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Club + período
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.teamName.toUpperCase(),
                  style: monoStyle(
                      size: 13, weight: FontWeight.w900, letterSpacing: -0.3),
                ),
              ),
              Text(
                '${entry.startYear ?? '?'} – ${entry.endYear ?? '?'}',
                style: monoStyle(size: 9, color: kHistAccent,
                    weight: FontWeight.w700),
              ),
            ],
          ),

          if (entry.teamCountry != null || entry.roleNote != null) ...[
            const SizedBox(height: 4),
            Text(
              entry.roleNote ?? entry.teamCountry ?? '',
              style: monoStyle(size: 9, color: kHistMuted,
                  weight: FontWeight.w600, letterSpacing: 0.6),
            ),
          ],

          // Stats inline
          if (entry.appearances > 0 ||
              entry.goals > 0 ||
              entry.assists > 0) ...[
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: kHistBorderL,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (entry.appearances > 0)
                  _MiniStat(
                      value: '${entry.appearances}', label: 'PJ'),
                if (entry.goals > 0)
                  _MiniStat(
                      value: '${entry.goals}',
                      label: 'G',
                      color: kHistAccent),
                if (entry.assists > 0)
                  _MiniStat(
                      value: '${entry.assists}',
                      label: 'A',
                      color: kHistGreen),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── National card ─────────────────────────────────────────────
class _NationalCard extends StatelessWidget {
  final PlayerNationalEntry entry;
  const _NationalCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: neoBox(shadowX: 3, shadowY: 3, bg: kHistCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.country.toUpperCase(),
                  style: monoStyle(
                      size: 13, weight: FontWeight.w900, letterSpacing: -0.3),
                ),
              ),
              Text(
                '${entry.startYear ?? '?'} – ${entry.endYear ?? '?'}',
                style: monoStyle(
                    size: 9, color: kHistGreen, weight: FontWeight.w700),
              ),
            ],
          ),
          if (entry.roleNote != null) ...[
            const SizedBox(height: 4),
            Text(
              entry.roleNote!,
              style: monoStyle(
                  size: 9, color: kHistMuted,
                  weight: FontWeight.w600, letterSpacing: 0.6),
            ),
          ],
          if (entry.caps > 0 || entry.goals > 0) ...[
            const SizedBox(height: 8),
            Container(height: 1, color: kHistBorderL),
            const SizedBox(height: 8),
            Row(
              children: [
                if (entry.caps > 0)
                  _MiniStat(value: '${entry.caps}', label: 'PARTIDOS'),
                if (entry.goals > 0)
                  _MiniStat(
                      value: '${entry.goals}',
                      label: 'GOLES',
                      color: kHistGreen),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Mini stat inline ──────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniStat({
    required this.value,
    required this.label,
    this.color = kHistDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: monoStyle(
                size: 14, weight: FontWeight.w900, color: color),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: monoStyle(
                size: 8, weight: FontWeight.w600, color: kHistMuted),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────
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
