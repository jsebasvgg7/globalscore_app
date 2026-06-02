import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/dashboard_service.dart';

// ── Usuario actual ────────────────────────────────────────────
final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return DashboardService.getCurrentUser();
});

// ── Datos del dashboard ───────────────────────────────────────
final dashboardDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return {'matches': [], 'leagues': [], 'awards': [], 'topUsers': []};

  final userId = user['id'] as String;

  final results = await Future.wait([
    DashboardService.getMatchesWithPredictions(userId),
    DashboardService.getLeaguesWithPredictions(userId),
    DashboardService.getAwardsWithPredictions(userId),
    DashboardService.getTopUsers(),
  ]);

  return {
    'matches': results[0],
    'leagues': results[1],
    'awards': results[2],
    'topUsers': results[3],
  };
});