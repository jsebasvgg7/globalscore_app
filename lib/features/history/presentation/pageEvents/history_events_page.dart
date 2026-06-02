import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import '../widgets/history_app_bar.dart';

const _kAccent = Color(0xFF5B4FD8);
const _kBg = Color(0xFFF0EDE8);
const _kDark = Color(0xFF1A1A2E);
const _kMuted = Color(0xFF88887D);
const _kBorder = Color(0xFFC4BFB8);

TextStyle _mono({
  Color color = _kDark,
  double size = 12,
  FontWeight weight = FontWeight.normal,
  double letterSpacing = 0,
}) =>
    GoogleFonts.dmMono(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      decoration: TextDecoration.none,
    );

const _catColor = {
  'player': Color(0xFF8B5CF6),
  'team': Color(0xFF3B82F6),
};
const _catLabel = {
  'player': 'Jugador',
  'team': 'Equipo',
};
const _eventTypeColor = {
  'Championship': Color(0xFFF59E0B),
  'Historic Match': Color(0xFF3B82F6),
  'Legendary Performance': Color(0xFF8B5CF6),
  'Era Defining': Color(0xFFEF4444),
  'Record': Color(0xFF10B981),
};
const _eventTypeLabel = {
  'Championship': 'Campeonato',
  'Historic Match': 'Partido Histórico',
  'Legendary Performance': 'Actuación Legendaria',
  'Era Defining': 'Definió una Era',
  'Record': 'Récord',
};

// ══════════════════════════════════════════════════════════════
//  EVENTS PAGE
// ══════════════════════════════════════════════════════════════

class HistoryEventsPage extends ConsumerStatefulWidget {
  const HistoryEventsPage({super.key});

  @override
  ConsumerState<HistoryEventsPage> createState() => _HistoryEventsPageState();
}

class _HistoryEventsPageState extends ConsumerState<HistoryEventsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedEventProvider);
    if (selected != null) return _EventDetailView(event: selected);
    return _EventListView(searchCtrl: _searchCtrl);
  }
}

// ══════════════════════════════════════════════════════════════
//  LIST VIEW
// ══════════════════════════════════════════════════════════════

