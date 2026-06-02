import 'package:flutter/material.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';
import 'history_events_shared.dart';

class EventTabInfo extends StatelessWidget {
  final EventDetail detail;
  const EventTabInfo({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final event = detail.event;
    final accentColor = catColor(event.eventCategory);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero banner ───────────────────────────────────────
          _EventHero(event: event, accentColor: accentColor),

          // ── Protagonista mini ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: EvProtagonistMini(event: event),
          ),

          // ── Score si existe ───────────────────────────────────
          if (event.scoreA != null && event.scoreB != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: EvScoreBlock(event: event),
            ),

          // ── Contexto ─────────────────────────────────────────
          if (event.contextText != null || event.description != null)
            _NarrativeBlock(
              label: 'CONTEXTO',
              icon: Icons.history_edu_outlined,
              text: event.contextText ?? event.description!,
              color: accentColor,
            ),

          // ── Impacto ───────────────────────────────────────────
          if (event.impactText != null)
            _NarrativeBlock(
              label: 'IMPACTO Y LEGADO',
              icon: Icons.bolt_outlined,
              text: event.impactText!,
              color: kEvGold,
              dark: true,
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Hero banner con imagen ────────────────────────────────────
class _EventHero extends StatelessWidget {
  final HistoricalEvent event;
  final Color accentColor;
  const _EventHero({required this.event, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: usa getHistoricalImageUrl para resolver paths relativos del storage
    final heroUrl = event.bannerImagePath != null
        ? getHistoricalImageUrl(event.bannerImagePath)
        : getHistoricalImageUrl(event.imagePath);

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: kEvDark,
        border: Border(bottom: BorderSide(color: kEvBorder, width: 1.5)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen
          if (heroUrl != null)
            Image.network(
              heroUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(accentColor),
            )
          else
            _placeholder(accentColor),

          // Gradiente
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD91A1A2E)],
              ),
            ),
          ),

          // Badges + fecha abajo izquierda
          Positioned(
            left: 16,
            bottom: 14,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    if (event.eventCategory != null)
                      EvCatBadge(category: event.eventCategory!),
                    if (event.eventType != null)
                      EvTypeBadge(type: event.eventType!),
                  ],
                ),
                if (event.eventDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 10, color: Colors.white70),
                      const SizedBox(width: 5),
                      Text(
                        _formatDate(event.eventDate!),
                        style: evMono(size: 10, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(Color color) => Container(
        color: kEvDark,
        child: Center(
          child: Icon(Icons.bolt_outlined,
              size: 48, color: color.withOpacity(0.3)),
        ),
      );

  String _formatDate(String date) {
    try {
      final d = DateTime.parse('${date}T12:00:00');
      const months = [
        '',
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return date;
    }
  }
}

// ── Bloque de texto narrativo ─────────────────────────────────
class _NarrativeBlock extends StatelessWidget {
  final String label;
  final IconData icon;
  final String text;
  final Color color;
  final bool dark;

  const _NarrativeBlock({
    required this.label,
    required this.icon,
    required this.text,
    required this.color,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final paragraphs =
        text.split('\n').where((p) => p.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EvSectionLabel(label: label, color: color),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark ? kEvDark : kEvCard,
            border: Border.all(color: kEvBorderL),
            boxShadow: [
              BoxShadow(
                color: kEvDark.withOpacity(0.3),
                offset: const Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: paragraphs.asMap().entries.map((e) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: e.key < paragraphs.length - 1 ? 10 : 0),
                child: Text(
                  e.value.trim(),
                  style: evMono(
                    size: 13,
                    color: dark ? Colors.white.withOpacity(0.85) : kEvDark,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}