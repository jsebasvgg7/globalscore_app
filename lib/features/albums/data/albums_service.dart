import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/albums_model.dart';

class AlbumsService {
  final _db = Supabase.instance.client;
  final _rng = Random();

  // ─── Packs ────────────────────────────────────────────────
  Future<AlbumPacks?> fetchPacks(String userId) async {
    try {
      final data = await _db
          .from('album_packs')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return data != null ? AlbumPacks.fromMap(data) : null;
    } catch (e) {
      print('[AlbumsService] fetchPacks error: $e');
      return null;
    }
  }

  // ─── Collection ───────────────────────────────────────────
  Future<List<AlbumCollectionItem>> fetchCollection(String userId) async {
    final data = await _db
        .from('album_collection')
        .select('*, album_cards(*)')
        .eq('user_id', userId)
        .order('last_obtained_at', ascending: false);
    return (data as List).map((m) => AlbumCollectionItem.fromMap(m)).toList();
  }

  // ─── Definitions ──────────────────────────────────────────
  Future<List<AlbumDefinition>> fetchDefinitions() async {
    final data = await _db
        .from('album_definitions')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (data as List).map((m) => AlbumDefinition.fromMap(m)).toList();
  }

  // ─── Progress ─────────────────────────────────────────────
  Future<Map<String, AlbumProgress>> fetchProgress(String userId) async {
    final data = await _db
        .from('album_progress')
        .select()
        .eq('user_id', userId);
    final list = (data as List).map((m) => AlbumProgress.fromMap(m)).toList();
    return {for (final p in list) p.albumId: p};
  }

