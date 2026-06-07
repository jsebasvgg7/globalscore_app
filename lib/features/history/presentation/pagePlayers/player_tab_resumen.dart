import 'package:flutter/material.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';
import 'history_players_shared.dart';

class PlayerTabResumen extends StatelessWidget {
  final PlayerDetail detail;
  const PlayerTabResumen({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final p = detail.player;
    final sig = p.significanceLevel ?? 0;
    final isGoat = sig == 5;
    final isActive = sig == 1;
    final imgUrl = getHistoricalImageUrl(p.imagePath);

    // Stats agregados
    int totalGoals = 0, totalAssists = 0, totalApps = 0;
    for (final c in detail.career) {
      totalGoals += c.goals;
      totalAssists += c.assists;
      totalApps += c.appearances;
    }
    int totalCaps = 0, nationalGoals = 0;
    for (final n in detail.national) {
      totalCaps += n.caps;
      nationalGoals += n.goals;
    }
    int titlesCount = 0;
    for (final t in detail.titles) {
      if (t.titleCategory != 'individual') titlesCount += t.quantity;
    }
    final lifespan = p.birthYear != null
        ? '${p.birthYear}${p.deathYear != null ? ' – ${p.deathYear}' : ' – Presente'}'
        : null;
    final posLabel = positionLabel[p.position] ?? p.position ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero ────────────────────────────────────────────
          _HeroSection(
            player: p,
            imgUrl: imgUrl,
            isGoat: isGoat,
            isActive: isActive,
            sig: sig,
            posLabel: posLabel,
            lifespan: lifespan,
          ),

          // ── Stats grid ──────────────────────────────────────
          _StatsGrid(
            totalGoals: totalGoals,
            totalAssists: totalAssists,
            totalApps: totalApps,
            totalCaps: totalCaps,
            nationalGoals: nationalGoals,
            titlesCount: titlesCount,
            clubsCount: detail.career.length,
          ),

          // ── Trascendencia ────────────────────────────────────
          if (p.impactSummary != null) ...[
            _SectionHeader(label: 'TRASCENDENCIA'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: kHistAccent, width: 4),
                    top: BorderSide(color: kHistBorder, width: 1.5),
                    right: BorderSide(color: kHistBorder, width: 1.5),
                    bottom: BorderSide(color: kHistBorder, width: 1.5),
                  ),
                  color: kHistAccent.withOpacity(0.03),
                  boxShadow: [
                    BoxShadow(
                      color: kHistDark.withOpacity(0.35),
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  p.impactSummary!,
                  style: monoStyle(size: 13, color: kHistDark),
                ),
              ),
            ),
          ],

