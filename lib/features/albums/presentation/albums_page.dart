import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/albums_provider.dart';
import '../domain/albums_model.dart';
import 'pack_opening_modal.dart';

// ── Paleta ───────────────────────────────────────────────
const _accent  = Color(0xFF2D0CFF);
const _gold    = Color(0xFFFFD600);
const _bg      = Color(0xFFF5F0E8);
const _card    = Color(0xFFEDE7DA);
const _border  = Color(0xFF1A1A2E);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF888880);
const _shadow  = Color(0x181A1A2E); // menos saturado

const _colorLeg   = Color(0xFF00B850);
const _colorStars = Color(0xFF7B2DFF);
const _colorCult  = Color(0xFFE07820);

Color _groupColor(String type) => switch (type) {
      'legendary' => _colorLeg,
      'stars'     => _colorStars,
      _           => _colorCult,
    };

// ════════════════════════════════════════════════════════
//  PAGE
// ════════════════════════════════════════════════════════
class AlbumsPage extends ConsumerStatefulWidget {
  const AlbumsPage({super.key});

  @override
  ConsumerState<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends ConsumerState<AlbumsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(albumsProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Tab bar (sin TopBar de branding) ──────────
          _TabBar(tabs: _tabs),
          Expanded(
            child: albumsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.red, fontSize: 11)),
                ),
              ),
              data: (model) => TabBarView(
                controller: _tabs,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ResumenTab(model: model),
                  _ColeccionTab(model: model),
                  const _ProntoTab(label: 'SOBRES',   icon: Icons.mail_outline),
                  const _ProntoTab(label: 'MISIONES', icon: Icons.star_outline),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  TAB BAR  —  fiel a imagen 1 / imagen 2
// ════════════════════════════════════════════════════════
class _TabBar extends StatelessWidget {
  final TabController tabs;
  const _TabBar({required this.tabs});

  static const _defs = [
    (Icons.grid_view,     'RESUMEN',    false),
    (Icons.book_outlined, 'COLECCIÓN',  false),
    (Icons.mail_outline,  'SOBRES',     true),
    (Icons.star_outline,  'MISIONES',   true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(
          top:    BorderSide(color: _border, width: 1),
          bottom: BorderSide(color: _border, width: 1),
        ),
      ),
      child: Row(
        children: List.generate(_defs.length, (i) {
          final (icon, label, pronto) = _defs[i];
          final active = tabs.index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => tabs.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? _border : Colors.transparent,
                  border: i < _defs.length - 1
                      ? const Border(
                          right: BorderSide(color: _border, width: 1))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 11,
                        color: active ? Colors.white : _muted),
                    const SizedBox(width: 5),
                    Text(label,
                        style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: active ? Colors.white : _muted,
                        )),
                    if (pronto) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 1),
                        color: active
                            ? _gold
                            : _border.withValues(alpha: 0.12),
                        child: Text('PRONTO',
                            style: TextStyle(
                              fontSize: 5, fontWeight: FontWeight.w900,
                              color: active ? _border : _muted,
                            )),
                      ),
                    ],
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

// ════════════════════════════════════════════════════════
//  TAB RESUMEN  —  fotocopia imagen 2
// ════════════════════════════════════════════════════════
class _ResumenTab extends ConsumerWidget {
  final AlbumsModel model;
  const _ResumenTab({required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActiveAlbumCard(model: model),
          _PackProgressCard(packs: model.packs),
          _SobresDisponiblesCard(packs: model.packs),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Card álbum activo (imagen 2) ─────────────────────────
// Layout: borde negro, fondo blanco, sin margen exterior (full width),
// borde inferior separador, badge ACTIVO top-right en amarillo/verde,
// título grande, subtítulo gris, dos stat-boxes (figuritas / % completado),
// barra de progreso con % a la derecha, chip contador "N / 30 figuritas"
class _ActiveAlbumCard extends StatelessWidget {
  final AlbumsModel model;
  const _ActiveAlbumCard({required this.model});

  @override
  Widget build(BuildContext context) {
    final active = model.legendaryAlbums
            .where((d) => model.progressFor(d.id)?.isCompleted != true)
            .firstOrNull ??
        model.legendaryAlbums.firstOrNull;

    if (active == null) return const SizedBox.shrink();

    final prog     = model.progressFor(active.id);
    final unique   = prog?.uniqueCards ?? 0;
    final required = active.requiredUniquePlayers ?? 30;
    final pct      = required > 0 ? (unique / required).clamp(0.0, 1.0) : 0.0;
    final completed = prog?.isCompleted == true;
    final acColor   = _groupColor(active.albumType);

    return Container(
      // Card sin margen lateral — toca los bordes como en imagen 2
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _border, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: "ÁLBUM ACTIVO" label + badge ACTIVO
          Row(
            children: [
              const Text('ÁLBUM ACTIVO',
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w900,
                      letterSpacing: 1.5, color: _muted)),
              const Spacer(),
              _StatusBadge(completed: completed),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: info izquierda + libro 3D derecha
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título álbum
                    Text(
                      active.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900,
                        letterSpacing: -0.3, height: 1.1, color: _text,
                      ),
                    ),
                    if (active.description != null) ...[
                      const SizedBox(height: 3),
                      Text(active.description!,
                          style: const TextStyle(
                              fontSize: 11, color: _muted)),
                    ],
                    const SizedBox(height: 14),
                    // Dos stat boxes
                    Row(
                      children: [
                        _StatBox(value: '$unique', label: 'FIGURITAS'),
                        const SizedBox(width: 8),
                        _StatBox(
                            value: '${(pct * 100).round()}%',
                            label: 'COMPLETADO',
                            valueColor: acColor),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Libro 3D
              _Book3D(
                color: acColor,
                albumType: active.albumType,
                unique: unique,
                required: required,
                pct: pct,
              ),
            ],
          ),

          const SizedBox(height: 14),
          // Barra de progreso
          _ProgBar(pct: pct, color: acColor),
          const SizedBox(height: 8),
          // Chip contador
          _Chip(label: '$unique / $required figuritas'),
        ],
      ),
    );
  }
}

// ── Card progreso de sobres (imagen 2) ───────────────────
// Track horizontal con 5 hitos: círculos check/número, líneas animadas,
// labels debajo. Divider. Fila "PRÓXIMO BOOST + número grande + sobres restantes"
class _PackProgressCard extends StatelessWidget {
  final AlbumPacks? packs;
  const _PackProgressCard({required this.packs});

  static const _ms = [
    (0,  'Inicio'),
    (10, 'Tu\nPremio'),
    (20, 'Épico'),
    (30, 'Élite'),
    (40, 'TOP\nEspecial'),
  ];

  @override
  Widget build(BuildContext context) {
    final opened   = packs?.totalPacksOpened ?? 0;
    final boostRem = packs?.boostPacksRemaining ?? 0;
    final nextIn   = boostRem > 0
        ? boostRem
        : (10 - (opened % 10)) % 10 == 0
            ? 10
            : (10 - (opened % 10)) % 10;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _border, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROGRESO DE SOBRES',
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w900,
                  letterSpacing: 2, color: _muted)),
          const SizedBox(height: 22),

          _HitosTrack(opened: opened, milestones: _ms),

          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8E0D0)),
          const SizedBox(height: 16),

          // Boost row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRÓXIMO BOOST',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w900,
                          letterSpacing: 0.5, color: _text)),
                  const SizedBox(height: 2),
                  const Text('cada 10 sobres',
                      style: TextStyle(fontSize: 10, color: _muted)),
                ],
              ),
              const Spacer(),
              Text('$nextIn',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w900,
                      height: 1, color: _accent)),
              const SizedBox(width: 6),
              const Text('sobres\nrestantes',
                  style: TextStyle(
                      fontSize: 9, color: _muted, height: 1.4)),
            ],
          ),
        ],
      ),
    );
  }
}

