import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;
import '../domain/albums_model.dart';
import 'sticker_card.dart';

// ════════════════════════════════════════════════════════════
//  ALBUM PANEL MODAL
//  React equiv: AlbumPanel (LegendaryAlbumsSection)
//  Modal fullscreen: sidebar info + grid de stickers
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
      albumId: albumId,
      name: name,
      shortLabel: shortLabel,
      tag: tag,
      spine: spine,
      accent: accent,
      coverBg: coverBg,
      filled: filled,
      slots: slots,
      pct: pct,
      allSlots: allSlots,
    ),
  );
}

class AlbumPanelModal extends StatefulWidget {
  final String albumId, name, shortLabel, tag;
  final Color spine, accent, coverBg;
  final int filled, slots;
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
  String _search = '';
  int _page = 0;
  static const _perPage = 9;

  List<({int index, String slotType, AlbumCollectionItem? item})>
      get _filtered {
    final base = widget.allSlots.indexed
        .map((e) => (index: e.$1, slotType: e.$2.slotType, item: e.$2.item))
        .toList();

    if (_search.trim().isEmpty) return base;
    return base
        .where((s) => s.item?.card?.name
                ?.toLowerCase()
                .contains(_search.toLowerCase()) ==
            true)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalPages = (filtered.length / _perPage).ceil().clamp(1, 9999);
    final safePage = _page.clamp(0, totalPages - 1);
    final pageItems = filtered
        .skip(safePage * _perPage)
        .take(_perPage)
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A12),
        borderRadius: BorderRadius.vertical(top: Radius.zero),
      ),
      child: Column(
        children: [
          // ── Topbar ────────────────────────────────────
          _PanelTopbar(
            name: widget.name,
            tag: widget.tag,
            spine: widget.spine,
            onClose: () => Navigator.of(context).pop(),
          ),

          // ── Body ──────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar
                _PanelSidebar(
                  albumId: widget.albumId,
                  shortLabel: widget.shortLabel,
                  accent: widget.accent,
                  coverBg: widget.coverBg,
                  spine: widget.spine,
                  filled: widget.filled,
                  slots: widget.slots,
                  pct: widget.pct,
                  tag: widget.tag,
                ),
                // Divisor
                Container(
                  width: 1,
                  color: GsColors.border.withValues(alpha: 0.2),
                ),
                // Panel principal
                Expanded(
                  child: Column(
                    children: [
                      _PanelToolbar(
                        search: _search,
                        onSearch: (v) => setState(() {
                          _search = v;
                          _page = 0;
                        }),
                        page: safePage,
                        totalPages: totalPages,
                        onPrev: safePage > 0
                            ? () => setState(() => _page = safePage - 1)
                            : null,
                        onNext: safePage < totalPages - 1
                            ? () => setState(() => _page = safePage + 1)
                            : null,
                      ),
                      Expanded(
                        child: _StickerGrid(
                          items: pageItems,
                          accent: widget.accent,
                          page: safePage,
                          totalPages: totalPages,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Footer ────────────────────────────────────
          _PanelFooter(
            filled: widget.filled,
            slots: widget.slots,
            onClose: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ── Topbar ────────────────────────────────────────────────
class _PanelTopbar extends StatelessWidget {
  final String name, tag;
  final Color spine;
  final VoidCallback onClose;

  const _PanelTopbar({
    required this.name, required this.tag,
    required this.spine, required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1A1A30), width: 1),
        ),
        boxShadow: [
          BoxShadow(color: spine.withValues(alpha: 0.15), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          // Banda de color del álbum
          Container(width: 4, color: spine),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 11, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: 1,
                  ),
                ),
                Text(
                  tag,
                  style: TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 8,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                border: Border.all(color: const Color(0xFF2A2A40), width: 1),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────
class _PanelSidebar extends StatelessWidget {
  final String albumId, shortLabel, tag;
  final Color accent, coverBg, spine;
  final int filled, slots;
  final double pct;

  const _PanelSidebar({
    required this.albumId, required this.shortLabel, required this.tag,
    required this.accent, required this.coverBg, required this.spine,
    required this.filled, required this.slots, required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      color: const Color(0xFF080810),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID
          Text(
            'ID: ALB-${albumId.split('_').last.padLeft(2, '0')}',
            style: TextStyle(
              fontFamily: GsColors.fontMono,
              fontSize: 7, color: accent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            shortLabel,
            style: TextStyle(
              fontFamily: GsColors.fontMono,
              fontSize: 16, fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),

          const SizedBox(height: 10),

          // Contador
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$filled',
                style: const TextStyle(
                  fontFamily: GsColors.fontMono,
                  fontSize: 28, fontWeight: FontWeight.w900,
                  height: 1, color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '/ $slots',
                  style: TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 11, color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Items',
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),

          const SizedBox(height: 10),
          Container(height: 1, color: const Color(0xFF1A1A30)),
          const SizedBox(height: 10),

          // Mini libro
          _MiniBook(
            accent: accent, coverBg: coverBg,
            spine: spine, shortLabel: shortLabel,
          ),

          const SizedBox(height: 10),

          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A30),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(pct * 100).round()}%',
            style: TextStyle(
              fontFamily: GsColors.fontMono,
              fontSize: 8, fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBook extends StatelessWidget {
  final Color accent, coverBg, spine;
  final String shortLabel;
  const _MiniBook({
    required this.accent, required this.coverBg,
    required this.spine, required this.shortLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          Container(
            width: 12,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [spine, spine.withValues(alpha: 0.6)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
            alignment: Alignment.center,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                shortLabel,
                style: const TextStyle(
                  fontFamily: GsColors.fontMono,
                  fontSize: 5, fontWeight: FontWeight.w900,
                  color: Colors.white60,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: coverBg,
                border: Border.all(
                  color: accent.withValues(alpha: 0.3), width: 0.8,
                ),
              ),
              child: Center(
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.4), width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.auto_awesome,
                        size: 10, color: accent.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toolbar ───────────────────────────────────────────────
class _PanelToolbar extends StatelessWidget {
  final String search;
  final ValueChanged<String> onSearch;
  final int page, totalPages;
  final VoidCallback? onPrev, onNext;

  const _PanelToolbar({
    required this.search, required this.onSearch,
    required this.page, required this.totalPages,
    this.onPrev, this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1A1A30), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Búsqueda
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A30),
                border: Border.all(color: const Color(0xFF2A2A40), width: 1),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.search, size: 12, color: Colors.white38),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      onChanged: onSearch,
                      style: const TextStyle(
                        fontFamily: GsColors.fontMono,
                        fontSize: 10, color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Buscar...',
                        hintStyle: TextStyle(
                          fontSize: 10, color: Colors.white30,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Paginación
          Row(
            children: [
              _PageBtn(
                icon: Icons.chevron_left,
                onTap: onPrev,
              ),
              Text(
                '${(page + 1).toString().padLeft(2, '0')} / '
                '${totalPages.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontFamily: GsColors.fontMono,
                  fontSize: 8, color: Colors.white54,
                ),
              ),
              _PageBtn(
                icon: Icons.chevron_right,
                onTap: onNext,
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _PageBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26, height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFF1A1A30)
              : Colors.transparent,
          border: Border.all(
            color: onTap != null
                ? const Color(0xFF2A2A40)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Icon(
          icon, size: 14,
          color: onTap != null ? Colors.white54 : Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

// ── Grid de stickers ──────────────────────────────────────
class _StickerGrid extends StatelessWidget {
  final List<({int index, String slotType, AlbumCollectionItem? item})> items;
  final Color accent;
  final int page, totalPages;

  const _StickerGrid({
    required this.items, required this.accent,
    required this.page, required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Indicador de página
          Row(
            children: [
              Expanded(child: Container(height: 1, color: const Color(0xFF1A1A30))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Página ${(page + 1).toString().padLeft(2, '0')} / '
                  '${totalPages.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: GsColors.fontMono,
                    fontSize: 8, color: Colors.white30,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: const Color(0xFF1A1A30))),
            ],
          ),
          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.68,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final slot = items[i];
              return StickerCard(
                index: slot.index,
                card: slot.item?.card,
                collectionItem: slot.item,
                accent: accent,
                slotType: slot.slotType,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────
class _PanelFooter extends StatelessWidget {
  final int filled, slots;
  final VoidCallback onClose;

  const _PanelFooter({
    required this.filled, required this.slots, required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1A),
        border: Border(top: BorderSide(color: Color(0xFF1A1A30), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FooterStat(label: 'Colectadas', value: '$filled'),
          const SizedBox(width: 16),
          _FooterStat(label: 'Total', value: '$slots'),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A30),
                border: Border.all(color: const Color(0xFF2A2A40), width: 1),
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  fontFamily: GsColors.fontMono,
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  final String label, value;
  const _FooterStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8, color: Colors.white30,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: GsColors.fontMono,
            fontSize: 14, fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
