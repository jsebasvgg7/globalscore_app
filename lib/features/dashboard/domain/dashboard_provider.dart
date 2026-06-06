import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/dashboard_service.dart';

// ══════════════════════════════════════════════════════════════
//  USUARIO ACTUAL — FutureProvider simple (no cambia en sesión)
// ══════════════════════════════════════════════════════════════

final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return DashboardService.getCurrentUser();
});

// ══════════════════════════════════════════════════════════════
//  MATCHES — StreamProvider con Supabase Realtime
//  Se actualiza automáticamente cuando cambia la tabla 'matches'
//  o 'predictions' en la base de datos, sin recargar la app.
// ══════════════════════════════════════════════════════════════

final _matchesStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield [];
    return;
  }
  final userId = user['id'] as String;

  // Emitir datos iniciales inmediatamente
  yield await DashboardService.getMatchesWithPredictions(userId);

  // Suscribirse a cambios en 'matches' Y 'predictions'
  final controller = StreamController<List<Map<String, dynamic>>>();

  Future<void> reload() async {
    if (controller.isClosed) return;
    try {
      final data = await DashboardService.getMatchesWithPredictions(userId);
      if (!controller.isClosed) controller.add(data);
    } catch (_) {}
  }

  final channelMatches = Supabase.instance.client
      .channel('realtime-matches')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'matches',
        callback: (_) => reload(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'predictions',
        callback: (_) => reload(),
      )
      .subscribe();

  ref.onDispose(() {
    channelMatches.unsubscribe();
    controller.close();
  });

  yield* controller.stream;
});

// ══════════════════════════════════════════════════════════════
//  LEAGUES — StreamProvider con Realtime
// ══════════════════════════════════════════════════════════════

final _leaguesStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield [];
    return;
  }
  final userId = user['id'] as String;

  yield await DashboardService.getLeaguesWithPredictions(userId);

  final controller = StreamController<List<Map<String, dynamic>>>();

  Future<void> reload() async {
    if (controller.isClosed) return;
    try {
      final data = await DashboardService.getLeaguesWithPredictions(userId);
      if (!controller.isClosed) controller.add(data);
    } catch (_) {}
  }

  final channel = Supabase.instance.client
      .channel('realtime-leagues')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'leagues',
        callback: (_) => reload(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'league_predictions',
        callback: (_) => reload(),
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  yield* controller.stream;
});

// ══════════════════════════════════════════════════════════════
//  AWARDS — StreamProvider con Realtime
// ══════════════════════════════════════════════════════════════

final _awardsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield [];
    return;
  }
  final userId = user['id'] as String;

  yield await DashboardService.getAwardsWithPredictions(userId);

  final controller = StreamController<List<Map<String, dynamic>>>();

  Future<void> reload() async {
    if (controller.isClosed) return;
    try {
      final data = await DashboardService.getAwardsWithPredictions(userId);
      if (!controller.isClosed) controller.add(data);
    } catch (_) {}
  }

  final channel = Supabase.instance.client
      .channel('realtime-awards')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'awards',
        callback: (_) => reload(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'award_predictions',
        callback: (_) => reload(),
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  yield* controller.stream;
});

// ══════════════════════════════════════════════════════════════
//  TOP USERS — polling cada 60 segundos
//  El ranking no necesita realtime instantáneo
// ══════════════════════════════════════════════════════════════

final _topUsersStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  yield await DashboardService.getTopUsers();

  final controller = StreamController<List<Map<String, dynamic>>>();

  final timer = Timer.periodic(const Duration(seconds: 60), (_) async {
    if (controller.isClosed) return;
    try {
      final data = await DashboardService.getTopUsers();
      if (!controller.isClosed) controller.add(data);
    } catch (_) {}
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  yield* controller.stream;
});

// ══════════════════════════════════════════════════════════════
//  DASHBOARD DATA — combina los 4 streams en un único provider
//  que el resto de la app ya conoce con la misma firma que antes
// ══════════════════════════════════════════════════════════════

final dashboardDataProvider =
    Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final matchesAsync  = ref.watch(_matchesStreamProvider);
  final leaguesAsync  = ref.watch(_leaguesStreamProvider);
  final awardsAsync   = ref.watch(_awardsStreamProvider);
  final topUsersAsync = ref.watch(_topUsersStreamProvider);

  // Si cualquiera está cargando, mostrar loading
  if (matchesAsync.isLoading ||
      leaguesAsync.isLoading ||
      awardsAsync.isLoading ||
      topUsersAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // Si cualquiera tiene error, propagarlo
  final firstError = [matchesAsync, leaguesAsync, awardsAsync, topUsersAsync]
      .firstWhere(
        (a) => a.hasError,
        orElse: () => AsyncValue<List<Map<String, dynamic>>>.data([]),
      );
  if (firstError.hasError) {
    return AsyncValue.error(firstError.error!, firstError.stackTrace!);
  }

  return AsyncValue.data({
    'matches':  matchesAsync.value  ?? [],
    'leagues':  leaguesAsync.value  ?? [],
    'awards':   awardsAsync.value   ?? [],
    'topUsers': topUsersAsync.value ?? [],
  });
});