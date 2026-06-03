// ═══════════════════════════════════════════════════════════
//  WORLDCUP MODELS  —  fixed: round16 keys always String
// ═══════════════════════════════════════════════════════════

const Map<String, List<String>> kGroupsData = {
  'A': ['Mexico', 'South Africa', 'Korea Republic', 'Czechia'],
  'B': ['Canada', 'Bosnia', 'Qatar', 'Switzerland'],
  'C': ['Brazil', 'Morocco', 'Haiti', 'Scotland'],
  'D': ['USA', 'Paraguay', 'Australia', 'Turkey'],
  'E': ['Germany', 'Curacao', 'Ivory Coast', 'Ecuador'],
  'F': ['Netherlands', 'Japan', 'Sweden', 'Tunisia'],
  'G': ['Belgium', 'Egypt', 'Iran', 'New Zealand'],
  'H': ['Spain', 'Cabo Verde', 'Saudi Arabia', 'Uruguay'],
  'I': ['France', 'Senegal', 'Iraq', 'Norway'],
  'J': ['Argentina', 'Algeria', 'Austria', 'Jordan'],
  'K': ['Portugal', 'Congo', 'Uzbekistan', 'Colombia'],
  'L': ['England', 'Croatia', 'Ghana', 'Panama'],
};

const Map<String, String> kTeamLogoMap = {
  'Mexico': 'mexico', 'South Africa': 'sudafrica', 'Korea Republic': 'coreadelsur',
  'Czechia': 'chequia', 'Canada': 'canada', 'Bosnia': 'bosnia', 'Qatar': 'qatar',
  'Switzerland': 'suiza', 'Brazil': 'brasil', 'Morocco': 'marruecos', 'Haiti': 'haiti',
  'Scotland': 'escocia', 'USA': 'usa', 'Paraguay': 'paraguay', 'Australia': 'australia',
  'Turkey': 'turquia', 'Germany': 'alemania', 'Curacao': 'curacao',
  'Ivory Coast': 'costamarfil', 'Ecuador': 'ecuador', 'Netherlands': 'paisesbajos',
  'Japan': 'japon', 'Sweden': 'suecia', 'Tunisia': 'tunez', 'Belgium': 'belgica',
  'Egypt': 'egipto', 'Iran': 'iran', 'New Zealand': 'nuevazelanda', 'Spain': 'espana',
  'Cabo Verde': 'caboverde', 'Saudi Arabia': 'arabiasaudita', 'Uruguay': 'uruguay',
  'France': 'francia', 'Senegal': 'senegal', 'Iraq': 'irak', 'Norway': 'noruega',
  'Argentina': 'argentina', 'Algeria': 'argelia', 'Austria': 'austria', 'Jordan': 'jordan',
  'Portugal': 'portugal', 'Congo': 'congo', 'Uzbekistan': 'uzbekistan', 'Colombia': 'colombia',
  'England': 'inglaterra', 'Croatia': 'croacia', 'Ghana': 'ghana', 'Panama': 'panama',
};

String getTeamFlagUrl(String team, String supabaseUrl) {
  final slug = kTeamLogoMap[team];
  if (slug == null) return '';
  return '$supabaseUrl/storage/v1/object/public/world-cup-logos/$slug.png';
}

// ─── Predicción de un partido de grupo ───────────────────
class MatchPrediction {
  final String homeScore;
  final String awayScore;

  const MatchPrediction({this.homeScore = '', this.awayScore = ''});

  bool get isFilled => homeScore.isNotEmpty && awayScore.isNotEmpty;

  Map<String, dynamic> toJson() => {'homeScore': homeScore, 'awayScore': awayScore};

  factory MatchPrediction.fromJson(Map<String, dynamic> json) => MatchPrediction(
        homeScore: json['homeScore']?.toString() ?? '',
        awayScore: json['awayScore']?.toString() ?? '',
      );

  MatchPrediction copyWith({String? homeScore, String? awayScore}) => MatchPrediction(
        homeScore: homeScore ?? this.homeScore,
        awayScore: awayScore ?? this.awayScore,
      );
}

