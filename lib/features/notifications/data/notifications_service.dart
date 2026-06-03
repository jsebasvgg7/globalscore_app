// lib/features/notifications/data/notifications_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/notifications_models.dart';

class NotificationsService {
  final _db = Supabase.instance.client;

  /// Trae los partidos de los últimos 7 días (igual que React)
  Future<List<AppNotification>> fetchNotifications() async {
    final sevenDaysAgo =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    final data = await _db
        .from('matches')
        .select('id, home_team, away_team, league, date, time, status, result_home, result_away, created_at')
        .gte('created_at', sevenDaysAgo)
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => AppNotification.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}