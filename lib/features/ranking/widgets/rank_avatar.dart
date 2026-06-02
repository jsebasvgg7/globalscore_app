import 'package:flutter/material.dart';

// ── Paleta Neobrutalismo ───────────────────────────────────────────────────────
const _border      = Color(0xFF1A1A2E);
const _accent      = Color(0xFF5B4FD8);
const _shadowColor = Color(0x661A1A2E);

/// Avatar cuadrado con estilo neobrutalista.
/// Soporta imagen de red con fallback a inicial del nombre.
/// El borde y la sombra dura se controlan externamente.
class RankAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  const RankAvatar({
    super.key,
    this.url,
    required this.name,
    required this.size,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    Widget avatar;
    if (url != null && url!.isNotEmpty) {
      avatar = SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          child: Image.network(
            url!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => _placeholder(initials, size),
          ),
        ),
      );
    } else {
      avatar = _placeholder(initials, size);
    }

    if (borderColor != null && borderWidth > 0) {
      return Container(
        width: size + borderWidth * 2,
        height: size + borderWidth * 2,
        decoration: BoxDecoration(
          // Borde de color de medalla
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: SizedBox(width: size, height: size, child: avatar),
      );
    }
    return SizedBox(width: size, height: size, child: avatar);
  }

  Widget _placeholder(String initials, double size) {
    return Container(
      width: size,
      height: size,
      // Fondo de acento — consistente con dashboard
      color: _accent,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.38,
          fontFamily: 'DMMono',
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}