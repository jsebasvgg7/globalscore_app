class LeagueStat {
  final String name;
  final int    points;
  final int    accuracy;
  final int    exact;

  const LeagueStat({
    required this.name,
    required this.points,
    required this.accuracy,
    required this.exact,
  });

  factory LeagueStat.fromMap(Map<String, dynamic> m) => LeagueStat(
        name:     m['name']     as String? ?? '',
        points:   (m['points']   as num?)?.toInt() ?? 0,
        accuracy: (m['accuracy'] as num?)?.toInt() ?? 0,
        exact:    (m['exact']    as num?)?.toInt() ?? 0,
      );
}

class DayStat {
  final String name;
  final int    correct;
  final int    total;

  const DayStat({required this.name, required this.correct, required this.total});

  int    get accuracy => total > 0 ? ((correct / total) * 100).round() : 0;
  double get opacity  => total > 0 ? 0.35 + (accuracy / 100) * 0.65 : 0.15;

  factory DayStat.fromMap(Map<String, dynamic> m) => DayStat(
        name:    m['name']    as String? ?? '',
        correct: (m['correct'] as num?)?.toInt() ?? 0,
        total:   (m['total']   as num?)?.toInt() ?? 0,
      );
}

class StatsModel {
  final int totalPredictions;
  final int pendingPredictions;
  final int exact;
  final int correctResult;
  final int wrong;
  final int accuracy;
  final int exactAccuracy;
  final int totalPoints;
  final int pointsFromMatches;
  final int pointsFromLeagues;
  final int pointsFromAwards;
  final int leaguePredictions;
  final int awardPredictions;
  final int currentStreak;
  final int bestStreak;
  final List<LeagueStat> leagueStats;
  final List<DayStat>    dayStats;

  const StatsModel({
    required this.totalPredictions,
    required this.pendingPredictions,
    required this.exact,
    required this.correctResult,
    required this.wrong,
    required this.accuracy,
    required this.exactAccuracy,
    required this.totalPoints,
    required this.pointsFromMatches,
    required this.pointsFromLeagues,
    required this.pointsFromAwards,
    required this.leaguePredictions,
    required this.awardPredictions,
    required this.currentStreak,
    required this.bestStreak,
    required this.leagueStats,
    required this.dayStats,
  });

  // FIX: suma real de los 3 orígenes de puntos
  int get totalPts    => pointsFromMatches + pointsFromLeagues + pointsFromAwards;

  // FIX: bonus de eliminatorios = diferencia entre lo almacenado en DB y lo calculado
  // base (exact*5 + correct*3). La diferencia son los advancing_points acumulados.
  int get knockoutBonus =>
      pointsFromMatches - (exact * 5 + correctResult * 3);

  // Porcentajes para la distribución de puntos — usa totalPts real
  int get pctMatches => totalPts > 0 ? ((pointsFromMatches / totalPts) * 100).round() : 0;
  int get pctLeagues => totalPts > 0 ? ((pointsFromLeagues / totalPts) * 100).round() : 0;
  int get pctAwards  => totalPts > 0 ? ((pointsFromAwards  / totalPts) * 100).round() : 0;
}