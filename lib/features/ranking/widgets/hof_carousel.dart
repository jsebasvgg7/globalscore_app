import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/ranking_service.dart';
import 'rank_avatar.dart';

// ── Paleta Neobrutalismo ───────────────────────────────────────────────────────
const _bg     = Color(0xFFF0EDE8);
const _card   = Color(0xFFEAE7E1);
const _border = Color(0xFF1A1A2E);
const _accent = Color(0xFF5B4FD8);
const _text   = Color(0xFF1A1A2E);
const _muted  = Color(0xFF6B6580);
const _gold   = Color(0xFFC9A227);
const _silver = Color(0xFF8A8A8A);
const _bronze = Color(0xFFA0652A);

const _shadowColor = Color(0x661A1A2E);
const _shadowSm    = BoxShadow(color: _shadowColor, offset: Offset(1, 1), blurRadius: 0);
const _shadow      = BoxShadow(color: _shadowColor, offset: Offset(1, 1), blurRadius: 0);
const _shadowLg    = BoxShadow(color: _shadowColor, offset: Offset(1, 1), blurRadius: 0);

TextStyle _mono({
  Color color = _text,
  double size = 12,
  FontWeight weight = FontWeight.normal,
  double letterSpacing = 0,
}) =>
    GoogleFonts.dmMono(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        decoration: TextDecoration.none);

// ── Medallas ──────────────────────────────────────────────────────────────────
class _Medal {
  final String label;
  final Color color;
  final Color bg;
  const _Medal(this.label, this.color, this.bg);
}

const _medals = [
  _Medal('ORO',    _gold,   Color(0xFFFFF8E1)),
  _Medal('PLATA',  _silver, Color(0xFFF5F5F5)),
  _Medal('BRONCE', _bronze, Color(0xFFFFF3E0)),
];

// ══════════════════════════════════════════════════════════════════════════════
//  HOF CAROUSEL — neobrutalista renovado
// ══════════════════════════════════════════════════════════════════════════════
class HofCarousel extends StatefulWidget {
  final List<HofChampion> champions;
  final void Function(String userId)? onSelect;

  const HofCarousel({super.key, required this.champions, this.onSelect});

  @override
  State<HofCarousel> createState() => _HofCarouselState();
}

