import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/worldcup_providers.dart';
import '../domain/worldcup_models.dart';
import '../widgets/group_card_button.dart';
import '../widgets/group_modal.dart';
import '../widgets/knockout_section.dart';
import '../widgets/awards_section.dart';

const _accent  = Color(0xFF5B4FD8);
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFE8E4DC);
const _border  = Color(0xFF1A1A2E);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF88887D);
const _shadow  = Color(0x8C1A1A2E);
const _gold    = Color(0xFFF59E0B);
const _correct = Color(0xFF1D9E75);

class WorldCupPage extends ConsumerStatefulWidget {
  const WorldCupPage({super.key});

  @override
  ConsumerState<WorldCupPage> createState() => _WorldCupPageState();
}

class _WorldCupPageState extends ConsumerState<WorldCupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref.read(worldCupProvider.notifier).save();
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? _correct : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        content: Text(
          ok ? '✓ Predicciones guardadas' : '✗ Error al guardar',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Solo observa loading para el estado inicial — los tabs manejan sus propios selects
    final loading = ref.watch(worldCupProvider.select((s) => s.loading));
    final supabaseUrl = ref.watch(supabaseUrlProvider);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        canvasColor: _bg,
        cardColor: _bg,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          surface: _bg,
          surfaceContainerHighest: _bg,
          surfaceContainerHigh: _bg,
          surfaceContainer: _bg,
          surfaceContainerLow: _bg,
          surfaceContainerLowest: _bg,
          surfaceDim: _bg,
          surfaceBright: _bg,
        ),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _WorldCupAppBar(
              onSave: _saving ? null : _save,
              saving: _saving,
            ),
            _NeoTabBar(controller: _tabCtrl),
            const Divider(height: 1, thickness: 1.5, color: _border),
            Expanded(
              child: loading
                  ? const _LoadingState()
                  : TabBarView(
                      controller: _tabCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Cada tab es keepAlive — no se rebuildan al deslizar
                        _GroupsTab(supabaseUrl: supabaseUrl),
                        _KnockoutTab(supabaseUrl: supabaseUrl),
                        const _AwardsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AppBar — solo observa lo que necesita ─────────────────
class _WorldCupAppBar extends ConsumerWidget {
  final VoidCallback? onSave;
  final bool saving;

  const _WorldCupAppBar({required this.onSave, required this.saving});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select: solo grupos → no se rebuilda cuando cambia knockout/awards
    final groups = ref.watch(
      worldCupProvider.select((s) => s.predictions.groups),
    );

    final completedGroups = kGroupsData.keys
        .where((g) => (groups[g]?.filledCount ?? 0) == 6)
        .length;

    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: top + 8, bottom: 12, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: _accent,
        border: Border(bottom: BorderSide(color: _border, width: 1.5)),
        boxShadow: [BoxShadow(color: _shadow, offset: Offset(0, 2), blurRadius: 0)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MUNDIAL 2026',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    letterSpacing: -0.5, color: Colors.white, height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _gold,
                        border: Border.all(color: _border, width: 0.5),
                      ),
                      child: const Text(
                        'USA · CAN · MEX',
                        style: TextStyle(
                          fontSize: 7, fontWeight: FontWeight.w900,
                          letterSpacing: 1, color: _border,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$completedGroups/${kGroupsData.length} grupos',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSave,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: saving ? _gold.withValues(alpha: 0.7) : _gold,
                border: Border.all(color: _border, width: 1.5),
                boxShadow: saving
                    ? const []
                    : const [BoxShadow(color: _shadow, offset: Offset(2, 2), blurRadius: 0)],
              ),
              child: saving
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _border),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_alt, size: 14, color: _border),
                        SizedBox(width: 5),
                        Text(
                          'GUARDAR',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w900,
                            letterSpacing: 1, color: _border,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── TabBar ────────────────────────────────────────────────
class _NeoTabBar extends StatelessWidget {
  final TabController controller;
  const _NeoTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    const labels = ['GRUPOS', 'ELIMINATORIAS', 'PREMIOS'];
    return Container(
      color: _bg,
      height: 44,
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = controller.index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selected ? _accent : _bg,
                  border: Border(
                    right: i < labels.length - 1
                        ? const BorderSide(color: _border, width: 0.5)
                        : BorderSide.none,
                    bottom: selected
                        ? const BorderSide(color: _accent, width: 2)
                        : BorderSide.none,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: selected ? Colors.white : _muted,
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

// ── Tab Grupos — keepAlive ────────────────────────────────
class _GroupsTab extends ConsumerStatefulWidget {
  final String supabaseUrl;
  const _GroupsTab({required this.supabaseUrl});

  @override
  ConsumerState<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends ConsumerState<_GroupsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // select: solo grupos, no knockout ni awards
    final groups = ref.watch(
      worldCupProvider.select((s) => s.predictions.groups),
    );
    final bestThirds = ref.watch(bestThirdsProvider);

    return ColoredBox(
      color: _bg,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ListHeader(title: 'FASE DE GRUPOS', subtitle: '12 grupos · 48 selecciones'),
          const SizedBox(height: 10),
          ...kGroupsData.keys.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RepaintBoundary(
              child: GroupCardButton(
                group: g,
                prediction: groups[g],
                supabaseUrl: widget.supabaseUrl,
                onTap: () => showGroupModal(context, g, widget.supabaseUrl),
              ),
            ),
          )),
          if (bestThirds.isNotEmpty) ...[
            const SizedBox(height: 20),
            _ListHeader(
              title: 'MEJORES TERCEROS',
              subtitle: 'Top 8 clasifican a octavos',
            ),
            const SizedBox(height: 10),
            _BestThirdsTable(thirds: bestThirds, supabaseUrl: widget.supabaseUrl),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Tab Eliminatorias — keepAlive ─────────────────────────
class _KnockoutTab extends ConsumerStatefulWidget {
  final String supabaseUrl;
  const _KnockoutTab({required this.supabaseUrl});

  @override
  ConsumerState<_KnockoutTab> createState() => _KnockoutTabState();
}

class _KnockoutTabState extends ConsumerState<_KnockoutTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: KnockoutSection(supabaseUrl: widget.supabaseUrl),
    );
  }
}

// ── Tab Premios — keepAlive ───────────────────────────────
class _AwardsTab extends ConsumerStatefulWidget {
  const _AwardsTab();

  @override
  ConsumerState<_AwardsTab> createState() => _AwardsTabState();
}

class _AwardsTabState extends ConsumerState<_AwardsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const SingleChildScrollView(child: AwardsSection());
  }
}

// ── Header de lista ───────────────────────────────────────
class _ListHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ListHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: _accent),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w900,
                  letterSpacing: 1.5, color: _text,
                )),
            Text(subtitle,
                style: const TextStyle(
                  fontSize: 9, color: _muted, fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ],
    );
  }
}

