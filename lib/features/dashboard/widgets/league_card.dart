import 'package:flutter/material.dart';

class LeagueCard extends StatefulWidget {
  final Map<String, dynamic> league;
  final Future<void> Function(String, String, String, String, String) onPredict;

  const LeagueCard({super.key, required this.league, required this.onPredict});

  @override
  State<LeagueCard> createState() => _LeagueCardState();
}

class _LeagueCardState extends State<LeagueCard> {
  late final TextEditingController _champion;
  late final TextEditingController _scorer;
  late final TextEditingController _assist;
  late final TextEditingController _mvp;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pred = widget.league['my_prediction'];
    _champion = TextEditingController(text: pred?['predicted_champion'] ?? '');
    _scorer = TextEditingController(text: pred?['predicted_top_scorer'] ?? '');
    _assist = TextEditingController(text: pred?['predicted_top_assist'] ?? '');
    _mvp = TextEditingController(text: pred?['predicted_mvp'] ?? '');
  }

  @override
  void dispose() {
    _champion.dispose(); _scorer.dispose(); _assist.dispose(); _mvp.dispose();
    super.dispose();
  }

  bool get _isDisabled {
    final deadline = widget.league['deadline'];
    if (widget.league['status'] == 'finished') return true;
    if (deadline == null) return false;
    return DateTime.now().isAfter(DateTime.parse(deadline));
  }

  Future<void> _save() async {
    if (_champion.text.trim().isEmpty || _scorer.text.trim().isEmpty ||
        _assist.text.trim().isEmpty || _mvp.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todas las predicciones')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onPredict(
        widget.league['id'],
        _champion.text.trim(),
        _scorer.text.trim(),
        _assist.text.trim(),
        _mvp.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.league;
    final hasPred = l['my_prediction'] != null;
    final isFinished = l['status'] == 'finished';

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Text(l['logo'] ?? '🏆', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l['name'] ?? '—',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(l['season'] ?? '—',
                          style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
                _StatusPill(
                  isFinished: isFinished,
                  isDisabled: _isDisabled,
                  hasPred: hasPred,
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // Fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _LeagueField(label: 'Campeón', controller: _champion, disabled: _isDisabled),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _LeagueField(label: 'Goleador', controller: _scorer, disabled: _isDisabled)),
                      const SizedBox(width: 8),
                      Expanded(child: _LeagueField(label: 'Asistidor', controller: _assist, disabled: _isDisabled)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _LeagueField(label: 'MVP', controller: _mvp, disabled: _isDisabled),
                ],
              ),
            ),
          ),
          // Footer
          if (!_isDisabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    _saving ? 'Guardando...' : (hasPred ? 'Actualizar' : 'Guardar'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeagueField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool disabled;
  const _LeagueField({required this.label, required this.controller, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: !disabled,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0A0A0F),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            hintText: '...',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isFinished;
  final bool isDisabled;
  final bool hasPred;
  const _StatusPill({required this.isFinished, required this.isDisabled, required this.hasPred});

  @override
  Widget build(BuildContext context) {
    final label = isFinished ? 'FINALIZADO' : isDisabled ? 'EXPIRADO' : hasPred ? 'GUARDADO' : 'PENDIENTE';
    final color = isFinished || isDisabled
        ? Colors.red.shade700
        : hasPred
            ? const Color(0xFF34D399)
            : const Color(0xFF5B4FD8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800)),
    );
  }
}