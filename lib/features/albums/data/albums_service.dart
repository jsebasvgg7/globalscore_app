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
    print('╔══ ALBUMS FETCH ══════════════════════════');

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

    print('║ packs disponibles : ${packs?.packsAvailable ?? 0}');
    print('║ cartas únicas     : ${collection.length}');
    print('║ álbumes activos   : ${definitions.length}');
    print('╚════════════════════════════════════════');

    return AlbumsModel(
      packs:             packs,
      collection:        collection,
      definitions:       definitions,
      progressByAlbumId: progress,
    );
  }

  // ─── Pack Opening (lógica local, sin Edge Function) ───────
  Future<PackOpenResult> openPack(String userId) async {
    // 1. Verificar sobres disponibles
    final packsData = await _db
        .from('album_packs')
        .select()
        .eq('user_id', userId)
        .single();

    final packs = AlbumPacks.fromMap(packsData);
    if (packs.packsAvailable <= 0) {
      throw Exception('No tienes sobres disponibles');
    }

    // 2. Traer todas las cartas activas agrupadas por tipo
    final allCardsData = await _db
        .from('album_cards')
        .select()
        .eq('is_active', true)
        .eq('drop_enabled', true);

    final allCards = (allCardsData as List)
        .map((m) => AlbumCard.fromMap(m))
        .toList();

    // 3. Separar por tipo
    final players      = allCards.where((c) => c.cardType == 'player').toList();
    final teams        = allCards.where((c) => c.cardType == 'team').toList();
    final competitions = allCards.where((c) => c.cardType == 'competition').toList();
    final events       = allCards.where((c) => c.cardType == 'event').toList();

    // 4. Seleccionar 1 carta de cada tipo con probabilidades por rareza
    final playerCard      = players.isNotEmpty      ? _pickByRarity(players)      : null;
    final teamCard        = teams.isNotEmpty         ? _pickRandom(teams)          : null;
    final competitionCard = competitions.isNotEmpty  ? _pickRandom(competitions)   : null;
    final eventCard       = events.isNotEmpty        ? _pickRandom(events)         : null;

    // 5. Guardar en colección e historial en paralelo
    await Future.wait([
      _saveToCollection(userId, playerCard),
      _saveToCollection(userId, teamCard),
      _saveToCollection(userId, competitionCard),
      _saveToCollection(userId, eventCard),
      _saveHistory(userId, playerCard, teamCard, competitionCard, eventCard),
      _decrementPack(userId, packs),
    ]);

    print('╔══ PACK OPENED ═══════════════════════════');
    print('║ player      : ${playerCard?.name ?? 'none'}  (${playerCard?.significanceLevel}★)');
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

  // ─── Selección por rareza (solo jugadores tienen rareza) ──
  AlbumCard _pickByRarity(List<AlbumCard> cards) {
    // Tasas de drop: 1★=55% 2★=25% 3★=12% 4★=7.5% 5★=0.5%
    const rates = {1: 55.0, 2: 25.0, 3: 12.0, 4: 7.5, 5: 0.5};

    // Determinar qué rareza salió
    final roll = _rng.nextDouble() * 100;
    int targetRarity = 1;
    double cumulative = 0;
    for (final entry in rates.entries) {
      cumulative += entry.value;
      if (roll < cumulative) {
        targetRarity = entry.key;
        break;
      }
    }

    // Filtrar cartas de esa rareza
    final candidates = cards
        .where((c) => c.significanceLevel == targetRarity)
        .toList();

    // Si no hay cartas de esa rareza, usar cualquiera
    final pool = candidates.isNotEmpty ? candidates : cards;
    return pool[_rng.nextInt(pool.length)];
  }

  // ─── Selección aleatoria simple ───────────────────────────
  AlbumCard _pickRandom(List<AlbumCard> cards) {
    return cards[_rng.nextInt(cards.length)];
  }

  // ─── Guardar/actualizar en colección ─────────────────────
  Future<void> _saveToCollection(String userId, AlbumCard? card) async {
    if (card == null) return;

    // Buscar si ya existe en la colección
    final existing = await _db
        .from('album_collection')
        .select()
        .eq('user_id', userId)
        .eq('card_id', card.id)
        .maybeSingle();

    if (existing != null) {
      // Ya la tiene → incrementar copias
      await _db
          .from('album_collection')
          .update({
            'copies': (existing['copies'] as int) + 1,
            'last_obtained_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);
    } else {
      // Nueva carta → insertar
      await _db.from('album_collection').insert({
        'user_id':          userId,
        'card_id':          card.id,
        'copies':           1,
        'frame_level':      'normal',
        'first_obtained_at': DateTime.now().toIso8601String(),
        'last_obtained_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ─── Guardar historial ────────────────────────────────────
  Future<void> _saveHistory(
    String userId,
    AlbumCard? player,
    AlbumCard? team,
    AlbumCard? competition,
    AlbumCard? event,
  ) async {
    await _db.from('album_pack_history').insert({
      'user_id':            userId,
      'opened_at':          DateTime.now().toIso8601String(),
      'card_player_id':     player?.id,
      'card_team_id':       team?.id,
      'card_competition_id': competition?.id,
      'card_event_id':      event?.id,
      'player_significance': player?.significanceLevel,
    });
  }

  // ─── Decrementar sobre + actualizar boost ─────────────────
  Future<void> _decrementPack(String userId, AlbumPacks current) async {
    final newOpened    = current.totalPacksOpened + 1;
    final newAvailable = current.packsAvailable - 1;

    // Boost: cada 10 sobres abiertos → activar boost con 3 sobres extra
    bool  newBoostActive    = current.boostActive;
    int   newBoostRemaining = current.boostPacksRemaining;

    if (current.boostActive) {
      // Consumir un sobre del boost
      newBoostRemaining = current.boostPacksRemaining - 1;
      if (newBoostRemaining <= 0) {
        newBoostActive    = false;
        newBoostRemaining = 0;
      }
    } else if (newOpened % 10 == 0) {
      // Activar boost
      newBoostActive    = true;
      newBoostRemaining = 3;
    }

    await _db.from('album_packs').update({
      'packs_available':      newAvailable,
      'total_packs_opened':   newOpened,
      'boost_active':         newBoostActive,
      'boost_packs_remaining': newBoostRemaining,
      'updated_at':           DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }
}