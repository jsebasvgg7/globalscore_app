import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/worldcup_models.dart';
import '../domain/worldcup_providers.dart';

// ── Paleta ────────────────────────────────────────────────
const _accent   = Color(0xFF5B4FD8);
const _bg       = Color(0xFFF0EDE8);
const _card     = Color(0xFFE8E4DC);
const _border   = Color(0xFF1A1A2E);
const _text     = Color(0xFF1A1A2E);
const _muted    = Color(0xFF88887D);
const _shadow   = Color(0x8C1A1A2E);
const _gold     = Color(0xFFF59E0B);
const _correct  = Color(0xFF1D9E75);
const _red      = Color(0xFFFF3C00);
const _amber    = Color(0xFFFF9500);
const _blue     = Color(0xFF0099FF);

class AwardsSection extends ConsumerWidget {
  const AwardsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awards = ref.watch(worldCupProvider).predictions.awards;

    final individual = kAwardsConfig.where((a) =>
        ['topScorer', 'topAssist', 'goldenBall', 'bestYoungPlayer', 'goldenGlove'].contains(a.key)).toList();
    final teams = kAwardsConfig.where((a) =>
        ['surpriseTeam', 'disappointmentTeam'].contains(a.key)).toList();
    final players = kAwardsConfig.where((a) =>
        ['breakoutPlayer', 'disappointmentPlayer'].contains(a.key)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'PREMIOS INDIVIDUALES', color: _gold),
        ...individual.map((cfg) => _AwardInputRow(config: cfg, value: awards.getByKey(cfg.key))),

        _SectionHeader(title: 'PREMIOS POR SELECCIÓN', color: _accent),
        ...teams.map((cfg) => _AwardInputRow(config: cfg, value: awards.getByKey(cfg.key))),

        _SectionHeader(title: 'JUGADORES DESTACADOS', color: _correct),
        ...players.map((cfg) => _AwardInputRow(config: cfg, value: awards.getByKey(cfg.key))),

        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Header de sección ─────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: _card,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(width: 4, height: 14, color: color),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: _text,
              )),
        ],
      ),
    );
  }
}

// ── Fila de premio ────────────────────────────────────────
class _AwardInputRow extends ConsumerStatefulWidget {
  final AwardConfig config;
  final String value;
  const _AwardInputRow({required this.config, required this.value});

  @override
  ConsumerState<_AwardInputRow> createState() => _AwardInputRowState();
}

class _AwardInputRowState extends ConsumerState<_AwardInputRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_AwardInputRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
      _ctrl.selection = TextSelection.collapsed(offset: widget.value.length);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _iconColor {
    switch (widget.config.iconVariant) {
      case 'gold':  return _gold;
      case 'blue':  return _blue;
      case 'green': return _correct;
      case 'red':   return _red;
      case 'amber': return _amber;
      default:      return _accent;
    }
  }

  IconData get _icon {
    switch (widget.config.key) {
      case 'topScorer':            return Icons.sports_soccer;
      case 'topAssist':            return Icons.assistant;
      case 'goldenBall':           return Icons.emoji_events;
      case 'bestYoungPlayer':      return Icons.star;
      case 'goldenGlove':          return Icons.back_hand;
      case 'surpriseTeam':         return Icons.rocket_launch;
      case 'disappointmentTeam':   return Icons.sentiment_dissatisfied;
      case 'breakoutPlayer':       return Icons.bolt;
      case 'disappointmentPlayer': return Icons.trending_down;
      default:                     return Icons.sports;
    }
  }

  bool get _isFilled => _ctrl.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFilled ? _iconColor.withValues(alpha: 0.04) : _bg,
        border: const Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // ── Icono del premio
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isFilled ? _iconColor.withValues(alpha: 0.12) : _card,
              border: Border.all(color: _border, width: 1),
              boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)],
            ),
            child: Icon(_icon, size: 18, color: _isFilled ? _iconColor : _muted),
          ),
          const SizedBox(width: 12),

          // ── Labels + input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.config.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: _text,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _card,
                        border: Border.all(color: _border, width: 0.5),
                      ),
                      child: Text(
                        widget.config.category.toUpperCase(),
                        style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: _muted, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isFilled ? Colors.white : _bg,
                    border: Border.all(
                      color: _isFilled ? _iconColor : _border.withValues(alpha: 0.4),
                      width: _isFilled ? 1.5 : 1,
                    ),
                    boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)],
                  ),
                  child: TextField(
                    controller: _ctrl,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _isFilled ? _text : _muted,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.config.placeholder,
                      hintStyle: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      suffixIcon: _isFilled
                          ? GestureDetector(
                              onTap: () {
                                _ctrl.clear();
                                ref.read(worldCupProvider.notifier).updateAward(widget.config.key, '');
                                setState(() {});
                              },
                              child: const Icon(Icons.close, size: 14, color: _muted),
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      ref.read(worldCupProvider.notifier).updateAward(widget.config.key, v);
                      setState(() {});
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
          ),

          // ── Check si está lleno
          if (_isFilled) ...[
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _iconColor,
                border: Border.all(color: _border, width: 1),
              ),
              child: const Icon(Icons.check, size: 11, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}