class _HofCarouselState extends State<HofCarousel>
    with SingleTickerProviderStateMixin {
  int  _active  = 0;
  bool _exiting = false;
  Timer? _timer;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.champions.length <= 1) return;
    _timer = Timer(const Duration(seconds: 6), () => _nav(1));
  }

  void _nav(int delta, {int? target}) {
    if (_exiting || widget.champions.isEmpty) return;
    _timer?.cancel();
    setState(() => _exiting = true);
    _animCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        final total = widget.champions.length;
        _active  = target ?? ((_active + delta) % total + total) % total;
        _exiting = false;
      });
      _animCtrl.forward();
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final champions = widget.champions;
    if (champions.isEmpty) return _buildEmpty();

    final champ    = champions[_active];
    final medalIdx = _active.clamp(0, 2);
    final medal    = _medals[medalIdx];
    final total    = champions.length;

    return Column(
      children: [
        // ── Tarjeta principal ──────────────────────────────────────────────────
        FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _card,
                border: Border.all(color: _border, width: 1),
                boxShadow: const [_shadowLg],
              ),
              child: Column(
                children: [
                  // ── HERO: fondo de color + avatar grande centrado ──────────
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Fondo de color de medalla
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: medal.color,
                        ),
                        child: Stack(
                          children: [
                            // Patrón de puntos decorativo (neobrutal)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _DotPatternPainter(
                                    color: _border.withOpacity(0.08)),
                              ),
                            ),
                            // Label "S. FAMA"
                            Positioned(
                              top: 10,
                              left: 12,
                              child: Text(
                                'SALÓN DE LA FAMA',
                                style: _mono(
                                    size: 8,
                                    weight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                    color: _border.withOpacity(0.5)),
                              ),
                            ),
                          ],
                        )
                      ),
                      // Avatar centrado, mitad dentro mitad fuera del hero
                      Positioned(
                        bottom: -40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () => widget.onSelect?.call(champ.id),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: _border, width: 1),
                                boxShadow: const [_shadow],
                              ),
                              child: RankAvatar(
                                url: champ.avatarUrl,
                                name: champ.name,
                                size: 80,
                                borderColor: medal.color,
                                borderWidth: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Espaciado para el avatar que sobresale ────────────────
                  const SizedBox(height: 48),

                  // ── Nombre + coronas (centrado) ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Nombre
                        Text(
                          champ.name,
                          style: _mono(
                              size: 20,
                              weight: FontWeight.w900,
                              color: _text,
                              letterSpacing: -0.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        // Coronas — solo aquí
                        _CrownRow(
                            count: champ.monthlyChampionships,
                            color: medal.color),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Stats 3 celdas ────────────────────────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: _border, width: 1)),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          _StatCell(
                            value: '${champ.monthlyChampionships}',
                            label: 'CORONAS',
                            color: medal.color,
                          ),
                          Container(width: 1, color: _border),
                          _StatCell(
                            value: champ.bestPoints > 0
                                ? _fmt(champ.bestPoints)
                                : '—',
                            label: 'MAX PTS',
                            color: _accent,
                          ),
                          Container(width: 1, color: _border),
                          _StatCell(
                            value: champ.lastMonthYear ?? '—',
                            label: 'ÚLTIMO TÍTULO',
                            color: _muted,
                            small: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Controles de navegación ───────────────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      color: _bg,
                      border:
                          Border(top: BorderSide(color: _border, width: 1)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _NavButton(
                          icon: Icons.arrow_back_ios_rounded,
                          onTap: () => _nav(-1),
                          enabled: total > 1,
                          color: medal.color,
                        ),
                        // Indicadores
                        Row(
                          children: List.generate(total.clamp(0, 5), (i) {
                            final isAct = i == _active;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width:  isAct ? 22 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: isAct
                                    ? medal.color
                                    : _border.withOpacity(0.18),
                                border: Border.all(
                                  color: isAct ? _border : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                            );
                          }),
                        ),
                        _NavButton(
                          icon: Icons.arrow_forward_ios_rounded,
                          onTap: () => _nav(1),
                          enabled: total > 1,
                          color: medal.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Lista TOP CAMPEONES ────────────────────────────────────────────────
        if (champions.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _card,
              border: Border.all(color: _border, width: 1),
              boxShadow: const [_shadow],
            ),
            child: Column(
              children: [
                // Header tabla
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: _bg,
                    border: Border(
                        bottom: BorderSide(color: _border, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 4, height: 14, color: _gold),
                      const SizedBox(width: 8),
                      Text(
                        'TOP CAMPEONES',
                        style: _mono(
                            size: 9,
                            weight: FontWeight.w800,
                            letterSpacing: 1.8,
                            color: _text),
                      ),
                    ],
                  ),
                ),
                // Filas
                ...champions.take(3).toList().asMap().entries.map((e) {
                  final i     = e.key;
                  final u     = e.value;
                  final medal = _medals[i];
                  final isAct = i == _active;

                  return GestureDetector(
                    onTap: () =>
                        _nav(i > _active ? 1 : -1, target: i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isAct
                            ? medal.color.withOpacity(0.07)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                              color: _border.withOpacity(0.3), width: 0.5),
                          left: BorderSide(
                            color: isAct ? medal.color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      padding: EdgeInsets.only(
                        left:   isAct ? 13 : 16,
                        right:  16,
                        top:    12,
                        bottom: 12,
                      ),
                      child: Row(
                        children: [
                          // Badge posición
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: medal.color,
                              border: Border.all(color: _border, width: 1),
                              boxShadow: const [_shadowSm],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: _mono(
                                  color: Colors.white,
                                  size: 10,
                                  weight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 10),
                          RankAvatar(
                              url: u.avatarUrl, name: u.name, size: 36),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.name,
                                  style: _mono(
                                      size: 13,
                                      weight: FontWeight.w700,
                                      color: _text),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    u.bestPoints > 0
                                        ? _fmt(u.bestPoints)
                                        : '—',
                                    style: _mono(
                                        size: 16,
                                        weight: FontWeight.w900,
                                        color: medal.color),
                                  ),
                                  Text('pts',
                                      style: _mono(size: 8, color: _muted)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('mejor mes',
                                  style: _mono(size: 7, color: _muted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border, width: 1),
        boxShadow: const [_shadow],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _bg,
              border: Border.all(color: _border, width: 1),
              boxShadow: const [_shadowSm],
            ),
            child: Center(
                child: SizedBox(
                  width: 28,
                  height: 22,
                  child: CustomPaint(painter: _CrownPainter(color: _gold)),
                ),
              ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 20, height: 2, color: _border),
              const SizedBox(width: 8),
              Text('SIN CAMPEONES',
                  style: _mono(
                      size: 10,
                      weight: FontWeight.w800,
                      letterSpacing: 2,
                      color: _text)),
              const SizedBox(width: 8),
              Container(width: 20, height: 2, color: _border),
            ],
          ),
          const SizedBox(height: 6),
          Text('Aún no hay campeones registrados',
              style: _mono(color: _muted, size: 11)),
        ],
      ),
    );
  }
}

// ── Botón nav — cuadrado con color de medalla activa ─────────────────────────
class _NavButton extends StatelessWidget {
  final IconData   icon;
  final VoidCallback? onTap;
  final bool       enabled;
  final Color      color;

  const _NavButton({
    required this.icon,
    this.onTap,
    required this.enabled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? color : _card,
          border: Border.all(
              color: _border, width: enabled ? 2 : 1.5),
          boxShadow: enabled ? const [_shadowSm] : null,
        ),
        alignment: Alignment.center,
        child: Icon(icon,
            size: 13,
            color: enabled ? Colors.white : _muted),
      ),
    );
  }
}

// ── Crown Row ────────────────────────────────────────────────────────────────
class _CrownRow extends StatelessWidget {
  final int   count;
  final Color color;
  const _CrownRow({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final show  = count.clamp(0, 6);
    final extra = count - 6;
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < show; i++)
          SizedBox(
            width: 20,
            height: 16,
            child: CustomPaint(painter: _CrownPainter(color: color)),
          ),
        if (extra > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: _border, width: 1),
            ),
            child: Text('+$extra',
                style: _mono(
                    size: 9,
                    weight: FontWeight.w800,
                    color: Colors.white)),
          ),
      ],
    );
  }
}

