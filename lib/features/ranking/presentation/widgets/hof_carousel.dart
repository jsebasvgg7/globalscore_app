import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/ranking_service.dart';
import 'rank_avatar.dart';

const _kGold = Color(0xFFC9A227);
const _kSilver = Color(0xFF8A8A8A);
const _kBronze = Color(0xFFA0652A);

const _meta = [
  {'label': 'ORO', 'color': _kGold},
  {'label': 'PLATA', 'color': _kSilver},
  {'label': 'BRONCE', 'color': _kBronze},
];

class HofCarousel extends StatefulWidget {
  final List<HofChampion> champions;
  final void Function(String userId)? onSelect;

  const HofCarousel({
    super.key,
    required this.champions,
    this.onSelect,
  });

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
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
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
    if (champions.isEmpty) {
      return _buildEmpty();
    }

    final champ = champions[_active];
    final metaIdx = _active.clamp(0, 2);
    final color = _meta[metaIdx]['color'] as Color;
    final label = _meta[metaIdx]['label'] as String;
    final total = champions.length;

    return Column(
      children: [
        // ── Main card ──
        FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: color, width: 3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Card top row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: color,
                          fontFamily: 'DMMono',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        color: color,
                        child: Text(
                          '#${_active + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'DMMono',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Avatar
                GestureDetector(
                  onTap: () => widget.onSelect?.call(champ.id),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.5),
                          color,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: RankAvatar(
                        url: champ.avatarUrl, name: champ.name, size: 88),
                  ),
                ),
                const SizedBox(height: 12),

                // Name
                Text(
                  champ.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    fontFamily: 'DMMono',
                  ),
                ),
                const SizedBox(height: 8),

                // Crowns
                Wrap(
                  spacing: 4,
                  children: [
                    for (int i = 0;
                        i < champ.monthlyChampionships.clamp(0, 6);
                        i++)
                      Icon(Icons.workspace_premium_rounded,
                          size: 16, color: color),
                    if (champ.monthlyChampionships > 6)
                      Text(
                        '+${champ.monthlyChampionships - 6}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontFamily: 'DMMono',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Stats grid
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: Colors.black.withOpacity(0.07), width: 0.5),
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _statCell(
                          value: '${champ.monthlyChampionships}',
                          label: 'Coronas',
                          color: color,
                        ),
                        VerticalDivider(
                            width: 0.5,
                            color: Colors.black.withOpacity(0.07)),
                        _statCell(value: '—', label: 'Max pts'),
                        VerticalDivider(
                            width: 0.5,
                            color: Colors.black.withOpacity(0.07)),
                        _statCell(value: '—', label: 'Título', small: true),
                      ],
                    ),
                  ),
                ),

                // Counter
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 8),
                  child: Text(
                    '${_active + 1} / $total',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFFB0AAA0),
                      fontFamily: 'DMMono',
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Dots ──
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final isActive = i == _active;
            return GestureDetector(
              onTap: () => _nav(i > _active ? 1 : -1, target: i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 6,
                height: 6,
                color: isActive ? color : Colors.black.withOpacity(0.15),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        // ── Top 3 list ──
        if (champions.length >= 1) ...[
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
                  child: const Text(
                    'TOP CAMPEONES',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: Color(0xFFB0AAA0),
                      fontFamily: 'DMMono',
                    ),
                  ),
                ),
                ...champions.take(3).toList().asMap().entries.map((e) {
                  final i = e.key;
                  final u = e.value;
                  final m = _meta[i];
                  final c = m['color'] as Color;
                  final isActive = i == _active;
                  return GestureDetector(
                    onTap: () => _nav(i > _active ? 1 : -1, target: i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isActive
                            ? c.withOpacity(0.05)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.black.withOpacity(0.06),
                              width: 0.5),
                          left: BorderSide(
                            color: isActive ? c : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            color: c,
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'DMMono',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          RankAvatar(
                              url: u.avatarUrl, name: u.name, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A2E),
                                    fontFamily: 'DMMono',
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.workspace_premium_rounded,
                                        size: 10, color: c),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${u.monthlyChampionships} coronas',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: c,
                                        fontFamily: 'DMMono',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${u.monthlyChampionships} 👑',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: c,
                              fontFamily: 'DMMono',
                            ),
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
      ],
    );
  }

  Widget _statCell({
    required String value,
    required String label,
    Color? color,
    bool small = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: small ? 13 : 20,
                fontWeight: FontWeight.w800,
                color: color ?? const Color(0xFF1A1A2E),
                fontFamily: 'DMMono',
                letterSpacing: small ? 0 : -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFFB0AAA0),
                fontFamily: 'DMMono',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_rounded,
              size: 48, color: Colors.black.withOpacity(0.1)),
          const SizedBox(height: 12),
          const Text(
            'Aún no hay campeones registrados',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFB0AAA0),
              fontFamily: 'DMMono',
            ),
          ),
        ],
      ),
    );
  }
}

String _fmt(int n) {
  if (n >= 1000) {
    final k = n ~/ 1000;
    final r = n % 1000;
    return '$k.${r.toString().padLeft(3, '0')}';
  }
  return '$n';
}