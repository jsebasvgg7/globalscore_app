import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show GsColors;
import '../domain/albums_model.dart';
import 'album_book_card.dart';
import 'album_panel_modal.dart';

// ════════════════════════════════════════════════════════════
//  LEGENDARY ALBUMS SECTION
//  React equiv: LegendaryAlbumsSection
//  Fila horizontal con 5 libros legendary desbloqueables
// ════════════════════════════════════════════════════════════

const _kLegendaryOrder = [
  'legendary_1', 'legendary_2', 'legendary_3', 'legendary_4', 'legendary_5',
];

const Map<String, _LegMeta> _legMeta = {
  'legendary_1': _LegMeta(
    label: 'FUNDACIÓN', shortLabel: 'LEG I', number: '01', tag: 'TEMP 25·26',
    spine: Color(0xFF5b4fd8), spineAlt: Color(0xFF3d34a5),
    accent: Color(0xFFa599d9), coverBg: Color(0xFF1a1726),
    slots: 30,
  ),
  'legendary_2': _LegMeta(
    label: 'LEYENDAS', shortLabel: 'LEG II', number: '02', tag: 'TEMP 25·26',
    spine: Color(0xFF7c3aed), spineAlt: Color(0xFF5b1fbd),
    accent: Color(0xFFc4b5fd), coverBg: Color(0xFF160e2a),
    slots: 30,
  ),
  'legendary_3': _LegMeta(
    label: 'ÉLITE', shortLabel: 'LEG III', number: '03', tag: 'TEMP 25·26',
    spine: Color(0xFF1D9E75), spineAlt: Color(0xFF0d6e50),
    accent: Color(0xFF34d399), coverBg: Color(0xFF0a1f18),
    slots: 30,
  ),
  'legendary_4': _LegMeta(
    label: 'GOAT', shortLabel: 'LEG IV', number: '04', tag: 'TEMP 25·26',
    spine: Color(0xFFb45309), spineAlt: Color(0xFF7c3b00),
    accent: Color(0xFFf59e0b), coverBg: Color(0xFF1a1200),
    slots: 30,
  ),
  'legendary_5': _LegMeta(
    label: 'INMORTALES', shortLabel: 'LEG V', number: '05', tag: 'ENDGAME',
    spine: Color(0xFF9d174d), spineAlt: Color(0xFF6b1130),
    accent: Color(0xFFf472b6), coverBg: Color(0xFF1a0e15),
    slots: 30,
  ),
};

const Map<String, _LegRequirements> _legReqs = {
  'legendary_1': _LegRequirements(slots: 30, reqZones: [
    _ReqZone(minStars: 4, count: 5),
  ]),
  'legendary_2': _LegRequirements(slots: 30, reqZones: [
    _ReqZone(minStars: 3, count: 5),
    _ReqZone(minStars: 4, count: 5),
  ]),
  'legendary_3': _LegRequirements(slots: 30, reqZones: [
    _ReqZone(minStars: 2, count: 5),
    _ReqZone(minStars: 3, count: 5),
    _ReqZone(minStars: 4, count: 5),
  ]),
  'legendary_4': _LegRequirements(slots: 30, reqZones: [
    _ReqZone(minStars: 2, count: 5),
    _ReqZone(minStars: 3, count: 5),
    _ReqZone(minStars: 4, count: 5),
    _ReqZone(minStars: 5, count: 1),
  ]),
  'legendary_5': _LegRequirements(slots: 30, reqZones: [
    _ReqZone(minStars: 2, count: 5),
    _ReqZone(minStars: 3, count: 5),
    _ReqZone(minStars: 4, count: 5),
    _ReqZone(minStars: 5, count: 5),
  ]),
};

class _LegMeta {
  final String label, shortLabel, number, tag;
  final Color spine, spineAlt, accent, coverBg;
  final int slots;
  const _LegMeta({
    required this.label, required this.shortLabel,
    required this.number, required this.tag,
    required this.spine, required this.spineAlt,
    required this.accent, required this.coverBg,
    required this.slots,
  });
}

class _LegRequirements {
  final int slots;
  final List<_ReqZone> reqZones;
  const _LegRequirements({required this.slots, required this.reqZones});
}

class _ReqZone {
  final int minStars, count;
  const _ReqZone({required this.minStars, required this.count});
}

// ── Widget público ────────────────────────────────────────
class LegendarySection extends StatelessWidget {
  final List<AlbumDefinition> definitions;
  final List<AlbumProgress> progress;
  final List<AlbumCollectionItem> collection;

  const LegendarySection({
    super.key,
    required this.definitions,
    required this.progress,
    required this.collection,
  });

