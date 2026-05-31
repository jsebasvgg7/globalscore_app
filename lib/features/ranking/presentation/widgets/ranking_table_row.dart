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
        letterSpacing: letterSpacing);

const _kGold   = Color(0xFFC9A227);
const _kSilver = Color(0xFF8A8A8A);
const _kBronze = Color(0xFFA0652A);
const _kAccent = Color(0xFF5B4FD8);

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

  Color get _badgeColor => pos == 1
      ? _kGold
      : pos == 2
          ? _kSilver
          : pos == 3
              ? _kBronze
              : const Color(0xFFB0AAA0);

  @override
  Widget build(BuildContext context) {
    final pts     = user.rankPoints(rankingType);
    final correct = user.rankCorrect(rankingType);
    final acc     = user.accuracy(rankingType);
    final isTop3  = pos <= 3;

    return GestureDetector(
      onTap: () => onTap?.call(user.id),
      child: Container(
        decoration: BoxDecoration(
          color: isMe ? _kAccent.withOpacity(0.06) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
                color: Colors.black.withOpacity(0.06), width: 0.5),
            left: isTop3
                ? BorderSide(color: _badgeColor, width: 3)
                : BorderSide.none,
          ),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            // ── Rank number ──
            SizedBox(
              width: 30,
              child: isTop3
                  ? Container(
                      width: 24,
                      height: 24,
                      color: _badgeColor,
                      alignment: Alignment.center,
                      child: Text(
                        '$pos',
                        style: _mono(
                            color: Colors.white,
                            size: 11,
                            weight: FontWeight.w900),
                      ),
                    )
                  : Text(
                      '$pos',
                      style: _mono(
                          size: 14,
                          weight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.25)),
                    ),
            ),
            const SizedBox(width: 10),

            // ── Avatar ──
            RankAvatar(
                url: user.avatarUrl, name: user.name, size: 38),
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
                              weight: FontWeight.w700),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          color: _kAccent,
                          child: Text(
                            'TÚ',
                            style: _mono(
                                color: Colors.white,
                                size: 8,
                                weight: FontWeight.w800,
                                letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$correct aciertos',
                    style: _mono(
                        size: 10,
                        color: const Color(0xFF888880)),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── Puntos + precisión ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _fmt(pts),
                        style: _mono(
                            size: 16,
                            weight: FontWeight.w800,
                            color: isTop3
                                ? _badgeColor
                                : const Color(0xFF1A1A2E)),
                      ),
                      TextSpan(
                        text: 'pts',
                        style: _mono(
                            size: 9,
                            weight: FontWeight.w600,
                            color: const Color(0xFF888880)),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$acc%',
                  style: _mono(
                      size: 11,
                      weight: FontWeight.w700,
                      color: const Color(0xFF1D9E75)),
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