// ── Tabla mejores terceros ────────────────────────────────
class _BestThirdsTable extends StatelessWidget {
  final List<ThirdPlaceEntry> thirds;
  final String supabaseUrl;
  const _BestThirdsTable({required this.thirds, required this.supabaseUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _border, width: 1.5),
        boxShadow: const [BoxShadow(color: _shadow, offset: Offset(2, 2), blurRadius: 0)],
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: _bg,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Row(
              children: [
                SizedBox(width: 22),
                SizedBox(width: 36, child: Text('GRP', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 1))),
                Expanded(child: Text('Selección', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _muted))),
                SizedBox(width: 24, child: Text('J', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: _muted, fontWeight: FontWeight.w700))),
                SizedBox(width: 24, child: Text('GD', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: _muted, fontWeight: FontWeight.w700))),
                SizedBox(width: 28, child: Text('PTS', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: _muted, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _border),
          ...thirds.asMap().entries.map((e) {
            final rank  = e.key + 1;
            final entry = e.value;
            final qualifies = rank <= 8;
            final flagUrl = getTeamFlagUrl(entry.team, supabaseUrl);
            return RepaintBoundary(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: qualifies ? _correct.withValues(alpha: 0.05) : _bg,
                  border: const Border(bottom: BorderSide(color: _border, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: qualifies ? _correct : _muted,
                        border: Border.all(color: _border, width: 0.5),
                      ),
                      alignment: Alignment.center,
                      child: Text('$rank',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 28, height: 18,
                      decoration: BoxDecoration(
                        color: _accent,
                        border: Border.all(color: _border, width: 0.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(entry.group,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 24, height: 17,
                      decoration: BoxDecoration(
                        border: Border.all(color: _border.withValues(alpha: 0.2), width: 0.5),
                      ),
                      child: flagUrl.isNotEmpty
                          ? Image.network(flagUrl, fit: BoxFit.cover,
                              cacheWidth: 48, cacheHeight: 34,
                              errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 10, color: _muted))
                          : const Icon(Icons.flag, size: 10, color: _muted),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(entry.team,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _text),
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(width: 24, child: Text('${entry.played}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: _muted))),
                    SizedBox(width: 24, child: Text(
                      entry.gd >= 0 ? '+${entry.gd}' : '${entry.gd}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: entry.gd > 0 ? _correct : entry.gd < 0 ? Colors.red : _muted,
                      ),
                    )),
                    SizedBox(width: 28, child: Text('${entry.pts}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _text))),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Loading state ─────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _card,
              border: Border.all(color: _border, width: 2),
              boxShadow: const [BoxShadow(color: _shadow, offset: Offset(3, 3), blurRadius: 0)],
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(strokeWidth: 2.5, color: _accent),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'CARGANDO PREDICCIONES...',
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w900,
              letterSpacing: 2, color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}