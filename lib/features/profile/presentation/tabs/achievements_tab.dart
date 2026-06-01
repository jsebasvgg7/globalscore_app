import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/profile_models.dart';
import '../../domain/profile_providers.dart';

// Colores y labels por categoría (mismo mapa que AchievementsTab.jsx)
const _categoryColors = {
  'predictions': Color(0xFF8B7FC7),
  'accuracy': Color(0xFF34D399),
  'streaks': Color(0xFFEF4444),
  'points': Color(0xFFF59E0B),
  'crowns': Color(0xFFC9A227),
  'special': Color(0xFFFB923C),
};

const _categoryLabels = {
  'predictions': 'Predicciones',
  'accuracy': 'Aciertos',
  'streaks': 'Rachas',
  'points': 'Puntos',
  'crowns': 'Coronas',
  'special': 'Especiales',
};

class AchievementsTab extends ConsumerWidget {
  final String userId;

  const AchievementsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achAsync = ref.watch(achievementsProvider(userId));
    final titlesAsync = ref.watch(titlesProvider(userId));

    return achAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (achState) => SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Títulos ─────────────────────
            titlesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (titlesState) =>
                  _TitlesSection(titles: titlesState.unlocked),
            ),

            // ── Barra de progreso logros ─────
            _ProgressBar(
              current: achState.unlocked.length,
              total: achState.available.length,
            ),

            // ── Logros desbloqueados por categoría ─
            ..._categoryLabels.entries.expand((entry) {
              final catKey = entry.key;
              final catLabel = entry.value;
              final items = achState.unlocked
                  .where((a) => a.category == catKey)
                  .toList();
              if (items.isEmpty) return <Widget>[];

              final color =
                  _categoryColors[catKey] ?? const Color(0xFF8B5CF6);
              return [
                _CategoryHeader(
                    label: catLabel, count: items.length, color: color),
                _AchievementsList(items: items, unlocked: true),
              ];
            }),

            // ── Bloqueados ───────────────────
            if (achState.locked.isNotEmpty) ...[
              _CategoryHeader(
                label: 'Bloqueados',
                count: achState.locked.length,
                color: Colors.grey.shade400,
                dim: true,
              ),
              _AchievementsList(items: achState.locked, unlocked: false),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Sección de títulos ───────────────────────
class _TitlesSection extends StatelessWidget {
  final List<UserTitle> titles;
  const _TitlesSection({required this.titles});

  @override
  Widget build(BuildContext context) {
    if (titles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.layers_outlined,
                  size: 18, color: Color(0xFF60519B)),
              const SizedBox(width: 8),
              Text(
                'TÍTULOS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 8),
              _CountBadge(count: titles.length),
            ],
          ),
        ),
        ...titles.map((title) => _TitleRow(title: title)),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  final UserTitle title;
  const _TitleRow({required this.title});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(title.color) ?? const Color(0xFF60519B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03), blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.crown_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
                if (title.description != null)
                  Text(title.description!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Barra de progreso global ─────────────────
class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? current / total : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_outlined,
                      size: 18, color: Color(0xFF60519B)),
                  const SizedBox(width: 8),
                  Text('LOGROS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          )),
                ],
              ),
              _CountBadge(count: current, total: total),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFF60519B).withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF60519B)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$current de $total logros desbloqueados',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.4),
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Categoría header ─────────────────────────
class _CategoryHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool dim;

  const _CategoryHeader({
    required this.label,
    required this.count,
    required this.color,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: dim ? Colors.grey.shade400 : color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: dim
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.35)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: dim ? Colors.grey.shade400 : color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lista de logros ──────────────────────────
class _AchievementsList extends StatelessWidget {
  final List<Achievement> items;
  final bool unlocked;

  const _AchievementsList({required this.items, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((a) => _AchievementRow(achievement: a, unlocked: unlocked))
          .toList(),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const _AchievementRow(
      {required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final color =
        _categoryColors[achievement.category] ?? const Color(0xFF8B5CF6);

    return Opacity(
      opacity: unlocked ? 1.0 : 0.45,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: unlocked ? color : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: unlocked
                    ? color
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: unlocked
                    ? Text(
                        achievement.icon ?? '🏆',
                        style: const TextStyle(fontSize: 16),
                      )
                    : Icon(Icons.lock_outline,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.35)),
              ),
            ),
            const SizedBox(width: 12),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                  ),
                  if (achievement.description != null)
                    Text(
                      achievement.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.45),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Badge categoría
            if (unlocked && achievement.category != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  _categoryLabels[achievement.category!] ??
                      achievement.category!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Count badge ──────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  final int? total;

  const _CountBadge({required this.count, this.total});

  @override
  Widget build(BuildContext context) {
    final label = total != null ? '$count/$total' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF60519B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF60519B),
        ),
      ),
    );
  }
}

// ─── Helper ───────────────────────────────────
Color? _parseColor(String? hex) {
  if (hex == null) return null;
  final clean = hex.replaceFirst('#', '');
  final value = int.tryParse(clean, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}