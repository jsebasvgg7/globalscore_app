import 'package:flutter/material.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';
import 'history_competitions_shared.dart';

const Color _kPurple = Color(0xFF5B4FD8);

class CompTabInfo extends StatelessWidget {
  final CompetitionDetail detail;
  const CompTabInfo({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final comp   = detail.competition;
    final imgUrl = getHistoricalImageUrl(comp.imagePath);
    final tc     = compTypeColor(comp.type);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Hero card ────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kHistBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: kHistDark, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Franja de color del tipo arriba
                Container(height: 4, color: tc),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo cuadrado
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBE7E1),
                          border: Border.all(color: kHistBorderL, width: 1),
                        ),
                        child: imgUrl != null
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.network(imgUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                        Icons.emoji_events,
                                        size: 30, color: tc)),
                              )
                            : Icon(Icons.emoji_events, size: 30, color: tc),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badges
                            Wrap(spacing: 5, runSpacing: 4, children: [
                              if (comp.type != null)
                                CompBadge(
                                  label: compTypeLabels[comp.type!] ?? comp.type!,
                                  bg: tc,
                                  fg: Colors.white,
                                ),
                              if (comp.format != null)
                                CompBadge(
                                  label: compFormatLabels[comp.format!] ?? comp.format!,
                                  bg: const Color(0xFFE8E4DE),
                                  fg: kHistMuted,
                                ),
                            ]),
                            const SizedBox(height: 7),
                            Text(
                              comp.name,
                              style: monoStyle(
                                  size: 16, weight: FontWeight.w900),
                            ),
                            if (comp.year != null || comp.country != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                [
                                  if (comp.year != null) '${comp.year}',
                                  if (comp.country != null) comp.country!,
                                ].join(' · '),
                                style: monoStyle(size: 11, color: kHistMuted),
                              ),
                            ],
                            if (comp.winnerDisplay != '—') ...[
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.emoji_events,
                                    size: 12, color: kHistGold),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    comp.winnerDisplay,
                                    style: monoStyle(
                                      size: 11,
                                      color: kHistGold,
                                      weight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Meta grid ────────────────────────────────────
          _MetaGrid(comp: comp),

          // ── Contexto histórico ────────────────────────────
          if (comp.description != null) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              label: 'CONTEXTO HISTÓRICO',
              icon: Icons.public_outlined,
              color: _kPurple,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kHistBorderL),
                boxShadow: const [
                  BoxShadow(
                      color: kHistBorderL,
                      offset: Offset(3, 3),
                      blurRadius: 0),
                ],
              ),
              child: Text(
                comp.description!,
                style: monoStyle(size: 12, color: kHistDark),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section header con punto de color ────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionHeader(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: monoStyle(
            size: 10,
            color: color,
            weight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ]);
}

// ── Meta grid ─────────────────────────────────────────────────
class _MetaGrid extends StatelessWidget {
  final HistoricalCompetition comp;
  const _MetaGrid({required this.comp});

  @override
  Widget build(BuildContext context) {
    final tc = compTypeColor(comp.type);
    final items = <_MetaItem>[
      if (comp.year != null)
        _MetaItem(
            icon: Icons.calendar_today_outlined,
            label: 'AÑO',
            value: '${comp.year}',
            color: _kPurple),
      if (comp.country != null)
        _MetaItem(
            icon: Icons.public_outlined,
            label: 'SEDE',
            value: comp.country!,
            color: kHistMuted),
      if (comp.type != null)
        _MetaItem(
            icon: Icons.flag_outlined,
            label: 'TIPO',
            value: compTypeLabels[comp.type!] ?? comp.type!,
            color: tc),
      if (comp.numTeams != null)
        _MetaItem(
            icon: Icons.groups_outlined,
            label: 'EQUIPOS',
            value: '${comp.numTeams}',
            color: const Color(0xFF10B981)),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    final w = (MediaQuery.of(context).size.width - 42) / 2;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((item) => SizedBox(
                width: w,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: kHistBorder, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                          color: kHistDark,
                          offset: Offset(3, 3),
                          blurRadius: 0),
                    ],
                  ),
                  child: Row(children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: item.color,
                        border: Border.all(color: kHistBorder, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                              color: kHistDark,
                              offset: Offset(2, 2),
                              blurRadius: 0),
                        ],
                      ),
                      child: Icon(item.icon, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label,
                              style: monoStyle(
                                  size: 7,
                                  color: kHistMuted,
                                  letterSpacing: 1)),
                          Text(item.value,
                              style: monoStyle(
                                  size: 12,
                                  color: item.color,
                                  weight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ]),
                ),
              ))
          .toList(),
    );
  }
}

class _MetaItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MetaItem(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
}