import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_players_shared.dart';

// ── Helper: construye eventos de la historia a partir de datos reales ──
List<_HistoriaEvent> _buildHistoria(PlayerDetail detail) {
  final events = <_HistoriaEvent>[];
  final p = detail.player;

  // Nacimiento
  if (p.birthYear != null) {
    events.add(_HistoriaEvent(
      year: p.birthYear!,
      title: 'NACE EN ${p.country?.toUpperCase() ?? '—'}',
      description: p.country != null
          ? 'Inicio de una historia en el fútbol mundial.'
          : null,
      imagePath: null,
      type: _EventType.birth,
    ));
  }

  // Clubes
  for (final c in detail.career) {
    if (c.startYear != null) {
      events.add(_HistoriaEvent(
        year: c.startYear!,
        title: c.roleNote?.toUpperCase() ??
            'LLEGA A ${c.teamName.toUpperCase()}',
        description: c.teamCountry != null
            ? '${c.teamName} · ${c.teamCountry}'
            : c.teamName,
        imagePath: null,
        type: _EventType.club,
        subtitle: c.roleNote,
      ));
    }
  }

  // Títulos individuales destacados (Balón de Oro, etc.)
  for (final t in detail.titles) {
    if (t.titleCategory == 'individual' && t.year != null) {
      final yearInt = int.tryParse(t.year!.split('-').first);
      if (yearInt != null) {
        events.add(_HistoriaEvent(
          year: yearInt,
          title: t.titleName.toUpperCase(),
          description: t.teamName,
          imagePath: null,
          type: _EventType.award,
        ));
      }
    }
  }

  // Selección nacional
  for (final n in detail.national) {
    if (n.startYear != null) {
      events.add(_HistoriaEvent(
        year: n.startYear!,
        title: 'DEBUTA CON ${n.country.toUpperCase()}',
        description: n.roleNote,
        imagePath: null,
        type: _EventType.national,
      ));
    }
  }

  events.sort((a, b) => a.year.compareTo(b.year));
  return events;
}

// ══════════════════════════════════════════════════════════════
//  TAB HISTORIA
// ══════════════════════════════════════════════════════════════

class PlayerTabHistoria extends StatelessWidget {
  final PlayerDetail detail;
  const PlayerTabHistoria({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final events = _buildHistoria(detail);
        
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
          _HistoriaHeader(detail: detail),

          if (events.isEmpty)
            const _Empty(message: 'Sin datos históricos')
          else ...[
            const SizedBox(height: 8),
            _HistoriaTimeline(events: events),
          ],
         ],
       ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────
class _HistoriaHeader extends StatelessWidget {
  final PlayerDetail detail;
  const _HistoriaHeader({required this.detail});

  @override
  Widget build(BuildContext context) {
    final p = detail.player;
    final lifespan = p.birthYear != null
        ? '${p.birthYear}${p.deathYear != null ? ' – ${p.deathYear}' : ' – Presente'}'
        : null;

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
            child: const Icon(Icons.auto_stories_outlined,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HISTORIA',
                  style: monoStyle(
                      size: 16, weight: FontWeight.w900, letterSpacing: -0.3),
                ),
                Text(
                  lifespan ?? 'Línea de tiempo',
                  style: monoStyle(size: 10, color: kHistMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline vertical ─────────────────────────────────────────
class _HistoriaTimeline extends StatelessWidget {
  final List<_HistoriaEvent> events;
  const _HistoriaTimeline({required this.events});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: events.asMap().entries.map((e) {
          final i = e.key;
          final event = e.value;
          final isLast = i == events.length - 1;
          return _TimelineRow(event: event, isLast: isLast);
        }).toList(),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final _HistoriaEvent event;
  final bool isLast;
  const _TimelineRow({required this.event, required this.isLast});

  Color get _typeColor => switch (event.type) {
        _EventType.birth    => kHistGold,
        _EventType.club     => kHistAccent,
        _EventType.national => kHistGreen,
        _EventType.award    => kHistGold,
      };

  IconData get _typeIcon => switch (event.type) {
        _EventType.birth    => Icons.child_care_outlined,
        _EventType.club     => Icons.shield_outlined,
        _EventType.national => Icons.public_outlined,
        _EventType.award    => Icons.emoji_events_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Año + línea
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
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
                    '${event.year}',
                    style: monoStyle(
                      size: 8, weight: FontWeight.w900,
                      color: event.type == _EventType.birth ||
                              event.type == _EventType.award
                          ? Colors.black
                          : Colors.white,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: color.withOpacity(0.25),
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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kHistBg,
                  border: Border(
                    left: BorderSide(color: color, width: 3),
                    top: BorderSide(color: kHistBorderL, width: 0.5),
                    right: BorderSide(color: kHistBorderL, width: 0.5),
                    bottom: BorderSide(color: kHistBorderL, width: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kHistDark.withOpacity(0.12),
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Ícono del tipo
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        border: Border.all(
                            color: color.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(_typeIcon, size: 16, color: color),
                    ),
                    const SizedBox(width: 10),

                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: monoStyle(
                              size: 11, weight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (event.description != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              event.description!,
                              style: monoStyle(
                                  size: 10, color: kHistMuted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Models locales ────────────────────────────────────────────
enum _EventType { birth, club, national, award }

class _HistoriaEvent {
  final int year;
  final String title;
  final String? description;
  final String? imagePath;
  final _EventType type;
  final String? subtitle;

  const _HistoriaEvent({
    required this.year,
    required this.title,
    required this.type,
    this.description,
    this.imagePath,
    this.subtitle,
  });
}

// ── Empty ─────────────────────────────────────────────────────
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
