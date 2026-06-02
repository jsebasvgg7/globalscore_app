import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/profile_models.dart';
import '../../domain/profile_providers.dart';
import '../widgets/profile_hero_banner.dart';

// ── Paleta ────────────────────────────────────────────────────
const _bg      = Color(0xFFF0EDE8);
const _card    = Color(0xFFEAE7E1);
const _border  = Color(0xFFC8C3B8);
const _accent  = Color(0xFF5B4FD8);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF6B6580);
const _red     = Color(0xFFE24B4A);

const _shadowSm = BoxShadow(color: Color(0x4D1A1A2E), offset: Offset(1, 1), blurRadius: 0);
const _shadow   = BoxShadow(color: Color(0x661A1A2E), offset: Offset(2, 2), blurRadius: 0);

const _cloudinaryUploadUrl    = 'https://api.cloudinary.com/v1_1/djahz5tq3/image/upload';
const _cloudinaryUploadPreset = 'globalscoredb';

class EditTab extends ConsumerStatefulWidget {
  final UserProfile profile;
  final VoidCallback onSaved;

  const EditTab({super.key, required this.profile, required this.onSaved});

  @override
  ConsumerState<EditTab> createState() => _EditTabState();
}

class _EditTabState extends ConsumerState<EditTab> {
  final _nameController   = TextEditingController();
  final _teamController   = TextEditingController();
  final _playerController = TextEditingController();
  final _bioController    = TextEditingController();

  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _nameController.text   = widget.profile.name;
    _teamController.text   = widget.profile.favoriteTeam ?? '';
    _playerController.text = widget.profile.favoritePlayer ?? '';
    _bioController.text    = widget.profile.bio ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teamController.dispose();
    _playerController.dispose();
    _bioController.dispose();
    super.dispose();
  }

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
      final body     = await response.stream.bytesToString();
      final json     = jsonDecode(body) as Map<String, dynamic>;
      final url      = json['secure_url'] as String;

      await ref.read(profileServiceProvider).updateAvatarUrl(widget.profile.id, url);
      ref.invalidate(ownProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar actualizado ✓')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    final input = UpdateProfileInput(
      name:           _nameController.text.trim(),
      bio:            _bioController.text.trim(),
      favoriteTeam:   _teamController.text.trim(),
      favoritePlayer: _playerController.text.trim(),
    );

    await ref.read(editProfileProvider.notifier).save(
      userId:    widget.profile.id,
      input:     input,
      onSuccess: () {
        ref.invalidate(ownProfileProvider);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil guardado ✓')));
      },
      onError: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final saveState   = ref.watch(editProfileProvider);
    final bannersAsync = ref.watch(userBannersProvider(widget.profile.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // ── Avatar section ──────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: _card,
              border: Border.fromBorderSide(BorderSide(color: _border, width: 1)),
              boxShadow: [_shadow],
            ),
            child: Column(
              children: [
                ProfileAvatar(
                  url:    widget.profile.avatarUrl,
                  radius: 48,
                  level:  widget.profile.level,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botón subir
                    GestureDetector(
                      onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                      child: Container(
                        width: 48, height: 48,
                        color: _accent,
                        child: _uploadingAvatar
                            ? const Center(
                                child: SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                            : const Icon(Icons.upload_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón quitar
                    GestureDetector(
                      onTap: () async {
                        await ref.read(profileServiceProvider)
                            .updateAvatarUrl(widget.profile.id, '');
                        ref.invalidate(ownProfileProvider);
                      },
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: _card,
                          border: Border.all(color: _red, width: 1.5),
                          boxShadow: const [_shadowSm],
                        ),
                        child: const Icon(Icons.close, color: _red, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Banner selector ─────────────────
          bannersAsync.when(
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
            data: (banners) => _BannerSelector(
              banners:    banners,
              currentUrl: widget.profile.equippedBannerUrl,
              userId:     widget.profile.id,
            ),
          ),

          // ── Form fields ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(icon: Icons.person_outline,           label: 'NOMBRE'),
                _FormField(controller: _nameController,   hintText: 'Tu nombre'),
                const SizedBox(height: 16),

                _FieldLabel(icon: Icons.sports_soccer_outlined,   label: 'EQUIPO FAVORITO'),
                _FormField(controller: _teamController,   hintText: 'Ej. Real Madrid'),
                const SizedBox(height: 16),

                _FieldLabel(icon: Icons.star_border_rounded,      label: 'JUGADOR FAVORITO'),
                _FormField(controller: _playerController, hintText: 'Ej. Vinicius Jr.'),
                const SizedBox(height: 16),

                _FieldLabel(icon: Icons.edit_note_rounded,        label: 'BIO'),
                _FormField(controller: _bioController,    hintText: 'Cuéntanos algo sobre ti...', maxLines: 3),
                const SizedBox(height: 24),

                // Botón guardar — neobrutalista
                GestureDetector(
                  onTap: saveState.isLoading ? null : _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: saveState.isLoading ? _accent.withOpacity(0.6) : _accent,
                      boxShadow: const [_shadow],
                    ),
                    alignment: Alignment.center,
                    child: saveState.isLoading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text(
                            'GUARDAR CAMBIOS',
                            style: TextStyle(
                              fontFamily: 'DM Mono',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Colors.white,
                              letterSpacing: 1.0,
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Row(
            children: [
              Container(width: 3, height: 12, color: _accent),
              const SizedBox(width: 8),
              const Text(
                'BANNER DE PERFIL',
                style: TextStyle(
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
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: _card,
            border: Border.fromBorderSide(BorderSide(color: _border, width: 1)),
            boxShadow: [_shadowSm],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: banners.map((banner) {
              final isSelected = banner.imageUrl == currentUrl;
              return _BannerRow(
                banner:     banner,
                isSelected: isSelected,
                onTap: () async {
                  await ref.read(editProfileProvider.notifier).equipBanner(
                    userId:    userId,
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

  const _BannerRow({required this.banner, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: _accent.withOpacity(0.05),
                border: const Border(
                  left: BorderSide(color: _accent, width: 3),
                ),
              )
            : null,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: CachedNetworkImage(
                imageUrl:    banner.imageUrl,
                width:       76,
                height:      44,
                fit:         BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 76, height: 44, color: _accent),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                banner.name,
                style: const TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _text,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: _accent,
                child: const Text(
                  '✓',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Field helpers ─────────────────────────────
class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FieldLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: _muted,
              letterSpacing: 1.4,
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
      maxLines:   maxLines,
      style: const TextStyle(
        fontFamily: 'DM Mono',
        color: _text,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText:  hintText,
        hintStyle: TextStyle(
          fontFamily: 'DM Mono',
          color: _muted.withOpacity(0.6),
          fontSize: 13,
        ),
        filled:      true,
        fillColor:   _bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _border, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _border, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }
}