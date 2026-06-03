import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/stats_model.dart';

class StatsService {
  final _db = Supabase.instance.client;

  Future<StatsModel> fetchStats(String userId, String timeRange) async {
    final from = _rangeStart(timeRange);

    print('╔══ STATS FETCH ══════════════════════════');
    print('║ timeRange : $timeRange');
    print('║ from (UTC): $from');

    List r0 = [], r1 = [], r2 = [], r3 = [];

    try {
      r0 = await _queryFinished(userId, from);
      print('║ [OK] predictions finished: ${r0.length}');
    } catch (e) {
      print('║ [ERR] predictions finished: $e');
    }

    try {
      r1 = await _queryPending(userId, from);
      print('║ [OK] predictions pending: ${r1.length}');
    } catch (e) {
      print('║ [ERR] predictions pending: $e');
    }

    try {
      r2 = await _queryLeagues(userId, from);
      print('║ [OK] league_predictions: ${r2.length}');
    } catch (e) {
      print('║ [ERR] league_predictions: $e');
    }

    try {
      r3 = await _queryAwards(userId, from);
      print('║ [OK] award_predictions: ${r3.length}');
    } catch (e) {
      print('║ [ERR] award_predictions: $e');
    }

    if (r0.isNotEmpty) {
      print('║ muestra[0]: ${r0.first}');
    }
    print('╚════════════════════════════════════════');

    return _compute(
      rows:         r0,
      pendingCount: r1.length,
      leagueRows:   r2,
      awardRows:    r3,
    );
  }

  DateTime? _rangeStart(String timeRange) {
    final now = DateTime.now().toUtc();
    return switch (timeRange) {
      'week'  => DateTime.utc(now.year, now.month, now.day)
                   .subtract(const Duration(days: 6)),
      'month' => DateTime.utc(now.year, now.month, 1),
      _       => null,
    };
  }

  // FIX: se añade advancing_points al select para calcular puntos correctamente
  Future<List> _queryFinished(String userId, DateTime? from) {
    if (from == null) {
      return _db
          .from('predictions')
          .select('points_earned, advancing_points, result_type, created_at, matches!inner(league, is_knockout, deadline)')
          .eq('user_id', userId)
          .filter('result_type', 'not.is', 'null');
    }
    return _db
        .from('predictions')
        .select('points_earned, advancing_points, result_type, created_at, matches!inner(league, is_knockout, deadline)')
        .eq('user_id', userId)
        .filter('result_type', 'not.is', 'null')
        .gte('matches.deadline', from.toIso8601String());
  }

  Future<List> _queryPending(String userId, DateTime? from) {
    if (from == null) {
      return _db
          .from('predictions')
          .select('id')
          .eq('user_id', userId)
          .filter('result_type', 'is', 'null');
    }
    return _db
        .from('predictions')
        .select('id, matches!inner(deadline)')
        .eq('user_id', userId)
        .filter('result_type', 'is', 'null')
        .gte('matches.deadline', from.toIso8601String());
  }

  // FIX: se añade leagues(name) para poder agrupar leagueStats por nombre
  Future<List> _queryLeagues(String userId, DateTime? from) {
    var q = _db
        .from('league_predictions')
        .select('points_earned, created_at, leagues(name)')
        .eq('user_id', userId);
    if (from != null) q = q.gte('created_at', from.toIso8601String());
    return q;
  }

  Future<List> _queryAwards(String userId, DateTime? from) {
    var q = _db
        .from('award_predictions')
        .select('points_earned, created_at')
        .eq('user_id', userId);
    if (from != null) q = q.gte('created_at', from.toIso8601String());
    return q;
  }