// ─── Predicciones de un grupo ────────────────────────────
class GroupPrediction {
  final Map<int, MatchPrediction> matches;

  const GroupPrediction({this.matches = const {}});

  int get filledCount => matches.values.where((m) => m.isFilled).length;

  Map<String, dynamic> toJson() => {
        'matches': matches.map((k, v) => MapEntry(k.toString(), v.toJson())),
      };

  factory GroupPrediction.fromJson(Map<String, dynamic> json) {
    final rawMatches = json['matches'] as Map<String, dynamic>? ?? {};
    return GroupPrediction(
      matches: rawMatches.map((k, v) =>
          MapEntry(int.parse(k), MatchPrediction.fromJson(v as Map<String, dynamic>))),
    );
  }

  GroupPrediction copyWithMatch(int idx, MatchPrediction pred) => GroupPrediction(
        matches: {...matches, idx: pred},
      );
}

// ─── Fila de tabla de grupo ───────────────────────────────
class GroupTableRow {
  final String team;
  final int played, won, drawn, lost, gf, ga, gd, pts;

  const GroupTableRow({
    required this.team,
    this.played = 0, this.won = 0, this.drawn = 0, this.lost = 0,
    this.gf = 0, this.ga = 0, this.gd = 0, this.pts = 0,
  });

  GroupTableRow copyWith({
    int? played, int? won, int? drawn, int? lost,
    int? gf, int? ga, int? gd, int? pts,
  }) =>
      GroupTableRow(
        team: team,
        played: played ?? this.played,
        won: won ?? this.won,
        drawn: drawn ?? this.drawn,
        lost: lost ?? this.lost,
        gf: gf ?? this.gf,
        ga: ga ?? this.ga,
        gd: gd ?? this.gd,
        pts: pts ?? this.pts,
      );
}

// ─── Tercero con grupo ────────────────────────────────────
class ThirdPlaceEntry extends GroupTableRow {
  final String group;

  const ThirdPlaceEntry({
    required super.team,
    required this.group,
    super.played, super.won, super.drawn, super.lost,
    super.gf, super.ga, super.gd, super.pts,
  });
}

// ─── Predicciones de eliminatorias ───────────────────────
// FIX: round16 ahora usa Map<String, String> en lugar de Map<dynamic, String>
// para evitar inconsistencias de tipo al serializar/deserializar.
class KnockoutPredictions {
  final Map<String, String> round16;
  final Map<String, String> round8;
  final Map<String, String> quarters;
  final Map<String, String> semis;
  final Map<String, String> final_;
  final Map<String, String> thirdPlace;

  const KnockoutPredictions({
    this.round16 = const {},
    this.round8 = const {},
    this.quarters = const {},
    this.semis = const {},
    this.final_ = const {},
    this.thirdPlace = const {},
  });

  Map<String, dynamic> toJson() => {
        'round16': round16,
        'round8': round8,
        'quarters': quarters,
        'semis': semis,
        'final': final_,
        'thirdPlace': thirdPlace,
      };

