// ============================================================
// PLAYERS
// ============================================================

class HistoricalPlayer {
  final String id;
  final String name;
  final String? country;
  final String? position;
  final int? birthYear;
  final int? deathYear;
  final String? imagePath;
  final String? description;
  final String? impactSummary;
  final String? legacyType;
  final int? ballonDorCount;      // ← corregido: ballon_dor_count
  final int? significanceLevel;   // ← nuevo: significance_level
  final bool isPublished;

  const HistoricalPlayer({
    required this.id,
    required this.name,
    this.country,
    this.position,
    this.birthYear,
    this.deathYear,
    this.imagePath,
    this.description,
    this.impactSummary,
    this.legacyType,
    this.ballonDorCount,
    this.significanceLevel,
    this.isPublished = true,
  });

  factory HistoricalPlayer.fromMap(Map<String, dynamic> m) => HistoricalPlayer(
        id: m['id'] as String,
        name: m['name'] as String,
        country: m['country'] as String?,
        position: m['position'] as String?,
        birthYear: m['birth_year'] as int?,
        deathYear: m['death_year'] as int?,
        imagePath: m['image_path'] as String?,
        description: m['description'] as String?,
        impactSummary: m['impact_summary'] as String?,
        legacyType: m['legacy_type'] as String?,
        ballonDorCount: m['ballon_dor_count'] as int?,   // ← corregido
        significanceLevel: m['significance_level'] as int?, // ← nuevo
        isPublished: m['is_published'] as bool? ?? true,
      );
}

// ============================================================
// TEAMS
// ============================================================

class HistoricalTeam {
  final String id;
  final String name;
  final String? country;
  final String? eraDominance;
  final String? activeYears;
  final String? legacyType;
  final String? imagePath;
  final String? description;
  final String? primaryColor;
  final String? secondaryColor;
  final int? titlesCount;
  final bool isPublished;

  const HistoricalTeam({
    required this.id,
    required this.name,
    this.country,
    this.eraDominance,
    this.activeYears,
    this.legacyType,
    this.imagePath,
    this.description,
    this.primaryColor,
    this.secondaryColor,
    this.titlesCount,
    this.isPublished = true,
  });

  String? get era => eraDominance ?? activeYears;

  factory HistoricalTeam.fromMap(Map<String, dynamic> m) => HistoricalTeam(
        id: m['id'] as String,
        name: m['name'] as String,
        country: m['country'] as String?,
        eraDominance: m['era_dominance'] as String?,
        activeYears: m['active_years'] as String?,
        legacyType: m['legacy_type'] as String?,
        imagePath: m['image_path'] as String?,
        description: m['description'] as String?,
        primaryColor: m['primary_color'] as String?,
        secondaryColor: m['secondary_color'] as String?,
        titlesCount: m['titles_count'] as int?,
        isPublished: m['is_published'] as bool? ?? true,
      );
}

// ============================================================
// COMPETITIONS
// ============================================================

class HistoricalCompetition {
  final String id;
  final String name;
  final String? type;
  final String? format;
  final int? year;
  final String? description;
  final String? imagePath;
  final String? winnerText;
  final String? edition;
  final String? country;
  final int? numTeams;
  final bool isPublished;
  final HistoricalTeam? winnerTeam;

  const HistoricalCompetition({
    required this.id,
    required this.name,
    this.type,
    this.format,
    this.year,
    this.description,
    this.imagePath,
    this.winnerText,
    this.edition,
    this.country,
    this.numTeams,
    this.isPublished = true,
    this.winnerTeam,
  });

  factory HistoricalCompetition.fromMap(Map<String, dynamic> m) {
    HistoricalTeam? winner;
    if (m['historical_teams'] != null) {
      winner = HistoricalTeam.fromMap(m['historical_teams'] as Map<String, dynamic>);
    }
    return HistoricalCompetition(
      id: m['id'] as String,
      name: m['name'] as String,
      type: m['type'] as String?,
      format: m['format'] as String?,
      year: m['year'] as int?,
      description: m['description'] as String?,
      imagePath: m['image_path'] as String?,
      winnerText: m['winner_text'] as String?,
      edition: m['edition'] as String?,
      country: m['country'] as String?,
      numTeams: m['num_teams'] as int?,
      isPublished: m['is_published'] as bool? ?? true,
      winnerTeam: winner,
    );
  }

  String get winnerDisplay => winnerTeam?.name ?? winnerText ?? '—';
}

class CompetitionGroup {
  final String id;
  final String groupName;
  final String teamName;
  final int? position;
  final int points;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;

