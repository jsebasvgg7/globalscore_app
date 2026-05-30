import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  static final _db = Supabase.instance.client;

  // ── Usuario actual (por auth_id) ─────────────────────────
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final authId = _db.auth.currentUser?.id;
    if (authId == null) return null;

    final res = await _db
        .from('users')
        .select()
        .eq('auth_id', authId)
        .single();
    return res;
  }

  // ── Partidos con predicciones del usuario ────────────────
  static Future<List<Map<String, dynamic>>> getMatchesWithPredictions(String userId) async {
    final res = await _db
        .from('matches')
        .select('*, predictions!left(*)') 
        .order('date', ascending: true)
        .order('time', ascending: true);

    // Filtrar predicciones del usuario en cada partido
    return (res as List).map((m) {
      final preds = (m['predictions'] as List?) ?? [];
      final myPred = preds.firstWhere(
        (p) => p['user_id'] == userId,
        orElse: () => null,
      );
      return {...m, 'my_prediction': myPred};
    }).toList();
  }

  // ── Ligas con predicciones del usuario ───────────────────
  static Future<List<Map<String, dynamic>>> getLeaguesWithPredictions(String userId) async {
    final res = await _db
        .from('leagues')
        .select('*, league_predictions!left(*)')
        .order('created_at', ascending: false);

    return (res as List).map((l) {
      final preds = (l['league_predictions'] as List?) ?? [];
      final myPred = preds.firstWhere(
        (p) => p['user_id'] == userId,
        orElse: () => null,
      );
      return {...l, 'my_prediction': myPred};
    }).toList();
  }

  // ── Premios con predicciones del usuario ─────────────────
  static Future<List<Map<String, dynamic>>> getAwardsWithPredictions(String userId) async {
    final res = await _db
        .from('awards')
        .select('*, award_predictions!left(*)')
        .order('created_at', ascending: false);

    return (res as List).map((a) {
      final preds = (a['award_predictions'] as List?) ?? [];
      final myPred = preds.firstWhere(
        (p) => p['user_id'] == userId,
        orElse: () => null,
      );
      return {...a, 'my_prediction': myPred};
    }).toList();
  }

  // ── Top usuarios para podio ───────────────────────────────
  static Future<List<Map<String, dynamic>>> getTopUsers() async {
    final res = await _db
        .from('users')
        .select('id, name, points, correct, predictions, avatar_url')
        .order('points', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(res);
  }

  // ── Guardar predicción de partido ─────────────────────────
  static Future<void> upsertMatchPrediction({
    required String matchId,
    required String userId,
    required int homeScore,
    required int awayScore,
    String? advancingTeam,
  }) async {
    await _db.from('predictions').upsert({
      'match_id': matchId,
      'user_id': userId,
      'home_score': homeScore,
      'away_score': awayScore,
      'predicted_advancing_team': advancingTeam,
    }, onConflict: 'match_id,user_id');
  }

  // ── Guardar predicción de liga ────────────────────────────
  static Future<void> upsertLeaguePrediction({
    required String leagueId,
    required String userId,
    required String champion,
    required String topScorer,
    required String topAssist,
    required String mvp,
  }) async {
    await _db.from('league_predictions').upsert({
      'league_id': leagueId,
      'user_id': userId,
      'predicted_champion': champion,
      'predicted_top_scorer': topScorer,
      'predicted_top_assist': topAssist,
      'predicted_mvp': mvp,
    }, onConflict: 'league_id,user_id');
  }

  // ── Guardar predicción de premio ──────────────────────────
  static Future<void> upsertAwardPrediction({
    required String awardId,
    required String userId,
    required String predictedWinner,
  }) async {
    await _db.from('award_predictions').upsert({
      'award_id': awardId,
      'user_id': userId,
      'predicted_winner': predictedWinner,
    }, onConflict: 'award_id,user_id');
  }
}