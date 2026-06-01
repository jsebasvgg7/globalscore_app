import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/profile_providers.dart';
import '../tabs/achievements_tab.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Espera que el profile cargue antes de pasarle el userId al tab
    final profileAsync = ref.watch(ownProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEEEAE4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEEAE4),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF60519B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'LOGROS',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: profileAsync.when(
        // Muestra loader SOLO si el profile aún no llegó
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('Sin datos'));
          // Pasa el userId real al tab — aquí sí tiene datos
          return AchievementsTab(userId: profile.id);
        },
      ),
    );
  }
}