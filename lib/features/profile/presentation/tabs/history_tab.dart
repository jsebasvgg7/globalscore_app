import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/profile_models.dart';
import '../../domain/profile_providers.dart';

// ── Colores brutalist ────────────────────────────────────────
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFEAE7E1);
const _surface = Color(0xFFF5F2EC);
const _border  = Color(0xFFC8C3B8);
const _borderH = Color(0xFFA8A49A);
const _accent  = Color(0xFF5B4FD8);
const _text    = Color(0xFF2A2535);
const _muted   = Color(0xFF9B95A8);
const _green   = Color(0xFF1D9E75);
const _red     = Color(0xFFE24B4A);
const _amber   = Color(0xFFF59E0B);

const _shadow   = BoxShadow(color: Color(0x55A8A49A), offset: Offset(3, 3), blurRadius: 0);
const _shadowSm = BoxShadow(color: Color(0x55A8A49A), offset: Offset(2, 2), blurRadius: 0);

// ── Filtros ──────────────────────────────────────────────────
enum _HistFilter { all, active, finished, exact, correct, wrong }

extension _HistFilterExt on _HistFilter {
  String get label {
    switch (this) {
      case _HistFilter.all:      return 'Todas';
      case _HistFilter.active:   return 'Activas';
      case _HistFilter.finished: return 'Terminadas';
      case _HistFilter.exact:    return 'Exactas';
      case _HistFilter.correct:  return 'Acertadas';
      case _HistFilter.wrong:    return 'Falladas';
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  HISTORY TAB
// ─────────────────────────────────────────────────────────────
class HistoryTab extends ConsumerStatefulWidget {
  final String userId;
  const HistoryTab({super.key, required this.userId});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  _HistFilter _filter = _HistFilter.all;

  List<PredictionHistoryEntry> _applyFilter(
      List<PredictionHistoryEntry> all, _HistFilter f) {
    switch (f) {
      case _HistFilter.all:      return all;
      case _HistFilter.active:   return all.where((e) => e.match?.status == 'pending').toList();
      case _HistFilter.finished: return all.where((e) => e.match?.status == 'finished').toList();
      case _HistFilter.exact:    return all.where((e) => e.resultType == 'exact').toList();
      case _HistFilter.correct:  return all.where((e) => e.resultType == 'correct').toList();
      case _HistFilter.wrong:    return all.where((e) => e.resultType == 'wrong').toList();
    }
  }

  Map<_HistFilter, int> _counts(List<PredictionHistoryEntry> all) => {
    _HistFilter.all:      all.length,
    _HistFilter.active:   all.where((e) => e.match?.status == 'pending').length,
    _HistFilter.finished: all.where((e) => e.match?.status == 'finished').length,
    _HistFilter.exact:    all.where((e) => e.resultType == 'exact').length,
    _HistFilter.correct:  all.where((e) => e.resultType == 'correct').length,
    _HistFilter.wrong:    all.where((e) => e.resultType == 'wrong').length,
  };

  @override
  Widget build(BuildContext context) {
    final histAsync = ref.watch(predictionHistoryProvider(widget.userId));

    return histAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (all) {
        final filtered = _applyFilter(all, _filter);
        final counts   = _counts(all);

        return Column(
          children: [
            _FilterHeader(
              filter: _filter,
              counts: counts,
              onFilterChanged: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(filter: _filter)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _HistCard(entry: filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FILTER HEADER
// ─────────────────────────────────────────────────────────────
class _FilterHeader extends StatelessWidget {
  final _HistFilter filter;
  final Map<_HistFilter, int> counts;
  final void Function(_HistFilter) onFilterChanged;

  const _FilterHeader({
    required this.filter,
    required this.counts,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _borderH, width: 1.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: _muted, size: 16),
          const SizedBox(width: 8),
          const Text(
            'Historial',
            style: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const Spacer(),
          _FilterButton(
            filter: filter,
            counts: counts,
            onFilterChanged: onFilterChanged,
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: _accent,
              boxShadow: [_shadowSm],
            ),
            child: Text(
              '${counts[_HistFilter.all]}',
              style: const TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FILTER BUTTON
// ─────────────────────────────────────────────────────────────
class _FilterButton extends StatefulWidget {
  final _HistFilter filter;
  final Map<_HistFilter, int> counts;
  final void Function(_HistFilter) onFilterChanged;

  const _FilterButton({
    required this.filter,
    required this.counts,
    required this.onFilterChanged,
  });

  @override
  State<_FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<_FilterButton> {
  final _key = GlobalKey();

  void _showModal() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos  = box.localToGlobal(Offset.zero);
    final size = box.size;

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            top: pos.dy + size.height + 4,
            right: MediaQuery.of(context).size.width - pos.dx - size.width,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: _card,
                  border: Border.all(color: _borderH, width: 1.5),
                  boxShadow: const [_shadow],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _HistFilter.values.map((f) {
                    final isActive = f == widget.filter;
                    final count    = widget.counts[f] ?? 0;
                    final isLast   = f == _HistFilter.values.last;
                    return GestureDetector(
                      onTap: () {
                        widget.onFilterChanged(f);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: isActive ? _accent : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: _borderH.withValues(alpha: 0.5),
                              width: isLast ? 0 : 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              f.label,
                              style: TextStyle(
                                fontFamily: 'DM Mono',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isActive ? Colors.white : _text,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              color: isActive
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : _borderH.withValues(alpha: 0.2),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontFamily: 'DM Mono',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.white : _muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFiltered = widget.filter != _HistFilter.all;
    return GestureDetector(
      key: _key,
      onTap: _showModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isFiltered ? _accent : _surface,
          border: Border.all(
            color: isFiltered ? _accent : _borderH,
            width: 1.5,
          ),
          boxShadow: const [_shadowSm],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert,
                size: 13,
                color: isFiltered ? Colors.white : _muted),
            const SizedBox(width: 5),
            Text(
              widget.filter.label,
              style: TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isFiltered ? Colors.white : _text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HIST CARD
// ─────────────────────────────────────────────────────────────
class _HistCard extends StatelessWidget {
  final PredictionHistoryEntry entry;
  const _HistCard({required this.entry});

  Color _accentForResult(String? r) {
    switch (r) {
      case 'exact':   return _amber;
      case 'correct': return _green;
      case 'wrong':   return _red;
      default:        return _muted;
    }
  }

  IconData _iconForResult(String? r) {
    switch (r) {
      case 'exact':   return Icons.stars_rounded;
      case 'correct': return Icons.check_circle_outline;
      case 'wrong':   return Icons.cancel_outlined;
      default:        return Icons.schedule;
    }
  }

  String _labelForResult(String? r) {
    switch (r) {
      case 'exact':   return '¡Exacto!';
      case 'correct': return 'Resultado Acertado';
      case 'wrong':   return 'Incorrecto';
      default:        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final match       = entry.match;
    final resultType  = entry.resultType;
    final accentColor = _accentForResult(resultType);

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
          left:   BorderSide(color: accentColor, width: 3),
          top:    const BorderSide(color: _border, width: 1),
          right:  const BorderSide(color: _border, width: 1),
          bottom: const BorderSide(color: _border, width: 1),
        ),
        boxShadow: const [_shadowSm],
      ),
      child: Column(
        children: [
          // ── Header liga + fecha ───────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: _card,
              border: Border(bottom: BorderSide(color: _border, width: 1)),
            ),
            child: Row(
              children: [
                _LogoBox(url: match?.leagueLogoUrl, fallback: '⚽', size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match?.league ?? '—',
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _muted,
                      letterSpacing: 0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.08),
                    border: Border.all(
                        color: _accent.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Text(
                    match?.date ?? '—',
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Cuerpo equipos + scores ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _TeamCol(
                    name: match?.homeTeam ?? '?',
                    logoUrl: match?.homeTeamLogoUrl,
                    align: CrossAxisAlignment.start,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ScoreBox(score: entry.homeScore),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Text('—',
                                style: TextStyle(
                                  fontFamily: 'DM Mono',
                                  fontWeight: FontWeight.w700,
                                  color: _muted,
                                  fontSize: 12,
                                )),
                          ),
                          _ScoreBox(score: entry.awayScore),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (match?.resultHome != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _bg,
                            border: Border.all(color: _border, width: 1),
                            boxShadow: const [_shadowSm],
                          ),
                          child: Column(
                            children: [
                              const Text('REAL',
                                  style: TextStyle(
                                    fontFamily: 'DM Mono',
                                    fontSize: 7,
                                    fontWeight: FontWeight.w700,
                                    color: _muted,
                                    letterSpacing: 1.0,
                                  )),
                              const SizedBox(height: 2),
                              Text(
                                '${match!.resultHome} · ${match.resultAway}',
                                style: const TextStyle(
                                  fontFamily: 'DM Mono',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: _text,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _muted.withValues(alpha: 0.08),
                            border: Border.all(color: _border, width: 1),
                          ),
                          child: const Text('PENDIENTE',
                              style: TextStyle(
                                fontFamily: 'DM Mono',
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: _muted,
                                letterSpacing: 0.8,
                              )),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _TeamCol(
                    name: match?.awayTeam ?? '?',
                    logoUrl: match?.awayTeamLogoUrl,
                    align: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
          ),

          // ── Footer resultado + puntos ─────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: _card,
              border: Border(top: BorderSide(color: _border, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    border: Border.all(
                        color: accentColor.withValues(alpha: 0.35),
                        width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_iconForResult(resultType),
                          size: 12, color: accentColor),
                      const SizedBox(width: 5),
                      Text(
                        _labelForResult(resultType),
                        style: TextStyle(
                          fontFamily: 'DM Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: entry.pointsEarned > 0
                        ? _green.withValues(alpha: 0.08)
                        : _bg,
                    border: Border.all(
                      color: entry.pointsEarned > 0 ? _green : _border,
                      width: 1.5,
                    ),
                    boxShadow: const [_shadowSm],
                  ),
                  child: Text(
                    entry.pointsEarned > 0
                        ? '+${entry.pointsEarned} PTS'
                        : '0 PTS',
                    style: TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: entry.pointsEarned > 0 ? _green : _muted,
                      letterSpacing: 0.6,
                    ),
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

// ─────────────────────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────────────────────
class _TeamCol extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final CrossAxisAlignment align;

  const _TeamCol({
    required this.name,
    required this.logoUrl,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        _LogoBox(url: logoUrl, fallback: '⚽', size: 40),
        const SizedBox(height: 6),
        Text(
          name,
          textAlign: align == CrossAxisAlignment.start
              ? TextAlign.left
              : TextAlign.right,
          style: const TextStyle(
            fontFamily: 'DM Mono',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _text,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int score;
  const _ScoreBox({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        border: Border.all(color: _accent, width: 1.5),
        boxShadow: const [_shadowSm],
      ),
      child: Center(
        child: Text(
          '$score',
          style: const TextStyle(
            fontFamily: 'DM Mono',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _accent,
          ),
        ),
      ),
    );
  }
}

class _LogoBox extends StatelessWidget {
  final String? url;
  final String fallback;
  final double size;

  const _LogoBox({this.url, required this.fallback, required this.size});

  bool get _hasUrl => url != null && url!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _borderH, width: 1),
        boxShadow: const [_shadowSm],
      ),
      child: _hasUrl
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => Center(
                child: Text(fallback,
                    style: TextStyle(
                        fontSize: size * 0.45,
                        decoration: TextDecoration.none)),
              ),
            )
          : Center(
              child: Text(fallback,
                  style: TextStyle(
                      fontSize: size * 0.45,
                      decoration: TextDecoration.none)),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final _HistFilter filter;
  const _EmptyState({required this.filter});

  String get _message {
    switch (filter) {
      case _HistFilter.all:      return 'AÚN NO HAY\nPREDICCIONES';
      case _HistFilter.active:   return 'NO HAY\nPREDICCIONES ACTIVAS';
      case _HistFilter.finished: return 'NO HAY\nPREDICCIONES FINALIZADAS';
      case _HistFilter.exact:    return 'NO HAY\nPREDICCIONES EXACTAS';
      case _HistFilter.correct:  return 'NO HAY\nPREDICCIONES ACERTADAS';
      case _HistFilter.wrong:    return 'NO HAY\nPREDICCIONES FALLADAS';
    }
  }

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
              border: Border.all(color: _borderH, width: 1.5),
              boxShadow: const [_shadow],
            ),
            child: const Icon(Icons.inbox_outlined, color: _muted, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _muted,
              letterSpacing: 1.2,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}