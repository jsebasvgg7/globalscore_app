import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/profile_models.dart';
import '../../domain/profile_providers.dart';

class HistoryTab extends ConsumerWidget {
  final String userId;

  const HistoryTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histAsync = ref.watch(predictionHistoryProvider(userId));

    return histAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if (list.isEmpty) return _EmptyHistory();
        return _HistoryList(entries: list);
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<PredictionHistoryEntry> entries;
  const _HistoryList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PredictionCard(entry: entries[i]),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final PredictionHistoryEntry entry;
  const _PredictionCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final result = entry.resultType;
    final match = entry.match;
    final borderColor = _borderColor(result);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Header: liga + fecha ──────────
          if (match != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (match.leagueLogoUrl != null)
                    CachedNetworkImage(
                      imageUrl: match.leagueLogoUrl!,
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    )
                  else
                    const Icon(Icons.sports_soccer_outlined,
                        size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.league,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF8B5CF6).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF8B5CF6).withOpacity(0.15)),
                    ),
                    child: Text(
                      match.date,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Equipos + scores ─────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Equipo local
                Expanded(
                  child: _TeamSection(
                    name: match?.homeTeam ?? '?',
                    logoUrl: match?.homeTeamLogoUrl,
                    alignment: CrossAxisAlignment.center,
                  ),
                ),

                // Scores
                _ScoreSection(entry: entry, match: match),

                // Equipo visitante
                Expanded(
                  child: _TeamSection(
                    name: match?.awayTeam ?? '?',
                    logoUrl: match?.awayTeamLogoUrl,
                    alignment: CrossAxisAlignment.center,
                  ),
                ),
              ],
            ),
          ),

          // ── Footer: resultado + puntos ────
          _CardFooter(entry: entry),
        ],
      ),
    );
  }

  Color _borderColor(String? result) {
    switch (result) {
      case 'exact':
        return const Color(0xFFF59E0B);
      case 'correct':
        return const Color(0xFF10B981);
      case 'wrong':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

class _TeamSection extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final CrossAxisAlignment alignment;

  const _TeamSection({
    required this.name,
    required this.logoUrl,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        // Logo
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: logoUrl != null
              ? CachedNetworkImage(
                  imageUrl: logoUrl!,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.sports_soccer,
                    size: 28,
                    color: Colors.grey,
                  ),
                )
              : const Icon(Icons.sports_soccer, size: 28, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ScoreSection extends StatelessWidget {
  final PredictionHistoryEntry entry;
  final MatchInfo? match;

  const _ScoreSection({required this.entry, required this.match});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Predicción
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScoreBox(score: entry.homeScore),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('—',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: Colors.grey)),
              ),
              _ScoreBox(score: entry.awayScore),
            ],
          ),
          const SizedBox(height: 8),

          // Resultado real (si terminó)
          if (match?.resultHome != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    'REAL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.0,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.45),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${match!.resultHome}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3),
                        child: Text('·',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.grey)),
                      ),
                      Text(
                        '${match!.resultAway}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF94A3B8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'PENDIENTE',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int score;
  const _ScoreBox({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
        ),
        border: Border.all(color: const Color(0xFF10B981), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$score',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF065F46),
          ),
        ),
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  final PredictionHistoryEntry entry;
  const _CardFooter({required this.entry});

  @override
  Widget build(BuildContext context) {
    final result = entry.resultType;
    final config = _resultConfig(result);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withOpacity(0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          // Result indicator
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: config.bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: config.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(config.icon, size: 14, color: config.textColor),
                  const SizedBox(width: 6),
                  Text(
                    config.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: config.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Points badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '+${entry.pointsEarned} pts',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ResultConfig _resultConfig(String? result) {
    switch (result) {
      case 'exact':
        return _ResultConfig(
          icon: Icons.stars_rounded,
          label: '¡Exacto!',
          textColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFF59E0B).withOpacity(0.1),
          borderColor: const Color(0xFFF59E0B).withOpacity(0.2),
        );
      case 'correct':
        return _ResultConfig(
          icon: Icons.check_circle_outline,
          label: 'Correcto',
          textColor: const Color(0xFF059669),
          bgColor: const Color(0xFF10B981).withOpacity(0.1),
          borderColor: const Color(0xFF10B981).withOpacity(0.2),
        );
      case 'wrong':
        return _ResultConfig(
          icon: Icons.cancel_outlined,
          label: 'Incorrecto',
          textColor: const Color(0xFFDC2626),
          bgColor: const Color(0xFFEF4444).withOpacity(0.1),
          borderColor: const Color(0xFFEF4444).withOpacity(0.2),
        );
      default:
        return _ResultConfig(
          icon: Icons.schedule,
          label: 'Pendiente',
          textColor: const Color(0xFF64748B),
          bgColor: const Color(0xFF94A3B8).withOpacity(0.1),
          borderColor: const Color(0xFF94A3B8).withOpacity(0.2),
        );
    }
  }
}

class _ResultConfig {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;

  const _ResultConfig({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
  });
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Sin predicciones aún',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}