import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/worldcup_models.dart';

class WorldCupService {
  final _client = Supabase.instance.client;

  Future<WorldCupPredictions?> fetchPredictions(String userId) async {
    final res = await _client
        .from('worldcup_predictions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null) return null;

    return WorldCupPredictions(
      groups: _parseGroups(res['groups_predictions']),
      knockout: KnockoutPredictions.fromJson(
        (res['knockout_predictions'] as Map<String, dynamic>?) ?? {},
      ),
      awards: AwardsPredictions.fromJson(
        (res['awards_predictions'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Future<void> upsertPredictions(String userId, WorldCupPredictions p) async {
    await _client.from('worldcup_predictions').upsert(
      {
        'user_id': userId,
        'groups_predictions': p.groups.map((k, v) => MapEntry(k, v.toJson())),
        'knockout_predictions': p.knockout.toJson(),
        'awards_predictions': p.awards.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  Map<String, GroupPrediction> _parseGroups(dynamic raw) {
    if (raw == null) return {};
    return (raw as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, GroupPrediction.fromJson(v as Map<String, dynamic>)),
    );
  }
}
