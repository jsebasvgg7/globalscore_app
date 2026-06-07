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

    final packs       = results[0] as AlbumPacks?;
    final collection  = results[1] as List<AlbumCollectionItem>;
    final definitions = results[2] as List<AlbumDefinition>;
    final progress    = results[3] as Map<String, AlbumProgress>;

    return AlbumsModel(
      packs:             packs,
      collection:        collection,
      definitions:       definitions,
      progressByAlbumId: progress,
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  PACK OPENING — mismo orden que React:
  //  1. Verificar sobres
  //  2. Obtener cartas
  //  3. Seleccionar cartas
  //  4. Decrement con optimistic lock ← PRIMERO antes de guardar
  //  5. Upsert colección
  //  6. Insertar historial
  // ═══════════════════════════════════════════════════════════
  Future<PackOpenResult> openPack(String userId) async {
    // 1. Verificar sobres disponibles
    final packsData = await _db
        .from('album_packs')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (packsData == null) throw Exception('No se encontró el registro de sobres');

    final packs = AlbumPacks.fromMap(packsData);
    if (packs.packsAvailable <= 0) {
      throw Exception('No tienes sobres disponibles');
    }

    // 2. Traer cartas activas por tipo en paralelo
    final cardResults = await Future.wait([
      _db.from('album_cards').select().eq('is_active', true).eq('drop_enabled', true).eq('card_type', 'player'),
      _db.from('album_cards').select().eq('is_active', true).eq('drop_enabled', true).eq('card_type', 'team'),
      _db.from('album_cards').select().eq('is_active', true).eq('drop_enabled', true).eq('card_type', 'competition'),
      _db.from('album_cards').select().eq('is_active', true).eq('drop_enabled', true).eq('card_type', 'event'),
    ]);

    final players      = (cardResults[0] as List).map((m) => AlbumCard.fromMap(m as Map<String, dynamic>)).toList();
    final teams        = (cardResults[1] as List).map((m) => AlbumCard.fromMap(m as Map<String, dynamic>)).toList();
    final competitions = (cardResults[2] as List).map((m) => AlbumCard.fromMap(m as Map<String, dynamic>)).toList();
    final events       = (cardResults[3] as List).map((m) => AlbumCard.fromMap(m as Map<String, dynamic>)).toList();

    // 3. Seleccionar cartas
    final playerCard      = players.isNotEmpty      ? _pickByRarity(players, boosted: packs.boostActive) : null;
    final teamCard        = teams.isNotEmpty         ? _pickRandom(teams)       : null;
    final competitionCard = competitions.isNotEmpty  ? _pickRandom(competitions) : null;
    final eventCard       = events.isNotEmpty        ? _pickRandom(events)      : null;

    // 4. ── OPTIMISTIC LOCK: decrement PRIMERO ──────────────
    //    Si packs_available cambió desde que lo leímos → el update
    //    no matchea ninguna fila → lanzamos error (igual que React)
    final newOpened = packs.totalPacksOpened + 1;
    final (newBoostActive, newBoostRemaining) = _computeBoost(
      boosted: packs.boostActive,
      boostRemaining: packs.boostPacksRemaining,
      newOpened: newOpened,
      totalPreviouslyOpened: packs.totalPacksOpened,
    );

    final updated = await _db
        .from('album_packs')
        .update({
          'packs_available':       packs.packsAvailable - 1,
          'total_packs_opened':    newOpened,
          'boost_active':          newBoostActive,
          'boost_packs_remaining': newBoostRemaining,
          'updated_at':            DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('packs_available', packs.packsAvailable) // ← optimistic lock
        .select();

    // Si no matcheó nada → otro proceso ya usó el sobre
    if ((updated as List).isEmpty) {
      throw Exception('No hay sobres disponibles');
    }

    // 5. Upsert colección (en paralelo)
    final drawn = [playerCard, teamCard, competitionCard, eventCard]
        .whereType<AlbumCard>()
        .toList();

    await Future.wait(drawn.map((card) => _upsertCollectionCard(userId, card)));

    // 6. Historial
    await _db.from('album_pack_history').insert({
      'user_id':              userId,
      'opened_at':            DateTime.now().toIso8601String(),
      'card_player_id':       playerCard?.id,
      'card_team_id':         teamCard?.id,
      'card_competition_id':  competitionCard?.id,
      'card_event_id':        eventCard?.id,
      'player_significance':  playerCard?.significanceLevel,
    });

    print('╔══ PACK OPENED ═══════════════════════════');
    print('║ player      : ${playerCard?.name ?? 'none'}  (${playerCard?.significanceLevel}★)  boosted=${ packs.boostActive}');
    print('║ team        : ${teamCard?.name ?? 'none'}');
    print('║ competition : ${competitionCard?.name ?? 'none'}');
    print('║ event       : ${eventCard?.name ?? 'none'}');
    print('║ boost next  : active=$newBoostActive remaining=$newBoostRemaining');
    print('╚════════════════════════════════════════');

    return PackOpenResult(
      player:      playerCard,
      team:        teamCard,
      competition: competitionCard,
      event:       eventCard,
    );
  }

  // ─── Boost logic (idéntica a React) ──────────────────────
  (bool active, int remaining) _computeBoost({
    required bool boosted,
    required int boostRemaining,
    required int newOpened,
    required int totalPreviouslyOpened,
  }) {
    // ¿Este sobre es el décimo? (mismo check que React: total anterior > 0)
    final boostTriggered = totalPreviouslyOpened > 0 && newOpened % 10 == 0;

    if (boostTriggered) {
      return (true, 3);
    } else if (boosted) {
      final remaining = boostRemaining - 1;
      return remaining <= 0 ? (false, 0) : (true, remaining);
    }
    return (false, 0);
  }

  // ─── Selección por rareza ─────────────────────────────────
  // Tasas base:  1★=55%  2★=25%  3★=12%  4★=7.5%  5★=0.5%   Σ=100
  // Tasas boost: 1★=40.3% 2★=25% 3★=19% 4★=14.5% 5★=1.2%   Σ=100
  //
  // IMPORTANTE: se usa una lista de records ordenada explícitamente porque
  // iterar sobre Map<int,double> en Dart preserva orden de inserción, pero
  // depender de eso es frágil. Lista garantiza el orden correcto de acumulado.
  AlbumCard _pickByRarity(List<AlbumCard> cards, {bool boosted = false}) {
    // (rareza, probabilidad) en orden de menor a mayor para acumular correctamente
    const baseRates = [
      (1, 55.0), (2, 25.0), (3, 12.0), (4, 7.5), (5, 0.5),
    ];
    const boostRates = [
      (1, 40.3), (2, 25.0), (3, 19.0), (4, 14.5), (5, 1.2),
    ];
    final rates = boosted ? boostRates : baseRates;

    // nextDouble() devuelve [0.0, 1.0) → escalar a (0, 100]
    final roll = _rng.nextDouble() * 100;
    int targetRarity = rates.last.$1; // fallback a la última rareza
    double cumulative = 0;

    for (final (rarity, pct) in rates) {
      cumulative += pct;
      if (roll < cumulative) {
        targetRarity = rarity;
        break;
      }
    }

    final candidates = cards
        .where((c) => c.significanceLevel == targetRarity)
        .toList();

    // Si no hay cartas de esa rareza, usar todo el pool como fallback
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