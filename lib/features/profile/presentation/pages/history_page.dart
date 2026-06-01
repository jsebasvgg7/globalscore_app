import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/profile_providers.dart';
import '../tabs/history_tab.dart';

class PredictionHistoryPage extends ConsumerWidget {
  const PredictionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(ownProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0EDE8),
      body: Column(
        children: [
          // Header manual — sin AppBar para evitar doble espacio
          Container(
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEAE7E1),
              border: Border(
                bottom: BorderSide(color: Color(0xFFA8A49A), width: 1.5),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Color(0xFF9B95A8), size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    'HISTORIAL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xFF2A2535),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (profile) {
                if (profile == null) {
                  return const Center(child: Text('Sin datos'));
                }
                return HistoryTab(userId: profile.id);
              },
            ),
          ),
        ],
      ),
    );
  }
}