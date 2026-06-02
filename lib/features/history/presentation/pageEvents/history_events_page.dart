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
    final eventsAsync = ref.watch(filteredEventsProvider);
    final allAsync    = ref.watch(historyEventsProvider);
    final catFilter   = ref.watch(eventCategoryFilterProvider);

    final totalCount  = allAsync.whenOrNull(data: (l) => l.length) ?? 0;
    final playerCount = allAsync.whenOrNull(
          data: (l) => l.where((e) => e.eventCategory == 'player').length) ?? 0;
    final teamCount   = allAsync.whenOrNull(
          data: (l) => l.where((e) => e.eventCategory == 'team').length) ?? 0;

    return Scaffold(
      backgroundColor: kEvBg,
      body: Column(
        children: [
          _EventsHeader(onBack: onBack),
          _StatsStrip(total: totalCount, players: playerCount, teams: teamCount),
          _SearchBar(controller: searchCtrl),
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
                  padding: const EdgeInsets.only(bottom: 24),
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

// ── Header ────────────────────────────────────────────────────
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
          const Positioned(right: 0, top: 0, child: EvDotGrid(cols: 5, rows: 4)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            color: Color.fromRGBO(26, 26, 46, 0.45),
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
                            weight: FontWeight.w800, letterSpacing: 1.0)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
  const _StatsStrip({required this.total, required this.players, required this.teams});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: evNeoBox(shadowX: 4, shadowY: 4),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(icon: Icons.bolt_outlined,   iconBg: kEvAccent, value: '$total',   label: 'EVENTOS',    bordered: true),
            _StatCell(icon: Icons.person_outline,  iconBg: kEvPurple, value: '$players', label: 'JUGADORES',  bordered: true),
            _StatCell(icon: Icons.shield_outlined, iconBg: kEvBlue,   value: '$teams',   label: 'EQUIPOS',    bordered: false),
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
    required this.icon, required this.iconBg,
    required this.value, required this.label, required this.bordered,
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
                    style: evMono(size: 18, weight: FontWeight.w900, color: kEvAccent)),
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
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kEvBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(26, 26, 46, 0.3),
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
          ),
          const SizedBox(width: 8),
          _RandomEventButton(),
        ],
      ),
    );
  }
}

// ── Random event button ───────────────────────────────────────
class _RandomEventButton extends ConsumerWidget {
  const _RandomEventButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(historyEventsProvider);
    return GestureDetector(
      onTap: () {
        eventsAsync.whenData((events) {
          if (events.isEmpty) return;
          showDialog(
            context: context,
            barrierColor: kEvDark.withValues(alpha: 0.7),
            builder: (_) => _RandomEventModal(
              events: events,
              onSelect: (event) =>
                  ref.read(selectedEventProvider.notifier).select(event),
            ),
          );
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kEvDark,
          border: Border.all(color: kEvBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x885B4FD8),
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Icon(Icons.shuffle_rounded, size: 17, color: Colors.white),
      ),
    );
  }
}

// ── Random event modal ────────────────────────────────────────
class _RandomEventModal extends StatefulWidget {
  final List<HistoricalEvent> events;
  final void Function(HistoricalEvent) onSelect;
  const _RandomEventModal({required this.events, required this.onSelect});

  @override
  State<_RandomEventModal> createState() => _RandomEventModalState();
}

class _RandomEventModalState extends State<_RandomEventModal> {
  HistoricalEvent? _displayed;
  HistoricalEvent? _winner;
  bool _spinning = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _spin();
  }

