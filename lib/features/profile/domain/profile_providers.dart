import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_service.dart';
import '../domain/profile_models.dart';

// ─── SERVICE ──────────────────────────────────
final profileServiceProvider = Provider<ProfileService>(
  (_) => ProfileService(),
);

// ─── PERFIL PROPIO ────────────────────────────
final ownProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final service = ref.watch(profileServiceProvider);
  return service.fetchOwnProfile();
});

// ─── PERFIL PÚBLICO ───────────────────────────
final publicProfileProvider =
    FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final service = ref.watch(profileServiceProvider);
  return service.fetchPublicProfile(userId);
});

// ─── LOGROS (propios) ─────────────────────────
// Combina disponibles + IDs desbloqueados del usuario actual
class AchievementsState {
  final List<Achievement> available;
  final Set<String> unlockedIds;

  const AchievementsState({
    required this.available,
    required this.unlockedIds,
  });

  List<Achievement> get unlocked =>
      available.where((a) => unlockedIds.contains(a.id)).toList();

  List<Achievement> get locked =>
      available.where((a) => !unlockedIds.contains(a.id)).toList();

  double get progress =>
      available.isEmpty ? 0 : unlocked.length / available.length;
}

final achievementsProvider =
    FutureProvider.family<AchievementsState, String>((ref, userId) async {
  final service = ref.watch(profileServiceProvider);
  final available = await service.fetchAvailableAchievements();
  final ids = await service.fetchUserAchievementIds(userId);
  return AchievementsState(available: available, unlockedIds: ids.toSet());
});

// ─── TÍTULOS ──────────────────────────────────
class TitlesState {
  final List<UserTitle> available;
  final Set<String> unlockedIds;

  const TitlesState({required this.available, required this.unlockedIds});

  List<UserTitle> get unlocked =>
      available.where((t) => unlockedIds.contains(t.id)).toList();
}

final titlesProvider =
    FutureProvider.family<TitlesState, String>((ref, userId) async {
  final service = ref.watch(profileServiceProvider);
  final available = await service.fetchAvailableTitles();
  final ids = await service.fetchUserTitleIds(userId);
  return TitlesState(available: available, unlockedIds: ids.toSet());
});

// ─── BANNERS ──────────────────────────────────
final userBannersProvider =
    FutureProvider.family<List<UserBanner>, String>((ref, userId) async {
  final service = ref.watch(profileServiceProvider);
  return service.fetchUserBanners(userId);
});

// ─── CAMPEONATOS ──────────────────────────────
final championshipsProvider =
    FutureProvider.family<List<MonthlyChampionship>, String>(
        (ref, userId) async {
  final service = ref.watch(profileServiceProvider);
  return service.fetchChampionships(userId);
});

// ─── HISTORIAL ────────────────────────────────
final predictionHistoryProvider =
    FutureProvider.family<List<PredictionHistoryEntry>, String>(
        (ref, userId) async {
  final service = ref.watch(profileServiceProvider);
  return service.fetchPredictionHistory(userId);
});

// ─── RANKING POSITION ─────────────────────────
final rankPositionProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(profileServiceProvider);
  return service.fetchUserRankPosition(userId);
});

// ─── EDIT PROFILE NOTIFIER ────────────────────
class EditProfileNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  ProfileService get _service => ref.read(profileServiceProvider);

  Future<void> save({
    required String userId,
    required UpdateProfileInput input,
    required void Function() onSuccess,
    required void Function(String) onError,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateProfile(userId, input);
      state = const AsyncValue.data(null);
      onSuccess();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      onError(e.toString());
    }
  }

  Future<void> equipBanner({
    required String userId,
    required String? bannerUrl,
    required void Function() onSuccess,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.equipBanner(userId, bannerUrl);
      state = const AsyncValue.data(null);
      onSuccess();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final editProfileProvider =
    NotifierProvider<EditProfileNotifier, AsyncValue<void>>(
  EditProfileNotifier.new,
);