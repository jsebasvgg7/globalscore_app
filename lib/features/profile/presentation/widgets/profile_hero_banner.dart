import 'package:flutter/material.dart';
import '../../domain/profile_models.dart';

bool _hasUrl(String? url) => url != null && url.trim().isNotEmpty;

class ProfileHeroBanner extends StatelessWidget {
  final UserProfile profile;
  final bool isOwner;

  const ProfileHeroBanner({
    super.key,
    required this.profile,
    required this.isOwner,
  });

  // 25% menos que 180 → 135
  static const double _bannerHeight = 135.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _BannerImage(url: profile.equippedBannerUrl, height: _bannerHeight),
        Positioned(
          bottom: 10,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF60519B).withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'PERFIL · GLOBALSCORE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerImage extends StatelessWidget {
  final String? url;
  final double height;
  const _BannerImage({required this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    if (_hasUrl(url)) {
      return Image.network(
        url!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _Fallback(height: height),
        errorBuilder: (_, __, ___) => _Fallback(height: height),
      );
    }
    return _Fallback(height: height);
  }
}

class _Fallback extends StatelessWidget {
  final double height;
  const _Fallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF60519B), Color(0xFF8B7FC7)],
        ),
      ),
    );
  }
}

// ─── Fila de identidad ────────────────────────
class ProfileIdentityRow extends StatelessWidget {
  final UserProfile profile;
  final bool isOwner;
  final VoidCallback? onTap;

  const ProfileIdentityRow({
    super.key,
    required this.profile,
    required this.isOwner,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _NetworkAvatar(url: profile.avatarUrl, radius: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'GLOBAL · NIV.${profile.level}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0x801A1A2E),
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0x401A1A2E), size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar circular robusto ──────────────────
class _NetworkAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  const _NetworkAvatar({required this.url, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE0DCF5),
      child: _hasUrl(url)
          ? ClipOval(
              child: Image.network(
                url!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person,
                  size: radius * 0.9,
                  color: const Color(0xFF60519B),
                ),
              ),
            )
          : Icon(Icons.person, size: radius * 0.9, color: const Color(0xFF60519B)),
    );
  }
}

/// Avatar con badge de nivel (usado en EditTab)
class ProfileAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  final int level;

  const ProfileAvatar({
    super.key,
    required this.url,
    required this.radius,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _NetworkAvatar(url: url, radius: radius),
        Positioned(
          bottom: -8,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF60519B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF60519B).withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.military_tech, color: Colors.white, size: 12),
                  const SizedBox(width: 3),
                  Text(
                    'Lvl $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Barra de stats oscura
class ProfileStatsBar extends StatelessWidget {
  final UserProfile profile;
  const ProfileStatsBar({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final accuracy = profile.accuracy.round();
    return Container(
      color: const Color(0xFF1E2032),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _StatCell(value: '${profile.points}', label: 'PUNTOS'),
          _VDivider(),
          _StatCell(value: '${profile.correct}', label: 'ACIERTOS'),
          _VDivider(),
          _StatCell(value: '$accuracy%', label: 'PRECISIÓN'),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.55),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: Colors.white.withOpacity(0.12));
  }
}