  const CompetitionGroup({
    required this.id,
    required this.groupName,
    required this.teamName,
    this.position,
    this.points = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  factory CompetitionGroup.fromMap(Map<String, dynamic> m) => CompetitionGroup(
        id: m['id'] as String,
        groupName: m['group_name'] as String,
        teamName: m['team_name'] as String,
        position: m['position'] as int?,
        points: m['points'] as int? ?? 0,
        wins: m['wins'] as int? ?? 0,
        draws: m['draws'] as int? ?? 0,
        losses: m['losses'] as int? ?? 0,
        goalsFor: m['goals_for'] as int? ?? 0,
        goalsAgainst: m['goals_against'] as int? ?? 0,
      );

  int get played => wins + draws + losses;
  int get goalDiff => goalsFor - goalsAgainst;
}

class CompetitionStanding {
  final String id;
  final int position;
  final String teamName;
  final int points;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final bool isChampion;

  const CompetitionStanding({
    required this.id,
    required this.position,
    required this.teamName,
    this.points = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.isChampion = false,
  });

  factory CompetitionStanding.fromMap(Map<String, dynamic> m) =>
      CompetitionStanding(
        id: m['id'] as String,
        position: m['position'] as int,
        teamName: m['team_name'] as String,
        points: m['points'] as int? ?? 0,
        wins: m['wins'] as int? ?? 0,
        draws: m['draws'] as int? ?? 0,
        losses: m['losses'] as int? ?? 0,
        goalsFor: m['goals_for'] as int? ?? 0,
        goalsAgainst: m['goals_against'] as int? ?? 0,
        isChampion: m['champion'] as bool? ?? false,
      );

  int get played => wins + draws + losses;
  int get goalDiff => goalsFor - goalsAgainst;
}

class KnockoutMatch {
  final String id;
  final String round;
  final int matchNumber;
  final String teamA;
  final String teamB;
  final int? scoreA;
  final int? scoreB;
  final int? aggA;
  final int? aggB;
  final int? penaltiesA;
  final int? penaltiesB;
  final String? winner;
  final String? notes;
  final int sortOrder;

  const KnockoutMatch({
    required this.id,
    required this.round,
    required this.matchNumber,
    required this.teamA,
    required this.teamB,
    this.scoreA,
    this.scoreB,
    this.aggA,
    this.aggB,
    this.penaltiesA,
    this.penaltiesB,
    this.winner,
    this.notes,
    this.sortOrder = 0,
  });

  factory KnockoutMatch.fromMap(Map<String, dynamic> m) => KnockoutMatch(
        id: m['id'] as String,
        round: m['round'] as String,
        matchNumber: m['match_number'] as int? ?? 1,
        teamA: m['team_a'] as String,
        teamB: m['team_b'] as String,
        scoreA: m['score_a'] as int?,
        scoreB: m['score_b'] as int?,
        aggA: m['agg_a'] as int?,
        aggB: m['agg_b'] as int?,
        penaltiesA: m['penalties_a'] as int?,
        penaltiesB: m['penalties_b'] as int?,
        winner: m['winner'] as String?,
        notes: m['notes'] as String?,
        sortOrder: m['sort_order'] as int? ?? 0,
      );

  bool get winnerIsA => winner == 'team_a';
  bool get winnerIsB => winner == 'team_b';
  bool get hasPenalties => penaltiesA != null || penaltiesB != null;
}

class CompetitionDetail {
  final HistoricalCompetition competition;
  final List<CompetitionGroup> groups;
  final List<CompetitionStanding> standings;
  final List<KnockoutMatch> knockout;

  const CompetitionDetail({
    required this.competition,
    required this.groups,
    required this.standings,
    required this.knockout,
  });
}

// ============================================================
// EVENTS
// ============================================================

class HistoricalEvent {
  final String id;
  final String title;
  final String? eventType;
  final String? eventCategory;
  final String? eventDate;
  final String? description;
  final String? contextText;
  final String? impactText;
  final String? imagePath;
  final String? bannerImagePath;
  final int? scoreA;
  final int? scoreB;
  final String? teamAName;
  final String? teamBName;
  final bool isPublished;
  final HistoricalPlayer? player;
  final HistoricalTeam? team;

  const HistoricalEvent({
    required this.id,
    required this.title,
    this.eventType,
    this.eventCategory,
    this.eventDate,
    this.description,
    this.contextText,
    this.impactText,
    this.imagePath,
    this.bannerImagePath,
    this.scoreA,
    this.scoreB,
    this.teamAName,
    this.teamBName,
    this.isPublished = true,
    this.player,
    this.team,
  });

  factory HistoricalEvent.fromMap(Map<String, dynamic> m) {
    HistoricalPlayer? player;
    HistoricalTeam? team;
    final playerData = m['historical_players'];
    final teamData = m['historical_teams'];
    if (playerData is Map<String, dynamic>) {
      player = HistoricalPlayer.fromMap(playerData);
    }
    if (teamData is Map<String, dynamic>) {
      team = HistoricalTeam.fromMap(teamData);
    }
    return HistoricalEvent(
      id: m['id'] as String,
      title: m['title'] as String,
      eventType: m['event_type'] as String?,
      eventCategory: m['event_category'] as String?,
      eventDate: m['event_date'] as String?,
      description: m['description'] as String?,
      contextText: m['context_text'] as String?,
      impactText: m['impact_text'] as String?,
      imagePath: m['image_path'] as String?,
      bannerImagePath: m['banner_image_path'] as String?,
      scoreA: m['score_a'] as int?,
      scoreB: m['score_b'] as int?,
      teamAName: m['team_a_name'] as String?,
      teamBName: m['team_b_name'] as String?,
      isPublished: m['is_published'] as bool? ?? true,
      player: player,
      team: team,
    );
  }

  int? get year {
    if (eventDate == null) return null;
    try {
      return DateTime.parse(eventDate!).year;
    } catch (_) {
      return null;
    }
  }
}

class EventLineup {
  final String id;
  final String teamSide;
  final String teamName;
  final String playerName;
  final int? shirtNumber;
  final String? positionRole;
  final bool isProtagonist;
  final int sortOrder;

  const EventLineup({
    required this.id,
    required this.teamSide,
    required this.teamName,
    required this.playerName,
    this.shirtNumber,
    this.positionRole,
    this.isProtagonist = false,
    this.sortOrder = 0,
  });

  factory EventLineup.fromMap(Map<String, dynamic> m) => EventLineup(
        id: m['id'] as String,
        teamSide: m['team_side'] as String,
        teamName: m['team_name'] as String,
        playerName: m['player_name'] as String,
        shirtNumber: m['shirt_number'] as int?,
        positionRole: m['position_role'] as String?,
        isProtagonist: m['is_protagonist'] as bool? ?? false,
        sortOrder: m['sort_order'] as int? ?? 0,
      );
}

class EventDetail {
  final HistoricalEvent event;
  final List<EventLineup> lineupA;
  final List<EventLineup> lineupB;
  final List<KnockoutMatch> knockout;

  const EventDetail({
    required this.event,
    required this.lineupA,
    required this.lineupB,
    required this.knockout,
  });
}

// ============================================================
// PLAYER DETAIL — carrera, nacional, títulos
// ============================================================

class PlayerCareerEntry {
  final String teamName;
  final String? teamCountry;
  final int? startYear;
  final int? endYear;
  final int appearances;
  final int goals;
  final int assists;
  final String? roleNote;

  const PlayerCareerEntry({
    required this.teamName,
    this.teamCountry,
    this.startYear,
    this.endYear,
    this.appearances = 0,
    this.goals = 0,
    this.assists = 0,
    this.roleNote,
  });

  factory PlayerCareerEntry.fromMap(Map<String, dynamic> m) => PlayerCareerEntry(
        teamName: m['team_name'] as String? ?? '—',
        teamCountry: m['team_country'] as String?,
        startYear: m['start_year'] as int?,
        endYear: m['end_year'] as int?,
        appearances: m['appearances'] as int? ?? 0,
        goals: m['goals'] as int? ?? 0,
        assists: m['assists'] as int? ?? 0,
        roleNote: m['role_note'] as String?,
      );
}
// Relación jugador ↔ HistoricalTeam (tabla historical_player_teams)
class PlayerTeamLink {
  final String startYear;
  final String endYear;
  final String? roles;
  final String teamId;
  final String teamName;
  final String? teamCountry;
  final String? teamImagePath;
  final String? primaryColor;

  const PlayerTeamLink({
    required this.startYear,
    required this.endYear,
    this.roles,
    required this.teamId,
    required this.teamName,
    this.teamCountry,
    this.teamImagePath,
    this.primaryColor,
  });

  factory PlayerTeamLink.fromMap(Map<String, dynamic> m) {
    final team = m['historical_teams'] as Map<String, dynamic>? ?? {};
    return PlayerTeamLink(
      startYear: m['start_year']?.toString() ?? '?',
      endYear: m['end_year']?.toString() ?? '?',
      roles: m['roles'],
      teamId: team['id']?.toString() ?? '',
      teamName: team['name'] ?? '—',
      teamCountry: team['country'],
      teamImagePath: team['image_path'],
      primaryColor: team['primary_color'],
    );
  }
}

class PlayerEventLink {
  final String? roleNote;
  final String eventId;
  final String eventTitle;
  final String? eventType;
  final String? eventDate;
  final String? imagePath;

  const PlayerEventLink({
    this.roleNote,
    required this.eventId,
    required this.eventTitle,
    this.eventType,
    this.eventDate,
    this.imagePath,
  });

  int? get year {
    if (eventDate == null) return null;
    try { return DateTime.parse(eventDate!).year; } catch (_) { return null; }
  }

  factory PlayerEventLink.fromMap(Map<String, dynamic> m) {
    final ev = m['historical_events'] as Map<String, dynamic>? ?? {};
    return PlayerEventLink(
      roleNote: m['role_note'],
      eventId: ev['id']?.toString() ?? '',
      eventTitle: ev['title'] ?? '—',
      eventType: ev['event_type'],
      eventDate: ev['event_date'],
      imagePath: ev['image_path'],
    );
  }
}
class PlayerNationalEntry {
  final String country;
  final int? startYear;
  final int? endYear;
  final int caps;
  final int goals;
  final int assists;
  final String? roleNote;

  const PlayerNationalEntry({
    required this.country,
    this.startYear,
    this.endYear,
    this.caps = 0,
    this.goals = 0,
    this.assists = 0,
    this.roleNote,
  });

  factory PlayerNationalEntry.fromMap(Map<String, dynamic> m) => PlayerNationalEntry(
        country: m['country'] as String? ?? '—',
        startYear: m['start_year'] as int?,
        endYear: m['end_year'] as int?,
        caps: m['caps'] as int? ?? 0,
        goals: m['goals'] as int? ?? 0,
        assists: m['assists'] as int? ?? 0,
        roleNote: m['role_note'] as String?,
      );
}

class PlayerTitleEntry {
  final String titleName;
  final String titleCategory; // club | national | individual
  final String? year;
  final String? teamName;
  final int quantity;

  const PlayerTitleEntry({
    required this.titleName,
    required this.titleCategory,
    this.year,
    this.teamName,
    this.quantity = 1,
  });

  factory PlayerTitleEntry.fromMap(Map<String, dynamic> m) => PlayerTitleEntry(
        titleName: m['title_name'] as String? ?? '—',
        titleCategory: m['title_category'] as String? ?? 'club',
        year: m['year'] as String?,
        teamName: m['team_name'] as String?,
        quantity: m['quantity'] as int? ?? 1,
      );
}

class PlayerDetail {
  final HistoricalPlayer player;
  final List<PlayerCareerEntry> career;
  final List<PlayerNationalEntry> national;
  final List<PlayerTitleEntry> titles;
  final List<PlayerTeamLink> teamLinks;    
  final List<PlayerEventLink> eventLinks;   

  const PlayerDetail({
    required this.player,
    required this.career,
    required this.national,
    required this.titles,
    this.teamLinks = const [],
    this.eventLinks = const [],
  });
}

 
// Alineación histórica del equipo (historical_team_lineup)
class TeamLineup {
  final String id;
  final int? shirtNumber;
  final String playerName;
  final String? positionRole;
  final String? teamSide;   // si hay sub-equipos (ej: once ideal A/B)
  final String? notes;
  final int sortOrder;
 
  // Enlace opcional al jugador histórico
  final String? historicalPlayerId;
  final String? historicalPlayerImagePath;
 
  const TeamLineup({
    required this.id,
    this.shirtNumber,
    required this.playerName,
    this.positionRole,
    this.teamSide,
    this.notes,
    this.sortOrder = 0,
    this.historicalPlayerId,
    this.historicalPlayerImagePath,
  });
 
  factory TeamLineup.fromMap(Map<String, dynamic> m) {
    // Soporta join con historical_players
    final player = m['historical_players'];
    return TeamLineup(
      id: m['id'] as String,
      shirtNumber: m['shirt_number'] as int?,
      playerName: m['player_name'] as String? ?? '—',
      positionRole: m['position_role'] as String?,
      teamSide: m['team_side'] as String?,
      notes: m['notes'] as String?,
      sortOrder: m['sort_order'] as int? ?? 0,
      historicalPlayerId: player != null ? (player['id'] as String?) : null,
      historicalPlayerImagePath:
          player != null ? (player['image_path'] as String?) : null,
    );
  }
}
 
// Título ganado por el equipo (historical_team_titles)
class TeamTitle {
  final String id;
  final String? titleName;
  final String? category;   // Liga | Copa | Europa | etc.
  final String? year;
  final String? notes;
  final int sortOrder;
 
  const TeamTitle({
    required this.id,
    this.titleName,
    this.category,
    this.year,
    this.notes,
    this.sortOrder = 0,
  });
 
  factory TeamTitle.fromMap(Map<String, dynamic> m) => TeamTitle(
        id: m['id'] as String,
        titleName: m['title_name'] as String?,
        category: m['category'] as String?,
        year: m['year']?.toString(),
        notes: m['notes'] as String?,
        sortOrder: m['sort_order'] as int? ?? 0,
      );
}
 
// Detalle completo del equipo
class TeamDetail {
  final HistoricalTeam team;
  final List<TeamLineup> lineup;
  final List<TeamTitle> titles;
 
  const TeamDetail({
    required this.team,
    required this.lineup,
    required this.titles,
  });
}