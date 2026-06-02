import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/ranking_service.dart';
import 'rank_avatar.dart';

// ── Paleta Neobrutalismo ───────────────────────────────────────────────────────
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFEAE7E1);
const _border  = Color(0xFF1A1A2E);
const _accent  = Color(0xFF5B4FD8);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF6B6580);
const _green   = Color(0xFF1D9E75);
const _gold    = Color(0xFFC9A227);
const _silver  = Color(0xFF8A8A8A);
const _bronze  = Color(0xFFA0652A);

const _shadowColor = Color(0xFF1A1A2E);
const _shadow   = BoxShadow(color: _shadowColor, offset: Offset(3, 3), blurRadius: 0);
const _shadowSm = BoxShadow(color: _shadowColor, offset: Offset(2, 2), blurRadius: 0);
const _shadowLg = BoxShadow(color: _shadowColor, offset: Offset(5, 5), blurRadius: 0);

TextStyle _mono({
  Color color = _text,
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

    // Orden visual: plata(1) | oro(0) | bronce(2)
    final items = [
      if (top3.length > 1) _PodiumItem(user: top3[1], rank: 1),
      _PodiumItem(user: top3[0], rank: 0),
      if (top3.length > 2) _PodiumItem(user: top3[2], rank: 2),
    ];

    const colors      = [_gold,   _silver, _bronze];
    const posBgColors = [_gold,   _silver, _bronze];
    const labels      = ['ORO',   'PLATA', 'BRONCE'];
    const stepHeights = [80.0,    52.0,    36.0];
    const avatarSizes = [66.0,    50.0,    44.0];

    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 2)),
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header "PODIO" — estilo neobrutalista ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(width: 4, height: 18, color: _gold),
                const SizedBox(width: 8),
                const Icon(Icons.emoji_events_rounded, size: 12, color: _gold),
                const SizedBox(width: 6),
                Text(
                  'PODIO',
                  style: _mono(size: 10, weight: FontWeight.w800, letterSpacing: 2.0, color: _text),
                ),
                const SizedBox(width: 10),
                Expanded(child: Container(height: 2, color: _border)),
                const SizedBox(width: 8),
                // Badge de ranking type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent,
                    boxShadow: const [_shadowSm],
                  ),
                  child: Text(
                    rankingType == 'monthly' ? 'MENSUAL' : 'GLOBAL',
                    style: _mono(color: Colors.white, size: 7, weight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Escenario del podio ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: items.map((item) {
              final color     = colors[item.rank];
              final posColor  = posBgColors[item.rank];
              final label     = labels[item.rank];
              final stepH     = stepHeights[item.rank];
              final avatarSz  = avatarSizes[item.rank];
              final isGold    = item.rank == 0;
              final pts       = item.user.rankPoints(rankingType);
              final acc       = item.user.accuracy(rankingType);

              return GestureDetector(
                onTap: () => onSelectUser?.call(item.user.id),
                child: SizedBox(
                  width: 116,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // ── Etiqueta de medalla — caja sólida neobrutalista ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(color: _border, width: isGold ? 2 : 1.5),
                          boxShadow: const [_shadowSm],
                        ),
                        child: Text(
                          label,
                          style: _mono(size: 8, weight: FontWeight.w900, letterSpacing: 1.8, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Avatar + número de posición ──
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: _border, width: isGold ? 3 : 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _shadowColor,
                                  offset: Offset(isGold ? 4 : 3, isGold ? 4 : 3),
                                  blurRadius: 0,
                                )
                              ],
                            ),
                            child: RankAvatar(
                              url: item.user.avatarUrl,
                              name: item.user.name,
                              size: avatarSz,
                              borderColor: color,
                              borderWidth: 0,
                            ),
                          ),
                          // Badge de posición — caja cuadrada sólida (igual que PodiumPanel del dashboard)
                          Positioned(
                            bottom: -8,
                            right: -6,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: posColor,
                                border: Border.all(color: _border, width: 2),
                                boxShadow: const [_shadowSm],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${item.rank + 1}',
                                style: _mono(color: Colors.white, size: 11, weight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Nombre ──
                      Text(
                        item.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: _mono(size: 11, weight: FontWeight.w800, color: _text),
                      ),
                      const SizedBox(height: 3),

                      // ── Puntos — valor grande con color de medalla ──
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _fmt(pts),
                              style: _mono(
                                size: isGold ? 20 : 16,
                                weight: FontWeight.w900,
                                color: color,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: ' pts',
                              style: _mono(size: 8, color: _muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),

                      // ── Precisión — pill verde ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.12),
                          border: Border.all(color: _green, width: 1.5),
                        ),
                        child: Text(
                          '$acc%',
                          style: _mono(size: 9, weight: FontWeight.w800, color: _green),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Escalón del podio — borde superior de color ──
                      Container(
                        height: stepH,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          border: Border(
                            top:   BorderSide(color: color, width: 2),
                            left:  BorderSide(color: _border.withOpacity(0.3), width: 1),
                            right: BorderSide(color: _border.withOpacity(0.3), width: 1),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: isGold
                            ? Icon(Icons.emoji_events_rounded, size: 20, color: color.withOpacity(0.3))
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

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