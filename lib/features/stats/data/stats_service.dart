import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/stats_model.dart';

class StatsService {
  final _db = Supabase.instance.client;

  Future<StatsModel> fetchStats(String userId, String timeRange) async {
    final from = _rangeStart(timeRange);

    final results = await Future.wait<dynamic>([
      _queryFinished(userId, from),
      _queryPending(userId, from),
      _queryLeagues(userId, from),
      _queryAwards(userId, from),
    ]);

    // ── DEBUG TEMPORAL ──────────────────────────────
    final r0 = results[0] as List;
    final r1 = results[1] as List;
    final r2 = results[2] as List;
    final r3 = results[3] as List;
    // ────────────────────────────────────────────────

    return _compute(
      rows:         r0,
      pendingCount: r1.length,
      leagueRows:   r2,
      awardRows:    r3,
    );
  }
  
  // ── Queries ────────────────────────────────────────────────────────────

  DateTime? _rangeStart(String timeRange) {
    final now = DateTime.now();
    return switch (timeRange) {
      'week'  => now.subtract(const Duration(days: 7)),
      'month' => DateTime(now.year, now.month, 1),
      _       => null,
    };
  }

  Future<List> _queryFinished(String userId, DateTime? from) {
    var q = _db
        .from('predictions')
        .select('points_earned, result_type, created_at')
        .eq('user_id', userId)
        .filter('result_type', 'not.is', 'null');
    if (from != null) q = q.gte('created_at', from.toIso8601String());
    return q;
  }

  Future<List> _queryPending(String userId, DateTime? from) {
    var q = _db
        .from('predictions')
        .select('id')
        .eq('user_id', userId)
        .filter('result_type', 'is', 'null');
    if (from != null) q = q.gte('created_at', from.toIso8601String());
    return q;
  }

  Future<List> _queryLeagues(String userId, DateTime? from) {
    var q = _db
        .from('league_predictions')
        .select('points_earned')
        .eq('user_id', userId);
    if (from != null) q = q.gte('created_at', from.toIso8601String());
    return q;
  }

  Future<List> _queryAwards(String userId, DateTime? from) {
    var q = _db
        .from('award_predictions')
        .select('points_earned')
        .eq('user_id', userId);
    if (from != null) q = q.gte('created_at', from.toIso8601String());
    return q;
  }

  // ── Compute ────────────────────────────────────────────────────────────

  StatsModel _compute({
    required List rows,
    required int pendingCount,
    required List leagueRows,
    required List awardRows,
  }) {
    int exact = 0, correct = 0, wrong = 0, ptsMatches = 0;
    final Map<int, Map<String, int>> dayMap = {};

    // Ordenar DESC para calcular racha desde la predicción más reciente
    final sorted = [...rows]..sort((a, b) {
        final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });

    // ── Racha: recorre desde la más reciente hacia atrás ──
    // currentStreak = cuántas seguidas correctas HASTA HOY (se corta al primer fallo)
    // bestStreak    = la racha más larga de toda la historia
    int currentStreak = 0;
    int bestStreak = 0;
    bool currentStreakBroken = false;
    int tempStreak = 0;

    for (int i = 0; i < sorted.length; i++) {
      final r      = sorted[i];
      final type   = r['result_type'] as String? ?? '';
      final pts    = (r['points_earned'] as num?)?.toInt() ?? 0;
      final isHit  = type == 'exact' || type == 'correct';

      // Contadores de resultados
      if (type == 'exact') {
        exact++;
      } else if (type == 'correct') {
        correct++;
      } else {
        wrong++;
      }
      ptsMatches += pts;

      // Racha actual: solo incrementa mientras no haya habido un fallo previo
      if (!currentStreakBroken) {
        if (isHit) {
          currentStreak++;
        } else {
          currentStreakBroken = true;
        }
      }

      // Mejor racha histórica
      if (isHit) {
        tempStreak++;
        if (tempStreak > bestStreak) bestStreak = tempStreak;
      } else {
        tempStreak = 0;
      }

      // Estadísticas por día de la semana
      final date = DateTime.tryParse(r['created_at'] ?? '');
      if (date != null) {
        final dow = date.weekday; // 1=Lun … 7=Dom
        dayMap.putIfAbsent(dow, () => {'correct': 0, 'total': 0});
        dayMap[dow]!['total'] = dayMap[dow]!['total']! + 1;
        if (isHit) dayMap[dow]!['correct'] = dayMap[dow]!['correct']! + 1;
      }
    }

    final total        = rows.length;
    final accuracy     = total > 0 ? (((exact + correct) / total) * 100).round() : 0;
    final exactAccuracy = total > 0 ? ((exact / total) * 100).round() : 0;

    final ptsLeagues = leagueRows.fold<int>(
      0, (sum, r) => sum + ((r['points_earned'] as num?)?.toInt() ?? 0));
    final ptsAwards  = awardRows.fold<int>(
      0, (sum, r) => sum + ((r['points_earned'] as num?)?.toInt() ?? 0));

    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final dayStats = List.generate(7, (i) {
      final d = dayMap[i + 1] ?? {'correct': 0, 'total': 0};
      return DayStat(name: dayNames[i], correct: d['correct']!, total: d['total']!);
    });

    return StatsModel(
      totalPredictions:   total,
      pendingPredictions: pendingCount,
      exact:              exact,
      correctResult:      correct,
      wrong:              wrong,
      accuracy:           accuracy,
      exactAccuracy:      exactAccuracy,
      totalPoints:        ptsMatches,
      pointsFromMatches:  ptsMatches,
      pointsFromLeagues:  ptsLeagues,
      pointsFromAwards:   ptsAwards,
      leaguePredictions:  leagueRows.length,
      awardPredictions:   awardRows.length,
      currentStreak:      currentStreak,
      bestStreak:         bestStreak,
      leagueStats:        [],
      dayStats:           dayStats,
    );
  }
}