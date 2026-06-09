import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/history_providers.dart';
import '../../domain/history_models.dart';
import '../../data/history_service.dart';

// ─── Paleta neobrutalista ─────────────────────────────────────────────────────
const _kBg      = Color(0xFFF0EDE8);  // crema base
const _kDark    = Color(0xFF1A1A2E);  // casi negro azulado
const _kAccent  = Color(0xFF5B4FD8);  // violeta
const _kGold    = Color(0xFFF59E0B);  // oro
const _kGreen   = Color(0xFF1D9E75);  // verde
const _kMuted   = Color(0xFF88887D);
const _kBorder  = Color(0xFF1A1A2E);  // borde negro duro (neobrutalista)
const _kBorderL = Color(0xFFC4BFB8);  // borde suave para divisores internos

// Sombra desplazada — signature del neobrutalismo
BoxDecoration _neoBox({
  Color bg = _kBg,
  Color border = _kBorder,
  double shadowX = 3,
  double shadowY = 3,
  Color? shadowColor,
}) =>
    BoxDecoration(
      color: bg,
      border: Border.all(color: border, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: shadowColor ?? _kDark.withOpacity(0.55),
          offset: Offset(shadowX, shadowY),
          blurRadius: 0,
        ),
      ],
    );

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
//  ROOT
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
          SliverToBoxAdapter(child: _HeroHeader()),

          SliverToBoxAdapter(
            child: statsAsync.when(
              data: (s) => _StatsRow(stats: s),
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          SliverToBoxAdapter(child: _FeaturedCarousel()),

          // Label EXPLORA POR SECCIONES
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Row(
                children: [
                  Container(width: 4, height: 14, color: _kAccent),
                  const SizedBox(width: 8),
                  Text(
                    'EXPLORA POR SECCIONES',
                    style: _mono(size: 10, weight: FontWeight.w700, letterSpacing: 1.6, color: _kMuted),
                  ),
                ],
              ),
            ),
          ),

          // Section cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildListDelegate([
                _SectionCard(
                  icon: Icons.emoji_events_outlined,
                  label: 'COMPETICIONES',
                  subtitle: 'Torneos y campeonatos históricos.',
                  section: 'competitions',
                  color: _kGold,
                ),
                _SectionCard(
                  icon: Icons.star_border_rounded,
                  label: 'EVENTOS',
                  subtitle: 'Momentos del fútbol mundial.',
                  section: 'events',
                  color: _kAccent,
                ),
                _SectionCard(
                  icon: Icons.person_outline_rounded,
                  label: 'LEYENDAS',
                  subtitle: 'Jugadores que cambiaron el juego.',
                  section: 'players',
                  color: _kGreen,
                ),
              ]),
            ),
          ),

          SliverToBoxAdapter(child: _FeaturedTeamsStrip()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HERO HEADER — retro editorial con dot grid decorativo
// ══════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1.5)),
      ),
      child: Stack(
        children: [
          // Dot grid decorativo (esquina superior derecha)
          Positioned(
            right: 0,
            top: 18,
            child: _DotGrid(cols: 6, rows: 4),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: _neoBox(bg: _kAccent, shadowX: 2, shadowY: 2),
                    child: Text(
                      'GLOBALSCORE',
                      style: _mono(color: Colors.white, size: 9, weight: FontWeight.w800, letterSpacing: 1.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('HISTÓRICO', style: _mono(size: 9, color: _kMuted, letterSpacing: 1.2)),
                ],
              ),
              const SizedBox(height: 8),

              // Título grande — una línea, fuente reducida
              Text(
                'BÓVEDA\nHISTÓRICA',
                style: _mono(size: 28, weight: FontWeight.w900, letterSpacing: -1.0),
              ),
              const SizedBox(height: 8),

              // Subtítulo con barra izquierda — una línea
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _kAccent,
                      border: Border.all(color: _kBorder, width: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Explora la historia que definió el fútbol.',
                    style: _mono(size: 11, color: _kMuted),
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

// Dot grid decorativo — no requiere assets
class _DotGrid extends StatelessWidget {
  final int cols;
  final int rows;
  const _DotGrid({required this.cols, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cols * 14.0,
      height: rows * 14.0,
      child: CustomPaint(painter: _DotPainter(cols: cols, rows: rows)),
    );
  }
}

class _DotPainter extends CustomPainter {
  final int cols;
  final int rows;
  _DotPainter({required this.cols, required this.rows});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _kBorder.withOpacity(0.18);
    final step = 14.0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(Offset(c * step + 7, r * step + 7), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
//  STATS ROW — sombra desplazada en cada celda
// ══════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final HistoryStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.bookmark_border_rounded, stats.players, 'LEYENDAS'),
      (Icons.emoji_events_outlined, stats.competitions, 'TORNEOS'),
      (Icons.shield_outlined, stats.teams, 'EQUIPOS'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      decoration: _neoBox(shadowX: 4, shadowY: 4),
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
                      : Border(right: BorderSide(color: _kBorder, width: 1.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _kAccent,
                        border: Border.all(color: _kBorder, width: 1),
                      ),
                      child: Icon(icon, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$count', style: _mono(size: 18, weight: FontWeight.w900, color: _kAccent)),
                          Text(label, style: _mono(size: 7, weight: FontWeight.w700, letterSpacing: 0.8, color: _kMuted)),
                        ],
                      ),
                    ),
                  ],
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
//  FEATURED CAROUSEL — borde negro + sombra desplazada
// ══════════════════════════════════════════════════════════════

class _FeaturedCarousel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends ConsumerState<_FeaturedCarousel> {
  final PageController _ctrl = PageController();
  int _current = 0;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(historyEventsProvider);

    return eventsAsync.when(
      loading: () => Container(
        height: 200,
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: _neoBox(bg: _kDark),
        child: const Center(child: CircularProgressIndicator(color: _kAccent)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (events) {
        final featured = events.take(10).toList();
        if (featured.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: SizedBox(
                height: 210,
                child: PageView.builder(
                  controller: _ctrl,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemCount: featured.length,
                  itemBuilder: (_, i) => _EventCarouselCard(
                    event: featured[i],
                    onTap: () {
                      ref.read(historySectionProvider.notifier).setSection('events');
                      ref.read(selectedEventProvider.notifier).select(featured[i]);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(featured.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i ? _kAccent : _kBorderL,
                    border: Border.all(color: _kBorder, width: _current == i ? 1 : 0.5),
                  ),
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
    final rawPath = event.bannerImagePath ?? event.imagePath;
    final imgUrl = getHistoricalImageUrl(rawPath);
    final year = event.year;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: _neoBox(bg: _kDark, shadowX: 4, shadowY: 4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imgUrl != null)
              Image.network(imgUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: _kDark),
                  loadingBuilder: (_, child, p) => p == null ? child : Container(color: _kDark))
            else
              Container(color: _kDark),

            // Gradiente oscuro abajo
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),

            // Contenido
            Positioned(
              left: 12, right: 52, bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (event.eventType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kAccent,
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Text(event.eventType!.toUpperCase(),
                          style: _mono(color: Colors.white, size: 8, weight: FontWeight.w700, letterSpacing: 1)),
                    ),
                  const SizedBox(height: 6),
                  if (year != null)
                    Text('$year', style: _mono(color: Colors.white70, size: 10)),
                  Text(event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _mono(color: Colors.white, size: 16, weight: FontWeight.w800)),
                ],
              ),
            ),

            // Botón flecha neobrutalista
            Positioned(
              right: 12, bottom: 12,
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _kAccent,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
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
//  SECTION CARDS — neobrutalista: borde negro + sombra desplazada
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
        decoration: _neoBox(shadowX: 3, shadowY: 3),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: _kBorder, width: 1),
              ),
              child: Icon(icon, size: 17, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(label, style: _mono(size: 9, weight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Expanded(
              child: Text(subtitle, style: _mono(size: 8, color: _kMuted), maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: _kBorder, width: 1),
                ),
                child: const Icon(Icons.arrow_forward, size: 11, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  EQUIPOS DESTACADOS — horizontal scroll, chips neobrutalistas
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
        final featured = teams.take(4).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 4, height: 14, color: _kAccent),
                      const SizedBox(width: 8),
                      Text('EQUIPOS DESTACADOS',
                          style: _mono(size: 10, weight: FontWeight.w700, letterSpacing: 1.2, color: _kMuted)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => ref.read(historySectionProvider.notifier).setSection('teams'),
                    child: Row(
                      children: [
                        Text('VER TODOS',
                            style: _mono(size: 9, weight: FontWeight.w700, color: _kAccent, letterSpacing: 0.8)),
                        const SizedBox(width: 6),
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: _kAccent,
                            border: Border.all(color: _kBorder, width: 1),
                          ),
                          child: const Icon(Icons.add, size: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 130,
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

  Color get _teamColor {
    if (team.primaryColor == null) return _kAccent;
    try {
      final hex = team.primaryColor!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) { return _kAccent; }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imgUrl = getHistoricalImageUrl(team.imagePath);

    return GestureDetector(
      onTap: () {
        ref.read(historySectionProvider.notifier).setSection('teams');
        ref.read(selectedTeamProvider.notifier).select(team);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: _neoBox(shadowX: 3, shadowY: 3),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 52, height: 52,
              child: imgUrl != null
                  ? Image.network(imgUrl, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.shield, size: 30, color: _teamColor))
                  : Icon(Icons.shield, size: 30, color: _teamColor),
            ),
            const SizedBox(height: 7),
            Text(
              team.name.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _mono(size: 8, weight: FontWeight.w800),
            ),
            if (team.era != null) ...[
              const SizedBox(height: 2),
              Text(team.era!, style: _mono(size: 7, color: _kMuted), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}