// Track de hitos
class _HitosTrack extends StatelessWidget {
  final int opened;
  final List<(int, String)> milestones;
  const _HitosTrack({required this.opened, required this.milestones});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < milestones.length; i++) ...[
              _HitoCircle(
                  value: milestones[i].$1,
                  reached: opened >= milestones[i].$1),
              if (i < milestones.length - 1)
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _seg(i, opened)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(height: 2,
                            color: _border.withValues(alpha: 0.12)),
                        FractionallySizedBox(
                          widthFactor: v,
                          child: Container(height: 2, color: _accent),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (int i = 0; i < milestones.length; i++) ...[
              SizedBox(
                width: 36,
                child: Text(
                  milestones[i].$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: opened >= milestones[i].$1
                        ? FontWeight.w800 : FontWeight.w500,
                    color: opened >= milestones[i].$1 ? _accent : _muted,
                    height: 1.3,
                  ),
                ),
              ),
              if (i < milestones.length - 1)
                const Expanded(child: SizedBox()),
            ],
          ],
        ),
      ],
    );
  }

  double _seg(int i, int opened) {
    final start = milestones[i].$1;
    final end   = milestones[i + 1].$1;
    if (end == 0) return 0;
    if (opened <= start) return 0;
    if (opened >= end)   return 1;
    return (opened - start) / (end - start);
  }
}

