import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ranking_service.dart';

// ── Service ──────────────────────────────────────────────────────────────────
final rankingServiceProvider = Provider<RankingService>((_) => RankingService());

// ── Tab state: 'global' | 'monthly' | 'halloffame' ───────────────────────────
class RankingTabNotifier extends Notifier<String> {
  @override
  String build() => 'global';

  void setTab(String tab) => state = tab;
}

final rankingTabProvider =
    NotifierProvider<RankingTabNotifier, String>(RankingTabNotifier.new);

// ── Users ─────────────────────────────────────────────────────────────────────
final rankingUsersProvider = FutureProvider<List<RankingUser>>((ref) {
  return ref.watch(rankingServiceProvider).fetchUsers();
});

// ── Champions (Hall of Fame) ──────────────────────────────────────────────────
final hofChampionsProvider = FutureProvider<List<HofChampion>>((ref) {
  return ref.watch(rankingServiceProvider).fetchChampions();
});