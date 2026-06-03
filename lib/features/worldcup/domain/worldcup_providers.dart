import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/worldcup_service.dart';
import '../../../main.dart';
import 'worldcup_models.dart';

// ─── Service provider ─────────────────────────────────────
final worldCupServiceProvider = Provider<WorldCupService>((_) => WorldCupService());

// ─── Supabase URL (para imágenes) ─────────────────────────
final supabaseUrlProvider = Provider<String>((_) => kSupabaseUrl);

// ─── Provider que resuelve el UUID real del usuario ───────
final userIdProvider = FutureProvider<String>((ref) async {
  final authId = Supabase.instance.client.auth.currentUser!.id;
  final res = await Supabase.instance.client
      .from('users')
      .select('id')
      .eq('auth_id', authId)
      .single();
  return res['id'] as String;
});

// ─── Estado ───────────────────────────────────────────────
class WorldCupState {
  final WorldCupPredictions predictions;
  final bool loading;
  final bool saving;
  final String? error;

  const WorldCupState({
    this.predictions = const WorldCupPredictions(),
    this.loading = true,
    this.saving = false,
    this.error,
  });

  WorldCupState copyWith({
    WorldCupPredictions? predictions,
    bool? loading,
    bool? saving,
    String? error,
  }) =>
      WorldCupState(
        predictions: predictions ?? this.predictions,
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        error: error,
      );
}

// ─── Notifier ─────────────────────────────────────────────
class WorldCupNotifier extends Notifier<WorldCupState> {
  late WorldCupService _service;
  String? _userId;

  @override
  WorldCupState build() {
    _service = ref.watch(worldCupServiceProvider);
    _load();
    return const WorldCupState();
  }

  Future<void> _load() async {
    try {
      final authId = Supabase.instance.client.auth.currentUser!.id;
      final userRes = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('auth_id', authId)
          .single();
      _userId = userRes['id'] as String;

      final data = await _service.fetchPredictions(_userId!);
      state = state.copyWith(
        predictions: data ?? const WorldCupPredictions(),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> save() async {
    if (_userId == null) return false;
    state = state.copyWith(saving: true);
    try {
      await _service.upsertPredictions(_userId!, state.predictions);
      state = state.copyWith(saving: false);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }

  void updateGroupMatch(String group, int matchIdx, MatchPrediction pred) {
    final current = state.predictions.groups[group] ?? const GroupPrediction();
    final updated = current.copyWithMatch(matchIdx, pred);
    state = state.copyWith(
      predictions: state.predictions.copyWith(
        groups: {...state.predictions.groups, group: updated},
      ),
    );
  }

  void updateRound16(String id, String team) {
    state = state.copyWith(
      predictions: state.predictions.copyWith(
        knockout: state.predictions.knockout.copyWithRound16(id, team),
      ),
    );
  }

  void updateRound8(String id, String team) {
    state = state.copyWith(
      predictions: state.predictions.copyWith(
        knockout: state.predictions.knockout.copyWithRound8(id, team),
      ),
    );
  }

  void updateQuarters(String id, String team) {
    state = state.copyWith(
      predictions: state.predictions.copyWith(
        knockout: state.predictions.knockout.copyWithQuarters(id, team),
      ),
    );
  }

  void updateSemis(String id, String team) {
    state = state.copyWith(
      predictions: state.predictions.copyWith(
        knockout: state.predictions.knockout.copyWithSemis(id, team),
      ),
    );
  }

  void updateFinal(String id, String team) {
    state = state.copyWith(
      predictions: state.predictions.copyWith(
        knockout: state.predictions.knockout.copyWithFinal(id, team),
      ),
    );
  }

  void updateThirdPlace(String id, String team) {
    state = state.copyWith(
      predictions: state.predictions.copyWith(
        knockout: state.predictions.knockout.copyWithThirdPlace(id, team),
      ),
    );
  }

  void updateAward(String key, String value) {
    state = state.copyWith(
      predictions: state.predictions.copyWith(
        awards: state.predictions.awards.setByKey(key, value),
      ),
    );
  }
}

// ─── Provider principal — SIN autoDispose para evitar re-fetch al volver ───
final worldCupProvider =
    NotifierProvider<WorldCupNotifier, WorldCupState>(
  WorldCupNotifier.new,
);

// ─── Providers derivados (computed) ───────────────────────
// Evitan recalcular tablas de grupo en cada rebuild de KnockoutSection.
// Solo se recomputan cuando cambia groups, no cuando cambia knockout/awards.

/// Tablas de clasificados (1° y 2°) por grupo — se recalcula solo si cambian groups
final qualifiedTeamsProvider = Provider<Map<String, Map<String, String?>>>((ref) {
  // select → solo observa groups, ignora cambios en knockout/awards
  final groups = ref.watch(
    worldCupProvider.select((s) => s.predictions.groups),
  );
  final qualified = <String, Map<String, String?>>{};
  for (final g in kGroupsData.keys) {
    final table = calcGroupTable(g, groups[g]);
    qualified[g] = {
      'first':  table.isNotEmpty ? table[0].team : null,
      'second': table.length > 1 ? table[1].team : null,
    };
  }
  return qualified;
});

/// Lista de mejores terceros — se recalcula solo si cambian groups
final bestThirdsProvider = Provider<List<ThirdPlaceEntry>>((ref) {
  final groups = ref.watch(
    worldCupProvider.select((s) => s.predictions.groups),
  );
  return calcBestThirds(groups);
});

/// Mapa groupLetter → team para los mejores terceros
final thirdsMapProvider = Provider<Map<String, String>>((ref) {
  final thirds = ref.watch(bestThirdsProvider);
  return {for (final t in thirds) t.group: t.team};
});