  StatsModel _compute({
    required List rows,
    required int pendingCount,
    required List leagueRows,
    required List awardRows,
  }) {
    int exact = 0, correct = 0, wrong = 0, ptsMatches = 0;
    final Map<int, Map<String, int>> dayMap = {};

    // Ordenar por created_at desc para calcular racha desde el más reciente
    final sorted = [...rows]..sort((a, b) {
        final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });

    int currentStreak = 0, bestStreak = 0, tempStreak = 0;
    bool streakBroken = false;

    for (final r in sorted) {
      final type   = r['result_type'] as String? ?? '';
      // FIX: sumar points_earned + advancing_points para incluir los 2pts extra
      // de partidos eliminatorios al total de puntos
      final pts    = ((r['points_earned'] as num?)?.toInt() ?? 0)
                   + ((r['advancing_points'] as num?)?.toInt() ?? 0);
      final isHit  = type == 'exact' || type == 'correct';

      if (type == 'exact')        { exact++; }
      else if (type == 'correct') { correct++; }
      else                        { wrong++; }

      ptsMatches += pts;

      // Racha actual: consecutivos desde la predicción más reciente
      if (!streakBroken) {
        if (isHit) { currentStreak++; } else { streakBroken = true; }
      }

      // Mejor racha histórica
      if (isHit) {
        tempStreak++;
        if (tempStreak > bestStreak) bestStreak = tempStreak;
      } else {
        tempStreak = 0;
      }

      // Mapa por día de semana (weekday: 1=Lun … 7=Dom, igual que Dart)
      final date = DateTime.tryParse(r['created_at'] ?? '');
      if (date != null) {
        final dow = date.weekday;
        dayMap.putIfAbsent(dow, () => {'correct': 0, 'total': 0});
        dayMap[dow]!['total'] = dayMap[dow]!['total']! + 1;
        if (isHit) dayMap[dow]!['correct'] = dayMap[dow]!['correct']! + 1;
      }
    }

    final total         = rows.length;
    final accuracy      = total > 0 ? (((exact + correct) / total) * 100).round() : 0;
    final exactAccuracy = total > 0 ? ((exact / total) * 100).round() : 0;

    final ptsLeagues = leagueRows.fold<int>(
        0, (s, r) => s + ((r['points_earned'] as num?)?.toInt() ?? 0));
    final ptsAwards  = awardRows.fold<int>(
        0, (s, r) => s + ((r['points_earned'] as num?)?.toInt() ?? 0));

    // FIX: construir leagueStats agrupando por nombre de liga
    // usando points_earned + advancing_points de la DB
    final Map<String, Map<String, dynamic>> leagueMap = {};
    for (final r in rows) {
      final leagueName = (r['matches'] as Map?)?['league'] as String?;
      if (leagueName == null || leagueName.isEmpty) continue;

      leagueMap.putIfAbsent(leagueName, () => {
        'total': 0, 'correct': 0, 'exact': 0, 'points': 0,
      });

      final type   = r['result_type'] as String? ?? '';
      final pts    = ((r['points_earned'] as num?)?.toInt() ?? 0)
                   + ((r['advancing_points'] as num?)?.toInt() ?? 0);
      final isHit  = type == 'exact' || type == 'correct';

      leagueMap[leagueName]!['total']  = leagueMap[leagueName]!['total']!  + 1;
      leagueMap[leagueName]!['points'] = leagueMap[leagueName]!['points']! + pts;
      if (isHit)           leagueMap[leagueName]!['correct'] = leagueMap[leagueName]!['correct']! + 1;
      if (type == 'exact') leagueMap[leagueName]!['exact']   = leagueMap[leagueName]!['exact']!   + 1;
    }

    final leagueStats = leagueMap.entries.map((e) {
      final s        = e.value;
      final t        = s['total'] as int;
      final accuracy = t > 0 ? (((s['correct'] as int) / t) * 100).round() : 0;
      return LeagueStat(
        name:     e.key,
        points:   s['points'] as int,
        exact:    s['exact']  as int,
        accuracy: accuracy,
      );
    }).toList()
      ..sort((a, b) => b.points.compareTo(a.points));

    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final dayStats = List.generate(7, (i) {
      final d = dayMap[i + 1] ?? {'correct': 0, 'total': 0};
      return DayStat(
        name:    dayNames[i],
        correct: d['correct']!,
        total:   d['total']!,
      );
    });

    return StatsModel(
      totalPredictions:   total,
      pendingPredictions: pendingCount,
      exact:              exact,
      correctResult:      correct,
      wrong:              wrong,
      accuracy:           accuracy,
      exactAccuracy:      exactAccuracy,
      // FIX: totalPoints refleja solo partidos; totalPts del modelo suma los 3
      totalPoints:        ptsMatches,
      pointsFromMatches:  ptsMatches,
      pointsFromLeagues:  ptsLeagues,
      pointsFromAwards:   ptsAwards,
      leaguePredictions:  leagueRows.length,
      awardPredictions:   awardRows.length,
      currentStreak:      currentStreak,
      bestStreak:         bestStreak,
      leagueStats:        leagueStats,
      dayStats:           dayStats,
    );
  }
}