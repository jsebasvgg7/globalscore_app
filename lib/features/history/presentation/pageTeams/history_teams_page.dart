import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/history_providers.dart';
import '../../domain/history_models.dart';
import '../../data/history_service.dart';
import 'history_teams_shared.dart';
import 'history_team_detail.dart';

// ══════════════════════════════════════════════════════════════
//  ROOT
// ══════════════════════════════════════════════════════════════

class HistoryTeamsPage extends ConsumerStatefulWidget {
  const HistoryTeamsPage({super.key});

  @override
  ConsumerState<HistoryTeamsPage> createState() => _HistoryTeamsPageState();
}

class _HistoryTeamsPageState extends ConsumerState<HistoryTeamsPage> {
  HistoricalTeam? _selected;

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return HistoryTeamDetail(
        team: _selected!,
        onBack: () => setState(() => _selected = null),
      );
    }
    return _TeamsListView(
      onSelect: (t) => setState(() => _selected = t),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LISTA
// ══════════════════════════════════════════════════════════════

class _TeamsListView extends ConsumerStatefulWidget {
  final void Function(HistoricalTeam) onSelect;
  const _TeamsListView({required this.onSelect});

  @override
  ConsumerState<_TeamsListView> createState() => _TeamsListViewState();
}

class _TeamsListViewState extends ConsumerState<_TeamsListView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync    = ref.watch(filteredTeamsProvider);
    final allTeamsAsync = ref.watch(historyTeamsProvider);

    final totalCount = allTeamsAsync.whenOrNull(data: (l) => l.length) ?? 0;
    final countriesCount = allTeamsAsync.whenOrNull(
          data: (l) =>
              l.map((t) => t.country).whereType<String>().toSet().length,
        ) ?? 0;
    final legendaryCount = allTeamsAsync.whenOrNull(
          data: (l) => l
              .where((t) =>
                  (t.legacyType ?? '').toLowerCase().contains('legend') ||
                  (t.legacyType ?? '').toLowerCase().contains('dominant'))
              .length,
        ) ?? 0;

    return Scaffold(
      backgroundColor: kTeamBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header editorial ────────────────────────────────
          _TeamsHeader(
            onBack: () =>
                ref.read(historySectionProvider.notifier).goBack(),
          ),

          // ── Stats strip ─────────────────────────────────────
          _StatsStrip(
            total: totalCount,
            legendary: legendaryCount,
            countries: countriesCount,
          ),

          // ── Search + random ──────────────────────────────────
          _SearchBar(
            controller: _searchCtrl,
            onRandomTap: () {
              allTeamsAsync.whenData((teams) {
                if (teams.isEmpty) return;
                showDialog(
                  context: context,
                  barrierColor: kTeamDark.withOpacity(0.70),
                  builder: (_) => _RandomTeamModal(
                    teams: teams,
                    onSelect: widget.onSelect,
                  ),
                );
              });
            },
          ),

          // ── Counter ──────────────────────────────────────────
          teamsAsync.whenOrNull(
            data: (teams) => _CounterRow(count: teams.length),
          ) ?? const SizedBox.shrink(),

          // ── Grid ─────────────────────────────────────────────
          Expanded(
            child: teamsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: kTeamAccent),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: teamMono(color: kTeamRed)),
              ),
              data: (teams) {
                if (teams.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 40, color: kTeamBorderL),
                        const SizedBox(height: 12),
                        Text('Sin resultados',
                            style: teamMono(size: 14, color: kTeamMuted)),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.76,
                  ),
                  itemCount: teams.length,
                  itemBuilder: (_, i) => _TeamCard(
                    team: teams[i],
                    onTap: () => widget.onSelect(teams[i]),
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

// ══════════════════════════════════════════════════════════════
//  HEADER
// ══════════════════════════════════════════════════════════════

class _TeamsHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _TeamsHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
     padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: kTeamBg,
        border: Border(bottom: BorderSide(color: kTeamBorder, width: 1.5)),
      ),
      child: Stack(
        children: [
          // Dot grid decorativo
          const Positioned(
            right: 0,
            top: 0,
            child: _DotGrid(cols: 5, rows: 4),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kTeamBg,
                        border: Border.all(color: kTeamBorder, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: kTeamDark.withOpacity(0.45),
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back,
                              size: 10, color: kTeamDark),
                          const SizedBox(width: 5),
                          Text(
                            'HISTÓRICO',
                            style: teamMono(
                                size: 8, weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    color: kTeamAccent,
                    child: Text(
                      'EQUIPOS',
                      style: teamMono(
                        size: 8,
                        color: Colors.white,
                        weight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Título grande partido en dos colores
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'EQUI',
                    style: teamMono(
                        size: 36,
                        weight: FontWeight.w900,
                        letterSpacing: -1.0),
                  ),
                  Text(
                    'POS',
                    style: teamMono(
                        size: 36,
                        weight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: kTeamAccent),
                  ),
                ],
              ),
              Text(
                'Equipos que definieron una era',
                style: teamMono(size: 11, color: kTeamMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STATS STRIP — igual layout que players
// ══════════════════════════════════════════════════════════════

class _StatsStrip extends StatelessWidget {
  final int total;
  final int legendary;
  final int countries;
  const _StatsStrip({
    required this.total,
    required this.legendary,
    required this.countries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: teamNeoBox(shadowX: 4, shadowY: 4),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(
              icon: Icons.shield_outlined,
              iconBg: kTeamAccent,
              value: '$total',
              label: 'EQUIPOS',
              bordered: true,
            ),
            _StatCell(
              icon: Icons.emoji_events_outlined,
              iconBg: kTeamGold,
              value: '$legendary',
              label: 'LEYENDAS',
              bordered: true,
            ),
            _StatCell(
              icon: Icons.public_outlined,
              iconBg: kTeamGreen,
              value: '$countries',
              label: 'PAÍSES',
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
              ? Border(
                  right: BorderSide(color: kTeamBorder, width: 1.5))
              : null,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                border: Border.all(color: kTeamBorder, width: 1),
              ),
              child:
                  Icon(icon, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: teamMono(
                        size: 18,
                        weight: FontWeight.w900,
                        color: kTeamAccent)),
                Text(label,
                    style: teamMono(
                        size: 7,
                        weight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: kTeamMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SEARCH BAR + botones filtro y random
// ══════════════════════════════════════════════════════════════

class _SearchBar extends ConsumerWidget {
  final TextEditingController controller;
  final VoidCallback onRandomTap;
  const _SearchBar(
      {required this.controller, required this.onRandomTap});

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
                border: Border.all(color: kTeamBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: kTeamDark.withOpacity(0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                style: teamMono(size: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar equipo...',
                  hintStyle: teamMono(size: 12, color: kTeamMuted),
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: kTeamMuted),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 13),
                          onPressed: () {
                            controller.clear();
                            ref
                                .read(teamSearchProvider.notifier)
                                .set('');
                          },
                        )
                      : null,
                ),
                onChanged: (v) =>
                    ref.read(teamSearchProvider.notifier).set(v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón random — igual estilo que players
          GestureDetector(
            onTap: onRandomTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kTeamDark,
                border:
                    Border.all(color: kTeamBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: kTeamAccent.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shuffle_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  COUNTER ROW
// ══════════════════════════════════════════════════════════════

class _CounterRow extends StatelessWidget {
  final int count;
  const _CounterRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: kTeamBorder, width: 1.5)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 12, color: kTeamAccent),
          const SizedBox(width: 8),
          Text(
            'EQUIPOS',
            style: teamMono(
                size: 9,
                weight: FontWeight.w700,
                letterSpacing: 1.2,
                color: kTeamMuted),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kTeamAccent,
              border: Border.all(color: kTeamBorder, width: 1),
            ),
            child: Text(
              '$count ENCONTRADOS',
              style: teamMono(
                  size: 8,
                  weight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TEAM CARD — grid 2 col, misma riqueza que PlayerCard
// ══════════════════════════════════════════════════════════════

class _TeamCard extends StatelessWidget {
  final HistoricalTeam team;
  final VoidCallback onTap;
  const _TeamCard({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = parseHexColor(team.primaryColor);
    final imgUrl = getHistoricalImageUrl(team.imagePath);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kTeamBg,
          border: Border.all(color: kTeamBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: kTeamDark.withOpacity(0.45),
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen / color block ──────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo con color primario del equipo
                  Container(
                    color: primaryColor.withOpacity(0.12),
                  ),
                  // Franja izquierda de color
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: Container(color: primaryColor),
                  ),
                  // Logo centrado
                  Center(
                    child: imgUrl != null
                        ? Image.network(
                            imgUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _TeamInitials(name: team.name, color: primaryColor),
                          )
                        : _TeamInitials(
                            name: team.name, color: primaryColor),
                  ),
                  // Badge de tipo (leyenda/dominante) esquina sup-der
                  if (_isLegendary(team.legacyType))
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        color: kTeamGold,
                        child: Text(
                          'TOP',
                          style: teamMono(
                              size: 7,
                              weight: FontWeight.w900,
                              color: Colors.black),
                        ),
                      ),
                    ),
                  // Número de índice esquina inf-izq
                  Positioned(
                    bottom: 5,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      color: kTeamDark.withOpacity(0.75),
                      child: Text(
                        team.era ?? '',
                        style: teamMono(
                            size: 7,
                            color: primaryColor,
                            weight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Menú dots
                  Positioned(
                    top: 6,
                    left: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      color: kTeamDark.withOpacity(0.65),
                      child: const Icon(Icons.more_horiz,
                          size: 13, color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: kTeamBorderL, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name.toUpperCase(),
                    style: teamMono(
                        size: 11, weight: FontWeight.w900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (team.country != null)
                    Text(
                      team.country!.toUpperCase(),
                      style: teamMono(
                          size: 9,
                          color: kTeamAccent,
                          weight: FontWeight.w700),
                    ),
                  const SizedBox(height: 5),
                  // Trofeos fila
                  if (team.titlesCount != null &&
                      team.titlesCount! > 0)
                    Row(
                      children: [
                        ...List.generate(
                          (team.titlesCount! > 5
                                  ? 5
                                  : team.titlesCount!)
                              .clamp(0, 5),
                          (_) => Padding(
                            padding:
                                const EdgeInsets.only(right: 2),
                            child: Icon(
                              Icons.emoji_events,
                              size: 10,
                              color: kTeamGold,
                            ),
                          ),
                        ),
                        if (team.titlesCount! > 5) ...[
                          const SizedBox(width: 2),
                          Text(
                            '+${team.titlesCount! - 5}',
                            style: teamMono(
                                size: 8,
                                color: kTeamGold,
                                weight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isLegendary(String? type) {
    if (type == null) return false;
    final t = type.toLowerCase();
    return t.contains('legend') || t.contains('dominant');
  }
}

// ── Fallback iniciales del equipo ─────────────────────────────
class _TeamInitials extends StatelessWidget {
  final String name;
  final Color color;
  const _TeamInitials({required this.name, required this.color});

  String get _initials {
    final words = name.split(' ');
    if (words.length == 1) {
      return name.substring(0, name.length.clamp(0, 3)).toUpperCase();
    }
    return words.take(2).map((w) => w[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _initials,
        style: teamMono(
          size: 28,
          weight: FontWeight.w900,
          color: color.withOpacity(0.45),
          letterSpacing: -1,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  MODAL ALEATORIO — misma mecánica que players
// ══════════════════════════════════════════════════════════════

class _RandomTeamModal extends StatefulWidget {
  final List<HistoricalTeam> teams;
  final void Function(HistoricalTeam) onSelect;
  const _RandomTeamModal(
      {required this.teams, required this.onSelect});

  @override
  State<_RandomTeamModal> createState() => _RandomTeamModalState();
}

class _RandomTeamModalState extends State<_RandomTeamModal> {
  HistoricalTeam? _displayed;
  HistoricalTeam? _winner;
  bool _spinning = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _spin();
  }

  void _spin() {
    if (widget.teams.isEmpty) return;
    final rng = DateTime.now().millisecondsSinceEpoch;
    final picked = widget.teams[rng % widget.teams.length];
    setState(() {
      _winner = picked;
      _spinning = true;
      _revealed = false;
      _displayed = null;
    });

    int i = 0;
    const totalSteps = 40;
    Future.doWhile(() async {
      final progress = i / totalSteps;
      final ms = (80 + (progress * progress * 220)).round();
      await Future.delayed(Duration(milliseconds: ms));
      if (!mounted) return false;
      setState(() =>
          _displayed = widget.teams[i % widget.teams.length]);
      i++;
      return i < totalSteps;
    }).then((_) {
      if (!mounted) return;
      setState(() {
        _displayed = _winner;
        _spinning = false;
        _revealed = true;
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
            color: kTeamBg,
            border: Border.all(color: kTeamBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: kTeamDark.withOpacity(0.6),
                offset: const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header modal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
                color: kTeamDark,
                child: Row(
                  children: [
                    const Icon(Icons.shuffle_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'MODO ALEATORIO',
                      style: teamMono(
                        size: 11,
                        weight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white54),
                    ),
                  ],
                ),
              ),

              // Ruleta
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 60),
                      child: _displayed == null
                          ? Container(
                              key: const ValueKey('empty'),
                              width: double.infinity,
                              height: 80,
                              decoration: BoxDecoration(
                                color: kTeamAccent.withOpacity(0.08),
                                border: Border.all(
                                    color: kTeamBorderL,
                                    width: 1.5),
                              ),
                              child: const Icon(
                                  Icons.shield_outlined,
                                  size: 36,
                                  color: kTeamBorderL),
                            )
                          : _TeamSlot(
                              key: ValueKey(_displayed!.id),
                              team: _displayed!,
                              revealed: _revealed,
                            ),
                    ),
                    const SizedBox(height: 16),

                    if (_spinning)
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Container(
                              width: 6,
                              height: 6,
                              color: kTeamAccent),
                          const SizedBox(width: 6),
                          Text(
                            'BUSCANDO...',
                            style: teamMono(
                              size: 9,
                              weight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: kTeamAccent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                              width: 6,
                              height: 6,
                              color: kTeamAccent),
                        ],
                      )
                    else if (_revealed && _winner != null) ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelect(_winner!);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          decoration: BoxDecoration(
                            color: kTeamAccent,
                            border: Border.all(
                                color: kTeamBorder, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    kTeamDark.withOpacity(0.4),
                                offset: const Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'VER EQUIPO →',
                              style: teamMono(
                                size: 11,
                                weight: FontWeight.w900,
                                letterSpacing: 1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _spin,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: kTeamBorder, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              'OTRO →',
                              style: teamMono(
                                size: 10,
                                weight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: kTeamDark,
                              ),
                            ),
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

// ── Slot de equipo en la ruleta ───────────────────────────────
class _TeamSlot extends StatelessWidget {
  final HistoricalTeam team;
  final bool revealed;
  const _TeamSlot(
      {super.key, required this.team, required this.revealed});

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(team.imagePath);
    final primaryColor = parseHexColor(team.primaryColor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: revealed ? const Color(0xFFEBE7E1) : kTeamBg,
        border: Border(
          left: BorderSide(
            color: revealed ? kTeamAccent : kTeamBorderL,
            width: revealed ? 4 : 1,
          ),
          top: BorderSide(color: kTeamBorderL, width: 0.5),
          right: BorderSide(color: kTeamBorderL, width: 0.5),
          bottom: BorderSide(color: kTeamBorderL, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              border: Border.all(color: kTeamBorderL, width: 1),
            ),
            clipBehavior: Clip.hardEdge,
            child: imgUrl != null
                ? Image.network(
                    imgUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _TeamInitials(
                        name: team.name, color: primaryColor),
                  )
                : _TeamInitials(
                    name: team.name, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name.toUpperCase(),
                  style: teamMono(
                      size: 12,
                      weight: FontWeight.w900,
                      letterSpacing: -0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (team.country != null)
                  Text(
                    team.country!,
                    style: teamMono(
                        size: 9,
                        color: kTeamAccent,
                        weight: FontWeight.w700),
                  ),
                if (team.era != null)
                  Text(
                    team.era!,
                    style: teamMono(
                        size: 8,
                        color: kTeamMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dot grid decorativo ───────────────────────────────────────
class _DotGrid extends StatelessWidget {
  final int cols;
  final int rows;
  const _DotGrid({required this.cols, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cols * 16.0,
      height: rows * 16.0,
      child:
          CustomPaint(painter: _DotPainter(cols: cols, rows: rows)),
    );
  }
}

class _DotPainter extends CustomPainter {
  final int cols;
  final int rows;
  _DotPainter({required this.cols, required this.rows});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kTeamBorder.withOpacity(0.18);
    const step = 16.0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(
            Offset(c * step + 8, r * step + 8), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}