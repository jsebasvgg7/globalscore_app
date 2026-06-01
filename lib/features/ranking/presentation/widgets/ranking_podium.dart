import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/ranking_service.dart';
import 'rank_avatar.dart';

// ── Tipografía ────────────────────────────────────────────────────────────
TextStyle _mono({
  Color color = const Color(0xFF1A1A2E),
  double size = 12,
  FontWeight weight = FontWeight.normal,
  double letterSpacing = 0,
}) =>
    GoogleFonts.dmMono(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        decoration: TextDecoration.none);

const _kGold = Color(0xFFC9A227);
const _kSilver = Color(0xFF8A8A8A);
const _kBronze = Color(0xFFA0652A);

class RankingPodium extends StatelessWidget {
  final List<RankingUser> top3;
  final String rankingType;
  final void Function(String userId)? onSelectUser;

  const RankingPodium({
    super.key,
    required this.top3,
    required this.rankingType,
    this.onSelectUser,
  });

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();

    // Order: silver(1) | gold(0) | bronze(2)
    final items = [
      if (top3.length > 1) _PodiumItem(user: top3[1], rank: 1),
      _PodiumItem(user: top3[0], rank: 0),
      if (top3.length > 2) _PodiumItem(user: top3[2], rank: 2),
    ];

    const colors = [_kGold, _kSilver, _kBronze];
    const labels = ['ORO', 'PLATA', 'BRONCE'];
    // Alturas del bloque base (escalón): oro=80, plata=52, bronce=36
    const stepHeights = [80.0, 52.0, 36.0];

    return Container(
      color: _kBg,
      padding: const EdgeInsets.only(top: 20, bottom: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Crown + title ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 40,
                  height: 0.5,
                  color: Colors.black.withOpacity(0.12)),
              const SizedBox(width: 8),
              const Icon(Icons.emoji_events_rounded, size: 14, color: _kGold),
              const SizedBox(width: 6),
              Text(
                'PODIO',
                style: _mono(size: 10, weight: FontWeight.w700, letterSpacing: 1.8, color: const Color(0xFF888880)),
              ),
              const SizedBox(width: 8),
              Container(
                  width: 40,
                  height: 0.5,
                  color: Colors.black.withOpacity(0.12)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Podio stage — Row alineado al bottom ──
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: items.map((item) {
                final color = colors[item.rank];
                final label = labels[item.rank];
                final isGold = item.rank == 0;
                final stepH = stepHeights[item.rank];
                final pts = item.user.rankPoints(rankingType);
                final acc = item.user.accuracy(rankingType);
                final avatarSize = isGold ? 66.0 : 50.0;

                return GestureDetector(
                  onTap: () => onSelectUser?.call(item.user.id),
                  child: SizedBox(
                    width: 112,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Medal label
                        Text(
                          label,
                          style: _mono(size: 9, weight: FontWeight.w700, letterSpacing: 1.4, color: color),
                        ),
                        const SizedBox(height: 8),

                        // Avatar + rank badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            RankAvatar(
                              url: item.user.avatarUrl,
                              name: item.user.name,
                              size: avatarSize,
                              borderColor: color,
                              borderWidth: isGold ? 3.0 : 2.0,
                            ),
                            Positioned(
                              bottom: -6,
                              right: -2,
                              child: Container(
                                width: 20,
                                height: 20,
                                color: color,
                                alignment: Alignment.center,
                                child: Text(
                                  '${item.rank + 1}',
                                  style: _mono(color: Colors.white, size: 10, weight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Name
                        Text(
                          item.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: _mono(size: 12, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),

                        // Points
                        Text(
                          '${_fmt(pts)} pts',
                         style: _mono(size: isGold ? 14 : 12, weight: FontWeight.w800, color: color),
                        ),
                        const SizedBox(height: 2),

                        // Accuracy
                        Text(
                          '$acc%',
                         style: _mono(size: 10, weight: FontWeight.w600, color: const Color(0xFF1D9E75)),
                        ),
                        const SizedBox(height: 8),

                        // ── Step block — altura fija, NO desborda ──
                        Container(
                          height: stepH,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.10),
                            border: Border(
                              top: BorderSide(color: color, width: 2),
                              left: BorderSide(
                                  color: color.withOpacity(0.25), width: 1),
                              right: BorderSide(
                                  color: color.withOpacity(0.25), width: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: constant_identifier_names
const _kBg = Color(0xFFF0EDE8);

class _PodiumItem {
  final RankingUser user;
  final int rank;
  const _PodiumItem({required this.user, required this.rank});
}

String _fmt(int n) {
  if (n >= 1000) {
    final k = n ~/ 1000;
    final r = n % 1000;
    return '$k.${r.toString().padLeft(3, '0')}';
  }
  return '$n';
}