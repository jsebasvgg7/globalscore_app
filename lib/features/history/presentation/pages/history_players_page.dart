import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
// history_app_bar kept for detail view only
import '../widgets/history_app_bar.dart';
import '../../../../shared/layout/scaffold_with_nav_bar.dart'
    show hideTopBarProvider;

// ── Providers de filtro (Riverpod 3) ─────────────────────────
// Filtra por legacy_type (p.ej. 'Goal Scorer', 'Leader'…)
final playerLegacyFilterProvider =
    NotifierProvider<_StringNotifier, String>(_StringNotifier.new);

// Filtra por significance_level exacto (0 = sin filtro)
final playerSigFilterProvider =
    NotifierProvider<_IntNotifier, int>(_IntNotifier.new);

class _StringNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

class _IntNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int v) => state = v;
}


// ── Paleta (idéntica a vault_page) ────────────────────────────
const _kBg      = Color(0xFFF0EDE8);
const _kDark    = Color(0xFF1A1A2E);
const _kAccent  = Color(0xFF5B4FD8);
const _kGold    = Color(0xFFF59E0B);
const _kGreen   = Color(0xFF1D9E75);
const _kMuted   = Color(0xFF88887D);
const _kBorder  = Color(0xFF1A1A2E);
const _kBorderL = Color(0xFFC4BFB8);
const _kCard    = Color(0xFFEBE7E1);

// Sombra desplazada — neobrutalista
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

// ── Helpers ───────────────────────────────────────────────────
const _positionLabel = {
  'Forward': 'Delantero',
  'Midfielder': 'Mediocampista',
  'Play-maker': 'Mediocampista',
  'All-rounder': 'Todocampista',
  'Defender': 'Defensor',
  'Goalkeeper': 'Portero',
};

const _legacyLabel = {
  'Goal Scorer': 'Goleador',
  'Tactician': 'Táctico',
  'Innovator': 'Genio',
  'Leader': 'Líder',
  'Goalkeeper': 'Portero',
  'Technician': 'Técnico',
};

const _titleCatLabel = {
  'club': 'Club',
  'national': 'Selección',
  'individual': 'Individual',
};

const _titleCatColor = {
  'club': _kAccent,
  'national': _kGreen,
  'individual': _kGold,
};

const _sigLabel = ['', 'Activo', 'Notable', 'Icónico', 'Leyenda', 'GOAT'];

// ══════════════════════════════════════════════════════════════
//  PLAYERS PAGE — root
// ══════════════════════════════════════════════════════════════

class HistoryPlayersPage extends ConsumerStatefulWidget {
  const HistoryPlayersPage({super.key});

  @override
  ConsumerState<HistoryPlayersPage> createState() => _HistoryPlayersPageState();
}

class _HistoryPlayersPageState extends ConsumerState<HistoryPlayersPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hideTopBarProvider.notifier).hide();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleBack() {
    ref.read(hideTopBarProvider.notifier).show();
    ref.read(historySectionProvider.notifier).goBack();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedPlayerProvider);
    if (selected != null) return _PlayerDetailView(player: selected, onBack: _handleBack);
    return _PlayerListView(searchCtrl: _searchCtrl, onBack: _handleBack);
  }
}

// ══════════════════════════════════════════════════════════════
//  LIST VIEW — estilo neobrutalista (imagen 2)
// ══════════════════════════════════════════════════════════════

