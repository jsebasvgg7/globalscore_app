import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/worldcup_service.dart';
import 'worldcup_models.dart';

// ─── Service provider ─────────────────────────────────────
final worldCupServiceProvider = Provider<WorldCupService>((_) => WorldCupService());

// ─── Supabase URL (para imágenes) ─────────────────────────
final supabaseUrlProvider = Provider<String>((_) {
  return Supabase.instance.client.supabaseUrl;
});

// ─── Estado del notifier ──────────────────────────────────
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
class WorldCupNotifier extends StateNotifier<WorldCupState> {
  final WorldCupService _service;
  final String _userId;

  WorldCupNotifier(this._service, this._userId) : super(const WorldCupState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.fetchPredictions(_userId);
      state = state.copyWith(
        predictions: data ?? const WorldCupPredictions(),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> save() async {
    state = state.copyWith(saving: true);
    try {
      await _service.upsertPredictions(_userId, state.predictions);
      state = state.copyWith(saving: false);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }

  // ── Grupos ─────────────────────────────────────────────
  void updateGroupMatch(String group, int matchIdx, MatchPrediction pred) {
    final current = state.predictions.groups[group] ?? const GroupPrediction();
    final updated = current.copyWithMatch(matchIdx, pred);
    state = state.copyWith(
      predictions: state.predictions.copyWith(
        groups: {...state.predictions.groups, group: updated},
      ),
    );
  }

  // ── Knockout ───────────────────────────────────────────
  void updateRound16(dynamic id, String team) {
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

  // ── Premios ────────────────────────────────────────────
  void updateAward(String key, String value) {
    state = state.copyWith(
      predictions: state.predictions.copyWith(
        awards: state.predictions.awards.setByKey(key, value),
      ),
    );
  }
}

// ─── Provider principal ───────────────────────────────────
final worldCupProvider =
    StateNotifierProvider.autoDispose<WorldCupNotifier, WorldCupState>((ref) {
  final service = ref.watch(worldCupServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser!.id;
  return WorldCupNotifier(service, userId);
});
