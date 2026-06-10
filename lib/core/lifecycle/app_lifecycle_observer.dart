import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/domain/dashboard_provider.dart';
import '../../features/albums/domain/albums_provider.dart';
import '../../features/history/domain/history_providers.dart';

class AppLifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;
  const AppLifecycleObserver({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleObserver> createState() =>
      _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  void _refreshAll() {
    ref.invalidate(currentUserProvider);
    ref.invalidate(albumsUserIdProvider);
    ref.invalidate(historyStatsProvider);
    ref.invalidate(historyPlayersProvider);
    ref.invalidate(historyTeamsProvider);
    ref.invalidate(historyCompetitionsProvider);
    ref.invalidate(historyEventsProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
