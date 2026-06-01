import 'package:flutter/material.dart';

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
      color: const Color(0xFF6055C8),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
          fontFamily: 'DMMono',
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}