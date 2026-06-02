import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/layout/scaffold_with_nav_bar.dart'
    show hideTopBarProvider, hideBottomNavProvider;
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import '../../data/history_service.dart';
import 'history_events_shared.dart';
import 'history_event_detail.dart';

// ══════════════════════════════════════════════════════════════
//  ROOT
// ══════════════════════════════════════════════════════════════

class HistoryEventsPage extends ConsumerStatefulWidget {
  const HistoryEventsPage({super.key});

  @override
  ConsumerState<HistoryEventsPage> createState() => _HistoryEventsPageState();
}

class _HistoryEventsPageState extends ConsumerState<HistoryEventsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hideTopBarProvider.notifier).hide();
      ref.read(hideBottomNavProvider.notifier).hide();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleBack() {
    ref.read(hideTopBarProvider.notifier).show();
    ref.read(hideBottomNavProvider.notifier).show();
    ref.read(historySectionProvider.notifier).goBack();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedEventProvider);

    if (selected != null) {
      return HistoryEventDetail(
        event: selected,
        onBack: () => ref.read(selectedEventProvider.notifier).select(null),
      );
    }

    return _EventListView(searchCtrl: _searchCtrl, onBack: _handleBack);
  }
}

// ══════════════════════════════════════════════════════════════
//  LIST VIEW
// ══════════════════════════════════════════════════════════════

