// ─────────────────────────────────────────────
// PROFILE MODELS
// Tablas: users · available_achievements · available_titles
//         predictions · monthly_championship_history
// ─────────────────────────────────────────────

class UserProfile {
  final String id;
  final String authId;
  final String name;
  final String? email;
  final String? bio;
  final String? favoriteTeam;
  final String? favoritePlayer;
  final String? gender;
  final String? nationality;
  final String? avatarUrl;
  final String? equippedBannerUrl;
  final int level;

  // Global stats
  final int points;
  final int predictions;
  final int correct;
  final int currentStreak;
  final int bestStreak;

  // Monthly stats
  final int monthlyPoints;
  final int monthlyPredictions;
  final int monthlyCorrect;
  final int monthlyChampionships;

  final String role;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.authId,
    required this.name,
    this.email,
    this.bio,
    this.favoriteTeam,
    this.favoritePlayer,
    this.gender,
    this.nationality,
    this.avatarUrl,
    this.equippedBannerUrl,
    required this.level,
    required this.points,
    required this.predictions,
    required this.correct,
    required this.currentStreak,
    required this.bestStreak,
    required this.monthlyPoints,
    required this.monthlyPredictions,
    required this.monthlyCorrect,
    required this.monthlyChampionships,
    required this.role,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        authId: json['auth_id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        bio: json['bio'] as String?,
        favoriteTeam: json['favorite_team'] as String?,
        favoritePlayer: json['favorite_player'] as String?,
        gender: json['gender'] as String?,
        nationality: json['nationality'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        equippedBannerUrl: json['equipped_banner_url'] as String?,
        level: (json['level'] as int?) ?? 1,
        points: (json['points'] as int?) ?? 0,
        predictions: (json['predictions'] as int?) ?? 0,
        correct: (json['correct'] as int?) ?? 0,
        currentStreak: (json['current_streak'] as int?) ?? 0,
        bestStreak: (json['best_streak'] as int?) ?? 0,
        monthlyPoints: (json['monthly_points'] as int?) ?? 0,
        monthlyPredictions: (json['monthly_predictions'] as int?) ?? 0,
        monthlyCorrect: (json['monthly_correct'] as int?) ?? 0,
        monthlyChampionships: (json['monthly_championships'] as int?) ?? 0,
        role: (json['is_admin'] == true) ? 'admin' : 'user',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  double get accuracy =>
      predictions > 0 ? (correct / predictions * 100) : 0.0;

  int get pointsInCurrentLevel => points % 20;
  double get levelProgress => pointsInCurrentLevel / 20.0;
  int get pointsToNextLevel => 20 - pointsInCurrentLevel;
}

// ─── UPDATE INPUT ─────────────────────────────
class UpdateProfileInput {
  final String? name;
  final String? bio;
  final String? favoriteTeam;
  final String? favoritePlayer;
  final String? gender;
  final String? nationality;
  final String? equippedBannerUrl;

  const UpdateProfileInput({
    this.name,
    this.bio,
    this.favoriteTeam,
    this.favoritePlayer,
    this.gender,
    this.nationality,
    this.equippedBannerUrl,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (bio != null) map['bio'] = bio;
    if (favoriteTeam != null) map['favorite_team'] = favoriteTeam;
    if (favoritePlayer != null) map['favorite_player'] = favoritePlayer;
    if (gender != null) map['gender'] = gender;
    if (nationality != null) map['nationality'] = nationality;
    if (equippedBannerUrl != null) {
      map['equipped_banner_url'] = equippedBannerUrl;
    }
    return map;
  }
}

// ─── ACHIEVEMENT ──────────────────────────────
class Achievement {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? category;
  final String? requirementType;
  final int? requirementValue;

  const Achievement({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.category,
    this.requirementType,
    this.requirementValue,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        category: json['category'] as String?,
        requirementType: json['requirement_type'] as String?,
        requirementValue: json['requirement_value'] as int?,
      );
}

// ─── TITLE ────────────────────────────────────
class UserTitle {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final String? requirementAchievementId;

  const UserTitle({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.requirementAchievementId,
  });

  factory UserTitle.fromJson(Map<String, dynamic> json) => UserTitle(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        color: json['color'] as String?,
        requirementAchievementId:
            json['requirement_achievement_id'] as String?,
      );
}

// ─── BANNER ───────────────────────────────────
class UserBanner {
  final String id;
  final String name;
  final String? description;
  final String imageUrl;

  const UserBanner({
    required this.id,
    required this.name,
    this.description,
    required this.imageUrl,
  });

  factory UserBanner.fromJson(Map<String, dynamic> json) => UserBanner(
        id: json['available_banners']['id'] as String,
        name: json['available_banners']['name'] as String,
        description: json['available_banners']['description'] as String?,
        imageUrl: json['available_banners']['image_url'] as String,
      );
}

// ─── MONTHLY CHAMPIONSHIP ─────────────────────
class MonthlyChampionship {
  final String id;
  final String monthYear;
  final int points;
  final DateTime awardedAt;

  const MonthlyChampionship({
    required this.id,
    required this.monthYear,
    required this.points,
    required this.awardedAt,
  });

  factory MonthlyChampionship.fromJson(Map<String, dynamic> json) =>
      MonthlyChampionship(
        id: json['id'] as String,
        monthYear: json['month_year'] as String,
        points: (json['points'] as int?) ?? 0,
        awardedAt: DateTime.parse(json['awarded_at'] as String),
      );
}

// ─── PREDICTION HISTORY ENTRY ─────────────────
class PredictionHistoryEntry {
  final String id;
  final int homeScore;
  final int awayScore;
  final int pointsEarned;
  final String? resultType; // 'exact' | 'correct' | 'wrong' | null
  final DateTime createdAt;
  final MatchInfo? match;

  const PredictionHistoryEntry({
    required this.id,
    required this.homeScore,
    required this.awayScore,
    required this.pointsEarned,
    this.resultType,
    required this.createdAt,
    this.match,
  });

  factory PredictionHistoryEntry.fromJson(Map<String, dynamic> json) =>
      PredictionHistoryEntry(
        id: json['id'] as String,
        homeScore: (json['home_score'] as int?) ?? 0,
        awayScore: (json['away_score'] as int?) ?? 0,
        pointsEarned: (json['points_earned'] as int?) ?? 0,
        resultType: json['result_type'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        match: json['matches'] != null
            ? MatchInfo.fromJson(json['matches'] as Map<String, dynamic>)
            : null,
      );
}

class MatchInfo {
  final String id;
  final String league;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamLogoUrl;
  final String? awayTeamLogoUrl;
  final String? leagueLogoUrl;
  final int? resultHome;
  final int? resultAway;
  final String status;
  final String date;

  const MatchInfo({
    required this.id,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamLogoUrl,
    this.awayTeamLogoUrl,
    this.leagueLogoUrl,
    this.resultHome,
    this.resultAway,
    required this.status,
    required this.date,
  });

  factory MatchInfo.fromJson(Map<String, dynamic> json) => MatchInfo(
        id: json['id'] as String,
        league: json['league'] as String,
        homeTeam: json['home_team'] as String,
        awayTeam: json['away_team'] as String,
        homeTeamLogoUrl: json['home_team_logo_url'] as String?,
        awayTeamLogoUrl: json['away_team_logo_url'] as String?,
        leagueLogoUrl: json['league_logo_url'] as String?,
        resultHome: json['result_home'] as int?,
        resultAway: json['result_away'] as int?,
        status: (json['status'] as String?) ?? 'pending',
        date: json['date'] as String,
      );
}