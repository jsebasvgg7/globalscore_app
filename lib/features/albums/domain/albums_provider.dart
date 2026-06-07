import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/albums_service.dart';
import '../domain/albums_model.dart';

// ══════════════════════════════════════════════════════════════
//  USER ID — resuelve auth_id → id interno una sola vez
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
//  ALBUMS — StreamProvider con Realtime
//  Escucha cambios en album_packs, album_collection y
//  album_progress para reflejar cualquier cambio en tiempo real.
//  album_definitions y album_cards casi nunca cambian,
//  se cargan una vez al inicio.
// ══════════════════════════════════════════════════════════════

final albumsProvider = StreamProvider<AlbumsModel>((ref) async* {
  final userId = await ref.watch(albumsUserIdProvider.future);
  final service = AlbumsService();

  // Emitir estado inicial inmediatamente
  yield await service.fetchAll(userId);

  final controller = StreamController<AlbumsModel>();

  // Debounce: si llegan varios eventos Realtime en ráfaga (ej. album_packs +
  // album_collection al mismo tiempo al abrir un sobre), no disparamos 4
  // fetchAll en paralelo — esperamos 400ms y hacemos uno solo.
  Timer? debounce;
  Future<void> reload() async {
    if (controller.isClosed) return;
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), () async {
      if (controller.isClosed) return;
      try {
        final model = await service.fetchAll(userId);
        if (!controller.isClosed) controller.add(model);
      } catch (_) {}
    });
  }

  // Nombre de canal con timestamp para evitar colisión si el provider
  // se descarta y re-crea rápidamente (ej. por ref.invalidate externo)
  final channelName =
      'realtime-albums-$userId-${DateTime.now().millisecondsSinceEpoch}';

  final channel = Supabase.instance.client
      .channel(channelName)
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'album_packs',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) => reload(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'album_collection',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) => reload(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'album_progress',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) => reload(),
      )
      .subscribe();

  ref.onDispose(() {
    debounce?.cancel();
    channel.unsubscribe();
    controller.close();
  });

  yield* controller.stream;
});

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
//  PACK OPENING — igual que antes, ref.invalidate ya no hace
//  falta porque el StreamProvider escucha el cambio automáticamente.
//  Lo dejamos por compatibilidad y como fallback de seguridad.
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
      // El StreamProvider ya detectará el cambio en album_packs automáticamente.
      // ref.invalidate(albumsProvider) ya no es necesario pero no hace daño.
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