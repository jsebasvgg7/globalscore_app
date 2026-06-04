import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show Ds;

// ════════════════════════════════════════════════════════════
//  BOOST PROGRESS BAR
//  Boceto: fondo blanco, título muted small caps,
//  nodos cuadrados pequeños morados con check blanco,
//  línea delgada entre nodos, labels debajo en 2 líneas,
//  fila boost: icono cuadrado amarillo + texto + número grande
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

  static const _perBoost = 10;

  // Exactamente como el boceto
  static const _milestones = [
    _Milestone(threshold: 0,  top: 'Inicio',   bottom: ''),
    _Milestone(threshold: 10, top: '10',        bottom: 'Tu Premio'),
    _Milestone(threshold: 20, top: '20',        bottom: 'Épico'),
    _Milestone(threshold: 30, top: '30',        bottom: 'Élite'),
    _Milestone(threshold: 40, top: 'TOP',       bottom: 'Especial'),
  ];

  @override
  Widget build(BuildContext context) {
    final cycle     = totalPacksOpened % _perBoost;
    final remaining = boostActive
        ? boostPacksRemaining
        : _perBoost - cycle;

    return Container(
      color: Ds.bg,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título ───────────────────────────────────
          const Text(
            'PROGRESO DE SOBRES',
            style: TextStyle(
              fontFamily: Ds.font,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Ds.muted,
            ),
          ),
          const SizedBox(height: 18),

          // ── Track ────────────────────────────────────
          _Track(
            packsOpened: totalPacksOpened,
            milestones: _milestones,
          ),

          const SizedBox(height: 18),
          Container(height: 1, color: Ds.border),
          const SizedBox(height: 14),

          // ── Estado boost ─────────────────────────────
          _BoostRow(
            boostActive: boostActive,
            remaining: remaining,
          ),
        ],
      ),
    );
  }
}

// ── Milestone data ────────────────────────────────────────
class _Milestone {
  final int threshold;
  final String top, bottom;
  const _Milestone({
    required this.threshold,
    required this.top,
    required this.bottom,
  });
}

// ── Track completo ────────────────────────────────────────
class _Track extends StatelessWidget {
  final int packsOpened;
  final List<_Milestone> milestones;

  const _Track({required this.packsOpened, required this.milestones});

  double _fill(int i) {
    if (i >= milestones.length - 1) return 0;
    final s = milestones[i].threshold;
    final e = milestones[i + 1].threshold;
    if (e == 0 || packsOpened <= s) return 0;
    if (packsOpened >= e) return 1;
    return (packsOpened - s) / (e - s);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Fila nodos + conectores
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < milestones.length; i++) ...[
              _Node(reached: packsOpened >= milestones[i].threshold),
              if (i < milestones.length - 1)
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: _fill(i)),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(height: 2, color: Ds.border),
                        FractionallySizedBox(
                          widthFactor: v,
                          child: Container(height: 2, color: Ds.accent),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Fila labels — alineados bajo cada nodo
        Row(
          children: [
            for (int i = 0; i < milestones.length; i++) ...[
              SizedBox(
                width: 38,
                child: Column(
                  children: [
                    Text(
                      milestones[i].top,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: Ds.font,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: packsOpened >= milestones[i].threshold
                            ? Ds.accent
                            : Ds.muted,
                      ),
                    ),
                    if (milestones[i].bottom.isNotEmpty)
                      Text(
                        milestones[i].bottom,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: Ds.font,
                          fontSize: 7,
                          color: Ds.muted,
                          height: 1.2,
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

// ── Nodo cuadrado — boceto: morado sólido con ✓ blanco ───
class _Node extends StatelessWidget {
  final bool reached;
  const _Node({required this.reached});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      color: reached ? Ds.accent : Ds.bg,
      foregroundDecoration: BoxDecoration(
        border: Border.all(
          color: reached ? Ds.accent : Ds.border,
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: reached
          ? const Icon(Icons.check, size: 20, color: Colors.white)
          : null,
    );
  }
}

// ── Fila estado boost ─────────────────────────────────────
// Boceto: cuadrado amarillo con rayo | "BOOST ACTIVO / +25%" | "3 / 5 sobres"
class _BoostRow extends StatelessWidget {
  final bool boostActive;
  final int remaining;

  const _BoostRow({required this.boostActive, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icono cuadrado
        Container(
          width: 38, height: 38,
          color: boostActive ? Ds.gold : Ds.bgCard,
          foregroundDecoration: BoxDecoration(
            border: Border.all(color: Ds.border, width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(
            boostActive ? Icons.bolt : Icons.bolt_outlined,
            size: 22,
            color: boostActive ? Ds.ink : Ds.muted,
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
                  fontFamily: Ds.font,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: Ds.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                boostActive ? '+25% probabilidades' : 'cada 10 sobres',
                style: const TextStyle(
                  fontFamily: Ds.font,
                  fontSize: 10,
                  color: Ds.muted,
                ),
              ),
            ],
          ),
        ),

        // Número grande + label
        // Boceto: número 3 muy grande dorado/morado, "/ 5 sobres" pequeño
        RichText(
          textAlign: TextAlign.right,
          text: TextSpan(
            children: [
              TextSpan(
                text: '$remaining',
                style: TextStyle(
                  fontFamily: Ds.font,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  color: boostActive ? Ds.gold : Ds.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          boostActive ? '/ 5\nsobres' : 'sobres\nrestantes',
          style: const TextStyle(
            fontFamily: Ds.font,
            fontSize: 9,
            color: Ds.muted,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}