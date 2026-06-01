import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile_models.dart';

class ProfileService {
  final _client = Supabase.instance.client;

  // ─── PERFIL PROPIO ────────────────────────────
  Future<UserProfile?> fetchOwnProfile() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) return null;

    final data = await _client
        .from('users')
        .select()
        .eq('auth_id', authId)
        .single();

    return UserProfile.fromJson(data);
  }

  // ─── PERFIL PÚBLICO ───────────────────────────
  Future<UserProfile?> fetchPublicProfile(String userId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return UserProfile.fromJson(data);
  }

  // ─── ACTUALIZAR PERFIL ────────────────────────
  Future<void> updateProfile(String userId, UpdateProfileInput input) async {
    await _client
        .from('users')
        .update(input.toJson())
        .eq('id', userId);
  }

  // ─── SUBIR AVATAR (Cloudinary via upload_url) ─
  // El upload real a Cloudinary se hace en el cliente con http package.
  // Este método solo actualiza la URL en Supabase.
  Future<void> updateAvatarUrl(String userId, String avatarUrl) async {
    await _client
        .from('users')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);
  }

// ─── LOGROS ───────────────────────────────────
Future<List<Achievement>> fetchAvailableAchievements() async {
  final data = await _client
      .from('available_achievements')
      .select()
      .order('requirement_value', ascending: true);

  return (data as List)
      .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<String>> fetchUserAchievementIds(String userId) async {
  // 1. Leer achievements guardados + stats del usuario
  final userData = await _client
      .from('users')
      .select('achievements, points, predictions, correct, best_streak')
      .eq('id', userId)
      .single();

  final stored = List<String>.from(userData['achievements'] as List? ?? []);
  final stats = {
    'points':       (userData['points']       as int?) ?? 0,
    'predictions':  (userData['predictions']  as int?) ?? 0,
    'correct':      (userData['correct']      as int?) ?? 0,
    'streak':       (userData['best_streak']  as int?) ?? 0,
  };

  // 2. Cargar todos los logros disponibles
  final available = await fetchAvailableAchievements();

  // 3. Calcular nuevos desbloqueos (igual que React)
  final newUnlocks = <String>[];
  for (final a in available) {
    if (stored.contains(a.id)) continue;
    final req = a.requirementType;
    final val = a.requirementValue ?? 0;
    final current = stats[req] ?? 0;
    if (current >= val) newUnlocks.add(a.id);
  }

  // 4. Si hay nuevos, escribir en BD (igual que React)
  if (newUnlocks.isNotEmpty) {
    final updated = [...stored, ...newUnlocks];
    await _client
        .from('users')
        .update({'achievements': updated})
        .eq('id', userId);
    return updated;
  }

  return stored;
}

// ─── TÍTULOS ──────────────────────────────────
Future<List<UserTitle>> fetchAvailableTitles() async {
  final data = await _client
      .from('available_titles')
      .select();

  return (data as List)
      .map((e) => UserTitle.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<String>> fetchUserTitleIds(String userId) async {
  final unlockedAchievements = await fetchUserAchievementIds(userId);
  final unlockedSet = unlockedAchievements.toSet();

  final allTitles = await fetchAvailableTitles();

  return allTitles
      .where((t) =>
          t.requirementAchievementId == null ||
          unlockedSet.contains(t.requirementAchievementId))
      .map((t) => t.id)
      .toList();
}

  // ─── BANNERS ──────────────────────────────────
  Future<List<UserBanner>> fetchUserBanners(String userId) async {
    final data = await _client
        .from('user_banners')
        .select('available_banners(*)')
        .eq('user_id', userId);

    return (data as List)
        .map((e) => UserBanner.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> equipBanner(String userId, String? bannerUrl) async {
    await _client
        .from('users')
        .update({'equipped_banner_url': bannerUrl})
        .eq('id', userId);
  }

  // ─── CAMPEONATOS MENSUALES ────────────────────
  Future<List<MonthlyChampionship>> fetchChampionships(String userId) async {
    final data = await _client
        .from('monthly_championship_history')
        .select()
        .eq('user_id', userId)
        .order('awarded_at', ascending: false);

    return (data as List)
        .map((e) => MonthlyChampionship.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── HISTORIAL DE PREDICCIONES ────────────────
  Future<List<PredictionHistoryEntry>> fetchPredictionHistory(
    String userId,
  ) async {
    final data = await _client
        .from('predictions')
        .select('*, matches(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    // ← Sin .limit(100)

    return (data as List)
        .map(
          (e) => PredictionHistoryEntry.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  // ─── RANKING POSITION ─────────────────────────
  Future<int> fetchUserRankPosition(String userId) async {
    // Cuenta cuántos usuarios tienen más puntos
    final data = await _client
        .from('users')
        .select('id')
        .gt('points', 0); // traemos todos para contar

    // Traemos puntos del usuario actual
    final me = await _client
        .from('users')
        .select('points')
        .eq('id', userId)
        .single();

    final myPoints = (me['points'] as int?) ?? 0;
    final usersAhead = (data as List)
        .where((u) => (u['points'] as int? ?? 0) > myPoints)
        .length;

    return usersAhead + 1;
  }
}