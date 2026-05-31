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
  });

  factory RankingUser.fromMap(Map<String, dynamic> m) => RankingUser(
        id: m['id'] as String,
        name: (m['name'] ?? m['username'] ?? 'Usuario') as String,
        avatarUrl: m['avatar_url'] as String?,
        points: (m['points'] ?? 0) as int,
        correct: (m['correct'] ?? 0) as int,
        predictions: (m['predictions'] ?? 0) as int,
        monthlyPoints: (m['monthly_points'] ?? 0) as int,
        monthlyCorrect: (m['monthly_correct'] ?? 0) as int,
        monthlyPredictions: (m['monthly_predictions'] ?? 0) as int,
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
  final int championshipPoints;
  final String? championshipMonthYear;

  const HofChampion({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.monthlyChampionships,
    required this.championshipPoints,
    this.championshipMonthYear,
  });

  factory HofChampion.fromMap(Map<String, dynamic> m) => HofChampion(
        id: m['id'] as String,
        name: (m['name'] ?? m['username'] ?? 'Usuario') as String,
        avatarUrl: m['avatar_url'] as String?,
        monthlyChampionships: (m['monthly_championships'] ?? 0) as int,
        championshipPoints: (m['championship_points'] ?? 0) as int,
        championshipMonthYear: m['championship_month_year'] as String?,
      );
}

class RankingService {
  final _sb = Supabase.instance.client;

  Future<List<RankingUser>> fetchUsers() async {
    final res = await _sb
        .from('profiles')
        .select(
            'id, name, username, avatar_url, points, correct, predictions, monthly_points, monthly_correct, monthly_predictions')
        .order('points', ascending: false);
    return (res as List).map((m) => RankingUser.fromMap(m)).toList();
  }

  Future<List<HofChampion>> fetchChampions() async {
    final res = await _sb
        .from('profiles')
        .select(
            'id, name, username, avatar_url, monthly_championships, championship_points, championship_month_year')
        .gt('monthly_championships', 0)
        .order('monthly_championships', ascending: false);
    return (res as List).map((m) => HofChampion.fromMap(m)).toList();
  }
}