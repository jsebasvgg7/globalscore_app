import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/profile_models.dart';
import '../../domain/profile_providers.dart';
import '../widgets/profile_hero_banner.dart';

// ─── Cloudinary config ────────────────────────
// Reemplaza con tus valores reales
const _cloudinaryUploadUrl =
    'https://api.cloudinary.com/v1_1/djahz5tq3/image/upload';
const _cloudinaryUploadPreset = 'globalscoredb';

class EditTab extends ConsumerStatefulWidget {
  final UserProfile profile;
  final VoidCallback onSaved;

  const EditTab({super.key, required this.profile, required this.onSaved});

  @override
  ConsumerState<EditTab> createState() => _EditTabState();
}

class _EditTabState extends ConsumerState<EditTab> {
  final _nameController = TextEditingController();
  final _teamController = TextEditingController();
  final _playerController = TextEditingController();
  final _bioController = TextEditingController();

  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile.name;
    _teamController.text = widget.profile.favoriteTeam ?? '';
    _playerController.text = widget.profile.favoritePlayer ?? '';
    _bioController.text = widget.profile.bio ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teamController.dispose();
    _playerController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ─── Cloudinary upload ────────────────────
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse(_cloudinaryUploadUrl))
            ..fields['upload_preset'] = _cloudinaryUploadPreset
            ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final url = json['secure_url'] as String;

      await ref
          .read(profileServiceProvider)
          .updateAvatarUrl(widget.profile.id, url);

      ref.invalidate(ownProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar actualizado ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    final input = UpdateProfileInput(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      favoriteTeam: _teamController.text.trim(),
      favoritePlayer: _playerController.text.trim(),
    );

    await ref.read(editProfileProvider.notifier).save(
          userId: widget.profile.id,
          input: input,
          onSuccess: () {
            ref.invalidate(ownProfileProvider);
            widget.onSaved();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Perfil guardado ✓')),
            );
          },
          onError: (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(editProfileProvider);
    final bannersAsync =
        ref.watch(userBannersProvider(widget.profile.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // ── Avatar section ──────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ProfileAvatar(
                  url: widget.profile.avatarUrl,
                  radius: 48,
                  level: widget.profile.level,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Upload button
                    ElevatedButton.icon(
                      onPressed:
                          _uploadingAvatar ? null : _pickAndUploadAvatar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60519B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      icon: _uploadingAvatar
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Subir'),
                    ),
                    const SizedBox(width: 10),
                    // Remove button
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(profileServiceProvider)
                            .updateAvatarUrl(widget.profile.id, '');
                        ref.invalidate(ownProfileProvider);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Quitar'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Banner selector ─────────────
          bannersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (banners) => _BannerSelector(
              banners: banners,
              currentUrl: widget.profile.equippedBannerUrl,
              userId: widget.profile.id,
            ),
          ),

          // ── Form fields ──────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(
                    icon: Icons.person_outline, label: 'NOMBRE'),
                _FormField(
                  controller: _nameController,
                  hintText: 'Tu nombre',
                ),
                const SizedBox(height: 16),

                _SectionLabel(
                    icon: Icons.sports_soccer_outlined,
                    label: 'EQUIPO FAVORITO'),
                _FormField(
                  controller: _teamController,
                  hintText: 'Ej. Real Madrid',
                ),
                const SizedBox(height: 16),

                _SectionLabel(
                    icon: Icons.star_border_rounded,
                    label: 'JUGADOR FAVORITO'),
                _FormField(
                  controller: _playerController,
                  hintText: 'Ej. Vinicius Jr.',
                ),
                const SizedBox(height: 16),

                _SectionLabel(
                    icon: Icons.edit_note_rounded, label: 'BIO'),
                _FormField(
                  controller: _bioController,
                  hintText: 'Cuéntanos algo sobre ti...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        saveState.isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF60519B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: saveState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Guardar cambios',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
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

// ─── Banner selector ──────────────────────────
class _BannerSelector extends ConsumerWidget {
  final List<UserBanner> banners;
  final String? currentUrl;
  final String userId;

  const _BannerSelector({
    required this.banners,
    required this.currentUrl,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.image_outlined,
                  size: 16, color: Color(0xFF60519B)),
              const SizedBox(width: 8),
              Text(
                'BANNER DE PERFIL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: banners.map((banner) {
              final isSelected = banner.imageUrl == currentUrl;
              return _BannerRow(
                banner: banner,
                isSelected: isSelected,
                onTap: () async {
                  await ref.read(editProfileProvider.notifier).equipBanner(
                        userId: userId,
                        bannerUrl: isSelected ? null : banner.imageUrl,
                        onSuccess: () {
                          ref.invalidate(ownProfileProvider);
                          ref.invalidate(userBannersProvider(userId));
                        },
                      );
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BannerRow extends StatelessWidget {
  final UserBanner banner;
  final bool isSelected;
  final VoidCallback onTap;

  const _BannerRow({
    required this.banner,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF60519B), width: 1.5)
              : null,
          borderRadius: isSelected ? BorderRadius.circular(10) : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: banner.imageUrl,
                width: 80,
                height: 46,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 80,
                  height: 46,
                  color: const Color(0xFF60519B),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                banner.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF60519B), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF60519B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;

  const _FormField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF60519B), width: 1.5),
        ),
      ),
    );
  }
}