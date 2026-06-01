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
          'EDITAR PERFIL',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => profile == null
            ? const Center(child: Text('Sin datos'))
            : EditTab(
                profile: profile,
                onSaved: () => Navigator.of(context).pop(),
              ),
      ),
    );
  }
}
