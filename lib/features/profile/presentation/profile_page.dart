import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile_providers.dart';
import '../domain/profile_models.dart';
import '../presentation/widgets/profile_hero_banner.dart';
import '../presentation/widgets/clinical_list_item.dart';

// ── Paleta ────────────────────────────────────────────────────
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFEAE7E1);
const _border  = Color(0xFFC8C3B8);
const _borderH = Color(0xFF1A1A2E);
const _accent  = Color(0xFF5B4FD8);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF6B6580);
const _red     = Color(0xFFE24B4A);

const _shadowColor = Color(0x4D1A1A2E);
const _shadowSm = BoxShadow(color: _shadowColor, offset: Offset(1, 1), blurRadius: 0);
const _shadow   = BoxShadow(color: Color(0x661A1A2E), offset: Offset(2, 2), blurRadius: 0);

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(ownProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _bg,
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            backgroundColor: _bg,
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
      backgroundColor: _bg,
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

            const SizedBox(height: 12),

            // ─── PREFERENCIAS ──────────────────────
            _SectionLabel('PREFERENCIAS'),
            _Card(children: [
              ClinicalListItem(
                iconColor: const Color(0xFF5B6BF5),
                icon: Icons.light_mode_outlined,
                title: 'Dark Mode',
                trailing: Switch(
                  value: false,
                  onChanged: null,
                  activeColor: _accent,
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

            const SizedBox(height: 4),

            // ─── MI ACTIVIDAD ──────────────────────
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
                iconColor: _accent,
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

            const SizedBox(height: 4),

            // ─── CUENTA ────────────────────────────
            _SectionLabel('CUENTA'),
            _Card(children: [
              ClinicalListItem(
                iconColor: const Color(0xFF6B7280),
                icon: Icons.edit_outlined,
                title: 'Editar Perfil',
                onTap: () => context.push('/profile/edit'),
              ),
              ClinicalListItem(
                iconColor: _accent,
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

            // ─── ADMIN ─────────────────────────────
            if (profile.role == 'admin') ...[
              const SizedBox(height: 4),
              _SectionLabel('ADMINISTRACIÓN'),
              _Card(children: [
                ClinicalListItem(
                  iconColor: _text,
                  icon: Icons.shield_outlined,
                  title: 'Panel de Admin',
                  subtitle: 'Partidos · Ligas · Logros · Banners',
                  onTap: () => context.push('/admin'),
                  showDivider: false,
                ),
              ]),
            ],

            const SizedBox(height: 4),

            // ─── SALIR ─────────────────────────────
            _SectionLabel('SALIR'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: _card,
                border: Border.all(color: _red.withOpacity(0.3), width: 1),
                boxShadow: const [_shadowSm],
              ),
              child: InkWell(
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/login');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        color: _red,
                        child: const Icon(Icons.logout, color: Colors.white, size: 19),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'CERRAR SESIÓN',
                          style: TextStyle(
                            fontFamily: 'DM Mono',
                            color: _red,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _red.withOpacity(0.5), size: 20),
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

// ─── Card neobrutalista ───────────────────────
class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border, width: 1),
        boxShadow: const [_shadowSm],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

// ─── Section label neobrutalista ─────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(width: 3, height: 12, color: _accent),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: _muted,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: _border)),
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