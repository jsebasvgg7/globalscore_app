import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import 'history_events_shared.dart';

// ══════════════════════════════════════════════════════════════
//  TAB MOMENTOS — Timeline cronológica del evento
// ══════════════════════════════════════════════════════════════

class EventTabMomentos extends StatelessWidget {
  final EventDetail detail;
  const EventTabMomentos({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final moments = detail.moments;

    if (moments.isEmpty) {
      return const Center(
        child: EvEmpty(message: 'Sin momentos registrados'),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EvTabHeader(
            icon: Icons.timeline,
            title: 'MOMENTOS',
            subtitle: '${moments.length} momento${moments.length == 1 ? '' : 's'} clave',
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              children: moments.asMap().entries.map((entry) {
                final isLast = entry.key == moments.length - 1;
                return _MomentRow(
                  moment: entry.value,
                  isLast: isLast,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FILA DE MOMENTO — layout: [tiempo] [conector] [contenido]
// ══════════════════════════════════════════════════════════════

class _MomentRow extends StatelessWidget {
  final EventMoment moment;
  final bool isLast;

  const _MomentRow({required this.moment, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Columna izquierda: etiqueta de tiempo ──────────
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _TimeLabel(label: moment.timeLabel),
            ),
          ),

          const SizedBox(width: 8),

          // ── Columna central: línea + círculo ───────────────
          SizedBox(
            width: 36,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Línea vertical (ocupa toda la altura menos el círculo)
                if (!isLast)
                  Positioned(
                    top: 44,
                    bottom: 0,
                    left: 17,
                    child: Container(width: 2, color: kEvBorderL),
                  ),

                // Círculo con icono/emoji
                _MomentDot(icon: moment.icon),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Columna derecha: título + descripción ──────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 6),
              child: _MomentContent(moment: moment),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Etiqueta de tiempo (minuto o fecha) ──────────────────────
class _TimeLabel extends StatelessWidget {
  final String label;
  const _TimeLabel({required this.label});

  // true si parece un minuto (termina en ' o es solo dígitos)
  bool get _isMinute => label.endsWith("'") || RegExp(r'^\d+$').hasMatch(label);

  @override
  Widget build(BuildContext context) {
    if (_isMinute) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        decoration: BoxDecoration(
          color: kEvDark,
          border: Border.all(color: kEvBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x445B4FD8),
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: evMono(
              size: 11,
              weight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Fecha de evento histórico: texto más compacto
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: evMono(size: 8, color: kEvMuted, weight: FontWeight.w700),
        textAlign: TextAlign.right,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Círculo del momento con icono/emoji ──────────────────────
class _MomentDot extends StatelessWidget {
  final String? icon;
  const _MomentDot({this.icon});

  @override
  Widget build(BuildContext context) {
    final hasEmoji = icon != null && icon!.isNotEmpty;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: kEvAccent,
        shape: BoxShape.circle,
        border: Border.all(color: kEvBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: kEvDark.withOpacity(0.35),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: hasEmoji
            ? Text(
                icon!,
                style: const TextStyle(fontSize: 16),
              )
            : const Icon(Icons.circle, size: 8, color: Colors.white),
      ),
    );
  }
}

// ── Contenido textual del momento ────────────────────────────
class _MomentContent extends StatelessWidget {
  final EventMoment moment;
  const _MomentContent({required this.moment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: kEvCard,
        border: Border.all(color: kEvBorderL, width: 1),
        boxShadow: [
          BoxShadow(
            color: kEvDark.withOpacity(0.2),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            moment.title,
            style: evMono(size: 13, weight: FontWeight.w800),
          ),
          if (moment.description != null &&
              moment.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              moment.description!.trim(),
              style: evMono(size: 11, color: kEvMuted),
            ),
          ],
        ],
      ),
    );
  }
}
