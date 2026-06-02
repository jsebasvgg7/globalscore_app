import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/history_models.dart';

String? getHistoricalImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) return null;
  if (imagePath.startsWith('http')) return imagePath;
  final storageUrl = Supabase.instance.client.storage
      .from('historical')
      .getPublicUrl(imagePath);
  return storageUrl;
}

class HistoryService {
  final _sb = Supabase.instance.client;

  Future<List<HistoricalPlayer>> fetchPlayers() async {
    final res = await _sb
        .from('historical_players')
        .select(
          'id, name, country, position, birth_year, death_year, '
          'image_path, description, impact_summary, legacy_type, '
          'significance_level, ballon_dor_count, is_published',
        )
        .eq('is_published', true)
        .eq('is_special', false)
        .order('significance_level', ascending: false)
        .order('name', ascending: true);
    return (res as List).map((m) => HistoricalPlayer.fromMap(m)).toList();
  }

  Future<PlayerDetail> fetchPlayerDetail(String playerId) async {
  final playerRes = await _sb
      .from('historical_players')
      .select(
        'id, name, country, position, birth_year, death_year, '
        'image_path, description, impact_summary, legacy_type, '
        'significance_level, ballon_dor_count, is_published',
      )
      .eq('id', playerId)
      .eq('is_published', true)
      .eq('is_special', false)
      .single();

  final results = await Future.wait([
    _sb
        .from('historical_player_career')
        .select('team_name, team_country, start_year, end_year, appearances, goals, assists, role_note')
        .eq('player_id', playerId)
        .order('sort_order', ascending: true),

    _sb
        .from('historical_player_national')
        .select('country, start_year, end_year, caps, goals, assists, role_note')
        .eq('player_id', playerId)
        .order('start_year', ascending: true),

    _sb
        .from('historical_player_titles')
        .select('title_name, title_category, year, team_name, quantity')
        .eq('player_id', playerId)
        .order('sort_order', ascending: true),

    _sb
        .from('historical_player_teams')
        .select('start_year, end_year, roles, historical_teams(id, name, country, image_path, primary_color, is_published)')
        .eq('player_id', playerId)
        .order('start_year', ascending: true),

    _sb
        .from('historical_player_events')
        .select('role_note, historical_events(id, title, event_type, event_date, image_path, is_published)')
        .eq('player_id', playerId)
        .order('historical_events(event_date)', ascending: true),
  ]);

  final rawTeams = (results[3] as List)
      .where((m) => (m['historical_teams'] as Map?)?['is_published'] == true)
      .toList();
  final rawEvents = (results[4] as List)
      .where((m) => (m['historical_events'] as Map?)?['is_published'] == true)
      .toList();

  return PlayerDetail(
    player: HistoricalPlayer.fromMap(playerRes),
    career: (results[0] as List).map((m) => PlayerCareerEntry.fromMap(m)).toList(),
    national: (results[1] as List).map((m) => PlayerNationalEntry.fromMap(m)).toList(),
    titles: (results[2] as List).map((m) => PlayerTitleEntry.fromMap(m)).toList(),
    teamLinks: rawTeams.map((m) => PlayerTeamLink.fromMap(m)).toList(),
    eventLinks: rawEvents.map((m) => PlayerEventLink.fromMap(m)).toList(),
  );
}

  Future<List<HistoricalTeam>> fetchTeams() async {
    final res = await _sb
        .from('historical_teams')
        .select(
          'id, name, country, era_dominance, active_years, legacy_type, '
          'image_path, description, primary_color, secondary_color, '
          'titles_count, is_published',
        )
        .eq('is_published', true)
        .order('name', ascending: true);
    return (res as List).map((m) => HistoricalTeam.fromMap(m)).toList();
  }

  Future<List<HistoricalCompetition>> fetchCompetitions() async {
    final res = await _sb
        .from('historical_competitions')
        .select(
          'id, name, type, format, year, description, image_path, '
          'winner_text, edition, country, num_teams, is_published, '
          'historical_teams(id, name, image_path, primary_color)',
        )
        .eq('is_published', true)
        .order('year', ascending: false);
    return (res as List).map((m) => HistoricalCompetition.fromMap(m)).toList();
  }

