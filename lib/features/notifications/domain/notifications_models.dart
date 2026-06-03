// lib/features/notifications/domain/notifications_models.dart

enum NotifType { newMatch, finished }

class AppNotification {
  final String id;
  final NotifType type;
  final String description; // "TeamA vs TeamB"
  final String league;
  final String date;
  final String? time;
  final String? result; // solo si finished
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.description,
    required this.league,
    required this.date,
    this.time,
    this.result,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final status = map['status'] as String? ?? '';
    final isFinished = status == 'finished';
    final homeScore = map['result_home'];
    final awayScore = map['result_away'];

    return AppNotification(
      id: map['id'].toString(),
      type: isFinished ? NotifType.finished : NotifType.newMatch,
      description: '${map['home_team']} vs ${map['away_team']}',
      league: map['league'] as String? ?? '',
      date: map['date'] as String? ?? '',
      time: map['time'] as String?,
      result: isFinished
          ? '${homeScore ?? 0} - ${awayScore ?? 0}'
          : null,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

enum NotifFilter { all, newMatch, finished }