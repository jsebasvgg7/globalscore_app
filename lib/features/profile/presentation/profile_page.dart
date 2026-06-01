import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile_providers.dart';
import '../domain/profile_models.dart';
import '../presentation/widgets/profile_hero_banner.dart';
import '../presentation/widgets/clinical_list_item.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(ownProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFEEEAE4),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFEEEAE4),
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFEEEAE4),
            body: Center(child: Text('No se pudo cargar el perfil')),
          );
        }
        return _ProfileMain(profile: profile);
      },
    );
  }
}

class _ProfileMain extends ConsumerWidget {
  final UserProfile profile;
  const _ProfileMain({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achAsync = ref.watch(achievementsProvider(profile.id));
    final unlockedCount = achAsync.whenOrNull(data: (s) => s.unlocked.length);

    return Scaffold(
      backgroundColor: const Color(0xFFEEEAE4),
      // Sin AppBar — el ScaffoldWithNavBar ya provee el header
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner + identity + stats bar ──────
            ProfileHeroBanner(profile: profile, isOwner: true),
            ProfileIdentityRow(
              profile: profile,
              isOwner: true,
              onTap: () => context.push('/profile/edit'),
            ),
            ProfileStatsBar(profile: profile),

            const SizedBox(height: 8),

            // ─────────────────────────────────
            // PREFERENCIAS
            // ─────────────────────────────────
            _SectionLabel('PREFERENCIAS'),
            _Card(children: [
              ClinicalListItem(
                iconColor: const Color(0xFF5B6BF5),
                icon: Icons.light_mode_outlined,
                title: 'Dark Mode',
                trailing: Switch(
                  value: false,
                  onChanged: null,
                  activeColor: const Color(0xFF60519B),
                ),
              ),
              ClinicalListItem(
                iconColor: const Color(0xFFEF9D1A),
                icon: Icons.palette_outlined,
                title: 'Apariencia',
                subtitle: 'Tema y estilo visual',
                trailing: _ComingSoonBadge(),
                showDivider: false,
              ),
            ]),

            // ─────────────────────────────────
            // MI ACTIVIDAD
            // ─────────────────────────────────
            _SectionLabel('MI ACTIVIDAD'),
            _Card(children: [
              ClinicalListItem(
                iconColor: const Color(0xFF22C55E),
                icon: Icons.bar_chart_rounded,
                title: 'Estadísticas',
                subtitle: 'Ver tu rendimiento',
                onTap: () => context.push('/stats'),
              ),
              ClinicalListItem(
                iconColor: const Color(0xFFF59E0B),
                icon: Icons.emoji_events_outlined,
                title: 'Logros',
                subtitle: unlockedCount != null
                    ? '$unlockedCount desbloqueados'
                    : 'Cargando...',
                onTap: () => context.push('/profile/achievements'),
              ),
              ClinicalListItem(
                iconColor: const Color(0xFF60519B),
                icon: Icons.military_tech_outlined,
                title: 'Campeonatos',
                subtitle: '${profile.monthlyChampionships} coronas',
                onTap: () => context.push('/profile/championships'),
              ),
              ClinicalListItem(
                iconColor: const Color(0xFF3B82F6),
                icon: Icons.history,
                title: 'Historial',
                subtitle: 'Todas tus predicciones',
                onTap: () => context.push('/profile/history'),
                showDivider: false,
              ),
            ]),

            // ─────────────────────────────────
            // CUENTA
            // ─────────────────────────────────
            _SectionLabel('CUENTA'),
            _Card(children: [
              ClinicalListItem(
                iconColor: const Color(0xFF6B7280),
                icon: Icons.edit_outlined,
                title: 'Editar Perfil',
                onTap: () => context.push('/profile/edit'),
              ),
              ClinicalListItem(
                iconColor: const Color(0xFF60519B),
                icon: Icons.person_outline,
                title: 'Cuenta',
                onTap: () {},
              ),
              ClinicalListItem(
                iconColor: const Color(0xFFEF9D1A),
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                onTap: () => context.push('/notifications'),
                showDivider: false,
              ),
            ]),

            // ─────────────────────────────────
            // ADMIN
            // ─────────────────────────────────
            if (profile.role == 'admin') ...[
              _SectionLabel('ADMINISTRACIÓN'),
              _Card(children: [
                ClinicalListItem(
                  iconColor: const Color(0xFF1A1A2E),
                  icon: Icons.shield_outlined,
                  title: 'Panel de Admin',
                  subtitle: 'Partidos · Ligas · Logros · Banners',
                  onTap: () => context.push('/admin'),
                  showDivider: false,
                ),
              ]),
            ],

            // ─────────────────────────────────
            // SALIR
            // ─────────────────────────────────
            _SectionLabel('SALIR'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                // Mismo tono crema-card, no blanco puro
                color: const Color(0xFFF5F2EE),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/login');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red, size: 20),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'CERRAR SESIÓN',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: Colors.red.withOpacity(0.5), size: 20),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Card con color crema (no blanco) ─────────
// Reemplaza ClinicalCard — mismo layout, color correcto
class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EE), // crema suave, no blanco
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

// ─── Section label ────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF60519B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0x7A1A1A2E),
              letterSpacing: 1.2,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF60519B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF60519B).withOpacity(0.2)),
      ),
      child: const Text(
        'Próximamente',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF60519B),
        ),
      ),
    );
  }
}