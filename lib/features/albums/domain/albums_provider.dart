import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/albums_service.dart';
import '../domain/albums_model.dart';

// ─── userId (reutiliza el mismo patrón de stats) ──────────
final albumsUserIdProvider = FutureProvider<String>((ref) async {
  final authId = Supabase.instance.client.auth.currentUser!.id;
  final data = await Supabase.instance.client
      .from('users')
      .select('id')
      .eq('auth_id', authId)
      .single();
  return data['id'] as String;
});

// ─── AlbumsModel principal ────────────────────────────────
final albumsProvider = FutureProvider<AlbumsModel>((ref) async {
  final userId = await ref.watch(albumsUserIdProvider.future);
  return AlbumsService().fetchAll(userId);
});

// ─── Tab activo (legendary / stars / cult) ────────────────
class AlbumsTabNotifier extends Notifier<String> {
  @override
  String build() => 'legendary';

  void set(String tab) => state = tab;
}

final albumsTabProvider =
    NotifierProvider<AlbumsTabNotifier, String>(AlbumsTabNotifier.new);

// ─── Pack Opening state ───────────────────────────────────
enum PackOpenStatus { idle, loading, success, error }

class PackOpenState {
  final PackOpenStatus status;
  final PackOpenResult? result;
  final String? errorMsg;

  const PackOpenState({
    this.status = PackOpenStatus.idle,
    this.result,
    this.errorMsg,
  });

  PackOpenState copyWith({
    PackOpenStatus? status,
    PackOpenResult? result,
    String? errorMsg,
  }) =>
      PackOpenState(
        status:   status   ?? this.status,
        result:   result   ?? this.result,
        errorMsg: errorMsg ?? this.errorMsg,
      );
}

class PackOpenNotifier extends Notifier<PackOpenState> {
  @override
  PackOpenState build() => const PackOpenState();

  Future<void> open() async {
    state = state.copyWith(status: PackOpenStatus.loading);
    try {
      final userId = await ref.read(albumsUserIdProvider.future);
      final result = await AlbumsService().openPack(userId);
      state = PackOpenState(status: PackOpenStatus.success, result: result);
      // Refrescar colección y packs después de abrir
      ref.invalidate(albumsProvider);
    } catch (e) {
      state = PackOpenState(
        status:   PackOpenStatus.error,
        errorMsg: e.toString(),
      );
    }
  }

  void reset() => state = const PackOpenState();
}

final packOpenProvider =
    NotifierProvider<PackOpenNotifier, PackOpenState>(PackOpenNotifier.new);
