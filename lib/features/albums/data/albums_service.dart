import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/albums_model.dart';

class AlbumsService {
  final _db = Supabase.instance.client;

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

    AlbumPacks? packs;
    List<AlbumCollectionItem> collection = [];
    List<AlbumDefinition> definitions = [];
    Map<String, AlbumProgress> progress = {};

    final results = await Future.wait([
      fetchPacks(userId),
      fetchCollection(userId),
      fetchDefinitions(),
      fetchProgress(userId),
    ]);

    packs       = results[0] as AlbumPacks?;
    collection  = results[1] as List<AlbumCollectionItem>;
    definitions = results[2] as List<AlbumDefinition>;
    progress    = results[3] as Map<String, AlbumProgress>;

    print('║ packs disponibles : ${packs?.packsAvailable ?? 0}');
    print('║ cartas únicas     : ${collection.length}');
    print('║ álbumes activos   : ${definitions.length}');
    print('╚════════════════════════════════════════');

    return AlbumsModel(
      packs:              packs,
      collection:         collection,
      definitions:        definitions,
      progressByAlbumId:  progress,
    );
  }

  // ─── Pack Opening (llama Edge Function) ───────────────────
  Future<PackOpenResult> openPack(String userId) async {
    final response = await _db.functions.invoke(
      'open-album-pack',
      body: {'user_id': userId},
    );

    if (response.status != 200) {
      throw Exception('Error abriendo sobre: ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;

    AlbumCard? _parseCard(String key) {
      final m = data[key] as Map<String, dynamic>?;
      return m != null ? AlbumCard.fromMap(m) : null;
    }

    return PackOpenResult(
      player:      _parseCard('player'),
      team:        _parseCard('team'),
      competition: _parseCard('competition'),
      event:       _parseCard('event'),
    );
  }
}