class _PlayerListView extends ConsumerWidget {
  final TextEditingController searchCtrl;
  final VoidCallback onBack;
  const _PlayerListView({required this.searchCtrl, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(filteredPlayersProvider);
    final allAsync    = ref.watch(historyPlayersProvider);
    final legacyFilter = ref.watch(playerLegacyFilterProvider);
    final sigFilter    = ref.watch(playerSigFilterProvider);

    final totalCount = allAsync.whenOrNull(data: (l) => l.length) ?? 0;
    final goatCount  = allAsync.whenOrNull(
          data: (l) => l.where((p) => (p.significanceLevel ?? 0) == 5).length,
        ) ?? 0;
    final countriesCount = allAsync.whenOrNull(
          data: (l) => l.map((p) => p.country).whereType<String>().toSet().length,
        ) ?? 0;

    // Aplicar filtros extra encima del provider base
    final filteredAsync = playersAsync.whenData((players) {
      var list = players;
      if (legacyFilter.isNotEmpty) {
        list = list.where((p) => p.legacyType == legacyFilter).toList();
      }
      if (sigFilter > 0) {
        list = list.where((p) => (p.significanceLevel ?? 0) == sigFilter).toList();
      }
      return list;
    });

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SafeArea para cubrir la status bar (ya no está el top bar)
          SizedBox(height: MediaQuery.of(context).padding.top),

          // ── Header neobrutalista ─────────────────────────────
          _PlayersHeader(onBack: onBack),

          // ── Stats strip ──────────────────────────────────────
          _StatsStrip(
            total: totalCount,
            goats: goatCount,
            countries: countriesCount,
          ),

          // ── Search + Filtros ─────────────────────────────────
          _SearchBar(controller: searchCtrl),

          // ── Contador ─────────────────────────────────────────
          filteredAsync.whenOrNull(
            data: (players) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _kBorder, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Container(width: 3, height: 12, color: _kAccent),
                  const SizedBox(width: 8),
                  Text(
                    'JUGADORES',
                    style: _mono(
                        size: 9,
                        weight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: _kMuted),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kAccent,
                      border: Border.all(color: _kBorder, width: 1),
                    ),
                    child: Text(
                      '${players.length} ENCONTRADOS',
                      style: _mono(
                          size: 8,
                          weight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ) ?? const SizedBox.shrink(),

          // ── Grid 2x2 ─────────────────────────────────────────
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _kAccent)),
              error: (e, _) => Center(
                  child: Text('Error: $e', style: _mono(color: _kMuted))),
              data: (players) {
                if (players.isEmpty) {
                  return Center(
                    child: Text('Sin resultados',
                        style: _mono(color: _kMuted)),
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
                    childAspectRatio: 0.72,
                  ),
                  itemCount: players.length,
                  itemBuilder: (_, i) => _PlayerCard(
                    player: players[i],
                    onTap: () => ref
                        .read(selectedPlayerProvider.notifier)
                        .select(players[i]),
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
//  HEADER neobrutalista — breadcrumb + título grande + back sutil
// ══════════════════════════════════════════════════════════════

class _PlayersHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _PlayersHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1.5)),
      ),
      child: Stack(
        children: [
          // Dot grid decorativo — esquina superior derecha
          Positioned(
            right: 0,
            top: 0,
            child: _DotGrid(cols: 5, rows: 4),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb: HISTÓRICO > JUGADORES
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kAccent,
                      border: Border.all(color: _kBorder, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: _kDark.withOpacity(0.45),
                          offset: const Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'HISTÓRICO',
                      style: _mono(
                          color: Colors.white,
                          size: 8,
                          weight: FontWeight.w800,
                          letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('›',
                      style: _mono(
                          size: 12,
                          weight: FontWeight.w700,
                          color: _kMuted)),
                  const SizedBox(width: 6),
                  Text(
                    'JUGADORES',
                    style: _mono(
                        size: 9,
                        weight: FontWeight.w600,
                        color: _kMuted,
                        letterSpacing: 1.0),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Título + botón back en la misma línea
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Barra izquierda acento
                  Container(
                    width: 5,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _kAccent,
                      border: Border.all(color: _kBorder, width: 1),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Bloque de texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JUGADORES',
                          style: _mono(
                              size: 28,
                              weight: FontWeight.w900,
                              letterSpacing: -1.0),
                        ),
                        Text(
                          'Explora las leyendas del fútbol.',
                          style: _mono(size: 11, color: _kMuted),
                        ),
                      ],
                    ),
                  ),

                  // Botón back — sutil, sin relleno
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border:
                            Border.all(color: _kBorder.withOpacity(0.35), width: 1),
                      ),
                      child: Icon(Icons.arrow_back,
                          size: 15,
                          color: _kDark.withOpacity(0.45)),
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

// Dot grid decorativo (reutilizado del vault)
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
    const step = 14.0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(
            Offset(c * step + 7, r * step + 7), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Stats strip ───────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final int total;
  final int goats;
  final int countries;
  const _StatsStrip({
    required this.total,
    required this.goats,
    required this.countries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: _neoBox(shadowX: 4, shadowY: 4),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(
              icon: Icons.person_outline_rounded,
              iconBg: _kAccent,
              value: '$total',
              label: 'JUGADORES',
              bordered: true,
            ),
            _StatCell(
              icon: Icons.star_border_rounded,
              iconBg: _kGold,
              value: '$goats',
              label: 'GOATS',
              bordered: true,
            ),
            _StatCell(
              icon: Icons.public_outlined,
              iconBg: _kGreen,
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
              ? Border(right: BorderSide(color: _kBorder, width: 1.5))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                border: Border.all(color: _kBorder, width: 1),
              ),
              child: Icon(icon, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: _mono(
                        size: 18, weight: FontWeight.w900, color: _kAccent)),
                Text(label,
                    style: _mono(
                        size: 7,
                        weight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: _kMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar con filtros funcionales ───────────────────────
class _SearchBar extends ConsumerWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legacyFilter = ref.watch(playerLegacyFilterProvider);
    final sigFilter    = ref.watch(playerSigFilterProvider);
    final hasFilters   = legacyFilter.isNotEmpty || sigFilter > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _kBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _kDark.withOpacity(0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                style: _mono(size: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar jugador...',
                  hintStyle: _mono(size: 12, color: _kMuted),
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: _kMuted),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 13),
                          onPressed: () {
                            controller.clear();
                            ref.read(playerSearchProvider.notifier).set('');
                          },
                        )
                      : null,
                ),
                onChanged: (v) =>
                    ref.read(playerSearchProvider.notifier).set(v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showFilterSheet(context, ref, legacyFilter, sigFilter),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: hasFilters ? _kAccent : _kBg,
                border: Border.all(
                  color: hasFilters ? _kAccent : _kBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kDark.withOpacity(0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 14,
                      color: hasFilters ? Colors.white : _kDark),
                  const SizedBox(width: 6),
                  Text('FILTROS',
                      style: _mono(
                          size: 9,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: hasFilters ? Colors.white : _kDark)),
                  if (hasFilters) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 14, height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${(legacyFilter.isNotEmpty ? 1 : 0) + (sigFilter > 0 ? 1 : 0)}',
                          style: _mono(size: 8, weight: FontWeight.w900, color: _kAccent),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(
    BuildContext context,
    WidgetRef ref,
    String currentLegacy,
    int currentSig,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        initialLegacy: currentLegacy,
        initialSig: currentSig,
        onApply: (legacy, sig) {
          ref.read(playerLegacyFilterProvider.notifier).set(legacy);
          ref.read(playerSigFilterProvider.notifier).set(sig);
        },
        onClear: () {
          ref.read(playerLegacyFilterProvider.notifier).set('');
          ref.read(playerSigFilterProvider.notifier).set(0);
        },
      ),
    );
  }
}

// ── Bottom sheet de filtros ───────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final String initialLegacy;
  final int initialSig;
  final void Function(String legacy, int sig) onApply;
  final VoidCallback onClear;
  const _FilterSheet({
    required this.initialLegacy,
    required this.initialSig,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _legacy;
  late int    _sig;

  static const _legacyOptions = [
    ('Goal Scorer', 'Goleador'),
    ('Tactician',   'Táctico'),
    ('Innovator',   'Genio'),
    ('Leader',      'Líder'),
    ('Goalkeeper',  'Portero'),
    ('Technician',  'Técnico'),
  ];

  static const _sigOptions = [
    (5, 'GOAT'),
    (4, 'Leyenda'),
    (3, 'Icónico'),
    (2, 'Notable'),
    (1, 'Activo'),
  ];

  @override
  void initState() {
    super.initState();
    _legacy = widget.initialLegacy;
    _sig    = widget.initialSig;
  }

  @override
  Widget build(BuildContext context) {
    final hasActive = _legacy.isNotEmpty || _sig > 0;
    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kBorder, width: 2)),
        boxShadow: [
          BoxShadow(
            color: _kDark.withOpacity(0.25),
            offset: const Offset(0, -4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36, height: 3,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                Text('FILTRAR', style: _mono(size: 13, weight: FontWeight.w900, letterSpacing: 1)),
                const Spacer(),
                if (hasActive)
                  GestureDetector(
                    onTap: () {
                      widget.onClear();
                      Navigator.pop(context);
                    },
                    child: Text('Limpiar todo',
                        style: _mono(size: 10, color: _kMuted,
                            weight: FontWeight.w600)),
                  ),
              ],
            ),
          ),

          // Legado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LEGADO', style: _mono(size: 9, weight: FontWeight.w700,
                    letterSpacing: 1, color: _kMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _legacyOptions.map((opt) {
                    final isActive = _legacy == opt.$1;
                    return GestureDetector(
                      onTap: () => setState(() =>
                          _legacy = isActive ? '' : opt.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? _kAccent : Colors.transparent,
                          border: Border.all(
                            color: isActive ? _kAccent : _kBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Text(opt.$2,
                            style: _mono(
                                size: 10,
                                weight: FontWeight.w700,
                                color: isActive ? Colors.white : _kDark)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Nivel
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NIVEL', style: _mono(size: 9, weight: FontWeight.w700,
                    letterSpacing: 1, color: _kMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _sigOptions.map((opt) {
                    final isActive = _sig == opt.$1;
                    return GestureDetector(
                      onTap: () => setState(() =>
                          _sig = isActive ? 0 : opt.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? _kGold : Colors.transparent,
                          border: Border.all(
                            color: isActive ? _kGold : _kBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Text(opt.$2,
                            style: _mono(
                                size: 10,
                                weight: FontWeight.w700,
                                color: isActive ? Colors.black : _kDark)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Aplicar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: GestureDetector(
              onTap: () {
                widget.onApply(_legacy, _sig);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _kDark,
                  border: Border.all(color: _kBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withOpacity(0.4),
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text('APLICAR FILTROS',
                      style: _mono(
                          size: 11,
                          weight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
//  PLAYER CARD — neobrutalista 2x2 (estilo imagen 2)
// ══════════════════════════════════════════════════════════════

class _PlayerCard extends StatelessWidget {
  final HistoricalPlayer player;
  final VoidCallback onTap;
  const _PlayerCard({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(player.imagePath);
    final sig = player.significanceLevel ?? 0;
    final isGoat = sig == 5;
    final posLabel = _positionLabel[player.position] ?? player.position ?? '';

    // Trofeos: GOAT=5, Leyenda=4, Icónico=3, Notable=2, Activo=1, 0=ninguno
    final trophyCount = sig.clamp(0, 5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _neoBox(shadowX: 4, shadowY: 4),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Foto ─────────────────────────────────────────
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: _kAccent.withOpacity(0.12),
                    child: imgUrl != null
                        ? Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _CardInitials(name: player.name),
                            loadingBuilder: (_, child, p) =>
                                p == null ? child : _CardInitials(name: player.name),
                          )
                        : _CardInitials(name: player.name),
                  ),

                  // Badge GOAT
                  if (isGoat)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        color: _kGold,
                        child: Text(
                          'GOAT',
                          style: _mono(
                              size: 8,
                              weight: FontWeight.w900,
                              letterSpacing: 1,
                              color: Colors.black),
                        ),
                      ),
                    ),

                  // Número esquina inf-izq
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      color: _kDark.withOpacity(0.85),
                      child: Text(
                        '#${_playerNumber(player)}',
                        style: _mono(
                            size: 8,
                            weight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),

                  // Menú 3 puntos
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 24,
                      height: 24,
                      color: _kDark.withOpacity(0.6),
                      child: const Icon(Icons.more_horiz,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ─────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nombre
                    Text(
                      player.name.toUpperCase(),
                      style: _mono(
                          size: 11,
                          weight: FontWeight.w900,
                          letterSpacing: -0.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),

                    // País + posición
                    Column(
                      children: [
                        if (player.country != null)
                          Text(
                            player.country!.toUpperCase(),
                            style: _mono(
                                size: 8,
                                weight: FontWeight.w700,
                                color: _kAccent,
                                letterSpacing: 0.5),
                            textAlign: TextAlign.center,
                          ),
                        if (posLabel.isNotEmpty)
                          Text(
                            posLabel.toUpperCase(),
                            style: _mono(
                                size: 8,
                                weight: FontWeight.w600,
                                color: _kMuted),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),

                    // Trofeos centrados
                    if (trophyCount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          trophyCount,
                          (_) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1.5),
                            child: Icon(Icons.emoji_events_outlined,
                                size: 11, color: _kGold),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 11),
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

// Número decorativo basado en hash del ID
String _playerNumber(HistoricalPlayer p) {
  final hash = p.id.hashCode.abs() % 99 + 1;
  return hash.toString();
}

// ── Iniciales para la card ────────────────────────────────────
class _CardInitials extends StatelessWidget {
  final String name;
  const _CardInitials({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
    return Center(
      child: Text(
        initials,
        style: _mono(
            size: 36, weight: FontWeight.w900, color: _kAccent.withOpacity(0.3)),
      ),
    );
  }
}

// ── Stars widget ──────────────────────────────────────────────
class _Stars extends StatelessWidget {
  final int level;
  final double size;
  const _Stars({required this.level, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < level;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: filled ? _kGold : _kBorderL,
        );
      }),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Chip({
    required this.label,
    required this.icon,
    this.color = _kMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
            color: color == _kMuted ? _kBorderL : color.withOpacity(0.3)),
        color: color == _kMuted ? Colors.transparent : color.withOpacity(0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: _mono(
                  size: 9,
                  color: color == _kMuted ? _kDark : color)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DETAIL VIEW
// ══════════════════════════════════════════════════════════════

class _PlayerDetailView extends ConsumerWidget {
  final HistoricalPlayer player;
  final VoidCallback onBack;
  const _PlayerDetailView({required this.player, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(playerDetailProvider(player.id));

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          HistoryAppBar(
            title: player.name.toUpperCase(),
            subtitle: player.country ?? '',
            icon: Icons.person_outline_rounded,
            onBack: () =>
                ref.read(selectedPlayerProvider.notifier).select(null),
          ),
          Expanded(
            child: detailAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _kAccent)),
              error: (e, _) => Center(
                  child: Text('Error: $e', style: _mono(color: _kMuted))),
              data: (detail) => _DetailBody(detail: detail),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final PlayerDetail detail;
  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    final p = detail.player;
    final sig = p.significanceLevel ?? 0;
    final isGoat = sig == 5;
    final isActive = sig == 1;
    final imgUrl = getHistoricalImageUrl(p.imagePath);

    final lifespan = p.birthYear != null
        ? '${p.birthYear}${p.deathYear != null ? ' – ${p.deathYear}' : ' – Presente'}'
        : null;

    int totalGoals = 0, totalAssists = 0, totalApps = 0;
    for (final c in detail.career) {
      totalGoals += c.goals;
      totalAssists += c.assists;
      totalApps += c.appearances;
    }

    int totalCaps = 0, nationalGoals = 0;
    for (final n in detail.national) {
      totalCaps += n.caps;
      nationalGoals += n.goals;
    }

    int titlesCount = 0;
    for (final t in detail.titles) {
      if (t.titleCategory != 'individual') titlesCount += t.quantity;
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCard,
              border: Border(
                  bottom: BorderSide(color: _kBorder, width: 1.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto con sombra neobrutalista
                Container(
                  decoration: _neoBox(shadowX: 4, shadowY: 4),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 96,
                        child: imgUrl != null
                            ? Image.network(imgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _CardInitials(name: p.name))
                            : _CardInitials(name: p.name),
                      ),
                      if (isGoat)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: _kGold,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              'GOAT',
                              textAlign: TextAlign.center,
                              style: _mono(
                                  size: 7,
                                  weight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: Colors.black),
                            ),
                          ),
                        ),
                      if (isActive)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: _kGreen,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              'EN ACTIVO',
                              textAlign: TextAlign.center,
                              style: _mono(
                                  size: 7,
                                  weight: FontWeight.w900,
                                  letterSpacing: 1,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: _mono(
                              size: 17, weight: FontWeight.w900)),
                      const SizedBox(height: 6),

                      // País
                      if (p.country != null)
                        Row(
                          children: [
                            Text(
                              p.country!.toUpperCase(),
                              style: _mono(
                                  size: 9,
                                  weight: FontWeight.w700,
                                  color: _kAccent,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),

                      if (sig >= 2) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Stars(level: sig, size: 10),
                            const SizedBox(width: 6),
                            Text(
                              sig < _sigLabel.length ? _sigLabel[sig] : '',
                              style: _mono(
                                  size: 8,
                                  color: sig == 5 ? _kGold : _kMuted,
                                  weight: FontWeight.w700,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          if (p.position != null)
                            _Chip(
                              label: _positionLabel[p.position!] ?? p.position!,
                              icon: Icons.sports_soccer_outlined,
                              color: _kAccent,
                            ),
                          if (lifespan != null)
                            _Chip(
                                label: lifespan,
                                icon: Icons.access_time_rounded),
                          if ((p.ballonDorCount ?? 0) > 0)
                            _Chip(
                              label:
                                  '${p.ballonDorCount} Balón${p.ballonDorCount! > 1 ? "es" : ""} de Oro',
                              icon: Icons.emoji_events_outlined,
                              color: _kGold,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Stats strip ────────────────────────────────────────
        if (detail.career.isNotEmpty ||
            detail.national.isNotEmpty ||
            titlesCount > 0)
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: _kBorder, width: 1.5)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    if (detail.career.isNotEmpty) ...[
                      _StatCell2(
                          value: '${detail.career.length}',
                          label: 'CLUBES'),
                      _StatCell2(
                          value: '$totalGoals',
                          label: 'GOLES',
                          bordered: true),
                      if (totalAssists > 0)
                        _StatCell2(
                            value: '$totalAssists',
                            label: 'ASIST.',
                            bordered: true),
                    ],
                    if (detail.national.isNotEmpty) ...[
                      _StatCell2(
                          value: '$totalCaps',
                          label: 'INT\'L PART.',
                          color: _kGreen,
                          bordered: detail.career.isNotEmpty),
                      _StatCell2(
                          value: '$nationalGoals',
                          label: 'INT\'L GOLES',
                          color: _kGreen,
                          bordered: true),
                    ],
                    if (titlesCount > 0)
                      _StatCell2(
                          value: '$titlesCount',
                          label: 'TÍTULOS',
                          color: _kGold,
                          bordered: detail.career.isNotEmpty ||
                              detail.national.isNotEmpty),
                  ],
                ),
              ),
            ),
          ),

        // ── Trascendencia ──────────────────────────────────────
        if (p.impactSummary != null)
          SliverToBoxAdapter(
            child: _Section(
              label: 'TRASCENDENCIA',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(color: _kAccent, width: 3)),
                  color: _kAccent.withOpacity(0.04),
                ),
                child: Text(p.impactSummary!,
                    style: _mono(size: 13, color: _kDark)),
              ),
            ),
          ),

        // ── Historia ────────────────────────────────────────────
        if (p.description != null)
          SliverToBoxAdapter(
            child: _Section(
              label: 'HISTORIA',
              child: Text(p.description!,
                  style: _mono(size: 12, color: _kMuted)),
            ),
          ),

        // ── Trayectoria en clubes ───────────────────────────────
        if (detail.career.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              label: 'TRAYECTORIA EN CLUBES',
              child: _CareerTable(rows: detail.career),
            ),
          ),

        // ── Selección nacional ──────────────────────────────────
        if (detail.national.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              label: 'SELECCIÓN NACIONAL',
              child: _NationalTable(rows: detail.national),
            ),
          ),

        // ── Palmarés ────────────────────────────────────────────
        if (detail.titles.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              label: 'PALMARÉS',
              child: _TitlesList(titles: detail.titles),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

// ── Stat cell detalle ─────────────────────────────────────────
class _StatCell2 extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool bordered;
  const _StatCell2({
    required this.value,
    required this.label,
    this.color = _kDark,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: bordered
              ? Border(
                  left: BorderSide(color: _kBorder, width: 1.5))
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: _mono(
                    size: 22, weight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: _mono(
                    size: 7,
                    weight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _kMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────
class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: _kBorder, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                color: _kAccent,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: _mono(
                    size: 9,
                    weight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: _kMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Career table ──────────────────────────────────────────────
class _CareerTable extends StatelessWidget {
  final List<PlayerCareerEntry> rows;
  const _CareerTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: _kCard,
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('CLUB', style: _mono(size: 8, weight: FontWeight.w700, letterSpacing: 0.8, color: _kMuted))),
              Expanded(flex: 2, child: Text('PERÍODO', style: _mono(size: 8, weight: FontWeight.w700, letterSpacing: 0.8, color: _kMuted))),
              SizedBox(width: 32, child: Text('PJ', textAlign: TextAlign.center, style: _mono(size: 8, weight: FontWeight.w700, letterSpacing: 0.8, color: _kMuted))),
              SizedBox(width: 32, child: Text('G', textAlign: TextAlign.center, style: _mono(size: 8, weight: FontWeight.w700, letterSpacing: 0.8, color: _kMuted))),
              SizedBox(width: 32, child: Text('A', textAlign: TextAlign.center, style: _mono(size: 8, weight: FontWeight.w700, letterSpacing: 0.8, color: _kMuted))),
            ],
          ),
        ),
        ...rows.map((r) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _kBorderL, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.teamName, style: _mono(size: 12, weight: FontWeight.w700)),
                        if (r.teamCountry != null)
                          Text(r.teamCountry!, style: _mono(size: 9, color: _kMuted)),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text('${r.startYear ?? '?'} – ${r.endYear ?? '?'}', style: _mono(size: 10, color: _kAccent))),
                  SizedBox(width: 32, child: Text(r.appearances > 0 ? '${r.appearances}' : '—', textAlign: TextAlign.center, style: _mono(size: 11, weight: FontWeight.w700))),
                  SizedBox(width: 32, child: Text(r.goals > 0 ? '${r.goals}' : '—', textAlign: TextAlign.center, style: _mono(size: 11, weight: FontWeight.w700))),
                  SizedBox(width: 32, child: Text(r.assists > 0 ? '${r.assists}' : '—', textAlign: TextAlign.center, style: _mono(size: 11, weight: FontWeight.w700))),
                ],
              ),
            )),
      ],
    );
  }
}

// ── National table ────────────────────────────────────────────
class _NationalTable extends StatelessWidget {
  final List<PlayerNationalEntry> rows;
  const _NationalTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: _kCard,
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('SELECCIÓN', style: _mono(size: 8, weight: FontWeight.w700, letterSpacing: 0.8, color: _kMuted))),
              Expanded(flex: 2, child: Text('PERÍODO', style: _mono(size: 8, weight: FontWeight.w700, letterSpacing: 0.8, color: _kMuted))),
              SizedBox(width: 32, child: Text('PJ', textAlign: TextAlign.center, style: _mono(size: 8, weight: FontWeight.w700, letterSpacing: 0.8, color: _kMuted))),
              SizedBox(width: 32, child: Text('G', textAlign: TextAlign.center, style: _mono(size: 8, weight: FontWeight.w700, letterSpacing: 0.8, color: _kMuted))),
            ],
          ),
        ),
        ...rows.map((r) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _kBorderL, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(r.country, style: _mono(size: 12, weight: FontWeight.w700))),
                  Expanded(flex: 2, child: Text('${r.startYear ?? '?'} – ${r.endYear ?? '?'}', style: _mono(size: 10, color: _kGreen))),
                  SizedBox(width: 32, child: Text(r.caps > 0 ? '${r.caps}' : '—', textAlign: TextAlign.center, style: _mono(size: 11, weight: FontWeight.w700))),
                  SizedBox(width: 32, child: Text(r.goals > 0 ? '${r.goals}' : '—', textAlign: TextAlign.center, style: _mono(size: 11, weight: FontWeight.w700))),
                ],
              ),
            )),
      ],
    );
  }
}

// ── Titles list ───────────────────────────────────────────────
class _TitlesList extends StatelessWidget {
  final List<PlayerTitleEntry> titles;
  const _TitlesList({required this.titles});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<PlayerTitleEntry>> grouped = {};
    for (final t in titles) {
      grouped.putIfAbsent(t.titleCategory, () => []).add(t);
    }
    const order = ['club', 'national', 'individual'];

    return Column(
      children: order.where((c) => grouped.containsKey(c)).map((cat) {
        final catTitles = grouped[cat]!;
        final catColor = _titleCatColor[cat] ?? _kAccent;
        final catLabel = _titleCatLabel[cat] ?? cat;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 10),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: catColor,
                      border: Border.all(color: _kBorder, width: 1),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(catLabel.toUpperCase(),
                      style: _mono(
                          size: 9,
                          weight: FontWeight.w700,
                          letterSpacing: 1,
                          color: catColor)),
                ],
              ),
            ),
            ...catTitles.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: catColor, width: 2),
                      bottom: const BorderSide(
                          color: _kBorderL, width: 0.5),
                    ),
                    color: _kBg,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 11,
                          color: catColor.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t.titleName,
                            style: _mono(
                                size: 12, weight: FontWeight.w700)),
                      ),
                      if (t.teamName != null) ...[
                        const SizedBox(width: 6),
                        Text(t.teamName!,
                            style: _mono(size: 9, color: _kMuted)),
                      ],
                      if (t.year != null) ...[
                        const SizedBox(width: 8),
                        Text(t.year!,
                            style: _mono(
                                size: 10,
                                weight: FontWeight.w700,
                                color: catColor)),
                      ],
                      if (t.quantity > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _kGold.withOpacity(0.1),
                            border: Border.all(
                                color: _kGold.withOpacity(0.3)),
                          ),
                          child: Text('×${t.quantity}',
                              style: _mono(
                                  size: 9,
                                  weight: FontWeight.w800,
                                  color: _kGold)),
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        );
      }).toList(),
    );
  }
}