          // ── Descripción breve ────────────────────────────────
          if (p.description != null) ...[
            _SectionHeader(label: 'DESCRIPCIÓN'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Text(
                p.description!,
                style: monoStyle(size: 12, color: kHistMuted),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Hero section ──────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final HistoricalPlayer player;
  final String? imgUrl;
  final bool isGoat;
  final bool isActive;
  final int sig;
  final String posLabel;
  final String? lifespan;

  const _HeroSection({
    required this.player,
    required this.imgUrl,
    required this.isGoat,
    required this.isActive,
    required this.sig,
    required this.posLabel,
    required this.lifespan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kHistCard,
        border: Border(bottom: BorderSide(color: kHistBorder, width: 1.5)),
      ),
      child: Stack(
        children: [
          // Dot grid decorativo
          const Positioned(
            right: 0,
            top: 0,
            child: DotGrid(cols: 5, rows: 4),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
             crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Foto
                _PlayerPhoto(
                  player: player,
                  imgUrl: imgUrl,
                  isGoat: isGoat,
                  isActive: isActive,
                  ballonDorCount: player.ballonDorCount,
                ),
                const SizedBox(width: 14),

                // Info derecha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge "ARCHIVO HISTÓRICO"
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: kHistAccent, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 8, color: kHistAccent),
                            const SizedBox(width: 3),
                            Text(
                              'ARCHIVO HISTÓRICO',
                              style: monoStyle(
                                size: 7,
                                weight: FontWeight.w700,
                                color: kHistAccent,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Nombre grande
                      Text(
                        player.name.toUpperCase(),
                        style: monoStyle(
                          size: 20,
                          weight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Legacy tag
                      if (player.legacyType != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kHistDark,
                            border: Border.all(color: kHistBorder, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 8,
                                  color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                (legacyLabel[player.legacyType!] ??
                                        player.legacyType!)
                                    .toUpperCase(),
                                style: monoStyle(
                                  size: 8,
                                  weight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.add, size: 8,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Stars
                      if (sig >= 2) ...[
                        Row(
                          children: [
                            PlayerStars(level: sig, size: 11),
                            const SizedBox(width: 6),
                            Text(
                              sig < sigLabel.length
                                  ? sigLabel[sig].toUpperCase()
                                  : '',
                              style: monoStyle(
                                size: 8,
                                color: sig == 5 ? kHistGold : kHistMuted,
                                weight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Chips: pos · país · lifespan
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          if (posLabel.isNotEmpty)
                            PlayerChip(
                              label: posLabel,
                              icon: Icons.sports_soccer_outlined,
                              color: kHistAccent,
                            ),
                          if (player.country != null)
                            PlayerChip(
                              label: player.country!,
                              icon: Icons.public_outlined,
                            ),
                          if (lifespan != null)
                            PlayerChip(
                              label: lifespan!,
                              icon: Icons.access_time_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Foto con overlay GOAT/ACTIVO y balones de oro
class _PlayerPhoto extends StatelessWidget {
  final HistoricalPlayer player;
  final String? imgUrl;
  final bool isGoat;
  final bool isActive;
  final int? ballonDorCount;

  const _PlayerPhoto({
    required this.player,
    required this.imgUrl,
    required this.isGoat,
    required this.isActive,
    required this.ballonDorCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: neoBox(shadowX: 4, shadowY: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: 100,
            height: 120,
            child: imgUrl != null
                ? Image.network(
                    imgUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        CardInitials(name: player.name),
                  )
                : CardInitials(name: player.name),
          ),

          // Overlay bottom: GOAT o ACTIVO
          if (isGoat)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                color: kHistGold,
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  'GOAT',
                  textAlign: TextAlign.center,
                  style: monoStyle(
                    size: 7, weight: FontWeight.w900,
                    letterSpacing: 1.2, color: Colors.black,
                  ),
                ),
              ),
            )
          else if (isActive)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                color: kHistGreen,
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  'EN ACTIVO',
                  textAlign: TextAlign.center,
                  style: monoStyle(
                    size: 7, weight: FontWeight.w900,
                    letterSpacing: 0.8, color: Colors.white,
                  ),
                ),
              ),
            ),

          // Balones de oro — flotando abajo izquierda
          if ((ballonDorCount ?? 0) > 0)
            Positioned(
              bottom: isGoat || isActive ? 20 : 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: kHistDark.withOpacity(0.85),
                  border: Border.all(color: kHistGold, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events,
                        size: 9, color: kHistGold),
                    const SizedBox(width: 2),
                    Text(
                      '${ballonDorCount}',
                      style: monoStyle(
                        size: 8, weight: FontWeight.w900,
                        color: kHistGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stats grid 2x3 ────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final int totalGoals;
  final int totalAssists;
  final int totalApps;
  final int totalCaps;
  final int nationalGoals;
  final int titlesCount;
  final int clubsCount;

  const _StatsGrid({
    required this.totalGoals,
    required this.totalAssists,
    required this.totalApps,
    required this.totalCaps,
    required this.nationalGoals,
    required this.titlesCount,
    required this.clubsCount,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ((totalGoals + nationalGoals) > 0 ? '${totalGoals + nationalGoals}' : '—', 'GOLES'),
      (totalAssists > 0 ? '$totalAssists' : '—', 'ASISTENCIAS'),
      (nationalGoals > 0 ? '$nationalGoals' : '—', "INT'L GOLES"),
      (clubsCount > 0 ? '$clubsCount' : '—', 'CLUBES'),
      (totalCaps > 0 ? '$totalCaps' : '—', "INT'L PARTIDOS"),
      (titlesCount > 0 ? '$titlesCount' : '—', 'TÍTULOS'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: neoBox(shadowX: 4, shadowY: 4),
      child: Column(
        children: [
          // Fila 1
          IntrinsicHeight(
            child: Row(
              children: [
                _StatCell(value: items[0].$1, label: items[0].$2, rightBorder: true),
                _StatCell(value: items[1].$1, label: items[1].$2, rightBorder: true),
                _StatCell(value: items[2].$1, label: items[2].$2, rightBorder: false),
              ],
            ),
          ),
          Container(height: 1.5, color: kHistBorder),
          // Fila 2
          IntrinsicHeight(
            child: Row(
              children: [
                _StatCell(value: items[3].$1, label: items[3].$2, rightBorder: true),
                _StatCell(value: items[4].$1, label: items[4].$2, rightBorder: true),
                _StatCell(value: items[5].$1, label: items[5].$2, rightBorder: false, color: kHistGold),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final bool rightBorder;
  final Color color;

  const _StatCell({
    required this.value,
    required this.label,
    required this.rightBorder,
    this.color = kHistAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          border: rightBorder
              ? Border(right: BorderSide(color: kHistBorder, width: 1.5))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: monoStyle(size: 22, weight: FontWeight.w900, color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: monoStyle(
                size: 7, weight: FontWeight.w700,
                letterSpacing: 0.6, color: kHistMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: kHistAccent),
          const SizedBox(width: 8),
          Text(
            label,
            style: monoStyle(
              size: 9, weight: FontWeight.w700,
              letterSpacing: 1.4, color: kHistMuted,
            ),
          ),
        ],
      ),
    );
  }
}
