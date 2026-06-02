import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/ranking_service.dart';
import 'rank_avatar.dart';

// ── Paleta Neobrutalismo ───────────────────────────────────────────────────────
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFEAE7E1);
const _border  = Color(0xFF1A1A2E);
const _accent  = Color(0xFF5B4FD8);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF6B6580);
const _green   = Color(0xFF1D9E75);
const _gold    = Color(0xFFC9A227);
const _silver  = Color(0xFF8A8A8A);
const _bronze  = Color(0xFFA0652A);

const _shadowColor = Color(0xFF1A1A2E);
const _shadow   = BoxShadow(color: _shadowColor, offset: Offset(3, 3), blurRadius: 0);
const _shadowSm = BoxShadow(color: _shadowColor, offset: Offset(2, 2), blurRadius: 0);
const _shadowLg = BoxShadow(color: _shadowColor, offset: Offset(5, 5), blurRadius: 0);

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
  const _Medal(this.label, this.color);
}

const _medals = [
  _Medal('ORO',    _gold),
  _Medal('PLATA',  _silver),
  _Medal('BRONCE', _bronze),
];

// ══════════════════════════════════════════════════════════════════════════════
//  HOF CAROUSEL — neobrutalista
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
  int _active   = 0;
  bool _exiting = false;
  Timer? _timer;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
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
        _active = target ?? ((_active + delta) % total + total) % total;
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
        // ── Tarjeta principal ──────────────────────────────────
        FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _card,
                border: Border.all(color: _border, width: 2),
                boxShadow: const [_shadowLg],
              ),
              child: Column(
                children: [
                  // ── Barra de color en el top (marca la medalla) ──
                  Container(height: 4, color: medal.color),

                  // ── Header: medalla + badge de posición ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: _bg,
                      border: Border(bottom: BorderSide(color: _border, width: 2)),
                    ),
                    child: Row(
                      children: [
                        // Barra vertical decorativa
                        Container(width: 4, height: 18, color: medal.color),
                        const SizedBox(width: 8),
                        const Icon(Icons.workspace_premium_rounded, size: 13, color: _gold),
                        const SizedBox(width: 6),
                        Text(
                          'SALÓN DE LA FAMA',
                          style: _mono(size: 9, weight: FontWeight.w800, letterSpacing: 1.8, color: _text),
                        ),
                        const Spacer(),
                        // Badge de medalla — pill sólida
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: medal.color,
                            border: Border.all(color: _border, width: 1.5),
                            boxShadow: const [_shadowSm],
                          ),
                          child: Text(
                            medal.label,
                            style: _mono(color: Colors.white, size: 8, weight: FontWeight.w900, letterSpacing: 1.2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Contenido central ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar con borde duro neobrutalista
                        GestureDetector(
                          onTap: () => widget.onSelect?.call(champ.id),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: _border, width: 2),
                              boxShadow: const [_shadow],
                            ),
                            child: Stack(
                              children: [
                                RankAvatar(
                                  url: champ.avatarUrl,
                                  name: champ.name,
                                  size: 80,
                                  borderColor: medal.color,
                                  borderWidth: 3,
                                ),
                                // Overlay de color en esquina
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    color: medal.color,
                                    child: Text(
                                      '#${_active + 1}',
                                      style: _mono(color: Colors.white, size: 9, weight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Info principal
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                champ.name,
                                style: _mono(size: 18, weight: FontWeight.w900, color: _text),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Coronas — row de iconos
                              _CrownRow(count: champ.monthlyChampionships, color: medal.color),
                              const SizedBox(height: 10),
                              // Último título
                              if (champ.lastMonthYear != null) ...[
                                Row(
                                  children: [
                                    Container(width: 3, height: 12, color: medal.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ÚLT. TÍTULO',
                                      style: _mono(size: 7, weight: FontWeight.w700, letterSpacing: 1.4, color: _muted),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _card,
                                        border: Border.all(color: _border, width: 1.5),
                                      ),
                                      child: Text(
                                        champ.lastMonthYear!,
                                        style: _mono(size: 9, weight: FontWeight.w800, color: _text),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Stats grid (3 celdas) — bordes duros ──
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: _border, width: 2)),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          _StatCell(
                            value: '${champ.monthlyChampionships}',
                            label: 'CORONAS',
                            color: medal.color,
                            icon: Icons.workspace_premium_rounded,
                          ),
                          Container(width: 2, color: _border),
                          _StatCell(
                            value: champ.bestPoints > 0 ? _fmt(champ.bestPoints) : '—',
                            label: 'MAX PTS',
                            color: _accent,
                          ),
                          Container(width: 2, color: _border),
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

                  // ── Controles de navegación ──
                  Container(
                    decoration: const BoxDecoration(
                      color: _bg,
                      border: Border(top: BorderSide(color: _border, width: 2)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón anterior — caja sólida neobrutalista
                        _NavButton(
                          icon: Icons.arrow_back_ios_rounded,
                          onTap: () => _nav(-1),
                          enabled: total > 1,
                        ),
                        // Indicadores de punto
                        Row(
                          children: List.generate(total.clamp(0, 5), (i) {
                            final isActive = i == _active;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: isActive ? 20 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: isActive ? medal.color : _border.withOpacity(0.2),
                                border: Border.all(
                                  color: isActive ? _border : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                            );
                          }),
                        ),
                        // Botón siguiente
                        _NavButton(
                          icon: Icons.arrow_forward_ios_rounded,
                          onTap: () => _nav(1),
                          enabled: total > 1,
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

        // ── Lista de top 3 campeones — estilo tabla neobrutalista ──
        if (champions.length > 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _card,
              border: Border.all(color: _border, width: 2),
              boxShadow: const [_shadow],
            ),
            child: Column(
              children: [
                // Encabezado de tabla
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: _bg,
                    border: Border(bottom: BorderSide(color: _border, width: 2)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 4, height: 14, color: _gold),
                      const SizedBox(width: 8),
                      Text(
                        'TOP CAMPEONES',
                        style: _mono(size: 9, weight: FontWeight.w800, letterSpacing: 1.8, color: _text),
                      ),
                    ],
                  ),
                ),
                // Filas de campeones
                ...champions.take(3).toList().asMap().entries.map((e) {
                  final i      = e.key;
                  final u      = e.value;
                  final medal  = _medals[i];
                  final isAct  = i == _active;

                  return GestureDetector(
                    onTap: () => _nav(i > _active ? 1 : -1, target: i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isAct ? medal.color.withOpacity(0.06) : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(color: _border.withOpacity(0.3), width: 0.5),
                          left: BorderSide(
                            color: isAct ? medal.color : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      padding: EdgeInsets.only(
                        left: isAct ? 13 : 16,
                        right: 16,
                        top: 12,
                        bottom: 12,
                      ),
                      child: Row(
                        children: [
                          // Badge posición — caja sólida
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: medal.color,
                              border: Border.all(color: _border, width: 2),
                              boxShadow: const [_shadowSm],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: _mono(color: Colors.white, size: 10, weight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Avatar
                          RankAvatar(url: u.avatarUrl, name: u.name, size: 36),
                          const SizedBox(width: 10),

                          // Nombre + coronas
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.name,
                                  style: _mono(size: 13, weight: FontWeight.w700, color: _text),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.workspace_premium_rounded, size: 10, color: medal.color),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${u.monthlyChampionships} coronas',
                                      style: _mono(size: 9, weight: FontWeight.w700, color: medal.color),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Puntos máximos + tag
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    u.bestPoints > 0 ? _fmt(u.bestPoints) : '—',
                                    style: _mono(size: 16, weight: FontWeight.w900, color: medal.color),
                                  ),
                                  Text(
                                    'pts',
                                    style: _mono(size: 8, color: _muted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'mejor mes',
                                style: _mono(size: 7, color: _muted),
                              ),
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
        border: Border.all(color: _border, width: 2),
        boxShadow: const [_shadow],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _bg,
              border: Border.all(color: _border, width: 2),
              boxShadow: const [_shadowSm],
            ),
            child: const Icon(Icons.workspace_premium_rounded, size: 28, color: _gold),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 20, height: 2, color: _border),
              const SizedBox(width: 8),
              Text(
                'SIN CAMPEONES',
                style: _mono(size: 10, weight: FontWeight.w800, letterSpacing: 2, color: _text),
              ),
              const SizedBox(width: 8),
              Container(width: 20, height: 2, color: _border),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Aún no hay campeones registrados',
            style: _mono(color: _muted, size: 11),
          ),
        ],
      ),
    );
  }
}

// ── Botón de navegación — caja cuadrada neobrutalista ────────────────────────
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _NavButton({required this.icon, this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? _accent : _card,
          border: Border.all(color: _border, width: enabled ? 2 : 1.5),
          boxShadow: enabled ? const [_shadowSm] : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 13,
          color: enabled ? Colors.white : _muted,
        ),
      ),
    );
  }
}

// ── Crown Row ────────────────────────────────────────────────────────────────
class _CrownRow extends StatelessWidget {
  final int count;
  final Color color;
  const _CrownRow({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final show  = count.clamp(0, 6);
    final extra = count - 6;
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        for (int i = 0; i < show; i++)
          Icon(Icons.workspace_premium_rounded, size: 18, color: color),
        if (extra > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: _border, width: 1.5),
            ),
            child: Text(
              '+$extra',
              style: _mono(size: 9, weight: FontWeight.w800, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

// ── Stat Cell ────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? icon;
  final bool small;

  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
    this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (icon != null) ...[
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
                    style: _mono(size: 7, weight: FontWeight.w700, letterSpacing: 1.0, color: _muted),
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

// ── Utilidad ─────────────────────────────────────────────────────────────────
String _fmt(int n) {
  if (n >= 1000) {
    final k = n ~/ 1000;
    final r = n % 1000;
    return '$k.${r.toString().padLeft(3, '0')}';
  }
  return '$n';
}
