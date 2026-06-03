import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notifications_service.dart';
import 'notifications_models.dart';

// ── Servicio ──────────────────────────────────────────────────────
final notificationsServiceProvider = Provider((_) => NotificationsService());

// ── Lista de notificaciones ───────────────────────────────────────
final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  return ref.watch(notificationsServiceProvider).fetchNotifications();
});

// ── Filtro activo (Riverpod 3.x → Notifier) ──────────────────────
class NotifFilterNotifier extends Notifier<NotifFilter> {
  @override
  NotifFilter build() => NotifFilter.all;

  void set(NotifFilter f) => state = f;
}

final notifFilterProvider =
    NotifierProvider<NotifFilterNotifier, NotifFilter>(
  NotifFilterNotifier.new,
);

// ── Lista filtrada (derivada) ─────────────────────────────────────
final filteredNotificationsProvider =
    Provider<AsyncValue<List<AppNotification>>>((ref) {
  final all = ref.watch(notificationsProvider);
  final filter = ref.watch(notifFilterProvider);

  return all.whenData((list) {
    if (filter == NotifFilter.all) return list;
    final target =
        filter == NotifFilter.newMatch ? NotifType.newMatch : NotifType.finished;
    return list.where((n) => n.type == target).toList();
  });
});