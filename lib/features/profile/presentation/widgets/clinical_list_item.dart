import 'package:flutter/material.dart';

// ── Paleta Neobrutalismo ──────────────────────────────────────────────
const _bg     = Color(0xFFF0EDE8);
const _card   = Color(0xFFEAE7E1);
const _border = Color(0xFF1A1A2E);   // ← borde oscuro, igual que ranking/stats
const _accent = Color(0xFF5B4FD8);
const _text   = Color(0xFF1A1A2E);
const _muted  = Color(0xFF6B6580);

const _shadowColor = Color(0x661A1A2E);
const _shadowSm    = BoxShadow(
  color: _shadowColor, offset: Offset(1, 1), blurRadius: 0);

/// Fila estilo neobrutalista: ícono cuadrado + título + subtítulo + chevron.
class ClinicalListItem extends StatelessWidget {
  final Color iconColor;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const ClinicalListItem({
    super.key,
    required this.iconColor,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: iconColor.withOpacity(0.08),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Icon box — cuadrado neobrutalista
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconColor,
                      boxShadow: const [_shadowSm],
                    ),
                    child: Icon(icon, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 14),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'DM Mono',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _text,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontFamily: 'DM Mono',
                              fontSize: 10,
                              color: _muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (trailing != null) trailing!,
                  if (trailing == null && onTap != null)
                    const Icon(Icons.chevron_right, color: _muted, size: 20),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 68),
            color: _border.withOpacity(0.15),
          ),
      ],
    );
  }
}

/// Card agrupadora neobrutalista — esquinas rectas, borde y sombra dura
class ClinicalCard extends StatelessWidget {
  final List<Widget> children;

  const ClinicalCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border, width: 1),
        boxShadow: const [_shadowSm],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Header de sección neobrutalista
class SectionHeader extends StatelessWidget {
  final String label;
  final Color? color;

  const SectionHeader({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? _accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: c),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: _muted,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: _border)),
        ],
      ),
    );
  }
} 