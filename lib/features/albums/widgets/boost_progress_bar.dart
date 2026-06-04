import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show Ds;

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

  @override
  Widget build(BuildContext context) {
    final cycle = totalPacksOpened % _perBoost;

    final remaining = boostActive
        ? boostPacksRemaining
        : (_perBoost - cycle);

    return Container(
      decoration: const BoxDecoration(
        color: Ds.bg,
        border: Border.fromBorderSide(
          BorderSide(
            color: Ds.border,
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PROGRESO DE SOBRES',
              style: TextStyle(
                fontFamily: Ds.font,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Ds.accent,
              ),
            ),

            const SizedBox(height: 6),

            _MilestoneTrack(
              totalPacksOpened: totalPacksOpened,
            ),

            const SizedBox(height: 6),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EEF8),
                border: Border.all(
                  color: Ds.border,
                  width: 2,
                ),
              ),
              child: _BoostContent(
                boostActive: boostActive,
                remaining: remaining,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneTrack extends StatelessWidget {
  final int totalPacksOpened;

  const _MilestoneTrack({
    required this.totalPacksOpened,
  });

  static const milestones = [0, 10, 20, 30, 40];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < milestones.length; i++) ...[
              _Node(
                active: totalPacksOpened >= milestones[i],
              ),
              if (i < milestones.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    color: totalPacksOpened > milestones[i]
                        ? Ds.accent
                        : Ds.borderSub,
                  ),
                ),
            ],
          ],
        ),

        const SizedBox(height: 4),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _MilestoneLabel(
              top: '',
              bottom: 'Inicio',
            ),
            _MilestoneLabel(
              top: '10',
              bottom: 'Tu\nPremio',
            ),
            _MilestoneLabel(
              top: '20',
              bottom: 'Épico',
            ),
            _MilestoneLabel(
              top: '30',
              bottom: 'Élite',
            ),
            _MilestoneLabel(
              top: 'TOP',
              bottom: 'Especial',
            ),
          ],
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  final bool active;

  const _Node({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Ds.accent : Ds.bg,
        border: Border.all(
          color: active ? Ds.accent : Ds.borderSub,
          width: 2,
        ),
      ),
      child: active
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            )
          : null,
    );
  }
}

class _MilestoneLabel extends StatelessWidget {
  final String top;
  final String bottom;

  const _MilestoneLabel({
    required this.top,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          if (top.isNotEmpty)
            Text(
              top,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: Ds.font,
                fontWeight: FontWeight.w900,
                fontSize: 9,
                color: Ds.ink,
              ),
            ),
          Text(
            bottom,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: Ds.font,
              fontSize: 7,
              color: Ds.ink,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostContent extends StatelessWidget {
  final bool boostActive;
  final int remaining;

  const _BoostContent({
    required this.boostActive,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                boostActive
                    ? 'BOOST ACTIVO'
                    : 'PRÓXIMO BOOST',
                style: const TextStyle(
                  fontFamily: Ds.font,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Ds.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                boostActive
                    ? '+25% probabilidades'
                    : 'cada 10 sobres',
                style: const TextStyle(
                  fontFamily: Ds.font,
                  fontSize: 8,
                  color: Ds.muted,
                ),
              ),
            ],
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$remaining',
              style: TextStyle(
                fontFamily: Ds.font,
                fontWeight: FontWeight.w900,
                fontSize: 34,
                height: 0.9,
                color: boostActive
                    ? Ds.gold
                    : Ds.accent,
              ),
            ),
            Text(
              boostActive
                  ? '/5 sobres'
                  : 'sobres restantes',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: Ds.font,
                fontSize: 7,
                color: Ds.muted,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
