import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_players_shared.dart';
import '../../data/history_service.dart';

// Mapeo de event_type igual que en React
const _eventTypeLabel = {
  'Championship': 'Campeonato',
  'Historic Match': 'Partido Histórico',
  'Legendary Performance': 'Actuación Legendaria',
  'Era Defining': 'Definió una Era',
  'Record': 'Récord',
};

class PlayerTabEquipos extends StatelessWidget {
  final PlayerDetail detail;
  const PlayerTabEquipos({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final teamLinks = detail.teamLinks;
    final eventLinks = detail.eventLinks;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────
            _TabHeader(
              icon: Icons.shield_outlined,
              title: 'EQUIPOS & MOMENTOS',
              subtitle: teamLinks.isEmpty
                  ? 'Sin registros'
                  : '${teamLinks.length} equipo${teamLinks.length != 1 ? 's' : ''} histórico${teamLinks.length != 1 ? 's' : ''}',
            ),

            if (teamLinks.isEmpty && eventLinks.isEmpty)
              const _Empty(message: 'Sin datos de equipos ni momentos')
            else ...[

              // ── Equipos históricos ──────────────────────
              if (teamLinks.isNotEmpty) ...[
                _SectionLabel(label: 'EQUIPOS HISTÓRICOS'),
                _TeamLinksList(links: teamLinks),
              ],

              // ── Momentos históricos ─────────────────────
              if (eventLinks.isNotEmpty) ...[
                _SectionLabel(label: 'MOMENTOS HISTÓRICOS', color: kHistGold),
                _EventLinksList(links: eventLinks),
              ],
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Lista de equipos históricos (tipo row, con imagen) ─────────
class _TeamLinksList extends StatelessWidget {
  final List<PlayerTeamLink> links;
  const _TeamLinksList({required this.links});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: links.map((link) => _TeamLinkRow(link: link)).toList(),
      ),
    );
  }
}

class _TeamLinkRow extends StatelessWidget {
  final PlayerTeamLink link;
  const _TeamLinkRow({required this.link});

  Color get _teamColor {
    if (link.primaryColor == null) return kHistAccent;
    try {
      final hex = link.primaryColor!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return kHistAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(link.teamImagePath);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: neoBox(shadowX: 3, shadowY: 3),
      child: Row(
        children: [
          // Logo del equipo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _teamColor.withOpacity(0.08),
              border: Border.all(color: kHistBorderL, width: 1),
            ),
            child: imgUrl != null
                ? Image.network(imgUrl, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.shield, size: 24, color: _teamColor))
                : Icon(Icons.shield, size: 24, color: _teamColor),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.teamName.toUpperCase(),
                  style: monoStyle(
                      size: 12, weight: FontWeight.w800, letterSpacing: -0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (link.teamCountry != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    link.teamCountry!,
                    style: monoStyle(size: 9, color: kHistMuted),
                  ),
                ],
                if (link.roles != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    link.roles!,
                    style: monoStyle(size: 9, color: kHistMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Período
          Text(
            '${link.startYear} – ${link.endYear}',
            style: monoStyle(
                size: 10, color: kHistAccent, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Lista de momentos históricos (eventos) ─────────────────────
class _EventLinksList extends StatelessWidget {
  final List<PlayerEventLink> links;
  const _EventLinksList({required this.links});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: links.map((link) => _EventLinkRow(link: link)).toList(),
      ),
    );
  }
}

class _EventLinkRow extends StatelessWidget {
  final PlayerEventLink link;
  const _EventLinkRow({required this.link});

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(link.imagePath);
    final typeLabel = _eventTypeLabel[link.eventType] ?? link.eventType;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: neoBox(shadowX: 3, shadowY: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail del evento
          if (imgUrl != null)
            SizedBox(
              width: 64,
              height: 64,
              child: Image.network(imgUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                        color: kHistDark,
                        child: const Icon(Icons.bolt, size: 24, color: kHistAccent),
                      )),
            )
          else
            Container(
              width: 64,
              height: 64,
              color: kHistDark,
              child: const Icon(Icons.bolt, size: 24, color: kHistAccent),
            ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge + year
                  Row(
                    children: [
                      if (typeLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          color: kHistAccent,
                          child: Text(
                            typeLabel.toUpperCase(),
                            style: monoStyle(
                                size: 7,
                                color: Colors.white,
                                weight: FontWeight.w800,
                                letterSpacing: 0.6),
                          ),
                        ),
                      if (link.year != null) ...[
                        const SizedBox(width: 6),
                        Text('${link.year}',
                            style: monoStyle(size: 9, color: kHistMuted)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Título del evento
                  Text(
                    link.eventTitle,
                    style: monoStyle(size: 11, weight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Role note si existe
                  if (link.roleNote != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      link.roleNote!,
                      style: monoStyle(
                          size: 9, color: kHistMuted, letterSpacing: 0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers compartidos ─────────────────────────────────────────
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
            width: 8,
            height: 8,
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
              size: 9,
              weight: FontWeight.w800,
              letterSpacing: 1.2,
              color: color,
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