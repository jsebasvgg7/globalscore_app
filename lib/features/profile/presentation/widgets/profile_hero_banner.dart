import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/profile_models.dart';

/// Banner hero superior del perfil.
/// Replica exactamente el diseño de la web: imagen de banner full-width,
/// avatar superpuesto abajo a la izquierda con badge de nivel.
class ProfileHeroBanner extends StatelessWidget {
  final UserProfile profile;
  final bool isOwner;
  final VoidCallback? onEditTap;

  const ProfileHeroBanner({
    super.key,
    required this.profile,
    required this.isOwner,
    this.onEditTap,
  });

  static const double _bannerHeight = 180.0;
  static const double _avatarRadius = 38.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Banner ──────────────────────────────
        _BannerImage(
          url: profile.equippedBannerUrl,
          height: _bannerHeight,
        ),

        // ── Label "PERFIL · GLOBALSCORE" ────────
        Positioned(
          bottom: 12,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF60519B).withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'PERFIL · GLOBALSCORE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
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
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(height),
        errorWidget: (_, __, ___) => _fallback(height),
      );
    }
    return _fallback(height);
  }

  Widget _placeholder(double h) => Container(
        height: h,
        color: const Color(0xFFE0DCF5),
      );

  Widget _fallback(double h) => Container(
        height: h,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF60519B), Color(0xFF8B7FC7)],
          ),
        ),
      );
}

/// Fila de identidad debajo del banner: avatar + nombre + nivel.
/// Usada en ProfilePage y PublicProfilePage.
class ProfileIdentityRow extends StatelessWidget {
  final UserProfile profile;
  final bool isOwner;
  final VoidCallback? onTap; // navegar al perfil o editar

  const ProfileIdentityRow({
    super.key,
    required this.profile,
    required this.isOwner,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _Avatar(url: profile.avatarUrl, radius: 30),
            const SizedBox(width: 12),

            // Nombre + nivel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'GLOBAL · NIV.${profile.level}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar circular con badge de nivel superpuesto (igual que en React).
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
        _Avatar(url: url, radius: radius),
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
                  const Icon(Icons.military_tech,
                      color: Colors.white, size: 12),
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

class _Avatar extends StatelessWidget {
  final String? url;
  final double radius;

  const _Avatar({required this.url, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE0DCF5),
      backgroundImage: (url != null && url!.isNotEmpty)
          ? CachedNetworkImageProvider(url!)
          : null,
      child: (url == null || url!.isEmpty)
          ? Icon(Icons.person, size: radius, color: const Color(0xFF60519B))
          : null,
    );
  }
}

/// Barra de stats oscura: Puntos / Aciertos / Precisión
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
          _Divider(),
          _StatCell(value: '${profile.correct}', label: 'ACIERTOS'),
          _Divider(),
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.12),
    );
  }
}