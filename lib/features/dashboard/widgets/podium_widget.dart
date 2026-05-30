import 'package:flutter/material.dart';

class PodiumWidget extends StatelessWidget {
  final List topUsers;
  final Map<String, dynamic>? currentUser;

  const PodiumWidget({super.key, required this.topUsers, this.currentUser});

  @override
  Widget build(BuildContext context) {
    if (topUsers.length < 3) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Sin datos de ranking', style: TextStyle(color: Colors.white38)),
      );
    }

    final first = topUsers[0];
    final second = topUsers[1];
    final third = topUsers[2];

    // Orden visual: 2º | 1º | 3º
    final visual = [second, first, third];
    final heights = [90.0, 120.0, 70.0];
    final medals = ['🥈', '🥇', '🥉'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text('RANKING GLOBAL',
                style: TextStyle(
                    color: Colors.white38, fontSize: 9, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(3, (i) {
                final u = visual[i] as Map<String, dynamic>;
                final isMe = u['id'] == currentUser?['id'];
                return _PodiumCol(
                  user: u,
                  height: heights[i],
                  medal: medals[i],
                  isMe: isMe,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumCol extends StatelessWidget {
  final Map<String, dynamic> user;
  final double height;
  final String medal;
  final bool isMe;

  const _PodiumCol({
    required this.user,
    required this.height,
    required this.medal,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] ?? '—').toString();
    final points = user['points'] ?? 0;
    final avatarUrl = user['avatar_url'] as String?;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMe ? const Color(0xFF00E5FF) : Colors.white12,
            border: isMe ? Border.all(color: const Color(0xFF00E5FF), width: 2) : null,
          ),
          child: avatarUrl != null
              ? ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(child: Text(name[0].toUpperCase(),
                    style: TextStyle(color: isMe ? Colors.black : Colors.white, fontWeight: FontWeight.w800)))))
              : Center(child: Text(name[0].toUpperCase(),
                  style: TextStyle(color: isMe ? Colors.black : Colors.white, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(height: 4),
        Text(name.substring(0, name.length.clamp(0, 8)).toUpperCase(),
            style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
        if (isMe)
          const Text('TÚ', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 8, fontWeight: FontWeight.w800)),
        Text('$points pts', style: const TextStyle(color: Colors.white38, fontSize: 9)),
        const SizedBox(height: 6),
        Text(medal, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        // Pedestal
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF5B4FD8).withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
      ],
    );
  }
}