// ── Stat Cell ────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String  value;
  final String  label;
  final Color   color;
  final IconData? icon;
  final bool    small;
  final bool    crownIcon;

  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
    this.icon,
    this.small = false,
    this.crownIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (crownIcon) ...[
                  SizedBox(
                    width: 16,
                    height: 13,
                    child: CustomPaint(painter: _CrownPainter(color: color)),
                  ),
                  const SizedBox(width: 3),
                ] else if (icon != null) ...[
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 3),
                ],
                Text(
                  value,
                  style: _mono(
                    size: small ? 13 : 22,
                    weight: FontWeight.w900,
                    color: color,
                    letterSpacing: small ? 0.5 : -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(width: 6, height: 2, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: _mono(
                        size: 7,
                        weight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: _muted),
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

// ── Crown Painter — corona vectorial dibujada con Path ────────────────────────
class _CrownPainter extends CustomPainter {
  final Color color;
  const _CrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = color..style = PaintingStyle.fill;

    // ── Cuerpo de la corona (izq → centro → der, sentido horario) ────
    final path = Path()
      ..moveTo(0,        h * 0.55)   // base pico izq
      ..lineTo(w * 0.14, 0)          // tip pico izq
      ..lineTo(w * 0.28, h * 0.55)   // valle izq-centro
      ..lineTo(w * 0.50, h * 0.05)   // tip pico centro
      ..lineTo(w * 0.72, h * 0.55)   // valle centro-der
      ..lineTo(w * 0.86, 0)          // tip pico der
      ..lineTo(w,        h * 0.55)   // base pico der
      ..lineTo(w,        h)          // esquina inf-der
      ..lineTo(0,        h)          // borde inferior
      ..close();

    canvas.drawPath(path, fill);

    // ── Perlas en cada tip ────────────────────────────────────────────
    final r = w * 0.09;
    for (final pt in [
      Offset(w * 0.14, 0),
      Offset(w * 0.50, h * 0.05),
      Offset(w * 0.86, 0),
    ]) {
      canvas.drawCircle(pt, r, fill);
    }
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.color != color;
}

// ── Painter para patrón de puntos ────────────────────────────────────────────
class _DotPatternPainter extends CustomPainter {
  final Color color;
  const _DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 16.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) => old.color != color;
}

// ── Utilidad ─────────────────────────────────────────────────────────────────
String _fmt(int n) {
  if (n >= 1000) {
    final k = n ~/ 1000;
    final r = n % 1000;
    return '$k.${r.toString().padLeft(3, '0')}';
  }
  return '$n';
}