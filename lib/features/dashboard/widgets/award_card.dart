import 'package:flutter/material.dart';

class AwardCard extends StatefulWidget {
  final Map<String, dynamic> award;
  final Future<void> Function(String awardId, String winner) onPredict;

  const AwardCard({super.key, required this.award, required this.onPredict});

  @override
  State<AwardCard> createState() => _AwardCardState();
}

class _AwardCardState extends State<AwardCard> {
  late final TextEditingController _winner;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pred = widget.award['my_prediction'];
    _winner = TextEditingController(text: pred?['predicted_winner'] ?? '');
  }

  @override
  void dispose() { _winner.dispose(); super.dispose(); }

  bool get _isDisabled {
    final deadline = widget.award['deadline'];
    if (widget.award['status'] == 'finished') return true;
    if (deadline == null) return false;
    return DateTime.now().isAfter(DateTime.parse(deadline));
  }

  Future<void> _save() async {
    if (_winner.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onPredict(widget.award['id'], _winner.text.trim());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.award;
    final hasPred = a['my_prediction'] != null;
    final isFinished = a['status'] == 'finished';

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Text(a['logo'] ?? '🏅', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['name'] ?? '—',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(a['season'] ?? '—',
                          style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GANADOR', style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _winner,
                    enabled: !_isDisabled,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0A0A0F),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      hintText: 'Nombre del ganador...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  if (isFinished && a['winner'] != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF34D399).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 14),
                          const SizedBox(width: 6),
                          Text('Ganador: ${a['winner']}',
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                  if (a['category'] != null) ...[
                    const SizedBox(height: 8),
                    Text('⭐ ${a['category']}',
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ],
              ),
            ),
          ),
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