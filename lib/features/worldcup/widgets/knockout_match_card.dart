import 'package:flutter/material.dart';
import '../domain/worldcup_models.dart';

// ── Paleta ────────────────────────────────────────────────
const _accent  = Color(0xFF5B4FD8);
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFE8E4DC);
const _border  = Color(0xFF1A1A2E);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF88887D);
const _gold    = Color(0xFFF59E0B);
const _correct = Color(0xFF1D9E75);

class KnockoutMatchCard extends StatelessWidget {
  final KoMatchConfig match;
  final String? homeTeam;
  final String? awayTeam;
  final String? selectedWinner;
  final ValueChanged<String>? onSelect;
  final bool disabled;
  final String supabaseUrl;

  const KnockoutMatchCard({
    super.key,
    required this.match,
    required this.supabaseUrl,
    this.homeTeam,
    this.awayTeam,
    this.selectedWinner,
    this.onSelect,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _border, width: 1),
        boxShadow: const [BoxShadow(color: _muted, offset: Offset(2, 2), blurRadius: 0)],
      ),
      child: Column(
        children: [
          // ── Header
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: _card,
              border: Border(bottom: BorderSide(color: _border, width: 1)),
            ),
            child: Row(
              children: [
                Text(
                  match.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: _text,
                  ),
                ),
                const Spacer(),
                Text(
                  '#${match.id}',
                  style: const TextStyle(fontSize: 8, color: _muted),
                ),
              ],
            ),
          ),

          // ── Home
          _TeamOption(
            team: homeTeam,
            placeholder: match.home,
            desc: match.homeDesc,
            isSelected: selectedWinner != null && selectedWinner == homeTeam,
            onSelect: (!disabled && homeTeam != null) ? () => onSelect!(homeTeam!) : null,
            supabaseUrl: supabaseUrl,
          ),

          // ── VS divider
          Container(
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: _border, width: 0.5)),
            ),
            child: const Text(
              'VS',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2, color: _muted),
            ),
          ),

          // ── Away
          _TeamOption(
            team: awayTeam,
            placeholder: match.away,
            desc: match.awayDesc,
            isSelected: selectedWinner != null && selectedWinner == awayTeam,
            onSelect: (!disabled && awayTeam != null) ? () => onSelect!(awayTeam!) : null,
            supabaseUrl: supabaseUrl,
          ),

          // ── Winner footer
          if (selectedWinner != null)
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: _gold,
                border: Border(top: BorderSide(color: _border, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, size: 10, color: _border),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      selectedWinner!,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: _border,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamOption extends StatelessWidget {
  final String? team;
  final String placeholder;
  final String desc;
  final bool isSelected;
  final VoidCallback? onSelect;
  final String supabaseUrl;

  const _TeamOption({
    required this.team,
    required this.placeholder,
    required this.desc,
    required this.isSelected,
    required this.supabaseUrl,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final flagUrl = team != null ? getTeamFlagUrl(team!, supabaseUrl) : '';
    final canTap = onSelect != null;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _correct.withValues(alpha: 0.1)
              : canTap
                  ? _bg
                  : _card.withValues(alpha: 0.5),
        ),
        child: Row(
          children: [
            // Flag
            Container(
              width: 28,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? _correct : _border.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: team != null && flagUrl.isNotEmpty
                  ? Image.network(
                      flagUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 10, color: _muted),
                    )
                  : Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: _muted.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    team ?? placeholder,
                    style: TextStyle(
                      fontSize: team != null ? 12 : 10,
                      fontWeight: FontWeight.w700,
                      color: team != null ? _text : _muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (team == null && desc.isNotEmpty)
                    Text(desc,
                        style: const TextStyle(fontSize: 8, color: _muted),
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _correct,
                  border: Border.all(color: _border, width: 0.5),
                ),
                child: const Icon(Icons.check, size: 10, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}