  Future<CompetitionDetail> fetchCompetitionDetail(String competitionId) async {
    final compRes = await _sb
        .from('historical_competitions')
        .select(
          'id, name, type, format, year, description, image_path, '
          'winner_text, edition, country, num_teams, is_published, '
          'historical_teams(id, name, image_path, primary_color)',
        )
        .eq('id', competitionId)
        .single();

    final groupsRes = await _sb
        .from('historical_competition_groups')
        .select(
          'id, group_name, team_name, position, points, wins, draws, '
          'losses, goals_for, goals_against, sort_order',
        )
        .eq('competition_id', competitionId)
        .order('group_name')
        .order('position');

    final standingsRes = await _sb
        .from('historical_competition_standings')
        .select(
          'id, position, team_name, points, wins, draws, losses, '
          'goals_for, goals_against, champion',
        )
        .eq('competition_id', competitionId)
        .order('position');

    final knockoutRes = await _sb
        .from('historical_competition_knockout')
        .select(
          'id, round, match_number, team_a, team_b, score_a, score_b, '
          'agg_a, agg_b, penalties_a, penalties_b, winner, notes, sort_order',
        )
        .eq('competition_id', competitionId)
        .order('sort_order');

    return CompetitionDetail(
      competition: HistoricalCompetition.fromMap(compRes),
      groups: (groupsRes as List).map((m) => CompetitionGroup.fromMap(m)).toList(),
      standings: (standingsRes as List).map((m) => CompetitionStanding.fromMap(m)).toList(),
      knockout: (knockoutRes as List).map((m) => KnockoutMatch.fromMap(m)).toList(),
    );
  }

  Future<List<HistoricalEvent>> fetchEvents() async {
    final res = await _sb
        .from('historical_events')
        .select(
          'id, title, event_type, event_category, event_date, description, '
          'context_text, impact_text, image_path, banner_image_path, '
          'score_a, score_b, team_a_name, team_b_name, is_published, '
          'historical_players:protagonist_id(id, name, image_path, country, position), '
          'historical_teams:team_protagonist_id(id, name, image_path, primary_color)',
        )
        .eq('is_published', true)
        .order('event_date', ascending: false);
    return (res as List).map((m) => HistoricalEvent.fromMap(m)).toList();
  }

  Future<EventDetail> fetchEventDetail(String eventId) async {
    final eventRes = await _sb
        .from('historical_events')
        .select(
          'id, title, event_type, event_category, event_date, description, '
          'context_text, impact_text, image_path, banner_image_path, '
          'score_a, score_b, team_a_name, team_b_name, is_published, '
          'historical_players:protagonist_id(id, name, image_path, country, position), '
          'historical_teams:team_protagonist_id(id, name, image_path, primary_color)',
        )
        .eq('id', eventId)
        .single();

    final lineupsRes = await _sb
        .from('historical_event_lineups')
        .select(
          'id, team_side, team_name, player_name, shirt_number, '
          'position_role, is_protagonist, sort_order',
        )
        .eq('event_id', eventId)
        .order('sort_order');

    final knockoutRes = await _sb
        .from('historical_event_knockout')
        .select(
          'id, round, match_number, team_a, team_b, score_a, score_b, '
          'winner, is_decisive, sort_order',
        )
        .eq('event_id', eventId)
        .order('sort_order');

    final allLineups = (lineupsRes as List).map((m) => EventLineup.fromMap(m)).toList();
    return EventDetail(
      event: HistoricalEvent.fromMap(eventRes),
      lineupA: allLineups.where((l) => l.teamSide == 'team_a').toList(),
      lineupB: allLineups.where((l) => l.teamSide == 'team_b').toList(),
      knockout: (knockoutRes as List).map((m) => KnockoutMatch.fromMap(m)).toList(),
    );
  }

  Future<HistoryStats> fetchStats() async {
    final results = await Future.wait([
      _sb.from('historical_players').select('id').eq('is_published', true).eq('is_special', false),
      _sb.from('historical_teams').select('id').eq('is_published', true),
      _sb.from('historical_competitions').select('id').eq('is_published', true),
      _sb.from('historical_events').select('id').eq('is_published', true),
    ]);
    return HistoryStats(
      players: (results[0] as List).length,
      teams: (results[1] as List).length,
      competitions: (results[2] as List).length,
      events: (results[3] as List).length,
    );
  }

  // ─── NUEVO ───────────────────────────────────────────────
  Future<TeamDetail> fetchTeamDetail(String teamId) async {
    final teamRes = await _sb
        .from('historical_teams')
        .select(
          'id, name, country, era_dominance, active_years, legacy_type, '
          'image_path, description, primary_color, secondary_color, '
          'titles_count, is_published',
        )
        .eq('id', teamId)
        .eq('is_published', true)
        .single();

    final lineupRes = await _sb
        .from('historical_team_lineup')
        .select(
          'id, shirt_number, player_name, position_role, '
          'historical_players(id, image_path)',
        )
        .eq('team_id', teamId)
        .order('shirt_number', ascending: true);

    final titlesRes = await _sb
        .from('historical_team_titles')
        .select('id, title_name, year')
        .eq('team_id', teamId)
        .order('year', ascending: true);

    return TeamDetail(
      team: HistoricalTeam.fromMap(teamRes),
      lineup: (lineupRes as List).map((m) => TeamLineup.fromMap(m)).toList(),
      titles: (titlesRes as List).map((m) => TeamTitle.fromMap(m)).toList(),
    );
  }
}
class HistoryStats {
  final int players;
  final int teams;
  final int competitions;
  final int events;
  const HistoryStats({
    required this.players,
    required this.teams,
    required this.competitions,
    required this.events,
  });
}