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

    // Usar fromJson directamente sobre cada campo JSONB tal como viene de Supabase.
    // Los campos pueden llegar como Map<String, dynamic> o ya deserializados.
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
    // Serializar usando los mismos toJson() que fromJson() espera.
    await _client.from('worldcup_predictions').upsert(
      {
        'user_id': userId,
        'groups_predictions': _serializeGroups(p.groups),
        'knockout_predictions': p.knockout.toJson(),
        'awards_predictions': p.awards.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  // Serializa Map<String, GroupPrediction> → formato que fromJson espera.
  Map<String, dynamic> _serializeGroups(Map<String, GroupPrediction> groups) {
    return groups.map((k, v) => MapEntry(k, v.toJson()));
  }

  // Deserializa el campo groups_predictions desde Supabase.
  // El formato guardado es: { "A": { "matches": { "0": {...}, ... } }, ... }
  Map<String, GroupPrediction> _parseGroups(dynamic raw) {
    if (raw == null) return {};
    final map = raw as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(
          k,
          GroupPrediction.fromJson(v as Map<String, dynamic>),
        ));
  }
}