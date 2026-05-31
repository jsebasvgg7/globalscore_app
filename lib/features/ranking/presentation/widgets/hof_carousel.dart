import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/ranking_service.dart';
import 'rank_avatar.dart';

// ── Helpers de tipografía ──────────────────────────────────────────────────
TextStyle _mono({
  Color color = const Color(0xFF1A1A2E),
  double size = 12,
  FontWeight weight = FontWeight.normal,
  double letterSpacing = 0,
}) =>
    GoogleFonts.dmMono(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing);

// ── Colores ────────────────────────────────────────────────────────────────
const _kGold   = Color(0xFFC9A227);
const _kSilver = Color(0xFF8A8A8A);
const _kBronze = Color(0xFFA0652A);
const _kBg     = Color(0xFFF0EDE8);

const _medals = [
  _Medal('ORO',    _kGold),
  _Medal('PLATA',  _kSilver),
  _Medal('BRONCE', _kBronze),
];

class _Medal {
  final String label;
  final Color color;
  const _Medal(this.label, this.color);
}

// ══════════════════════════════════════════════════════════════════════════════
//  HOF CAROUSEL
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
  int _active = 0;
  bool _exiting = false;
  Timer? _timer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
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
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        final total = widget.champions.length;
        _active = target ?? ((_active + delta) % total + total) % total;
        _exiting = false;
      });
      _fadeCtrl.forward();
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeCtrl.dispose();
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
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
             color: const Color(0xFFF5F2EC),
              border: Border(top: BorderSide(color: medal.color, width: 3)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                // ── Fila superior: medalla + badge ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(medal.label,
                          style: _mono(
                              color: medal.color,
                              size: 11,
                              weight: FontWeight.w700,
                              letterSpacing: 1.4)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        color: medal.color,
                        child: Text('#${_active + 1}',
                            style: _mono(
                                color: Colors.white,
                                size: 10,
                                weight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),

                // ── Avatar circular con anillo de color ──
                GestureDetector(
                  onTap: () => widget.onSelect?.call(champ.id),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: medal.color, width: 3),
                    ),
                    child: RankAvatar(
                        url: champ.avatarUrl,
                        name: champ.name,
                        size: 88),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Nombre ──
                Text(champ.name,
                    style: _mono(
                        size: 18,
                        weight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E))),
                const SizedBox(height: 8),

                // ── Iconos de corona (sin emojis) ──
                _CrownRow(
                    count: champ.monthlyChampionships,
                    color: medal.color),
                const SizedBox(height: 14),

                // ── Stats grid ──
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: Colors.black.withOpacity(0.07),
                          width: 0.5),
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _StatCell(
                          value: '${champ.monthlyChampionships}',
                          label: 'CORONAS',
                          color: medal.color,
                        ),
                        VerticalDivider(
                            width: 0.5,
                            color: Colors.black.withOpacity(0.07)),
                        _StatCell(
                          value: champ.bestPoints > 0
                              ? _fmt(champ.bestPoints)
                              : '—',
                          label: 'MAX PTS',
                        ),
                        VerticalDivider(
                            width: 0.5,
                            color: Colors.black.withOpacity(0.07)),
                        _StatCell(
                          value: champ.lastMonthYear ?? '—',
                          label: 'TÍTULO',
                          small: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Contador ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 8),
                  child: Text('${_active + 1} / $total',
                      style: _mono(
                          color: const Color(0xFFB0AAA0),
                          size: 9,
                          letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ),

        // ── Dots ──────────────────────────────────────────────
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final isActive = i == _active;
            final dotColor = _medals[i.clamp(0, 2)].color;
            return GestureDetector(
              onTap: () => _nav(i > _active ? 1 : -1, target: i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 6,
                height: 6,
                color: isActive
                    ? dotColor
                    : Colors.black.withOpacity(0.15),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        // ── Top campeones ─────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  color: Colors.black.withOpacity(0.07), width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: const Color(0xFFE8E4DE),
                child: Text('TOP CAMPEONES',
                    style: _mono(
                        color: const Color(0xFFB0AAA0),
                        size: 9,
                        weight: FontWeight.w700,
                        letterSpacing: 1.4)),
              ),
              ...champions.take(3).toList().asMap().entries.map((e) {
                final i      = e.key;
                final u      = e.value;
                final medal  = _medals[i];
                final isActive = i == _active;

                return GestureDetector(
                  onTap: () =>
                      _nav(i > _active ? 1 : -1, target: i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isActive
                          ? medal.color.withOpacity(0.05)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.black.withOpacity(0.06),
                            width: 0.5),
                        left: BorderSide(
                          color: isActive
                              ? medal.color
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Badge número
                        Container(
                          width: 22,
                          height: 22,
                          color: medal.color,
                          alignment: Alignment.center,
                          child: Text('${i + 1}',
                              style: _mono(
                                  color: Colors.white,
                                  size: 10,
                                  weight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 10),

                        // Avatar circular
                        RankAvatar(
                            url: u.avatarUrl,
                            name: u.name,
                            size: 36),
                        const SizedBox(width: 10),

                        // Nombre + coronas
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(u.name,
                                  style: _mono(
                                      size: 13,
                                      weight: FontWeight.w700,
                                      color: const Color(
                                          0xFF1A1A2E))),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                      Icons
                                          .workspace_premium_rounded,
                                      size: 11,
                                      color: medal.color),
                                  const SizedBox(width: 3),
                                  Text(
                                      '${u.monthlyChampionships} coronas',
                                      style: _mono(
                                          size: 10,
                                          weight: FontWeight.w700,
                                          color: medal.color)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Puntos del mejor mes
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              u.bestPoints > 0
                                  ? _fmt(u.bestPoints)
                                  : '—',
                              style: _mono(
                                  size: 15,
                                  weight: FontWeight.w800,
                                  color: medal.color),
                            ),
                            Text('pts',
                                style: _mono(
                                    size: 8,
                                    color: const Color(
                                        0xFFB0AAA0))),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_rounded,
              size: 48,
              color: Colors.black.withOpacity(0.1)),
          const SizedBox(height: 12),
          Text('Aún no hay campeones registrados',
              style: _mono(
                  color: const Color(0xFFB0AAA0), size: 13)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CROWN ROW — iconos, sin emojis
// ══════════════════════════════════════════════════════════════════════════════
class _CrownRow extends StatelessWidget {
  final int count;
  final Color color;
  const _CrownRow({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final show = count.clamp(0, 6);
    final extra = count - 6;
    return Wrap(
      spacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < show; i++)
          Icon(Icons.workspace_premium_rounded,
              size: 18, color: color),
        if (extra > 0)
          Text('+$extra',
              style: _mono(
                  size: 12,
                  weight: FontWeight.w700,
                  color: color)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STAT CELL
// ══════════════════════════════════════════════════════════════════════════════
class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  final bool small;

  const _StatCell({
    required this.value,
    required this.label,
    this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: _mono(
                size: small ? 12 : 20,
                weight: FontWeight.w800,
                color: color ?? const Color(0xFF1A1A2E),
                letterSpacing: small ? 0 : -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: _mono(
                  size: 8,
                  weight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: const Color(0xFFB0AAA0)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Utilidad ──────────────────────────────────────────────────────────────────
String _fmt(int n) {
  if (n >= 1000) {
    final k = n ~/ 1000;
    final r = n % 1000;
    return '$k.${r.toString().padLeft(3, '0')}';
  }
  return '$n';
}