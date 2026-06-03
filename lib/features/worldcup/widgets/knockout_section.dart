import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/worldcup_models.dart';
import '../domain/worldcup_providers.dart';
import 'knockout_match_card.dart';

// ── Paleta ────────────────────────────────────────────────
const _accent  = Color(0xFF5B4FD8);
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFE8E4DC);
const _border  = Color(0xFF1A1A2E);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF88887D);
const _gold    = Color(0xFFF59E0B);
const _exact   = Color(0xFFFF3C00);
const _correct = Color(0xFF1D9E75);

// ── Estructura bracket ────────────────────────────────────
const _r8 = [
  ('R8-1', 'Octavos 1', [1, 2]),
  ('R8-2', 'Octavos 2', [3, 4]),
  ('R8-3', 'Octavos 3', [5, 6]),
  ('R8-4', 'Octavos 4', [7, 8]),
  ('R8-5', 'Octavos 5', [9, 10]),
  ('R8-6', 'Octavos 6', [11, 12]),
  ('R8-7', 'Octavos 7', [13, 14]),
  ('R8-8', 'Octavos 8', [15, 16]),
];

const _quarters = [
  ('QF1', 'Cuarto 1', ['R8-1', 'R8-2']),
  ('QF2', 'Cuarto 2', ['R8-3', 'R8-4']),
  ('QF3', 'Cuarto 3', ['R8-5', 'R8-6']),
  ('QF4', 'Cuarto 4', ['R8-7', 'R8-8']),
];

const _semis = [
  ('SF1', 'Semifinal 1', ['QF1', 'QF2']),
  ('SF2', 'Semifinal 2', ['QF3', 'QF4']),
];

