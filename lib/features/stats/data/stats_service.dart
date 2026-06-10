import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/stats_model.dart';

class StatsService {
  final _db = Supabase.instance.client;

  Future<StatsModel> fetchStats(String userId, String timeRange) async {
    final from = _rangeStart(timeRange);
    final isAll = from == null;

    List predRows = [], pendingRows = [], leagueRows = [], awardRows = [];
    Map<String, dynamic>? userRow;

    // Siempre traemos la fila del usuario — es la fuente de verdad para
    // puntos totales, rachas históricas y contadores globales.
    try {
      userRow = await _db
          .from('users')
          .select('points, correct, predictions, current_streak, best_streak')
          .eq('id', userId)
          .single();
    } catch (e) {
      print('[StatsService] ERROR user row: $e');
    }

    // Predicciones de partidos finalizados
    try {
      predRows = await _queryFinished(userId, from);
    } catch (e) {
      print('[StatsService] ERROR predictions finished: $e');
    }

    // Predicciones pendientes (solo para contar)
    try {
      pendingRows = await _queryPending(userId, from);
    } catch (e) {
      print('[StatsService] ERROR predictions pending: $e');
    }

    // Predicciones de ligas
    try {
      leagueRows = await _queryLeagues(userId, from);
    } catch (e) {
      print('[StatsService] ERROR league_predictions: $e');
    }

    // Predicciones de premios
    try {
      awardRows = await _queryAwards(userId, from);
    } catch (e) {
      print('[StatsService] ERROR award_predictions: $e');
    }

    return _compute(
      predRows:     predRows,
      pendingCount: pendingRows.length,
      leagueRows:   leagueRows,
      awardRows:    awardRows,
      userRow:      userRow,
      isAll:        isAll,
    );
  }

  // ── Rango de fecha ──────────────────────────────────────────────────

  DateTime? _rangeStart(String timeRange) {
    final now = DateTime.now().toUtc();
    return switch (timeRange) {
      'week'  => DateTime.utc(now.year, now.month, now.day)
                   .subtract(const Duration(days: 6)),
      'month' => DateTime.utc(now.year, now.month, 1),
      _       => null,
    };
  }

  // ── Queries ─────────────────────────────────────────────────────────

  // CORRECCIÓN: filtramos por predictions.created_at (no matches.deadline)
  // para que week/month/all sean coherentes entre las 3 fuentes de datos.
  Future<List> _queryFinished(String userId, DateTime? from) async {
    var q = _db
        .from('predictions')
        .select(
          'points_earned, advancing_points, result_type, created_at, '
          'matches(league, is_knockout)',
        )
        .eq('user_id', userId)
        .not('result_type', 'is', null);

    if (from != null) {
      q = q.gte('created_at', from.toIso8601String());
    }

    return q;
  }

  Future<List> _queryPending(String userId, DateTime? from) async {
    var q = _db
        .from('predictions')
        .select('id, created_at')
        .eq('user_id', userId)
        .filter('result_type', 'is', null);

    if (from != null) {
      q = q.gte('created_at', from.toIso8601String());
    }

    return q;
  }

  Future<List> _queryLeagues(String userId, DateTime? from) async {
    var q = _db
        .from('league_predictions')
        .select('points_earned, created_at')
        .eq('user_id', userId);

    if (from != null) {
      q = q.gte('created_at', from.toIso8601String());
    }

    return q;
  }

  Future<List> _queryAwards(String userId, DateTime? from) async {
    var q = _db
        .from('award_predictions')
        .select('points_earned, created_at')
        .eq('user_id', userId);

    if (from != null) {
      q = q.gte('created_at', from.toIso8601String());
    }

    return q;
  }

  // ── Cálculo ─────────────────────────────────────────────────────────

