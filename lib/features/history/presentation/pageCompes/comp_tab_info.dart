import 'package:flutter/material.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';
import 'history_competitions_shared.dart';

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Hero card ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: tc, width: 4)),
              boxShadow: const [
                BoxShadow(
                    color: kHistDark,
                    offset: Offset(3, 3),
                    blurRadius: 0),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFFE8E4DE),
                  child: imgUrl != null
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.network(imgUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.emoji_events,
                                      size: 30, color: tc)))
                      : Icon(Icons.emoji_events, size: 30, color: tc),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          if (comp.type != null)
                            CompBadge(
                                label: compTypeLabels[comp.type!] ??
                                    comp.type!,
                                bg: tc,
                                fg: Colors.white),
                          if (comp.format != null)
                            CompBadge(
                                label:
                                    compFormatLabels[comp.format!] ??
                                        comp.format!,
                                bg: const Color(0xFFE8E4DE),
                                fg: kHistMuted),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(comp.name,
                          style: monoStyle(
                              size: 15, weight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      if (comp.winnerDisplay != '—')
                        Row(children: [
                          const Icon(Icons.emoji_events,
                              size: 12, color: kHistGold),
                          const SizedBox(width: 4),
                          Text('Campeón: ',
                              style: monoStyle(
                                  size: 10, color: kHistMuted)),
                          Flexible(
                            child: Text(comp.winnerDisplay,
                                style: monoStyle(
                                    size: 10,
                                    color: kHistGold,
                                    weight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Meta grid ────────────────────────────────────
          _MetaGrid(comp: comp),

          // ── Descripción ───────────────────────────────────
          if (comp.description != null) ...[
            const SizedBox(height: 20),
            CompSectionLabel(
                label: 'CONTEXTO HISTÓRICO',
                icon: Icons.public_outlined),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kHistBorderL),
              ),
              child: Text(comp.description!,
                  style: monoStyle(size: 12, color: kHistDark)),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

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
            color: kHistAccent),
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

    final w = (MediaQuery.of(context).size.width - 44) / 2;
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
                    border: Border.all(color: kHistBorderL),
                    boxShadow: const [
                      BoxShadow(
                          color: kHistBorderL,
                          offset: Offset(2, 2),
                          blurRadius: 0)
                    ],
                  ),
                  child: Row(children: [
                    Icon(item.icon, size: 14, color: item.color),
                    const SizedBox(width: 8),
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
                                  size: 11,
                                  color: item.color,
                                  weight: FontWeight.w700),
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