class _HitoCircle extends StatelessWidget {
  final int value;
  final bool reached;
  const _HitoCircle({required this.value, required this.reached});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: reached ? _accent : _bg,
        border: Border.all(
          color: reached ? _accent : _border.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: reached
            ? [const BoxShadow(color: _shadow, offset: Offset(2, 2))]
            : [],
      ),
      alignment: Alignment.center,
      child: reached
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text('$value',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w900,
                  color: _border.withValues(alpha: 0.3))),
    );
  }
}

// ── Card sobres disponibles (imagen 2 bottom) ─────────────
// Fondo _bg crema, borde negro, libro apilado izquierda,
// texto "Tienes X sobres...", botón ABRIR SOBRES azul ancho completo
class _SobresDisponiblesCard extends ConsumerWidget {
  final AlbumPacks? packs;
  const _SobresDisponiblesCard({required this.packs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = packs?.packsAvailable ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: _shadow, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: label + contador badge
          Row(
            children: [
              const Text('SOBRES DISPONIBLES',
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w900,
                      letterSpacing: 2, color: _muted)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: available > 0 ? _accent : _card,
                  border: Border.all(color: _border, width: 1),
                ),
                child: Text('$available',
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w900,
                        color: available > 0 ? Colors.white : _muted)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sobres + texto
          Row(
            children: [
              _PackStack(count: available.clamp(0, 4)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  available > 0
                      ? 'Tienes $available sobres listos para abrir.'
                      : 'Gana resultados exactos para obtener sobres.',
                  style: const TextStyle(
                      fontSize: 11, color: _text,
                      fontFamily: 'monospace'),
                ),
              ),
            ],
          ),

          if (available > 0) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => showPackOpeningModal(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _accent,
                  border: Border.all(color: _border, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: _shadow, offset: Offset(3, 3)),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('ABRIR SOBRES',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w900,
                            letterSpacing: 2, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  TAB COLECCIÓN  —  fotocopia imagen 1
// ════════════════════════════════════════════════════════
class _ColeccionTab extends StatelessWidget {
  final AlbumsModel model;
  const _ColeccionTab({required this.model});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card "TU COLECCIÓN"
          _TuColeccionCard(model: model),

          // Header "TUS COLECCIONES"
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text('TUS COLECCIONES',
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w900,
                    letterSpacing: 2, color: _muted)),
          ),

          // Grupos
          _ColGroup(
            title: 'LEGENDARIOS',
            albumType: 'legendary',
            definitions: model.legendaryAlbums,
            model: model,
          ),
          _ColGroup(
            title: 'ESTRELLAS',
            albumType: 'stars',
            definitions: model.starsAlbums,
            model: model,
          ),
          _ColGroup(
            title: 'DE CULTO',
            albumType: 'cult',
            definitions: model.cultAlbums,
            model: model,
          ),

          // Banner sobres al fondo (imagen 1 bottom)
          _SobresBanner(model: model),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── "TU COLECCIÓN" card  (imagen 1 top) ──────────────────
// Borde negro, sombra offset, fondo blanco.
// Fila: número grande "14 ÁLBUMES ACTIVOS" | separador | 3 stats con icono
// Barra de progreso global al fondo de la card
class _TuColeccionCard extends StatelessWidget {
  final AlbumsModel model;
  const _TuColeccionCard({required this.model});

  @override
  Widget build(BuildContext context) {
    final totalAlbums = model.definitions.length;
    final completed   = model.definitions
        .where((d) => model.progressFor(d.id)?.isCompleted == true)
        .length;
    int totalReq = 0, totalGot = 0;
    for (final d in model.definitions) {
      totalReq += d.requiredUniquePlayers ?? 0;
      totalGot += model.progressFor(d.id)?.uniqueCards ?? 0;
    }
    final pct = totalReq > 0 ? (totalGot / totalReq).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: _shadow, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Text('TU COLECCIÓN',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900,
                      letterSpacing: 1, color: _text)),
              const Spacer(),
              _SmallBtn(label: 'VER TODO', onTap: () {}),
            ],
          ),
          const SizedBox(height: 14),

          // Stats row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Número grande álbumes activos
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$totalAlbums',
                          style: const TextStyle(
                              fontSize: 42, fontWeight: FontWeight.w900,
                              letterSpacing: -2, height: 1, color: _accent)),
                      const Text('ÁLBUMES\nACTIVOS',
                          style: TextStyle(
                              fontSize: 8, fontWeight: FontWeight.w700,
                              color: _muted, height: 1.3)),
                    ],
                  ),
                ),
                // Separador vertical
                Container(
                  width: 1,
                  color: _border.withValues(alpha: 0.12),
                  margin: const EdgeInsets.only(bottom: 14),
                ),
                const SizedBox(width: 14),
                // 3 stat cells en fila
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Expanded(child: _StatCell(
                          icon: Icons.style_outlined,
                          iconColor: _accent,
                          value: '${model.totalUniqueCards}',
                          label: 'FIGURITAS\nCONSEGUIDAS',
                        )),
                        Expanded(child: _StatCell(
                          icon: Icons.check_box_outlined,
                          iconColor: const Color(0xFF22C55E),
                          value: '${(pct * 100).round()}%',
                          label: 'PROGRESO\nGLOBAL',
                        )),
                        Expanded(child: _StatCell(
                          icon: Icons.star_outline,
                          iconColor: _gold,
                          value: '$completed',
                          label: 'COMPLE-\nTADOS',
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Barra global — al ras del borde inferior de la card
          _ProgBar(pct: pct, color: _accent),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${(pct * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 8, fontWeight: FontWeight.w900,
                      color: _accent)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _StatCell({
    required this.icon, required this.iconColor,
    required this.value, required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900,
                height: 1, color: _text)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 7, fontWeight: FontWeight.w700,
                color: _muted, height: 1.3)),
      ],
    );
  }
}

