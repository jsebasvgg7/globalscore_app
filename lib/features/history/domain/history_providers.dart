import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/history_service.dart';
import '../domain/history_models.dart';

// ── Service ───────────────────────────────────────────────────────────────────
final historyServiceProvider =
    Provider<HistoryService>((_) => HistoryService());

// ══════════════════════════════════════════════════════════════
//  SECTION — which tab is active on the landing
//  'vault' | 'competitions' | 'events' | 'teams' | 'players'
// ══════════════════════════════════════════════════════════════

class HistorySectionNotifier extends Notifier<String> {
  @override
  String build() => 'vault';

  void setSection(String section) => state = section;
  void goBack() => state = 'vault';
}

final historySectionProvider =
    NotifierProvider<HistorySectionNotifier, String>(HistorySectionNotifier.new);

// ══════════════════════════════════════════════════════════════
//  STATS (landing counters)
// ══════════════════════════════════════════════════════════════

final historyStatsProvider = FutureProvider<HistoryStats>((ref) {
  return ref.watch(historyServiceProvider).fetchStats();
});

// ══════════════════════════════════════════════════════════════
//  PLAYERS
// ══════════════════════════════════════════════════════════════

final historyPlayersProvider = FutureProvider<List<HistoricalPlayer>>((ref) {
  return ref.watch(historyServiceProvider).fetchPlayers();
});

final playerSearchProvider = StateProvider<String>((_) => '');
final playerPositionFilterProvider = StateProvider<String>((_) => '');

final filteredPlayersProvider = Provider<AsyncValue<List<HistoricalPlayer>>>((ref) {
  final playersAsync = ref.watch(historyPlayersProvider);
  final search = ref.watch(playerSearchProvider).toLowerCase();
  final position = ref.watch(playerPositionFilterProvider);

  return playersAsync.whenData((players) {
    return players.where((p) {
      final matchesSearch = search.isEmpty ||
          p.name.toLowerCase().contains(search) ||
          (p.country?.toLowerCase().contains(search) ?? false);
      final matchesPosition = position.isEmpty || p.position == position;
      return matchesSearch && matchesPosition;
    }).toList();
  });
});

// ══════════════════════════════════════════════════════════════
//  SELECTED PLAYER (for detail side panel / route)
// ══════════════════════════════════════════════════════════════

final selectedPlayerProvider = StateProvider<HistoricalPlayer?>((_) => null);

// ══════════════════════════════════════════════════════════════
//  TEAMS
// ══════════════════════════════════════════════════════════════

final historyTeamsProvider = FutureProvider<List<HistoricalTeam>>((ref) {
  return ref.watch(historyServiceProvider).fetchTeams();
});

final teamSearchProvider = StateProvider<String>((_) => '');

final filteredTeamsProvider = Provider<AsyncValue<List<HistoricalTeam>>>((ref) {
  final teamsAsync = ref.watch(historyTeamsProvider);
  final search = ref.watch(teamSearchProvider).toLowerCase();

  return teamsAsync.whenData((teams) {
    if (search.isEmpty) return teams;
    return teams.where((t) {
      return t.name.toLowerCase().contains(search) ||
          (t.country?.toLowerCase().contains(search) ?? false) ||
          (t.era?.toLowerCase().contains(search) ?? false);
    }).toList();
  });
});

final selectedTeamProvider = StateProvider<HistoricalTeam?>((_) => null);

// ══════════════════════════════════════════════════════════════
//  COMPETITIONS
// ══════════════════════════════════════════════════════════════

final historyCompetitionsProvider =
    FutureProvider<List<HistoricalCompetition>>((ref) {
  return ref.watch(historyServiceProvider).fetchCompetitions();
});

final competitionSearchProvider = StateProvider<String>((_) => '');
final competitionTypeFilterProvider = StateProvider<String>((_) => '');
final competitionFormatFilterProvider = StateProvider<String>((_) => '');