  bool _isUnlocked(String albumId) {
    final idx = _kLegendaryOrder.indexOf(albumId);
    if (idx == 0) return true;
    final prevId = _kLegendaryOrder[idx - 1];
    return progress.any((p) => p.albumId == prevId && p.isCompleted);
  }

  _SlotLayout _buildSlots(
    String albumId,
    Set<String> prevUsed,
  ) {
    final reqs = _legReqs[albumId];
    if (reqs == null) return const _SlotLayout(slots: [], filled: 0, pct: 0);

    final playerCol = collection
        .where((c) =>
            c.card?.card_type == 'player' && !prevUsed.contains(c.cardId))
        .toList()
      ..sort((a, b) => a.firstObtainedAt.compareTo(b.firstObtainedAt));

    final assignedIds = <String>{};
    final result = <({String slotType, AlbumCollectionItem? item})>[];

    // Zonas requeridas (más estrellas primero)
    final sortedZones = [...reqs.reqZones]
      ..sort((a, b) => b.minStars.compareTo(a.minStars));

    for (final zone in sortedZones) {
      final tag = switch (zone.minStars) {
        5 => 'req5', 4 => 'req4', 3 => 'req3', _ => 'req2',
      };
      final candidates = playerCol
          .where((c) =>
              (c.card?.significance_level ?? 0) >= zone.minStars &&
              !assignedIds.contains(c.cardId))
          .toList();

      for (int i = 0; i < zone.count; i++) {
        final item = i < candidates.length ? candidates[i] : null;
        if (item != null) assignedIds.add(item.cardId);
        result.add((slotType: tag, item: item));
      }
    }

    // Slots generales
    final reqTotal = reqs.reqZones.fold(0, (s, z) => s + z.count);
    final generalCount = reqs.slots - reqTotal;
    final generalPool = playerCol
        .where((c) => !assignedIds.contains(c.cardId))
        .toList();

    for (int i = 0; i < generalCount; i++) {
      final item = i < generalPool.length ? generalPool[i] : null;
      if (item != null) assignedIds.add(item.cardId);
      result.add((slotType: 'general', item: item));
    }

    final filled = result.where((s) => s.item != null).length;
    final pct = reqs.slots > 0 ? filled / reqs.slots : 0.0;

    return _SlotLayout(slots: result, filled: filled, pct: pct);
  }

  @override
  Widget build(BuildContext context) {
    final globalUsed = <String>{};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _kLegendaryOrder.map((albumId) {
          final meta = _legMeta[albumId]!;
          final unlocked = _isUnlocked(albumId);
          final prog = progress.firstWhere(
            (p) => p.albumId == albumId,
            orElse: () => const AlbumProgress(
              id: '', userId: '', albumId: '',
              uniqueCards: 0, isCompleted: false,
              rewardClaimed: false, updatedAt: '',
            ),
          );

          _SlotLayout layout;
          Set<String> usedSnapshot;

          if (unlocked) {
            usedSnapshot = Set.from(globalUsed);
            layout = _buildSlots(albumId, usedSnapshot);
            // Agregar usados al pool global
            for (final s in layout.slots) {
              if (s.item != null) globalUsed.add(s.item!.cardId);
            }
          } else {
            layout = const _SlotLayout(slots: [], filled: 0, pct: 0);
            usedSnapshot = {};
          }

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _LegendaryBookWithPanel(
              albumId: albumId,
              meta: meta,
              locked: !unlocked,
              completed: prog.isCompleted,
              layout: layout,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Libro + panel ─────────────────────────────────────────
class _LegendaryBookWithPanel extends StatelessWidget {
  final String albumId;
  final _LegMeta meta;
  final bool locked, completed;
  final _SlotLayout layout;

  const _LegendaryBookWithPanel({
    required this.albumId, required this.meta,
    required this.locked, required this.completed,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return AlbumBookCard(
      albumId: albumId,
      shortLabel: meta.shortLabel,
      number: meta.number,
      tag: meta.tag,
      spine: meta.spine,
      spineAlt: meta.spineAlt,
      accent: meta.accent,
      coverBg: meta.coverBg,
      filled: layout.filled,
      total: meta.slots,
      pct: layout.pct,
      locked: locked,
      completed: completed,
      onTap: () => showAlbumPanel(
        context: context,
        albumId: albumId,
        name: meta.label,
        shortLabel: meta.shortLabel,
        tag: meta.tag,
        spine: meta.spine,
        accent: meta.accent,
        coverBg: meta.coverBg,
        filled: layout.filled,
        slots: meta.slots,
        pct: layout.pct,
        collection: [],
        allSlots: layout.slots,
      ),
    );
  }
}

class _SlotLayout {
  final List<({String slotType, AlbumCollectionItem? item})> slots;
  final int filled;
  final double pct;
  const _SlotLayout({
    required this.slots, required this.filled, required this.pct,
  });
}
