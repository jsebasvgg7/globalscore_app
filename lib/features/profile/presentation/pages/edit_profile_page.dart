import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/profile_providers.dart';
import '../tabs/edit_tab.dart';

class EditProfilePage extends ConsumerWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(ownProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEEEAE4),
      body: Column(
        children: [
          // Header manual — igual que achievements/history page
          Container(
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEEEAE4),
              border: Border(
                bottom: BorderSide(color: Color(0xFFD5D0CA), width: 1.5),
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
                    'EDITAR PERFIL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DM Mono',
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
              data: (profile) => profile == null
                  ? const Center(child: Text('Sin datos'))
                  : EditTab(
                      profile: profile,
                      onSaved: () => Navigator.of(context).pop(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}