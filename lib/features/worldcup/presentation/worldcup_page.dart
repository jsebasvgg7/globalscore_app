import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/worldcup_providers.dart';
import '../domain/worldcup_models.dart';
import '../widgets/group_card_button.dart';
import '../widgets/group_modal.dart';
import '../widgets/knockout_section.dart';
import '../widgets/awards_section.dart';

// ── Paleta
const _accent  = Color(0xFF2D0CFF);
const _bg      = Color(0xFFF5F0E8);
const _card    = Color(0xFFEDE7DA);
const _border  = Color(0xFF1A1A2E);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF555550);
const _shadow  = Color(0x661A1A2E);
const _gold    = Color(0xFFFFD600);
const _correct = Color(0xFF00C48C);

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
    final state      = ref.watch(worldCupProvider);
    final supabaseUrl = ref.watch(supabaseUrlProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── AppBar neobrut
          _WorldCupAppBar(
            state: state,
            onSave: _saving ? null : _save,
            saving: _saving,
          ),

          // ── TabBar
          _NeoTabBar(controller: _tabCtrl),
          const Divider(height: 1, thickness: 1.5, color: _border),

          // ── Contenido
          Expanded(
            child: state.loading
                ? const _LoadingState()
                : TabBarView(
                    controller: _tabCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // ── Tab 0: Grupos
                      _GroupsTab(state: state, supabaseUrl: supabaseUrl),
                      // ── Tab 1: Eliminatorias
                      SingleChildScrollView(
                        child: KnockoutSection(supabaseUrl: supabaseUrl),
                      ),
                      // ── Tab 2: Premios
                      const SingleChildScrollView(
                        child: AwardsSection(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────
class _WorldCupAppBar extends StatelessWidget {
  final WorldCupState state;
  final VoidCallback? onSave;
  final bool saving;

  const _WorldCupAppBar({
    required this.state,
    required this.onSave,
    required this.saving,
  });

  int get _totalGroups => kGroupsData.length; // 12
  int get _completedGroups {
    int count = 0;
    for (final g in kGroupsData.keys) {
      final pred = state.predictions.groups[g];
      if (pred != null && pred.filledCount == 6) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
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
          // ── Título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MUNDIAL 2026',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                    height: 1,
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
                      child: Text(
                        'USA · CAN · MEX',
                        style: const TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: _border,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_completedGroups/$_totalGroups grupos',
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

          // ── Botón guardar
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
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _border,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_alt, size: 14, color: _border),
                        SizedBox(width: 5),
                        Text(
                          'GUARDAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: _border,
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
    final labels = ['GRUPOS', 'ELIMINATORIAS', 'PREMIOS'];
    return Container(
      color: _card,
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
                  color: selected ? _accent : _card,
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
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
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

// ── Tab Grupos ────────────────────────────────────────────
class _GroupsTab extends StatelessWidget {
  final WorldCupState state;
  final String supabaseUrl;
  const _GroupsTab({required this.state, required this.supabaseUrl});

  @override
  Widget build(BuildContext context) {
    final groups = kGroupsData.keys.toList();
    final bestThirds = calcBestThirds(state.predictions.groups);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header sección grupos
        _ListHeader(title: 'FASE DE GRUPOS', subtitle: '12 grupos · 48 selecciones'),
        const SizedBox(height: 10),

        // ── Grid de grupos (2 columnas)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: groups.length,
          itemBuilder: (_, i) {
            final g = groups[i];
            return GroupCardButton(
              group: g,
              prediction: state.predictions.groups[g],
              supabaseUrl: supabaseUrl,
              onTap: () => showGroupModal(context, g, supabaseUrl),
            );
          },
        ),

        // ── Mejores terceros
        if (bestThirds.isNotEmpty) ...[
          const SizedBox(height: 20),
          _ListHeader(
            title: 'MEJORES TERCEROS',
            subtitle: 'Top 8 clasifican a octavos',
          ),
          const SizedBox(height: 10),
          _BestThirdsTable(thirds: bestThirds, supabaseUrl: supabaseUrl),
        ],

        const SizedBox(height: 20),
      ],
    );
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
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: _text,
                )),
            Text(subtitle,
                style: const TextStyle(fontSize: 9, color: _muted, fontWeight: FontWeight.w600)),
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
          // Thead
          Container(
            height: 28,
            color: _card,
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
            return Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: qualifies ? _correct.withValues(alpha: 0.05) : _bg,
                border: const Border(bottom: BorderSide(color: _border, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: qualifies ? _correct : _muted,
                      border: Border.all(color: _border, width: 0.5),
                    ),
                    alignment: Alignment.center,
                    child: Text('$rank',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(width: 4),
                  // Grupo badge
                  Container(
                    width: 28,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _accent,
                      border: Border.all(color: _border, width: 0.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(entry.group,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(width: 6),
                  // Flag
                  Container(
                    width: 24,
                    height: 17,
                    decoration: BoxDecoration(
                      border: Border.all(color: _border.withValues(alpha: 0.2), width: 0.5),
                    ),
                    child: flagUrl.isNotEmpty
                        ? Image.network(flagUrl, fit: BoxFit.cover,
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
            width: 56,
            height: 56,
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
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}