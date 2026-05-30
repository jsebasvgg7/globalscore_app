import 'package:flutter/material.dart';

class MatchCard extends StatefulWidget {
  final Map<String, dynamic> match;
  final Future<void> Function(String matchId, int home, int away, String? adv) onPredict;

  const MatchCard({super.key, required this.match, required this.onPredict});

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  late int _home;
  late int _away;
  String? _advancing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pred = widget.match['my_prediction'];
    _home = pred?['home_score'] ?? 0;
    _away = pred?['away_score'] ?? 0;
    _advancing = pred?['predicted_advancing_team'];
  }

  bool get _isDisabled {
    final deadline = widget.match['deadline'];
    final status = widget.match['status'];
    if (status != 'pending') return true;
    if (deadline == null) return false;
    return DateTime.now().isAfter(DateTime.parse(deadline));
  }

  bool get _hasPred => widget.match['my_prediction'] != null;
  bool get _isKnockout => widget.match['is_knockout'] == true;
  bool get _isLive => widget.match['status'] == 'live';

  Future<void> _save() async {
    if (_isDisabled || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onPredict(widget.match['id'], _home, _away, _advancing);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _pillLabel {
    if (_isLive) return 'EN VIVO';
    if (_isDisabled) return 'CERRADO';
    if (_saving) return 'GUARDANDO';
    if (_hasPred) return 'GUARDADO';
    return 'PENDIENTE';
  }

  Color get _pillColor {
    if (_isLive) return const Color(0xFFF59E0B);
    if (_isDisabled) return Colors.red.shade800;
    if (_saving) return Colors.blue;
    if (_hasPred) return const Color(0xFF34D399);
    return const Color(0xFF5B4FD8);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isLive ? const Color(0xFFF59E0B).withOpacity(0.4) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                if (m['league_logo_url'] != null)
                  Image.network(m['league_logo_url'], width: 16, height: 16,
                      errorBuilder: (_, __, ___) => const Text('🏆', style: TextStyle(fontSize: 14)))
                else
                  const Text('🏆', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    (m['league'] ?? 'Liga').toString().toUpperCase(),
                    style: const TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 0.8),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _pillColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_pillLabel,
                      style: TextStyle(color: _pillColor, fontSize: 8, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TeamRow(
                    name: m['home_team'] ?? '—',
                    logoUrl: m['home_team_logo_url'],
                    score: _home,
                    isDisabled: _isDisabled,
                    isAdvancing: _advancing == 'home',
                    isKnockout: _isKnockout,
                    onInc: () { setState(() { if (_home < 20) _home++; }); _save(); },
                    onDec: () { setState(() { if (_home > 0) _home--; }); _save(); },
                    onAdvTap: () {
                      if (!_isKnockout || _isDisabled) return;
                      setState(() => _advancing = _advancing == 'home' ? null : 'home');
                      _save();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white10)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _isKnockout && !_isDisabled ? '⚔' : 'VS',
                            style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.white10)),
                      ],
                    ),
                  ),
                  _TeamRow(
                    name: m['away_team'] ?? '—',
                    logoUrl: m['away_team_logo_url'],
                    score: _away,
                    isDisabled: _isDisabled,
                    isAdvancing: _advancing == 'away',
                    isKnockout: _isKnockout,
                    onInc: () { setState(() { if (_away < 20) _away++; }); _save(); },
                    onDec: () { setState(() { if (_away > 0) _away--; }); _save(); },
                    onAdvTap: () {
                      if (!_isKnockout || _isDisabled) return;
                      setState(() => _advancing = _advancing == 'away' ? null : 'away');
                      _save();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 10, color: Colors.white38),
                const SizedBox(width: 4),
                Text(m['time'] ?? '—', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(width: 8),
                Text(m['date'] ?? '—', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final int score;
  final bool isDisabled;
  final bool isAdvancing;
  final bool isKnockout;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onAdvTap;

  const _TeamRow({
    required this.name,
    this.logoUrl,
    required this.score,
    required this.isDisabled,
    required this.isAdvancing,
    required this.isKnockout,
    required this.onInc,
    required this.onDec,
    required this.onAdvTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Logo
        GestureDetector(
          onTap: onAdvTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isAdvancing ? const Color(0xFF00E5FF).withOpacity(0.15) : Colors.white10,
              borderRadius: BorderRadius.circular(6),
              border: isAdvancing ? Border.all(color: const Color(0xFF00E5FF), width: 1.5) : null,
            ),
            child: logoUrl != null
                ? Image.network(logoUrl!, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text('⚽', style: TextStyle(fontSize: 16)))
                : const Text('⚽', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 8),
        // Nombre
        Expanded(
          child: Text(name,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
        // Controles +/-
        Row(
          children: [
            _KeyBtn(symbol: '−', onTap: isDisabled || score <= 0 ? null : onDec),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$score',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            _KeyBtn(symbol: '+', onTap: isDisabled ? null : onInc, accent: true),
          ],
        ),
      ],
    );
  }
}

class _KeyBtn extends StatelessWidget {
  final String symbol;
  final VoidCallback? onTap;
  final bool accent;
  const _KeyBtn({required this.symbol, this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active
              ? (accent ? const Color(0xFF00E5FF).withOpacity(0.15) : Colors.white10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? Colors.white24 : Colors.white10),
        ),
        child: Text(symbol,
            style: TextStyle(
              color: active ? (accent ? const Color(0xFF00E5FF) : Colors.white70) : Colors.white24,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }
}