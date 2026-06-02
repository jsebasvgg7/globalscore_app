import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/stats_service.dart';
import 'stats_model.dart';

class StatsTimeRangeNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void set(String range) => state = range;
}

final statsTimeRangeProvider =
    NotifierProvider<StatsTimeRangeNotifier, String>(StatsTimeRangeNotifier.new);

final userIdProvider = FutureProvider<String>((ref) async {
  final authId = Supabase.instance.client.auth.currentUser!.id;
  final data = await Supabase.instance.client
      .from('users')
      .select('id')
      .eq('auth_id', authId)
      .single();
  return data['id'] as String;
});

final statsProvider = FutureProvider<StatsModel>((ref) async {
  final timeRange = ref.watch(statsTimeRangeProvider);
  final userId = await ref.watch(userIdProvider.future);

  try {
    return await StatsService().fetchStats(userId, timeRange);
  } catch (e) {
     rethrow;
  }
});