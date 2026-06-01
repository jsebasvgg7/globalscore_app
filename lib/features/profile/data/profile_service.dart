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
    final data = await _client
        .from('users')
        .select('achievements')
        .eq('id', userId)
        .single();

    final raw = data['achievements'];
    if (raw == null) return [];
    return (raw as List).map((e) => e.toString()).toList();
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
    final data = await _client
        .from('users')
        .select('titles')
        .eq('id', userId)
        .single();

    final raw = data['titles'];
    if (raw == null) return [];
    return (raw as List).map((e) => e.toString()).toList();
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
        .order('created_at', ascending: false)
        .limit(100);

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