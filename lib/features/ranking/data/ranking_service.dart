import 'package:supabase_flutter/supabase_flutter.dart';

class RankingUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final int points;
  final int correct;
  final int predictions;
  final int monthlyPoints;
  final int monthlyCorrect;
  final int monthlyPredictions;
  final int level;
  final int currentStreak;

  const RankingUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.points,
    required this.correct,
    required this.predictions,
    required this.monthlyPoints,
    required this.monthlyCorrect,
    required this.monthlyPredictions,
    required this.level,
    required this.currentStreak,
  });

  factory RankingUser.fromMap(Map<String, dynamic> m) => RankingUser(
        id: m['id'] as String,
        name: (m['name'] ?? 'Usuario') as String,
        avatarUrl: m['avatar_url'] as String?,
        points: (m['points'] ?? 0) as int,
        correct: (m['correct'] ?? 0) as int,
        predictions: (m['predictions'] ?? 0) as int,
        monthlyPoints: (m['monthly_points'] ?? 0) as int,
        monthlyCorrect: (m['monthly_correct'] ?? 0) as int,
        monthlyPredictions: (m['monthly_predictions'] ?? 0) as int,
        level: (m['level'] ?? 1) as int,
        currentStreak: (m['current_streak'] ?? 0) as int,
      );

  int rankPoints(String type) =>
      type == 'monthly' ? monthlyPoints : points;
  int rankCorrect(String type) =>
      type == 'monthly' ? monthlyCorrect : correct;
  int rankPredictions(String type) =>
      type == 'monthly' ? monthlyPredictions : predictions;

  int accuracy(String type) {
    final pred = rankPredictions(type);
    if (pred == 0) return 0;
    return ((rankCorrect(type) / pred) * 100).round();
  }
}

class HofChampion {
  final String id;
  final String name;
  final String? avatarUrl;
  final int monthlyChampionships;
  final int bestPoints;         // max pts de monthly_championship_history
  final String? lastMonthYear;  // último mes ganado

  const HofChampion({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.monthlyChampionships,
    required this.bestPoints,
    this.lastMonthYear,
  });
}

class RankingService {
  final _sb = Supabase.instance.client;

  Future<List<RankingUser>> fetchUsers() async {
    final res = await _sb
        .from('users')
        .select(
            'id, name, avatar_url, points, correct, predictions, '
            'monthly_points, monthly_correct, monthly_predictions, '
            'level, current_streak')
        .order('points', ascending: false);
    return (res as List).map((m) => RankingUser.fromMap(m)).toList();
  }

  Future<List<HofChampion>> fetchChampions() async {
    // 1. Traer usuarios con al menos 1 campeonato
    final usersRes = await _sb
        .from('users')
        .select('id, name, avatar_url, monthly_championships')
        .gt('monthly_championships', 0)
        .order('monthly_championships', ascending: false);

    final users = usersRes as List;
    if (users.isEmpty) return [];

    final ids = users.map((u) => u['id'] as String).toList();

    // 2. Traer historial de campeonatos de esos usuarios
    final histRes = await _sb
        .from('monthly_championship_history')
        .select('user_id, month_year, points')
        .inFilter('user_id', ids);

    final history = histRes as List;

    // 3. Por cada usuario calcular: max points y último mes
    final Map<String, int> bestPts = {};
    final Map<String, String> lastMonth = {};

    for (final row in history) {
      final uid = row['user_id'] as String;
      final pts = (row['points'] ?? 0) as int;
      final my = row['month_year'] as String? ?? '';

      // max points
      if (!bestPts.containsKey(uid) || pts > bestPts[uid]!) {
        bestPts[uid] = pts;
      }

      // último mes (string YYYY-MM, el mayor lexicográficamente)
      if (!lastMonth.containsKey(uid) || my.compareTo(lastMonth[uid]!) > 0) {
        lastMonth[uid] = my;
      }
    }

    return users.map((u) {
      final uid = u['id'] as String;
      return HofChampion(
        id: uid,
        name: (u['name'] ?? 'Usuario') as String,
        avatarUrl: u['avatar_url'] as String?,
        monthlyChampionships: (u['monthly_championships'] ?? 0) as int,
        bestPoints: bestPts[uid] ?? 0,
        lastMonthYear: lastMonth[uid],
      );
    }).toList();
  }
}