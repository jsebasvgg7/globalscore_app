import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/history_service.dart';
import '../domain/history_models.dart';

// ── Service ───────────────────────────────────────────────────────────────────
final historyServiceProvider =
    Provider<HistoryService>((_) => HistoryService());

// ══════════════════════════════════════════════════════════════
//  SECTION — 'vault' | 'competitions' | 'events' | 'teams' | 'players'
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
//  STATS
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

// String filters — Riverpod 3: usa Notifier en lugar de StateProvider
class _StringNotifier extends Notifier<String> {
  final String _initial;
  _StringNotifier(this._initial);
  @override
  String build() => _initial;
  void set(String v) => state = v;
}

final playerSearchProvider =
    NotifierProvider<_StringNotifier, String>(() => _StringNotifier(''));
final playerPositionFilterProvider =
    NotifierProvider<_StringNotifier, String>(() => _StringNotifier(''));
final teamSearchProvider =
    NotifierProvider<_StringNotifier, String>(() => _StringNotifier(''));
final competitionSearchProvider =
    NotifierProvider<_StringNotifier, String>(() => _StringNotifier(''));
final competitionTypeFilterProvider =
    NotifierProvider<_StringNotifier, String>(() => _StringNotifier(''));
final competitionFormatFilterProvider =
    NotifierProvider<_StringNotifier, String>(() => _StringNotifier(''));
final eventSearchProvider =
    NotifierProvider<_StringNotifier, String>(() => _StringNotifier(''));
final eventCategoryFilterProvider =
    NotifierProvider<_StringNotifier, String>(() => _StringNotifier(''));
final eventTypeFilterProvider =
    NotifierProvider<_StringNotifier, String>(() => _StringNotifier(''));

// Nullable entity selection notifiers
class _PlayerNotifier extends Notifier<HistoricalPlayer?> {
  @override
  HistoricalPlayer? build() => null;
  void select(HistoricalPlayer? p) => state = p;
}

class _TeamNotifier extends Notifier<HistoricalTeam?> {
  @override
  HistoricalTeam? build() => null;
  void select(HistoricalTeam? t) => state = t;
}

class _CompetitionNotifier extends Notifier<HistoricalCompetition?> {
  @override
  HistoricalCompetition? build() => null;
  void select(HistoricalCompetition? c) => state = c;
}

class _EventNotifier extends Notifier<HistoricalEvent?> {
  @override
  HistoricalEvent? build() => null;
  void select(HistoricalEvent? e) => state = e;
}

final selectedPlayerProvider =
    NotifierProvider<_PlayerNotifier, HistoricalPlayer?>(_PlayerNotifier.new);
final selectedTeamProvider =
    NotifierProvider<_TeamNotifier, HistoricalTeam?>(_TeamNotifier.new);
final selectedCompetitionProvider =
    NotifierProvider<_CompetitionNotifier, HistoricalCompetition?>(_CompetitionNotifier.new);
final selectedEventProvider =
    NotifierProvider<_EventNotifier, HistoricalEvent?>(_EventNotifier.new);

// ══════════════════════════════════════════════════════════════
//  FILTERED PROVIDERS
// ══════════════════════════════════════════════════════════════

final filteredPlayersProvider =
    Provider<AsyncValue<List<HistoricalPlayer>>>((ref) {
  final playersAsync = ref.watch(historyPlayersProvider);
  final search = ref.watch(playerSearchProvider).toLowerCase();
  final position = ref.watch(playerPositionFilterProvider);
  return playersAsync.whenData((players) => players.where((p) {
        final matchesSearch = search.isEmpty ||
            p.name.toLowerCase().contains(search) ||
            (p.country?.toLowerCase().contains(search) ?? false);
        final matchesPosition = position.isEmpty || p.position == position;
        return matchesSearch && matchesPosition;
      }).toList());
});

final historyTeamsProvider = FutureProvider<List<HistoricalTeam>>((ref) {
  return ref.watch(historyServiceProvider).fetchTeams();
});

final filteredTeamsProvider =
    Provider<AsyncValue<List<HistoricalTeam>>>((ref) {
  final teamsAsync = ref.watch(historyTeamsProvider);
  final search = ref.watch(teamSearchProvider).toLowerCase();
  return teamsAsync.whenData((teams) {
    if (search.isEmpty) return teams;
    return teams.where((t) =>
        t.name.toLowerCase().contains(search) ||
        (t.country?.toLowerCase().contains(search) ?? false) ||
        (t.era?.toLowerCase().contains(search) ?? false)).toList();
  });
});

final historyCompetitionsProvider =
    FutureProvider<List<HistoricalCompetition>>((ref) {
  return ref.watch(historyServiceProvider).fetchCompetitions();
});

final filteredCompetitionsProvider =
    Provider<AsyncValue<List<HistoricalCompetition>>>((ref) {
  final compsAsync = ref.watch(historyCompetitionsProvider);
  final search = ref.watch(competitionSearchProvider).toLowerCase();
  final type = ref.watch(competitionTypeFilterProvider);
  final format = ref.watch(competitionFormatFilterProvider);
  return compsAsync.whenData((comps) => comps.where((c) {
        final matchesSearch = search.isEmpty ||
            c.name.toLowerCase().contains(search) ||
            (c.country?.toLowerCase().contains(search) ?? false);
        return matchesSearch &&
            (type.isEmpty || c.type == type) &&
            (format.isEmpty || c.format == format);
      }).toList());
});

final competitionDetailProvider =
    FutureProvider.family<CompetitionDetail, String>((ref, id) {
  return ref.watch(historyServiceProvider).fetchCompetitionDetail(id);
});

final historyEventsProvider = FutureProvider<List<HistoricalEvent>>((ref) {
  return ref.watch(historyServiceProvider).fetchEvents();
});

final filteredEventsProvider =
    Provider<AsyncValue<List<HistoricalEvent>>>((ref) {
  final eventsAsync = ref.watch(historyEventsProvider);
  final search = ref.watch(eventSearchProvider).toLowerCase();
  final category = ref.watch(eventCategoryFilterProvider);
  final type = ref.watch(eventTypeFilterProvider);
  return eventsAsync.whenData((events) => events.where((e) {
        final matchesSearch = search.isEmpty ||
            e.title.toLowerCase().contains(search) ||
            (e.teamAName?.toLowerCase().contains(search) ?? false) ||
            (e.teamBName?.toLowerCase().contains(search) ?? false);
        return matchesSearch &&
            (category.isEmpty || e.eventCategory == category) &&
            (type.isEmpty || e.eventType == type);
      }).toList());
});

final eventDetailProvider =
    FutureProvider.family<EventDetail, String>((ref, id) {
  return ref.watch(historyServiceProvider).fetchEventDetail(id);
});

// ══════════════════════════════════════════════════════════════
//  PLAYER DETAIL  ← NUEVO
// ══════════════════════════════════════════════════════════════

final playerDetailProvider =
    FutureProvider.family<PlayerDetail, String>((ref, id) {
  return ref.watch(historyServiceProvider).fetchPlayerDetail(id);
});

// ══════════════════════════════════════════════════════════════
//  RANDOM SPINNER
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
  final String type;
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