class _EventListView extends ConsumerWidget {
  final TextEditingController searchCtrl;
  final VoidCallback onBack;
  const _EventListView({required this.searchCtrl, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync  = ref.watch(filteredEventsProvider);
    final allAsync     = ref.watch(historyEventsProvider);
    final catFilter    = ref.watch(eventCategoryFilterProvider);

    final totalCount   = allAsync.whenOrNull(data: (l) => l.length) ?? 0;
    final playerCount  = allAsync.whenOrNull(
          data: (l) => l.where((e) => e.eventCategory == 'player').length) ?? 0;
    final teamCount    = allAsync.whenOrNull(
          data: (l) => l.where((e) => e.eventCategory == 'team').length) ?? 0;

    return Scaffold(
      backgroundColor: kEvBg,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────
          _EventsHeader(onBack: onBack),

          // ── Stats strip ──────────────────────────────────
          _StatsStrip(
            total: totalCount,
            players: playerCount,
            teams: teamCount,
          ),

          // ── Search bar ───────────────────────────────────
          _SearchBar(controller: searchCtrl),

          // ── Category filter tabs ─────────────────────────
          _CategoryTabs(active: catFilter),

          // ── Counter row ──────────────────────────────────
          eventsAsync.whenOrNull(data: (list) => _CounterRow(count: list.length))
              ?? const SizedBox.shrink(),

          // ── List ─────────────────────────────────────────
          Expanded(
            child: eventsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: kEvAccent)),
              error: (e, _) =>
                  Center(child: Text('Error: $e', style: evMono(color: kEvMuted))),
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Text('Sin resultados', style: evMono(color: kEvMuted)),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (_, i) => _EventCard(
                    event: events[i],
                    onTap: () =>
                        ref.read(selectedEventProvider.notifier).select(events[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────
class _EventsHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _EventsHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 18),
      decoration: BoxDecoration(
        color: kEvBg,
        border: Border(bottom: BorderSide(color: kEvBorder, width: 1.5)),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 0, top: 0,
            child: EvDotGrid(cols: 5, rows: 4),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kEvBg,
                        border: Border.all(color: kEvBorder, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: kEvDark.withOpacity(0.45),
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, size: 10, color: kEvDark),
                          const SizedBox(width: 5),
                          Text('HISTÓRICO',
                              style: evMono(size: 8, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    color: kEvAccent,
                    child: Text('EVENTOS',
                        style: evMono(
                          size: 8, color: Colors.white,
                          weight: FontWeight.w800, letterSpacing: 1.0,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Título grande
              Row(
                children: [
                  Container(
                    width: 5, height: 44,
                    decoration: BoxDecoration(
                      color: kEvAccent,
                      border: Border.all(color: kEvBorder, width: 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EVENTOS',
                            style: evMono(
                                size: 28, weight: FontWeight.w900,
                                letterSpacing: -1.0)),
                        Text('Momentos históricos del fútbol.',
                            style: evMono(size: 11, color: kEvMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats strip ───────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final int total;
  final int players;
  final int teams;
  const _StatsStrip({
    required this.total,
    required this.players,
    required this.teams,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: evNeoBox(shadowX: 4, shadowY: 4),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(
              icon: Icons.bolt_outlined,
              iconBg: kEvAccent,
              value: '$total',
              label: 'EVENTOS',
              bordered: true,
            ),
            _StatCell(
              icon: Icons.person_outline,
              iconBg: kEvPurple,
              value: '$players',
              label: 'JUGADORES',
              bordered: true,
            ),
            _StatCell(
              icon: Icons.shield_outlined,
              iconBg: kEvBlue,
              value: '$teams',
              label: 'EQUIPOS',
              bordered: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String value;
  final String label;
  final bool bordered;
  const _StatCell({
    required this.icon,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.bordered,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: bordered
              ? Border(right: BorderSide(color: kEvBorder, width: 1.5))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                border: Border.all(color: kEvBorder, width: 1),
              ),
              child: Icon(icon, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: evMono(
                        size: 18, weight: FontWeight.w900, color: kEvAccent)),
                Text(label,
                    style: evMono(
                        size: 7, weight: FontWeight.w700,
                        letterSpacing: 0.8, color: kEvMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────
class _SearchBar extends ConsumerWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kEvBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: kEvDark.withOpacity(0.3),
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          style: evMono(size: 12),
          decoration: InputDecoration(
            hintText: 'Buscar evento...',
            hintStyle: evMono(size: 12, color: kEvMuted),
            prefixIcon: const Icon(Icons.search, size: 16, color: kEvMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 13),
                    onPressed: () {
                      controller.clear();
                      ref.read(eventSearchProvider.notifier).set('');
                    },
                  )
                : null,
          ),
          onChanged: (v) => ref.read(eventSearchProvider.notifier).set(v),
        ),
      ),
    );
  }
}

// ── Category tabs ─────────────────────────────────────────────
class _CategoryTabs extends ConsumerWidget {
  final String active;
  const _CategoryTabs({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const cats   = ['',       'player',     'team'];
    const labels = ['TODOS',  'JUGADORES',  'EQUIPOS'];

    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border(
          top:    BorderSide(color: kEvBorderL, width: 0.5),
          bottom: BorderSide(color: kEvBorder, width: 1.5),
        ),
      ),
      child: Row(
        children: List.generate(cats.length, (i) {
          final isActive = active == cats[i];
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(eventCategoryFilterProvider.notifier).set(cats[i]),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? kEvAccent : Colors.transparent,
                  border: i < cats.length - 1
                      ? Border(
                          right: BorderSide(color: kEvBorderL, width: 0.5))
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: evMono(
                    size: 9, weight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isActive ? Colors.white : kEvMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Counter row ───────────────────────────────────────────────
class _CounterRow extends StatelessWidget {
  final int count;
  const _CounterRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kEvBorder, width: 1.5)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 12, color: kEvAccent),
          const SizedBox(width: 8),
          Text('EVENTOS',
              style: evMono(
                  size: 9, weight: FontWeight.w700,
                  letterSpacing: 1.2, color: kEvMuted)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kEvAccent,
              border: Border.all(color: kEvBorder, width: 1),
            ),
            child: Text('$count ENCONTRADOS',
                style: evMono(
                    size: 8, weight: FontWeight.w800,
                    letterSpacing: 0.5, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Event card (lista) ────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final HistoricalEvent event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cc     = catColor(event.eventCategory);
    final tc     = typeColor(event.eventType);
    final imgUrl = getHistoricalImageUrl(event.imagePath);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: kEvBorderL, width: 0.5),
            left:   BorderSide(color: cc, width: 4),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (imgUrl != null)
              Container(
                width: 60, height: 60,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: kEvBorderL, width: 0.5),
                ),
                child: Image.network(imgUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          color: kEvDark,
                          child: const Icon(Icons.bolt, size: 22, color: kEvAccent),
                        )),
              )
            else
              Container(
                width: 60, height: 60,
                margin: const EdgeInsets.only(right: 12),
                color: kEvDark.withOpacity(0.08),
                child: const Icon(Icons.bolt_outlined, size: 22, color: kEvMuted),
              ),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Wrap(
                    spacing: 4, runSpacing: 2,
                    children: [
                      if (event.eventCategory != null)
                        EvCatBadge(category: event.eventCategory!),
                      if (event.eventType != null)
                        EvTypeBadge(type: event.eventType!),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Título
                  Text(event.title,
                      style: evMono(size: 12, weight: FontWeight.w800)),
                  const SizedBox(height: 4),

                  // Año + score inline
                  Row(
                    children: [
                      if (event.year != null)
                        Text('${event.year}',
                            style: evMono(size: 10, color: kEvMuted)),
                      if (event.scoreA != null && event.scoreB != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          color: kEvDark,
                          child: Text(
                            '${event.teamAName ?? '?'}  ${event.scoreA}–${event.scoreB}  ${event.teamBName ?? '?'}',
                            style: evMono(
                                color: Colors.white, size: 8,
                                weight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: kEvMuted),
          ],
        ),
      ),
    );
  }
}