final filteredCompetitionsProvider =
    Provider<AsyncValue<List<HistoricalCompetition>>>((ref) {
  final compsAsync = ref.watch(historyCompetitionsProvider);
  final search = ref.watch(competitionSearchProvider).toLowerCase();
  final type = ref.watch(competitionTypeFilterProvider);
  final format = ref.watch(competitionFormatFilterProvider);

  return compsAsync.whenData((comps) {
    return comps.where((c) {
      final matchesSearch = search.isEmpty ||
          c.name.toLowerCase().contains(search) ||
          (c.country?.toLowerCase().contains(search) ?? false);
      final matchesType = type.isEmpty || c.type == type;
      final matchesFormat = format.isEmpty || c.format == format;
      return matchesSearch && matchesType && matchesFormat;
    }).toList();
  });
});

final selectedCompetitionProvider =
    StateProvider<HistoricalCompetition?>((_) => null);

final competitionDetailProvider =
    FutureProvider.family<CompetitionDetail, String>((ref, id) {
  return ref.watch(historyServiceProvider).fetchCompetitionDetail(id);
});

// ══════════════════════════════════════════════════════════════
//  EVENTS
// ══════════════════════════════════════════════════════════════

final historyEventsProvider = FutureProvider<List<HistoricalEvent>>((ref) {
  return ref.watch(historyServiceProvider).fetchEvents();
});

final eventSearchProvider = StateProvider<String>((_) => '');
final eventCategoryFilterProvider = StateProvider<String>((_) => '');
final eventTypeFilterProvider = StateProvider<String>((_) => '');

final filteredEventsProvider =
    Provider<AsyncValue<List<HistoricalEvent>>>((ref) {
  final eventsAsync = ref.watch(historyEventsProvider);
  final search = ref.watch(eventSearchProvider).toLowerCase();
  final category = ref.watch(eventCategoryFilterProvider);
  final type = ref.watch(eventTypeFilterProvider);

  return eventsAsync.whenData((events) {
    return events.where((e) {
      final matchesSearch = search.isEmpty ||
          e.title.toLowerCase().contains(search) ||
          (e.teamAName?.toLowerCase().contains(search) ?? false) ||
          (e.teamBName?.toLowerCase().contains(search) ?? false);
      final matchesCategory = category.isEmpty || e.eventCategory == category;
      final matchesType = type.isEmpty || e.eventType == type;
      return matchesSearch && matchesCategory && matchesType;
    }).toList();
  });
});

final selectedEventProvider = StateProvider<HistoricalEvent?>((_) => null);

final eventDetailProvider =
    FutureProvider.family<EventDetail, String>((ref, id) {
  return ref.watch(historyServiceProvider).fetchEventDetail(id);
});

// ══════════════════════════════════════════════════════════════
//  RANDOM ITEM SPINNER — picks random item from current section
// ══════════════════════════════════════════════════════════════

class SpinnerNotifier extends Notifier<SpinnerState> {
  @override
  SpinnerState build() => const SpinnerState();

  void spin() => state = state.copyWith(isSpinning: true);
  void land(SpinnerResult result) =>
      state = state.copyWith(isSpinning: false, result: result);
  void clear() => state = const SpinnerState();
}

final spinnerProvider =
    NotifierProvider<SpinnerNotifier, SpinnerState>(SpinnerNotifier.new);

class SpinnerState {
  final bool isSpinning;
  final SpinnerResult? result;

  const SpinnerState({this.isSpinning = false, this.result});

  SpinnerState copyWith({bool? isSpinning, SpinnerResult? result}) =>
      SpinnerState(
        isSpinning: isSpinning ?? this.isSpinning,
        result: result ?? this.result,
      );
}

class SpinnerResult {
  final String type; // 'player' | 'team' | 'competition' | 'event'
  final String id;
  final String name;
  final String? imagePath;

  const SpinnerResult({
    required this.type,
    required this.id,
    required this.name,
    this.imagePath,
  });
}
