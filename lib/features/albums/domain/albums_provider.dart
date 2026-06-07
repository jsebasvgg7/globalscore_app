import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/albums_service.dart';
import '../domain/albums_model.dart';

// ══════════════════════════════════════════════════════════════
//  USER ID
// ══════════════════════════════════════════════════════════════
final albumsUserIdProvider = FutureProvider<String>((ref) async {
  final authId = Supabase.instance.client.auth.currentUser!.id;
  final data = await Supabase.instance.client
      .from('users')
      .select('id')
      .eq('auth_id', authId)
      .single();
  return data['id'] as String;
});

// ══════════════════════════════════════════════════════════════
//  ALBUMS STATE
//  Usamos un StateNotifier en lugar de StreamProvider para
//  tener control total sobre cuándo y cómo se actualiza el estado.
//
//  El Realtime sigue activo como respaldo (colección, progreso),
//  pero el contador de tickets se actualiza de forma inmediata
//  directamente desde el resultado del RPC — sin esperar Realtime.
// ══════════════════════════════════════════════════════════════

class AlbumsNotifier extends AsyncNotifier<AlbumsModel> {
  AlbumsService get _service => AlbumsService();
  RealtimeChannel? _channel;
  Timer? _debounce;

  @override
  Future<AlbumsModel> build() async {
    final userId = await ref.watch(albumsUserIdProvider.future);
    final model = await _service.fetchAll(userId);
    _subscribeRealtime(userId);
    ref.onDispose(_cleanup);
    return model;
  }

  void _cleanup() {
    _debounce?.cancel();
    _channel?.unsubscribe();
    _channel = null;
  }

  // ── Refresco con debounce (para Realtime) ──────────────────
  Future<void> _debouncedRefresh(String userId) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final model = await _service.fetchAll(userId);
        state = AsyncData(model);
      } catch (_) {}
    });
  }

  // ── Realtime: solo colección y progreso ────────────────────
  void _subscribeRealtime(String userId) {
    _channel?.unsubscribe();

    final channelName =
        'albums-$userId-${DateTime.now().millisecondsSinceEpoch}';

    _channel = Supabase.instance.client
        .channel(channelName)
        // album_collection → puede cambiar al abrir sobre
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'album_collection',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _debouncedRefresh(userId),
        )
        // album_progress → cambia al completar álbum
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'album_progress',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _debouncedRefresh(userId),
        )
        // album_packs → como respaldo, pero el contador ya se actualiza
        // de forma inmediata via updatePacksFromRpc()
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'album_packs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _debouncedRefresh(userId),
        )
        .subscribe();
  }

  // ── Refresh completo (lifecycle resume, etc.) ──────────────
  Future<void> refresh() async {
    final userId = await ref.read(albumsUserIdProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.fetchAll(userId));
    _subscribeRealtime(userId);
  }

  // ══════════════════════════════════════════════════════════
  //  updatePacksFromRpc — CLAVE
  //
  //  Llamado inmediatamente después de que el RPC responde.
  //  Actualiza solo el objeto AlbumPacks en el estado actual
  //  sin hacer ningún fetch a la DB ni esperar Realtime.
  //  El contador baja en pantalla en el mismo frame en que
  //  el RPC retorna.
  // ══════════════════════════════════════════════════════════
  void updatePacksFromRpc(Map<String, dynamic> rpcResult) {
    final current = state.asData?.value;
    if (current == null) return;

    final currentPacks = current.packs;
    if (currentPacks == null) return;

    // Construir el nuevo AlbumPacks con los valores del RPC
    final updatedPacks = AlbumPacks(
      id:                   currentPacks.id,
      userId:               currentPacks.userId,
      packsAvailable:       (rpcResult['new_available'] as num).toInt(),
      totalPacksEarned:     currentPacks.totalPacksEarned,
      totalPacksOpened:     (rpcResult['new_opened'] as num).toInt(),
      boostActive:          rpcResult['boost_active'] as bool? ?? false,
      boostPacksRemaining:  (rpcResult['boost_remaining'] as num?)?.toInt() ?? 0,
      updatedAt:            DateTime.now().toIso8601String(),
    );

    state = AsyncData(AlbumsModel(
      packs:             updatedPacks,
      collection:        current.collection,
      definitions:       current.definitions,
      progressByAlbumId: current.progressByAlbumId,
    ));
  }
}

final albumsProvider =
    AsyncNotifierProvider<AlbumsNotifier, AlbumsModel>(AlbumsNotifier.new);

// ══════════════════════════════════════════════════════════════
//  TAB ACTIVO
// ══════════════════════════════════════════════════════════════
class AlbumsTabNotifier extends Notifier<String> {
  @override
  String build() => 'legendary';
  void set(String tab) => state = tab;
}

final albumsTabProvider =
    NotifierProvider<AlbumsTabNotifier, String>(AlbumsTabNotifier.new);

// ══════════════════════════════════════════════════════════════
//  PACK OPENING
// ══════════════════════════════════════════════════════════════
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