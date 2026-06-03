// lib/features/notifications/presentation/notifications_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notifications_models.dart';
import '../domain/notifications_providers.dart';
import '../../../shared/layout/scaffold_with_nav_bar.dart';

// ── Paleta (igual que notes_page) ─────────────────────────────────
const _bg      = Color(0xFFF5F0E8);
const _card    = Color(0xFFEDE7DA);
const _border  = Color(0xFF1A1A2E);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF88887D);
const _shadow  = Color(0x661A1A2E);
const _accent  = Color(0xFF5B4FD8);   // morado app
const _green   = Color(0xFF00C48C);
const _red     = Color(0xFFFF3C00);

// ═══════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {

  @override
  Widget build(BuildContext context) {
    final filtered   = ref.watch(filteredNotificationsProvider);
    final all        = ref.watch(notificationsProvider);
    final filter     = ref.watch(notifFilterProvider);
    final totalCount = all.asData?.value.length ?? 0;
    final newCount   = all.asData?.value.where((n) => n.type == NotifType.newMatch).length ?? 0;
    final finCount   = all.asData?.value.where((n) => n.type == NotifType.finished).length ?? 0;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          _NotifHeader(
            totalCount: totalCount,
            onBack: () => Navigator.of(context).pop(),
          ),

          // ── Filter Bar ──────────────────────────────────────────
          _FilterBar(
            filter:     filter,
            totalCount: totalCount,
            newCount:   newCount,
            finCount:   finCount,
            onChanged:  (f) => ref.read(notifFilterProvider.notifier).set(f),
          ),

          // ── Lista ───────────────────────────────────────────────
          Expanded(
            child: filtered.when(
              loading: () => const _SkeletonList(),
              error:   (e, _) => _ErrorState(message: e.toString()),
              data:    (list) => list.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
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

// ═══════════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════════
class _NotifHeader extends StatelessWidget {
  final int totalCount;
  final VoidCallback onBack;
  const _NotifHeader({required this.totalCount, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 12),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
        boxShadow: [
          BoxShadow(color: _shadow, offset: Offset(0, 2), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          // Botón back neo-brutalista
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _bg,
                border: Border.all(color: _border, width: 1),
                boxShadow: const [
                  BoxShadow(color: _shadow, offset: Offset(2, 2), blurRadius: 0),
                ],
              ),
              child: const Icon(Icons.arrow_back, size: 16, color: _text),
            ),
          ),
          const SizedBox(width: 12),

          // Acento + título
          Container(width: 4, height: 26, color: _accent),
          const SizedBox(width: 8),
          const Text(
            'NOTIFICACIONES',
            style: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: _text,
            ),
          ),
          const SizedBox(width: 8),

          // Badge contador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _accent,
              border: Border.all(color: _border, width: 1),
              boxShadow: const [
                BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0),
              ],
            ),
            child: Text(
              '$totalCount',
              style: const TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FILTER BAR
// ═══════════════════════════════════════════════════════════
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
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              label: 'TODAS',
              count: totalCount,
              active: filter == NotifFilter.all,
              onTap: () => onChanged(NotifFilter.all),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterChip(
              label: 'NUEVAS',
              count: newCount,
              active: filter == NotifFilter.newMatch,
              color: _accent,
              onTap: () => onChanged(NotifFilter.newMatch),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterChip(
              label: 'FINAL',
              count: finCount,
              active: filter == NotifFilter.finished,
              color: _green,
              onTap: () => onChanged(NotifFilter.finished),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
    this.color = _accent,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 32,
        transform: _pressed && active
            ? (Matrix4.identity()..translate(2.0, 2.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: active ? widget.color : _bg,
          border: Border.all(color: _border, width: 1),
          boxShadow: (_pressed && active)
              ? []
              : active
                  ? const [BoxShadow(color: _shadow, offset: Offset(2, 2), blurRadius: 0)]
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: active ? Colors.white : _muted,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withOpacity(0.25)
                    : _card,
                border: Border.all(
                  color: active ? Colors.transparent : _border,
                  width: 0.5,
                ),
              ),
              child: Text(
                '${widget.count}',
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: active ? Colors.white : _muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  NOTIF CARD
// ═══════════════════════════════════════════════════════════
class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    final isNew       = notif.type == NotifType.newMatch;
    final accentColor = isNew ? _accent : _green;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border, width: 1),
        boxShadow: const [
          BoxShadow(color: _shadow, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra lateral de acento
            Container(width: 4, color: accentColor),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge + descripción
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor,
                            border: Border.all(color: _border, width: 1),
                          ),
                          child: Text(
                            isNew ? 'NUEVO' : 'FINAL',
                            style: const TextStyle(
                              fontFamily: 'DM Mono',
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notif.description,
                            style: const TextStyle(
                              fontFamily: 'DM Mono',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Meta chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MetaChip(icon: Icons.emoji_events_outlined, text: notif.league),
                        _MetaChip(icon: Icons.calendar_today_outlined, text: notif.date),
                        if (notif.time != null)
                          _MetaChip(icon: Icons.access_time, text: notif.time!),
                      ],
                    ),

                    // Resultado
                    if (notif.result != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _bg,
                          border: Border.all(color: _green, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3300C48C),
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          notif.result!,
                          style: const TextStyle(
                            fontFamily: 'DM Mono',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: _green,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Icono derecho
            Container(
              width: 44,
              color: accentColor.withOpacity(0.08),
              child: Icon(
                isNew
                    ? Icons.notifications_active_outlined
                    : Icons.check_circle_outline_rounded,
                color: accentColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meta chip ─────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _border.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: _muted),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SKELETON
// ═══════════════════════════════════════════════════════════
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        height: 80,
        decoration: BoxDecoration(
          color: _card,
          border: Border.all(color: _border, width: 1),
          boxShadow: const [
            BoxShadow(color: _shadow, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            Container(width: 4, color: _border.withOpacity(0.15)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                        height: 10,
                        width: 60,
                        color: _border.withOpacity(0.1)),
                    Container(
                        height: 12,
                        width: double.infinity,
                        color: _border.withOpacity(0.08)),
                    Container(
                        height: 9,
                        width: 140,
                        color: _border.withOpacity(0.06)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _card,
              border: Border.all(color: _border, width: 1),
              boxShadow: const [
                BoxShadow(color: _shadow, offset: Offset(3, 3), blurRadius: 0),
              ],
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 28,
              color: _muted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'SIN NOTIFICACIONES',
            style: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: _text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aquí aparecerán las novedades',
            style: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 10,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ERROR STATE
// ═══════════════════════════════════════════════════════════
class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          border: Border.all(color: _red, width: 1),
          boxShadow: const [
            BoxShadow(color: _shadow, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _red,
                border: Border.all(color: _border, width: 1),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 10,
                  color: _text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}