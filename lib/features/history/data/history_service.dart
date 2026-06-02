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

    final category = eventRes['event_category'] as String?;

    // Consultas paralelas según categoría
    final results = await Future.wait([
      // lineups (ambas categorías pueden tenerlos, pero los usa 'player')
      _sb
          .from('historical_event_lineups')
          .select(
            'id, team_side, team_name, player_name, shirt_number, '
            'position_role, is_protagonist, sort_order',
          )
          .eq('event_id', eventId)
          .order('sort_order'),

      // knockout (ambas categorías pueden tenerlo)
      _sb
          .from('historical_event_knockout')
          .select(
            'id, round, match_number, team_a, team_b, score_a, score_b, '
            'winner, is_decisive, sort_order',
          )
          .eq('event_id', eventId)
          .order('sort_order'),

      // squad (solo 'team')
      if (category == 'team')
        _sb
            .from('historical_event_squad')
            .select('id, player_name, shirt_number, position_role, is_key_player, sort_order')
            .eq('event_id', eventId)
            .order('sort_order')
      else
        Future.value(<dynamic>[]),

      // standings (solo 'team')
      if (category == 'team')
        _sb
            .from('historical_event_standings')
            .select('position, team_name, points, wins, draws, losses, goals_for, goals_against, is_champion')
            .eq('event_id', eventId)
            .order('position')
      else
        Future.value(<dynamic>[]),
    ]);

    final allLineups = (results[0] as List).map((m) => EventLineup.fromMap(m)).toList();
    final knockout   = (results[1] as List).map((m) => KnockoutMatch.fromMap(m)).toList();
    final squad      = (results[2] as List).map((m) => EventSquad.fromMap(m)).toList();
    final standings  = (results[3] as List).map((m) => EventStanding.fromMap(m)).toList();

    return EventDetail(
      event: HistoricalEvent.fromMap(eventRes),
      lineupA:   allLineups.where((l) => l.teamSide == 'team_a').toList(),
      lineupB:   allLineups.where((l) => l.teamSide == 'team_b').toList(),
      squad:     squad,
      standings: standings,
      knockout:  knockout,
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

    final results = await Future.wait([
      _sb
          .from('historical_team_lineup')
          .select(
            'id, shirt_number, player_name, position_role, '
            'historical_players(id, image_path)',
          )
          .eq('team_id', teamId)
          .order('shirt_number', ascending: true),

      _sb
          .from('historical_team_titles')
          .select('id, title_name, year')
          .eq('team_id', teamId)
          .order('year', ascending: true),
    ]);

    final lineup = (results[0] as List).map((m) => TeamLineup.fromMap(m)).toList();
    final titles = (results[1] as List).map((m) => TeamTitle.fromMap(m)).toList();

    // Si no hay lineup en historical_team_lineup, buscar en historical_event_squad
    // para equipos que solo tienen plantel ligado a un evento.
    if (lineup.isEmpty) {
      // Buscar el evento más reciente publicado que tenga a este equipo como protagonista
      try {
        final eventRes = await _sb
            .from('historical_events')
            .select('id')
            .eq('is_published', true)
            .not('team_protagonist_id', 'is', null)
            // No podemos filtrar directamente por team_protagonist_id sin el id del equipo
            // así que filtramos por nombre del equipo en team_a_name como fallback
            .order('event_date', ascending: false)
            .limit(20);

        // Buscar el evento que corresponde a este equipo por su id de protagonista
        final eventsForTeam = await _sb
            .from('historical_events')
            .select('id')
            .eq('is_published', true)
            .eq('team_protagonist_id', teamId)
            .order('event_date', ascending: false)
            .limit(1);

        if ((eventsForTeam as List).isNotEmpty) {
          final eventId = eventsForTeam.first['id'] as String;
          final squadRes = await _sb
              .from('historical_event_squad')
              .select('id, player_name, shirt_number, position_role, is_key_player, sort_order')
              .eq('event_id', eventId)
              .order('sort_order');

          // Convertir EventSquad → TeamLineup para reutilizar la UI existente
          final squadAsLineup = (squadRes as List).map((m) {
            final sq = EventSquad.fromMap(m);
            return TeamLineup(
              id: sq.id,
              shirtNumber: sq.shirtNumber,
              playerName: sq.playerName,
              positionRole: sq.positionRole,
              sortOrder: sq.sortOrder,
            );
          }).toList();

          return TeamDetail(
            team: HistoricalTeam.fromMap(teamRes),
            lineup: squadAsLineup,
            titles: titles,
          );
        }
      } catch (_) {
        // Si falla la consulta del squad, retornar sin plantel
      }
    }

    return TeamDetail(
      team: HistoricalTeam.fromMap(teamRes),
      lineup: lineup,
      titles: titles,
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