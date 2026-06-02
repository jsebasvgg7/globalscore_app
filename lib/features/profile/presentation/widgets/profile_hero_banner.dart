import 'package:flutter/material.dart';
import '../../domain/profile_models.dart';

bool _hasUrl(String? url) => url != null && url.trim().isNotEmpty;

// ── Paleta ────────────────────────────────────────────────────
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFEAE7E1);
const _border  = Color(0xFFC8C3B8);
const _accent  = Color(0xFF5B4FD8);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF6B6580);

const _shadowSm = BoxShadow(color: Color(0x4D1A1A2E), offset: Offset(1, 1), blurRadius: 0);

class ProfileHeroBanner extends StatelessWidget {
  final UserProfile profile;
  final bool isOwner;

  const ProfileHeroBanner({
    super.key,
    required this.profile,
    required this.isOwner,
  });

  static const double _bannerHeight = 130.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _BannerImage(url: profile.equippedBannerUrl, height: _bannerHeight),
        // Badge neobrutalista
        Positioned(
          bottom: 10,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _accent,
              boxShadow: const [_shadowSm],
            ),
            child: const Text(
              'PERFIL · GLOBALSCORE',
              style: TextStyle(
                fontFamily: 'DM Mono',
                color: Colors.white,
                fontSize: 8,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
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
          colors: [Color(0xFF5B4FD8), Color(0xFF8B7FC7)],
        ),
      ),
    );
  }
}

// ─── Fila de identidad neobrutalista ─────────
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: _card,
          border: Border(bottom: BorderSide(color: _border, width: 1)),
        ),
        child: Row(
          children: [
            _NetworkAvatar(url: profile.avatarUrl, radius: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(width: 4, height: 4, color: _accent),
                      const SizedBox(width: 5),
                      Text(
                        'GLOBAL · NIV.${profile.level}',
                        style: const TextStyle(
                          fontFamily: 'DM Mono',
                          fontSize: 9,
                          color: _muted,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isOwner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  border: Border.all(color: _accent.withOpacity(0.3), width: 1),
                ),
                child: const Text(
                  'EDITAR',
                  style: TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: _accent,
                    letterSpacing: 1.0,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────
class _NetworkAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  const _NetworkAvatar({required this.url, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: const Color(0xFF8B7FC7),
        border: Border.all(color: _border, width: 1),
        boxShadow: const [_shadowSm],
      ),
      clipBehavior: Clip.hardEdge,
      child: _hasUrl(url)
          ? Image.network(
              url!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.person,
                size: radius * 0.9,
                color: Colors.white,
              ),
            )
          : Icon(Icons.person, size: radius * 0.9, color: Colors.white),
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
          bottom: -10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _accent,
                boxShadow: const [_shadowSm],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.military_tech, color: Colors.white, size: 11),
                  const SizedBox(width: 3),
                  Text(
                    'NIV.$level',
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
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

/// Barra de stats — estilo neobrutalista oscuro
class ProfileStatsBar extends StatelessWidget {
  final UserProfile profile;
  const ProfileStatsBar({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final accuracy = profile.accuracy.round();
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(
          bottom: BorderSide(color: Color(0xFF5B4FD8), width: 2),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(value: '${profile.points}', label: 'PUNTOS'),
            Container(width: 1, color: Colors.white.withOpacity(0.12)),
            _StatCell(value: '${profile.correct}', label: 'ACIERTOS'),
            Container(width: 1, color: Colors.white.withOpacity(0.12)),
            _StatCell(value: '$accuracy%', label: 'PRECISIÓN'),
          ],
        ),
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
              fontFamily: 'DM Mono',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}