  factory KnockoutPredictions.fromJson(Map<String, dynamic> json) {
    Map<String, String> _toStrMap(dynamic raw) {
      if (raw == null) return {};
      return (raw as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    return KnockoutPredictions(
      round16: _toStrMap(json['round16']),
      round8: _toStrMap(json['round8']),
      quarters: _toStrMap(json['quarters']),
      semis: _toStrMap(json['semis']),
      final_: _toStrMap(json['final']),
      thirdPlace: _toStrMap(json['thirdPlace']),
    );
  }

  KnockoutPredictions copyWithRound16(String id, String team) => KnockoutPredictions(
        round16: {...round16, id: team},
        round8: round8, quarters: quarters, semis: semis, final_: final_, thirdPlace: thirdPlace,
      );
  KnockoutPredictions copyWithRound8(String id, String team) => KnockoutPredictions(
        round16: round16, round8: {...round8, id: team},
        quarters: quarters, semis: semis, final_: final_, thirdPlace: thirdPlace,
      );
  KnockoutPredictions copyWithQuarters(String id, String team) => KnockoutPredictions(
        round16: round16, round8: round8, quarters: {...quarters, id: team},
        semis: semis, final_: final_, thirdPlace: thirdPlace,
      );
  KnockoutPredictions copyWithSemis(String id, String team) => KnockoutPredictions(
        round16: round16, round8: round8, quarters: quarters,
        semis: {...semis, id: team}, final_: final_, thirdPlace: thirdPlace,
      );
  KnockoutPredictions copyWithFinal(String id, String team) => KnockoutPredictions(
        round16: round16, round8: round8, quarters: quarters, semis: semis,
        final_: {...final_, id: team}, thirdPlace: thirdPlace,
      );
  KnockoutPredictions copyWithThirdPlace(String id, String team) => KnockoutPredictions(
        round16: round16, round8: round8, quarters: quarters, semis: semis,
        final_: final_, thirdPlace: {...thirdPlace, id: team},
      );
}

// ─── Predicciones de premios ──────────────────────────────
class AwardsPredictions {
  final String topScorer, topAssist, goldenBall, bestYoungPlayer,
      goldenGlove, surpriseTeam, disappointmentTeam, breakoutPlayer, disappointmentPlayer;

  const AwardsPredictions({
    this.topScorer = '', this.topAssist = '', this.goldenBall = '',
    this.bestYoungPlayer = '', this.goldenGlove = '', this.surpriseTeam = '',
    this.disappointmentTeam = '', this.breakoutPlayer = '', this.disappointmentPlayer = '',
  });

  Map<String, dynamic> toJson() => {
        'topScorer': topScorer, 'topAssist': topAssist, 'goldenBall': goldenBall,
        'bestYoungPlayer': bestYoungPlayer, 'goldenGlove': goldenGlove,
        'surpriseTeam': surpriseTeam, 'disappointmentTeam': disappointmentTeam,
        'breakoutPlayer': breakoutPlayer, 'disappointmentPlayer': disappointmentPlayer,
      };

  factory AwardsPredictions.fromJson(Map<String, dynamic> json) => AwardsPredictions(
        topScorer: json['topScorer'] ?? '',
        topAssist: json['topAssist'] ?? '',
        goldenBall: json['goldenBall'] ?? '',
        bestYoungPlayer: json['bestYoungPlayer'] ?? '',
        goldenGlove: json['goldenGlove'] ?? '',
        surpriseTeam: json['surpriseTeam'] ?? '',
        disappointmentTeam: json['disappointmentTeam'] ?? '',
        breakoutPlayer: json['breakoutPlayer'] ?? '',
        disappointmentPlayer: json['disappointmentPlayer'] ?? '',
      );

  AwardsPredictions copyWith({
    String? topScorer, String? topAssist, String? goldenBall, String? bestYoungPlayer,
    String? goldenGlove, String? surpriseTeam, String? disappointmentTeam,
    String? breakoutPlayer, String? disappointmentPlayer,
  }) =>
      AwardsPredictions(
        topScorer: topScorer ?? this.topScorer,
        topAssist: topAssist ?? this.topAssist,
        goldenBall: goldenBall ?? this.goldenBall,
        bestYoungPlayer: bestYoungPlayer ?? this.bestYoungPlayer,
        goldenGlove: goldenGlove ?? this.goldenGlove,
        surpriseTeam: surpriseTeam ?? this.surpriseTeam,
        disappointmentTeam: disappointmentTeam ?? this.disappointmentTeam,
        breakoutPlayer: breakoutPlayer ?? this.breakoutPlayer,
        disappointmentPlayer: disappointmentPlayer ?? this.disappointmentPlayer,
      );

  String getByKey(String key) {
    switch (key) {
      case 'topScorer': return topScorer;
      case 'topAssist': return topAssist;
      case 'goldenBall': return goldenBall;
      case 'bestYoungPlayer': return bestYoungPlayer;
      case 'goldenGlove': return goldenGlove;
      case 'surpriseTeam': return surpriseTeam;
      case 'disappointmentTeam': return disappointmentTeam;
      case 'breakoutPlayer': return breakoutPlayer;
      case 'disappointmentPlayer': return disappointmentPlayer;
      default: return '';
    }
  }

  AwardsPredictions setByKey(String key, String val) {
    switch (key) {
      case 'topScorer': return copyWith(topScorer: val);
      case 'topAssist': return copyWith(topAssist: val);
      case 'goldenBall': return copyWith(goldenBall: val);
      case 'bestYoungPlayer': return copyWith(bestYoungPlayer: val);
      case 'goldenGlove': return copyWith(goldenGlove: val);
      case 'surpriseTeam': return copyWith(surpriseTeam: val);
      case 'disappointmentTeam': return copyWith(disappointmentTeam: val);
      case 'breakoutPlayer': return copyWith(breakoutPlayer: val);
      case 'disappointmentPlayer': return copyWith(disappointmentPlayer: val);
      default: return this;
    }
  }
}

// ─── Predicciones completas ───────────────────────────────
class WorldCupPredictions {
  final Map<String, GroupPrediction> groups;
  final KnockoutPredictions knockout;
  final AwardsPredictions awards;

  const WorldCupPredictions({
    this.groups = const {},
    this.knockout = const KnockoutPredictions(),
    this.awards = const AwardsPredictions(),
  });

  Map<String, dynamic> toJson() => {
        'groups': groups.map((k, v) => MapEntry(k, v.toJson())),
        'knockout': knockout.toJson(),
        'awards': awards.toJson(),
      };

  factory WorldCupPredictions.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'] as Map<String, dynamic>? ?? {};
    return WorldCupPredictions(
      groups: rawGroups.map((k, v) =>
          MapEntry(k, GroupPrediction.fromJson(v as Map<String, dynamic>))),
      knockout: KnockoutPredictions.fromJson(
          json['knockout'] as Map<String, dynamic>? ?? {}),
      awards: AwardsPredictions.fromJson(
          json['awards'] as Map<String, dynamic>? ?? {}),
    );
  }

  WorldCupPredictions copyWith({
    Map<String, GroupPrediction>? groups,
    KnockoutPredictions? knockout,
    AwardsPredictions? awards,
  }) =>
      WorldCupPredictions(
        groups: groups ?? this.groups,
        knockout: knockout ?? this.knockout,
        awards: awards ?? this.awards,
      );
}

// ─── Config de awards ─────────────────────────────────────
class AwardConfig {
  final String key, label, category, placeholder, iconVariant;
  const AwardConfig({
    required this.key, required this.label, required this.category,
    required this.placeholder, required this.iconVariant,
  });
}

const List<AwardConfig> kAwardsConfig = [
  AwardConfig(key: 'topScorer', label: 'Bota de Oro', category: 'Máximo Goleador', placeholder: 'Nombre del goleador...', iconVariant: 'gold'),
  AwardConfig(key: 'topAssist', label: 'Mejor Asistidor', category: 'Más Asistencias', placeholder: 'Nombre del asistidor...', iconVariant: 'blue'),
  AwardConfig(key: 'goldenBall', label: 'Balón de Oro', category: 'Mejor Jugador del Mundial', placeholder: 'Nombre del jugador...', iconVariant: 'gold'),
  AwardConfig(key: 'bestYoungPlayer', label: 'Mejor Joven', category: 'Sub-21 Destacado', placeholder: 'Nombre del jugador...', iconVariant: 'green'),
  AwardConfig(key: 'goldenGlove', label: 'Guante de Oro', category: 'Mejor Portero', placeholder: 'Nombre del portero...', iconVariant: 'blue'),
  AwardConfig(key: 'surpriseTeam', label: 'Selección Sorpresa', category: 'Equipo Revelación', placeholder: 'Nombre del equipo...', iconVariant: 'green'),
  AwardConfig(key: 'disappointmentTeam', label: 'Selec. Decepción', category: 'Bajo Rendimiento', placeholder: 'Nombre del equipo...', iconVariant: 'red'),
  AwardConfig(key: 'breakoutPlayer', label: 'Jugador Revelación', category: 'Descubrimiento del Torneo', placeholder: 'Nombre del jugador...', iconVariant: 'amber'),
  AwardConfig(key: 'disappointmentPlayer', label: 'Jugador Decepción', category: 'Por Debajo de Expectativas', placeholder: 'Nombre del jugador...', iconVariant: 'red'),
];

// ─── Config de bracket KO ─────────────────────────────────
class KoMatchConfig {
  final String id; // FIX: siempre String
  final String home, away, label, homeDesc, awayDesc;
  const KoMatchConfig({
    required this.id, required this.home, required this.away,
    required this.label, this.homeDesc = '', this.awayDesc = '',
  });
}

const List<KoMatchConfig> kRound16 = [
  KoMatchConfig(id: '1',  home: 'E-1', away: 'ABCDF-3',  label: 'Llave 1',  homeDesc: '1° Grupo E',  awayDesc: '3° A/B/C/D/F'),
  KoMatchConfig(id: '2',  home: 'I-1', away: 'CDFGH-3',  label: 'Llave 2',  homeDesc: '1° Grupo I',  awayDesc: '3° C/D/F/G/H'),
  KoMatchConfig(id: '3',  home: 'A-2', away: 'B-2',      label: 'Llave 3',  homeDesc: '2° Grupo A',  awayDesc: '2° Grupo B'),
  KoMatchConfig(id: '4',  home: 'F-1', away: 'C-2',      label: 'Llave 4',  homeDesc: '1° Grupo F',  awayDesc: '2° Grupo C'),
  KoMatchConfig(id: '5',  home: 'K-2', away: 'L-2',      label: 'Llave 5',  homeDesc: '2° Grupo K',  awayDesc: '2° Grupo L'),
  KoMatchConfig(id: '6',  home: 'H-1', away: 'J-2',      label: 'Llave 6',  homeDesc: '1° Grupo H',  awayDesc: '2° Grupo J'),
  KoMatchConfig(id: '7',  home: 'D-1', away: 'BEFIJ-3',  label: 'Llave 7',  homeDesc: '1° Grupo D',  awayDesc: '3° B/E/F/I/J'),
  KoMatchConfig(id: '8',  home: 'G-1', away: 'AEHIJ-3',  label: 'Llave 8',  homeDesc: '1° Grupo G',  awayDesc: '3° A/E/H/I/J'),
  KoMatchConfig(id: '9',  home: 'C-1', away: 'F-2',      label: 'Llave 9',  homeDesc: '1° Grupo C',  awayDesc: '2° Grupo F'),
  KoMatchConfig(id: '10', home: 'E-2', away: 'I-2',      label: 'Llave 10', homeDesc: '2° Grupo E',  awayDesc: '2° Grupo I'),
  KoMatchConfig(id: '11', home: 'A-1', away: 'CEFHI-3',  label: 'Llave 11', homeDesc: '1° Grupo A',  awayDesc: '3° C/E/F/H/I'),
  KoMatchConfig(id: '12', home: 'L-1', away: 'BHIJK-3',  label: 'Llave 12', homeDesc: '1° Grupo L',  awayDesc: '3° B/H/I/J/K'),
  KoMatchConfig(id: '13', home: 'J-1', away: 'H-2',      label: 'Llave 13', homeDesc: '1° Grupo J',  awayDesc: '2° Grupo H'),
  KoMatchConfig(id: '14', home: 'D-2', away: 'G-2',      label: 'Llave 14', homeDesc: '2° Grupo D',  awayDesc: '2° Grupo G'),
  KoMatchConfig(id: '15', home: 'B-1', away: 'EFGIJ-3',  label: 'Llave 15', homeDesc: '1° Grupo B',  awayDesc: '3° E/F/G/I/J'),
  KoMatchConfig(id: '16', home: 'K-1', away: 'DEJL-3',   label: 'Llave 16', homeDesc: '1° Grupo K',  awayDesc: '3° D/E/J/L'),
];

// ─── Helpers de cálculo ───────────────────────────────────
List<GroupTableRow> calcGroupTable(String group, GroupPrediction? pred) {
  final teams = kGroupsData[group];
  if (teams == null) return [];

  final matches = [
    [teams[0], teams[1]], [teams[2], teams[3]],
    [teams[0], teams[2]], [teams[1], teams[3]],
    [teams[0], teams[3]], [teams[1], teams[2]],
  ];

  final table = teams.map((t) => GroupTableRow(team: t)).toList();
  final matchPreds = pred?.matches ?? {};

  matchPreds.forEach((idx, mp) {
    if (!mp.isFilled) return;
    final home = matches[idx][0];
    final away = matches[idx][1];
    final hi = teams.indexOf(home);
    final ai = teams.indexOf(away);
    final hs = int.tryParse(mp.homeScore) ?? 0;
    final as_ = int.tryParse(mp.awayScore) ?? 0;

    table[hi] = table[hi].copyWith(played: table[hi].played + 1, gf: table[hi].gf + hs, ga: table[hi].ga + as_);
    table[ai] = table[ai].copyWith(played: table[ai].played + 1, gf: table[ai].gf + as_, ga: table[ai].ga + hs);

    if (hs > as_) {
      table[hi] = table[hi].copyWith(won: table[hi].won + 1, pts: table[hi].pts + 3);
      table[ai] = table[ai].copyWith(lost: table[ai].lost + 1);
    } else if (hs < as_) {
      table[ai] = table[ai].copyWith(won: table[ai].won + 1, pts: table[ai].pts + 3);
      table[hi] = table[hi].copyWith(lost: table[hi].lost + 1);
    } else {
      table[hi] = table[hi].copyWith(drawn: table[hi].drawn + 1, pts: table[hi].pts + 1);
      table[ai] = table[ai].copyWith(drawn: table[ai].drawn + 1, pts: table[ai].pts + 1);
    }
    table[hi] = table[hi].copyWith(gd: table[hi].gf - table[hi].ga);
    table[ai] = table[ai].copyWith(gd: table[ai].gf - table[ai].ga);
  });

  table.sort((a, b) {
    if (b.pts != a.pts) return b.pts.compareTo(a.pts);
    if (b.gd != a.gd) return b.gd.compareTo(a.gd);
    return b.gf.compareTo(a.gf);
  });
  return table;
}

List<ThirdPlaceEntry> calcBestThirds(Map<String, GroupPrediction> groups) {
  final thirds = <ThirdPlaceEntry>[];
  for (final g in kGroupsData.keys) {
    final table = calcGroupTable(g, groups[g]);
    if (table.length > 2) {
      final t = table[2];
      thirds.add(ThirdPlaceEntry(
        team: t.team, group: g,
        played: t.played, won: t.won, drawn: t.drawn, lost: t.lost,
        gf: t.gf, ga: t.ga, gd: t.gd, pts: t.pts,
      ));
    }
  }
  thirds.sort((a, b) {
    if (b.pts != a.pts) return b.pts.compareTo(a.pts);
    if (b.gd != a.gd) return b.gd.compareTo(a.gd);
    return b.gf.compareTo(a.gf);
  });
  return thirds.take(8).toList();
}

// Dado el ganador de una semi y los equipos que participaron,
// devuelve el perdedor (para el partido por el 3er puesto).
// homeTeam/awayTeam deben ser los ganadores de cuartos que se enfrentaron.
String? calcSemiLoser({
  required String? winner,
  required String? homeTeam,
  required String? awayTeam,
}) {
  if (winner == null || homeTeam == null || awayTeam == null) return null;
  if (winner == homeTeam) return awayTeam;
  if (winner == awayTeam) return homeTeam;
  return null;
}