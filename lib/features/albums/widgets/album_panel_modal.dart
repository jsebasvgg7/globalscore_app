import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show Ds, GsColors;
import '../domain/albums_model.dart';
import 'sticker_card.dart';

// ════════════════════════════════════════════════════════════
//  API PÚBLICA — firma idéntica, sin cambios
// ════════════════════════════════════════════════════════════
void showAlbumPanel({
  required BuildContext context,
  required String albumId,
  required String name,
  required String shortLabel,
  required String tag,
  required Color spine,
  required Color accent,
  required Color coverBg,
  required int filled,
  required int slots,
  required double pct,
  required List<AlbumCollectionItem> collection,
  required List<({String slotType, AlbumCollectionItem? item})> allSlots,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AlbumPanelModal(
      albumId:    albumId,
      name:       name,
      shortLabel: shortLabel,
      tag:        tag,
      spine:      spine,
      accent:     accent,
      coverBg:    coverBg,
      filled:     filled,
      slots:      slots,
      pct:        pct,
      allSlots:   allSlots,
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  WIDGET PRINCIPAL
// ════════════════════════════════════════════════════════════
class AlbumPanelModal extends StatefulWidget {
  final String albumId, name, shortLabel, tag;
  final Color  spine, accent, coverBg;
  final int    filled, slots;
  final double pct;
  final List<({String slotType, AlbumCollectionItem? item})> allSlots;

  const AlbumPanelModal({
    super.key,
    required this.albumId,
    required this.name,
    required this.shortLabel,
    required this.tag,
    required this.spine,
    required this.accent,
    required this.coverBg,
    required this.filled,
    required this.slots,
    required this.pct,
    required this.allSlots,
  });

  @override
  State<AlbumPanelModal> createState() => _AlbumPanelModalState();
}

class _AlbumPanelModalState extends State<AlbumPanelModal> {
  // ── estado (toda la lógica intacta) ──────────────────────
  String _search      = '';
  int    _page        = 0;
  int    _filterIndex = 0;             // 0=todas 1=obtenidas 2=faltantes
  static const _perPage  = 12;         // 4 cols × 3 filas
  static const _filters  = ['TODAS', 'OBTENIDAS', 'FALTANTES'];

  // ── filtrado exactamente igual que antes ─────────────────
  List<({int index, String slotType, AlbumCollectionItem? item})>
      get _filtered {
    final base = widget.allSlots.indexed
        .map((e) => (index: e.$1, slotType: e.$2.slotType, item: e.$2.item))
        .toList();

    var result = base;
    if (_filterIndex == 1) result = result.where((s) => s.item != null).toList();
    if (_filterIndex == 2) result = result.where((s) => s.item == null).toList();

    if (_search.trim().isNotEmpty) {
      result = result
          .where((s) => s.item?.card?.name
                  ?.toLowerCase()
                  .contains(_search.toLowerCase()) ==
              true)
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filtered   = _filtered;
    final totalPages = (filtered.length / _perPage).ceil().clamp(1, 9999);
    final safePage   = _page.clamp(0, totalPages - 1);
    final pageItems  = filtered.skip(safePage * _perPage).take(_perPage).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.96,
      color:  Ds.bg,
      child: Column(
        children: [
          // ① Drag handle
          _DragHandle(),

          // ② Header: ← nombre / libro / % completado
          _AlbumHeader(
            shortLabel: widget.shortLabel,
            name:       widget.name,
            tag:        widget.tag,
            spine:      widget.spine,
            accent:     widget.accent,
            coverBg:    widget.coverBg,
            filled:     widget.filled,
            slots:      widget.slots,
            pct:        widget.pct,
            onClose:    () => Navigator.of(context).pop(),
          ),

          // ③ Franja de acento
          Container(height: 2, color: widget.accent),

          // ④ Barra de sección + búsqueda + paginación
          _SectionToolbar(
            name:        widget.name,
            filled:      widget.filled,
            slots:       widget.slots,
            filterLabel: _filters[_filterIndex],
            search:      _search,
            page:        safePage,
            totalPages:  totalPages,
            accent:      widget.accent,
            onFilterCycle: () => setState(() {
              _filterIndex = (_filterIndex + 1) % _filters.length;
              _page = 0;
            }),
            onSearch: (v) => setState(() { _search = v; _page = 0; }),
            onPrev:   safePage > 0
                ? () => setState(() => _page = safePage - 1)
                : null,
            onNext:   safePage < totalPages - 1
                ? () => setState(() => _page = safePage + 1)
                : null,
          ),

          // ⑤ Grid de figuritas
          Expanded(
            child: _StickerGrid(items: pageItems, accent: widget.accent),
          ),

          // ⑥ Footer "VER TODAS LAS CARTAS"
          _FooterButton(
            filled:  widget.filled,
            slots:   widget.slots,
            accent:  widget.accent,
            onClose: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  DRAG HANDLE
// ════════════════════════════════════════════════════════════
class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Ds.borderSub,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  HEADER
// ════════════════════════════════════════════════════════════
class _AlbumHeader extends StatelessWidget {
  final String   shortLabel, name, tag;
  final Color    spine, accent, coverBg;
  final int      filled, slots;
  final double   pct;
  final VoidCallback onClose;

  const _AlbumHeader({
    required this.shortLabel, required this.name, required this.tag,
    required this.spine, required this.accent, required this.coverBg,
    required this.filled, required this.slots,
    required this.pct, required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   Ds.bg,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Izquierda: back + nombre + conteo ─────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Back button estilo neobrutal
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width:  34, height: 34,
                      decoration: BoxDecoration(
                        color: Ds.bg,
                        border: Border.all(color: Ds.border, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFFB0AAA0), offset: Offset(2, 2)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, size: 14, color: Ds.ink),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shortLabel,
                        style: const TextStyle(
                          fontFamily: GsColors.fontMono,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Ds.ink,
                          height: 1,
                          letterSpacing: 0.5,
                        ),
                      ),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: '$filled',
                            style: TextStyle(
                              fontFamily: GsColors.fontMono,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: accent,
                            ),
                          ),
                          const TextSpan(
                            text: ' / ',
                            style: TextStyle(
                              fontFamily: GsColors.fontMono,
                              fontSize: 12,
                              color: Ds.muted,
                            ),
                          ),
                          TextSpan(
                            text: '$slots',
                            style: const TextStyle(
                              fontFamily: GsColors.fontMono,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Ds.muted,
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tag,
                style: const TextStyle(
                  fontFamily: GsColors.fontMono,
                  fontSize: 8,
                  color: Ds.muted,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          // ── Centro: portada del álbum ──────────────────
          Expanded(
            child: Center(
              child: _BookCover(
                shortLabel: shortLabel,
                spine:      spine,
                accent:     accent,
                coverBg:    coverBg,
              ),
            ),
          ),

          // ── Derecha: caja de progreso ──────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Ds.bg,
              border: Border.all(color: Ds.borderSub, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xFFB0AAA0), offset: Offset(3, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(pct * 100).round()}%',
                  style: TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    height: 1,
                  ),
                ),
                const Text(
                  'COMPLETADO',
                  style: TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 7,
                    color: Ds.muted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 80,
                  height: 5,
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: Ds.borderSub,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Portada mini del álbum (en el header) ─────────────────
class _BookCover extends StatelessWidget {
  final String shortLabel;
  final Color  spine, accent, coverBg;
  const _BookCover({
    required this.shortLabel,
    required this.spine, required this.accent, required this.coverBg,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60, height: 84,
      child: Row(
        children: [
          // Lomo
          Container(
            width: 12,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [spine, spine.withValues(alpha: 0.65)],
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
              ),
            ),
            alignment: Alignment.center,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                shortLabel,
                style: const TextStyle(
                  fontFamily: GsColors.fontMono,
                  fontSize: 5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          // Tapa
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: coverBg,
                border: Border(
                  top:    BorderSide(color: accent.withValues(alpha: 0.5), width: 1),
                  right:  BorderSide(color: accent.withValues(alpha: 0.5), width: 1),
                  bottom: BorderSide(color: accent.withValues(alpha: 0.5), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: spine.withValues(alpha: 0.35),
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.55), width: 1),
                  ),
                  child: Icon(Icons.shield_outlined, size: 13,
                      color: accent.withValues(alpha: 0.75)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SECTION TOOLBAR
// ════════════════════════════════════════════════════════════
class _SectionToolbar extends StatelessWidget {
  final String   name, filterLabel, search;
  final int      filled, slots, page, totalPages;
  final Color    accent;
  final VoidCallback         onFilterCycle;
  final ValueChanged<String> onSearch;
  final VoidCallback? onPrev, onNext;

  const _SectionToolbar({
    required this.name,    required this.filled,    required this.slots,
    required this.filterLabel, required this.search,
    required this.page,    required this.totalPages,
    required this.accent,  required this.onFilterCycle,
    required this.onSearch, this.onPrev, this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   Ds.bgSection,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        children: [
          // Fila 1: label + filtro + grid icon
          Row(
            children: [
              // "LEYENDAS 4 / 5"
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: name.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: GsColors.fontMono,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Ds.ink,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: '$filled / $slots',
                    style: TextStyle(
                      fontFamily: GsColors.fontMono,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ]),
              ),
              const Spacer(),

              // Filter cycle button
              GestureDetector(
                onTap: onFilterCycle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Ds.bg,
                    border: Border.all(color: Ds.border, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFFB0AAA0), offset: Offset(2, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filterLabel,
                        style: const TextStyle(
                          fontFamily: GsColors.fontMono,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Ds.ink,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 12, color: Ds.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Grid icon (decorativo, estado activo)
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: accent,
                  border: Border.all(color: Ds.border, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFB0AAA0), offset: Offset(2, 2)),
                  ],
                ),
                child: const Icon(Icons.grid_view_rounded, size: 14, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Fila 2: búsqueda + paginación
          Row(
            children: [
              // Búsqueda
              Expanded(
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Ds.bg,
                    border: Border.all(color: Ds.borderSub, width: 1),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(Icons.search, size: 12, color: Ds.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          onChanged: onSearch,
                          style: const TextStyle(
                            fontFamily: GsColors.fontMono,
                            fontSize: 10,
                            color: Ds.ink,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Buscar...',
                            hintStyle: TextStyle(fontSize: 10, color: Ds.muted),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Paginación
              _PageBtn(icon: Icons.chevron_left,  onTap: onPrev, accent: accent),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${(page + 1).toString().padLeft(2, '0')} / '
                  '${totalPages.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Ds.muted,
                  ),
                ),
              ),
              _PageBtn(icon: Icons.chevron_right, onTap: onNext, accent: accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;
  const _PageBtn({required this.icon, this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(
            color: active ? Ds.border : Ds.borderSub,
            width: 1.5,
          ),
        ),
        child: Icon(icon, size: 14,
            color: active ? Ds.ink : Ds.borderSub),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  GRID DE FIGURITAS
// ════════════════════════════════════════════════════════════
class _StickerGrid extends StatelessWidget {
  final List<({int index, String slotType, AlbumCollectionItem? item})> items;
  final Color accent;

  const _StickerGrid({required this.items, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 32, color: Ds.muted),
            const SizedBox(height: 8),
            const Text(
              'SIN RESULTADOS',
              style: TextStyle(
                fontFamily: GsColors.fontMono,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Ds.muted,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   4,
          mainAxisSpacing:  8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.66,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final slot = items[i];
          return StickerCard(
            index:          slot.index,
            card:           slot.item?.card,
            collectionItem: slot.item,
            accent:         accent,
            slotType:       slot.slotType,
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FOOTER BUTTON
// ════════════════════════════════════════════════════════════
class _FooterButton extends StatelessWidget {
  final int filled, slots;
  final Color accent;
  final VoidCallback onClose;

  const _FooterButton({
    required this.filled, required this.slots,
    required this.accent, required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   Ds.bg,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Ds.bg,
            border: Border.all(color: Ds.border, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0xFFB0AAA0), offset: Offset(4, 4)),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.style_outlined, size: 18, color: accent),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'VER TODAS LAS CARTAS',
                  style: TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Ds.ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Ds.muted),
            ],
          ),
        ),
      ),
    );
  }
}