import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/history_models.dart';

// ── Cloudinary image helper (same as React getHistoricalImageUrl) ─────────────
String? getHistoricalImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) return null;
  if (imagePath.startsWith('http')) return imagePath;
  const cloudName = 'dkxoanvyv';
  const base = 'https://res.cloudinary.com/$cloudName/image/upload';
  const transform = 'w_400,h_400,c_fill,q_auto,f_auto';
  return '$base/$transform/$imagePath';
}

class HistoryService {
  final _sb = Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════
  //  PLAYERS
  // ══════════════════════════════════════════════════════════════

  Future<List<HistoricalPlayer>> fetchPlayers() async {
    final res = await _sb
        .from('historical_players')
        .select(
          'id, name, country, position, birth_year, death_year, '
          'image_path, description, legacy, ballon_dor_wins, is_published',
        )
        .eq('is_published', true)
        .order('name', ascending: true);
    return (res as List).map((m) => HistoricalPlayer.fromMap(m)).toList();
  }

  // ══════════════════════════════════════════════════════════════
  //  TEAMS
  // ══════════════════════════════════════════════════════════════

  Future<List<HistoricalTeam>> fetchTeams() async {
    final res = await _sb
        .from('historical_teams')
        .select(
          'id, name, country, confederation, era, image_path, '
          'description, primary_color, secondary_color, is_published',
        )
        .eq('is_published', true)
        .order('name', ascending: true);
    return (res as List).map((m) => HistoricalTeam.fromMap(m)).toList();
  }

  // ══════════════════════════════════════════════════════════════
  //  COMPETITIONS
  // ══════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════
  //  EVENTS
  // ══════════════════════════════════════════════════════════════

  Future<List<HistoricalEvent>> fetchEvents() async {
    final res = await _sb
        .from('historical_events')
        .select(
          'id, title, event_type, event_category, event_date, description, '
          'context_text, impact_text, image_path, banner_image_path, '
          'score_a, score_b, team_a_name, team_b_name, is_published, '
          'historical_players(id, name, image_path, country, position), '
          'historical_teams(id, name, image_path, primary_color, country)',
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
          'historical_players(id, name, image_path, country, position), '
          'historical_teams(id, name, image_path, primary_color, country)',
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

  // ══════════════════════════════════════════════════════════════
  //  STATS for the landing page
  // ══════════════════════════════════════════════════════════════

  Future<HistoryStats> fetchStats() async {
    final results = await Future.wait([
      _sb.from('historical_players').select('id').eq('is_published', true),
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
