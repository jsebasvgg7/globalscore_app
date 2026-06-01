import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/profile_models.dart';
import '../../domain/profile_providers.dart';

class ChampionshipsTab extends ConsumerWidget {
  final String userId;

  const ChampionshipsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final champAsync = ref.watch(championshipsProvider(userId));

    return champAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) => list.isEmpty
          ? _EmptyChampionships()
          : _ChampionshipList(championships: list),
    );
  }
}

class _ChampionshipList extends StatelessWidget {
  final List<MonthlyChampionship> championships;
  const _ChampionshipList({required this.championships});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Showcase header
          _CrownsShowcase(count: championships.length),
          const SizedBox(height: 16),

          // History list
          Text(
            'HISTORIAL',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04), blurRadius: 6)
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: championships
                  .asMap()
                  .entries
                  .map(
                    (e) => _ChampionRow(
                      championship: e.value,
                      showDivider: e.key < championships.length - 1,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrownsShowcase extends StatelessWidget {
  final int count;
  const _CrownsShowcase({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A227).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC9A227).withOpacity(0.25)),
        // Top accent
      ),
      child: Row(
        children: [
          const Icon(Icons.military_tech, color: Color(0xFFC9A227), size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFC9A227),
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const Text(
                'CORONAS GANADAS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC9A227),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChampionRow extends StatelessWidget {
  final MonthlyChampionship championship;
  final bool showDivider;

  const _ChampionRow(
      {required this.championship, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 36,
                color: const Color(0xFFC9A227),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      championship.monthYear,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      '${championship.points} puntos',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1D9E75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.military_tech,
                  color: Color(0xFFC9A227), size: 20),
              const SizedBox(width: 4),
              Text(
                '#1',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC9A227),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 29,
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
          ),
      ],
    );
  }
}

class _EmptyChampionships extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.military_tech_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes campeonatos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sigue prediciendo para ganar el mes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}