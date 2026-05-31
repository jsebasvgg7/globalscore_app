import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/stats_service.dart';
import '../domain/stats_model.dart';

class StatsTimeRangeNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void set(String range) => state = range;
}

final statsTimeRangeProvider =
    NotifierProvider<StatsTimeRangeNotifier, String>(StatsTimeRangeNotifier.new);

final statsProvider = FutureProvider<StatsModel>((ref) async {
  final timeRange = ref.watch(statsTimeRangeProvider);

  // auth.currentUser.id = auth_id, NO es el users.id que usan las FK
  final authId = Supabase.instance.client.auth.currentUser!.id;

  final userData = await Supabase.instance.client
      .from('users')
      .select('id')
      .eq('auth_id', authId)
      .single();

  final userId = userData['id'] as String;

  return StatsService().fetchStats(userId, timeRange);
});