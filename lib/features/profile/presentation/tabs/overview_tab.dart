import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/profile_models.dart';
import '../../domain/profile_providers.dart';
import '../widgets/clinical_list_item.dart';

/// Tab principal del perfil (equivalente a MobileProfileMain en React).
/// Muestra: stats, preferencias, mi actividad.
class OverviewTab extends ConsumerWidget {
  final UserProfile profile;
  final bool isOwner;
  final void Function(String route) onNavigate;

  const OverviewTab({
    super.key,
    required this.profile,
    required this.isOwner,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankAsync = ref.watch(rankPositionProvider(profile.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats cards ─────────────────────
          _StatsGrid(profile: profile),
          const SizedBox(height: 4),

          // ── Nivel ────────────────────────────
          _LevelCard(profile: profile),
          const SizedBox(height: 4),

          // ── Ranking ──────────────────────────
          _RankingCard(rankAsync: rankAsync),

          // ── Preferencias ─────────────────────
          if (isOwner) ...[
            const SectionHeader(label: 'Preferencias'),
            ClinicalCard(
              children: [
                ClinicalListItem(
                  iconColor: const Color(0xFF5B6BF5),
                  icon: Icons.light_mode_outlined,
                  title: 'Dark Mode',
                  trailing: _ComingSoonBadge(),
                  showDivider: false,
                ),
              ],
            ),
            ClinicalCard(
              children: [
                ClinicalListItem(
                  iconColor: const Color(0xFFEF9D1A),
                  icon: Icons.palette_outlined,
                  title: 'Apariencia',
                  subtitle: 'Tema y estilo visual',
                  trailing: _ComingSoonBadge(),
                  showDivider: false,
                ),
              ],
            ),
          ],

          // ── Mi actividad ─────────────────────
          const SectionHeader(label: 'Mi Actividad'),
          ClinicalCard(
            children: [
              ClinicalListItem(
                iconColor: const Color(0xFF22C55E),
                icon: Icons.bar_chart_rounded,
                title: 'Estadísticas',
                subtitle: 'Ver tu rendimiento',
                onTap: () => onNavigate('/stats'),
              ),
              ClinicalListItem(
                iconColor: const Color(0xFFF59E0B),
                icon: Icons.emoji_events_outlined,
                title: 'Logros',
                subtitle: _achievementsSubtitle(ref),
                onTap: () => onNavigate('achievements'),
              ),
              ClinicalListItem(
                iconColor: const Color(0xFF60519B),
                icon: Icons.military_tech_outlined,
                title: 'Campeonatos',
                subtitle: '${profile.monthlyChampionships} coronas',
                onTap: () => onNavigate('championships'),
                showDivider: false,
              ),
            ],
          ),

          // ── Notas ────────────────────────────
          if (isOwner) ...[
            const SectionHeader(label: 'Más'),
            ClinicalCard(
              children: [
                ClinicalListItem(
                  iconColor: const Color(0xFF06B6D4),
                  icon: Icons.notes_rounded,
                  title: 'Notas',
                  subtitle: 'Mis predicciones anotadas',
                  trailing: _ComingSoonBadge(),
                  showDivider: false,
                ),
              ],
            ),
          ],

          // ── Admin (solo visible para admins) ──
          if (isOwner && profile.role == 'admin') ...[
            const SectionHeader(label: 'Administración'),
            ClinicalCard(
              children: [
                ClinicalListItem(
                  iconColor: const Color(0xFF1A1A2E),
                  icon: Icons.shield_outlined,
                  title: 'Panel de Admin',
                  subtitle: 'Partidos · Ligas · Logros · Banners',
                  onTap: () => onNavigate('/admin'),
                  showDivider: false,
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),  // ← este ya existía
        ],
      ),
    );
  }

  String _achievementsSubtitle(WidgetRef ref) {
    final async = ref.watch(achievementsProvider(profile.id));
    return async.when(
      data: (s) => '${s.unlocked.length} desbloqueados',
      loading: () => 'Cargando...',
      error: (_, __) => '',
    );
  }
}

// ─── Stats 3 columnas ─────────────────────────
class _StatsGrid extends StatelessWidget {
  final UserProfile profile;
  const _StatsGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatCard(value: '${profile.points}', label: 'PUNTOS'),
          const SizedBox(width: 8),
          _StatCard(value: '${profile.correct}', label: 'ACIERTOS'),
          const SizedBox(width: 8),
          _StatCard(
            value: '${profile.accuracy.round()}%',
            label: 'PRECISIÓN',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nivel ────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final UserProfile profile;
  const _LevelCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final progress = profile.levelProgress;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF60519B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.military_tech_outlined,
                color: Color(0xFF60519B), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nivel ${profile.level}',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF60519B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${profile.pointsToNextLevel} pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Para el siguiente nivel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.45),
                      ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        const Color(0xFF60519B).withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFF60519B),
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

// ─── Ranking ──────────────────────────────────
class _RankingCard extends StatelessWidget {
  final AsyncValue<int> rankAsync;
  const _RankingCard({required this.rankAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.leaderboard_outlined,
                  color: Color(0xFFEF9D1A), size: 20),
              const SizedBox(width: 6),
              Text(
                'RANKING GLOBAL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFEF9D1A),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          rankAsync.when(
            data: (pos) => Text(
              '#$pos',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
            ),
            loading: () => const SizedBox(
              height: 40,
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const Text('—'),
          ),
          const SizedBox(height: 4),
          Text(
            'posición actual',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.45),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Próximamente badge ───────────────────────
class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF60519B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF60519B).withOpacity(0.2),
        ),
      ),
      child: Text(
        'Próximamente',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF60519B).withOpacity(0.7),
        ),
      ),
    );
  }
}