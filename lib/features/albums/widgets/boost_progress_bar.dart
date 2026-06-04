import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show Ds;

// ════════════════════════════════════════════════════════════
//  BOOST PROGRESS BAR — v2 neobrutalista con relieve real
//
//  Sección completa tiene:
//   • Contenedor con borde 2px + sombra offset 4,4
//   • Título con franja de acento izquierda
//   • Track: nodos cuadrados con relieve + líneas embutidas
//   • Boost row: cuadrado de icono con sombra + texto + número
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

  static const _milestones = [
    _MS(thr: 0,  top: 'Inicio',    bot: ''),
    _MS(thr: 10, top: '10',        bot: 'Tu Premio'),
    _MS(thr: 20, top: '20',        bot: 'Épico'),
    _MS(thr: 30, top: '30',        bot: 'Élite'),
    _MS(thr: 40, top: 'TOP',       bot: 'Especial'),
  ];

  @override
  Widget build(BuildContext context) {
    final cycle = totalPacksOpened % _perBoost;
    final remaining = boostActive
        ? boostPacksRemaining
        : _perBoost - cycle;

    return Container(
      decoration: const BoxDecoration(
        color: Ds.bg,
        border: Border.fromBorderSide(BorderSide(color: Ds.border, width: 2)),
        boxShadow: [
          BoxShadow(color: Ds.shadow3d, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header con franja acento ───────────────
          _SectionHeader(label: 'PROGRESO DE SOBRES'),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
            child: _Track(
              packsOpened: totalPacksOpened,
              milestones: _milestones,
            ),
          ),

          const SizedBox(height: 16),
          Container(height: 1.5, color: Ds.border),

          // ── Boost row ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: _BoostRow(boostActive: boostActive, remaining: remaining),
          ),
        ],
      ),
    );
  }
}

// ── Section header con franja izquierda ──────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Ds.border, width: 1.5)),
      ),
      child: Row(
        children: [
          // Franja de acento izquierda
          Container(width: 5, height: 38, color: Ds.accent),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: Ds.font,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Ds.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Milestone data ────────────────────────────────────────
class _MS {
  final int thr;
  final String top, bot;
  const _MS({required this.thr, required this.top, required this.bot});
}

// ── Track con nodos y líneas ──────────────────────────────
class _Track extends StatelessWidget {
  final int packsOpened;
  final List<_MS> milestones;

  const _Track({required this.packsOpened, required this.milestones});

  double _fill(int i) {
    if (i >= milestones.length - 1) return 0;
    final s = milestones[i].thr;
    final e = milestones[i + 1].thr;
    if (e == 0 || packsOpened <= s) return 0;
    if (packsOpened >= e) return 1;
    return (packsOpened - s) / (e - s);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Fila nodos + conectores embutidos
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < milestones.length; i++) ...[
              _Node3D(reached: packsOpened >= milestones[i].thr),
              if (i < milestones.length - 1)
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: _fill(i)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => _ConnectorLine(fill: v),
                  ),
                ),
            ],
          ],
        ),

        const SizedBox(height: 10),

        // Labels — alineados bajo nodos
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
                        color: packsOpened >= milestones[i].thr
                            ? Ds.accent
                            : Ds.muted,
                      ),
                    ),
                    if (milestones[i].bot.isNotEmpty)
                      Text(
                        milestones[i].bot,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: Ds.font,
                          fontSize: 6.5,
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

// ── Nodo 3D cuadrado con relieve ──────────────────────────
class _Node3D extends StatelessWidget {
  final bool reached;
  const _Node3D({required this.reached});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: reached ? Ds.accent : Ds.bgCard,
        // Relieve: si activo sombra interior, si inactivo elevado
        border: Border(
          top: BorderSide(
            color: reached
                ? Ds.accent.withValues(alpha: 0.5)
                : const Color(0xFFFFFFFF),
            width: 1.5,
          ),
          left: BorderSide(
            color: reached
                ? Ds.accent.withValues(alpha: 0.5)
                : const Color(0xFFFFFFFF),
            width: 1.5,
          ),
          bottom: BorderSide(color: Ds.border, width: reached ? 2 : 1),
          right: BorderSide(color: Ds.border, width: reached ? 2 : 1),
        ),
        boxShadow: reached
            ? const [
                BoxShadow(
                  color: Ds.shadow3d, offset: Offset(2, 2), blurRadius: 0),
              ]
            : const [
                BoxShadow(
                  color: Color(0x22000000), offset: Offset(1, 1), blurRadius: 0),
              ],
      ),
      alignment: Alignment.center,
      child: reached
          ? const Icon(Icons.check, size: 20, color: Colors.white)
          : null,
    );
  }
}

// ── Línea conectora embutida ──────────────────────────────
class _ConnectorLine extends StatelessWidget {
  final double fill;
  const _ConnectorLine({required this.fill});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(
        color: Ds.bgCard,
        border: Border(
          top: BorderSide(color: Color(0xFF888070), width: 1),
          bottom: BorderSide(color: Color(0xFFFFFFFF), width: 1),
        ),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fill,
        child: Container(color: Ds.accent),
      ),
    );
  }
}

// ── Boost row con relieve ─────────────────────────────────
class _BoostRow extends StatelessWidget {
  final bool boostActive;
  final int remaining;

  const _BoostRow({required this.boostActive, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icono cuadrado con sombra 3D
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: boostActive ? Ds.gold : Ds.bgCard,
            border: const Border.fromBorderSide(
              BorderSide(color: Ds.border, width: 1.5),
            ),
            boxShadow: const [
              BoxShadow(
                color: Ds.shadow3d, offset: Offset(3, 3), blurRadius: 0),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            boostActive ? Icons.bolt : Icons.bolt_outlined,
            size: 24,
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
                  fontFamily: Ds.font, fontSize: 12,
                  fontWeight: FontWeight.w900, letterSpacing: 0.3, color: Ds.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                boostActive ? '+25% probabilidades' : 'cada 10 sobres',
                style: const TextStyle(
                  fontFamily: Ds.font, fontSize: 10, color: Ds.muted,
                ),
              ),
            ],
          ),
        ),

        // Número grande con relieve
        _BigNumber(value: '$remaining', boostActive: boostActive),
        const SizedBox(width: 6),
        Text(
          boostActive ? '/ 5\nsobres' : 'sobres\nrestantes',
          style: const TextStyle(
            fontFamily: Ds.font, fontSize: 8.5, color: Ds.muted, height: 1.3),
        ),
      ],
    );
  }
}

// ── Número grande con borde ───────────────────────────────
class _BigNumber extends StatelessWidget {
  final String value;
  final bool boostActive;
  const _BigNumber({required this.value, required this.boostActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: boostActive ? Ds.gold : Ds.accent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (boostActive ? Ds.gold : Ds.accent).withValues(alpha: 0.2),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        value,
        style: TextStyle(
          fontFamily: Ds.font, fontSize: 38,
          fontWeight: FontWeight.w900, height: 1,
          color: boostActive ? Ds.gold : Ds.accent,
        ),
      ),
    );
  }
}