  StatsModel _compute({
    required List predRows,
    required int  pendingCount,
    required List leagueRows,
    required List awardRows,
    required Map<String, dynamic>? userRow,
    required bool isAll,
  }) {
    int exact = 0, correct = 0, wrong = 0, ptsMatches = 0;
    final Map<int, Map<String, int>> dayMap = {};

    // Ordenar DESC (más reciente primero) para calcular racha actual
    final sorted = [...predRows]..sort((a, b) {
        final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });

    // Racha actual local (para week/month)
    int localCurrentStreak = 0;
    bool streakBroken = false;

    // Mejor racha local (para week/month)
    int localBestStreak = 0;
    int tempStreak = 0;

    for (final r in sorted) {
      final type  = r['result_type'] as String? ?? '';
      final pts   = ((r['points_earned']    as num?)?.toInt() ?? 0)
                  + ((r['advancing_points'] as num?)?.toInt() ?? 0);
      final isHit = type == 'exact' || type == 'result';

      if      (type == 'exact')   { exact++; }
      else if (type == 'result') { correct++; }
      else if (type.isNotEmpty)   { wrong++; }

      ptsMatches += pts;

      // Racha actual: consecutivos desde el más reciente
      if (!streakBroken) {
        if (isHit) { localCurrentStreak++; }
        else       { streakBroken = true; }
      }

      // Mejor racha en el período
      if (isHit) {
        tempStreak++;
        if (tempStreak > localBestStreak) localBestStreak = tempStreak;
      } else {
        tempStreak = 0;
      }

      // Mapa por día de la semana (1=Lun … 7=Dom)
      final date = DateTime.tryParse(r['created_at'] ?? '');
      if (date != null) {
        final dow = date.toLocal().weekday;
        dayMap.putIfAbsent(dow, () => {'correct': 0, 'total': 0});
        dayMap[dow]!['total']   = dayMap[dow]!['total']!   + 1;
        if (isHit) {
          dayMap[dow]!['correct'] = dayMap[dow]!['correct']! + 1;
        }
      }
    }

    final total         = predRows.length;
    final accuracy      = total > 0 ? (((exact + correct) / total) * 100).round() : 0;
    final exactAccuracy = total > 0 ? ((exact / total) * 100).round() : 0;

    // Puntos de ligas y premios calculados desde el período
    final ptsLeaguesCalc = leagueRows.fold<int>(
        0, (s, r) => s + ((r['points_earned'] as num?)?.toInt() ?? 0));
    final ptsAwardsCalc  = awardRows.fold<int>(
        0, (s, r) => s + ((r['points_earned'] as num?)?.toInt() ?? 0));

    // ── Fuente de verdad según modo ──────────────────────────────────
    //
    // Modo ALL:
    //   - Puntos totales → users.points (incluye ajustes históricos del admin)
    //   - Rachas → users.current_streak / best_streak
    //   - El excedente respecto a lo calculado se suma a ptsLeagues
    //
    // Modo WEEK / MONTH:
    //   - Todo calculado desde las predicciones del período
    //   - Rachas calculadas localmente dentro del período
    //
    final int finalPtsMatches;
    final int finalPtsLeagues;
    final int finalPtsAwards;
    final int finalCurrentStreak;
    final int finalBestStreak;

    if (isAll && userRow != null) {
      final dbTotal = (userRow['points']         as num?)?.toInt() ?? 0;
      finalPtsMatches     = ptsMatches;
      finalPtsAwards      = ptsAwardsCalc;
      // Lo que falta para llegar al total real de la DB
      final resto = dbTotal - ptsMatches - ptsAwardsCalc;
      finalPtsLeagues     = resto > 0 ? resto : ptsLeaguesCalc;
      finalCurrentStreak  = (userRow['current_streak'] as num?)?.toInt() ?? localCurrentStreak;
      finalBestStreak     = (userRow['best_streak']    as num?)?.toInt() ?? localBestStreak;
    } else {
      finalPtsMatches    = ptsMatches;
      finalPtsLeagues    = ptsLeaguesCalc;
      finalPtsAwards     = ptsAwardsCalc;
      finalCurrentStreak = localCurrentStreak;
      finalBestStreak    = localBestStreak;
    }

    // ── Stats por liga ───────────────────────────────────────────────
    final Map<String, Map<String, int>> leagueMap = {};
    for (final r in predRows) {
      final leagueName = (r['matches'] as Map?)?['league'] as String?;
      if (leagueName == null || leagueName.isEmpty) continue;

      leagueMap.putIfAbsent(leagueName, () => {
        'total': 0, 'correct': 0, 'exact': 0, 'points': 0,
      });

      final type  = r['result_type'] as String? ?? '';
      final pts   = ((r['points_earned']    as num?)?.toInt() ?? 0)
                  + ((r['advancing_points'] as num?)?.toInt() ?? 0);
      final isHit = type == 'exact' || type == 'result';

      final entry = leagueMap[leagueName]!;
      entry['total']   = entry['total']!   + 1;
      entry['points']  = entry['points']!  + pts;
      if (isHit)           entry['correct'] = entry['correct']! + 1;
      if (type == 'exact') entry['exact']   = entry['exact']!   + 1;
    }

    final leagueStats = leagueMap.entries.map((e) {
      final s   = e.value;
      final t   = s['total']!;
      final acc = t > 0 ? (((s['correct']!) / t) * 100).round() : 0;
      return LeagueStat(
        name:     e.key,
        points:   s['points']!,
        exact:    s['exact']!,
        accuracy: acc,
      );
    }).toList()
      ..sort((a, b) => b.points.compareTo(a.points));

    // ── Stats por día ────────────────────────────────────────────────
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
      totalPoints:        finalPtsMatches,
      pointsFromMatches:  finalPtsMatches,
      pointsFromLeagues:  finalPtsLeagues,
      pointsFromAwards:   finalPtsAwards,
      leaguePredictions:  leagueRows.length,
      awardPredictions:   awardRows.length,
      currentStreak:      finalCurrentStreak,
      bestStreak:         finalBestStreak,
      leagueStats:        leagueStats,
      dayStats:           dayStats,
    );
  }
}