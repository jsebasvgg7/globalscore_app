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
  String? _userId; // se resuelve de forma asíncrona en _load()

  @override
  WorldCupState build() {
    _service = ref.watch(worldCupServiceProvider);
    _load();
    return const WorldCupState();
  }

  Future<void> _load() async {
    try {
      // Resolver el UUID real de public.users a partir del auth_id
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
    NotifierProvider.autoDispose<WorldCupNotifier, WorldCupState>(
  WorldCupNotifier.new,
);