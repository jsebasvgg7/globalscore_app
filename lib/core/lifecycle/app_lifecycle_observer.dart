import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importa los providers que deben refrescarse al volver a la app
import '../../features/dashboard/domain/dashboard_provider.dart';
import '../../features/albums/domain/albums_provider.dart';
import '../../features/history/domain/history_providers.dart';

// ══════════════════════════════════════════════════════════════
//  APP LIFECYCLE OBSERVER
//
//  Detecta cuando la app vuelve a primer plano (resumed) y
//  fuerza un refresco de todos los providers críticos.
//
//  USO — en main.dart, dentro de GlobalScoreApp.build():
//
//    @override
//    Widget build(BuildContext context, WidgetRef ref) {
//      return AppLifecycleObserver(
//        child: MaterialApp.router(...),
//      );
//    }
// ══════════════════════════════════════════════════════════════

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
    // ── Dashboard: los StreamProviders ya tienen Realtime activo,
    //    pero forzamos un reload del usuario por si la sesión cambió.
    ref.invalidate(currentUserProvider);

    // ── Albums: el StreamProvider detecta cambios solo, pero si
    //    el usuario estuvo mucho tiempo fuera, forzamos reload.
    ref.invalidate(albumsUserIdProvider);

    // ── Historia: polling cada 5 min, pero al volver forzamos
    //    refresco inmediato de las listas principales.
    ref.invalidate(historyStatsProvider);
    ref.invalidate(historyPlayersProvider);
    ref.invalidate(historyTeamsProvider);
    ref.invalidate(historyCompetitionsProvider);
    ref.invalidate(historyEventsProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
