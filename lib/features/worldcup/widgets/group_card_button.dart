import 'package:flutter/material.dart';
import '../domain/worldcup_models.dart';

const _accent  = Color(0xFF5B4FD8);
const _bg      = Color(0xFFF0EDE8); // crema base
const _card    = Color(0xFFE8E4DC); // crema oscura
const _border  = Color(0xFF1A1A2E);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF88887D);
const _shadow  = Color(0x8C1A1A2E);
const _gold    = Color(0xFFF59E0B);

class GroupCardButton extends StatelessWidget {
  final String group;
  final GroupPrediction? prediction;
  final String supabaseUrl;
  final VoidCallback onTap;

  const GroupCardButton({
    super.key,
    required this.group,
    required this.prediction,
    required this.supabaseUrl,
    required this.onTap,
  });

  List<String> get _teams => kGroupsData[group] ?? [];
  int get _filledMatches => prediction?.matches.values.where((m) => m.isFilled).length ?? 0;
  static const int _totalMatches = 6;
  bool get _isComplete => _filledMatches == _totalMatches;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _isComplete ? _accent.withValues(alpha: 0.06) : _bg,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            border: Border.all(color: _border, width: 1.5),
            boxShadow: const [
              BoxShadow(color: _shadow, offset: Offset(2, 2), blurRadius: 0),
            ],
          ),
        child: Row(
          children: [
            // ── Etiqueta grupo
            Container(
              width: 44,
              decoration: const BoxDecoration(
                color: _accent,
                border: Border(right: BorderSide(color: _border, width: 1.5)),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'GRP',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    group,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // ── Escudos (4 flags) — fondo crema
            Expanded(
              child: Container(
                color: _isComplete ? _accent.withValues(alpha: 0.06) : _bg,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: _teams.map((team) => Expanded(
                    child: _TeamFlag(
                      team: team,
                      supabaseUrl: supabaseUrl,
                    ),
                  )).toList(),
                ),
              ),
            ),

            // ── Indicador progreso + flecha — fondo crema
            Container(
              width: 52,
              decoration: BoxDecoration(
                color: _isComplete ? _accent.withValues(alpha: 0.06) : _bg,
                border: const Border(left: BorderSide(color: _border, width: 1)),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isComplete
                      ? Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _gold,
                            border: Border.all(color: _border, width: 1),
                          ),
                          child: const Icon(Icons.check, size: 12, color: _border),
                        )
                      : Text(
                          '$_filledMatches/$_totalMatches',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _muted,
                          ),
                        ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, size: 14, color: _muted),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _TeamFlag extends StatelessWidget {
  final String team;
  final String supabaseUrl;

  const _TeamFlag({required this.team, required this.supabaseUrl});

  String get _flagUrl => getTeamFlagUrl(team, supabaseUrl);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 20,
          decoration: BoxDecoration(
            border: Border.all(color: _border.withValues(alpha: 0.25), width: 0.5),
          ),
          child: _flagUrl.isNotEmpty
              ? Image.network(
                  _flagUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _FlagPlaceholder(),
                )
              : const _FlagPlaceholder(),
        ),
        const SizedBox(height: 3),
        Text(
          team.length > 5 ? '${team.substring(0, 4)}.' : team,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: _muted,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

class _FlagPlaceholder extends StatelessWidget {
  const _FlagPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      // FIX: fondo crema en lugar de _card gris
      color: _bg,
      child: const Icon(Icons.flag, size: 14, color: _muted),
    );
  }
}