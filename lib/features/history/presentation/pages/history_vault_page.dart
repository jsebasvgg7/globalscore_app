import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/history_providers.dart';
import '../data/history_service.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
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

// ══════════════════════════════════════════════════════════════
//  HISTORY VAULT PAGE (landing)
// ══════════════════════════════════════════════════════════════

class HistoryVaultPage extends ConsumerWidget {
  const HistoryVaultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(historyStatsProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero header ──
          SliverToBoxAdapter(child: _HeroHeader()),

          // ── Stats row ──
          SliverToBoxAdapter(
            child: statsAsync.when(
              data: (s) => _StatsRow(stats: s),
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // ── Featured carousel (events as "momento histórico") ──
          SliverToBoxAdapter(child: _FeaturedCarousel()),

          // ── Section label ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Container(width: 3, height: 14, color: _kAccent),
                  const SizedBox(width: 8),
                  Text(
                    'EXPLORA POR SECCIONES',
                    style: _mono(
                      size: 10,
                      weight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 4 section cards (2×2 grid) ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildListDelegate([
                _SectionCard(
                  icon: Icons.emoji_events_outlined,
                  label: 'COMPETICIONES',
                  subtitle: 'Torneos y campeonatos que hicieron historia.',
                  section: 'competitions',
                  color: const Color(0xFFF59E0B),
                ),
                _SectionCard(
                  icon: Icons.star_border_rounded,
                  label: 'EVENTOS',
                  subtitle: 'Momentos inolvidables del fútbol mundial.',
                  section: 'events',
                  color: const Color(0xFF8B5CF6),
                ),
                _SectionCard(
                  icon: Icons.shield_outlined,
                  label: 'EQUIPOS',
                  subtitle: 'Clubes y selecciones legendarias.',
                  section: 'teams',
                  color: _kAccent,
                ),
                // _SectionCard(
                //   icon: Icons.person_outline_rounded,
                //   label: 'LEYENDAS',
                //   subtitle: 'Los jugadores que cambiaron el juego.',
                //   section: 'players',
                //   color: const Color(0xFF1D9E75),
                // ),
              ]),
            ),
          ),

          // ── Random spinner ──
          SliverToBoxAdapter(child: _RandomSpinner()),

          // ── Featured teams strip ──
          SliverToBoxAdapter(child: _FeaturedTeamsStrip()),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HERO HEADER
// ══════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: _kAccent,
                child: Text(
                  'GLOBALSCORE',
                  style: _mono(color: Colors.white, size: 9, weight: FontWeight.w800, letterSpacing: 1.2),
                ),
              ),
              const SizedBox(width: 8),
              Text('HISTÓRICO', style: _mono(size: 9, color: _kMuted, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),

          // Big title
          Text(
            'BÓVEDA\nHISTÓRICA',
            style: _mono(size: 36, weight: FontWeight.w900, letterSpacing: -1),
          ),
          const SizedBox(height: 12),

          // Subtitle with left bar
          Row(
            children: [
              Container(width: 3, height: 36, color: _kAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Explora la historia que\ndefinió el fútbol.',
                  style: _mono(size: 13, color: _kMuted, letterSpacing: 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STATS ROW
// ══════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final HistoryStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.person_outline, stats.players, 'LEYENDAS'),
      (Icons.emoji_events_outlined, stats.competitions, 'TORNEOS'),
      (Icons.shield_outlined, stats.teams, 'EQUIPOS'),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            final (icon, count, label) = e.value;
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(right: BorderSide(color: _kBorder)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        color: _kAccent,
                        child: Icon(icon, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$count',
                              style: _mono(size: 18, weight: FontWeight.w900, color: _kAccent),
                            ),
                            Text(
                              label,
                              style: _mono(size: 8, weight: FontWeight.w700, letterSpacing: 1, color: _kMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FEATURED CAROUSEL (events)
// ══════════════════════════════════════════════════════════════

class _FeaturedCarousel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends ConsumerState<_FeaturedCarousel> {
  final PageController _ctrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(historyEventsProvider);

    return eventsAsync.when(
      loading: () => Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: _kBorder,
        child: const Center(child: CircularProgressIndicator(color: _kAccent)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (events) {
        final featured = events.take(4).toList();
        if (featured.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: featured.length,
                itemBuilder: (_, i) => _EventCarouselCard(
                  event: featured[i],
                  onTap: () {
                    ref.read(historySectionProvider.notifier).setSection('events');
                    ref.read(selectedEventProvider.notifier).state = featured[i];
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(featured.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 16 : 6,
                  height: 6,
                  color: _current == i ? _kAccent : _kBorder,
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _EventCarouselCard extends StatelessWidget {
  final HistoricalEvent event;
  final VoidCallback? onTap;
  const _EventCarouselCard({required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(event.imagePath ?? event.bannerImagePath);
    final year = event.year;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _kDark,
          border: Border.all(color: _kBorder),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (imgUrl != null)
              Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: _kDark),
              ),

            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),

            // Content
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.eventType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      color: _kAccent,
                      child: Text(
                        event.eventType!.toUpperCase(),
                        style: _mono(color: Colors.white, size: 8, weight: FontWeight.w700, letterSpacing: 1),
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (year != null)
                    Text('$year', style: _mono(color: Colors.white70, size: 10)),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _mono(color: Colors.white, size: 18, weight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            // Arrow
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                width: 32,
                height: 32,
                color: _kAccent,
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SECTION CARDS
// ══════════════════════════════════════════════════════════════

class _SectionCard extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final String section;
  final Color color;

  const _SectionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.section,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(historySectionProvider.notifier).setSection(section),
      child: Container(
        decoration: BoxDecoration(
          color: _kBg,
          border: Border.all(color: _kBorder),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              color: color,
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(label, style: _mono(size: 10, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: _mono(size: 9, color: _kMuted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 24,
                height: 24,
                color: color,
                child: const Icon(Icons.arrow_forward, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  RANDOM SPINNER
// ══════════════════════════════════════════════════════════════

class _RandomSpinner extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RandomSpinner> createState() => _RandomSpinnerState();
}

class _RandomSpinnerState extends ConsumerState<_RandomSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rot;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _rot = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    final service = ref.read(historyServiceProvider);
    ref.read(spinnerProvider.notifier).spin();
    _ctrl.repeat();

    // Pick random from all items
    final results = await Future.wait([
      service.fetchPlayers(),
      service.fetchTeams(),
      service.fetchEvents(),
    ]);

    final players = results[0] as List<HistoricalPlayer>;
    final teams = results[1] as List<HistoricalTeam>;
    final events = results[2] as List<HistoricalEvent>;

    final all = <SpinnerResult>[
      ...players.map((p) => SpinnerResult(
            type: 'player',
            id: p.id,
            name: p.name,
            imagePath: p.imagePath,
          )),
      ...teams.map((t) => SpinnerResult(
            type: 'team',
            id: t.id,
            name: t.name,
            imagePath: t.imagePath,
          )),
      ...events.map((e) => SpinnerResult(
            type: 'event',
            id: e.id,
            name: e.title,
            imagePath: e.imagePath,
          )),
    ];

    if (all.isEmpty) {
      _ctrl.stop();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 700));
    _ctrl.stop();
    await _ctrl.animateTo(1.0);

    final picked = all[Random().nextInt(all.length)];
    ref.read(spinnerProvider.notifier).land(picked);
  }

  @override
  Widget build(BuildContext context) {
    final spinner = ref.watch(spinnerProvider);
    final result = spinner.result;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        color: _kBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 14, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text(
                'DESCUBRIMIENTO ALEATORIO',
                style: _mono(size: 9, weight: FontWeight.w700, letterSpacing: 1.2, color: _kMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Spin button
              GestureDetector(
                onTap: spinner.isSpinning ? null : _spin,
                child: Container(
                  width: 52,
                  height: 52,
                  color: _kAccent,
                  child: RotationTransition(
                    turns: _rot,
                    child: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Result
              Expanded(
                child: result != null
                    ? _SpinnerResult(result: result)
                    : Text(
                        spinner.isSpinning
                            ? 'Buscando…'
                            : 'Pulsa para descubrir un momento histórico aleatorio.',
                        style: _mono(size: 12, color: _kMuted),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpinnerResult extends ConsumerWidget {
  final SpinnerResult result;
  const _SpinnerResult({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imgUrl = getHistoricalImageUrl(result.imagePath);
    final typeLabel = {
      'player': 'LEYENDA',
      'team': 'EQUIPO',
      'event': 'EVENTO',
      'competition': 'TORNEO',
    }[result.type] ?? result.type.toUpperCase();

    return GestureDetector(
      onTap: () {
        // Navigate to the relevant section and pre-select
        ref.read(historySectionProvider.notifier).setSection(
              result.type == 'player'
                  ? 'players'
                  : result.type == 'team'
                      ? 'teams'
                      : result.type == 'competition'
                          ? 'competitions'
                          : 'events',
            );
      },
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            color: _kBorder,
            child: imgUrl != null
                ? Image.network(imgUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.history, size: 22))
                : const Icon(Icons.history, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  color: _kAccent,
                  child: Text(typeLabel, style: _mono(color: Colors.white, size: 7, weight: FontWeight.w800, letterSpacing: 1)),
                ),
                const SizedBox(height: 4),
                Text(result.name, style: _mono(size: 13, weight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: _kMuted),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FEATURED TEAMS STRIP
// ══════════════════════════════════════════════════════════════

class _FeaturedTeamsStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(historyTeamsProvider);

    return teamsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (teams) {
        if (teams.isEmpty) return const SizedBox.shrink();
        final featured = teams.take(6).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 3, height: 14, color: _kAccent),
                      const SizedBox(width: 8),
                      Text(
                        'EQUIPOS DESTACADOS',
                        style: _mono(size: 10, weight: FontWeight.w700, letterSpacing: 1.2, color: _kMuted),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => ref.read(historySectionProvider.notifier).setSection('teams'),
                    child: Row(
                      children: [
                        Text('VER TODOS', style: _mono(size: 9, weight: FontWeight.w700, color: _kAccent, letterSpacing: 0.8)),
                        const SizedBox(width: 6),
                        Container(
                          width: 20,
                          height: 20,
                          color: _kAccent,
                          child: const Icon(Icons.add, size: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: featured.length,
                itemBuilder: (_, i) => _TeamChip(team: featured[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TeamChip extends ConsumerWidget {
  final HistoricalTeam team;
  const _TeamChip({required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imgUrl = getHistoricalImageUrl(team.imagePath);

    return GestureDetector(
      onTap: () {
        ref.read(historySectionProvider.notifier).setSection('teams');
        ref.read(selectedTeamProvider.notifier).state = team;
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(color: _kBorder),
          color: _kBg,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: imgUrl != null
                  ? Image.network(imgUrl, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 28, color: _kMuted))
                  : const Icon(Icons.shield, size: 28, color: _kMuted),
            ),
            const SizedBox(height: 6),
            Text(
              team.name.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _mono(size: 8, weight: FontWeight.w800),
            ),
            if (team.era != null)
              Text(team.era!, style: _mono(size: 7, color: _kMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
