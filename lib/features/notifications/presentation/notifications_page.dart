// lib/features/notifications/presentation/notifications_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notifications_models.dart';
import '../domain/notifications_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredNotificationsProvider);
    final all = ref.watch(notificationsProvider);
    final filter = ref.watch(notifFilterProvider);

    // Conteos para los chips
    final newCount = all.valueOrNull
            ?.where((n) => n.type == NotifType.newMatch)
            .length ??
        0;
    final finCount =
        all.valueOrNull?.where((n) => n.type == NotifType.finished).length ?? 0;
    final totalCount = all.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1824),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF8B7FC7),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'NOTIFICACIONES',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Color(0xFFB0AAC0),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: const Color(0xFF2A2535),
              child: Text(
                '$totalCount',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B7FC7),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Filtros ──────────────────────────────────────────────
          _FilterBar(
            filter: filter,
            totalCount: totalCount,
            newCount: newCount,
            finCount: finCount,
            onChanged: (f) => ref.read(notifFilterProvider.notifier).state = f,
          ),

          // ── Lista ────────────────────────────────────────────────
          Expanded(
            child: filtered.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B7FC7)),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (list) => list.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) => _NotifCard(notif: list[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final NotifFilter filter;
  final int totalCount, newCount, finCount;
  final ValueChanged<NotifFilter> onChanged;

  const _FilterBar({
    required this.filter,
    required this.totalCount,
    required this.newCount,
    required this.finCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: const Color(0xFF1A1824),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todas',
            count: totalCount,
            active: filter == NotifFilter.all,
            onTap: () => onChanged(NotifFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Nuevas',
            count: newCount,
            active: filter == NotifFilter.newMatch,
            onTap: () => onChanged(NotifFilter.newMatch),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Final.',
            count: finCount,
            active: filter == NotifFilter.finished,
            onTap: () => onChanged(NotifFilter.finished),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF8B7FC7) : const Color(0xFF2A2535),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: active ? Colors.white : const Color(0xFF60519B),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              color: active
                  ? Colors.white.withOpacity(0.25)
                  : Colors.white.withOpacity(0.06),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0xFF60519B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notif Card ────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    final isNew = notif.type == NotifType.newMatch;
    final accentColor =
        isNew ? const Color(0xFF8B7FC7) : const Color(0xFF34D399);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
          left: BorderSide(color: accentColor, width: 3),
        ),
        color: isNew
            ? const Color(0xFF8B7FC7).withOpacity(0.04)
            : const Color(0xFF34D399).withOpacity(0.04),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono
          Container(
            width: 34,
            height: 34,
            color: accentColor.withOpacity(0.12),
            child: Icon(
              isNew ? Icons.emoji_events_rounded : Icons.check_circle_rounded,
              color: accentColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge + título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: accentColor,
                      child: Text(
                        isNew ? 'NUEVO' : 'FINAL',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notif.description,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF0F1F7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Meta info
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MetaItem(icon: Icons.emoji_events_outlined, text: notif.league),
                    _MetaItem(icon: Icons.calendar_today_outlined, text: notif.date),
                    if (notif.time != null)
                      _MetaItem(icon: Icons.access_time, text: notif.time!),
                  ],
                ),

                // Resultado
                if (notif.result != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399).withOpacity(0.08),
                      border: Border.all(
                          color: const Color(0xFF34D399).withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      notif.result!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF34D399),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: const Color(0xFF5A566E)),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5A566E),
          ),
        ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 40, color: Color(0xFF3A3550)),
          SizedBox(height: 12),
          Text(
            'SIN NOTIFICACIONES',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xFF3A3550),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Aquí aparecerán las novedades',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Color(0xFF2A2535),
            ),
          ),
        ],
      ),
    );
  }
}