// ── Grupo colección (imagen 1 cards) ─────────────────────
// Card blanca, borde negro, sombra offset.
// Izquierda: libro 3D con color del grupo.
// Derecha: tipo colored + "N ÁLBUMES" bold + check/lock chips + botón >
//          barra de progreso + "X / N COMPLETADOS" en color del grupo
class _ColGroup extends StatelessWidget {
  final String title;
  final String albumType;
  final List<AlbumDefinition> definitions;
  final AlbumsModel model;
  const _ColGroup({
    required this.title, required this.albumType,
    required this.definitions, required this.model,
  });

  @override
  Widget build(BuildContext context) {
    if (definitions.isEmpty) return const SizedBox.shrink();

    final color     = _groupColor(albumType);
    final completed = definitions
        .where((d) => model.progressFor(d.id)?.isCompleted == true)
        .length;
    final pct = definitions.isEmpty
        ? 0.0 : completed / definitions.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: _shadow, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Libro 3D
          _BookCover3D(color: color, albumType: albumType),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo en color
                  Text(title,
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w900,
                          letterSpacing: 0.5, color: color)),
                  const SizedBox(height: 2),
                  // Cantidad álbumes
                  Text('${definitions.length} ÁLBUMES',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900,
                          color: _text)),
                  const SizedBox(height: 10),
                  // Chips + botón >
                  Row(
                    children: [
                      ...definitions.map((d) => _CheckChip(
                            completed: model.progressFor(d.id)
                                    ?.isCompleted ==
                                true,
                            color: color,
                          )),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context
                            .push('/albums/${definitions.first.id}'),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: _bg,
                            border: Border.all(color: _border, width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                  color: _shadow, offset: Offset(2, 2))
                            ],
                          ),
                          child: const Icon(Icons.chevron_right,
                              size: 16, color: _text),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Barra
                  _ProgBar(pct: pct, color: color),
                  const SizedBox(height: 5),
                  // Contador completados en color
                  Text('$completed / ${definitions.length} COMPLETADOS',
                      style: TextStyle(
                          fontSize: 8, fontWeight: FontWeight.w800,
                          letterSpacing: 0.3, color: color)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banner sobres disponibles (imagen 1 fondo) ───────────
// Fondo crema, borde negro, sombra. Libro mini izquierda con badge numérico,
// texto "SOBRES DISPONIBLES / Tienes sobres...", botón ABRIR SOBRES azul derecha
class _SobresBanner extends ConsumerWidget {
  final AlbumsModel model;
  const _SobresBanner({required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = model.packs?.packsAvailable ?? 0;
    if (available == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: _shadow, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Mini libro + badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44, height: 54,
                decoration: BoxDecoration(
                  color: _colorStars,
                  border: Border.all(color: _border, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: _shadow, offset: Offset(2, 2))
                  ],
                ),
                child: Stack(
                  children: [
                    // Lomo
                    Container(width: 6, color: const Color(0xFF4A1899)),
                    const Center(
                      child: Icon(Icons.auto_awesome,
                          color: Colors.white54, size: 18),
                    ),
                  ],
                ),
              ),
              // Badge numérico
              Positioned(
                top: -6, right: -6,
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text('$available',
                      style: const TextStyle(
                          fontSize: 8, fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SOBRES DISPONIBLES',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w900,
                        letterSpacing: 0.5, color: _text)),
                const SizedBox(height: 2),
                const Text('Tienes sobres listos para abrir.',
                    style: TextStyle(fontSize: 10, color: _muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Botón
          GestureDetector(
            onTap: () => showPackOpeningModal(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: _accent,
                border: Border.all(color: _border, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: _shadow, offset: Offset(2, 2))
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      color: Colors.white, size: 13),
                  SizedBox(width: 5),
                  Text('ABRIR SOBRES',
                      style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w900,
                          letterSpacing: 0.5, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  TAB PRÓXIMAMENTE
// ════════════════════════════════════════════════════════
class _ProntoTab extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ProntoTab({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _card,
              border: Border.all(color: _border, width: 1.5),
              boxShadow: const [
                BoxShadow(color: _shadow, offset: Offset(3, 3))
              ],
            ),
            child: Icon(icon, size: 30, color: _muted),
          ),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900,
                  letterSpacing: 2, color: _text)),
          const SizedBox(height: 6),
          const Text('Próximamente',
              style: TextStyle(fontSize: 11, color: _muted)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  WIDGETS COMPARTIDOS
// ════════════════════════════════════════════════════════

// Libro 3D para álbum activo (resumen tab)
class _Book3D extends StatelessWidget {
  final Color color;
  final String albumType;
  final int unique;
  final int required;
  final double pct;
  const _Book3D({
    required this.color, required this.albumType,
    required this.unique, required this.required, required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final spine = Color.fromARGB(255,
        (color.red * 0.5).round(),
        (color.green * 0.5).round(),
        (color.blue * 0.5).round());

    return SizedBox(
      width: 90, height: 112,
      child: Stack(
        children: [
          // Sombra
          Positioned(
            left: 6, top: 6,
            child: Container(
              width: 82, height: 104,
              color: _border.withValues(alpha: 0.08),
            ),
          ),
          // Lomo
          Positioned(
            left: 0, top: 2,
            child: Container(width: 10, height: 102, color: spine),
          ),
          // Tapa
          Positioned(
            left: 8, top: 0,
            child: Container(
              width: 82, height: 104,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: _border, width: 1.5),
              ),
              child: Stack(
                children: [
                  // Season badge top-left
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      color: _border.withValues(alpha: 0.3),
                      child: const Text('TEMPORADA 25+26',
                          style: TextStyle(
                              fontSize: 4.5, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 0.5)),
                    ),
                  ),
                  // Marcador rojo
                  const Positioned(
                    top: 0, left: 0, right: 0,
                    child: Center(
                      child: SizedBox(
                        width: 10, height: 22,
                        child: ColoredBox(color: Color(0xFFCC2222)),
                      ),
                    ),
                  ),
                  // Icono central
                  Center(
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        switch (albumType) {
                          'legendary' => Icons.bolt,
                          'stars'     => Icons.star,
                          _           => Icons.public,
                        },
                        color: Colors.white, size: 20,
                      ),
                    ),
                  ),
                  // Label + counter bottom
                  Positioned(
                    bottom: 8, left: 0, right: 0,
                    child: Column(
                      children: [
                        Text(
                          switch (albumType) {
                            'legendary' => 'ÉLITE',
                            'stars'     => 'STARS',
                            _           => 'CULT',
                          },
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 8, fontWeight: FontWeight.w900,
                              letterSpacing: 2, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text('$unique / $required ITEMS',
                            style: TextStyle(
                                fontSize: 6,
                                color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  // Barra progreso bottom
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 4,
                      color: Colors.black.withValues(alpha: 0.15),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: const ColoredBox(color: Colors.white54),
                      ),
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

// Libro 3D para grupos de colección
class _BookCover3D extends StatelessWidget {
  final Color color;
  final String albumType;
  const _BookCover3D({required this.color, required this.albumType});

  @override
  Widget build(BuildContext context) {
    final spine = Color.fromARGB(255,
        (color.red * 0.45).round(),
        (color.green * 0.45).round(),
        (color.blue * 0.45).round());
    const gold = Color(0xFFD4A820);

    return SizedBox(
      width: 80, height: 110,
      child: Stack(
        children: [
          // Sombra
          Positioned(
            left: 4, top: 4,
            child: Container(
              width: 74, height: 104,
              color: _border.withValues(alpha: 0.06),
            ),
          ),
          // Lomo
          Positioned(
            left: 0, top: 0,
            child: Container(
              width: 10, height: 104,
              decoration: BoxDecoration(
                color: spine,
                border: Border.all(color: _border, width: 0.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (_) => Container(
                  width: 4, height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white24, shape: BoxShape.circle,
                  ),
                )),
              ),
            ),
          ),
          // Tapa
          Positioned(
            left: 8, top: 0,
            child: Container(
              width: 72, height: 104,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: _border, width: 1.5),
              ),
              child: Stack(
                children: [
                  // Marco dorado interior
                  Positioned(
                    left: 4, top: 4, right: 4, bottom: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: gold, width: 1),
                      ),
                    ),
                  ),
                  // Marcador rojo
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        width: 8, height: 20,
                        color: const Color(0xFFCC2222),
                      ),
                    ),
                  ),
                  // Icono central
                  Center(
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        switch (albumType) {
                          'legendary' => Icons.bolt,
                          'stars'     => Icons.star,
                          _           => Icons.public,
                        },
                        color: Colors.white, size: 18,
                      ),
                    ),
                  ),
                  // Label
                  Positioned(
                    bottom: 10, left: 0, right: 0,
                    child: Text(
                      switch (albumType) {
                        'legendary' => 'ÉLITE',
                        'stars'     => 'STARS',
                        _           => 'CULT',
                      },
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 7, fontWeight: FontWeight.w900,
                          letterSpacing: 2, color: Colors.white),
                    ),
                  ),
                  // Esquinas doradas
                  Positioned(left: 4, top: 0,
                      child: Container(width: 8, height: 1, color: gold)),
                  Positioned(left: 4, bottom: 0,
                      child: Container(width: 8, height: 1, color: gold)),
                  Positioned(right: 0, top: 0,
                      child: Container(width: 8, height: 1, color: gold)),
                  Positioned(right: 0, bottom: 0,
                      child: Container(width: 8, height: 1, color: gold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Stack de sobres
class _PackStack extends StatelessWidget {
  final int count;
  const _PackStack({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Container(
        width: 56, height: 70,
        decoration: BoxDecoration(
          color: _card,
          border: Border.all(color: _border.withValues(alpha: 0.2), width: 1),
        ),
        child: const Icon(Icons.inbox_outlined, size: 24, color: _muted),
      );
    }
    return SizedBox(
      width: 56 + (count - 1) * 6.0,
      height: 72,
      child: Stack(
        children: [
          for (int i = count - 1; i >= 0; i--)
            Positioned(
              left: i * 6.0,
              top: (count - 1 - i) * 2.0,
              child: _PackEnv(index: i),
            ),
        ],
      ),
    );
  }
}

class _PackEnv extends StatelessWidget {
  final int index;
  const _PackEnv({required this.index});
  static const _colors = [
    _accent, Color(0xFF1A0CA8), Color(0xFF4A3AFF), Color(0xFF7B61FF),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    return Container(
      width: 54, height: 68,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
              color: _border.withValues(alpha: 0.08),
              offset: const Offset(1, 1))
        ],
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(54, 18),
            painter: _FlapPainter(color: Color.fromARGB(
              255,
              (color.red * 0.6).round(),
              (color.green * 0.6).round(),
              (color.blue * 0.6).round(),
            )),
          ),
          Align(
            alignment: const Alignment(0, 0.3),
            child: Icon(Icons.auto_awesome,
                color: Colors.white.withValues(alpha: 0.3), size: 18),
          ),
        ],
      ),
    );
  }
}

class _FlapPainter extends CustomPainter {
  final Color color;
  const _FlapPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)..lineTo(size.width, 0)
      ..lineTo(size.width, 4)..lineTo(size.width / 2, 15)
      ..lineTo(0, 4)..close();
    canvas.drawPath(path, p);
  }
  @override
  bool shouldRepaint(_FlapPainter o) => o.color != color;
}

// Barra de progreso animada
class _ProgBar extends StatelessWidget {
  final double pct;
  final Color color;
  const _ProgBar({required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (_, v, __) => Container(
        height: 10,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E0D0),
          border: Border.all(
              color: _border.withValues(alpha: 0.2), width: 1),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v,
            child: Container(color: color),
          ),
        ),
      ),
    );
  }
}

// Stat box (resumen álbum activo)
class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  const _StatBox(
      {required this.value, required this.label,
       this.valueColor = _text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _border, width: 1),
        boxShadow: const [BoxShadow(color: _shadow, offset: Offset(2, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900,
                  letterSpacing: -1, height: 1, color: valueColor)),
          Text(label,
              style: const TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w700,
                  letterSpacing: 0.5, color: _muted)),
        ],
      ),
    );
  }
}

// Chip contador
class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _border, width: 1),
        boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1))],
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: _text)),
    );
  }
}

// Check/lock chip
class _CheckChip extends StatelessWidget {
  final bool completed;
  final Color color;
  const _CheckChip({required this.completed, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: completed ? color : const Color(0xFFE8E0D0),
        border: Border.all(
          color: completed ? _border : _border.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: completed
            ? [const BoxShadow(color: _shadow, offset: Offset(1, 1))]
            : [],
      ),
      child: Icon(
        completed ? Icons.check : Icons.lock,
        size: completed ? 14 : 12,
        color: completed ? Colors.white : _muted,
      ),
    );
  }
}

// Badge ACTIVO / COMPLETADO
class _StatusBadge extends StatelessWidget {
  final bool completed;
  const _StatusBadge({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFF00C48C) : _gold,
        border: Border.all(color: _border, width: 1),
        boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1))],
      ),
      child: Text(
        completed ? 'COMPLETADO' : 'ACTIVO',
        style: const TextStyle(
            fontSize: 8, fontWeight: FontWeight.w900,
            letterSpacing: 1, color: _border),
      ),
    );
  }
}

// Botón outline pequeño
class _SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SmallBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _bg,
          border: Border.all(color: _border, width: 1),
          boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1))],
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w900,
                letterSpacing: 0.5, color: _text)),
      ),
    );
  }
}