  // ─── Todo en paralelo ─────────────────────────────────────
  Future<AlbumsModel> fetchAll(String userId) async {
    final results = await Future.wait([
      fetchPacks(userId),
      fetchCollection(userId),
      fetchDefinitions(),
      fetchProgress(userId),
    ]);

    return AlbumsModel(
      packs:             results[0] as AlbumPacks?,
      collection:        results[1] as List<AlbumCollectionItem>,
      definitions:       results[2] as List<AlbumDefinition>,
      progressByAlbumId: results[3] as Map<String, AlbumProgress>,
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  PACK OPENING — flujo simplificado
  //
  //  ANTES: optimistic lock en Flutter con .update().eq().eq().select()
  //         → frágil, dependía de que RLS y supabase_flutter retornen
  //           filas después del update (no siempre pasa).
  //
  //  AHORA: open_pack_atomic() hace todo en Postgres con FOR UPDATE.
  //         Flutter solo llama al RPC, verifica success, y si es true
  //         procede a seleccionar y guardar las cartas.
  //
  //  Orden:
  //    1. RPC open_pack_atomic → decrementa ticket atómicamente
  //    2. Obtener cartas activas en paralelo
  //    3. Seleccionar cartas por rareza
  //    4. Upsert colección
  //    5. Insertar historial
  // ═══════════════════════════════════════════════════════════
  Future<PackOpenResult> openPack(String userId) async {
    // ── 1. Decremento atómico via RPC ──────────────────────
    final rpcResult = await _db.rpc(
      'open_pack_atomic',
      params: {'p_user_id': userId},
    );

    // rpcResult es un Map con las claves: success, reason, new_available, etc.
    final resultMap = rpcResult as Map<String, dynamic>;
    final success = resultMap['success'] as bool? ?? false;

    if (!success) {
      final reason = resultMap['reason'] as String? ?? 'unknown';
      if (reason == 'no_tickets') {
        throw Exception('No tienes sobres disponibles');
      }
      throw Exception('Error al abrir sobre: $reason');
    }

    final boostActive = resultMap['boost_active'] as bool? ?? false;

    print('[AlbumsService] openPack: RPC ok — '
        'available=${resultMap['new_available']} '
        'opened=${resultMap['new_opened']} '
        'boost=$boostActive');

    // ── 2. Obtener cartas activas en paralelo ──────────────
    final cardResults = await Future.wait([
      _db.from('album_cards').select()
          .eq('is_active', true).eq('drop_enabled', true).eq('card_type', 'player'),
      _db.from('album_cards').select()
          .eq('is_active', true).eq('drop_enabled', true).eq('card_type', 'team'),
      _db.from('album_cards').select()
          .eq('is_active', true).eq('drop_enabled', true).eq('card_type', 'competition'),
      _db.from('album_cards').select()
          .eq('is_active', true).eq('drop_enabled', true).eq('card_type', 'event'),
    ]);

    final players      = (cardResults[0] as List).map((m) => AlbumCard.fromMap(m as Map<String, dynamic>)).toList();
    final teams        = (cardResults[1] as List).map((m) => AlbumCard.fromMap(m as Map<String, dynamic>)).toList();
    final competitions = (cardResults[2] as List).map((m) => AlbumCard.fromMap(m as Map<String, dynamic>)).toList();
    final events       = (cardResults[3] as List).map((m) => AlbumCard.fromMap(m as Map<String, dynamic>)).toList();

    // ── 3. Seleccionar cartas ──────────────────────────────
    final playerCard      = players.isNotEmpty      ? _pickByRarity(players, boosted: boostActive) : null;
    final teamCard        = teams.isNotEmpty         ? _pickRandom(teams)        : null;
    final competitionCard = competitions.isNotEmpty  ? _pickRandom(competitions) : null;
    final eventCard       = events.isNotEmpty        ? _pickRandom(events)       : null;

    // ── 4. Upsert colección ────────────────────────────────
    final drawn = [playerCard, teamCard, competitionCard, eventCard]
        .whereType<AlbumCard>()
        .toList();

    await Future.wait(drawn.map((card) => _upsertCollectionCard(userId, card)));

    // ── 5. Historial ───────────────────────────────────────
    await _db.from('album_pack_history').insert({
      'user_id':             userId,
      'opened_at':           DateTime.now().toIso8601String(),
      'card_player_id':      playerCard?.id,
      'card_team_id':        teamCard?.id,
      'card_competition_id': competitionCard?.id,
      'card_event_id':       eventCard?.id,
      'player_significance': playerCard?.significanceLevel,
    });

    print('╔══ PACK OPENED ═══════════════════════════');
    print('║ player      : ${playerCard?.name ?? 'none'}  (${playerCard?.significanceLevel}★)  boosted=$boostActive');
    print('║ team        : ${teamCard?.name ?? 'none'}');
    print('║ competition : ${competitionCard?.name ?? 'none'}');
    print('║ event       : ${eventCard?.name ?? 'none'}');
    print('╚════════════════════════════════════════');

    return PackOpenResult(
      player:      playerCard,
      team:        teamCard,
      competition: competitionCard,
      event:       eventCard,
    );
  }

  // ─── Selección por rareza ─────────────────────────────────
  AlbumCard _pickByRarity(List<AlbumCard> cards, {bool boosted = false}) {
    const baseRates = [
      (1, 55.0), (2, 25.0), (3, 12.0), (4, 7.5), (5, 0.5),
    ];
    const boostRates = [
      (1, 40.3), (2, 25.0), (3, 19.0), (4, 14.5), (5, 1.2),
    ];
    final rates = boosted ? boostRates : baseRates;

    final roll = _rng.nextDouble() * 100;
    int targetRarity = rates.last.$1;
    double cumulative = 0;

    for (final (rarity, pct) in rates) {
      cumulative += pct;
      if (roll < cumulative) {
        targetRarity = rarity;
        break;
      }
    }

    final candidates = cards.where((c) => c.significanceLevel == targetRarity).toList();
    final pool = candidates.isNotEmpty ? candidates : cards;
    return pool[_rng.nextInt(pool.length)];
  }

  AlbumCard _pickRandom(List<AlbumCard> cards) =>
      cards[_rng.nextInt(cards.length)];

  Future<void> _upsertCollectionCard(String userId, AlbumCard card) async {
    await _db.rpc('upsert_collection_card', params: {
      'p_user_id': userId,
      'p_card_id': card.id,
      'p_now':     DateTime.now().toIso8601String(),
    });
  }
}