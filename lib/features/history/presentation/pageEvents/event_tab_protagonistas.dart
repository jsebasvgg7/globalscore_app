import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import 'history_events_shared.dart';

// ══════════════════════════════════════════════════════════════
//  TAB PROTAGONISTAS — personajes clave con navegación interna
// ══════════════════════════════════════════════════════════════

class EventTabProtagonistas extends ConsumerWidget {
  final EventDetail detail;
  const EventTabProtagonistas({super.key, required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protagonists = detail.protagonists;

    if (protagonists.isEmpty) {
      return const Center(
        child: EvEmpty(message: 'Sin protagonistas registrados'),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EvTabHeader(
            icon: Icons.stars_rounded,
            title: 'PROTAGONISTAS',
            subtitle:
                '${protagonists.length} protagonista${protagonists.length == 1 ? '' : 's'} del evento',
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              children: protagonists
                  .map((p) => _ProtagonistCard(protagonist: p))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  CARD DE PROTAGONISTA
// ══════════════════════════════════════════════════════════════

class _ProtagonistCard extends ConsumerWidget {
  final EventProtagonist protagonist;
  const _ProtagonistCard({required this.protagonist});

  Color get _accentColor {
    if (protagonist.player != null) return kEvPurple;
    if (protagonist.team != null) return kEvBlue;
    return kEvGold;
  }

  // Un protagonista "sin entidad" es aquel sin imagePath Y sin link a ficha interna
  bool get _hasEntity => protagonist.imagePath != null || protagonist.hasLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proto = protagonist;
    final accent = _accentColor;
    final imgUrl = getHistoricalImageUrl(proto.imagePath);
    final initials = proto.displayName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kEvBg,
        border: Border.all(color: kEvBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1A1A2E).withValues(alpha: 0.35),
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Barra de color superior ───────────────────────
          Container(height: 4, color: accent),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: _hasEntity
                ? _EntityLayout(
                    proto: proto,
                    accent: accent,
                    imgUrl: imgUrl,
                    initials: initials,
                  )
                : _NoEntityLayout(proto: proto, accent: accent),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LAYOUT CON ENTIDAD — tiene imagen o link a ficha
// ══════════════════════════════════════════════════════════════

class _EntityLayout extends ConsumerWidget {
  final EventProtagonist proto;
  final Color accent;
  final String? imgUrl;
  final String initials;

  const _EntityLayout({
    required this.proto,
    required this.accent,
    required this.imgUrl,
    required this.initials,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Avatar ───────────────────────────────────────
        _Avatar(
          imgUrl: imgUrl,
          initials: initials,
          accent: accent,
          isTeam: proto.team != null,
        ),

        const SizedBox(width: 14),

        // ── Info ─────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre + icono
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      proto.displayName.toUpperCase(),
                      style: evMono(
                        size: 14,
                        weight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (proto.icon != null && proto.icon!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      proto.icon!,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ],
              ),

              // Subtítulo (posición · país)
              if (_subtitle(proto).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _subtitle(proto),
                    style: evMono(size: 9, color: kEvMuted),
                  ),
                ),

              // Rol label
              if (proto.roleLabel != null &&
                  proto.roleLabel!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                _RoleLabel(label: proto.roleLabel!, accent: accent),
              ],

              // Botón VER FICHA
              if (proto.hasLink) ...[
                const SizedBox(height: 10),
                _LinkButton(protagonist: proto, accent: accent),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _subtitle(EventProtagonist p) {
    if (p.player != null) {
      final parts = <String>[];
      if (p.player!.position != null) parts.add(p.player!.position!);
      if (p.player!.country != null) parts.add(p.player!.country!);
      return parts.join(' · ');
    }
    if (p.team?.country != null) return p.team!.country!;
    return '';
  }
}

// ══════════════════════════════════════════════════════════════
//  LAYOUT SIN ENTIDAD 
// ══════════════════════════════════════════════════════════════

class _NoEntityLayout extends StatelessWidget {
  final EventProtagonist proto;
  final Color accent;

  const _NoEntityLayout({required this.proto, required this.accent});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banda lateral de color
          Container(width: 4, color: accent),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre + emoji
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        proto.displayName.toUpperCase(),
                        style: evMono(
                          size: 18,
                          weight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (proto.icon != null && proto.icon!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        proto.icon!,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ],
                  ],
                ),

                // Subtítulo
                if (_subtitle(proto).isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    _subtitle(proto),
                    style: evMono(size: 9, color: kEvMuted),
                  ),
                ],

                // Rol label
                if (proto.roleLabel != null &&
                    proto.roleLabel!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _RoleLabel(label: proto.roleLabel!, accent: accent),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(EventProtagonist p) {
    if (p.player != null) {
      final parts = <String>[];
      if (p.player!.position != null) parts.add(p.player!.position!);
      if (p.player!.country != null) parts.add(p.player!.country!);
      return parts.join(' · ');
    }
    if (p.team?.country != null) return p.team!.country!;
    return '';
  }
}

// ══════════════════════════════════════════════════════════════
//  WIDGETS COMPARTIDOS
// ══════════════════════════════════════════════════════════════

// ── Rol label reutilizable ───────────────────────────────────
class _RoleLabel extends StatelessWidget {
  final String label;
  final Color accent;
  const _RoleLabel({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        border: Border.all(color: accent.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: evMono(
          size: 9,
          weight: FontWeight.w800,
          color: accent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Avatar cuadrado neobrutalista ────────────────────────────
class _Avatar extends StatelessWidget {
  final String? imgUrl;
  final String initials;
  final Color accent;
  final bool isTeam;

  const _Avatar({
    required this.imgUrl,
    required this.initials,
    required this.accent,
    required this.isTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        border: Border.all(color: kEvBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: kEvDark.withOpacity(0.3),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: imgUrl != null
          ? Image.network(
              imgUrl!,
              fit: isTeam ? BoxFit.contain : BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _InitialsBox(initials: initials, accent: accent),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : _InitialsBox(initials: initials, accent: accent),
            )
          : _InitialsBox(initials: initials, accent: accent),
    );
  }
}

class _InitialsBox extends StatelessWidget {
  final String initials;
  final Color accent;
  const _InitialsBox({required this.initials, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withOpacity(0.12),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : '?',
          style: evMono(size: 20, weight: FontWeight.w900, color: accent),
        ),
      ),
    );
  }
}

// ── Botón de navegación a la ficha interna ───────────────────
class _LinkButton extends ConsumerWidget {
  final EventProtagonist protagonist;
  final Color accent;
  const _LinkButton({required this.protagonist, required this.accent});

  void _navigate(WidgetRef ref) {
    if (protagonist.player != null) {
      ref.read(selectedPlayerProvider.notifier).select(protagonist.player);
      ref.read(historySectionProvider.notifier).setSection('players');
    } else if (protagonist.team != null) {
      ref.read(selectedTeamProvider.notifier).select(protagonist.team);
      ref.read(historySectionProvider.notifier).setSection('teams');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _navigate(ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: accent,
          border: Border.all(color: kEvBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: kEvDark.withOpacity(0.35),
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VER FICHA',
              style: evMono(
                size: 9,
                weight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward, size: 11, color: Colors.white),
          ],
        ),
      ),
    );
  }
}