class KnockoutSection extends ConsumerWidget {
  final String supabaseUrl;
  const KnockoutSection({super.key, required this.supabaseUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state     = ref.watch(worldCupProvider);
    final notifier  = ref.read(worldCupProvider.notifier);
    final ko        = state.predictions.knockout;
    final groups    = state.predictions.groups;

    // Calcular clasificados desde grupos
    final qualified = <String, Map<String, String?>>{};
    for (final g in kGroupsData.keys) {
      final table = calcGroupTable(g, groups[g]);
      qualified[g] = {
        'first':  table.isNotEmpty ? table[0].team : null,
        'second': table.length > 1 ? table[1].team : null,
      };
    }
    final bestThirds = calcBestThirds(groups);
    final thirdsMap  = { for (final t in bestThirds) t.group: t.team };

    // Losers de semis para el 3er puesto
    final sf1Home = ko.quarters['QF1'];
    final sf1Away = ko.quarters['QF2'];
    final sf2Home = ko.quarters['QF3'];
    final sf2Away = ko.quarters['QF4'];

    final semi1Loser = calcSemiLoser(
      winner: ko.semis['SF1'],
      homeTeam: sf1Home,
      awayTeam: sf1Away,
    );
    final semi2Loser = calcSemiLoser(
      winner: ko.semis['SF2'],
      homeTeam: sf2Home,
      awayTeam: sf2Away,
    );

    return Column(
      children: [
        // ── Dieciseisavos de final (ronda 1: 16 partidos)
        _RoundSection(
          title: 'DIECISEISAVOS DE FINAL',
          color: _accent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 32) / 2.3;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: kRound16.map((m) {
                    final home = _resolveTeam(m.home, qualified, thirdsMap, ko);
                    final away = _resolveTeam(m.away, qualified, thirdsMap, ko);
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: cardWidth,
                        child: KnockoutMatchCard(
                          match: m,
                          homeTeam: home,
                          awayTeam: away,
                          selectedWinner: ko.round16[m.id],
                          onSelect: (team) => notifier.updateRound16(m.id, team),
                          supabaseUrl: supabaseUrl,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),

        // ── Octavos de final (ronda 2: 8 partidos)
        _RoundSection(
          title: 'OCTAVOS DE FINAL',
          color: _exact,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 32) / 2.3;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _r8.map((r) {
                    final (id, label, matchIds) = r;
                    final homeWinner = ko.round16[matchIds[0].toString()];
                    final awayWinner = ko.round16[matchIds[1].toString()];
                    final cfg = KoMatchConfig(
                      id: id,
                      home: 'Llave ${matchIds[0]}',
                      away: 'Llave ${matchIds[1]}',
                      label: label,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: cardWidth,
                        child: KnockoutMatchCard(
                          match: cfg,
                          homeTeam: homeWinner,
                          awayTeam: awayWinner,
                          selectedWinner: ko.round8[id],
                          onSelect: (team) => notifier.updateRound8(id, team),
                          supabaseUrl: supabaseUrl,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),

        // ── Cuartos de final
        _RoundSection(
          title: 'CUARTOS DE FINAL',
          color: _gold,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 32) / 2.3;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _quarters.map((q) {
                    final (id, label, r8Ids) = q;
                    final homW = ko.round8[r8Ids[0]];
                    final awyW = ko.round8[r8Ids[1]];
                    final cfg = KoMatchConfig(
                      id: id,
                      home: r8Ids[0],
                      away: r8Ids[1],
                      label: label,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: cardWidth,
                        child: KnockoutMatchCard(
                          match: cfg,
                          homeTeam: homW,
                          awayTeam: awyW,
                          selectedWinner: ko.quarters[id],
                          onSelect: (team) => notifier.updateQuarters(id, team),
                          supabaseUrl: supabaseUrl,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),

        // ── Semifinales
        _RoundSection(
          title: 'SEMIFINALES',
          color: _correct,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 32) / 2.3;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _semis.map((s) {
                    final (id, label, qfIds) = s;
                    final homW = ko.quarters[qfIds[0]];
                    final awyW = ko.quarters[qfIds[1]];
                    final cfg = KoMatchConfig(
                      id: id,
                      home: qfIds[0],
                      away: qfIds[1],
                      label: label,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: cardWidth,
                        child: KnockoutMatchCard(
                          match: cfg,
                          homeTeam: homW,
                          awayTeam: awyW,
                          selectedWinner: ko.semis[id],
                          onSelect: (team) => notifier.updateSemis(id, team),
                          supabaseUrl: supabaseUrl,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),

        // ── Tercer puesto + Final
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tercer puesto — FIX: usa calcSemiLoser en lugar de _getLoser null
              Expanded(
                child: _FinalMatch(
                  title: '3ER PUESTO',
                  color: _gold,
                  homeTeam: semi1Loser,
                  awayTeam: semi2Loser,
                  selected: ko.thirdPlace['final'],
                  onSelect: (t) => notifier.updateThirdPlace('final', t),
                  supabaseUrl: supabaseUrl,
                ),
              ),
              const SizedBox(width: 10),
              // Final
              Expanded(
                child: _FinalMatch(
                  title: 'FINAL',
                  color: _accent,
                  homeTeam: ko.semis['SF1'],
                  awayTeam: ko.semis['SF2'],
                  selected: ko.final_['final'],
                  onSelect: (t) => notifier.updateFinal('final', t),
                  supabaseUrl: supabaseUrl,
                  isFinal: true,
                ),
              ),
            ],
          ),
        ),

        // ── Campeón
        if (ko.final_['final'] != null)
          _ChampionBanner(team: ko.final_['final']!, supabaseUrl: supabaseUrl),

        const SizedBox(height: 20),
      ],
    );
  }

  String? _resolveTeam(
    String code,
    Map<String, Map<String, String?>> qualified,
    Map<String, String> thirds,
    KnockoutPredictions ko,
  ) {
    // Formato "X-1" o "X-2" → clasificado de grupo
    final parts = code.split('-');
    if (parts.length == 2 && !code.contains('3')) {
      final g = parts[0];
      final pos = parts[1];
      if (pos == '1') return qualified[g]?['first'];
      if (pos == '2') return qualified[g]?['second'];
    }
    // Formato "ABC...-3" → mejor tercero de esos grupos
    if (code.endsWith('-3')) {
      final groupLetters = code.replaceAll('-3', '').split('');
      for (final g in groupLetters) {
        if (thirds.containsKey(g)) return thirds[g];
      }
    }
    return null;
  }
}

// ── Sección de ronda ──────────────────────────────────────
class _RoundSection extends StatelessWidget {
  final String title;
  final Color color;
  final Widget child;
  const _RoundSection({required this.title, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: _card,
            border: Border(
              top: BorderSide(color: _border, width: 1),
              bottom: BorderSide(color: _border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(width: 4, height: 14, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: _text,
                  )),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

// ── Partido final / 3er puesto ────────────────────────────
class _FinalMatch extends StatelessWidget {
  final String title;
  final Color color;
  final String? homeTeam;
  final String? awayTeam;
  final String? selected;
  final ValueChanged<String>? onSelect;
  final String supabaseUrl;
  final bool isFinal;

  const _FinalMatch({
    required this.title,
    required this.color,
    required this.supabaseUrl,
    this.homeTeam,
    this.awayTeam,
    this.selected,
    this.onSelect,
    this.isFinal = false,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = KoMatchConfig(
      id: isFinal ? 'FINAL' : 'THIRD',
      home: isFinal ? 'SF1' : 'Perdedor SF1',
      away: isFinal ? 'SF2' : 'Perdedor SF2',
      label: title,
    );
    return Column(
      children: [
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: _border, width: 1),
          ),
          alignment: Alignment.center,
          child: Text(title,
              style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: _border,
              )),
        ),
        KnockoutMatchCard(
          match: cfg,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          selectedWinner: selected,
          onSelect: onSelect,
          supabaseUrl: supabaseUrl,
        ),
      ],
    );
  }
}

// ── Banner campeón ────────────────────────────────────────
class _ChampionBanner extends StatelessWidget {
  final String team;
  final String supabaseUrl;
  const _ChampionBanner({required this.team, required this.supabaseUrl});

  @override
  Widget build(BuildContext context) {
    final flagUrl = getTeamFlagUrl(team, supabaseUrl);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _gold,
        border: Border.all(color: _border, width: 2),
        boxShadow: const [BoxShadow(color: _muted, offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, size: 36, color: _border),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CAMPEÓN MUNDIAL 2026',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: _border)),
                Text(team,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.1, color: _border)),
              ],
            ),
          ),
          if (flagUrl.isNotEmpty)
            Container(
              width: 56,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: _border, width: 1.5),
              ),
              child: Image.network(flagUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
        ],
      ),
    );
  }
}