  void _spin() {
    if (widget.events.isEmpty) return;
    final rng    = DateTime.now().millisecondsSinceEpoch;
    final picked = widget.events[rng % widget.events.length];
    setState(() {
      _winner   = picked;
      _spinning = true;
      _revealed = false;
      _displayed = null;
    });

    int i = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return false;
      setState(() => _displayed = widget.events[i % widget.events.length]);
      i++;
      return i < 35;
    }).then((_) {
      if (!mounted) return;
      setState(() {
        _displayed = _winner;
        _spinning  = false;
        _revealed  = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: kEvBg,
            border: Border.all(color: kEvBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: kEvDark.withValues(alpha: 0.6),
                offset: const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: kEvDark,
                child: Row(
                  children: [
                    const Icon(Icons.shuffle_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'MODO ALEATORIO',
                      style: evMono(
                          size: 11, weight: FontWeight.w900,
                          letterSpacing: 1.2, color: Colors.white),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 14, color: Colors.white54),
                    ),
                  ],
                ),
              ),

              // Ruleta
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Slot animado
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 60),
                      child: _displayed == null
                          ? Container(
                              key: const ValueKey('empty'),
                              width: double.infinity,
                              height: 80,
                              decoration: BoxDecoration(
                                color: kEvAccent.withValues(alpha: 0.08),
                                border: Border.all(color: kEvBorder, width: 1.5),
                              ),
                              child: const Icon(Icons.bolt_outlined,
                                  size: 36, color: kEvMuted),
                            )
                          : _EventSlot(
                              key: ValueKey(_displayed!.id),
                              event: _displayed!,
                              revealed: _revealed,
                            ),
                    ),

                    const SizedBox(height: 16),

                    if (_spinning)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 6, height: 6, color: kEvAccent),
                          const SizedBox(width: 6),
                          Text('BUSCANDO...',
                              style: evMono(
                                  size: 9, weight: FontWeight.w700,
                                  letterSpacing: 1.5, color: kEvAccent)),
                          const SizedBox(width: 6),
                          Container(width: 6, height: 6, color: kEvAccent),
                        ],
                      )
                    else if (_revealed && _winner != null) ...[
                      // VER EVENTO
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelect(_winner!);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: kEvAccent,
                            border: Border.all(color: kEvBorder, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: kEvDark.withValues(alpha: 0.4),
                                offset: const Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text('VER EVENTO →',
                                style: evMono(
                                    size: 11, weight: FontWeight.w900,
                                    letterSpacing: 1, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // OTRO
                      GestureDetector(
                        onTap: _spin,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: kEvBorder, width: 1.5),
                          ),
                          child: Center(
                            child: Text('OTRO →',
                                style: evMono(
                                    size: 10, weight: FontWeight.w700,
                                    letterSpacing: 0.8, color: kEvDark)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Event slot (ruleta item) ──────────────────────────────────
class _EventSlot extends StatelessWidget {
  final HistoricalEvent event;
  final bool revealed;
  const _EventSlot({super.key, required this.event, required this.revealed});

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(event.imagePath);
    final cc     = catColor(event.eventCategory);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: revealed ? const Color(0xFFF5F0EB) : kEvBg,
        border: Border(
          left: BorderSide(
            color: revealed ? kEvAccent : kEvBorder,
            width: revealed ? 4 : 1,
          ),
          top:    BorderSide(color: kEvBorder, width: 0.5),
          right:  BorderSide(color: kEvBorder, width: 0.5),
          bottom: BorderSide(color: kEvBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: kEvAccent.withValues(alpha: 0.1),
              border: Border.all(color: kEvBorder, width: 1),
            ),
            clipBehavior: Clip.hardEdge,
            child: imgUrl != null
                ? Image.network(imgUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.bolt_outlined, size: 24, color: kEvMuted))
                : const Icon(Icons.bolt_outlined, size: 24, color: kEvMuted),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title.toUpperCase(),
                  style: evMono(size: 12, weight: FontWeight.w900, letterSpacing: -0.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.year != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${event.year}',
                    style: evMono(size: 9, color: kEvAccent, weight: FontWeight.w700),
                  ),
                ],
                if (event.eventCategory != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: cc,
                    child: Text(
                      (kCatLabel[event.eventCategory] ?? event.eventCategory!).toUpperCase(),
                      style: evMono(size: 7, weight: FontWeight.w900, color: Colors.white),
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

// ── Category tabs ─────────────────────────────────────────────
class _CategoryTabs extends ConsumerWidget {
  final String active;
  const _CategoryTabs({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const cats   = ['',      'player',    'team'];
    const labels = ['TODOS', 'JUGADORES', 'EQUIPOS'];
    const icons  = [Icons.apps_rounded, Icons.person_outline, Icons.shield_outlined];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        border: Border.all(color: kEvBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(26, 26, 46, 0.35),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: List.generate(cats.length, (i) {
          final isActive = active == cats[i];
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(eventCategoryFilterProvider.notifier).set(cats[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? kEvAccent : Colors.transparent,
                  border: i < cats.length - 1
                      ? Border(right: BorderSide(color: kEvBorder, width: 1.5))
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icons[i], size: 13,
                        color: isActive ? Colors.white : kEvMuted),
                    const SizedBox(height: 2),
                    Text(labels[i],
                        style: evMono(
                            size: 8, weight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isActive ? Colors.white : kEvMuted)),
                  ],
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
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
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(26, 26, 46, 0.3),
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
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

// ── Event card ────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final HistoricalEvent event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cc     = catColor(event.eventCategory);
    final imgUrl = getHistoricalImageUrl(event.imagePath);
    final hasScore = event.scoreA != null && event.scoreB != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          color: kEvBg,
          border: Border.all(color: kEvBorder, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0xFF1A1A2E), offset: Offset(5, 5), blurRadius: 0),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top accent bar
            Container(
              height: 36,
              color: cc,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(width: 4, height: 18,
                      color: Colors.white.withValues(alpha: 0.45)),
                  const SizedBox(width: 8),
                  if (event.year != null)
                    Text('${event.year}',
                        style: evMono(
                            size: 18, weight: FontWeight.w900,
                            color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(width: 10),
                  if (event.eventType != null)
                    Expanded(
                      child: Text(
                        (kEventTypeLabel[event.eventType] ?? event.eventType!).toUpperCase(),
                        style: evMono(
                            size: 8, weight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 0.8),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  if (event.eventCategory != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5), width: 1),
                      ),
                      child: Text(
                        (kCatLabel[event.eventCategory] ?? event.eventCategory!).toUpperCase(),
                        style: evMono(size: 7, weight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            // Body
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thumbnail
                  Container(
                    width: 90,
                    constraints: const BoxConstraints(minHeight: 90),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E4DF),
                      border: Border(right: BorderSide(color: kEvBorder, width: 2)),
                    ),
                    child: imgUrl != null
                        ? Image.network(imgUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFE8E4DF),
                              child: const Icon(Icons.bolt, size: 32, color: kEvMuted),
                            ))
                        : const Icon(Icons.bolt_outlined, size: 32, color: kEvMuted),
                  ),

                  // Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title.toUpperCase(),
                            style: evMono(
                                size: 13, weight: FontWeight.w900, letterSpacing: -0.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          if (hasScore) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: kEvDark,
                                border: Border.all(color: cc, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: cc.withValues(alpha: 0.45),
                                    offset: const Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(event.teamAName ?? '?',
                                        style: evMono(
                                            size: 9, weight: FontWeight.w700,
                                            color: Colors.white),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('${event.scoreA}–${event.scoreB}',
                                        style: evMono(
                                            size: 13, weight: FontWeight.w900,
                                            color: cc)),
                                  ),
                                  Flexible(
                                    child: Text(event.teamBName ?? '?',
                                        style: evMono(
                                            size: 9, weight: FontWeight.w700,
                                            color: Colors.white),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          Row(
                            children: [
                              if (event.player?.name != null || event.team?.name != null)
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        event.eventCategory == 'player'
                                            ? Icons.person_outline
                                            : Icons.shield_outlined,
                                        size: 10, color: kEvMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          event.player?.name ?? event.team?.name ?? '',
                                          style: evMono(size: 9, color: kEvMuted),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const Spacer(),
                              Container(
                                width: 26, height: 26,
                                decoration: BoxDecoration(
                                  color: cc,
                                  border: Border.all(color: kEvBorder, width: 1.5),
                                ),
                                child: const Icon(Icons.arrow_forward,
                                    size: 12, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}