class _EventListView extends ConsumerWidget {
  final TextEditingController searchCtrl;
  const _EventListView({required this.searchCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(filteredEventsProvider);
    final catFilter = ref.watch(eventCategoryFilterProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          HistoryAppBar(
            title: 'EVENTOS',
            subtitle: 'Momentos históricos del fútbol',
            icon: Icons.star_border_rounded,
            onBack: () => ref.read(historySectionProvider.notifier).goBack(),
          ),

          // Search
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: _kBorder),
                color: Colors.white,
              ),
              child: TextField(
                controller: searchCtrl,
                style: _mono(size: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar evento…',
                  hintStyle: _mono(size: 12, color: _kMuted),
                  prefixIcon: const Icon(Icons.search, size: 16, color: _kMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            searchCtrl.clear();
                            ref.read(eventSearchProvider.notifier).set('');
                          },
                        )
                      : null,
                ),
                onChanged: (v) =>ref.read(eventSearchProvider.notifier).set(v),
              ),
            ),
          ),

          // Category filter
          _CategoryFilter(active: catFilter),

          // List
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _kAccent)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (events) {
                if (events.isEmpty) {
                  return Center(child: Text('Sin resultados', style: _mono(color: _kMuted)));
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (_, i) => _EventCard(
                    event: events[i],
                    onTap: () => ref.read(selectedEventProvider.notifier).select(events[i]),
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

class _CategoryFilter extends ConsumerWidget {
  final String active;
  const _CategoryFilter({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ['', 'player', 'team'];
    final labels = ['TODOS', 'JUGADORES', 'EQUIPOS'];

    return Container(
      height: 36,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: List.generate(cats.length, (i) {
          final isActive = active == cats[i];
          return Expanded(
            child: GestureDetector(
              onTap: () =>ref.read(eventCategoryFilterProvider.notifier).set(cats[i]),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? _kAccent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: _mono(
                    size: 9,
                    weight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isActive ? _kAccent : _kMuted,
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

class _EventCard extends StatelessWidget {
  final HistoricalEvent event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor[event.eventCategory] ?? _kAccent;
    final typeColor = _eventTypeColor[event.eventType] ?? _kMuted;
    final imgUrl = getHistoricalImageUrl(event.imagePath);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: const BorderSide(color: _kBorder, width: 0.5),
            left: BorderSide(color: catColor, width: 3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (imgUrl != null)
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(right: 12),
                child: Image.network(imgUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (event.eventCategory != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          color: catColor,
                          child: Text(
                            (_catLabel[event.eventCategory!] ?? event.eventCategory!).toUpperCase(),
                            style: _mono(color: Colors.white, size: 7, weight: FontWeight.w700, letterSpacing: 0.8),
                          ),
                        ),
                      const SizedBox(width: 6),
                      if (event.eventType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          color: typeColor.withOpacity(0.15),
                          child: Text(
                            _eventTypeLabel[event.eventType!] ?? event.eventType!,
                            style: _mono(size: 7, color: typeColor, weight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(event.title, style: _mono(size: 13, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (event.year != null) ...[
                        Text('${event.year}', style: _mono(size: 10, color: _kMuted)),
                        const SizedBox(width: 6),
                      ],
                      // Score
                      if (event.scoreA != null && event.scoreB != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          color: _kDark,
                          child: Text(
                            '${event.teamAName ?? '?'}  ${event.scoreA} – ${event.scoreB}  ${event.teamBName ?? '?'}',
                            style: _mono(color: Colors.white, size: 8, weight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: _kMuted),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DETAIL VIEW
// ══════════════════════════════════════════════════════════════

class _EventDetailView extends ConsumerWidget {
  final HistoricalEvent event;
  const _EventDetailView({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(eventDetailProvider(event.id));
    final catColor = _catColor[event.eventCategory] ?? _kAccent;
    final imgUrl = getHistoricalImageUrl(event.bannerImagePath ?? event.imagePath);

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          HistoryAppBar(
            title: event.title.toUpperCase(),
            subtitle: event.year != null ? '${event.year}' : '',
            icon: Icons.star_border_rounded,
            onBack: () =>ref.read(selectedEventProvider.notifier).select(null),
          ),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Banner image
                if (imgUrl != null)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 180,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(imgUrl, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, _kBg],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Badges + title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          children: [
                            if (event.eventCategory != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                color: catColor,
                                child: Text(
                                  _catLabel[event.eventCategory!]?.toUpperCase() ?? event.eventCategory!,
                                  style: _mono(color: Colors.white, size: 8, weight: FontWeight.w700, letterSpacing: 1),
                                ),
                              ),
                            if (event.eventType != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                color: (_eventTypeColor[event.eventType!] ?? _kMuted).withOpacity(0.15),
                                child: Text(
                                  _eventTypeLabel[event.eventType!] ?? event.eventType!,
                                  style: _mono(size: 8, color: _eventTypeColor[event.eventType!] ?? _kMuted, weight: FontWeight.w700),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(event.title, style: _mono(size: 20, weight: FontWeight.w800)),
                        if (event.year != null) ...[
                          const SizedBox(height: 4),
                          Text('${event.year}', style: _mono(size: 12, color: _kMuted)),
                        ],

                        // Score display
                        if (event.scoreA != null && event.scoreB != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: _kDark,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event.teamAName ?? '?',
                                        textAlign: TextAlign.end,
                                        style: _mono(color: Colors.white, size: 13, weight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${event.scoreA} – ${event.scoreB}',
                                      style: _mono(color: Colors.white, size: 22, weight: FontWeight.w900),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        event.teamBName ?? '?',
                                        style: _mono(color: Colors.white, size: 13, weight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Description
                        if (event.description != null) ...[
                          const SizedBox(height: 16),
                          Text(event.description!, style: _mono(size: 13, color: _kDark)),
                        ],

                        // Context
                        if (event.contextText != null) ...[
                          const SizedBox(height: 16),
                          Text('CONTEXTO', style: _mono(size: 9, weight: FontWeight.w700, letterSpacing: 1.2, color: _kMuted)),
                          const SizedBox(height: 6),
                          Text(event.contextText!, style: _mono(size: 12, color: _kMuted)),
                        ],

                        // Impact
                        if (event.impactText != null) ...[
                          const SizedBox(height: 16),
                          Text('IMPACTO', style: _mono(size: 9, weight: FontWeight.w700, letterSpacing: 1.2, color: _kMuted)),
                          const SizedBox(height: 6),
                          Text(event.impactText!, style: _mono(size: 12, color: _kMuted)),
                        ],
                      ],
                    ),
                  ),
                ),

                // Lineups
                detailAsync.when(
                  loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  data: (detail) => SliverToBoxAdapter(
                    child: _LineupsSection(detail: detail),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineupsSection extends StatelessWidget {
  final EventDetail detail;
  const _LineupsSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    final hasLineup = detail.lineupA.isNotEmpty || detail.lineupB.isNotEmpty;
    if (!hasLineup) return const SizedBox.shrink();

    final teamAName = detail.lineupA.isNotEmpty ? detail.lineupA.first.teamName : 'Equipo A';
    final teamBName = detail.lineupB.isNotEmpty ? detail.lineupB.first.teamName : 'Equipo B';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFE8E4DE),
          child: Text('ALINEACIONES', style: _mono(size: 9, weight: FontWeight.w700, letterSpacing: 1.4, color: _kMuted)),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _LineupColumn(teamName: teamAName, players: detail.lineupA)),
            Container(width: 0.5, color: _kBorder),
            Expanded(child: _LineupColumn(teamName: teamBName, players: detail.lineupB)),
          ],
        ),
      ],
    );
  }
}

class _LineupColumn extends StatelessWidget {
  final String teamName;
  final List<EventLineup> players;
  const _LineupColumn({required this.teamName, required this.players});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: _kDark,
          child: Text(teamName, style: _mono(color: Colors.white, size: 9, weight: FontWeight.w700), overflow: TextOverflow.ellipsis),
        ),
        ...players.map((p) => Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  if (p.shirtNumber != null)
                    Container(
                      width: 20,
                      height: 20,
                      color: p.isProtagonist ? _kAccent : _kBorder,
                      alignment: Alignment.center,
                      child: Text(
                        '${p.shirtNumber}',
                        style: _mono(
                          size: 9,
                          weight: FontWeight.w700,
                          color: p.isProtagonist ? Colors.white : _kDark,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p.playerName,
                      style: _mono(
                        size: 10,
                        weight: p.isProtagonist ? FontWeight.w700 : FontWeight.normal,
                        color: p.isProtagonist ? _kAccent : _kDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
