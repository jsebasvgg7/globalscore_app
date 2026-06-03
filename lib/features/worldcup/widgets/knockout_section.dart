import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/worldcup_models.dart';
import '../domain/worldcup_providers.dart';
import 'knockout_match_card.dart';

const _accent  = Color(0xFF2D0CFF);
const _bg      = Color(0xFFF5F0E8);
const _card    = Color(0xFFEDE7DA);
const _border  = Color(0xFF1A1A2E);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF555550);
const _gold    = Color(0xFFFFD600);
const _exact   = Color(0xFFFF3C00);
const _correct = Color(0xFF00C48C);

// ── Estructura bracket R8 ─────────────────────────────────────────────
const _r8 = [
  ('R8-1', 'Octavo 1', [1, 2]),
  ('R8-2', 'Octavo 2', [3, 4]),
  ('R8-3', 'Octavo 3', [5, 6]),
  ('R8-4', 'Octavo 4', [7, 8]),
  ('R8-5', 'Octavo 5', [9, 10]),
  ('R8-6', 'Octavo 6', [11, 12]),
  ('R8-7', 'Octavo 7', [13, 14]),
  ('R8-8', 'Octavo 8', [15, 16]),
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

    return Column(
      children: [
        _RoundSection(
          title: 'OCTAVOS DE FINAL',
          color: _accent,
          child: SingleChildScrollView(
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
                    width: 180,
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
          ),
        ),

        _RoundSection(
          title: 'OCTAVOS (ROUND OF 8)',
          color: _exact,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _r8.map((r) {
                final (id, label, matchIds) = r;
                final homeWinner = ko.round16[matchIds[0]];
                final awayWinner = ko.round16[matchIds[1]];
                final cfg = KoMatchConfig(id: id, home: 'G${matchIds[0]}', away: 'G${matchIds[1]}', label: label);
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 180,
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
          ),
        ),

        _RoundSection(
          title: 'CUARTOS DE FINAL',
          color: _gold,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _quarters.map((q) {
                final (id, label, octavosIds) = q;
                final homW = ko.round8[octavosIds[0]];
                final awyW = ko.round8[octavosIds[1]];
                final cfg = KoMatchConfig(id: id, home: octavosIds[0], away: octavosIds[1], label: label);
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 180,
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
          ),
        ),

        _RoundSection(
          title: 'SEMIFINALES',
          color: _correct,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _semis.map((s) {
                final (id, label, quartersIds) = s;
                final homW = ko.quarters[quartersIds[0]];
                final awyW = ko.quarters[quartersIds[1]];
                final cfg = KoMatchConfig(id: id, home: quartersIds[0], away: quartersIds[1], label: label);
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 180,
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
          ),
        ),

        // ── Tercer puesto + Final
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Tercer puesto
              Expanded(
                child: _FinalMatch(
                  title: '3ER PUESTO',
                  color: _gold,
                  homeTeam: _getLoser(ko.semis['SF1'], ko.semis, 'SF1', ko.quarters),
                  awayTeam: _getLoser(ko.semis['SF2'], ko.semis, 'SF2', ko.quarters),
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
        if (ko.final_['final'] != null) _ChampionBanner(team: ko.final_['final']!, supabaseUrl: supabaseUrl),
      ],
    );
  }

  String? _resolveTeam(
    String code,
    Map<String, Map<String, String?>> qualified,
    Map<String, String> thirds,
    KnockoutPredictions ko,
  ) {
    final parts = code.split('-');
    if (parts.length == 2) {
      final g = parts[0];
      final pos = parts[1];
      if (pos == '1') return qualified[g]?['first'];
      if (pos == '2') return qualified[g]?['second'];
    }
    if (code.contains('-3')) {
      // Best third from multiple groups — return first available
      final groups = code.replaceAll('-3', '').split('');
      for (final g in groups) {
        if (thirds.containsKey(g)) return thirds[g];
      }
    }
    return null;
  }

  String? _getLoser(String? winner, Map<String, String> semis, String semiId, Map<String, String> quarters) {
    // Find the loser of a semi: the other team that wasn't picked
    // This is simplified — in practice you'd track both teams per match
    return null; // Visual placeholder
  }
}

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
          decoration: BoxDecoration(
            color: _card,
            border: const Border(
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
      id: title,
      home: isFinal ? 'SF1' : 'SF1-loser',
      away: isFinal ? 'SF2' : 'SF2-loser',
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
