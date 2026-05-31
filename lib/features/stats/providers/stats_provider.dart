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

final statsProvider = FutureProvider.autoDispose<StatsModel>((ref) async {
  final timeRange = ref.watch(statsTimeRangeProvider);
  final userId = Supabase.instance.client.auth.currentUser!.id;
  return StatsService().fetchStats(userId, timeRange);
});