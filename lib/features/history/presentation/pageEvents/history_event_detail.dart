import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import 'history_events_shared.dart';
import 'event_tab_info.dart';
import 'event_tab_alineaciones.dart';
import 'event_tab_plantel.dart';
import 'event_tab_tabla.dart';
import 'event_tab_momentos.dart';
import 'event_tab_protagonistas.dart';

class HistoryEventDetail extends ConsumerStatefulWidget {
  final HistoricalEvent event;
  final VoidCallback onBack;

  const HistoryEventDetail({
    super.key,
    required this.event,
    required this.onBack,
  });

  @override
  ConsumerState<HistoryEventDetail> createState() => _HistoryEventDetailState();
}

class _HistoryEventDetailState extends ConsumerState<HistoryEventDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<(IconData, String)> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = _buildTabs(widget.event.eventCategory);
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  List<(IconData, String)> _buildTabs(String? category) {
    // Base siempre presente
    final base = <(IconData, String)>[
      (Icons.info_outline, 'INFO'),
    ];
    // Tabs específicas por categoría
    if (category == 'player') {
      base.addAll([
        (Icons.groups_outlined, 'DUELO'),
        (Icons.people_outline, 'PLANTEL'),
      ]);
    } else if (category == 'team') {
      base.addAll([
        (Icons.people_outline, 'PLANTEL'),
        (Icons.route_outlined, 'CAMPAÑA'),
      ]);
    }
    base.addAll([
      (Icons.timeline, 'MOMENTOS'),
      (Icons.stars_rounded, 'PROTAS'),
    ]);
    return base;
  }

  List<Widget> _buildTabViews(EventDetail detail) {
    final views = <Widget>[EventTabInfo(detail: detail)];
    if (widget.event.eventCategory == 'player') {
      views.addAll([
        EventTabAlineaciones(detail: detail),
        EventTabPlantel(detail: detail),
      ]);
    } else if (widget.event.eventCategory == 'team') {
      views.addAll([
        EventTabPlantel(detail: detail),
        EventTabTabla(detail: detail),
      ]);
    }
    // Siempre al final
    views.addAll([
      EventTabMomentos(detail: detail),
      EventTabProtagonistas(detail: detail),
    ]);
    return views;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(eventDetailProvider(widget.event.id));
    final accentColor = catColor(widget.event.eventCategory);

    return Scaffold(
      backgroundColor: kEvBg,
      // ── Tab bar abajo ─────────────────────────────────────
      bottomNavigationBar: _EventTabBar(
        controller: _tabController,
        tabs: _tabs,
        accentColor: accentColor,
      ),
      body: Column(
        children: [
          // ── Solo el app bar arriba ────────────────────────
          _EventAppBar(
            event: widget.event,
            accentColor: accentColor,
            onBack: widget.onBack,
          ),
          // ── Contenido ────────────────────────────────────
          Expanded(
            child: detailAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: accentColor, strokeWidth: 2),
                    const SizedBox(height: 14),
                    Text('Cargando evento...', style: evMono(size: 12, color: kEvMuted)),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 36, color: kEvRed),
                    const SizedBox(height: 12),
                    Text('Error: $e', style: evMono(size: 12, color: kEvRed)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => ref.refresh(eventDetailProvider(widget.event.id)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: evNeoBox(),
                        child: Text(
                          'REINTENTAR',
                          style: evMono(size: 11, weight: FontWeight.w700, color: kEvAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (detail) {
                final views = _buildTabViews(detail);
                if (views.length != _tabController.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final newTabs = _buildTabs(widget.event.eventCategory);
                    _tabController.dispose();
                    setState(() {
                      _tabs = newTabs;
                      _tabController = TabController(length: newTabs.length, vsync: this);
                      _tabController.addListener(() {
                        if (mounted) setState(() {});
                      });
                    });
                  });
                  return Center(
                    child: CircularProgressIndicator(color: accentColor, strokeWidth: 2),
                  );
                }
                return TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: views,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  APP BAR — solo título + back, sin tabs
// ══════════════════════════════════════════════════════════════

class _EventAppBar extends StatelessWidget {
  final HistoricalEvent event;
  final Color accentColor;
  final VoidCallback onBack;

  const _EventAppBar({
    required this.event,
    required this.accentColor,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        color: kEvBg,
        border: Border(
          bottom: BorderSide(color: kEvBorder, width: 1.5),
          top: BorderSide(color: accentColor, width: 3),
        ),
      ),
      padding: EdgeInsets.fromLTRB(14, topPad + 14, 14, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kEvBg,
                border: Border.all(color: kEvBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: kEvDark.withOpacity(0.4),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, size: 16, color: kEvDark),
            ),
          ),
          const SizedBox(width: 12),
          if (event.year != null)
            Container(
              width: 36,
              height: 36,
              color: accentColor,
              child: Center(
                child: Text(
                  '${event.year}',
                  style: evMono(size: 9, weight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title.toUpperCase(),
                  style: evMono(size: 12, weight: FontWeight.w800, letterSpacing: 0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.eventType != null)
                  Text(
                    kEventTypeLabel[event.eventType] ?? event.eventType!,
                    style: evMono(size: 9, color: kEvMuted),
                  ),
              ],
            ),
          ),
          if (event.eventCategory != null)
            EvCatBadge(category: event.eventCategory!),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TAB BAR — abajo, respeta safe area del home indicator
// ══════════════════════════════════════════════════════════════

class _EventTabBar extends StatelessWidget {
  final TabController controller;
  final List<(IconData, String)> tabs;
  final Color accentColor;

  const _EventTabBar({
    required this.controller,
    required this.tabs,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: kEvBg,
        border: Border(
          top: BorderSide(color: kEvBorder, width: 1.5),
          bottom: BorderSide(color: accentColor, width: 3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: controller,
            indicatorColor: accentColor,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: EdgeInsets.zero,
            // Con 5 tabs puede quedar apretado — usar isScrollable si hay más de 4
            isScrollable: false,
            tabAlignment: TabAlignment.fill,
            tabs: tabs.asMap().entries.map((e) {
              final isActive = controller.index == e.key;
              final (icon, label) = e.value;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: isActive ? accentColor : kEvMuted),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: evMono(
                        size: 8,
                        weight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isActive ? accentColor : kEvMuted,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: bottomPad),
        ],
      ),
    );
  }
}