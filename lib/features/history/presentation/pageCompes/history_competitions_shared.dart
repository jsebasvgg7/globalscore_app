import 'package:flutter/material.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';

// ══════════════════════════════════════════════════════════════
//  TOKENS DE COLOR
// ══════════════════════════════════════════════════════════════

const Color kHistBg      = Color(0xFFF5F1EB);
const Color kHistDark    = Color(0xFF1A1A1A);
const Color kHistAccent  = Color(0xFF1A1A1A);
const Color kHistGold    = Color(0xFFD4A017);
const Color kHistGreen   = Color(0xFF10B981);
const Color kHistMuted   = Color(0xFF888077);
const Color kHistBorder  = Color(0xFF1A1A1A);
const Color kHistBorderL = Color(0xFFD6D0C8);
const Color kHistCard    = Color(0xFFFFFFFF);

// ══════════════════════════════════════════════════════════════
//  HELPERS
// ══════════════════════════════════════════════════════════════

TextStyle monoStyle({
  double size = 12,
  Color color = kHistDark,
  FontWeight weight = FontWeight.normal,
  double letterSpacing = 0,
}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );

BoxDecoration neoBox({
  Color bg = Colors.white,
  Color border = kHistBorder,
  double shadowX = 3,
  double shadowY = 3,
  Color shadow = kHistDark,
}) =>
    BoxDecoration(
      color: bg,
      border: Border.all(color: border, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: shadow,
          offset: Offset(shadowX, shadowY),
          blurRadius: 0,
        ),
      ],
    );

// ══════════════════════════════════════════════════════════════
//  DOT GRID
// ══════════════════════════════════════════════════════════════

class DotGrid extends StatelessWidget {
  final int cols;
  final int rows;
  final Color color;
  const DotGrid({
    super.key,
    this.cols = 6,
    this.rows = 4,
    this.color = kHistBorderL,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        rows,
        (_) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            cols,
            (_) => Container(
              width: 3,
              height: 3,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TIPO DE COMPETICIÓN
// ══════════════════════════════════════════════════════════════

const compTypeColors = {
  'International': Color(0xFFE8A020),
  'Continental'  : Color(0xFF3DAA80),
  'Domestic'     : Color(0xFF5B4FD8),
};

const compTypeLabels = {
  'International': 'INTERNACIONAL',
  'Continental'  : 'CONTINENTAL',
  'Domestic'     : 'NACIONAL',
};

const compFormatLabels = {
  'groups_knockout': 'Grupos + Elim.',
  'league_only'    : 'Liga',
  'knockout_only'  : 'Eliminatorias',
};

Color compTypeColor(String? t) => compTypeColors[t] ?? kHistMuted;

// ══════════════════════════════════════════════════════════════
//  BADGE
// ══════════════════════════════════════════════════════════════

class CompBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const CompBadge({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        color: bg,
        child: Text(
          label,
          style: monoStyle(
            size: 7,
            color: fg,
            weight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  SECTION LABEL
// ══════════════════════════════════════════════════════════════

class CompSectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  const CompSectionLabel({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFFE8E4DE),
        child: Row(
          children: [
            Container(width: 3, height: 12, color: kHistAccent),
            const SizedBox(width: 8),
            if (icon != null) ...[
              Icon(icon, size: 10, color: kHistMuted),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: monoStyle(
                size: 9,
                color: kHistMuted,
                weight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  COMP CARD  ← FIX: logo cuadrado 1:1 perfectamente alineado
// ══════════════════════════════════════════════════════════════

class CompCard extends StatefulWidget {
  final HistoricalCompetition comp;
  final int index;
  final VoidCallback onTap;
  const CompCard({
    super.key,
    required this.comp,
    required this.index,
    required this.onTap,
  });

  @override
  State<CompCard> createState() => _CompCardState();
}

class _CompCardState extends State<CompCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _slide = Tween<Offset>(
            begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeIn);
    Future.delayed(
      Duration(milliseconds: 35 * widget.index),
      () { if (mounted) _ac.forward(); },
    );
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comp   = widget.comp;
    final imgUrl = getHistoricalImageUrl(comp.imagePath);
    final tc     = compTypeColor(comp.type);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            transform: _pressed
                ? (Matrix4.identity()..translate(3.0, 3.0))
                : Matrix4.identity(),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kHistBorder, width: 1.5),
              boxShadow: _pressed
                  ? []
                  : const [
                      BoxShadow(
                          color: kHistDark,
                          offset: Offset(3, 3),
                          blurRadius: 0)
                    ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stripe de color
                  Container(width: 4, color: tc),

                  // ── FIX logo 1:1 ──────────────────────────────────────
                  // SizedBox con width fijo + AspectRatio 1:1
                  // garantiza que sea siempre un cuadrado perfecto
                  SizedBox(
                    width: 90,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFEBE7E1),
                          border: Border(
                            right: BorderSide(color: kHistBorderL, width: 1),
                          ),
                        ),
                        child: imgUrl != null
                            ? Padding(
                                padding: const EdgeInsets.all(6),
                                child: Image.network(
                                  imgUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Icon(Icons.emoji_events,
                                        size: 36, color: tc),
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(Icons.emoji_events,
                                    size: 36, color: tc),
                              ),
                      ),
                    ),
                  ),

                  // Contenido
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              if (comp.type != null)
                                CompBadge(
                                  label: compTypeLabels[comp.type!] ??
                                      comp.type!,
                                  bg: tc,
                                  fg: Colors.white,
                                ),
                              if (comp.format != null)
                                CompBadge(
                                  label: compFormatLabels[comp.format!] ??
                                      comp.format!,
                                  bg: const Color(0xFFE8E4DE),
                                  fg: kHistMuted,
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            comp.name,
                            style:
                                monoStyle(size: 13, weight: FontWeight.w800),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(children: [
                            if (comp.year != null)
                              Text('${comp.year}',
                                  style:
                                      monoStyle(size: 10, color: kHistMuted)),
                            if (comp.country != null) ...[
                              Text(' · ',
                                  style: monoStyle(
                                      size: 10, color: kHistBorderL)),
                              Flexible(
                                child: Text(
                                  comp.country!,
                                  style:
                                      monoStyle(size: 10, color: kHistMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ]),
                          if (comp.winnerDisplay != '—') ...[
                            const SizedBox(height: 5),
                            Row(children: [
                              const Icon(Icons.emoji_events,
                                  size: 10, color: kHistGold),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  comp.winnerDisplay.toUpperCase(),
                                  style: monoStyle(
                                    size: 10,
                                    color: kHistGold,
                                    weight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(Icons.chevron_right,
                        size: 18, color: kHistMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}