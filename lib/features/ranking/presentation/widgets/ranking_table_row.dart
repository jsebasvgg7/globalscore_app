import 'package:flutter/material.dart';
import '../../data/ranking_service.dart';
import 'rank_avatar.dart';

const _kGold = Color(0xFFC9A227);
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
    final pts = user.rankPoints(rankingType);
    final correct = user.rankCorrect(rankingType);
    final acc = user.accuracy(rankingType);
    final isTop3 = pos <= 3;

    return GestureDetector(
      onTap: () => onTap?.call(user.id),
      child: Container(
        decoration: BoxDecoration(
          color: isMe
              ? _kAccent.withOpacity(0.06)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.black.withOpacity(0.06),
              width: 0.5,
            ),
            left: isTop3
                ? BorderSide(color: _badgeColor, width: 3)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'DMMono',
                        ),
                      ),
                    )
                  : Text(
                      '$pos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withOpacity(0.25),
                        fontFamily: 'DMMono',
                      ),
                    ),
            ),
            const SizedBox(width: 10),

            // ── Avatar ──
            RankAvatar(url: user.avatarUrl, name: user.name, size: 38),
            const SizedBox(width: 10),

            // ── Name + aciertos ──
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                            fontFamily: 'DMMono',
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          color: _kAccent,
                          child: const Text(
                            'TÚ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              fontFamily: 'DMMono',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$correct aciertos',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF888880),
                      fontFamily: 'DMMono',
                    ),
                  ),
                ],
              ),
            ),

            // ── Predictions badge ──
            const SizedBox(width: 6),
            Text(
              '□ 0/5',
              style: TextStyle(
                fontSize: 9,
                color: Colors.black.withOpacity(0.3),
                fontFamily: 'DMMono',
              ),
            ),
            const SizedBox(width: 10),

            // ── Points + accuracy ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _fmt(pts),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isTop3 ? _badgeColor : const Color(0xFF1A1A2E),
                          fontFamily: 'DMMono',
                        ),
                      ),
                      const TextSpan(
                        text: 'pts',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF888880),
                          fontFamily: 'DMMono',
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$acc%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D9E75),
                    fontFamily: 'DMMono',
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