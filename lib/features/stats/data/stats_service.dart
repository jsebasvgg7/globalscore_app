import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/stats_model.dart';

class StatsService {
  final _db = Supabase.instance.client;

  Future<StatsModel> fetchStats(String userId, String timeRange) async {
    DateTime? from;
    final now = DateTime.now();
    if (timeRange == 'week') {
      from = now.subtract(const Duration(days: 7));
    } else if (timeRange == 'month') {
      from = DateTime(now.year, now.month, 1);
    }

    // ── predictions con join a matches (league es string, no FK)
    var query = _db
        .from('predictions')
        .select('home_score, away_score, created_at, matches(id, league, result_home, result_away, status, date)')
        .eq('user_id', userId);
    if (from != null) query = query.gte('created_at', from.toIso8601String());

    // ── league_predictions
    var leagueQuery = _db
        .from('league_predictions')
        .select('points_earned')
        .eq('user_id', userId);
    if (from != null) leagueQuery = leagueQuery.gte('created_at', from.toIso8601String());

    // ── award_predictions
    var awardQuery = _db
        .from('award_predictions')
        .select('points_earned')
        .eq('user_id', userId);
    if (from != null) awardQuery = awardQuery.gte('created_at', from.toIso8601String());

    final results = await Future.wait([query, leagueQuery, awardQuery]);
    final rows = results[0] as List;
    final leagueRows = results[1] as List;
    final awardRows = results[2] as List;

    return _compute(rows, leagueRows, awardRows);
  }

  StatsModel _compute(List rows, List leagueRows, List awardRows) {
    // Solo predicciones de partidos finalizados
    final finished = rows.where((r) {
      final status = r['matches']?['status'] as String?;
      return status == 'finished' || status == 'finalized';
    }).toList();

    int exact = 0, correct = 0, wrong = 0, ptsMatches = 0;
    int currentStreak = 0, bestStreak = 0, tempStreak = 0;
    final Map<String, Map<String, int>> leagueMap = {};
    final Map<int, Map<String, int>> dayMap = {};

    // Ordenar por fecha desc para calcular racha igual que React
    final sorted = [...finished];
    sorted.sort((a, b) {
      final da = DateTime.tryParse(a['matches']?['date'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['matches']?['date'] ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    for (int i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      final m = r['matches'] as Map?;
      if (m == null) continue;

      final predHome = (r['home_score'] as num?)?.toInt() ?? -1;
      final predAway = (r['away_score'] as num?)?.toInt() ?? -1;
      final resHome = (m['result_home'] as num?)?.toInt() ?? -2;
      final resAway = (m['result_away'] as num?)?.toInt() ?? -2;

      final predDir = (predHome - predAway).sign;
      final resDir = (resHome - resAway).sign;

      final isExact = predHome == resHome && predAway == resAway;
      final isCorrect = !isExact && predDir == resDir;

      if (isExact) {
        exact++;
        ptsMatches += 5;
      } else if (isCorrect) {
        correct++;
        ptsMatches += 3;
      } else {
        wrong++;
      }

      // Racha
      final ok = isExact || isCorrect;
      if (ok) {
        tempStreak++;
        if (i == 0) currentStreak = tempStreak;
        if (tempStreak > bestStreak) bestStreak = tempStreak;
      } else {
        if (i == 0) currentStreak = 0;
        tempStreak = 0;
      }

      // Por liga (league es string directo)
      final leagueName = (m['league'] as String?) ?? 'Sin liga';
      leagueMap.putIfAbsent(leagueName, () => {'pts': 0, 'total': 0, 'correct': 0, 'exact': 0});
      leagueMap[leagueName]!['pts'] = leagueMap[leagueName]!['pts']! + (isExact ? 5 : isCorrect ? 3 : 0);
      leagueMap[leagueName]!['total'] = leagueMap[leagueName]!['total']! + 1;
      if (isExact || isCorrect) leagueMap[leagueName]!['correct'] = leagueMap[leagueName]!['correct']! + 1;
      if (isExact) leagueMap[leagueName]!['exact'] = leagueMap[leagueName]!['exact']! + 1;

      // Por día
      final date = DateTime.tryParse(m['date'] ?? '');
      if (date != null) {
        final dow = date.weekday; // 1=Lun...7=Dom
        dayMap.putIfAbsent(dow, () => {'correct': 0, 'total': 0});
        dayMap[dow]!['total'] = dayMap[dow]!['total']! + 1;
        if (ok) dayMap[dow]!['correct'] = dayMap[dow]!['correct']! + 1;
      }
    }

    final totalFinished = finished.length;
    final pending = rows.length - totalFinished;
    final accuracy = totalFinished > 0 ? (((exact + correct) / totalFinished) * 100).round() : 0;
    final exactAccuracy = totalFinished > 0 ? ((exact / totalFinished) * 100).round() : 0;

    // Puntos de ligas y premios
    int ptsLeagues = 0;
    for (final r in leagueRows) {
      ptsLeagues += ((r['points_earned'] as num?)?.toInt() ?? 0);
    }
    int ptsAwards = 0;
    for (final r in awardRows) {
      ptsAwards += ((r['points_earned'] as num?)?.toInt() ?? 0);
    }

    // League stats ordenadas por puntos, top 5
    final leagueStats = leagueMap.entries.map((e) {
      final total = e.value['total']!;
      final acc = total > 0 ? ((e.value['correct']! / total) * 100).round() : 0;
      return LeagueStat(
        name: e.key,
        points: e.value['pts']!,
        accuracy: acc,
        exact: e.value['exact']!,
      );
    }).toList()
      ..sort((a, b) => b.points.compareTo(a.points));

    // Day stats: React usa [Dom,Lun,...Sáb] con getDay() (0=Dom)
    // Luego hace slice(1) + [0] → [Lun,Mar,Mié,Jue,Vie,Sáb,Dom]
    // Flutter weekday: 1=Lun...7=Dom → mismo orden final
    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final dayStats = List.generate(7, (i) {
      final dow = i + 1; // 1=Lun...7=Dom
      final d = dayMap[dow] ?? {'correct': 0, 'total': 0};
      return DayStat(name: dayNames[i], correct: d['correct']!, total: d['total']!);
    });

    return StatsModel(
      totalPredictions: totalFinished,
      pendingPredictions: pending,
      exact: exact,
      correctResult: correct,
      wrong: wrong,
      accuracy: accuracy,
      exactAccuracy: exactAccuracy,
      totalPoints: ptsMatches,
      pointsFromMatches: ptsMatches,
      pointsFromLeagues: ptsLeagues,
      pointsFromAwards: ptsAwards,
      leaguePredictions: leagueRows.length,
      awardPredictions: awardRows.length,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      leagueStats: leagueStats.take(5).toList(),
      dayStats: dayStats,
    );
  }
}