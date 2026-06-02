import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../../../shared/layout/scaffold_with_nav_bar.dart'
    show hideTopBarProvider, hideBottomNavProvider;
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import '../../data/history_service.dart';
import 'history_competitions_shared.dart';
import 'history_competition_detail.dart';

// ══════════════════════════════════════════════════════════════
//  ROOT
// ══════════════════════════════════════════════════════════════

class HistoryCompetitionsPage extends ConsumerStatefulWidget {
  const HistoryCompetitionsPage({super.key});

  @override
  ConsumerState<HistoryCompetitionsPage> createState() =>
      _HistoryCompetitionsPageState();
}

class _HistoryCompetitionsPageState
    extends ConsumerState<HistoryCompetitionsPage> {
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
    final selected = ref.watch(selectedCompetitionProvider);

    if (selected != null) {
      return HistoryCompetitionDetail(
        competition: selected,
        onBack: () =>
            ref.read(selectedCompetitionProvider.notifier).select(null),
      );
    }

    return _CompListView(searchCtrl: _searchCtrl, onBack: _handleBack);
  }
}

// ══════════════════════════════════════════════════════════════
//  LIST VIEW
// ══════════════════════════════════════════════════════════════

class _CompListView extends ConsumerWidget {
  final TextEditingController searchCtrl;
  final VoidCallback onBack;
  const _CompListView(
      {required this.searchCtrl, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compsAsync = ref.watch(filteredCompetitionsProvider);
    final allAsync   = ref.watch(historyCompetitionsProvider);

    final totalCount = allAsync.whenOrNull(data: (l) => l.length) ?? 0;
    final intlCount  = allAsync.whenOrNull(
          data: (l) => l.where((c) => c.type == 'International').length,
        ) ?? 0;
    final contCount  = allAsync.whenOrNull(
          data: (l) => l.where((c) => c.type == 'Continental').length,
        ) ?? 0;

    return Scaffold(
      backgroundColor: kHistBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompHeader(
            onBack: onBack,
            allAsync: allAsync,
          ),

          _StatsStrip(
            total: totalCount,
            intl: intlCount,
            continental: contCount,
          ),

          _SearchBar(
            controller: searchCtrl,
            allAsync: allAsync,
          ),

          compsAsync.whenOrNull(
                data: (comps) => _CounterRow(count: comps.length),
              ) ??
              const SizedBox.shrink(),

          Expanded(
            child: compsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: kHistAccent)),
              error: (e, _) => Center(
                  child:
                      Text('Error: $e', style: monoStyle(color: kHistMuted))),
              data: (comps) {
                if (comps.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_outlined,
                            size: 42, color: kHistBorderL),
                        const SizedBox(height: 10),
                        Text('SIN RESULTADOS',
                            style: monoStyle(
                                size: 11,
                                color: kHistMuted,
                                letterSpacing: 1.5)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                  itemCount: comps.length,
                  itemBuilder: (_, i) => CompCard(
                    comp: comps[i],
                    index: i,
                    onTap: () => ref
                        .read(selectedCompetitionProvider.notifier)
                        .select(comps[i]),
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

// ── Counter row ──────────────────────────────────────────────
class _CounterRow extends StatelessWidget {
  final int count;
  const _CounterRow({required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: kHistBorder, width: 1.5)),
        ),
        child: Row(children: [
          Container(width: 3, height: 12, color: kHistAccent),
          const SizedBox(width: 8),
          Text('COMPETICIONES',
              style: monoStyle(
                  size: 9,
                  weight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: kHistMuted)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kHistAccent,
              border: Border.all(color: kHistBorder, width: 1),
            ),
            child: Text('$count ENCONTRADAS',
                style: monoStyle(
                    size: 8,
                    weight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white)),
          ),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  HEADER — igual al de players
// ══════════════════════════════════════════════════════════════
const Color _kPurple = Color(0xFF5B4FD8);
 
class _CompHeader extends StatelessWidget {
  final VoidCallback onBack;
  final AsyncValue<List<HistoricalCompetition>> allAsync;
  const _CompHeader({required this.onBack, required this.allAsync});
 
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
 
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 18),
      decoration: const BoxDecoration(
        color: kHistBg,
        border: Border(bottom: BorderSide(color: kHistBorder, width: 1.5)),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 0,
            top: 0,
            child: DotGrid(cols: 5, rows: 4),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb back
              Row(children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: neoBox(shadowX: 2, shadowY: 2),
                    child: Row(children: [
                      const Icon(Icons.arrow_back,
                          size: 11, color: kHistDark),
                      const SizedBox(width: 5),
                      Text('HISTÓRICO',
                          style: monoStyle(
                              size: 9,
                              weight: FontWeight.w700,
                              letterSpacing: 0.8)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                // FIX: badge morado igual que players
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kPurple,
                    boxShadow: const [
                      BoxShadow(
                        color: kHistDark,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text('COMPETICIONES',
                      style: monoStyle(
                          color: Colors.white,
                          size: 9,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8)),
                ),
              ]),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // FIX: barra lateral morada igual que players
                  Container(width: 4, height: 40, color: _kPurple),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COMPETICIONES',
                          style: monoStyle(
                              size: 24,
                              weight: FontWeight.w900,
                              letterSpacing: -0.5)),
                      Text('Torneos que definieron una era.',
                          style: monoStyle(size: 11, color: kHistMuted)),
                    ],
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
 
class _StatsStrip extends StatelessWidget {
  final int total;
  final int intl;
  final int continental;
  const _StatsStrip({
    required this.total,
    required this.intl,
    required this.continental,
  });
 
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.emoji_events_outlined, '$total', 'TORNEOS',   _kPurple),
      (Icons.public_outlined,       '$intl',  'INTER\'L',  const Color(0xFFE8A020)),
      (Icons.language_outlined,     '$continental', 'CONTIN.', const Color(0xFF3DAA80)),
    ];
 
    return Container(
      decoration: const BoxDecoration(
        color: kHistBg,
        border: Border(bottom: BorderSide(color: kHistBorder, width: 1.5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final (icon, val, label, color) = entry.value;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: i < items.length - 1
                      ? const Border(
                          right: BorderSide(color: kHistBorderL, width: 1))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // FIX: relieve neo-brutalista igual que players
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(color: kHistBorder, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: kHistDark,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 15, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          val,
                          style: monoStyle(
                            size: 18,
                            weight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                        Text(
                          label,
                          style: monoStyle(
                            size: 7,
                            color: kHistMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
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
//  SEARCH BAR con botón aleatorio (modal)
// ══════════════════════════════════════════════════════════════

class _SearchBar extends ConsumerWidget {
  final TextEditingController controller;
  final AsyncValue<List<HistoricalCompetition>> allAsync;
  const _SearchBar(
      {required this.controller, required this.allAsync});

  void _showRandomModal(
      BuildContext context, List<HistoricalCompetition> all, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => _RandomModal(
        comps: all,
        onSelect: (comp) {
          Navigator.pop(context);
          ref
              .read(selectedCompetitionProvider.notifier)
              .select(comp);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = allAsync.whenOrNull(data: (l) => l) ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: kHistBorderL, width: 1)),
      ),
      child: Row(children: [
        // Search field
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kHistBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: kHistDark,
                    offset: Offset(2, 2),
                    blurRadius: 0)
              ],
            ),
            child: TextField(
              controller: controller,
              style: monoStyle(size: 12),
              decoration: InputDecoration(
                hintText: 'Buscar competición…',
                hintStyle: monoStyle(size: 12, color: kHistMuted),
                prefixIcon: const Icon(Icons.search,
                    size: 16, color: kHistMuted),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 14, color: kHistMuted),
                        onPressed: () {
                          controller.clear();
                          ref
                              .read(competitionSearchProvider.notifier)
                              .set('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) =>
                  ref.read(competitionSearchProvider.notifier).set(v),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Random button
        GestureDetector(
          onTap: all.isEmpty
              ? null
              : () => _showRandomModal(context, all, ref),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kHistDark,
              border: Border.all(color: kHistBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: kHistAccent,
                    offset: Offset(2, 2),
                    blurRadius: 0)
              ],
            ),
            child: const Icon(Icons.shuffle,
                size: 16, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  RANDOM MODAL  — igual al estilo de players
// ══════════════════════════════════════════════════════════════

class _RandomModal extends StatefulWidget {
  final List<HistoricalCompetition> comps;
  final void Function(HistoricalCompetition) onSelect;
  const _RandomModal(
      {required this.comps, required this.onSelect});

  @override
  State<_RandomModal> createState() => _RandomModalState();
}

class _RandomModalState extends State<_RandomModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  HistoricalCompetition? _current;
  HistoricalCompetition? _winner;
  bool _running = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _spinCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && _running) {
        _spinCtrl.reset();
        _spinCtrl.forward();
        final r = Random();
        setState(() =>
            _current = widget.comps[r.nextInt(widget.comps.length)]);
      }
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  void _start() {
    if (widget.comps.isEmpty) return;
    final r = Random();
    _winner = widget.comps[r.nextInt(widget.comps.length)];
    setState(() {
      _running = true;
      _done = false;
      _current = widget.comps[r.nextInt(widget.comps.length)];
    });
    _spinCtrl.forward();

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      _spinCtrl.stop();
      setState(() {
        _running = false;
        _done = true;
        _current = _winner;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kHistBg,
        border: Border(top: BorderSide(color: kHistBorder, width: 2)),
        boxShadow: [
          BoxShadow(
              color: kHistDark,
              offset: Offset(0, -3),
              blurRadius: 0)
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(bottom: 16),
              decoration:
                  BoxDecoration(color: kHistBorder),
            ),
          ),

          // Title
          Row(children: [
            Container(
                width: 3, height: 18, color: kHistAccent),
            const SizedBox(width: 8),
            Text('COMPETICIÓN ALEATORIA',
                style: monoStyle(
                    size: 13,
                    weight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 16),

          // Slot display
          if (_current != null) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 60),
              child: _RandomSlot(
                  key: ValueKey(_current!.id),
                  comp: _current!,
                  done: _done),
            ),
            const SizedBox(height: 16),
          ],

          // Buttons
          if (!_running && !_done)
            _ActionBtn(
              label: 'GIRAR',
              icon: Icons.shuffle,
              color: kHistDark,
              shadowColor: kHistAccent,
              onTap: _start,
            )
          else if (_running)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: kHistBorderL,
                border:
                    Border.all(color: kHistBorder, width: 1.5),
              ),
              child: Center(
                child: Text('GIRANDO…',
                    style: monoStyle(
                        size: 11,
                        weight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: kHistMuted)),
              ),
            )
          else ...[
            _ActionBtn(
              label: 'VER COMPETICIÓN',
              icon: Icons.arrow_forward,
              color: kHistAccent,
              shadowColor: kHistDark,
              onTap: () =>
                  _winner != null ? widget.onSelect(_winner!) : null,
            ),
            const SizedBox(height: 8),
            _ActionBtn(
              label: 'GIRAR DE NUEVO',
              icon: Icons.refresh,
              color: kHistDark,
              shadowColor: kHistAccent,
              onTap: () => setState(() {
                _done = false;
                _current = null;
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _RandomSlot extends StatelessWidget {
  final HistoricalCompetition comp;
  final bool done;
  const _RandomSlot({super.key, required this.comp, required this.done});

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(comp.imagePath);
    final tc = compTypeColor(comp.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color: done ? kHistAccent : kHistBorderL, width: 1.5),
        boxShadow: done
            ? [const BoxShadow(
                color: kHistAccent,
                offset: Offset(3, 3),
                blurRadius: 0)]
            : null,
      ),
      child: Row(children: [
        // Logo
        Container(
          width: 64,
          height: 64,
          color: const Color(0xFFE8E4DE),
          child: imgUrl != null
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.network(imgUrl, fit: BoxFit.contain))
              : Icon(Icons.emoji_events, size: 32, color: tc),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (comp.type != null)
                CompBadge(
                    label: compTypeLabels[comp.type!] ?? comp.type!,
                    bg: tc,
                    fg: Colors.white),
              const SizedBox(height: 4),
              Text(comp.name,
                  style: monoStyle(size: 13, weight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (comp.year != null || comp.country != null)
                Text(
                    [
                      if (comp.year != null) '${comp.year}',
                      if (comp.country != null) comp.country!,
                    ].join(' · '),
                    style: monoStyle(size: 10, color: kHistMuted)),
            ],
          ),
        ),
        if (done)
          const Icon(Icons.arrow_forward,
              size: 16, color: kHistAccent),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color shadowColor;
  final VoidCallback? onTap;
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.shadowColor,
      this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: kHistBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: shadowColor.withOpacity(0.5),
                  offset: const Offset(3, 3),
                  blurRadius: 0)
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 8),
              Text(label,
                  style: monoStyle(
                      size: 11,
                      weight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.white)),
            ],
          ),
        ),
      );
}
