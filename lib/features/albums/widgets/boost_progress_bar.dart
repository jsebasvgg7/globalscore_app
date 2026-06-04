import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;

// ════════════════════════════════════════════════════════════
//  BOOST PROGRESS BAR
//  React equiv: BoostProgressBar
//  Track de hitos + tarjeta de estado boost
// ════════════════════════════════════════════════════════════
class BoostProgressBar extends StatelessWidget {
  final bool boostActive;
  final int boostPacksRemaining;
  final int totalPacksOpened;

  const BoostProgressBar({
    super.key,
    required this.boostActive,
    required this.boostPacksRemaining,
    required this.totalPacksOpened,
  });

  static const _packsPerBoost = 10;

  static const _milestones = [
    (0, 'Inicio', ''),
    (10, '10', 'Premium'),
    (20, '20', 'Épico'),
    (30, '30', 'Élite'),
    (40, 'TOP', 'Especial'),
  ];

  @override
  Widget build(BuildContext context) {
    final packsThisCycle = totalPacksOpened % _packsPerBoost;
    final trackPct = boostActive
        ? 1.0
        : (packsThisCycle / _packsPerBoost).clamp(0.0, 1.0);

    final remaining = boostActive
        ? boostPacksRemaining
        : _packsPerBoost - packsThisCycle;

    return Container(
      color: GsColors.cream,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROGRESO DE SOBRES',
            style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w900,
              letterSpacing: 2, color: GsColors.muted,
            ),
          ),
          const SizedBox(height: 20),

          // ── Track con hitos ───────────────────────────
          _MilestonesTrack(
            packsOpened: totalPacksOpened,
            trackPct: trackPct,
            milestones: _milestones,
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8E0D0)),
          const SizedBox(height: 16),

          // ── Boost status row ──────────────────────────
          _BoostStatusRow(
            boostActive: boostActive,
            remaining: remaining,
          ),
        ],
      ),
    );
  }
}

// ── Track de hitos ────────────────────────────────────────
class _MilestonesTrack extends StatelessWidget {
  final int packsOpened;
  final double trackPct;
  final List<(int, String, String)> milestones;

  const _MilestonesTrack({
    required this.packsOpened,
    required this.trackPct,
    required this.milestones,
  });

  double _segmentFill(int i) {
    if (i >= milestones.length - 1) return 0;
    final start = milestones[i].$1;
    final end = milestones[i + 1].$1;
    if (end == 0) return 0;
    if (packsOpened <= start) return 0;
    if (packsOpened >= end) return 1;
    return (packsOpened - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Círculos + líneas
        Row(
          children: [
            for (int i = 0; i < milestones.length; i++) ...[
              _MilestoneNode(
                value: milestones[i].$1,
                reached: packsOpened >= milestones[i].$1,
              ),
              if (i < milestones.length - 1)
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _segmentFill(i)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 3,
                          color: GsColors.border.withValues(alpha: 0.12),
                        ),
                        FractionallySizedBox(
                          widthFactor: v,
                          child: Container(height: 3, color: GsColors.accent),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        // Labels
        Row(
          children: [
            for (int i = 0; i < milestones.length; i++) ...[
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    Text(
                      milestones[i].$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: GsColors.fontMono,
                        fontSize: 8,
                        fontWeight: packsOpened >= milestones[i].$1
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: packsOpened >= milestones[i].$1
                            ? GsColors.accent
                            : GsColors.muted,
                      ),
                    ),
                    if (milestones[i].$3.isNotEmpty)
                      Text(
                        milestones[i].$3,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 7, color: GsColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (i < milestones.length - 1) const Expanded(child: SizedBox()),
            ],
          ],
        ),
      ],
    );
  }
}

class _MilestoneNode extends StatelessWidget {
  final int value;
  final bool reached;
  const _MilestoneNode({required this.value, required this.reached});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: reached ? GsColors.accent : GsColors.cream,
        border: Border.all(
          color: reached
              ? GsColors.accent
              : GsColors.border.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: reached
            ? const [BoxShadow(color: GsColors.shadow, offset: Offset(2, 2))]
            : null,
      ),
      alignment: Alignment.center,
      child: reached
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text(
              '$value',
              style: TextStyle(
                fontFamily: GsColors.fontMono,
                fontSize: 10, fontWeight: FontWeight.w900,
                color: GsColors.border.withValues(alpha: 0.3),
              ),
            ),
    );
  }
}

// ── Fila estado boost ─────────────────────────────────────
class _BoostStatusRow extends StatelessWidget {
  final bool boostActive;
  final int remaining;
  const _BoostStatusRow({required this.boostActive, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icono boost
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: boostActive
                ? GsColors.gold
                : GsColors.card,
            border: Border.all(color: GsColors.border, width: 1),
            boxShadow: boostActive
                ? const [BoxShadow(color: GsColors.shadow, offset: Offset(1, 1))]
                : null,
          ),
          child: Icon(
            boostActive ? Icons.bolt : Icons.bolt_outlined,
            size: 18,
            color: boostActive ? GsColors.border : GsColors.muted,
          ),
        ),
        const SizedBox(width: 12),
        // Textos
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                boostActive ? 'BOOST ACTIVO' : 'PRÓXIMO BOOST',
                style: const TextStyle(
                  fontFamily: GsColors.fontMono,
                  fontSize: 10, fontWeight: FontWeight.w900,
                  letterSpacing: 0.5, color: GsColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                boostActive
                    ? '+25% probabilidades'
                    : 'cada 10 sobres',
                style: const TextStyle(fontSize: 10, color: GsColors.muted),
              ),
            ],
          ),
        ),
        // Número grande
        Text(
          '$remaining',
          style: TextStyle(
            fontFamily: GsColors.fontMono,
            fontSize: 32, fontWeight: FontWeight.w900,
            height: 1,
            color: boostActive ? GsColors.gold : GsColors.accent,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          boostActive ? '/ 5\nsobres' : 'sobres\nrestan.',
          style: const TextStyle(
            fontSize: 9, color: GsColors.muted, height: 1.4,
          ),
        ),
      ],
    );
  }
}
