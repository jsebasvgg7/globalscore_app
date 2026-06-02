import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/profile_models.dart';
import '../../domain/profile_providers.dart';
import '../widgets/clinical_list_item.dart';

// ── Paleta ────────────────────────────────────────────────────
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFEAE7E1);
const _border  = Color(0xFFC8C3B8);
const _accent  = Color(0xFF5B4FD8);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF6B6580);
const _gold    = Color(0xFFC9A227);
const _green   = Color(0xFF1D9E75);

const _shadowSm = BoxShadow(color: Color(0x4D1A1A2E), offset: Offset(1, 1), blurRadius: 0);
const _shadow   = BoxShadow(color: Color(0x661A1A2E), offset: Offset(2, 2), blurRadius: 0);

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
          const SizedBox(height: 8),

          // ── Nivel ────────────────────────────
          _LevelCard(profile: profile),
          const SizedBox(height: 8),

          // ── Ranking ──────────────────────────
          _RankingCard(rankAsync: rankAsync),
          const SizedBox(height: 4),

          // ── Preferencias ─────────────────────
          if (isOwner) ...[
            const SectionHeader(label: 'Preferencias'),
            ClinicalCard(children: [
              ClinicalListItem(
                iconColor: const Color(0xFF5B6BF5),
                icon: Icons.light_mode_outlined,
                title: 'Dark Mode',
                trailing: _ComingSoonBadge(),
                showDivider: false,
              ),
            ]),
            ClinicalCard(children: [
              ClinicalListItem(
                iconColor: const Color(0xFFEF9D1A),
                icon: Icons.palette_outlined,
                title: 'Apariencia',
                subtitle: 'Tema y estilo visual',
                trailing: _ComingSoonBadge(),
                showDivider: false,
              ),
            ]),
          ],

          // ── Mi actividad ─────────────────────
          const SectionHeader(label: 'Mi Actividad'),
          ClinicalCard(children: [
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
              iconColor: _accent,
              icon: Icons.military_tech_outlined,
              title: 'Campeonatos',
              subtitle: '${profile.monthlyChampionships} coronas',
              onTap: () => onNavigate('championships'),
              showDivider: false,
            ),
          ]),

          // ── Notas ────────────────────────────
          if (isOwner) ...[
            const SectionHeader(label: 'Más'),
            ClinicalCard(children: [
              ClinicalListItem(
                iconColor: const Color(0xFF06B6D4),
                icon: Icons.notes_rounded,
                title: 'Notas',
                subtitle: 'Mis predicciones anotadas',
                trailing: _ComingSoonBadge(),
                showDivider: false,
              ),
            ]),
          ],

          // ── Admin ─────────────────────────────
          if (isOwner && profile.role == 'admin') ...[
            const SectionHeader(label: 'Administración'),
            ClinicalCard(children: [
              ClinicalListItem(
                iconColor: _text,
                icon: Icons.shield_outlined,
                title: 'Panel de Admin',
                subtitle: 'Partidos · Ligas · Logros · Banners',
                onTap: () => onNavigate('/admin'),
                showDivider: false,
              ),
            ]),
          ],

          const SizedBox(height: 16),
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

// ─── Stats 3 columnas neobrutalistas ──────────
class _StatsGrid extends StatelessWidget {
  final UserProfile profile;
  const _StatsGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCard(value: '${profile.points}', label: 'PUNTOS', accentColor: _accent),
            Container(width: 1, color: _border),
            _StatCard(value: '${profile.correct}', label: 'ACIERTOS', accentColor: _green),
            Container(width: 1, color: _border),
            _StatCard(
              value: '${profile.accuracy.round()}%',
              label: 'PRECISIÓN',
              accentColor: _gold,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color accentColor;
  const _StatCard({required this.value, required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _card,
          border: Border.all(color: _border, width: 1),
          boxShadow: const [_shadowSm],
        ),
        child: Column(
          children: [
            // Barra de acento top
            Container(height: 2, color: accentColor,
                margin: const EdgeInsets.only(bottom: 8)),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 7,
                fontWeight: FontWeight.w800,
                color: _muted,
                letterSpacing: 1.4,
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border, width: 1),
        boxShadow: const [_shadowSm],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            color: _accent.withOpacity(0.12),
            child: const Icon(Icons.military_tech_outlined,
                color: _accent, size: 20),
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
                      'NIVEL ${profile.level}',
                      style: const TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      color: _accent,
                      child: Text(
                        '${profile.pointsToNextLevel} pts',
                        style: const TextStyle(
                          fontFamily: 'DM Mono',
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Para el siguiente nivel',
                  style: const TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 9,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 8),
                // Barra de progreso neobrutalista
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: _bg,
                    border: Border.all(color: _border, width: 1),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(color: _accent),
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border, width: 1),
        boxShadow: const [_shadow],
      ),
      child: Column(
        children: [
          // Header dorado
          Container(
            height: 2,
            color: _gold,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 4, height: 4, color: _gold),
                    const SizedBox(width: 6),
                    const Text(
                      'RANKING GLOBAL',
                      style: TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _gold,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                rankAsync.when(
                  data: (pos) => Text(
                    '#$pos',
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -3,
                      color: _text,
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 48,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
                  ),
                  error: (_, __) => const Text('—'),
                ),
                const SizedBox(height: 2),
                const Text(
                  'posición actual',
                  style: TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 9,
                    color: _muted,
                    fontWeight: FontWeight.w600,
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

// ─── Coming soon badge ────────────────────────
class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.08),
        border: Border.all(color: _accent.withOpacity(0.25), width: 1),
      ),
      child: const Text(
        'PRONTO',
        style: TextStyle(
          fontFamily: 'DM Mono',
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: _accent,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}