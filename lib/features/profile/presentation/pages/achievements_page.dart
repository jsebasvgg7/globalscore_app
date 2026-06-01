import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/profile_providers.dart';
import '../tabs/achievements_tab.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(ownProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEEEAE4),
      // Sin AppBar — usamos un header manual sin SafeArea extra
      body: Column(
        children: [
          // Header manual pegado arriba
          Container(
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEEEAE4),
              border: Border(
                bottom: BorderSide(color: Color(0xFFD5D0CA), width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Color(0xFF60519B), size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    'LOGROS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: profileAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (profile) {
                if (profile == null) {
                  return const Center(child: Text('Sin datos'));
                }
                return AchievementsTab(userId: profile.id);
              },
            ),
          ),
        ],
      ),
    );
  }
}