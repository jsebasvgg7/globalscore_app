import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/ranking_service.dart';
import 'rank_avatar.dart';

// ── Paleta Neobrutalismo ───────────────────────────────────────────────────────
const _bg      = Color(0xFFF0EDE8);
const _border  = Color(0xFF1A1A2E);
const _accent  = Color(0xFF5B4FD8);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF6B6580);
const _green   = Color(0xFF1D9E75);
const _gold    = Color(0xFFC9A227);
const _silver  = Color(0xFF8A8A8A);
const _bronze  = Color(0xFFA0652A);

const _shadowColor = Color(0xFF1A1A2E);
const _shadowSm = BoxShadow(color: _shadowColor, offset: Offset(2, 2), blurRadius: 0);

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

class RankingTableRow extends StatelessWidget {
  final RankingUser user;
  final int pos;
  final bool isMe;
  final String rankingType;
  final void Function(String userId)? onTap;

  const RankingTableRow({
    super.key,
    required this.user,
    required this.pos,
    required this.isMe,
    required this.rankingType,
    this.onTap,
  });

  Color get _medalColor => pos == 1
      ? _gold
      : pos == 2
          ? _silver
          : pos == 3
              ? _bronze
              : _muted;

  bool get _isTop3 => pos <= 3;

  @override
  Widget build(BuildContext context) {
    final pts     = user.rankPoints(rankingType);
    final correct = user.rankCorrect(rankingType);
    final acc     = user.accuracy(rankingType);
    final color   = _medalColor;

    return GestureDetector(
      onTap: () => onTap?.call(user.id),
      child: Container(
        decoration: BoxDecoration(
          color: isMe ? _accent.withOpacity(0.05) : _bg,
          border: Border(
            bottom: BorderSide(color: _border.withOpacity(0.4), width: 0.5),
            // Barra lateral de color para top3 — igual que LeagueRow del dashboard
            left: _isTop3
                ? BorderSide(color: color, width: 3)
                : BorderSide(color: _border.withOpacity(0.1), width: 1),
          ),
        ),
        padding: EdgeInsets.only(
          left: _isTop3 ? 13 : 16,
          right: 16,
          top: 12,
          bottom: 12,
        ),
        child: Row(
          children: [
            // ── Número de posición ──
            SizedBox(
              width: 32,
              child: _isTop3
                  // Caja sólida neobrutalista para top3
                  ? Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(color: _border, width: 2),
                        boxShadow: const [_shadowSm],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$pos',
                        style: _mono(color: Colors.white, size: 11, weight: FontWeight.w900),
                      ),
                    )
                  : Text(
                      '$pos',
                      style: _mono(
                        size: 14,
                        weight: FontWeight.w800,
                        color: _border.withOpacity(0.2),
                      ),
                    ),
            ),
            const SizedBox(width: 10),

            // ── Avatar ──
            RankAvatar(url: user.avatarUrl, name: user.name, size: 38),
            const SizedBox(width: 10),

            // ── Nombre + aciertos ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _mono(
                            size: 13,
                            weight: FontWeight.w700,
                            color: _text,
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        // Pill "TÚ" sólida — igual al dashboard
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accent,
                            border: Border.all(color: _border, width: 1.5),
                            boxShadow: const [_shadowSm],
                          ),
                          child: Text(
                            'TÚ',
                            style: _mono(
                              color: Colors.white,
                              size: 7,
                              weight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(width: 6, height: 2, color: _green),
                      const SizedBox(width: 4),
                      Text(
                        '$correct aciertos',
                        style: _mono(size: 9, color: _muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── Puntos + precisión ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _fmt(pts),
                      style: _mono(
                        size: 18,
                        weight: FontWeight.w900,
                        color: _isTop3 ? color : _text,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'pts',
                      style: _mono(size: 8, weight: FontWeight.w600, color: _muted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Precisión — tag compacta
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.1),
                    border: Border.all(color: _green, width: 1),
                  ),
                  child: Text(
                    '$acc%',
                    style: _mono(size: 9, weight: FontWeight.w800, color: _green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(int n) {
  if (n >= 1000) {
    final k = n ~/ 1000;
    final r = n % 1000;
    return '$k.${r.toString().padLeft(3, '0')}';
  }
  return '$n';
}
