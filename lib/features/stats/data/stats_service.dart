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

    var query = _db
        .from('predictions')
        .select('points_earned, result_type, created_at, match_id')
        .eq('user_id', userId)
        .not('result_type', 'is', null); // solo finalizadas
    if (from != null) query = query.gte('created_at', from.toIso8601String());

    var pendingQuery = _db
        .from('predictions')
        .select('id')
        .eq('user_id', userId)
        .filter('result_type', 'is', 'null');
    if (from != null) pendingQuery = pendingQuery.gte('created_at', from.toIso8601String());

    var leagueQuery = _db
        .from('league_predictions')
        .select('points_earned')
        .eq('user_id', userId);
    if (from != null) leagueQuery = leagueQuery.gte('created_at', from.toIso8601String());

    var awardQuery = _db
        .from('award_predictions')
        .select('points_earned')
        .eq('user_id', userId);
    if (from != null) awardQuery = awardQuery.gte('created_at', from.toIso8601String());

    final results = await Future.wait<dynamic>([
      query,
      pendingQuery,
      leagueQuery,
      awardQuery,
    ]);
    final rows = results[0] as List;
    final pendingRows = results[1] as List;
    final leagueRows = results[2] as List;
    final awardRows = results[3] as List;

    return _compute(rows, pendingRows.length, leagueRows, awardRows);
  }

  StatsModel _compute(List rows, int pending, List leagueRows, List awardRows) {
    
    int exact = 0, correct = 0, wrong = 0, ptsMatches = 0;
    int currentStreak = 0, bestStreak = 0, tempStreak = 0;
    final Map<int, Map<String, int>> dayMap = {};

    // Ordenar por fecha desc para racha
    final sorted = [...rows];
    sorted.sort((a, b) {
      final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    for (int i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      final type = r['result_type'] as String? ?? '';
      final pts = (r['points_earned'] as num?)?.toInt() ?? 0;

      if (type == 'exact') {
        exact++;
      } else if (type == 'correct') {
        correct++;
      } else {
        wrong++;
      }
      ptsMatches += pts;

      // Racha
      final ok = type == 'exact' || type == 'correct';
      if (ok) {
        tempStreak++;
        if (i == 0) currentStreak = tempStreak;
        if (tempStreak > bestStreak) bestStreak = tempStreak;
      } else {
        if (i == 0) currentStreak = 0;
        tempStreak = 0;
      }

      // Por día
      final date = DateTime.tryParse(r['created_at'] ?? '');
      if (date != null) {
        final dow = date.weekday; // 1=Lun...7=Dom
        dayMap.putIfAbsent(dow, () => {'correct': 0, 'total': 0});
        dayMap[dow]!['total'] = dayMap[dow]!['total']! + 1;
        if (ok) dayMap[dow]!['correct'] = dayMap[dow]!['correct']! + 1;
      }
    }

    final totalFinished = rows.length;
    final accuracy = totalFinished > 0 ? (((exact + correct) / totalFinished) * 100).round() : 0;
    final exactAccuracy = totalFinished > 0 ? ((exact / totalFinished) * 100).round() : 0;

    int ptsLeagues = 0;
    for (final r in leagueRows) {
      ptsLeagues += ((r['points_earned'] as num?)?.toInt() ?? 0);
    }
    int ptsAwards = 0;
    for (final r in awardRows) {
      ptsAwards += ((r['points_earned'] as num?)?.toInt() ?? 0);
    }

    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final dayStats = List.generate(7, (i) {
      final dow = i + 1;
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
      leagueStats: [], // sin join a matches no tenemos liga por ahora
      dayStats: dayStats,
    );
  }
}