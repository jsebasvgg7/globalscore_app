import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/worldcup_models.dart';
import '../domain/worldcup_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Paleta unificada
const _accent   = Color(0xFF5B4FD8);
const _correct  = Color(0xFF1D9E75);
const _bg       = Color(0xFFF0EDE8);
const _card     = Color(0xFFE8E4DC);
const _border   = Color(0xFF1A1A2E);
const _text     = Color(0xFF1A1A2E);
const _muted    = Color(0xFF88887D);
const _shadow   = Color(0x8C1A1A2E);
const _gold     = Color(0xFFF59E0B);

void showGroupModal(BuildContext context, String group, String supabaseUrl) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GroupModal(group: group, supabaseUrl: supabaseUrl),
  );
}

class _GroupModal extends ConsumerWidget {
  final String group;
  final String supabaseUrl;

  const _GroupModal({required this.group, required this.supabaseUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(worldCupProvider);
    final pred  = state.predictions.groups[group];
    final table = calcGroupTable(group, pred);
    final teams = kGroupsData[group] ?? [];

    final matches = [
      [teams[0], teams[1]], [teams[2], teams[3]],
      [teams[0], teams[2]], [teams[1], teams[3]],
      [teams[0], teams[3]], [teams[1], teams[2]],
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: _bg,
          border: Border(
            top: BorderSide(color: _border, width: 2),
            left: BorderSide(color: _border, width: 2),
            right: BorderSide(color: _border, width: 2),
          ),
          boxShadow: [BoxShadow(color: _shadow, offset: Offset(0, -3), blurRadius: 0)],
        ),
        child: Column(
          children: [
            // ── Handle / header
            Container(
              width: double.infinity,
              height: 44,
              decoration: const BoxDecoration(
                color: _accent,
                border: Border(bottom: BorderSide(color: _border, width: 1.5)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'GRUPO ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
                      ),
                      Text(
                        group,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: _gold),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.zero,
                children: [
                  // ── Tabla del grupo
                  _GroupTable(table: table, supabaseUrl: supabaseUrl),

                  // ── Divisor sección partidos
                  Container(
                    height: 36,
                    color: _bg,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(width: 4, height: 14, color: _accent),
                        const SizedBox(width: 8),
                        const Text(
                          'PREDICCIONES DE PARTIDOS',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: _text),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: _border),

                  // ── Lista de partidos
                  ...List.generate(matches.length, (i) => _MatchRow(
                    group: group,
                    matchIdx: i,
                    home: matches[i][0],
                    away: matches[i][1],
                    prediction: pred?.matches[i] ?? const MatchPrediction(),
                    supabaseUrl: supabaseUrl,
                  )),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tabla del grupo ───────────────────────────────────────
class _GroupTable extends StatelessWidget {
  final List<GroupTableRow> table;
  final String supabaseUrl;
  const _GroupTable({required this.table, required this.supabaseUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 28,
          color: _bg,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const Row(
            children: [
              SizedBox(width: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Equipo', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: _muted))),
              SizedBox(width: 24, child: Text('J', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _muted))),
              SizedBox(width: 24, child: Text('G', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _muted))),
              SizedBox(width: 24, child: Text('GD', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _muted))),
              SizedBox(width: 28, child: Text('PTS', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _muted))),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _border),
        ...table.asMap().entries.map((e) => _TableRow(
          rank: e.key + 1,
          row: e.value,
          supabaseUrl: supabaseUrl,
        )),
        const Divider(height: 1, thickness: 1, color: _border),
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  final int rank;
  final GroupTableRow row;
  final String supabaseUrl;
  const _TableRow({required this.rank, required this.row, required this.supabaseUrl});

  Color get _rankColor {
    if (rank == 1) return _accent;
    if (rank == 2) return const Color(0xFF7B61FF);
    if (rank == 3) return _gold;
    return _muted;
  }

  bool get _advances => rank <= 2;

  @override
  Widget build(BuildContext context) {
    final flagUrl = getTeamFlagUrl(row.team, supabaseUrl);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _advances ? _accent.withValues(alpha: 0.03) : _bg,
        border: const Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: _rankColor, border: Border.all(color: _border, width: 0.5)),
            alignment: Alignment.center,
            child: Text('$rank', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 20,
            decoration: BoxDecoration(border: Border.all(color: _border.withValues(alpha: 0.2), width: 0.5)),
            child: flagUrl.isNotEmpty
                ? Image.network(flagUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 10, color: _muted))
                : const Icon(Icons.flag, size: 10, color: _muted),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(row.team,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _text),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(width: 24, child: Text('${row.played}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: _muted))),
          SizedBox(width: 24, child: Text('${row.won}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: _muted))),
          SizedBox(width: 24, child: Text(
            row.gd >= 0 ? '+${row.gd}' : '${row.gd}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: row.gd > 0 ? _correct : row.gd < 0 ? Colors.red : _muted),
          )),
          SizedBox(width: 28, child: Text('${row.pts}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _text))),
        ],
      ),
    );
  }
}

// ── Fila de partido ───────────────────────────────────────
class _MatchRow extends ConsumerStatefulWidget {
  final String group;
  final int matchIdx;
  final String home;
  final String away;
  final MatchPrediction prediction;
  final String supabaseUrl;

  const _MatchRow({
    required this.group,
    required this.matchIdx,
    required this.home,
    required this.away,
    required this.prediction,
    required this.supabaseUrl,
  });

  @override
  ConsumerState<_MatchRow> createState() => _MatchRowState();
}

class _MatchRowState extends ConsumerState<_MatchRow> {
  late TextEditingController _homeCtrl;
  late TextEditingController _awayCtrl;
  final _homeFocus = FocusNode();
  final _awayFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _homeCtrl = TextEditingController(text: widget.prediction.homeScore);
    _awayCtrl = TextEditingController(text: widget.prediction.awayScore);
  }

  @override
  void didUpdateWidget(_MatchRow old) {
    super.didUpdateWidget(old);
    // FIX: siempre llamar setState después de actualizar los controllers
    bool needsRebuild = false;
    if (old.prediction.homeScore != widget.prediction.homeScore &&
        _homeCtrl.text != widget.prediction.homeScore) {
      _homeCtrl.text = widget.prediction.homeScore;
      _homeCtrl.selection = TextSelection.collapsed(offset: widget.prediction.homeScore.length);
      needsRebuild = true;
    }
    if (old.prediction.awayScore != widget.prediction.awayScore &&
        _awayCtrl.text != widget.prediction.awayScore) {
      _awayCtrl.text = widget.prediction.awayScore;
      _awayCtrl.selection = TextSelection.collapsed(offset: widget.prediction.awayScore.length);
      needsRebuild = true;
    }
    if (needsRebuild) setState(() {});
  }

  @override
  void dispose() {
    _homeCtrl.dispose();
    _awayCtrl.dispose();
    _homeFocus.dispose();
    _awayFocus.dispose();
    super.dispose();
  }

  void _update() {
    ref.read(worldCupProvider.notifier).updateGroupMatch(
      widget.group,
      widget.matchIdx,
      MatchPrediction(homeScore: _homeCtrl.text, awayScore: _awayCtrl.text),
    );
  }

  bool get _isFilled => _homeCtrl.text.isNotEmpty && _awayCtrl.text.isNotEmpty;

  String _shortName(String team) {
    const abbr = {
      'Korea Republic': 'KOR', 'South Africa': 'RSA', 'Saudi Arabia': 'KSA',
      'Ivory Coast': 'CIV', 'New Zealand': 'NZL', 'Cabo Verde': 'CPV',
      'Netherlands': 'NED',
    };
    return abbr[team] ?? (team.length > 8 ? team.substring(0, 7) : team);
  }

  @override
  Widget build(BuildContext context) {
    final homeFlag = getTeamFlagUrl(widget.home, widget.supabaseUrl);
    final awayFlag = getTeamFlagUrl(widget.away, widget.supabaseUrl);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _isFilled ? _correct.withValues(alpha: 0.04) : _bg,
        border: const Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        children: [
          // ── Home
          Expanded(
            child: Row(
              children: [
                _Flag(url: homeFlag),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(_shortName(widget.home),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _text),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),

          // ── Score inputs
          Row(
            children: [
              _ScoreInput(
                controller: _homeCtrl,
                focusNode: _homeFocus,
                onChanged: (_) {
                  _update();
                  setState(() {}); // rebuild borde
                  if (_homeCtrl.text.isNotEmpty) _awayFocus.requestFocus();
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('–', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _muted)),
              ),
              _ScoreInput(
                controller: _awayCtrl,
                focusNode: _awayFocus,
                onChanged: (_) {
                  _update();
                  setState(() {}); // rebuild borde
                },
              ),
            ],
          ),

          // ── Away
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(_shortName(widget.away),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _text),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                _Flag(url: awayFlag),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  final String url;
  const _Flag({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(color: _border.withValues(alpha: 0.2), width: 0.5),
      ),
      child: url.isNotEmpty
          ? Image.network(url, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 10, color: _muted))
          : const Icon(Icons.flag, size: 10, color: _muted),
    );
  }
}

class _ScoreInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _ScoreInput({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: controller.text.isNotEmpty ? _correct.withValues(alpha: 0.1) : Colors.white,
        border: Border.all(
          color: controller.text.isNotEmpty ? _correct : _border.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 2,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: controller.text.isNotEmpty ? _correct : _text,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}